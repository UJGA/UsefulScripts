import os
import time
import random
import mutagen
from mutagen.mp4 import MP4
from mutagen.flac import FLAC
from tidalapi import Session
from pathlib import Path

# ========================
# CONFIGURATION VARIABLES
# ========================

MUSIC_FOLDER = ""
LOG_FILE = "failed_tracks.log"
PLAYLIST_NAME = "Imported from Local"
PLAYLIST_DESCRIPTION = "Songs matched by metadata from local files"
SUPPORTED_EXTENSIONS = ('.mp3', '.flac', '.m4a')
MIN_SLEEP = 1
MAX_SLEEP = 4
METADATA_SEARCH_RETRY = True  # If no match, try again including album info

# ========================
# FUNCTION DEFINITIONS
# ========================

def get_metadata(file_path):
    try:
        audio = mutagen.File(file_path)
        if isinstance(audio, MP4):
            title = audio.get('\xa9nam', [''])[0]
            artist = audio.get('\xa9ART', [''])[0]
            album = audio.get('\xa9alb', [''])[0]
        elif isinstance(audio, FLAC):
            title = audio.get('title', [''])[0]
            artist = audio.get('artist', [''])[0]
            album = audio.get('album', [''])[0]
        else:
            audio = mutagen.File(file_path, easy=True)
            if audio is None:
                return None
            title = audio.get('title', [''])[0]
            artist = audio.get('artist', [''])[0]
            album = audio.get('album', [''])[0]

        if title and artist:
            return {'title': title, 'artist': artist, 'album': album}
    except Exception as e:
        print(f"Error reading metadata from {file_path}: {e}")
    return None

def search_tidal(session, metadata):
    try:
        time.sleep(0.5)
        search_query = f"{metadata['artist']} {metadata['title']}"
        results = session.search(search_query)

        if 'tracks' in results:
            tracks = results['tracks']
            for track in tracks:
                if ('remix' not in track.name.lower() and 
                    metadata['artist'].lower() == track.artist.name.lower() and 
                    metadata['title'].lower() == track.name.lower()):
                    return track

            for track in tracks[:5]:
                artist_match = metadata['artist'].lower() in track.artist.name.lower() or \
                               track.artist.name.lower() in metadata['artist'].lower()
                title_match = metadata['title'].lower() in track.name.lower() or \
                              track.name.lower() in metadata['title'].lower()
                if artist_match and title_match:
                    return track

        if METADATA_SEARCH_RETRY and metadata['album']:
            time.sleep(0.5)
            search_query = f"{metadata['artist']} {metadata['title']} {metadata['album']}"
            results = session.search(search_query)

            if 'tracks' in results:
                tracks = results['tracks']
                for track in tracks[:5]:
                    if metadata['artist'].lower() in track.artist.name.lower() and \
                       metadata['title'].lower() in track.name.lower():
                        return track
    except Exception as e:
        print(f"Error searching Tidal: {e}")
    return None

def log_failure(log_path, filepath, reason):
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(f"{filepath} | {reason}\n")

def main():
    open(LOG_FILE, "w").close()  # Clear log at start

    if not os.path.exists(MUSIC_FOLDER):
        print(f"Error: Directory {MUSIC_FOLDER} does not exist or is not accessible.")
        return

    # Log in to Tidal
    session = Session()
    session.login_oauth_simple()

    user = session.user
    playlist = user.create_playlist(PLAYLIST_NAME, PLAYLIST_DESCRIPTION)

    processed = 0
    matched = 0
    failed = []

    for root, dirs, files in os.walk(MUSIC_FOLDER):
        for filename in files:
            if not filename.lower().endswith(SUPPORTED_EXTENSIONS):
                continue

            processed += 1
            filepath = os.path.join(root, filename)
            print(f"\nProcessing ({processed}): {filepath}")

            metadata = get_metadata(filepath)
            if not metadata:
                print(f"Could not read metadata from: {filename}")
                failed.append((filepath, "Could not read metadata"))
                log_failure(LOG_FILE, filepath, "Could not read metadata")
                continue

            print(f"Looking for: {metadata['artist']} - {metadata['title']}")
            track = search_tidal(session, metadata)

            if track:
                try:
                    playlist.add([track.id])
                    matched += 1
                    print(f"✓ Added: {track.artist.name} - {track.name}")
                    print(f"Progress: {matched}/{processed} songs matched")
                except Exception as e:
                    print(f"Error adding to playlist: {e}")
                    failed.append((filepath, f"Error adding to playlist: {e}"))
                    log_failure(LOG_FILE, filepath, f"Error adding to playlist: {e}")
            else:
                print(f"✗ No match found on Tidal for: {metadata['artist']} - {metadata['title']}")
                failed.append((filepath, "No match found on Tidal"))
                log_failure(LOG_FILE, filepath, "No match found on Tidal")

            time.sleep(random.uniform(MIN_SLEEP, MAX_SLEEP))

    print(f"\nFinished! Added {matched} out of {processed} songs to playlist.")
    if failed:
        print("\nFailed songs:")
        for path, reason in failed:
            print(f"- {path}: {reason}")
        print(f"\nSee details in: {LOG_FILE}")

if __name__ == "__main__":
    main()

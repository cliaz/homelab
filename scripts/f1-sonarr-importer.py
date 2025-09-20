#!/usr/bin/env python3
"""
Formula 1 File Mapper for Sonarr
Maps downloaded F1 files to Sonarr episodes and creates hardlinks for import.

cliaz, maintained on github.com/cliaz/homelab/scripts
"""

import re
import sys
import json
import urllib.request
import urllib.error
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Configuration
DEBUG = False  # set to False to disable debug output
DRY_RUN = False  # set to False to actually create hardlinks
NUMBER_OF_IMPORT_LIMIT = 0  # set to 0 for no limit
SERIES_TITLE = "Formula 1"

# Load configuration from f1_sonarr_importer_config.py, if available
try:
    from f1_sonarr_importer_config import (
        SONARR_URL, SONARR_API_KEY, TARGET_SEASON,
        F1_DOWNLOAD_DIR, TARGET_IMPORT_DIR, SONARR_TARGET_IMPORT_DIR,
        ALLOW_PARTIAL_MATCHING
    )
    F1_DOWNLOAD_DIR = Path(F1_DOWNLOAD_DIR)
    TARGET_IMPORT_DIR = Path(TARGET_IMPORT_DIR)
    SONARR_TARGET_IMPORT_DIR = Path(SONARR_TARGET_IMPORT_DIR)
except ImportError as e:
    print(f"Warning: Import error occurred: {str(e)}")
    print("Warning: f1_sonarr_importer_config.py not found. Using placeholder values.")
    SONARR_URL = "http://localhost:8989"
    SONARR_API_KEY = "your-api-key-here"
    TARGET_SEASON = 2025
    F1_DOWNLOAD_DIR = Path("./downloads")
    TARGET_IMPORT_DIR = Path("./import")
    SONARR_TARGET_IMPORT_DIR = Path("./import")
    ALLOW_PARTIAL_MATCHING = False

def map_session_name(filename_session: str) -> str:
    """
    Map session names from filename format to Sonarr format.
    eg 'filename_session_name' to 'sonarr_session_name'
    """
    session_mapping = {
        # Practice sessions
        'Free.Practice.One': 'Practice 1',
        'Free.Practice.Two': 'Practice 2', 
        'Free.Practice.Three': 'Practice 3',
        'Practice.One': 'Practice 1',
        'Practice.Two': 'Practice 2',
        'Practice.Three': 'Practice 3',
        'Practice': 'Practice',  # For single practice sessions
        
        # Qualifying
        'Qualifying': 'Qualifying',
        'Sprint.Qualifying': 'Sprint Qualifying',
        
        # Race sessions
        'Race': 'Race',
        'Sprint': 'Sprint Race',
        'Sprint.Race': 'Sprint Race',
        
        # Other sessions (these might not have direct Sonarr matches)
        'Drivers.Press.Conference': 'Drivers Press Conference',
        'Team.Principals.Press.Conference': 'Team Principals Press Conference',
        'Team.Principal.Press.Conference': 'Team Principal Press Conference',
        'F1.Show': 'F1 Show',
        'Teds.Qualifying.Notebook': 'Teds Qualifying Notebook',
        'Teds.Sprint.Notebook': 'Teds Sprint Notebook',
        'Teds.Notebook': 'Teds Notebook'
    }
    
    return session_mapping.get(filename_session, filename_session)

def extract_session_from_filename(filename: str) -> Optional[str]:
    """
    Extract session information from filename.
    """
    # Common session patterns in filenames - order matters for specificity
    session_patterns = [
        # Ted's Notebook sessions first (most specific)
        'Teds.Qualifying.Notebook', 'Teds.Sprint.Notebook', 'Teds.Notebook',
        
        # Practice sessions
        'Free.Practice.One', 'Free.Practice.Two', 'Free.Practice.Three',
        'Practice.One', 'Practice.Two', 'Practice.Three',
        
        # Qualifying and Sprint (more specific before general)
        'Sprint.Qualifying', 'Sprint.Race', 'Sprint',
        
        # Other specific sessions
        'Drivers.Press.Conference', 'Team.Principals.Press.Conference', 
        'Team.Principal.Press.Conference', 'F1.Show',
        
        # General sessions last
        'Qualifying', 'Race', 'Practice'
    ]
    
    for pattern in session_patterns:
        if pattern in filename:
            return pattern
    
    return None

def debug_print(message: str):
    """Print debug message if DEBUG is enabled."""
    if DEBUG:
        print(f"[DEBUG] {message}")

def get_series_id_by_title(sonarr_url: str, api_key: str, title: str) -> int:
    """Get series ID by title from Sonarr API."""
    debug_print(f"Searching for series: {title}")
    headers = {"X-Api-Key": api_key}
    
    try:
        req = urllib.request.Request(f"{sonarr_url}/api/v3/series", headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
        
        for series in data:
            if title.lower() == series.get('title', '').lower():
                debug_print(f"Found series ID: {series['id']}")
                return series['id']
                
        raise SystemExit(f"Series '{title}' not found on Sonarr at {sonarr_url}")
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as e:
        raise SystemExit(f"Error connecting to Sonarr: {e}")

def get_episodes_for_series(sonarr_url: str, api_key: str, series_id: int) -> List[Dict]:
    """Get all episodes for a series from Sonarr API."""
    debug_print(f"Getting episodes for series ID: {series_id}")
    headers = {"X-Api-Key": api_key}
    
    try:
        req = urllib.request.Request(f"{sonarr_url}/api/v3/episode?seriesId={series_id}", headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            episodes = json.loads(response.read().decode('utf-8'))
        debug_print(f"Found {len(episodes)} episodes")
        return episodes
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as e:
        raise SystemExit(f"Error getting episodes from Sonarr: {e}")

def generate_rounds_lookup_table(episodes: List[Dict]) -> Dict[int, Dict]:
    """
    Generate a lookup table of rounds from Sonarr episodes.
    
    Example episode data from Sonarr:
    {
        'seasonNumber': 2025,
        'episodeNumber': 1,
        'title': 'Formula 1 Aramco Pre-Season Testing 2025 (Day 1) - Session 1'
    }
    
    Returns a dictionary with round numbers as keys and round data as values:
    {
        0: {
            'round_name': 'Formula 1 Aramco Pre-Season Testing 2025 (Day 1)',
            'sessions': {
                'Session 1': {'prefix': 'S2025E1', 'episode_number': 1},
                'Session 2': {'prefix': 'S2025E2', 'episode_number': 2}
            }
        },
        ...
    }
    """
    debug_print("Generating rounds lookup table")
    rounds_data = {}
    round_counter = 0
    seen_rounds = set()
    
    # Pattern to match episode titles like "Formula 1 Aramco Pre-Season Testing 2025 (Day 1) - Session 1"
    episode_pattern = re.compile(r'^(.+?)\s*-\s*(.+)$')
    
    for episode in episodes:
        title = episode.get('title', '')
        season_num = episode.get('seasonNumber', 0)
        episode_num = episode.get('episodeNumber', 0)
        
        # Skip if not target season
        if season_num != TARGET_SEASON:
            continue
            
        match = episode_pattern.match(title)
        if not match:
            debug_print(f"Could not parse episode title: {title}")
            continue
            
        round_name, session = match.groups()
        prefix = f"S{season_num}E{episode_num}"
        
        # Clean up round name (remove "Formula 1" prefix if present)
        if round_name.startswith('Formula 1 '):
            round_name = round_name[10:].strip()
            
        # Assign round number if not seen before
        if round_name not in seen_rounds:
            rounds_data[round_counter] = {
                'round_name': round_name,
                'sessions': {}
            }
            seen_rounds.add(round_name)
            current_round = round_counter
            round_counter += 1
        else:
            # Find existing round number for this round name
            current_round = None
            for round_num, round_data in rounds_data.items():
                if round_data['round_name'] == round_name:
                    current_round = round_num
                    break
        
        if current_round is not None:
            rounds_data[current_round]['sessions'][session.strip()] = {
                'prefix': prefix,
                'episode_number': episode_num
            }
    
    debug_print(f"Generated lookup table with {len(rounds_data)} rounds")
    for round_num, round_data in rounds_data.items():
        debug_print(f"Round {round_num}: {round_data['round_name']} ({len(round_data['sessions'])} sessions)")
    
    return rounds_data

def extract_round_number_from_filename(filename: str) -> Optional[int]:
    """
    Extract round number from filename.
    Matches patterns like '.R12.' or '.Round.12.'
    """
    # Pattern for .R##. format
    r_pattern = re.compile(r'\.R(\d+)\.')
    match = r_pattern.search(filename)
    if match:
        return int(match.group(1))
    
    # Pattern for .Round.##. format
    round_pattern = re.compile(r'\.Round\.(\d+)\.')
    match = round_pattern.search(filename)
    if match:
        return int(match.group(1))
    
    return None

def find_matching_episode(filename: str, rounds_lookup: Dict[int, Dict]) -> Optional[Tuple[int, str]]:
    """
    Find matching sonarr episode for a filename.
    Returns tuple of (episode_number, prefix) or None if no match found.
    """
    debug_print(f"Processing file: {filename}")
    
    # Extract round number from filename
    round_number = extract_round_number_from_filename(filename)
    if round_number is None:
        debug_print("Could not extract round number from filename")
        return None
    
    debug_print(f"Found Round {round_number} in filename")
    
    if round_number not in rounds_lookup:
        debug_print(f"Round {round_number} (index {round_number}) not found in lookup table")
        return None

    # Log the round we're looking at
    round_data = rounds_lookup[round_number]
    debug_print(f"Mapped to Sonarr round: {round_data['round_name']}")
    
    # Get sessions for this round
    sessions = round_data['sessions']
    debug_print(f"Available sessions for the Round Lookup Table for round {round_number} are: {list(sessions.keys())}")
    
    # Extract session from filename
    filename_session = extract_session_from_filename(filename)
    if filename_session is None:
        debug_print("Could not extract session from filename")
        return None
    
    debug_print(f"Found session in filename: '{filename_session}'")
    
    # Map session name
    mapped_session = map_session_name(filename_session)
    debug_print(f"Mapped session '{filename_session}' to '{mapped_session}'")
    
    if mapped_session in sessions:
        episode_info = sessions[mapped_session]
        debug_print(f"Found match: {episode_info['prefix']}: {round_data['round_name']} - {mapped_session}")
        return episode_info['episode_number'], episode_info['prefix']
    
    # Try partial matching for sessions that might not have exact matches
    if ALLOW_PARTIAL_MATCHING:
        for session_name in sessions.keys():
            if mapped_session.lower() in session_name.lower() or session_name.lower() in mapped_session.lower():
                episode_info = sessions[session_name]
                debug_print(f"Found partial match: {episode_info['prefix']}: {round_data['round_name']} - {session_name}")
                return episode_info['episode_number'], episode_info['prefix']
    
    debug_print(f"No matching session found for '{mapped_session}' in the Round Lookup Table for round {round_number}")
    return None

def create_season_folder_if_missing(target_dir: Path, folder_name: str):
    """Create season folder in the target import directory if it doesn't exist."""
    season_folder = target_dir / folder_name
    if not season_folder.exists():
        if DRY_RUN:
            print(f"[DRY RUN] Would create season folder: {season_folder}")
        else:
            season_folder.mkdir(parents=True, exist_ok=True)
            print(f"Created season folder: {season_folder}")
    else:
        debug_print(f"Season folder already exists: {season_folder}")
    return season_folder

def create_hardlink(source_file: Path, target_dir: Path, episode_number: int, original_filename: str) -> bool:
    """
    Create a hardlink in the target directory with episode number prefix.
    Returns True if a new hardlink was created, False if it already existed.
    """
    target_filename = f"Formula 1 - S{TARGET_SEASON}E{episode_number} - {original_filename}"
    target_path = target_dir / target_filename

    target_dir.mkdir(parents=True, exist_ok=True)

    if DRY_RUN:
        if target_path.exists():
            print(f"[DRY RUN] Target already exists: {target_path}")
            return False
        else:
            print(f"[DRY RUN] Would create hardlink on host system:")
            print(f"  Source: {source_file}")
            print(f"  Target: {target_path}")
            return True
    else:
        try:
            if target_path.exists():
                print(f"Target already exists: {target_path}")
                return False

            target_path.hardlink_to(source_file)
            if target_path.exists():
                print(f"Created hardlink: {target_path}")
                return True
            else:
                # Was having issues with Sonarr deleting hardlinks on import, so this is just a sanity check
                print(f"Failed to create hardlink: {target_path}")
                return False
        except OSError as e:
            if e.errno == 18:
                print(f"Error: Cannot create hardlink across different devices/mounts: {e}")
            elif e.errno == 13:
                print(f"Error: Permission denied when creating hardlink: {e}")
            else:
                print(f"Error creating hardlink: {e}")
            return False

def convert_system_path_to_sonarr_container_path(system_path: Path) -> str:
    """
    Convert a system path to the corresponding path inside the Sonarr container.
    
    Args:
        system_path: Path object representing the file path on the host system
        
    Returns:
        String representing the path as seen from inside the Sonarr container
    
    Example:
        If on the host system the file is at '/media/MEDIA_SSD/torrents/tv/file.mkv'
        but Sonarr sees it as '/data/torrents/tv/file.mkv', this function will
        perform that conversion.
    """
    # Convert the paths to strings and ensure they're resolved/normalized
    system_str = str(system_path.resolve())
    host_base = str(TARGET_IMPORT_DIR.resolve())
    container_base = str(SONARR_TARGET_IMPORT_DIR)
    
    # Ensure host_base ends with separator for accurate replacement
    if not host_base.endswith('/'):
        host_base += '/'
    if not container_base.endswith('/'):
        container_base += '/'
    
    # Replace the host system's base path with the container's base path
    if system_str.startswith(host_base):
        relative_path = system_str[len(host_base):]
        container_path = container_base + relative_path
    else:
        # Fallback: try without trailing slash
        host_base_no_slash = host_base.rstrip('/')
        container_base_no_slash = container_base.rstrip('/')
        container_path = system_str.replace(host_base_no_slash, container_base_no_slash, 1)
    
    debug_print(f"Converting path for Sonarr:")
    debug_print(f"  System path: {system_str}")
    debug_print(f"  Container path: {container_path}")
    
    return container_path

def trigger_sonarr_import(sonarr_url: str, api_key: str, file_path: str) -> bool:
    """Trigger a Sonarr DownloadedEpisodesScan, passing in the Sonarr-compatible named and newly created hardlink."""
    debug_print(f"Triggering Sonarr scan for file: {file_path}")
    headers = {
        "X-Api-Key": api_key,
        "Content-Type": "application/json"
    }
    
    try:
        # Command 'DownloadedEpisodesScan' with specific file path
        data = {
            "name": "DownloadedEpisodesScan",
            "path": file_path,
            "importMode": "Copy"    # with the setting "Use Hardlinks instead of Copy" enabled in Sonarr, this will create a hardlink
        }
        debug_print(f"Sending API request to Sonarr: POST {sonarr_url}/api/v3/command")
        debug_print(f"Request data: {data}")
        
        json_data = json.dumps(data).encode('utf-8')
        req = urllib.request.Request(f"{sonarr_url}/api/v3/command", data=json_data, headers=headers, method='POST')
        
        with urllib.request.urlopen(req, timeout=10) as response:
            response_data = json.loads(response.read().decode('utf-8'))
        
        command_id = response_data.get('id')
        debug_print(f"Scan command initiated with ID: {command_id}")
        return True
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as e:
        print(f"Error triggering Sonarr scan: {e}")
        return False

def process_files(source_path: Path, target_dir: Path, rounds_lookup: Dict[int, Dict]):
    """
    Process video files from source path and create hardlinks in the target directory.
    
    Args:
        source_path: Source file or directory containing F1 video files
        target_dir: Target directory where hardlinks will be created
        rounds_lookup: Lookup table mapping round numbers to episode data
        
    The function will:
    1. If source_path is a file, process that single file
    2. If source_path is a directory, recursively scan for video files
    3. Try to match each file to a Sonarr episode
    4. Create a hardlink with the correct episode number prefix
    5. Trigger Sonarr import for each matched file
    
    If NUMBER_OF_IMPORT_LIMIT is set (>0), only process that many files.
    """
    debug_print(f"Processing files from: {source_path}")
    
    if not source_path.exists():
        print(f"Source path does not exist: {source_path}")
        return
    
    processed = 0
    matched = 0
    imported = 0
    
    if NUMBER_OF_IMPORT_LIMIT > 0:
        debug_print(f"Import limit is set to {NUMBER_OF_IMPORT_LIMIT} files")
    
    # Process all video files
    video_extensions = {'.mkv', '.mp4', '.avi', '.mov', '.ts'}
    
    # Determine files to process based on whether source is file or directory
    if source_path.is_file():
        # Single file mode
        files_to_process = [source_path] if source_path.suffix.lower() in video_extensions else []
    else:
        # Directory mode - recursively find all video files
        files_to_process = [f for f in source_path.rglob('*') if f.is_file() and f.suffix.lower() in video_extensions]
    
    for file_path in files_to_process:
        # Check if we've hit the import limit
        if NUMBER_OF_IMPORT_LIMIT > 0 and matched >= NUMBER_OF_IMPORT_LIMIT:
            print(f"Reached import limit of {NUMBER_OF_IMPORT_LIMIT} files")
            break
            
        processed += 1
        filename = file_path.name
        
        match_result = find_matching_episode(filename, rounds_lookup)
        if match_result:
            episode_number, prefix = match_result
            target_filename = f"Formula 1 - S{TARGET_SEASON}E{episode_number} - {filename}"
            target_path = target_dir / target_filename
            
            created = create_hardlink(file_path, target_dir, episode_number, filename)
            if created:
                matched += 1
                if DRY_RUN:
                    container_path = convert_system_path_to_sonarr_container_path(target_path)
                    print(f"[DRY RUN] Would trigger Sonarr API import command for container path: {container_path}")
                elif target_path.exists():
                    container_path = convert_system_path_to_sonarr_container_path(target_path)
                    if trigger_sonarr_import(SONARR_URL, SONARR_API_KEY, container_path):
                        print(f"Triggered Sonarr import for: {target_path.name}")
                        imported += 1
                    else:
                        print(f"Failed to trigger Sonarr import for: {target_path.name}")
            else:
                debug_print(f"Skipped Sonarr import since target already existed: {target_path}")
        print(f"\n")
        

    print(f"Processing complete: {matched}/{processed} files matched and processed")
    if NUMBER_OF_IMPORT_LIMIT > 0:
        print(f"Import limit was set to {NUMBER_OF_IMPORT_LIMIT} files")
    if not DRY_RUN:
        print(f"Sonarr import triggered for {imported}/{matched} matched files")


def main():
    """Main function."""
    # Handle command line arguments
    if len(sys.argv) > 1 and sys.argv[1] in ['-h', '--help', 'help']:
        print("Usage: python f1-sonarr-importer.py [path]")
        print("  path: Optional file or directory path to process")
        print("        If not provided, uses F1_DOWNLOAD_DIR from config")
        print("        If provided, must be a valid file or directory")
        return 0
    
    source_dir = F1_DOWNLOAD_DIR  # Default to value from config file
    
    if len(sys.argv) > 1:
        custom_path = Path(sys.argv[1])
        if not custom_path.exists():
            print(f"Error: Provided path does not exist: {custom_path}")
            return 1
        if not (custom_path.is_file() or custom_path.is_dir()):
            print(f"Error: Provided path is neither a file nor a directory: {custom_path}")
            return 1
        source_dir = custom_path
        print(f"Using custom source path: {source_dir}")
    else:
        print(f"Using source path from config: {source_dir}")
    
    print(f"Formula 1 File Mapper for Sonarr")
    print(f"Mode: {'DRY RUN' if DRY_RUN else 'LIVE'}")
    print(f"Debug: {'ON' if DEBUG else 'OFF'}")
    print(f"Import Limit: {NUMBER_OF_IMPORT_LIMIT if NUMBER_OF_IMPORT_LIMIT > 0 else 'Unlimited'}")
    
    # Step 1-3: Build lookup table
    try:
        series_id = get_series_id_by_title(SONARR_URL, SONARR_API_KEY, SERIES_TITLE)
        episodes = get_episodes_for_series(SONARR_URL, SONARR_API_KEY, series_id)
        rounds_lookup = generate_rounds_lookup_table(episodes)
        
        debug_print("\nRounds Lookup Table:")
        for round_num, round_data in rounds_lookup.items():
            debug_print(f"Round {round_num}: {round_data['round_name']}")
            for session_name, session_info in round_data['sessions'].items():
                debug_print(f"  Session: {session_name} -> Episode {session_info['episode_number']} ({session_info['prefix']})")
        debug_print("")
    except Exception as e:
        print(f"Error building lookup table: {e}")
        return 1
    
    # Step 4-7: Process files and trigger Sonarr imports
    try:
        F1_SEASON_FOLDER_IN_TARGET_IMPORT_DIR = create_season_folder_if_missing(Path(TARGET_IMPORT_DIR), f"Formula.1.{TARGET_SEASON}")
        process_files(Path(source_dir), F1_SEASON_FOLDER_IN_TARGET_IMPORT_DIR, rounds_lookup)
    except Exception as e:
        print(f"Error processing files: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
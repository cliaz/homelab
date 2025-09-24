#!/usr/bin/env python3
"""
Small test script: fetch episodes for 'Formula 1' from Sonarr and print those from season 2025.

Configuration: edit SONARR_URL and SONARR_API_KEY as needed.
"""
import json
import urllib.request
import urllib.error
import re
import f1_sonarr_importer_config

SONARR_URL = f1_sonarr_importer_config.SONARR_URL
SONARR_API_KEY = f1_sonarr_importer_config.SONARR_API_KEY
SERIES_TITLE = "Formula 1"
TARGET_SEASON = 2025
STARTING_ROUND = 0  # for numbering output rounds from this number


def get_series_id_by_title(sonarr_url, api_key, title):
    headers = {"X-Api-Key": api_key}
    try:
        req = urllib.request.Request(f"{sonarr_url}/api/v3/series", headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
        
        for s in data:
            if title.lower() == s.get('title', '').lower():
                return s['id']
        raise SystemExit(f"Series '{title}' not found on Sonarr at {sonarr_url}")
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as e:
        raise SystemExit(f"Error connecting to Sonarr: {e}")


def get_episodes_for_series(sonarr_url, api_key, series_id):
    headers = {"X-Api-Key": api_key}
    try:
        req = urllib.request.Request(f"{sonarr_url}/api/v3/episode?seriesId={series_id}", headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            return json.loads(response.read().decode('utf-8'))
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as e:
        raise SystemExit(f"Error getting episodes from Sonarr: {e}")


def main():
    series_id = get_series_id_by_title(SONARR_URL, SONARR_API_KEY, SERIES_TITLE)
    print(f"Found series ID: {series_id}")
    episodes = get_episodes_for_series(SONARR_URL, SONARR_API_KEY, series_id)
    print(f"Total episodes fetched: {len(episodes)}")

    eps_2025 = [e for e in episodes if e.get('seasonNumber') == TARGET_SEASON]
    print(f"Episodes in season {TARGET_SEASON}: {len(eps_2025)}\n")

    # Dynamically derive unique round prefixes by stripping session suffixes
    def canonical_prefix(title: str) -> str:
        # remove leading episode numbering like 'S2025E1:' or '1:' if present
        s = re.sub(r'^\s*(S\d+E\d+\s*:|\d+\s*[:.-]\s*)', '', title, flags=re.I)
        # split off session suffixes separated by ' - ' and keep left side
        s = s.split(' - ')[0]
        # remove parenthetical day/session markers like ' (Day 1)'
        s = re.sub(r'\s*\(day\s*\d+\)\s*', '', s, flags=re.I)
        # normalize whitespace
        s = re.sub(r'\s+', ' ', s).strip()
        return s

    groups = {}
    for ep in eps_2025:
        title = ep.get('title', '')
        base = canonical_prefix(title)
        groups.setdefault(base, []).append(ep)

    # Order prefixes by first appearance
    prefixes = list(groups.keys())

    # Print grouped results as numbered rounds
    for idx, p in enumerate(prefixes, start=STARTING_ROUND):
        group = sorted(groups[p], key=lambda x: x.get('episodeNumber'))
        #print(f"\n== Round {idx}: {p} ({len(group)} episodes) ==")
        for ep in group:
            print(f"S{ep.get('seasonNumber')}E{ep.get('episodeNumber')}: {ep.get('title')}")


if __name__ == '__main__':
    main()

#!/usr/bin/env python3

## This script moves Radarr movies to a new root folder based on a specific tag.
# Example usage: configure the system's local 'radarr' user to run this script as a cron job.
# $ sudo -u radarr crontab -l
# 30 1 * * * /usr/bin/python3 /path/to/homelab/scripts/radarr_tag_based_move.py >> /dockers/radarr/archive_move.log 2>&1

import logging

import requests


LOG_LEVEL = logging.INFO
logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s - %(levelname)s - %(message)s")


# Configuration
RADARR_API_URL = "http://localhost:7878/api/v3"
RADARR_API_KEY = "radarr_api_key"  # Replace with your Radarr API key
TAG_NAME = "archive"
NEW_ROOT_FOLDER = "/data_archive/media/movies"  # Must already exist as a Radarr root folder
TEST_MOVIE_TITLE = ""  # Leave empty to check all movies


headers = {
    "X-Api-Key": RADARR_API_KEY,
}


def log_request_response(response):
    logging.debug("Request URL: %s", response.request.url)
    logging.debug("Request Method: %s", response.request.method)
    logging.debug("Request Headers: %s", response.request.headers)
    if response.request.body:
        logging.debug("Request Body: %s", response.request.body)
    logging.debug("Response Status Code: %s", response.status_code)
    logging.debug("Response Content: %s", response.text)


def get_movies():
    logging.info("Fetching movies from Radarr...")
    response = requests.get(f"{RADARR_API_URL}/movie", headers=headers, verify=False)
    log_request_response(response)
    return response.json()


def get_tags():
    logging.info("Fetching tags from Radarr...")
    response = requests.get(f"{RADARR_API_URL}/tag", headers=headers, verify=False)
    log_request_response(response)
    return {tag["id"]: tag["label"] for tag in response.json()}


def get_root_folders():
    logging.info("Fetching root folders from Radarr...")
    response = requests.get(f"{RADARR_API_URL}/rootfolder", headers=headers, verify=False)
    log_request_response(response)
    return response.json()


def find_root_folder_id(root_folders, root_folder_path):
    logging.info("Finding root folder ID for %s...", root_folder_path)
    for folder in root_folders:
        if folder["path"] == root_folder_path:
            return folder["id"]
    return None


def update_movie_root_folder(movie, new_root_folder_id, new_root_folder_path):
    logging.info("Updating root folder for movie: %s", movie["title"])
    movie["rootFolderPath"] = new_root_folder_path
    movie["rootFolderId"] = new_root_folder_id

    folder_name = movie["path"].rstrip("/").split("/")[-1]
    movie["path"] = f"{new_root_folder_path}/{folder_name}"

    response = requests.put(
        f"{RADARR_API_URL}/movie/{movie['id']}",
        json=movie,
        headers=headers,
        params={"moveFiles": True},
        verify=False,
    )
    log_request_response(response)
    return response.status_code


def main():
    movies = get_movies()
    tags = get_tags()
    root_folders = get_root_folders()
    tag_id = next((id for id, label in tags.items() if label == TAG_NAME), None)

    if tag_id is None:
        logging.error("Tag '%s' not found in Radarr.", TAG_NAME)
        return

    new_root_folder_id = find_root_folder_id(root_folders, NEW_ROOT_FOLDER)

    if new_root_folder_id is None:
        logging.error("Root folder '%s' not found in Radarr configuration.", NEW_ROOT_FOLDER)
        return

    for movie in movies:
        if TEST_MOVIE_TITLE and movie["title"] != TEST_MOVIE_TITLE:
            continue

        if tag_id not in movie.get("tags", []):
            continue

        if movie["rootFolderPath"] == NEW_ROOT_FOLDER:
            continue

        status_code = update_movie_root_folder(movie, new_root_folder_id, NEW_ROOT_FOLDER)
        if status_code in (200, 202):
            logging.info("Successfully updated root folder for movie: %s", movie["title"])
        else:
            logging.error("Failed to update movie: %s - Status Code: %s", movie["title"], status_code)

    logging.info("Script execution completed.")


if __name__ == "__main__":
    main()

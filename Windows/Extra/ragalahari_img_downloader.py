"""
Ragalahari Image Downloader Script

This script allows users to download images from a specified URL. It checks for an active
internet connection, validates image URLs, and downloads the images to a designated folder.

Author: Sakshi
Date: 02-12-2023
"""

import os
import re
import sys
from urllib.parse import urlparse
import requests
from colorama import Fore, Style

DEFAULT_URL = (
    "https://starzone.ragalahari.com/feb2022/hd/"
    "aakanksha-singh-clap-press-meet/aakanksha-singh-"
    "clap-press-meet1.jpg"
)
DEFAULT_NUM_IMAGES = "A"
SEPARATOR_LINE = "━" * 125
CHUNK_SIZE = 1024
TIMEOUT = 5


def check_internet():
    """
    Checks for an active internet connection by making a request to Google's homepage.

    Returns:
    bool: True if an internet connection is available, False otherwise.
    """
    try:
        requests.get("http://www.google.com", timeout=TIMEOUT)
        return True
    except requests.exceptions.RequestException:
        return False


def get_user_input(prompt, default):
    """
    Get user input with a provided prompt and default value.

    Args:
    prompt (str): The message prompt.
    default (str): The default value.

    Returns:
    str: User input or default value if no input is provided.
    """
    user_input = input(prompt)
    return user_input if user_input else default


def validate_image_url(url):
    """
    Validate if the given URL is a supported image format (jpg or png) over HTTPS.

    Args:
    url (str): The URL to validate.

    Returns:
    bool: True if the URL is valid, False otherwise.
    """
    return url.startswith("https://") and (
        url.lower().endswith(".jpg") or url.lower().endswith(".png")
    )


def main():
    """
    Main function to run the image downloading script.
    """
    if not check_internet():
        print(f"{Fore.RED}No internet connection{Style.RESET_ALL}")
        sys.exit(1)

    print(SEPARATOR_LINE)
    print(f"{Style.BRIGHT}Default URL: {Style.RESET_ALL}{DEFAULT_URL}")
    print(f"{Style.BRIGHT}Default Number of images: {Style.RESET_ALL}All")
    print(SEPARATOR_LINE)

    # Prompt for the URL of the first image
    while True:
        url_prompt = (
            f"{Style.BRIGHT}Enter the full URL of the first image "
            f"(Press enter for default): {Style.RESET_ALL}"
        )
        full_url = get_user_input(url_prompt, DEFAULT_URL)

        if not validate_image_url(full_url):
            print("\n" + f"{Fore.RED}Invalid or unsupported image URL{Style.RESET_ALL}")
        else:
            break

    # Prompt for the number of images to download
    while True:
        num_images_prompt = (
            f"{Style.BRIGHT}How many images would you like to download? "
            f"(Press enter for default): {Style.RESET_ALL}"
        )
        num_images_input = input(num_images_prompt).strip()
        print()

        if num_images_input.lower() == "a" or num_images_input == "":
            num_images = float("inf")
            break
        else:
            if not num_images_input.isdigit() or int(num_images_input) <= 0:
                print(f"{Fore.RED}Invalid number of images{Style.RESET_ALL}")
            else:
                num_images = int(num_images_input)
                break

    parsed_url = urlparse(full_url)
    site_url = (
        f"{parsed_url.scheme}://{parsed_url.netloc}{os.path.dirname(parsed_url.path)}/"
    )
    folder_name = (
        re.sub(r"\d*$", "", os.path.splitext(os.path.basename(parsed_url.path))[0])
        .replace("-", " ")
        .title()
    )
    file_name_match = re.search(r"(\d+)\.(jpg|png)$", full_url)

    if file_name_match:
        file_number = int(file_name_match.group(1))
        file_extension = file_name_match.group(2)
        file_name = os.path.splitext(os.path.basename(full_url))[0][
            : -len(str(file_number))
        ]
    else:
        print(f"{Fore.RED}Couldn't extract image number from URL{Style.RESET_ALL}")
        sys.exit(1)

    num_downloaded = total_size = 0
    i = 1

    try:
        while i <= num_images:
            file_name_format = f"{file_name}{file_number + i - 1}.{file_extension}"
            file_path = os.path.join(folder_name, file_name_format)

            if not os.path.exists(folder_name):
                os.makedirs(folder_name)
                print(f"{Fore.GREEN}Folder '{folder_name}' created{Style.RESET_ALL}")
                print()

            if os.path.exists(file_path):
                print(
                    f"{file_name_format}{Fore.YELLOW} - already exists. "
                    f"Skipping...{Style.RESET_ALL}"
                )
                i += 1
                continue

            file_url = f"{site_url}{file_name_format}"
            try:
                with requests.get(file_url, stream=True, timeout=TIMEOUT) as response:
                    if response.status_code == 404:
                        print(
                            f"{Fore.YELLOW}No more images available. "
                            f"Stopping download.{Style.RESET_ALL}"
                        )
                        break

                    response.raise_for_status()
                    file_size = int(response.headers.get("content-length") or 0)

                    if file_size == 0:
                        print(
                            f"{file_name_format}{Fore.RED} - Unable to get file size. "
                            f"Skipping...{Style.RESET_ALL}"
                        )
                        continue

                    download_size = 0
                    with open(file_path, "wb") as file:
                        for chunk in response.iter_content(chunk_size=CHUNK_SIZE):
                            if chunk:
                                file.write(chunk)
                                download_size += len(chunk)
                                total_size += len(chunk)

                                percent = min(
                                    int((download_size / file_size) * 100), 100
                                )
                                if percent < 100:
                                    print(
                                        f"{file_name_format} - Downloading {percent}%{Style.RESET_ALL}",
                                        end="\r",
                                    )
                                else:
                                    print(
                                        f"{file_name_format} - Downloaded {percent}%{Style.RESET_ALL}",
                                        end="\r",
                                    )

                    print()
                    num_downloaded += 1
                    i += 1
            except requests.exceptions.RequestException as e:
                print(
                    f"{file_name_format}{Fore.RED} - {e.__class__.__name__} for URL: "
                    f"{file_url}{Style.RESET_ALL}"
                )
                break

        print()
        if num_images_input.lower() == "a":
            download_info = f"All images of '{folder_name}'"
        else:
            download_info = f"{num_downloaded} out of {num_images} images"

        print(
            f"{Fore.BLUE}Downloaded {download_info} at '{os.path.abspath(folder_name)}' - "
            f"Total downloaded size: {total_size/CHUNK_SIZE/CHUNK_SIZE:.2f} MB{Style.RESET_ALL}"
        )

    except KeyboardInterrupt:
        print()
        print(f"\n{Fore.RED}Download interrupted by user{Style.RESET_ALL}")


if __name__ == "__main__":
    main()

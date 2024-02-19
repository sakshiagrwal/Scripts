#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to get the desired number of images
function get_num_images() {
  local total_images=$1
  read -p "$(echo -e "Enter the ${GREEN}number${NC} of images to download (Press Enter for all $total_images): ")" user_input
  user_input="${user_input:-$total_images}"
  while ! [[ "$user_input" =~ ^[0-9]+$ && "$user_input" -ge 1 && "$user_input" -le $total_images ]]; do
    read -p "$(echo -e "${RED}Invalid input.${NC} Enter a ${GREEN}number${NC} between ${GREEN}1${NC} and ${GREEN}$total_images${NC}: ")" user_input
  done
  echo "$user_input"
}

# Function to download and handle existing files
function download_image() {
  local url=$1
  local destination_folder=$2
  local filename=$(basename "$url")
  local filepath="$destination_folder/$filename"
  if [[ -f "$filepath" ]]; then
    echo -e "'$filename' ${RED}already exists.${NC}"
    return 0
  fi
  echo -e "Downloading '${GREEN}$filename${NC}'..."
  if wget -q -O "$filepath" "$url"; then
    echo -e "${GREEN}Downloaded${NC}"
    return 0
  else
    echo -e "${RED}Failed${NC} to download '${GREEN}$filename${NC}'."
    return 1
  fi
}

# Get gallery URL
read -p "$(echo -e "Enter the ${GREEN}gallery URL${NC} (Press Enter for default): ")" user_url
user_url="${user_url:-https://www.ragalahari.com/actor/171464/allu-arjun-at-honer-richmont-launch.aspx}"

# Validate URL format
if [[ ! "$user_url" =~ \.aspx$ ]]; then
  echo -e "${RED}Invalid URL.${NC} Please enter a valid gallery URL." >&2
  exit 1
fi

# Get image URLs
response=$(curl -s "$user_url")
image_urls=($(echo "$response" | grep -oP '(?<=src=")[^"]*t\.jpg' | sed 's/t\.jpg$/\.jpg/'))
total_images=${#image_urls[@]}

# Get desired number of images
number_of_images=$(get_num_images "$total_images")

# Get destination folder
read -p "$(echo -e "Enter the ${GREEN}destination folder name${NC}: ")" destination_folder

# Create folder if it doesn't exist
mkdir -p "$destination_folder" || { echo -e "${RED}Failed${NC} to create destination folder." >&2; exit 1; }

# Download images
downloaded_count=0
skipped_count=0
for ((i=0; i<number_of_images; i++)); do
  imageUrl="${image_urls[i]}"
  if download_image "$imageUrl" "$destination_folder"; then
    ((downloaded_count++))
  else
    ((skipped_count++))
  fi
done

echo -e "All images downloaded at '$(realpath "$destination_folder")', ${GREEN}Total downloaded:${NC} $downloaded_count, ${RED}Total skipped:${NC} $skipped_count"

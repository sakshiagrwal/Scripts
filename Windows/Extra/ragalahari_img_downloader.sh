#!/bin/bash

# Function to get the desired number of images
function get_num_images () {
  total_images=$1
  while true; do
    read -p "Enter the number of images to download (Press Enter for all $total_images): " user_input
    if [[ -z "$user_input" ]]; then
      return $total_images
    fi
    if [[ ! $user_input =~ ^[0-9]+$ ]]; then
      echo "Enter a valid number between 1 and $total_images." >&2
    elif [[ $user_input -lt 1 || $user_input -gt $total_images ]]; then
      echo "Invalid number. Needs to be between 1 and $total_images." >&2
    else
      return $user_input
    fi
  done
}

# Function to download and handle existing files
function download_image () {
  url=$1
  destination_folder=$2
  filename=$(basename "$url")
  filepath="$destination_folder/$filename"
  if [[ ! -f "$filepath" ]]; then
    echo "Downloading '$filename'..."
    wget -q -O "$filepath" "$url" || return 1
    echo "downloaded"
  else
    echo "'$filename' already exists."
    return 0
  fi
}

# Get gallery URL
read -p "Enter the gallery URL (Press Enter for default): " user_url
if [[ -z "$user_url" ]]; then
  user_url="https://www.ragalahari.com/actor/171464/allu-arjun-at-honer-richmont-launch.aspx"
fi

# Validate URL format
if ! [[ "$user_url" =~ \.aspx$ ]]; then
  echo "Invalid URL. Please enter a valid gallery URL." >&2
  exit 1
fi

# Get image URLs
response=$(curl -s "$user_url")
image_urls=$(echo "$response" | grep -oP '(?<=src=")[^"]*t\.jpg' | sed 's/t\.jpg$/\.jpg/')
total_images=${#image_urls[@]}

# Get desired number of images
number_of_images=$(get_num_images $total_images)

# Get destination folder
read -p "Enter the destination folder name: " destination_folder

# Create folder if it doesn't exist
if [[ ! -d "$destination_folder" ]]; then
  mkdir -p "$destination_folder"
fi

# Download images
downloaded_count=0
skipped_count=0
for ((i=0; i<$number_of_images; i++)); do
  imageUrl=${image_urls[$i]}
  status=$(download_image "$imageUrl" "$destination_folder")
  if [[ "$status" -eq 0 ]]; then
    downloaded_count=$((downloaded_count+1))
  else
    skipped_count=$((skipped_count+1))
  fi
done

echo "All images downloaded at '$(realpath "$destination_folder")', Total downloaded: $downloaded_count, Total skipped: $skipped_count"

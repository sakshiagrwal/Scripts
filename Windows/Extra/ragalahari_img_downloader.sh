#!/bin/bash

# Function to get the desired number of images
function get_num_images() {
  local total_images=$1
  read -p "Enter the number of images to download (Press Enter for all '$total_images'): " user_input
  user_input="${user_input:-$total_images}"
  while ! [[ "$user_input" =~ ^[0-9]+$ && "$user_input" -ge 1 && "$user_input" -le $total_images ]]; do
    read -p "Invalid input. Enter a number between 1 and $total_images: " user_input
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
    echo -e "$filename - \e[93malready exists. Skipping...\e[0m"
    return 1
  fi
  printf "$filename - \e[93mDownloading...\e[0m"
  if wget -q -O "$filepath" "$url"; then
    echo -e "\r$filename - \e[92mDownloaded\e[0m    "
    return 0
  else
    echo -e "\r$filename - \e[91mFailed\e[0m        "
    return 1
  fi
}

# Get gallery URL
printf "%s\n" "$(printf '\u2500%.0s' {1..125})"
read -p "Enter the gallery URL (Press Enter for default): " user_url
user_url="${user_url:-https://www.ragalahari.com/actor/171464/allu-arjun-at-honer-richmont-launch.aspx}"

# Validate URL format
if [[ ! "$user_url" =~ \.aspx$ ]]; then
  echo -e "\n\e[91mInvalid URL. Please enter a valid gallery URL.\e[0m" >&2
  exit 1
fi

# Extract folder name from URL and convert to title case
folder_name=$(echo "$user_url" | grep -oP '[^/]+(?=\.aspx$)' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

# Get image URLs
response=$(curl -s "$user_url")
image_urls=($(echo "$response" | grep -oP '(?<=src=")[^"]*t\.jpg' | sed 's/t\.jpg$/\.jpg/'))
total_images=${#image_urls[@]}

# Get desired number of images
number_of_images=$(get_num_images "$total_images")

# Create destination folder
destination_folder="./$folder_name"
if [ ! -d "$destination_folder" ]; then
    mkdir -p "$destination_folder" || { echo "Failed to create destination folder." >&2; exit 1; }
    echo -e "\n\e[92mFolder '$folder_name' created.\e[0m\n"
fi

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
  # Update progress bar
  progress=$(( (i+1) * 100 / number_of_images ))
  printf "\rProgress: [%-20s] %d%%" $(printf '#%.0s' $(seq 1 $((progress / 5)))) $progress
done

echo -e "\nImages downloaded at: $(realpath "$destination_folder")/\n\e[92mTotal downloaded: $downloaded_count\e[0m - \e[93mTotal skipped: $skipped_count\e[0m\n"

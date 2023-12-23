#!/usr/bin/env bash

username=$1

if [ -z $username ]; then
    echo "Unable to start backuper, username is empty"
    exit -1
fi

echo "Started backuper for username $username"

backuppath="$username"
folder=$(date +%Y-%m-%d-%H%M%S | less)
backup_folder="$backuppath/$folder"
echo "Timestamp: $folder"
echo "Target backup folder: $backup_folder"
mkdir -p "$backup_folder"
echo "Folder for backup has been created..."

page_number=1

working_dir=$(pwd)

while true
do
    cd $working_dir

    repositories=$(curl -s "https://api.github.com/users/${username}/repos?per_page=100&page=$page_number" -H "Connection: close" | less)

    compact_json=$(echo "$repositories" | ./jq -c . | less)

    if [ "$compact_json" = "[]" ]; then
        break
    fi

    echo "Received page $page_number..."

    echo "Repositories descriptor received..."
    urls=$(echo "$repositories" | ./jq '.[].html_url')

    echo "Repositories urls successfully parsed..."

    echo "Saving repositories..."
    cd $backup_folder
    echo "$urls" | while read repo; do
        repo_url=$(echo "$repo" | cut -d'"' -f 2)
        echo "Processing $repo_url"
        zipball_url="$repo_url/archive/refs/heads/main.zip"
        echo "Zipball url: $zipball_url"
        curl "$zipball_url" -O -J -L >/dev/null
    done

    page_number=$(($page_number + 1))
done

echo "Backup of your repositories completed."

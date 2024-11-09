#!/bin/bash

requirement_check() {

    echo -n "Checking if jq is installed..."
    if ! command -v jq &> /dev/null
    then
        echo "jq could not be found"
        exit 1
    fi
    echo "OK"

    echo -n "Checking if git is installed..."
    if ! command -v git &> /dev/null
    then
        echo "git could not be found"
        exit 1
    fi
    echo "OK"

    echo -n "Checking if gitleaks is installed..."
    if ! command -v gitleaks &> /dev/null
    then
        echo "gitleaks could not be found"
        exit 1
    fi
    echo "OK"

    echo -n "Creating reports directory..."
    mkdir -p GSecScanReports
    echo "OK"

    echo -n "Creating temporary directory..."
    mkdir -p /tmp/GSecScan
    touch /tmp/GSecScan/all-repo.json
    echo "OK"

}

validate() {
    if [ "$1" -ne 2 ]; then
        echo "please provide the required arguments."
        echo "Usage: <base_url> <gitlab_access_token>"
        exit 1
    fi

}

Initialize() {
    BASE_URL=$1
    GITLAB_ACCESS_TOKEN=$2
}


fetch_repositories() {
    echo -n "Fetching all repositories metadata in GitLab..."

    response=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$BASE_URL/api/v4/application/statistics")
    TOTAL_REPOS=$(echo "$response" | jq -r '.projects')
    PAGE_SIZE=100
    TOTAL_PAGES=$(($TOTAL_REPOS / $PAGE_SIZE ))

    for page in $(seq 1 $TOTAL_PAGES); do
        response=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$BASE_URL/api/v4/projects?per_page=$PAGE_SIZE&page=$page")
        echo "$response" | jq -r '.[].ssh_url_to_repo' >> /tmp/GSecScan/all-repo.json
    done

    echo "OK"
        
}

scan_repositories() {
    while IFS= read -r repo; do
        printf "\nScanning repository: $repo"
    
        repo_name=$(echo $repo | cut -d':' -f2 | sed 's/\.git$//'| sed 's/\//_/g')
        git clone -q $repo /tmp/GSecScan/$repo_name

        leaks=$(gitleaks -v --report-path GSecScanReports/$repo_name-report dir /tmp/GSecScan/$repo_name)

        if [ $? -eq 1 ]; then
            echo "Leak found in repository: $repo"
        else
            echo "No leak found in repository: $repo"
            rm -rf GSecScanReports/$repo_name-report
        fi
        rm -rf /tmp/GSecScan/$repo_name
    done < /tmp/gitScan/all-repo.json
}

cleanup() {
    rm -rf /tmp/GSecScan
}

requirement_check
validate $#
Initialize $1 $2
fetch_repositories
scan_repositories
cleanup

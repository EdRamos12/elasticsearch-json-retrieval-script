#!/bin/bash

username=""
password=""
api_key=""
url=""

declare -A requests=(
  ["field_usage_stats"]="_all/_field_usage_stats"
  ["mapping"]="_all/_mapping"
  ["_nodes_usage"]="_nodes/usage"
  ["_stats"]="_stats"
  ["_cat_shards"]="_cat/shards?h=*&format=json&bytes=b&time=ms"
)

LOG_FILE="script_log.txt"

help() {
   # Display Help
   echo "Utility for getting various useful information in elasticsearch."
   echo "nodes usage | mapping | field_usage_stats | cluster stats | _cat/shards"
   echo
   echo "Syntax: bash get_json.sh [-url|u|p|i]"
   echo "options:"
   echo "url      Elasticsearch Url (cloud and localhost)."
   echo "u        Username to use for ElasticSearch."
   echo "p        Password to use for ElasticSearch."
   echo "api_key  Alternative authentication method for ElasticSearch."
   echo
}

display_usage() {
  echo "Usage: -url <url> -u <username> -p <password> -api_key <api_key>"
}

log() {
   exec 1>&2

   local timestamp
   timestamp=$(date +"%Y-%m-%d %H:%M:%S")
   local message="[$timestamp] $1"

   # Print to console
   echo "$message" | tee -a "$LOG_FILE"
}

request_json() {
  local uri="$1"
  local output_file="$2"
  local max_retries=5
  local retry=0

  if [ -z "$api_key" ]; then
    if [ -z "$username" ] || [ -z "$password" ] || [ -z "$url" ]; then
      log "Error: Missing required options."
      display_usage
      exit 1
    fi
    
    request_cmd () { curl -s "-u$username:$password" "$url/$uri"; } 
  else
    if [ -z "$url" ]; then
      log "Error: Missing required options."
      display_usage
      exit 1
    fi

    request_cmd () { curl -s -H "Authorization: ApiKey $api_key" "$url/$uri"; }
  fi

  while [ $retry -lt $max_retries ]; do
    log "Attempt $((retry + 1)): Sending request to $uri"
    response=$(request_cmd)

    if [ $? -eq 0 ]; then
      log "Request successful. Saving response to $output_file"
      echo "$response" > "$output_file"
      return 0
    else
      log "Request failed. Retrying..."
      ((retry++))
    fi
  done

  log "Maximum retries reached. Request failed."

  echo
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -u|--username)
      username="$2"
      ;;
    -p|--password)
      password="$2"
      ;;
    -url|--url)
      url="$2"
      ;;
    -api_key|--api_key)
      api_key="$2"
      ;;
    -h|--help)
      help
      exit
      ;;
    *)
      display_usage
      ;;
  esac
  shift 2
done

echo "$username"

if [ -z "$api_key" ] && [ -z "$username" ] && [ -z "$password" ] && [ -z "$url" ]; then
  help
  read -p "No arguments detected! Do you wish to proceed with wizard method? [y/n]: " wiz;

  if [ "$wiz" = "y" ]; then
    read -p "Use username and password for authentication? [y/n]: " use_login;

    if [ "$use_login" = "y" ]; then
      read -p "Elastic URL: " url
      read -p "Elastic username: " username
      read -sp "Elastic password: " password
      echo
    else
      read -p "Elastic URL: " url
      read -sp "Elastic api key: " api_key
    fi
  else
    exit 1
  fi
fi

if [ -z "$api_key" ]; then
  masked_password=${password//?/*}

  log "Using login credentials: $username:$masked_password and connecting to $url"
else
  masked_api_key=${api_key//?/*}

  log "Using API key: $masked_api_key and connecting to $url"
fi

for key in "${!requests[@]}"; do
  value="${requests[$key]}"

  current_timestamp=$(date +%s)

  result=$(request_json "$value" "${key}_${current_timestamp}.json")
done

log "Successfully requested and downloaded all required json!"
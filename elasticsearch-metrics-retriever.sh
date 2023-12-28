#!/bin/bash

username=""
password=""
api_key=""
url=""
exclude_commands=()
error=0

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
   echo "Utility for retrieving various useful information from Elasticsearch. (nodes usage | mapping | field_usage_stats | cluster stats | _cat/shards)"
   echo "Usage: bash elasticsearch-metrics-retriever.sh [-url <url>] [-u <username>] [-p <password>] [-api_key <api_key>]"
   echo
   echo "Options:"
   echo "  -url, --url          Elasticsearch URL (cloud or localhost)."
   echo "  -u, --username       Username for Elasticsearch authentication."
   echo "  -p, --password       Password for Elasticsearch authentication."
   echo "  -api_key, --api_key  Alternative authentication method using an API key for Elasticsearch."
  #  echo "  -x, --exclude        Exclude specific commands from being executed with curl."
   echo "  -h, --help           Display this help message."
   echo
   echo "Examples:"
   echo "  bash elasticsearch-metrics-retriever.sh -url http://localhost:9200 -u myuser -p mypass"
   echo "  bash elasticsearch-metrics-retriever.sh -url https://myelasticsearch.com -api_key myapikey -x '_all/_field_usage_stats' '_nodes/usage'"
   echo
   echo "Note: If no options are provided, the script will prompt for input interactively."
   echo
}

display_usage() {
  echo "Usage: bash elasticsearch-metrics-retriever.sh [-url <url>] [-u <username>] [-p <password>] [-api_key <api_key>] [-h]";
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
      return 1
    fi
    
    request_cmd () { curl -s "-u$username:$password" "$url/$uri"; } 
  else
    if [ -z "$url" ]; then
      log "Error: Missing required options."
      display_usage
      return 1
    fi

    request_cmd () { curl -s -H "Authorization: ApiKey $api_key" "$url/$uri"; }
  fi

  while [ $retry -lt $max_retries ]; do
    log "Attempt $((retry + 1)): Sending request to $uri"
    response=$(request_cmd)

    if [ $? -eq 0 ]; then
      if [[ "$response" == *"\"status\":401"* ]]; then
        if [ -z "$api_key" ]; then
          log "Error: Authentication failed. Please check your username and password."
        else
          log "Error: Authentication failed. Please check your api key."
        fi

        return 1
      fi

      log "Request successful. Saving response to $output_file"

      echo "$response" > "$output_file"
      return 0
    else
      log "Request failed. Retrying..."
      ((retry++))
    fi
  done

  log "Maximum retries reached. Request failed."
  return 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    # TODO: exclude commands
    # -x|--exclude)
    #   shift
    #   exclude_commands+=("$1")
    #   break
    #   ;;
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

if [ -z "$api_key" ] && [ -z "$username" ] && [ -z "$password" ] && [ -z "$url" ]; then
  help
  read -p "No arguments detected! Do you wish to proceed with the interactive wizard? [y/n]: " wiz;

  if [ "$wiz" = "y" ]; then
    read -p "Use username and password for authentication? [y/n]: " use_login;

    if [ "$use_login" = "y" ]; then
      read -p "Enter Elasticsearch URL: " url
      read -p "Enter Elasticsearch username: " username
      read -sp "Enter Elasticsearch password: " password
      echo
    else
      read -p "Enter Elasticsearch URL: " url
      read -sp "Enter Elasticsearch API key: " api_key
    fi
  else
    echo "Exiting the script. Provide necessary options or run the script with command-line arguments."
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

  if [[ " ${exclude_commands[@]} " =~ " $value " ]]; then
    log "Skipping the execution of the command '$value'"
    continue 
  fi

  current_timestamp=$(date +%s)

  # Call the function without capturing its output
  request_json "$value" "${key}_${current_timestamp}.json"

  # Check the return code directly
  if [ $? -ne 0 ]; then
    error=1
    echo "Something went wrong while the script was running. You can check script_log.txt to get more details."
    exit 1
  fi
done

if [ $error -eq 0 ]; then
  log "Done!"
  echo "Successfully requested and downloaded all required json!"
else
  echo "Something went wrong while the script was running. You can check script_log.txt to get more details."
fi
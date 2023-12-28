# Elasticsearch JSON Retrieval Script

This Bash script allows you to retrieve field usage statistics and mapping from an Elasticsearch index. It supports both basic authentication (username and password) and API key authentication. The script handles potential errors gracefully and provides useful logging.

## Prerequisites

Make sure you have the following prerequisites installed:

- [curl](https://curl.se/)

## Usage

```bash
bash get_json.sh -url <url> -u <username> -p <password> -api_key <api_key>
```

## Options
- `-url`: Elasticsearch URL (cloud and localhost).
- `-u`: Username to use for Elasticsearch.
- `-p`: Password to use for Elasticsearch.
- `-api_key`: Alternative authentication method for Elasticsearch.

## Example

```bash
bash get_json.sh -url https://your-elasticsearch-cluster -u your-username -p your-password
```

## Wizard Method

If no arguments are provided, the script will prompt you with a wizard to enter the required information.

```bash
bash get_json.sh
```

## Notes

- The script supports a set of predefined requests, including:
  - _all/_field_usage_stats
  - _all/_mapping
  - _nodes/usage
  - _stats
  - _cat/shards?h=*&format=json&bytes=b&time=ms
- The script uses a retry mechanism with a maximum of 5 retries in case of a request failure.

## Logging

The script logs its activities in the script_log.txt file, providing details on each request, success, failure, and the downloaded JSON files.

## Contributions

Feel free to contribute to this script and make it even more robust! If you encounter any issues or have suggestions, please open an issue or submit a pull request.

Happy scripting!
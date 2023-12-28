# Elasticsearch JSON Retrieval Script

This Bash script allows you to retrieve field usage statistics and mapping from an Elasticsearch index. It supports both basic authentication (username and password) and API key authentication. The script handles potential errors gracefully and provides useful logging.

## Prerequisites

Make sure you have the following prerequisites installed:

- [curl](https://curl.se/)

## How to Run

### Option 1: Run the Script via Curl (Bash One-Liner)

Run the following command in your terminal:

```bash
bash -c "$(curl -s https://raw.githubusercontent.com/EdRamos12/elasticsearch-json-retrieval-script/main/elasticsearch-metrics-retriever.sh)" -- -url <your_elasticsearch_url> -u <your_username> -p <your_password> -api_key <your_api_key>
```

This one-liner downloads and executes the script directly from the GitHub repository.

### Option 2: Run the Script Directly

1. Clone the repository:

  ```bash
  git clone https://github.com/EdRamos12/elasticsearch-json-retrieval-script.git
  ```

2. Navigate to the script directory:

  ```bash
  cd elasticsearch-json-retrieval-script
  ```

3. Run the script with the desired options:

  ```bash
  bash elasticsearch-metrics-retriever.sh -url <your_elasticsearch_url> -u <your_username> -p <your_password> -api_key <your_api_key>
  ```

## Options
- `-url`: Elasticsearch URL (cloud and localhost).
- `-u`: Username to use for Elasticsearch.
- `-p`: Password to use for Elasticsearch.
- `-api_key`: Alternative authentication method for Elasticsearch.

## Example

```bash
bash elasticsearch-metrics-retriever.sh -url https://your-elasticsearch-cluster -u your-username -p your-password
```

## Wizard Method

If no arguments are provided, the script will prompt you with a wizard to enter the required information.

```bash
bash elasticsearch-metrics-retriever.sh
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
#!/bin/bash

# **************************************************************
# This is a frontend to the elasticdump utility.
# Syntax:
# ./dump-query.sh "INDEX-NAME-OR-PATTERN" /path/to/query.json /path/to/result.json
# Example:
# ./dump-query.sh "logstash-*" query-received-message-times.json result-week2.json
# 
# Dependencies:
# - Create an environment file with your host and authorization header.
#   For the structure of the file, copy dump-query-template.env into dump-query.env.
# - Requires Elastic Dump (an NPM package).
#   https://github.com/elasticsearch-dump/elasticsearch-dump#readme
#   Install globally on your workstation with `npm i elasticdump -g`
# **************************************************************

# Command Line Arguments
INDEX="$1"
INQUERY="$2"
OUTFILE="$3"

# Verify we received all the stuff
if [[ -z "${INDEX}" ]] || [[ -z "${INQUERY}" ]] || [[ -z "${OUTFILE}" ]]; then
  echo "Missing parameter."
  echo "Syntax: ./dump-query.sh \"INDEX-NAME-OR-PATTERN\" /path/to/query.json /path/to/result.json"
  exit 1
fi

# Load environment file
set -o allexport
[[ -f dump-query.env ]] && source dump-query.env
set +o allexport

# Constants
# From Environment: 
# - ED_HEADERS
# - ED_HOST
# Batch Limit (will pull in batches of this amount). Edit to suit!
ED_LIMIT=5000
# How many concurrent processes to run. Edit to suit!
ED_CONCURRENCY=3
# File Size for each output file (will create files of this size at most)
ED_FILESIZE=250mb

echo "You are about to DUMP records from Elasticsearch."
echo "Host: $ED_HOST"
echo "Index: $INDEX"
echo "Query File: $INQUERY"
echo "Output File: $OUTFILE"
echo "Batch Size: $ED_LIMIT"
echo "Output File Chunk Size: $ED_FILESIZE"
echo ""
# Wait for the user to press any KEY to proceed or allow them to Ctrl+C
read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'

# Do it!
elasticdump \
  --headers "${ED_HEADERS}" \
  --input="${ED_HOST}${INDEX}" \
  --output="${OUTFILE}" \
  --searchBody=@"${INQUERY}" \
  --limit "$ED_LIMIT" \
  --concurrency $ED_CONCURRENCY \
  --fileSize="$ED_FILESIZE"
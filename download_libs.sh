#!/bin/bash

# Exit on error
set -e

# Configuration
JAR_URL="https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-core/1.2.1/hadoop-core-1.2.1.jar"
OUTPUT_DIR="./libs"
OUTPUT_FILE="${OUTPUT_DIR}/hadoop-core-1.2.1.jar"

# Create the output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
  echo "Creating directory: $OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"
fi

# Download the JAR file
echo "Downloading JAR from $JAR_URL..."
curl -o "$OUTPUT_FILE" "$JAR_URL"

# Verify the download
if [ -f "$OUTPUT_FILE" ]; then
  echo "Download complete: $OUTPUT_FILE"
else
  echo "Download failed!"
  exit 1
fi
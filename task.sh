#!/bin/bash

# Exit on error
set -e

# Configuration
HADOOP_IMAGE="bde2020/hadoop-base:2.0.0-hadoop2.7.4-java8"
CONTAINER_NAME="namenode"
HDFS_INPUT_DIR="/input_dir"
HDFS_OUTPUT_DIR="/output_dir"
LOCAL_SAMPLE_FILE="sample.txt"
PROCESS_UNITS_SOURCE="units/hadoop/ProcessUnits.java"
HADOOP_JAR="lib/hadoop-core-1.2.1.jar"
LOCAL_OUTPUT_DIR="./output"

# Step 1: Compile ProcessUnits.java
echo "Compiling ProcessUnits.java..."
if [ ! -f "$HADOOP_JAR" ]; then
  echo "Hadoop JAR file not found: $HADOOP_JAR"
  exit 1
fi

if [ ! -f "$PROCESS_UNITS_SOURCE" ]; then
  echo "Source file not found: $PROCESS_UNITS_SOURCE"
  exit 1
fi

COMPILED_DIR="./classes"
mkdir -p "$COMPILED_DIR"

javac --release 7 -classpath "$HADOOP_JAR" -d "$COMPILED_DIR" "$PROCESS_UNITS_SOURCE"
if [ $? -eq 0 ]; then
  echo "Compilation successful."
else
  echo "Compilation failed!"
  exit 1
fi

JAR_FILE="ProcessUnits.jar"
jar -cvf "$JAR_FILE" -C "$COMPILED_DIR" .
echo "JAR file created: $JAR_FILE"

# Step 2: Create HDFS input directory
echo "Creating HDFS input directory..."
docker exec -it $CONTAINER_NAME hdfs dfs -mkdir -p $HDFS_INPUT_DIR

# Step 4: Copy sample.txt to HDFS input directory
echo "Copying sample.txt to HDFS..."
docker cp $LOCAL_SAMPLE_FILE $CONTAINER_NAME:/tmp/sample.txt
docker exec -it $CONTAINER_NAME hdfs dfs -put /tmp/sample.txt $HDFS_INPUT_DIR

# Step 5: Verify sample.txt in HDFS input directory
echo "Verifying file in HDFS input directory..."
docker exec -it $CONTAINER_NAME hdfs dfs -ls $HDFS_INPUT_DIR

# Step 6: Copy and run the MapReduce program
echo "Copying and running MapReduce program..."
docker cp "$JAR_FILE" $CONTAINER_NAME:/tmp/ProcessUnits.jar
docker exec -it $CONTAINER_NAME hadoop jar /tmp/ProcessUnits.jar hadoop.ProcessUnits $HDFS_INPUT_DIR $HDFS_OUTPUT_DIR

# Step 7: Verify result file in HDFS output directory
echo "Verifying output files in HDFS output directory..."
docker exec -it $CONTAINER_NAME hdfs dfs -ls $HDFS_OUTPUT_DIR

# Step 8: Display Part-00000 from output folder
echo "Displaying Part-00000 content..."
docker exec -it $CONTAINER_NAME hdfs dfs -cat $HDFS_OUTPUT_DIR/part-00000

# Step 9: Copy output files to host system
echo "Copying output files to local host system..."
docker exec -it $CONTAINER_NAME hdfs dfs -get $HDFS_OUTPUT_DIR /tmp/output
docker cp $CONTAINER_NAME:/tmp/output "$LOCAL_OUTPUT_DIR"

echo "All tasks completed. Output files are in $LOCAL_OUTPUT_DIR"
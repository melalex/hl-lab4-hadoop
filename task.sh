#!/bin/bash

# Exit on error
set -e

# Configuration
HADOOP_IMAGE="bde2020/hadoop-base:2.0.0-hadoop2.7.4-java8"
CONTAINER_NAME="hadoop-docker"
HDFS_INPUT_DIR="/input_dir"
HDFS_OUTPUT_DIR="/output_dir"
LOCAL_SAMPLE_FILE="sample.txt"
MAPREDUCE_SOURCE="ProcessUnits.java"
LOCAL_OUTPUT_DIR="./output"

# Step 1: Start Hadoop in Docker
echo "Starting Hadoop container..."
docker run -d --name $CONTAINER_NAME --hostname hadoop-master $HADOOP_IMAGE

# Wait for Hadoop to start
echo "Waiting for Hadoop to initialize..."
sleep 30

# Step 2: Create HDFS input directory
echo "Creating HDFS input directory..."
docker exec -it $CONTAINER_NAME hdfs dfs -mkdir -p $HDFS_INPUT_DIR

# Step 3: Copy sample.txt to HDFS input directory
echo "Copying sample.txt to HDFS..."
docker cp $LOCAL_SAMPLE_FILE $CONTAINER_NAME:/tmp/sample.txt
docker exec -it $CONTAINER_NAME hdfs dfs -put /tmp/sample.txt $HDFS_INPUT_DIR

# Step 4: Verify sample.txt in HDFS input directory
echo "Verifying file in HDFS input directory..."
docker exec -it $CONTAINER_NAME hdfs dfs -ls $HDFS_INPUT_DIR

# Step 5: Compile and run the MapReduce program
echo "Compiling ProcessUnits.java..."
docker cp $MAPREDUCE_SOURCE $CONTAINER_NAME:/tmp/ProcessUnits.java
docker exec -it $CONTAINER_NAME bash -c "
  javac -classpath \$(hadoop classpath) -d /tmp /tmp/ProcessUnits.java &&
  jar -cvf /tmp/ProcessUnits.jar -C /tmp/ .
"

echo "Running MapReduce job..."
docker exec -it $CONTAINER_NAME hadoop jar /tmp/ProcessUnits.jar ProcessUnits $HDFS_INPUT_DIR $HDFS_OUTPUT_DIR

# Step 6: Verify result file is present in HDFS output directory
echo "Verifying output files in HDFS output directory..."
docker exec -it $CONTAINER_NAME hdfs dfs -ls $HDFS_OUTPUT_DIR

# Step 7: Display Part-00000 from output folder
echo "Displaying Part-00000 content..."
docker exec -it $CONTAINER_NAME hdfs dfs -cat $HDFS_OUTPUT_DIR/part-00000

# Step 8: Copy output files from HDFS to local host system
echo "Copying output files to local host system..."
docker exec -it $CONTAINER_NAME hdfs dfs -get $HDFS_OUTPUT_DIR /tmp/output
docker cp $CONTAINER_NAME:/tmp/output $LOCAL_OUTPUT_DIR

echo "All tasks completed. Output files are in $LOCAL_OUTPUT_DIR"
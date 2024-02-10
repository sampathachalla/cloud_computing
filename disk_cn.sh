#!/bin/bash

# Define file names
METRICS_FILE="disk_cn_metrics.txt"
FULL_OUTPUT_FILE="disk_cn_output.txt"

# Ensure the metrics file has a header if it's the first run
if [ ! -s $METRICS_FILE ]; then
    echo "Virtualization Type,CN Name,Thread Count,Total Number of Events,Throughput Read (MiB/s),Throughput Written (MiB/s)" > $METRICS_FILE
fi

# Array of container names
VM_NAMES=("CN48") 

# Initial thread count
THREAD_COUNT=64

# Loop through each VM name
for VM_NAME in "${VM_NAMES[@]}"; do
    # Sysbench commands executed inside VM using lxc shell
    # Prepare phase
    echo "Starting sysbench prepare in $VM_NAME with $THREAD_COUNT threads at $(date)" >> $FULL_OUTPUT_FILE
    sudo lxc exec $VM_NAME -- bash -c "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$THREAD_COUNT prepare" >> $FULL_OUTPUT_FILE 2>&1

    # Run phase
    echo "Starting sysbench run in $VM_NAME with $THREAD_COUNT threads at $(date)" >> $FULL_OUTPUT_FILE
    OUTPUT=$(sudo lxc exec $VM_NAME -- bash -c "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$THREAD_COUNT run")
    echo "$OUTPUT" >> $FULL_OUTPUT_FILE

    # Extract metrics from the OUTPUT variable
    TOTAL_EVENTS=$(echo "$OUTPUT" | grep "total number of events:" | awk '{print $NF}')
    READ_MB_S=$(echo "$OUTPUT" | awk '/read, MiB\/s:/{print $3}')
    WRITTEN_MB_S=$(echo "$OUTPUT" | awk '/written, MiB\/s:/{print $4}')

    # Append the extracted data to the metrics file
    VIRTUALIZATION_TYPE="LXC" # Adjust as necessary
    echo "$VIRTUALIZATION_TYPE  $VM_NAME    $THREAD_COUNT   $TOTAL_EVENTS   $READ_MB_S  $WRITTEN_MB_S" >> $METRICS_FILE

    # Cleanup phase
    echo "Starting sysbench cleanup in $VM_NAME with $THREAD_COUNT threads at $(date)" >> $FULL_OUTPUT_FILE
    sudo lxc exec $VM_NAME -- bash -c "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$THREAD_COUNT cleanup" >> $FULL_OUTPUT_FILE 2>&1

    echo "Sysbench test in $VM_NAME with $THREAD_COUNT threads completed at $(date)" >> $FULL_OUTPUT_FILE

    # Double the thread count for the next iteration
    THREAD_COUNT=$((THREAD_COUNT * 2))
done

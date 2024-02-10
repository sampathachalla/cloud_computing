#!/bin/bash

# Define file names
METRICS_FILE="disk_baremetal_metrics.txt"
FULL_OUTPUT_FILE="disk_baremetal_output.txt"

# Ensure the metrics file has a header if it's the first run
if [ ! -s $METRICS_FILE ]; then
    echo "Virtualization Type,Thread Count,Total Number of Events,Throughput Read (MiB/s),Throughput Written (MiB/s)" > $METRICS_FILE
fi

# Array of thread counts
THREAD_COUNTS=(1 2 4 8 16 32 64)

# Loop through each thread count
for THREAD_COUNT in "${THREAD_COUNTS[@]}"; do
    # Sysbench commands
    # Prepare phase
    echo "Starting sysbench prepare for ${THREAD_COUNT} threads at $(date)" >> $FULL_OUTPUT_FILE
    sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$THREAD_COUNT prepare >> $FULL_OUTPUT_FILE 2>&1

    # Run phase
    echo "Starting sysbench run for ${THREAD_COUNT} threads at $(date)" >> $FULL_OUTPUT_FILE
    OUTPUT=$(sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$THREAD_COUNT run)
    echo "$OUTPUT" >> $FULL_OUTPUT_FILE

    # Extract metrics from the OUTPUT variable
    TOTAL_EVENTS=$(echo "$OUTPUT" | grep "total number of events:" | awk '{print $NF}')
    # Assuming values are on the same line immediately after the labels
    READ_MB_S=$(echo "$OUTPUT" | awk '/read, MiB\/s:/{print $3}')
    WRITTEN_MB_S=$(echo "$OUTPUT" | awk '/written, MiB\/s:/{print $4}')

    # Append the extracted data to the metrics file
    VIRTUALIZATION_TYPE="baremetal" # Replace with actual virtualization type
    echo "$VIRTUALIZATION_TYPE,$THREAD_COUNT,$TOTAL_EVENTS,$READ_MB_S,$WRITTEN_MB_S" >> $METRICS_FILE

    # Cleanup phase
    echo "Starting sysbench cleanup for ${THREAD_COUNT} threads at $(date)" >> $FULL_OUTPUT_FILE
    sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$THREAD_COUNT cleanup >> $FULL_OUTPUT_FILE 2>&1

    echo "Sysbench test for ${THREAD_COUNT} threads completed at $(date)" >> $FULL_OUTPUT_FILE
done

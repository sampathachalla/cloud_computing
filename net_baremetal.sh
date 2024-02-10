#!/bin/bash

# Output files
summary_output_file="net_baremetal_metrics.txt"
detailed_output_file="net_baremetal_output.txt"

# Function to run iperf test
run_iperf_test() {
    threads=$1
    # Append detailed output to a single file
    output=$(iperf -c 127.0.0.1 -e -i 1 --nodelay -l 8192K -w 2.5M --trip-times --parallel $threads | tee -a $detailed_output_file)
    latency=$(echo "$output" | grep -oP '(\d+\.\d+)/\d+\.\d+/(\d+\.\d+)/\d+\.\d+ ms' | cut -d'/' -f3)
    throughput=$(echo "$output" | grep -oP '(\d+\.\d+) Gbits/sec' | tail -1)
    echo "$latency $throughput"
}

# Initialize output files
echo "Virtualization Type | Server | Client Threads | Latency (ms) | Measured Throughput (Gbits/s) | Efficiency" > $summary_output_file
# Clear the detailed output file to start fresh
echo "" > $detailed_output_file

# Start iperf server in the background
iperf -s -w 1M &

# Baseline throughput for efficiency calculations
baseline_throughput=0

# Run tests
for threads in 1 2 4 8 16 32 48 64; do
    echo "Running test with $threads thread(s)..." | tee -a $detailed_output_file
    # Get latency and throughput
    read latency throughput <<< $(run_iperf_test $threads)

    # Set baseline throughput on the first run
    if [ "$threads" -eq 1 ]; then
        baseline_throughput=$throughput
    fi

    # Calculate efficiency (assuming Baremetal is the baseline, so efficiency is 100%)
    efficiency=100
    
    # Output in the required format and append to the summary file
    echo "Baremetal | 1 | $threads | $latency | $throughput | $efficiency" >> $summary_output_file
done

# Stop iperf server
killall iperf


#!/bin/bash

# Summary output file
summary_output_file="net_cn_metrics.txt"
# Prefix for detailed output files
detailed_output_prefix="net_cn_output.txt"

# Function to run iperf test
run_iperf_test() {
    container_name=$1
    threads=$2
    # Define detailed output file for this test
    detailed_output_file="${detailed_output_prefix}${container_name}_threads_${threads}.txt"
    output=$(sudo lxc exec "$container_name" -- iperf -c 127.0.0.1 -e -i 1 --nodelay -l 8192K -w 2.5M --trip-times --parallel $threads)
    echo "$output" > "$detailed_output_file"  # Save detailed output to its file
    latency=$(echo "$output" | grep -oP '(\d+\.\d+)/\d+\.\d+/(\d+\.\d+)/\d+\.\d+ ms' | cut -d'/' -f3)
    throughput=$(echo "$output" | grep -oP '(\d+\.\d+) Gbits/sec' | tail -1)
    echo "$latency $throughput"
}

# Initialize summary output file
echo "Virtualization Type | Server | Client Threads | Latency (ms) | Measured Throughput (Gbits/s)" > "$summary_output_file"

# Function to run tests on containers
run_tests_on_containers() {
    for cpu_size in 1 2 4 8 16 32 48; do
        container_name="CN${cpu_size}"

        # Start iperf server inside the container
        sudo lxc exec "$container_name" -- iperf -s -w 1M &

        sleep 5 # Short pause to ensure the iperf server starts

        # Run tests  thread counts
        for threads in 1 2 4 8 16 32 64; do
            # Get latency and throughput
            read latency throughput <<< $(run_iperf_test "$container_name" "$threads")

            # reframing the output and push to the output file
            echo "Container | $cpu_size | $threads | $latency | $throughput" >> "$summary_output_file"
        done

        # Stopping the server
        sudo lxc exec "$container_name" -- killall iperf

        echo "Tests for $container_name complete." >> "${detailed_output_prefix}${container_name}.txt"
    done
}

# Running the containers
run_tests_on_containers

echo "Network tests on all containers are complete."


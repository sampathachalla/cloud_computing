#!/bin/bash

# Summary output file
summary_output_file="net_vm_metrics.txt"
# Detailed output file
detailed_output_file="net_vm_output.txt"

# Function to run iperf test
run_iperf_test() {
    vm_name=$1
    threads=$2
    # Capture detailed output in a variable and append to the detailed output file
    output=$(sudo lxc exec "$vm_name" -- iperf -c 127.0.0.1 -e -i 1 --nodelay -l 8192K -w 2.5M --trip-times --parallel $threads | tee -a $detailed_output_file)
    latency=$(echo "$output" | grep -oP '(\d+\.\d+)/\d+\.\d+/(\d+\.\d+)/\d+\.\d+ ms' | cut -d'/' -f3)
    throughput=$(echo "$output" | grep -oP '(\d+\.\d+) Gbits/sec' | tail -1)
    echo "$latency $throughput"
}

# Initialize output files
echo "Virtualization Type | Server | Client Threads | Latency (ms) | Measured Throughput (Gbits/s)" > $summary_output_file
# Clear the detailed output file to start fresh
echo "" > $detailed_output_file

# Function to run tests on VMs
run_tests_on_vms() {
    for cpu_size in 1 2 4 8 16 32 48; do
        vm_name="VM${cpu_size}"

        echo "Starting the network test for  $vm_name" | tee -a $detailed_output_file

        # Start iperf server inside the VM
        sudo lxc exec "$vm_name" -- iperf -s -w 1M &

        sleep 5 # Short pause to ensure iperf server starts

        # Run tests for different thread counts
        for threads in 1 2 4 8 16 32 64; do
            echo "Testing $vm_name with $threads thread(s)" | tee -a $detailed_output_file
            # Get latency and throughput
            read latency throughput <<< $(run_iperf_test $vm_name $threads)

            # Output in the required format and append to the summary file
            echo "VM | $cpu_size | $threads | $latency | $throughput" >> $summary_output_file
        done

        # Stop iperf server inside the VM
        sudo lxc exec "$vm_name" -- killall iperf

        echo "Tests for $vm_name complete." | tee -a $detailed_output_file
    done
}

# Run network tests on all VMs
run_tests_on_vms

echo "Network tests on all VMs are complete." | tee -a $detailed_output_file


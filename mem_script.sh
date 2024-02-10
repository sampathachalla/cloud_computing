#Sysbench code of memory testing using baremetal instance
#!/bin/bash

# Specify the file names
full_output_file="mem_output_baremetal.txt"
summary_file="mem_metrics.txt"

# Define the array of thread counts
thread_counts=(1 2 4 8 16 32 64)

# Virtualization type (adjust as necessary)
virtualization_type="baremetal"

# Check if summary file exists and is not empty, then add header if needed
if [ ! -s "$summary_file" ]; then
    echo "Virtualization_Type Threads Total_Operations MiB/sec" > "$summary_file"
fi

# Loop through each thread count
for threads in "${thread_counts[@]}"; do
    # Run the sysbench command and append the output
    echo "Running memory test using sysbench command with $threads thread(s)..." >> "$full_output_file"
    sysbench memory --memory-block-size=1K --memory-total-size=120G --threads=$threads run >> "$full_output_file"
    echo "Test results for $threads thread(s) appended to $full_output_file."

    # Extract the total number of operations and MiB/sec and append to the summary file
    echo "Extracting and storing summary information for $threads thread(s)..."

    # Extract and clean total operations and MiB/sec
    total_operations=$(grep "total number of events" "$full_output_file" | tail -n 1 | awk '{print $NF}')
    mib_sec=$(grep "transferred" "$full_output_file" | tail -n 1 | awk '{print $(NF-1)}' | tr -d '()')

    # Ensure numeric format for total_operations and mib_sec
    total_operations_clean=$(echo "$total_operations" | tr -d '[:alpha:]()')
    mib_sec_clean=$(echo "$mib_sec" | tr -d '[:alpha:]()')

    # Format and append the summary information using correct placeholders
    printf "%s %d %d %.2f\n"                    "$virtualization_type"      "$threads"      "$total_operations_clean"       "$mib_sec_clean" >> "$summary_file"

    # Clear the cache
    echo "Clearing cache..." >> "$full_output_file"
    sudo sync; sudo sh -c 'echo 3 >/proc/sys/vm/drop_caches'
    echo "Cache cleared for $threads thread(s)." >> "$full_output_file"
done

echo "Summary information for all baremetal instances appended to $summary_file."

#sysbench code of virtual machine instance

#!/bin/bash

# File names for consolidated output and metrics
total_output_file="mem_output_vm.txt"
metrics_file="mem_metrics.txt"

# Define the array of VM names
vm_names=("VM1" "VM2" "VM4" "VM8" "VM16" "VM32" "VM48") # You can add more VM names as needed

# Check and add header for metrics file if it does not exist or is empty
# Adjust the header to clearly separate VM_Name and Threads as distinct columns
if [ ! -s "$metrics_file" ]; then
    echo "Virtualization_Type VM_Name Threads Total_Operations MiB/sec" > "$metrics_file"
fi

# Initialize thread count
thread_count=1

# Loop through each VM name
for vm_name in "${vm_names[@]}"; do
    # Run the sysbench command inside the VM and append the output to the total output file
    echo "Running sysbench memory test inside $vm_name with $thread_count thread(s)..." >> "$total_output_file"
    sudo lxc exec "$vm_name" -- sysbench memory --memory-block-size=1K --memory-total-size=120G --threads=$thread_count run >> "$total_output_file"
    echo "Test results for $vm_name with $thread_count thread(s) appended to $total_output_file."

    # Extract the total number of operations and MiB/sec
    total_operations=$(grep "total number of events" "$total_output_file" | tail -n 1 | awk '{print $NF}')
    mib_sec=$(grep "transferred" "$total_output_file" | tail -n 1 | awk '{print $(NF-1)}' | tr -d '()')

    # Append the summary information along with thread count after VM name to the metrics file
    # Here, we adjust to include thread count as a separate column next to VM name
    printf "VirtualMachine-%s     %d  %d    %.2f\n"             "$vm_name"         "$thread_count"        "$total_operations"         "$mib_sec" >> "$metrics_file"

    # Attempt to clear cache inside VM, note about permissions applies
    echo "Attempting to clear cache inside $vm_name..." >> "$total_output_file"
    sudo lxc exec "$vm_name" -- bash -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    echo "Cache clear attempted for $vm_name." >> "$total_output_file"

    # Double the thread count for the next iteration
    thread_count=$((thread_count * 2))
done

echo "All VM test results and metrics, including thread counts, have been consolidated into $total_output_file and $metrics_file, respectively."



#sysbench command for running memory test in container instance
#!/bin/bash

# File names for consolidated output and metrics
total_output_file1="mem_output_cn.txt"
metrics_file1="mem_metrics.txt"

# Define the array of container names
vm_names=("CN1" "CN2" "CN4" "CN8" "CN16" "CN32" "CN48") # Add more container names as needed

# Header for metrics file, added only if it does not exist or is empty
# Adjust the header to accommodate VM_Name and Threads as separate columns for clarity
if [ ! -s "$metrics_file1" ]; then
    echo "Virtualization_Type VM_Name Threads Total_Operations MiB/sec" > "$metrics_file1"
fi

# Initial thread count
thread_count=1

# Loop through each VM name
for vm_name in "${vm_names[@]}"; do
    # Run the sysbench command inside the VM and append the output to the total output file
    echo "Running sysbench memory test inside $vm_name with $thread_count thread(s)..." >> "$total_output_file1"
    sudo lxc exec "$vm_name" -- sysbench memory --memory-block-size=1K --memory-total-size=120G --threads=$thread_count run >> "$total_output_file1"
    echo "Test results for $vm_name appended to $total_output_file1."

    # Extract the total number of operations and MiB/sec
    total_operations=$(grep "total number of events" "$total_output_file1" | tail -n 1 | awk '{print $NF}')
    mib_sec=$(grep "transferred" "$total_output_file1" | tail -n 1 | awk '{print $(NF-1)}' | tr -d '()')

    # Append the summary information to the metrics file
    # Here, we keep the thread count beside the VM name in the data lines, as per your request
    printf "Container-%s        %d      %d      %.2f\n"              "$vm_name"           "$thread_count"           "$total_operations"         "$mib_sec" >> "$metrics_file1"

    # Attempt to clear cache inside VM, note about permissions applies
    #echo "Attempting to clear cache inside $vm_name..." >> "$total_output_file1"
    #sudo lxc exec "$vm_name" -- bash -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    #echo "Cache clear attempted for $vm_name." >> "$total_output_file1"

    # Double the thread count for the next iteration
    thread_count=$((thread_count * 2))
done

echo "All container test results and metrics have been added into $total_output_file1 and $metrics_file1, respectively."




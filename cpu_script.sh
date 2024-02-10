#Sysbench code of cpu testing using baremetal instance
#!/bin/bash

# Defining the variables
output_file1="cpu_output_baremetal.txt"
metrics_file1="cpu_metrics.txt"
vt1="Baremetal"
thread_counts=(1 2 4 8 16 32 64)

# Checking the output file and checking the header
if [ ! -f "$output_file1" ]; then
  echo "Sysbench Output" > "$output_file1"
fi

if [ ! -f "$metrics_file1" ]; then
  echo "Virtualization_Type Threads Avg_Latency Throughput" > "$metrics_file1"
fi

# Looping based on cpu count
for threads in "${thread_counts[@]}"; do
  # Running the  sysbench command and send the output to the output file
  sysbench_output=$(sysbench cpu --cpu-max-prime=100000 --threads=$threads run)
  echo "Running with $threads thread(s):" >> "$output_file1"
  echo "$sysbench_output" >> "$output_file1"

  # Extract CPU speed and latency from the output
  cpu_speed=$(echo "$sysbench_output" | grep -oP 'events per second:\s+\K[0-9.]+')
  latency=$(echo "$sysbench_output" | grep -oP 'avg:\s+\K[0-9.]+')

  # Append CPU speed and latency to metrics file along with the thread count
  echo "$vt1              $threads      $latency      $cpu_speed " >> "$metrics_file1"
done

echo "Sysbench test for cpu is completed for all baremetal instances"


#Sysbench code of cpu testing using virtual machine instance

#!/bin/bash

# Defining the VM names
vm_names=("VM1" "VM2" "VM4" "VM8" "VM16" "VM32" "VM48") # Replace or extend this list with your actual VM names

# Define initial thread count
initial_thread_count=1

# Define base files for output and metrics
output_file2="cpu_output_vm.txt"
metrics_file2="cpu_metrics.txt"
vt1="VirtualMachine"

# Checking the output files and headers
if [ ! -f "$output_file2" ]; then
  echo "Sysbench Output for all VMs" > "$output_file2"
fi
if [ ! -f "$metrics_file2" ]; then
  echo "Virtualization_Type VM_Name Threads Avg_Latency Throughput" > "$metrics_file2"
fi

# Looping based on VM count
thread_count=$initial_thread_count
for vm_name in "${vm_names[@]}"; do
  # Running the  sysbench command amd storing the output to the output file
  sysbench_output=$(sudo lxc exec "$vm_name" -- sysbench cpu --cpu-max-prime=100000 --threads=$thread_count run)
  echo "Running with $thread_count thread(s) in $vm_name:" >> "$output_file2"
  echo "$sysbench_output" >> "$output_file2"

  # Extract CPU speed and latency from the output
  cpu_speed=$(echo "$sysbench_output" | grep -oP 'events per second:\s+\K[0-9.]+')
  latency=$(echo "$sysbench_output" | grep -oP 'avg:\s+\K[0-9.]+')

  # Append CPU speed and latency to the metrics file along with the VM name and thread count
  echo "$vt1-$vm_name     $thread_count     $latency      $cpu_speed" >> "$metrics_file2"

  # Doubling the thread count
  thread_count=$((thread_count * 2))
done

echo "Sysbench test for cpu completed for all virtual machine instances"

#Sysbench code of cpu testing using container instance

#!/bin/bash

# Defining container names
vm_names=("CN1" "CN2" "CN4" "CN8" "CN16" "CN32" "CN48") 

# Define initial thread count
initial_thread_count=1

# Defining the output files
output_file3="cpu_output_cn.txt"
metrics_file3="cpu_metrics.txt"
vt2="Container"

# Checking the output files and headers
if [ ! -f "$output_file3" ]; then
  echo "Sysbench Output for all containers" > "$output_file3"
fi
if [ ! -f "$metrics_file3" ]; then
  echo "Virtualization_Type VM_Name Threads Avg_Latency Throughput" > "$metrics_file3"
fi

# Loop through each container
thread_count=$initial_thread_count
for vm_name in "${vm_names[@]}"; do
  # Run sysbench command and append the output to the output file
  sysbench_output=$(sudo lxc exec "$vm_name" -- sysbench cpu --cpu-max-prime=100000 --threads=$thread_count run)
  echo "Running with $thread_count thread(s) in $vm_name:" >> "$output_file3"
  echo "$sysbench_output" >> "$output_file3"

  # Extract CPU speed and latency from the output
  cpu_speed=$(echo "$sysbench_output" | grep -oP 'events per second:\s+\K[0-9.]+')
  latency=$(echo "$sysbench_output" | grep -oP 'avg:\s+\K[0-9.]+')

  # Append CPU speed and latency to the metrics file along with the container name and thread count
  echo "$vt2-$vm_name           $thread_count     $latency      $cpu_speed" >> "$metrics_file3"

  # Double the thread count for the next iteration
  thread_count=$((thread_count * 2))
done

echo "Sysbench test of cpu completed for all container instances"



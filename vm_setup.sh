#!/bin/bash

# Redirect all output to vm_setup_output.txt
exec > vm_setup_output.txt 2>&1

# Loop through the desired CPU sizes
for cpu_size in 1 2 4 8 16 32 48; do
    # Define the VM name based on the CPU size
    vm_name="VM${cpu_size}"
    
    # Launch the VM with the specified CPU and memory limits
    echo "Creating $vm_name with $cpu_size CPU(s)..."
    sudo lxc launch ubuntu:22.04 "$vm_name" --vm -c limits.cpu="$cpu_size" -c limits.memory=4GiB
    
    # Wait for the VM to start and get an IP address
    echo "Waiting for $vm_name to start..."
    sleep 60 # Adjust this sleep as necessary to allow the VM to start up

    # Install sysbench and iperf inside the VM
    echo "Installing sysbench and iperf in $vm_name..."
    sudo lxc exec "$vm_name" -- sudo apt update
    sudo lxc exec "$vm_name" -- sudo apt install -y sysbench iperf

    echo "$vm_name setup complete."
done

echo "All VMs have been created and setup."


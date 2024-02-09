#!/bin/bash

# Redirect all output to container_setup_output.txt 
exec > cn_setup_output.txt 2>&1

# Loop through the desired CPU sizes
for cpu_size in 1 ; do
    # Define the container name based on the CPU size
    container_name="CN${cpu_size}"
    
    # Launch the container with the specified CPU and memory limits
    echo "Creating $container_name with $cpu_size CPU(s)"
    sudo lxc launch ubuntu:22.04 "$container_name"  -c limits.cpu="$cpu_size" -c limits.memory=150GiB
    
    # Wait for the VM to start and get an IP address
    echo "Waiting for $container_name to start"
    sleep 60 # Adjust this sleep as necessary to allow the conatiner to start up

    # Install sysbench and iperf inside the VM
    echo "Installing sysbench and iperf in $container_name..."
    sudo lxc exec "$container_name" -- sudo apt update
    sudo lxc exec "$container_name" -- sudo apt install -y sysbench iperf

    echo "$container_name setup complete."
done

echo "All the required containers have been created and setuped for experiment"

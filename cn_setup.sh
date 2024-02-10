#!/bin/bash

#Storing the outputs in container_setup_output.txt file
exec > cn_setup_output.txt 2>&1


#For loop run based on cpu sizes that we required for creating the container
for cpu_size in 1 2 4 8 16 32 48; do
    # Defining the container name based on the allocated CPU sizes
    container_name="CN${cpu_size}"
    
    # Launching the container with the specified CPU count and specified memory limits
    echo "Creating the container with name $container_name and have $cpu_size CPU(s) "
    sudo lxc launch ubuntu:22.04 "$container_name"  -c limits.cpu="$cpu_size" -c limits.memory=150GiB
    
    # Waiting for the VM to start 
    echo "Waiting for the $container_name to start"
    sleep 60 

    # Installing sysbench and iperf libraries inside the VM
    echo "Installing sysbench and iperf in $container_name..."
    sudo lxc exec "$container_name" -- sudo apt update
    sudo lxc exec "$container_name" -- sudo apt install -y sysbench iperf

    echo "$container_name setup completed successfully"
done

echo "All the required containers have been created and setuped for experiment"

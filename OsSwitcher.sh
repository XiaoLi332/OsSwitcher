#!/bin/bash

if ! command -v g++ &> /dev/null; then
    echo "Error: g++ is not installed. Installing it now..."
    sudo apt-get update
    sudo apt-get install -y g++
    if [ $? -ne 0 ]; then
        echo "Failed to install g++. Please install it manually."
        exit 1
    fi
fi

g++ modify_grub.cpp -o modify_grub

sudo ./modify_grub

if [ $? -eq 0 ]; then
    echo "Modify_grub executed successfully. Rebooting system now."
    sudo reboot
else
    echo "Modify_grub command failed."
fi

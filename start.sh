#!/bin/bash

# Start the container

docker compose up -d

# Check if the container is running
if ! docker ps | grep -q "rpi-os-emulated"; then
    echo "Container is not running"
    exit 1
fi

# User Instructions
echo "🚀 Container is running!"
echo "🎉 You can now access the Raspberry Pi OS Emulator."
echo "👤 The default username is 'pi' and the password is 'raspberry'."
echo "🔑 You can ssh into the container using the following command:"
echo "💻 ssh pi@localhost -p 5000"
echo "🔐 Or root@localhost -p 5000"

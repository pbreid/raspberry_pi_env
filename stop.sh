#!/bin/bash

# Check if the container is running
if ! docker ps | grep -q "rpi-os-emulated"; then
    echo "Container is not running"
    exit 1
fi

# Stop the container
docker compose down

# User Instructions
echo "👋 Container stopped!"
echo "🔑 You can start the container again using the following command:"
echo "🔐 Or ./start.sh"

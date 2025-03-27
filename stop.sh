#!/bin/bash

# Check we are in the correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo "You must run this script from the root directory of the project"
    exit 1
fi

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

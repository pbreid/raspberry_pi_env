#!/bin/bash

# Use the custom builder
docker buildx use mybuilder

# Ensure QEMU is set up for ARM emulation
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Build the Docker images using Docker Compose
docker compose build
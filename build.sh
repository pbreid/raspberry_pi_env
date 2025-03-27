#!/bin/bash

# Enable BuildKit for better performance
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

# Create .dockerignore if it doesn't exist
if [ ! -f .dockerignore ]; then
  cat > .dockerignore << EOF
.git
.github
**/*.md
**/*.log
**/__pycache__
**/*.pyc
EOF
fi

# Setup better cross-platform emulation
echo "Setting up improved ARM emulation..."
docker run --privileged --rm tonistiigi/binfmt --install all

# Use the custom builder
docker buildx use mybuilder || docker buildx create --name mybuilder --use

# Add build cache options and parallelism
echo "Building images with optimization..."
docker compose build --parallel --build-arg BUILDKIT_INLINE_CACHE=1

echo "Build complete!"
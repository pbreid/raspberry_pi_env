#!/bin/bash
# Start the container

# Check if we are in the correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo "You must run this script from the root directory of the project"
    exit 1
fi

# Install QEMU emulation support for cross-architecture containers
echo "🔄 Installing QEMU emulation support for ARM architecture..."
docker run --privileged --rm tonistiigi/binfmt --install all

# Check if the container is running
if docker ps | grep -q "rpi-emulator"; then
    echo "Container is already running"
    exit 0
fi

echo "🚀 Starting the Raspberry Pi emulator container..."
docker compose up -d

# Check if the container started successfully
if ! docker ps | grep -q "rpi-emulator"; then
    echo "❌ Container failed to start. Check logs with 'docker compose logs'"
    exit 1
fi

# User Instructions
echo ""
echo "✅ Container is running successfully!"
echo "🖥️ You can now access the Raspberry Pi OS Emulator."
echo ""
echo "📝 Login credentials:"
echo "   👤 Username: pi or root"
echo "   🔑 Password: raspberry"
echo ""
echo "🔒 SSH connection:"
echo "   ssh pi@localhost -p 22"
echo "   ssh root@localhost -p 22"
echo ""
echo "🌐 Web interface available at http://localhost:5000"
echo ""
echo "📋 To attach to the container shell, use: ./attach-pi.sh or ./attach-root.sh"
echo "🛑 To stop the container, use: ./stop.sh"

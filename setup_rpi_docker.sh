#!/bin/bash

set -e

# Configurable
IMAGE_URL="https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64-lite.img.xz"
IMAGE_FILE="2024-11-19-raspios-bookworm-arm64-lite.img.xz"
EXTRACTED_IMG="${IMAGE_FILE%.xz}"
MOUNT_DIR="/mnt/rpi-root"
BUILD_DIR="$PWD/.rpi_docker"
ROOTFS_DIR="$BUILD_DIR/rootfs"
DOCKER_IMAGE_NAME="rpi-os-emulated"


echo "🧰 Installing required packages..."
sudo apt update
sudo apt install -y docker.io qemu-user-static docker-buildx-plugin rsync xz-utils wget util-linux kpartx

echo "🗂️ Creating build directory..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Check if image file exists and is complete
download_required=true
extract_required=true

if [ -f "$IMAGE_FILE" ]; then
    # Check if the downloaded file is complete by comparing its size with the size reported by the server
    expected_size=$(curl -sI "$IMAGE_URL" | grep -i "Content-Length" | awk '{print $2}' | tr -d '\r')
    actual_size=$(stat -c%s "$IMAGE_FILE")
    
    if [ "$actual_size" -eq "$expected_size" ]; then
        echo "✅ Image file $IMAGE_FILE is already downloaded and complete."
        download_required=false
    else
        echo "⚠️ Image file $IMAGE_FILE exists but is incomplete. Re-downloading..."
        rm -f "$IMAGE_FILE"
    fi
fi

# Check if extracted image exists and is valid
if [ -f "$EXTRACTED_IMG" ] && [ "$download_required" = "false" ]; then
    # Basic validation: check if the file is a valid disk image
    if file "$EXTRACTED_IMG" | grep -q "boot sector"; then
        echo "✅ Extracted image $EXTRACTED_IMG is already available and valid."
        extract_required=false
    else
        echo "⚠️ Extracted image $EXTRACTED_IMG exists but appears invalid. Re-extracting..."
        rm -f "$EXTRACTED_IMG"
    fi
fi

# Download image if required
if [ "$download_required" = "true" ]; then
    echo "⬇️ Downloading Raspberry Pi OS image..."
    wget -O "$IMAGE_FILE" "$IMAGE_URL"
fi

# Extract image if required
if [ "$extract_required" = "true" ]; then
    echo "📦 Extracting image..."
    xz -dk "$IMAGE_FILE"
fi

echo "🔍 Attaching image and mapping partitions..."
LOOP_DEV=$(sudo losetup --show -f "$EXTRACTED_IMG")
sudo kpartx -av "$LOOP_DEV"

MAPPED_ROOT_PART="/dev/mapper/$(basename $LOOP_DEV)p2"

# Wait for partition to appear
for i in {1..5}; do
    if [ -e "$MAPPED_ROOT_PART" ]; then break; fi
    echo "⏳ Waiting for $MAPPED_ROOT_PART to appear..."
    sleep 1
done

if [ ! -e "$MAPPED_ROOT_PART" ]; then
    echo "❌ Partition $MAPPED_ROOT_PART not found!"
    sudo kpartx -d "$LOOP_DEV"
    sudo losetup -d "$LOOP_DEV"
    exit 1
fi

sudo mkdir -p "$MOUNT_DIR"
sudo mount "$MAPPED_ROOT_PART" "$MOUNT_DIR"

echo "📁 Copying root filesystem..."
sudo rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"
sudo rsync -aAX "$MOUNT_DIR/" "$ROOTFS_DIR/"

echo "🧼 Cleaning up mounts..."
sudo umount "$MOUNT_DIR"
sudo kpartx -d "$LOOP_DEV"
sudo losetup -d "$LOOP_DEV"

echo "🧠 Copying QEMU for ARM64 emulation..."
sudo cp /usr/bin/qemu-aarch64-static "$ROOTFS_DIR/usr/bin/"

echo "📦 Copying setup_root.sh..."
cp ../../setup_root.sh "$BUILD_DIR/"
cp ../root-bashrc "$BUILD_DIR/"
cp ../pi-bashrc "$BUILD_DIR/"
cp ../vimrc "$BUILD_DIR/"

# Create wrapper script for automatic sudo
cat > "$BUILD_DIR/entrypoint.sh" << 'EOF'
#!/bin/bash
if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@"
fi

# If we're root and the first argument is "su - pi", skip it
if [ "$1" = "su" ] && [ "$2" = "-" ] && [ "$3" = "pi" ]; then
  shift 3
  cd /home/pi
  exec "$@"
fi

exec "$@"
EOF

chmod +x "$BUILD_DIR/entrypoint.sh"

# Setup data directory
mkdir -p ../data
chown -R 1000:1000 -R ../data  

echo "⚙️ Setting up Docker buildx..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx create --use --name mybuilder || true
docker buildx inspect --bootstrap

echo "🐳 Building Docker image: $DOCKER_IMAGE_NAME"

# Copy configuration files needed for the build to the build directory
cp -f ../Dockerfile "$BUILD_DIR/"

sudo docker buildx build --platform linux/arm64 -t "$DOCKER_IMAGE_NAME" --load "$BUILD_DIR"

echo "✅ Done!"

FROM dtcooper/raspberrypi-os:bookworm

# Create users and directories first
RUN useradd -m -s /bin/bash pi && \
    usermod -aG sudo pi && \
    echo "root:raspberry" | chpasswd && \
    echo "pi:raspberry" | chpasswd && \
    mkdir -p /home/pi/.vim /root/.vim /run/sshd /data && \
    chmod 755 /run/sshd && \
    chown -R 1000:1000 /home/pi /data

# Install all dependencies in a single RUN to reduce layers
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-dev python3-venv python3-full python3.11-dev python3-pip \
    openssh-server \
    libgl1-mesa-glx libcap-dev libffi-dev libssl-dev \
    libatlas-base-dev libhdf5-dev libc-bin \
    v4l-utils gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    libcamera-dev libcamera-apps libcamera-tools \
    python3-picamera2 python3-libcamera \
    dnsmasq hostapd \
    libjpeg-dev libopenjp2-7-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    cmake build-essential pkg-config \
    jq curl uuid-runtime libcap-dev lm-sensors git nano sudo iputils-ping && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure SSH in a separate layer (small text files)
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Setup X authority files
RUN touch /home/pi/.Xauthority && chown 1000:1000 /home/pi/.Xauthority && chmod 600 /home/pi/.Xauthority && \
    touch /root/.Xauthority && chown 0:0 /root/.Xauthority && chmod 600 /root/.Xauthority

# Copy configuration files in a single layer
COPY ./env/root-bashrc /root/.bashrc
COPY ./env/pi-bashrc /home/pi/.bashrc
COPY ./env/vimrc /root/.vimrc 
COPY ./env/vimrc /home/pi/.vimrc

# Set Default Timezone to Brisbane/Australia
RUN ln -sf /usr/share/zoneinfo/Australia/Brisbane /etc/localtime


# Expose Web UI and SSH port
EXPOSE 5000 22

# Update CMD to start SSH and keep the container running
CMD chown -R 1000:1000 /data && service ssh start && tail -f /dev/null

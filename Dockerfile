FROM dtcooper/raspberrypi-os:bookworm

# Base Python dependencies
RUN apt update && apt install -y \
    python3 python3-dev python3-venv python3-full python3.11-dev python3-pip

# Install OpenSSH server
RUN apt install -y openssh-server

# System libraries
RUN apt install -y \
    libgl1-mesa-glx libcap-dev libffi-dev libssl-dev \
    libatlas-base-dev libhdf5-dev

# Camera and multimedia libraries
RUN apt install -y \
    v4l-utils gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    libcamera-dev libcamera-apps libcamera-tools \
    python3-picamera2 python3-libcamera

# Network and access point tools
RUN apt install -y \
    dnsmasq hostapd

# Image processing libraries
RUN apt install -y \
    libjpeg-dev libopenjp2-7-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev

# Build tools
RUN apt install -y \
    cmake build-essential pkg-config

# Utilities
RUN apt install -y \
    jq uuid-runtime libcap-dev lm-sensors git nano sudo    


# Add user pi
RUN useradd -m -s /bin/bash pi

# Set the root password
RUN echo "root:raspberry" | chpasswd
# Set the pi password
RUN echo "pi:raspberry" | chpasswd

# Create root's bashrc file
COPY ../env/root-bashrc /root/.bashrc

# Create pi's bashrc file
COPY ../env/pi-bashrc /home/pi/.bashrc

# # Configure Vim with basic colorscheme
COPY ../env/vimrc /root/.vimrc
COPY ../env/vimrc /home/pi/.vimrc

RUN mkdir -p /home/pi/.vim /root/.vim

RUN touch /home/pi/.Xauthority && chown 1000:1000 /home/pi/.Xauthority && chmod 600 /home/pi/.Xauthority

# Set ownership of pi's home directory to pi
RUN chown -R 1000:1000 /home/pi

RUN mkdir /run/sshd && chmod 755 /run/sshd

# Configure SSH to allow password authentication and PermitRootLogin yes
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config


# Add the pi user to the sudo group
RUN usermod -aG sudo pi

#Expose Web UI and SSH port
EXPOSE 5000 22

# Update CMD to start SSH and keep the container running
CMD service ssh start && tail -f /dev/null

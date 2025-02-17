#!/bin/bash
set -e

# Change to host root directory since we're running in a container
cd /host/tmp

# Configuration Variables
GVISOR_VERSION=${GVISOR_VERSION:-"latest"}
ARCH=$(uname -m)
INSTALL_DIR=${INSTALL_DIR:-"/usr/bin"}
RUNTIME_CLASS=${RUNTIME_CLASS:-"gvisor"}

echo "Installing gVisor version: $GVISOR_VERSION"
echo "Architecture: $ARCH"
echo "Installation Directory: $INSTALL_DIR"
echo "Runtime Class: $RUNTIME_CLASS"

# Determine the download URL based on the specified version
if [ "$GVISOR_VERSION" = "latest" ]; then
    BASE_URL="https://storage.googleapis.com/gvisor/releases/release/latest/${ARCH}"
else
    BASE_URL="https://storage.googleapis.com/gvisor/releases/release/${GVISOR_VERSION}/${ARCH}"
fi

# Download the gVisor binaries
curl -sLO ${BASE_URL}/runsc
curl -sLO ${BASE_URL}/runsc.sha512
curl -sLO ${BASE_URL}/containerd-shim-runsc-v1
curl -sLO ${BASE_URL}/containerd-shim-runsc-v1.sha512

# Verify the integrity of the downloaded binaries
sha512sum -c runsc.sha512
sha512sum -c containerd-shim-runsc-v1.sha512

# Remove checksum files
rm -f *.sha512

# Make the binaries executable
chmod a+rx runsc containerd-shim-runsc-v1

# Copy the binaries to the installation directory on host
chroot /host cp tmp/runsc tmp/containerd-shim-runsc-v1 usr/bin

export PATH=${PATH}:${INSTALL_DIR}

# Verify gVisor installation
chroot /host runsc --version

echo "Configuring Containerd to use gVisor..."

# Update Containerd config to use gVisor
cat <<EOF > /host/etc/containerd/config.toml
version = 2
[plugins."io.containerd.runtime.v1.linux"]
  shim_debug = true
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF

# Restart Containerd to apply changes
chroot /host systemctl restart containerd

echo "gVisor installation and Containerd configuration completed."
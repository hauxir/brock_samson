#!/bin/bash

# Variables
REPO_URL="https://github.com/jhogberg/otp.git"
INSTALL_DIR="/usr/"

# Update package list and install dependencies
apt-get update
apt-get install -y build-essential autoconf libncurses5-dev libssl-dev \
                        libsctp-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev \
                        libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev \
                        xsltproc fop

# Clone the Erlang/OTP repository
if [ -d "otp" ]; then
  echo "Directory 'otp' already exists. Removing it."
  rm -rf otp
fi

git clone $REPO_URL
cd otp

# Checkout the desired version (for example, OTP-24.0.6)
# git checkout OTP-24.0.6
git checkout john/erts/fix-compressed-ets-crash/OTP-19176

# Run the autoconf script
./otp_build autoconf

# Configure the build
./configure --prefix=$INSTALL_DIR

# Build Erlang/OTP
make

# Install Erlang/OTP
make install

# Verify installation
$INSTALL_DIR/bin/erl -version

echo "Erlang/OTP installation completed successfully."

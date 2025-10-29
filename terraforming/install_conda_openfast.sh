#!/bin/bash
set -e

# Update and install necessary tools
sudo apt-get update
sudo apt-get install -y wget

# 1. Install Miniconda (lightweight Anaconda distribution)
echo "Installing Miniconda..."
MINICONDA_INSTALLER="/tmp/Miniconda3-latest-Linux-x86_64.sh"
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $MINICONDA_INSTALLER
bash $MINICONDA_INSTALLER -b -p /opt/miniconda
rm $MINICONDA_INSTALLER

# Add Conda to the PATH for all users (or at least azureuser)
echo 'export PATH="/opt/miniconda/bin:$PATH"' | sudo tee -a /etc/profile.d/conda.sh

# Source the profile to make conda command available immediately
source /etc/profile.d/conda.sh

# 2. Conda Installation (as per OpenFAST documentation 2.1.1)
echo "Creating and installing OpenFAST environment..."
# Note: The 'azureuser' runs this, so the install directory is writeable.
# Create the environment with OpenFAST from conda-forge
/opt/miniconda/bin/conda create -n openfast -c conda-forge openfast -y

echo "Installation complete. The 'openfast' environment is created."
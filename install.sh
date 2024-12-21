#!/bin/bash

# Check and install packages
install_package() {
    PACKAGE=$1
    if ! command -v $PACKAGE &>/dev/null; then
        echo "$PACKAGE is not installed, installing..."
        # If it's Docker, use the official Docker installation steps
        if [ "$PACKAGE" == "docker" ]; then
            # Install dependencies required for Docker
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            # Add Docker's GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            # Add Docker repository
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            # Update package list
            sudo apt-get update
            # Install Docker
            sudo apt-get install -y docker-ce
        else
            # Install other packages
            sudo apt-get install -y $PACKAGE
        fi
    else
        echo "$PACKAGE is already installed"
    fi
}

# Start Docker if it's not running
start_docker_if_needed() {
    if ! docker info &>/dev/null; then
        echo "Docker is not running, starting..."
        sudo service docker start || { echo "Failed to start Docker"; exit 1; }
    else
        echo "Docker is running."
    fi
}

# Install necessary system packages
packages=("docker" "jq" "curl" "wget" "bc" "python3-pip")

for package in "${packages[@]}"; do
    install_package $package
done

# Ensure `pip3` is properly installed and available
if ! command -v pip3 &>/dev/null; then
    echo "pip3 is not properly installed, attempting to reinstall..."
    sudo apt-get install --reinstall -y python3-pip
    if ! command -v pip3 &>/dev/null; then
        echo "Failed to install pip3. Please check your Python environment."
        exit 1
    fi
fi
echo "pip3 is installed and available: $(pip3 --version)"

# Check and install Python packages
install_python_package() {
    PYTHON_PACKAGE=$1
    if ! pip3 show $PYTHON_PACKAGE &>/dev/null; then
        echo "$PYTHON_PACKAGE Python library is not installed, installing..."
        pip3 install $PYTHON_PACKAGE
    else
        echo "$PYTHON_PACKAGE Python library is already installed"
    fi
}

# Install necessary Python libraries
python_packages=("cryptography" "requests")

for python_package in "${python_packages[@]}"; do
    install_python_package $python_package
done

# Verify Docker installation and ensure it's running
echo "Verifying Docker installation..."
if ! command -v docker &>/dev/null; then
    echo "Docker is not installed, installing..."
    install_package "docker"
else
    start_docker_if_needed
fi

echo "All packages and libraries have been installed."
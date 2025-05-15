#!/bin/bash

# fail the whole script if any command fails
set -e

# Checks if a command exists on the current machine
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Installs homebrew if no package manager is found on the device since
# homebrew is support on MacOS and Linux
install_package_manager() {
    echo "No package manager found. Attempting to install Homebrew..."

    if [[ "$(uname)" == "Linux" ]]; then
        if command_exists yum; then
            sudo yum install -y curl file git
        elif command_exists dnf; then
            sudo dnf install -y curl file git
        else
            echo "No known system package manager to install prerequisites."
            exit 1
        fi
    fi

    if command_exists curl; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || /opt/homebrew/bin/brew shellenv)"

        if command_exists brew; then
            PKG_MANAGER="brew"
            echo "Homebrew installed successfully."
        else
            echo "Failed to install Homebrew."
            exit 1
        fi
    else
        echo "curl not available. Cannot install Homebrew."
        exit 1
    fi
}

# See if there is a package manager on the
# machine already
if command_exists apt; then
    PKG_MANAGER="apt"
elif command_exists snap; then
    PKG_MANAGER="snap"
elif command_exists brew; then
    PKG_MANAGER="brew"
else
    install_package_manager
fi

echo "Using Package Manager: $PKG_MANAGER"

# Install YAML parser to get packages to install
# if it's not already installed
if ! command_exists yq; then
    echo "Installing yq (YAML parser...)"
    case "$PKG_MANAGER" in
        apt)
            sudo apt update && sudo apt install -y yq
            ;;
        snap)
            sudo snap install yq
            ;;
        brew)
            brew install yq
            ;;
    esac
fi

if [ ! -f packages.yaml ]; then
    echo "No packages file found..."
    exit 1
fi

PACKAGES=$(yq '.packages[]' packages.yaml) # Read packages from YAML file

# Install packages using the package manager we installed
# or found above
for pkg in $PACKAGES; do
    if ! command_exists "$pkg"; then
        echo "installing $pkg"
        case "$PKG_MANAGER" in
            apt|snap)
                sudo $PKG_MANAGER install $pkg
                ;;
            brew)
                $PKG_MANAGER install $pkg
                ;;
        esac
    else
        echo "$pkg is already installed, skipping..."
    fi
done

echo "All packages installed..."

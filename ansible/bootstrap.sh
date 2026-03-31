#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh — run on a fresh machine to get Ansible + this repo, then provision.
# Usage: curl -sO https://raw.githubusercontent.com/ctjohnson/infra/main/ansible/bootstrap.sh && bash bootstrap.sh

REPO_URL="${INFRA_REPO:-https://github.com/ctjohnson/infra.git}"
INFRA_DIR="${INFRA_DIR:-$HOME/infra}"
ANSIBLE_DIR="$INFRA_DIR/ansible"

echo "==> Detecting OS..."
OS="$(uname -s)"
ARCH="$(uname -m)"
echo "    OS=$OS ARCH=$ARCH"

install_ansible_macos() {
    if ! command -v brew &>/dev/null; then
        echo "==> Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon path
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo "==> Installing Ansible via Homebrew..."
    brew install ansible git
}

install_ansible_debian() {
    echo "==> Installing Ansible via apt..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq software-properties-common git python3-pip
    sudo apt-get install -y -qq ansible
}

install_ansible_arch() {
    echo "==> Installing Ansible via pacman..."
    sudo pacman -Sy --noconfirm ansible git python
}

case "$OS" in
    Darwin)  install_ansible_macos ;;
    Linux)
        if [ -f /etc/debian_version ]; then
            install_ansible_debian
        elif [ -f /etc/arch-release ]; then
            install_ansible_arch
        else
            echo "ERROR: Unsupported Linux distro. Install ansible manually, then re-run."
            exit 1
        fi
        ;;
    *)
        echo "ERROR: Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "==> Ansible version: $(ansible --version | head -1)"

# Clone or update the infra repo
if [ -d "$INFRA_DIR/.git" ]; then
    echo "==> Updating existing infra repo..."
    git -C "$INFRA_DIR" pull --rebase
else
    echo "==> Cloning infra repo..."
    git clone "$REPO_URL" "$INFRA_DIR"
fi

# Install required Ansible collections
echo "==> Installing Ansible Galaxy requirements..."
if [ -f "$ANSIBLE_DIR/requirements.yml" ]; then
    ansible-galaxy install -r "$ANSIBLE_DIR/requirements.yml"
fi

# Run the playbook
echo "==> Running Ansible playbook..."
cd "$ANSIBLE_DIR"
ansible-playbook site.yml --ask-become-pass

echo ""
echo "==> System provisioned. Now apply dotfiles:"
echo "    chezmoi init --apply https://github.com/ctjohnson/infra.git"
echo ""

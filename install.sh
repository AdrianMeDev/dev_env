#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# TODO: Set this to your own dotfiles repository
DOTFILES_REPO="https://github.com/your-username/your-dotfiles-repo.git"

# --- Helper Functions ---
# Function to print messages
log() {
  echo "--------------------------------------------------"
  echo "$1"
  echo "--------------------------------------------------"
}

# --- Main Setup Functions ---

# 1. Update and Upgrade System
update_system() {
  log "Updating and upgrading system packages..."
  sudo apt-get update
  sudo apt-get upgrade -y
}

# 2. Install Nala and Core Utilities
install_core_utils() {
  log "Installing Nala and core utilities..."
  sudo apt-get install -y nala

  # Use nala for subsequent installations
  sudo nala install -y \
    build-essential \
    git \
    unzip \
    tree \
    ripgrep \
    fd-find \
    eza \
    curl \
    wget

  # Create a symbolic link for fd -> fdfind
  # Some tools expect 'fd' but Ubuntu packages it as 'fd-find'
  ln -s $(which fdfind) ~/.local/bin/fd || true
}

# 3. Install and Configure Zsh & Oh My Zsh
setup_zsh() {
  log "Installing and configuring Zsh with Oh My Zsh..."
  sudo nala install -y zsh

  # Set Zsh as the default shell
  chsh -s $(which zsh)

  # Install Oh My Zsh
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  # Install Zsh plugins
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || true

  # Note: You'll need to add these plugins to your .zshrc file, e.g.:
  # plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
  # This script avoids modifying .zshrc directly to prevent conflicts with your dotfiles.
  log "Remember to add 'zsh-autosuggestions' and 'zsh-syntax-highlighting' to the plugins array in your .zshrc!"
}

# 4. Install Neovim and its Dependencies
install_neovim() {
  log "Installing Neovim and dependencies (Lazygit)..."

  # Check if snapd is installed, if not, install it
  if ! command -v snap &> /dev/null; then
    sudo nala install -y snapd
  fi

  # Install latest stable Neovim from Snap
  log "Installing Neovim via Snap..."
  sudo snap install nvim --classic

  # Install Lazygit
  log "Installing Lazygit..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  sudo tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
  rm /tmp/lazygit.tar.gz
}

# 5. Install Zellij Terminal Multiplexer
install_zellij() {
  log "Installing Zellij..."
  # Check if snapd is installed, if not, install it
  if ! command -v snap &> /dev/null; then
    sudo nala install -y snapd
  fi

  sudo snap install zellij --classic

  # Create config directory and dump default config
  mkdir -p "$HOME/.config/zellij"
  zellij setup --dump-config > "$HOME/.config/zellij/config.kdl"

  # Add Zellij to Zsh startup
  echo 'eval "$(zellij setup --init zsh)"' >> "$HOME/.zshrc"
  log "Zellij will now start automatically with new Zsh shells."
}

# 6. Setup for WSL2 (Clipboard sharing)
setup_wsl() {
  if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; then
    log "WSL detected. Installing win32yank for clipboard support..."
    curl -sLo/tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
    unzip -p /tmp/win32yank.zip win32yank.exe > /tmp/win32yank.exe
    chmod +x /tmp/win32yank.exe
    sudo mv /tmp/win32yank.exe /usr/local/bin/
    log "win32yank.exe installed."
  else
    log "Not in WSL. Skipping win32yank installation."
  fi
}

# 7. Clone Personal Dotfiles
clone_dotfiles() {
  log "Cloning dotfiles from $DOTFILES_REPO..."
  if [ ! -d "$HOME/dotfiles" ]; then
    git clone "$DOTFILES_REPO" "$HOME/dotfiles"
    log "Dotfiles cloned into ~/dotfiles. You can now symlink them into place."
  else
    log "~/dotfiles directory already exists. Skipping clone."
  fi
}


# --- Main Execution ---
main() {
  update_system
  install_core_utils
  setup_zsh
  install_neovim
  install_zellij
  setup_wsl
  clone_dotfiles

  log "✅ Setup complete! Please restart your terminal or log out and back in to apply all changes."
}

main

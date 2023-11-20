#!/bin/bash

package_manager=""

check_root() {
	if [[ "$EUID" -ne 0 ]]; then
		echo "Error: This script requires root privileges. Please run it with sudo."
		exit 1
	fi
}

detect_package_manager() {
	if command -v yum &>/dev/null; then
		# CentOS/RHEL
		package_manager="yum"
	elif command -v apt-get &>/dev/null; then
		# Debian/Ubuntu
		package_manager="apt-get"
	else
		echo "Error: Unsupported Linux distribution."
		exit 1
	fi
}

install_prerequisites() {
	check_root

	# Install prerequisites
	$package_manager install -y ruby ruby-devel git jq

	echo "Prerequisites installed successfully."
}

install_neovim() {
	# Download Neovim app image
	curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage

	# Move the downloaded file to /usr/local/bin as nvim
	chmod +x nvim.appimage
	mv nvim.appimage /usr/local/bin/nvim

	# Add an alias for vi to use Neovim
	echo "alias vi='nvim'" >>~/.bashrc
	echo "alias vi='nvim'" >>~/.zshrc
	source "$HOME"/.bashrc

	echo "Neovim setup complete. You can now use 'nvim' or 'vi' to open Neovim."
}

install_node_18() {
	check_root

	# Install Node.js 18
	if [[ "$package_manager" == "apt-get" ]]; then
		$package_manager apt-get update
		$package_manager install -y ca-certificates curl gnupg
		mkdir -p /etc/apt/keyrings
		curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
		NODE_MAJOR=18
		echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
		$package_manager update
		$package_manager install nodejs -y

	elif [[ "$package_manager" == "yum" ]]; then
		$package_manager install https://rpm.nodesource.com/pub_18.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
		$package_manager install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1
	fi

	echo "Node.js version 18 installed successfully."
}

install_golang() {
	# Install Go
	if [[ "$package_manager" == "yum" ]]; then
		$package_manager install -y golang
	elif [[ "$package_manager" == "apt-get" ]]; then
		$package_manager install -y golang
	fi

	echo "Go installed successfully."
}

clone_and_setup_dotfiles() {
	# Directory to clone dotfiles repository
	dotfiles_dir="$HOME/dotfiles"

	# Check if dotfiles directory exists, remove it if it does
	if [[ -d "$dotfiles_dir" ]]; then
		echo "Dotfiles directory already exists. Removing it before cloning."
		rm -rf "$dotfiles_dir"
	fi

	# Clone the dotfiles repository
	git clone https://github.com/AshutoshPatole18/dotfiles.git "$dotfiles_dir"

	# Remove existing nvim configuration
	rm -rf "$HOME/.config/nvim"
	rm -rf "$HOME/.local/share/nvim/"

	# Move neovim configuration
	mkdir -pv "$HOME/.config/nvim"
	cp -r "$dotfiles_dir/nvim/." "$HOME/.config/nvim/"

	# Move zsh configuration
	cp -f "$dotfiles_dir/.zshrc" "$HOME/"
	cp -f "$dotfiles_dir/.p10k.zsh" "$HOME/"

	echo "Dotfiles setup completed."
}

install_ohmyzsh_powerlevel10k() {
	$package_manager install zsh -y

  rm -rf "$HOME/.oh-my-zsh/"
	# Install Oh My Zsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
	git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
	echo "Oh My Zsh and Powerlevel10k installed successfully. Please restart your terminal to apply changes."
}

install_extra_packages(){
  gem install colorls
}

main() {
	check_root
	detect_package_manager
	install_prerequisites
	install_neovim
	install_node_18
	install_golang
	clone_and_setup_dotfiles
	install_ohmyzsh_powerlevel10k
  install_extra_packages
}

main

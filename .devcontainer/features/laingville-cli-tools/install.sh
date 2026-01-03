#!/bin/bash
set -e

# Feature options (passed from devcontainer-feature.json)
INSTALL_JQ="${INSTALLJQ:-true}"
INSTALL_RIPGREP="${INSTALLRIPGREP:-true}"
INSTALL_FD="${INSTALLFD:-true}"
INSTALL_BAT="${INSTALLBAT:-true}"
INSTALL_FZF="${INSTALLFZF:-true}"
INSTALL_SHELLCHECK="${INSTALLSHELLCHECK:-true}"
INSTALL_SHFMT="${INSTALLSHFMT:-true}"
INSTALL_JUST="${INSTALLJUST:-true}"

echo "=========================================="
echo "Laingville CLI Tools Feature"
echo "=========================================="

# Detect OS
if [ -f /etc/os-release ]; then
	. /etc/os-release
	OS_ID="${ID}"
	OS_VERSION="${VERSION_ID}"
else
	echo "ERROR: Cannot detect OS (missing /etc/os-release)"
	exit 1
fi

echo "Detected OS: ${OS_ID} ${OS_VERSION}"

# Package manager detection and setup
install_packages_apt() {
	local packages=("$@")
	if [ ${#packages[@]} -eq 0 ]; then
		return 0
	fi

	export DEBIAN_FRONTEND=noninteractive
	apt-get update -y
	apt-get install -y --no-install-recommends "${packages[@]}"
	rm -rf /var/lib/apt/lists/*
}

install_packages_apk() {
	local packages=("$@")
	if [ ${#packages[@]} -eq 0 ]; then
		return 0
	fi

	apk add --no-cache "${packages[@]}"
}

# Build package list based on options
declare -a PACKAGES=()

case "${OS_ID}" in
ubuntu | debian)
	[ "${INSTALL_JQ}" = "true" ] && PACKAGES+=("jq")
	[ "${INSTALL_RIPGREP}" = "true" ] && PACKAGES+=("ripgrep")
	[ "${INSTALL_FD}" = "true" ] && PACKAGES+=("fd-find")
	[ "${INSTALL_BAT}" = "true" ] && PACKAGES+=("bat")
	[ "${INSTALL_FZF}" = "true" ] && PACKAGES+=("fzf")
	[ "${INSTALL_SHELLCHECK}" = "true" ] && PACKAGES+=("shellcheck")
	[ "${INSTALL_SHFMT}" = "true" ] && PACKAGES+=("shfmt")

	echo "Installing packages: ${PACKAGES[*]}"
	install_packages_apt "${PACKAGES[@]}"

	# Ubuntu/Debian binary name quirks
	if [ "${INSTALL_BAT}" = "true" ]; then
		ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
	fi
	if [ "${INSTALL_FD}" = "true" ]; then
		ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
	fi

	# just: Try apt first, fall back to installer script
	if [ "${INSTALL_JUST}" = "true" ]; then
		if apt-get install -y --no-install-recommends just 2>/dev/null; then
			echo "Installed just via apt"
		else
			echo "just not in apt, installing from GitHub releases..."
			curl -fsSL https://just.systems/install.sh | bash -s -- --to /usr/local/bin
		fi
		rm -rf /var/lib/apt/lists/*
	fi
	;;

alpine)
	[ "${INSTALL_JQ}" = "true" ] && PACKAGES+=("jq")
	[ "${INSTALL_RIPGREP}" = "true" ] && PACKAGES+=("ripgrep")
	[ "${INSTALL_FD}" = "true" ] && PACKAGES+=("fd")
	[ "${INSTALL_BAT}" = "true" ] && PACKAGES+=("bat")
	[ "${INSTALL_FZF}" = "true" ] && PACKAGES+=("fzf")
	[ "${INSTALL_SHELLCHECK}" = "true" ] && PACKAGES+=("shellcheck")
	[ "${INSTALL_SHFMT}" = "true" ] && PACKAGES+=("shfmt")
	[ "${INSTALL_JUST}" = "true" ] && PACKAGES+=("just")

	echo "Installing packages: ${PACKAGES[*]}"
	install_packages_apk "${PACKAGES[@]}"
	;;

fedora | rhel | centos | rocky | almalinux)
	[ "${INSTALL_JQ}" = "true" ] && PACKAGES+=("jq")
	[ "${INSTALL_RIPGREP}" = "true" ] && PACKAGES+=("ripgrep")
	[ "${INSTALL_FD}" = "true" ] && PACKAGES+=("fd-find")
	[ "${INSTALL_BAT}" = "true" ] && PACKAGES+=("bat")
	[ "${INSTALL_FZF}" = "true" ] && PACKAGES+=("fzf")
	[ "${INSTALL_SHELLCHECK}" = "true" ] && PACKAGES+=("ShellCheck")

	echo "Installing packages: ${PACKAGES[*]}"
	if command -v dnf &>/dev/null; then
		dnf install -y "${PACKAGES[@]}"
	else
		yum install -y "${PACKAGES[@]}"
	fi

	# shfmt and just often need manual install on RHEL-based
	if [ "${INSTALL_SHFMT}" = "true" ]; then
		echo "Installing shfmt from GitHub releases..."
		ARCH=$(uname -m)
		case "${ARCH}" in
		x86_64) SHFMT_ARCH="amd64" ;;
		aarch64) SHFMT_ARCH="arm64" ;;
		*)
			echo "Unsupported architecture for shfmt: ${ARCH}"
			exit 1
			;;
		esac
		curl -fsSL "https://github.com/mvdan/sh/releases/latest/download/shfmt_v3.8.0_linux_${SHFMT_ARCH}" -o /usr/local/bin/shfmt
		chmod +x /usr/local/bin/shfmt
	fi

	if [ "${INSTALL_JUST}" = "true" ]; then
		echo "Installing just from GitHub releases..."
		curl -fsSL https://just.systems/install.sh | bash -s -- --to /usr/local/bin
	fi
	;;

*)
	echo "WARNING: Unsupported OS '${OS_ID}'. Attempting generic install..."
	# Fall back to direct downloads for unsupported distros
	if [ "${INSTALL_JUST}" = "true" ]; then
		curl -fsSL https://just.systems/install.sh | bash -s -- --to /usr/local/bin
	fi
	;;
esac

echo ""
echo "=========================================="
echo "Installed tools:"
echo "=========================================="
command -v jq && jq --version || echo "jq: not installed"
command -v rg && rg --version | head -1 || echo "ripgrep: not installed"
command -v fd && fd --version || echo "fd: not installed"
command -v bat && bat --version || echo "bat: not installed"
command -v fzf && fzf --version || echo "fzf: not installed"
command -v shellcheck && shellcheck --version | head -2 || echo "shellcheck: not installed"
command -v shfmt && shfmt --version || echo "shfmt: not installed"
command -v just && just --version || echo "just: not installed"
echo "=========================================="
echo "Laingville CLI Tools installation complete"
echo "=========================================="

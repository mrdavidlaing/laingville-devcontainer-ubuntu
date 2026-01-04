#!/bin/bash
set -e

echo "=== Laingville CLI Tools ==="

if [ -f /etc/os-release ]; then
	. /etc/os-release
	if [ "${ID}" != "ubuntu" ]; then
		echo "ERROR: This feature only supports Ubuntu (detected: ${ID})"
		exit 1
	fi
	echo "Detected: ${ID} ${VERSION_ID}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SOURCE="${SCRIPT_DIR}/bin"

if [ ! -d "${BIN_SOURCE}" ]; then
	echo "ERROR: Binary directory not found: ${BIN_SOURCE}"
	exit 1
fi

echo "Installing binaries to /usr/local/bin..."

for bin in jq rg fd bat fzf shellcheck shfmt just; do
	if [ -f "${BIN_SOURCE}/${bin}" ]; then
		cp "${BIN_SOURCE}/${bin}" /usr/local/bin/
		chmod +x "/usr/local/bin/${bin}"
		echo "  ✓ ${bin}"
	else
		echo "  ✗ ${bin} (not found)"
		exit 1
	fi
done

LICENSE_SOURCE="${SCRIPT_DIR}/licenses"
LICENSE_DEST="/usr/local/share/licenses/laingville-cli-tools"

if [ -d "${LICENSE_SOURCE}" ]; then
	echo ""
	echo "Installing licenses to ${LICENSE_DEST}..."
	mkdir -p "${LICENSE_DEST}"
	cp "${LICENSE_SOURCE}"/*.LICENSE "${LICENSE_DEST}/" 2>/dev/null || true
	cp "${LICENSE_SOURCE}"/*.SOURCE_OFFER "${LICENSE_DEST}/" 2>/dev/null || true

	if [ -f "${SCRIPT_DIR}/THIRD_PARTY_NOTICES.md" ]; then
		cp "${SCRIPT_DIR}/THIRD_PARTY_NOTICES.md" "${LICENSE_DEST}/"
	fi

	echo "  ✓ Licenses installed"
	ls "${LICENSE_DEST}/"
else
	echo "WARNING: License directory not found, skipping license installation"
fi

echo ""
echo "=== Installed versions ==="
jq --version
rg --version | head -1
fd --version
bat --version
fzf --version
shellcheck --version | head -2
shfmt --version
just --version
echo "=== Done ==="

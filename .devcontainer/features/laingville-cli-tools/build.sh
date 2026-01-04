#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_NAME="laingville-cli-tools"

usage() {
	cat <<EOF
Usage: $(basename "$0") <command>

Commands:
    download    Download tool binaries to bin/
    validate    Validate feature files (JSON, shell syntax)
    package     Create feature tarball (runs download first)
    test        Run version checks on downloaded binaries
    clean       Remove bin/ directory and output files

Examples:
    ./build.sh download
    ./build.sh package
    ./build.sh test
EOF
	exit 1
}

download_binaries() {
	local bin_dir="${SCRIPT_DIR}/bin"
	mkdir -p "${bin_dir}"

	echo "=== Downloading pre-built binaries for Linux amd64 ==="

	echo "Downloading jq..."
	curl -fsSL "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64" \
		-o "${bin_dir}/jq"
	chmod +x "${bin_dir}/jq"

	echo "Downloading ripgrep..."
	curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz" |
		tar -xzf - --strip-components=1 -C "${bin_dir}" "ripgrep-14.1.1-x86_64-unknown-linux-musl/rg"

	echo "Downloading fd..."
	curl -fsSL "https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz" |
		tar -xzf - --strip-components=1 -C "${bin_dir}" "fd-v10.2.0-x86_64-unknown-linux-musl/fd"

	echo "Downloading bat..."
	curl -fsSL "https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-musl.tar.gz" |
		tar -xzf - --strip-components=1 -C "${bin_dir}" "bat-v0.24.0-x86_64-unknown-linux-musl/bat"

	echo "Downloading fzf..."
	curl -fsSL "https://github.com/junegunn/fzf/releases/download/v0.56.3/fzf-0.56.3-linux_amd64.tar.gz" |
		tar -xzf - -C "${bin_dir}" fzf

	echo "Downloading shellcheck..."
	curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz" |
		tar -xJf - --strip-components=1 -C "${bin_dir}" "shellcheck-v0.10.0/shellcheck"

	echo "Downloading shfmt..."
	curl -fsSL "https://github.com/mvdan/sh/releases/download/v3.10.0/shfmt_v3.10.0_linux_amd64" \
		-o "${bin_dir}/shfmt"
	chmod +x "${bin_dir}/shfmt"

	echo "Downloading just..."
	curl -fsSL "https://github.com/casey/just/releases/download/1.36.0/just-1.36.0-x86_64-unknown-linux-musl.tar.gz" |
		tar -xzf - -C "${bin_dir}" just

	echo ""
	echo "=== Downloaded binaries ==="
	ls -la "${bin_dir}"
}

validate_feature() {
	echo "=== Validating ${FEATURE_NAME} ==="

	if [ ! -f "${SCRIPT_DIR}/devcontainer-feature.json" ]; then
		echo "ERROR: Missing devcontainer-feature.json"
		exit 1
	fi

	if [ ! -f "${SCRIPT_DIR}/install.sh" ]; then
		echo "ERROR: Missing install.sh"
		exit 1
	fi

	python3 -c "import json; json.load(open('${SCRIPT_DIR}/devcontainer-feature.json'))"
	echo "✓ devcontainer-feature.json is valid JSON"

	bash -n "${SCRIPT_DIR}/install.sh"
	echo "✓ install.sh has valid bash syntax"

	if command -v shellcheck &>/dev/null; then
		shellcheck "${SCRIPT_DIR}/install.sh" || echo "⚠ shellcheck warnings (non-blocking)"
	fi

	echo "✓ Feature validation passed"
}

package_feature() {
	local output_dir="${SCRIPT_DIR}/output"
	mkdir -p "${output_dir}"

	if [ ! -d "${SCRIPT_DIR}/bin" ]; then
		echo "bin/ not found, downloading binaries first..."
		download_binaries
	fi

	echo "=== Packaging ${FEATURE_NAME} ==="
	tar -czf "${output_dir}/${FEATURE_NAME}.tgz" \
		-C "${SCRIPT_DIR}" \
		--exclude='output' \
		--exclude='build.sh' \
		.

	echo ""
	echo "=== Package contents ==="
	tar -tzf "${output_dir}/${FEATURE_NAME}.tgz"

	echo ""
	echo "=== Package size ==="
	du -h "${output_dir}/${FEATURE_NAME}.tgz"

	echo ""
	echo "Output: ${output_dir}/${FEATURE_NAME}.tgz"
}

test_binaries() {
	local bin_dir="${SCRIPT_DIR}/bin"

	if [ ! -d "${bin_dir}" ]; then
		echo "ERROR: bin/ directory not found. Run './build.sh download' first."
		exit 1
	fi

	echo "=== Testing binaries ==="
	local failed=0

	for tool in jq rg fd bat fzf shellcheck shfmt just; do
		if [ -f "${bin_dir}/${tool}" ]; then
			echo -n "${tool}: "
			"${bin_dir}/${tool}" --version 2>&1 | head -1
		else
			echo "${tool}: NOT FOUND"
			failed=1
		fi
	done

	if [ "${failed}" -eq 0 ]; then
		echo ""
		echo "✓ All binaries present and working"
	else
		echo ""
		echo "✗ Some binaries missing"
		exit 1
	fi
}

clean() {
	echo "=== Cleaning ==="
	rm -rf "${SCRIPT_DIR}/bin"
	rm -rf "${SCRIPT_DIR}/output"
	echo "✓ Cleaned bin/ and output/"
}

case "${1:-}" in
download)
	download_binaries
	;;
validate)
	validate_feature
	;;
package)
	package_feature
	;;
test)
	test_binaries
	;;
clean)
	clean
	;;
*)
	usage
	;;
esac

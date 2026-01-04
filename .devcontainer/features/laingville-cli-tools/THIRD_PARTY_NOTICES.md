# Third-Party Software Notices

This devcontainer feature (`laingville-cli-tools`) includes the following third-party software components. Each component is subject to its respective license terms.

## Summary

| Component   | Version | License        | Source Repository                          |
| ----------- | ------- | -------------- | ------------------------------------------ |
| jq          | 1.7.1   | MIT            | https://github.com/jqlang/jq               |
| ripgrep     | 14.1.1  | MIT/Unlicense  | https://github.com/BurntSushi/ripgrep      |
| fd          | 10.2.0  | MIT/Apache-2.0 | https://github.com/sharkdp/fd              |
| bat         | 0.24.0  | MIT/Apache-2.0 | https://github.com/sharkdp/bat             |
| fzf         | 0.56.3  | MIT            | https://github.com/junegunn/fzf            |
| shellcheck  | 0.10.0  | GPL-3.0        | https://github.com/koalaman/shellcheck     |
| shfmt       | 3.10.0  | BSD-3-Clause   | https://github.com/mvdan/sh                |
| just        | 1.36.0  | CC0-1.0        | https://github.com/casey/just              |

---

## Component Details

### jq (MIT License)

- **Version**: 1.7.1
- **Source**: https://github.com/jqlang/jq
- **Binary Source**: https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
- **License**: https://github.com/jqlang/jq/blob/master/COPYING

### ripgrep (MIT License / Unlicense)

- **Version**: 14.1.1
- **Source**: https://github.com/BurntSushi/ripgrep
- **Binary Source**: https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz
- **License**: https://github.com/BurntSushi/ripgrep/blob/master/LICENSE-MIT
- **Note**: Dual-licensed under MIT and Unlicense; we distribute under MIT terms.

### fd (MIT License / Apache-2.0)

- **Version**: 10.2.0
- **Source**: https://github.com/sharkdp/fd
- **Binary Source**: https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz
- **License**: https://github.com/sharkdp/fd/blob/master/LICENSE-MIT
- **Note**: Dual-licensed under MIT and Apache-2.0; we distribute under MIT terms.

### bat (MIT License / Apache-2.0)

- **Version**: 0.24.0
- **Source**: https://github.com/sharkdp/bat
- **Binary Source**: https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-musl.tar.gz
- **License**: https://github.com/sharkdp/bat/blob/master/LICENSE-MIT
- **Note**: Dual-licensed under MIT and Apache-2.0; we distribute under MIT terms.

### fzf (MIT License)

- **Version**: 0.56.3
- **Source**: https://github.com/junegunn/fzf
- **Binary Source**: https://github.com/junegunn/fzf/releases/download/v0.56.3/fzf-0.56.3-linux_amd64.tar.gz
- **License**: https://github.com/junegunn/fzf/blob/master/LICENSE

### shellcheck (GPL-3.0 License)

- **Version**: 0.10.0
- **Source**: https://github.com/koalaman/shellcheck
- **Binary Source**: https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz
- **License**: https://github.com/koalaman/shellcheck/blob/master/LICENSE

#### GPL-3.0 Source Code Offer

This distribution includes shellcheck, which is licensed under the GNU General Public License version 3 (GPL-3.0).

In accordance with Section 6 of the GPL-3.0, we hereby offer to provide the complete corresponding source code for shellcheck to any third party, upon request, for a period of three (3) years from the date of this distribution.

**To request source code**, contact: [Insert contact method - e.g., email, GitHub issue]

Alternatively, the source code is available directly from the upstream project:
- **Source Repository**: https://github.com/koalaman/shellcheck
- **Release Tag**: v0.10.0
- **Source Archive**: https://github.com/koalaman/shellcheck/archive/refs/tags/v0.10.0.tar.gz

### shfmt (BSD-3-Clause License)

- **Version**: 3.10.0
- **Source**: https://github.com/mvdan/sh
- **Binary Source**: https://github.com/mvdan/sh/releases/download/v3.10.0/shfmt_v3.10.0_linux_amd64
- **License**: https://github.com/mvdan/sh/blob/master/LICENSE

### just (CC0-1.0 / Public Domain)

- **Version**: 1.36.0
- **Source**: https://github.com/casey/just
- **Binary Source**: https://github.com/casey/just/releases/download/1.36.0/just-1.36.0-x86_64-unknown-linux-musl.tar.gz
- **License**: https://github.com/casey/just/blob/master/LICENSE
- **Note**: CC0-1.0 dedicates the work to the public domain. No attribution required.

---

## License Texts

Complete license texts for each component are bundled with this distribution in the `licenses/` directory and installed to `/usr/local/share/licenses/laingville-cli-tools/` in the container.

| File                     | Component(s)            |
| ------------------------ | ----------------------- |
| `jq.LICENSE`             | jq                      |
| `ripgrep.LICENSE`        | ripgrep                 |
| `fd.LICENSE`             | fd                      |
| `bat.LICENSE`            | bat                     |
| `fzf.LICENSE`            | fzf                     |
| `shellcheck.LICENSE`     | shellcheck              |
| `shellcheck.SOURCE_OFFER`| shellcheck (GPL offer)  |
| `shfmt.LICENSE`          | shfmt                   |
| `just.LICENSE`           | just                    |

---

## Obtaining Source Code

All components are open source. Source code can be obtained from the repositories listed above, or from the specific release archives:

```bash
# Example: Download shellcheck source
curl -L https://github.com/koalaman/shellcheck/archive/refs/tags/v0.10.0.tar.gz -o shellcheck-source.tar.gz
```

---

*Last updated: 2026-01-04*
*Feature version: 1.0.0*

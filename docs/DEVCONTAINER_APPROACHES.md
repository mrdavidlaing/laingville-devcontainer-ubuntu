# DevContainer Construction Approaches in Laingville

## Introduction

This document provides a technical analysis of the three distinct architectural approaches used in the `laingville-devcontainer-ubuntu` repository to build and manage development environments. 

As development teams move away from "it works on my machine" toward standardized, containerized environments, the choice of how tools are provisioned becomes critical. This choice impacts build reproducibility, security posture, supply chain integrity, and legal compliance.

In this repository, we demonstrate three paradigms:
1. **Approach A**: The "Monolithic Dockerfile" (Native Ubuntu Packages)
2. **Approach B**: The "Modular Feature" (Runtime Upstream Fetch)
3. **Approach C**: The "Pre-packaged Feature" (Publish-time Binary Bundling)

---

## 1. Overview of the Approaches

### Approach A: Custom Dockerfile with Ubuntu Packages
This is the "classic" container build approach. The `Dockerfile` at the repository root uses `ubuntu:25.10` as a base and relies exclusively on the official Ubuntu repositories (`apt-get`) for tool installation.

*   **Key File**: `Dockerfile`
*   **Strategy**: Strict adherence to OS-provided packages.
*   **Target**: High security and low maintenance for standard tools.

### Approach B: Microsoft Base Image + Official Features
This approach utilizes the DevContainer specification's "Features" property in `.devcontainer/devcontainer.json`. It starts with a Microsoft-maintained base image and layers on official features that fetch tools at runtime.

*   **Key File**: `.devcontainer/devcontainer.json`
*   **Strategy**: Delegate tool installation to community-maintained scripts.
*   **Target**: Ease of use and access to specific versions not yet in OS repos.

### Approach C: Custom Feature with Pre-packaged Binaries
This is a sophisticated supply-chain-conscious approach. We build a custom DevContainer Feature (`laingville-cli-tools`) where binaries are downloaded from GitHub releases at **publish time**, bundled into an OCI artifact, and merely copied into the container at runtime.

*   **Key Files**: `.devcontainer/features/laingville-cli-tools/`
*   **Strategy**: Bundle everything into the artifact; no network access required at devcontainer build time.
*   **Target**: Air-gapped support and total control over tool provenance.

---

## 2. Tool Provenance & Shipping Strategy

Provenance refers to the chronology of ownership, custody, or location of a software artifact. Understanding where your binaries come from is the foundation of a secure supply chain.

### Provenance Flow Diagram

```text
APPROACH A (Ubuntu Repo)
Upstream Project -> Ubuntu Maintainer -> Ubuntu Repo (Apt) -> Your Container

APPROACH B (Runtime Fetch)
Upstream Project -> GitHub/PPA -> Feature Script (Runtime) -> Your Container

APPROACH C (Pre-packaged)
Upstream Project -> GitHub Release -> build.sh (Publish Time) -> OCI Artifact -> Your Container
```

### shipping vs. Fetching
*   **Approach A (Shipped in Image)**: Tools like `jq` and `ripgrep` are baked into the image layers. When a developer pulls `ghcr.io/.../laingville-devcontainer`, the tools are already there.
*   **Approach B (Fetched at Runtime)**: The image is relatively slim. When the developer first opens the project in VS Code (or runs `devcontainer up`), the feature scripts execute `curl` or `apt-add-repository` to fetch Node, Python, and the GitHub CLI. **If the developer is offline or behind a strict proxy, this step will fail.**
*   **Approach C (Pre-packaged OCI)**: The tools are downloaded during the CI/CD pipeline (`publish-features.yml`). They are packaged into a `.tgz` and pushed to GHCR as an OCI layer. At runtime, the `install.sh` simply runs `cp`. This combines the modularity of Features with the air-gapped reliability of Approach A.

---

## 3. CVE Scanning & Patching Responsibility

Security scanning in this repo is handled by `security-scan.yml`, utilizing **Trivy** and **Grype** for vulnerability detection, and **Syft** for SBOM (Software Bill of Materials) generation.

| Aspect | Approach A | Approach B | Approach C |
| :--- | :--- | :--- | :--- |
| **Who patches CVEs?** | Canonical (Ubuntu Security) | Upstream Project / Microsoft | You (Manual Update) |
| **Scanning Coverage** | Full Container Scan | Base Image Only* | Feature-specific SBOM |
| **Patch Latency** | Tied to Ubuntu release cycle | Immediate (usually) | Manual (whenever you update `build.sh`) |
| **Update Mechanism** | `apt-get upgrade` | Re-build devcontainer | Re-publish feature |

*\*Note: Scanning Approach B is difficult because tools are fetched at runtime and may not exist in the static image scan performed by CI.*

### Supply Chain Verification
Approach C goes a step further in security. The `publish-features.yml` workflow:
1.  Downloads binaries.
2.  Signs the OCI artifact using **Cosign** (Sigstore).
3.  Generates an **SPDX SBOM** using **Syft**.
4.  Attaches the SBOM as an attestation to the image.

This allows consumers to verify that the `jq` binary inside the feature is exactly what was downloaded by the CI process and hasn't been tampered with.

---

## 4. License Compliance: The "Distribution" Factor

This is often the most overlooked aspect of devcontainer construction. Open source licenses like the **GPL (General Public License)** or **MPL (Mozilla Public License)** have specific requirements that trigger upon **distribution**.

### When are you a "Distributor"?

**Key principle**: If you publish a container image containing a binary, you are distributing that binary. The source of the binary (Ubuntu repos vs GitHub releases) does not change this fact.

*   **Approach A**: **YOU ARE A DISTRIBUTOR.** When you `apt-get install shellcheck` and then `docker push` the image, you are distributing shellcheck. However, Ubuntu packages are designed to facilitate compliant redistribution—license files are installed to `/usr/share/doc/*/copyright`, and source code is available via `apt-get source`.

*   **Approach B**: **You are NOT a distributor of the tools.** Your published artifact (the devcontainer.json) contains no binaries—only a configuration that tells the user's machine where to download the tools. The user (or their machine) fetches software directly from the source. This is the safest approach from a legal liability perspective.

*   **Approach C**: **YOU ARE A DISTRIBUTOR.** By downloading `shellcheck` (GPL-3.0) and packaging it into your `laingville-cli-tools` feature on GHCR, you are distributing that software. Unlike Approach A, the raw binaries from GitHub releases do not include license files or source code pointers—you must handle this yourself.

### Compliance Burden Comparison

| Aspect | Approach A (apt packages) | Approach B (runtime fetch) | Approach C (pre-packaged) |
| :--- | :--- | :--- | :--- |
| **Are you a distributor?** | Yes | **No** | Yes |
| **License files included?** | Yes (`/usr/share/doc/*/copyright`) | N/A | No (must add manually) |
| **Source code available?** | Yes (`apt-get source`) | N/A | No (must document links) |
| **Compliance effort** | Low (Ubuntu did the work) | None | High (you do the work) |

### License Implications for Tools in This Repo

| Tool | License | Approach A | Approach C |
| :--- | :--- | :--- | :--- |
| **jq** | MIT | Compliant via apt | Include LICENSE file |
| **ripgrep** | MIT / Unlicense | Compliant via apt | Include LICENSE file |
| **fd / bat** | MIT / Apache 2.0 | Compliant via apt | Include LICENSE file |
| **shellcheck** | **GPL-3.0** | Compliant via apt | **Must provide source access** |
| **shfmt** | BSD-3-Clause | Compliant via apt | Include LICENSE file |
| **just** | CC0-1.0 | Compliant via apt | Public domain (no action needed) |

### GPL Compliance for Approach C

If you distribute GPL-licensed tools like `shellcheck` via Approach C, you must either:
1. Include the source code in your distribution, OR
2. Provide a written offer (valid for 3 years) to provide source code, OR
3. Provide a link to the upstream source (if you received the binary with such a link)

For this repository, we rely on option 3: the `build.sh` script documents the exact GitHub release URLs from which binaries were downloaded, and those releases link to the source repositories.

### Copyleft and Aggregation: When Does GPL "Infect" Your Code?

A common concern: "If I ship my proprietary software in a container alongside GPL tools, do I need to open-source my software?"

**The short answer: No, mere aggregation does not trigger copyleft.**

The GPL distinguishes between:
- **Derivative works** (combined/linked) → GPL applies to the whole
- **Mere aggregation** (separate programs on same medium) → GPL applies only to the GPL component

#### Scenario 1: Proprietary Tool Executes GPL Binary

```
┌─────────────────────────────────────────────────────┐
│ Container                                           │
│  ┌──────────────────┐      ┌───────────────────┐   │
│  │ Your Proprietary │ exec │ shellcheck        │   │
│  │ Tool             │ ───> │ (GPL-3.0)         │   │
│  └──────────────────┘      └───────────────────┘   │
│         │                           │               │
│         │ stdout/stderr             │               │
│         <───────────────────────────┘               │
└─────────────────────────────────────────────────────┘

Result: MERE AGGREGATION - Your tool remains proprietary
```

Your proprietary tool can:
- Call `shellcheck` via subprocess/exec
- Parse its stdout/stderr output
- Ship in the same container

This is no different than calling `grep` or `bash`. The GPL FAQ explicitly states that "mere aggregation... has no effect on the licensing of either work."

#### Scenario 2: Python Tool Imports a GPL Library

```
┌─────────────────────────────────────────────────────┐
│ Python Runtime                                      │
│  ┌──────────────────┐                               │
│  │ your_tool.py     │                               │
│  │                  │                               │
│  │ import gpl_lib   │ ←── Creates combined work     │
│  │ gpl_lib.func()   │     at runtime                │
│  └──────────────────┘                               │
│           │                                         │
│           ▼                                         │
│  ┌──────────────────┐                               │
│  │ gpl_lib (GPL)    │                               │
│  └──────────────────┘                               │
└─────────────────────────────────────────────────────┘

Result: DERIVATIVE WORK - Your tool must be GPL-compatible
```

**This is different.** When your Python code does `import gpl_library`, it creates a combined work at runtime. The consensus interpretation (though not court-tested for Python specifically):

- `import` is analogous to dynamic linking
- Your code + the GPL library form a single program
- **Your code must be licensed under GPL or a GPL-compatible license**

#### Scenario 3: Python Tool with GPL Library as Transitive Dependency

```
your_tool.py
    └── imports: useful_lib (MIT)
                    └── imports: gpl_lib (GPL)
```

**Still a derivative work.** The GPL applies transitively. Even if you don't directly import the GPL library, if it's loaded into the same Python runtime as part of your dependency chain, the combined work is subject to GPL.

#### Summary: Linking vs. Execution

| Interaction Type | Example | Copyleft Triggered? |
| :--- | :--- | :--- |
| Execute as subprocess | `subprocess.run(['shellcheck', 'script.sh'])` | **No** |
| Parse output | Read stdout from GPL tool | **No** |
| Import library | `import gpl_library` | **Yes** |
| Transitive dependency | Your dep imports GPL lib | **Yes** |
| Link C library | `gcc -lgpl_lib` | **Yes** |

#### Escape Hatches

If you need to use a copyleft library without open-sourcing your code:

1. **LGPL (Lesser GPL)**: Specifically designed to allow linking without copyleft. If the library is LGPL (e.g., `GNU Readline` alternatives), you can import it freely.

2. **GPL with Classpath Exception**: Common in Java ecosystem (e.g., OpenJDK). Allows linking without triggering copyleft.

3. **Process isolation**: Instead of importing a GPL library, wrap it in a microservice or CLI tool and communicate via IPC/HTTP. This maintains the "separate programs" distinction.

4. **Alternative libraries**: Often there are permissively-licensed alternatives (MIT, Apache 2.0, BSD) that provide similar functionality.

#### Practical Guidance for This Repository

| If your proprietary tool... | License obligation |
| :--- | :--- |
| Ships in same container as shellcheck | None (aggregation) |
| Calls shellcheck via subprocess | None (aggregation) |
| Imports a GPL Python library | **Must be GPL-compatible** |
| Imports an LGPL Python library | None (LGPL permits linking) |
| Has GPL library as transitive dep | **Must be GPL-compatible** |

---

## 5. Comparison & Trade-offs Summary

| Feature | Approach A (Dockerfile) | Approach B (Official Features) | Approach C (Custom Pre-packaged) |
| :--- | :--- | :--- | :--- |
| **Build Reproducibility** | High (if pinned) | Low (runtime fetches latest) | High (version pinned in CI) |
| **Offline Support** | Excellent | None (requires internet) | Excellent |
| **Tool Freshness** | Slow (OS Repo speed) | Fast (Direct from source) | Fast (Manual control) |
| **SBOM Completeness** | Excellent | Poor (runtime invisible) | Excellent (attestation based) |
| **Distribution?** | Yes | **No** | Yes |
| **License Compliance Effort** | Low (apt includes licenses) | None (not distributing) | High (manual license handling) |
| **Ease of Use** | Moderate | Very Easy | High Effort (Maintenance) |

---

## 6. Approach C License Compliance Implementation

This repository implements comprehensive license compliance for Approach C (pre-packaged binaries). Here's how we address each requirement:

### Compliance Artifacts

| Artifact | Location | Purpose |
| :--- | :--- | :--- |
| `THIRD_PARTY_NOTICES.md` | Feature root | Human-readable summary of all licenses, versions, source URLs |
| `licenses/*.LICENSE` | Downloaded at build | Full license texts for each tool |
| `licenses/shellcheck.SOURCE_OFFER` | Feature root | GPL-3.0 written offer with source links |
| SBOM attestation | Attached to OCI image | Machine-readable license data (SPDX format) |

### Build-time License Collection

The `build.sh` script downloads LICENSE files alongside binaries:

```bash
./build.sh download    # Downloads binaries AND licenses
./build.sh package     # Bundles everything into feature tarball
```

License files are fetched from the exact release tags matching the binary versions, ensuring version consistency.

### Runtime License Installation

The `install.sh` script installs licenses to a standard location:

```
/usr/local/share/licenses/laingville-cli-tools/
├── THIRD_PARTY_NOTICES.md
├── jq.LICENSE
├── ripgrep.LICENSE
├── fd.LICENSE
├── bat.LICENSE
├── fzf.LICENSE
├── shellcheck.LICENSE
├── shellcheck.SOURCE_OFFER    # GPL written offer
├── shfmt.LICENSE
└── just.LICENSE
```

### SBOM with License Information

The `publish-features.yml` workflow generates an SPDX SBOM with license detection enabled:

```bash
syft dir:"${FEATURE_DIR}" --catalogers all -o spdx-json > sbom.spdx.json
```

The SBOM is cryptographically attested to the OCI image using Cosign, providing:
- Machine-readable license inventory
- Tamper-evident audit trail
- Integration with vulnerability scanners that consume SPDX

### GPL-3.0 Compliance (shellcheck)

For shellcheck specifically, we satisfy GPL-3.0 Section 6 through:

1. **Pass-through link**: The binary was obtained from GitHub releases, which link to source
2. **Written offer**: `shellcheck.SOURCE_OFFER` provides explicit source availability notice
3. **Full license text**: `shellcheck.LICENSE` contains the complete GPL-3.0 text

### SBOM Coverage: Why Go Dependencies But Not Rust?

Our SBOM includes **22 packages**:
- 8 top-level binaries we distribute (jq, ripgrep, fd, bat, fzf, shellcheck, shfmt, just)
- 11 Go module dependencies (auto-detected by Syft)
- 2 Go stdlib entries
- 1 feature directory entry

**Key observation**: Syft automatically detects dependency trees for Go binaries (fzf, shfmt) but not for Rust binaries (ripgrep, fd, bat, just) or Haskell binaries (shellcheck).

#### Why This Difference?

**Go embeds build metadata in every binary by default:**

Go 1.18+ includes a `.go.buildinfo` ELF section in compiled binaries containing:
- Module path and version
- All dependencies with exact versions
- VCS information (git commit, timestamp)

```bash
# You can extract this from any Go binary:
go version -m ./fzf
# Output:
#   path    github.com/junegunn/fzf
#   dep     github.com/mattn/go-isatty  v0.0.20
#   dep     golang.org/x/term            v0.25.0
#   ...
```

Syft reads this section using standard ELF parsing—**no source code needed**.

**Rust does NOT embed dependency metadata:**

When `cargo build --release` compiles a Rust binary, it produces stripped machine code with **no embedded information** about dependencies from `Cargo.lock`. To generate a complete SBOM for Rust binaries, you need:
1. Access to the source repository
2. Parse `Cargo.lock` or `Cargo.toml`
3. Trace transitive dependencies

This is a **philosophical difference** between the ecosystems:

| Aspect | Go | Rust |
| :--- | :--- | :--- |
| Philosophy | "Know thy build" - reproducibility first | "Minimal runtime" - ship only what runs |
| Binary size | +1-2 KB for metadata | No overhead |
| SBOM from binary? | ✓ Yes (automatic) | ✗ No (need source) |
| Privacy | Exposes build environment details | No metadata leakage |
| Debug production | Can see exact dependency versions | Need external records |

#### Our Hybrid Approach

Since we distribute **pre-built binaries** without source:

1. **Automatic detection** (Syft): Go binaries → full dependency tree
2. **Manual enrichment** (`sbom-enrichment.json`): Rust/Haskell/C binaries → top-level packages only

**For license compliance**, this is usually sufficient because:
- We document the top-level binary (ripgrep, fd, bat)
- Their Rust dependencies are statically linked and unmodified
- If we needed full transitive dependencies, we'd need to download source repos and parse lock files during CI

**Final SBOM coverage**: 20 of 22 packages have licenses (91%), with only Go stdlib and the feature directory itself remaining as NOASSERTION.

---

## 7. Conclusion: Which approach to choose?

*   Choose **Approach A** when security and stability are paramount, and you can live with the versions provided by the OS (e.g., Node 20.x on Ubuntu 25.10). It is the most "production-like" environment.
*   Choose **Approach B** for rapid prototyping, individual developer environments, or when you need the absolute latest version of a tool (e.g., Python 3.13) that hasn't made it into the OS repos yet.
*   Choose **Approach C** for enterprise environments where build reproducibility is non-negotiable, air-gapped support is required, or you need to strictly audit the supply chain using tools like Cosign and Syft.

By providing all three patterns in this repository, Laingville enables developers to select the strategy that best fits their specific constraints regarding security, connectivity, and compliance.

---
*Referenced files:*
- `Dockerfile`
- `.devcontainer/devcontainer.json`
- `.devcontainer/features/laingville-cli-tools/build.sh`
- `.devcontainer/features/laingville-cli-tools/install.sh`
- `.devcontainer/features/laingville-cli-tools/THIRD_PARTY_NOTICES.md`
- `.devcontainer/features/laingville-cli-tools/shellcheck.SOURCE_OFFER.template`
- `.github/workflows/security-scan.yml`
- `.github/workflows/publish-features.yml`

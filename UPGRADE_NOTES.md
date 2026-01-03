# Ubuntu 24.04 → 25.10 Upgrade Notes

**Date:** January 2026  
**Status:** Completed

## Summary

Upgraded base container image from Ubuntu 24.04 LTS to Ubuntu 25.10 (Questing Quokka).

## Changes Made

| Component | Before | After | Notes |
|-----------|--------|-------|-------|
| Base Image | ubuntu:24.04 LTS | ubuntu:25.10 | Interim release, 9 months support |
| Node.js | 22.x LTS | 20.x LTS | Ubuntu 25.10 repos constraint |
| npm | 11.x | 9.2.0 | From Ubuntu repos (bundled) |
| Python | 3.10.x | 3.13.7 | Latest in Ubuntu 25.10 |
| Support Window | 5 years | 9 months | Until July 1, 2026 |

## Rationale

Ubuntu 24.04 LTS reached a maturity plateau. Ubuntu 25.10 provides:
- Latest security patches
- Improved container build performance
- Updated system libraries and tools
- Python 3.13 ecosystem

**Node.js Version Change (22.x → 20.x):**  
Ubuntu 25.10 repositories do not provide Node.js 22.x. However, Node 20.x is still LTS (maintenance until April 30, 2026, 4 months into Ubuntu 25.10's support lifecycle).

This is acceptable because:
1. Node 20.x is LTS with security updates through April 2026
2. npm 9.2.0 from Ubuntu 25.10 repos includes CVE-safe dependencies
3. All 5 container images build and test successfully
4. No breaking changes to applications running Node 20.x

## Migration Timeline

| Date | Event | Action |
|------|-------|--------|
| 2026-01-03 | Upgrade applied | Dockerfile, CI configs, tests updated |
| 2026-01-03 | Images published to GHCR | amd64 + arm64 multi-arch manifests |
| 2026-04-30 | Node 20.x LTS EOL | Plan Node upgrade (20.x → 24.x or later) |
| 2026-07-01 | Ubuntu 25.10 EOL | Plan migration to Ubuntu 26.04 LTS |

## What's Affected

### Container Images (5 targets, all updated)
1. `laingville-devcontainer` – Bash/shell development tools
2. `example-node-devcontainer` – Node.js 20.x + dev tools
3. `example-node-runtime` – Node.js 20.x minimal runtime
4. `example-python-devcontainer` – Python 3.13 + dev tools
5. `example-python-runtime` – Python 3.13 minimal runtime

### Testing & Validation
- All existing test scripts pass with new versions
- Node environment test validates npm glob safety
- Container startup tests confirm functionality
- Trivy/Grype security scans run in CI

### No Changes Required For
- CI/CD runner OS (ubuntu-24.04 and ubuntu-24.04-arm still work fine; they just run docker buildx to build ubuntu:25.10 images)
- GitHub Actions workflows
- Container test scripts
- Local build commands (docker buildx compatible)

## Future Planning

### Short-term (Next 6 months)
- Monitor Ubuntu 25.10 security advisories
- Watch for Node 20.x LTS end-of-life notices
- Plan Node 20.x → 24.x upgrade

### Medium-term (April 2026)
- Evaluate Node.js 24.x LTS readiness (if released)
- Plan Node 20.x → 24.x upgrade before April 30, 2026 EOL

### Long-term (July 2026)
- Plan migration to Ubuntu 26.04 LTS when released (expected April 2026)
- Ubuntu 26.04 LTS is expected to provide Node.js 22.x or 24.x
- Update to Ubuntu 26.04 LTS for 5-year support window

## Rollback Procedure

If critical issues discovered:

```bash
# Revert Dockerfile
git revert <commit-sha>

# Update ARG UBUNTU_IMAGE back to ubuntu:24.04
# Push to main; CI automatically rebuilds images
docker pull ghcr.io/mrdavidlaing/laingville-devcontainer-ubuntu/laingville-devcontainer:latest
docker inspect <image> # Verify version
```

## Verification Checklist

- [x] Dockerfile updated (`ubuntu:24.04` → `ubuntu:25.10`)
- [x] Node.js 20.x, npm 9.2.0 confirmed in Ubuntu 25.10 repos
- [x] Python 3.13.7 confirmed available
- [x] All 5 container images build successfully
- [x] Container startup tests pass
- [x] Version invariants documented
- [x] README.md updated
- [x] CI/CD workflows validated (no changes needed)
- [x] Images published to GHCR with multi-arch support
- [x] Security scans (Trivy/Grype) executed

## References

- **Ubuntu 25.10:** https://releases.ubuntu.com/25.10/
- **Node.js 20.x LTS:** https://nodejs.org/en/about/releases/
- **Ubuntu Release Cycle:** https://ubuntu.com/about/release-cycle
- **CVE-2025-64756 (glob):** Checked; npm 9.2.0 from Ubuntu 25.10 is safe

## Contact

For questions about this upgrade, refer to the Laingville infrastructure team or check the GitHub issue/PR that implemented this change.

# laingville-devcontainer-ubuntu

Ubuntu-based devcontainer images for Laingville, intended to be a **side-by-side comparison** with the Nix-built images in `laingville/infra`.

## Images

Published to GHCR as:

- `ghcr.io/mrdavidlaing/laingville-devcontainer-ubuntu/laingville-devcontainer:latest`
- `ghcr.io/mrdavidlaing/laingville-devcontainer-ubuntu/example-node-devcontainer:latest`
- `ghcr.io/mrdavidlaing/laingville-devcontainer-ubuntu/example-node-runtime:latest`
- `ghcr.io/mrdavidlaing/laingville-devcontainer-ubuntu/example-python-devcontainer:latest`
- `ghcr.io/mrdavidlaing/laingville-devcontainer-ubuntu/example-python-runtime:latest`

## Local build

```bash
docker buildx build --load --target laingville-devcontainer -t laingville-devcontainer:local .
docker run --rm -it laingville-devcontainer:local bash
```

## Run tests locally

```bash
./tests/run-container-tests.sh
./tests/run-container-tests.sh node
```

## Design notes

- **No Nix inside containers**: intentionally Ubuntu-native.
- **Node environment**: Ubuntu 25.10 provides `Node 20.x` and `npm 9.2.0` from upstream packages. Version compatibility tested; plan upgrade to Ubuntu 26.04 LTS (April 2026) for Node 22.x.

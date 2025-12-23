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
- **Node invariant parity**: uses the same Node environment test as Laingville (`Node 22.x`, `npm 11.x`, `glob` not vulnerable).

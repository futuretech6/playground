# Playground

Playground is a Docker-based development environment preloaded with popular development tools and language support, including C/C++, Rust, Python, Go, and more. It supports multi-architecture builds (amd64 and arm64) and automates builds and releases using GitHub Actions.

## Features

- **Multi-language Support**: Pre-installed environments for C/C++, Rust, Python, Go and more.
- **User Isolation**: Dynamically adjusts container users and permissions via `entrypoint.sh`.
- **Multi-architecture Support**: Builds images for both amd64 and arm64 architectures.
- **Automated Builds**: Scheduled and triggered builds using GitHub Actions.
- **Efficient Builds**: Leverages Docker BuildKit caching for faster builds.

## Quick Start

### Pull the Image from Docker Hub

Run the image directly from Docker Hub:

```bash
# play around
docker run --rm -it futuretech6/playground

# run with workspace mounted
docker run --rm -it -v .:/playground futuretech6/playground
```

### Build the Image Locally

You can build the image locally using the following command:

```bash
docker build --tag playground .
```

### Build with Proxy (Optional)

If you need to build the image using a proxy, you can use the following command:

```bash
docker build \
    --build-arg http_proxy=${PROXY} \
    --build-arg https_proxy=${PROXY} \
    --network=host \
    --tag playground \
    --file $< \
    .
```

## GitHub Actions Automation

This project uses GitHub Actions to automate image builds and releases. The configuration file is located at [`.github/workflows/build-image.yaml`](.github/workflows/build-image.yaml). Key features include:

1. **Multi-architecture Builds**: Builds images for amd64 and arm64 using `buildx`.
2. **Image Manifest Creation**: Combines multi-architecture images into a single multi-platform image.
3. **Scheduled Builds**: Automatically triggers builds every Monday.

## Development Environment

The image includes the following tools and environments:

- **System Tools**: `wget`, `curl`, `git`, `vim`, `sudo`, and more.
- **Programming Languages**:
  - C/C++ (with `gcc`, `g++`)
  - Go (installed via official binaries)
  - Rust (installed via `rustup`)
  - Python 3 (with `pip`, `uv` and `venv` support)
- **Additional Tools**:
  - `starship` (cross-platform terminal prompt)

## Contribution Guidelines

We welcome contributions to improve this project. Please follow these steps before submitting an Issue or Pull Request:

1. Ensure your code is well-formatted.
2. Test your changes to verify they work as expected.
3. Provide detailed commit messages.

## License

This project is licensed under the [MIT License](LICENSE).

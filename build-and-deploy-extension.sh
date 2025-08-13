#!/bin/bash

set -e

# Configuration
EXTENSION_NAME="i915-sriov-driver"
REGISTRY="ghcr.io"
USERNAME="ojsef39"
TALOS_VERSION="v1.10.6"
KERNEL_VERSION="v1.10.0-32-g6fb65d0"
TALOS_BASE_IMAGE_FACTORY_SHA="d248e6fc0eb8fde85021d68c2677360cb6ce56995f5115eb1fb483b7c6f9ebb5"
PLATFORM="linux/amd64"

# Image names - need to use the kernel we built with the module
KERNEL_IMAGE="${REGISTRY}/${USERNAME}/kernel:${KERNEL_VERSION}"
EXTENSION_IMAGE="${REGISTRY}/${USERNAME}/${EXTENSION_NAME}:${TALOS_VERSION}"
INSTALLER_IMAGE="${REGISTRY}/${USERNAME}/installer-${EXTENSION_NAME}:${TALOS_VERSION}"

echo "=== Building Custom Installer with Extension ==="
echo "Base Image: factory.talos.dev/installer/${TALOS_BASE_IMAGE_FACTORY_SHA}:${TALOS_VERSION}"
echo "Extension Image: ${EXTENSION_IMAGE}"
echo "Installer Image: ${INSTALLER_IMAGE}"
echo

# Step 1: Build the extension container
echo "Step 1: Building extension container..."
make ${EXTENSION_NAME} \
  PLATFORM=${PLATFORM} \
  PUSH=true \
  REGISTRY=${REGISTRY} \
  USERNAME=${USERNAME} \
  TAG=${TALOS_VERSION} \
  PKGS_PREFIX=${REGISTRY}/${USERNAME} \
  PKGS=${KERNEL_VERSION}

echo "✅ Extension built and pushed: ${EXTENSION_IMAGE}"
echo

# Step 2: Create installer image with extension
echo "Step 2: Creating installer image with extensions and kernel args..."
mkdir -p _out

docker run -t --rm -v "${PWD}/_out":/out \
  ghcr.io/siderolabs/imager:${TALOS_VERSION} installer \
  --arch amd64 \
  --extra-kernel-arg i915.enable_guc=3 \
  --extra-kernel-arg intel_iommu=on \
  --extra-kernel-arg module_blacklist=xe \
  --base-installer-image factory.talos.dev/installer/${TALOS_BASE_IMAGE_FACTORY_SHA}:${TALOS_VERSION} \
  --system-extension-image ${EXTENSION_IMAGE}

echo "✅ Installer created"
echo

# Step 3: Load, tag, and push the installer
echo "Step 3: Loading and pushing installer image..."

LOADED_IMAGE=$(docker load -i ./_out/installer-amd64.tar | grep "Loaded image:" | cut -d' ' -f3)
echo "Loaded image: ${LOADED_IMAGE}"

# Tag with our name
docker tag ${LOADED_IMAGE} ${INSTALLER_IMAGE}

# Push the custom installer
docker push ${INSTALLER_IMAGE}

echo "✅ Custom installer pushed: ${INSTALLER_IMAGE}"
echo
echo "=== DONE ==="
echo "Custom installer image: ${INSTALLER_IMAGE}"

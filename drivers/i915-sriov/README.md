# i915-sriov-driver extension

This extension provides the Intel i915 SR-IOV DKMS driver for Talos Linux, enabling GPU virtualization support for Intel integrated graphics.

## Installation

See [Installing Extensions](https://github.com/siderolabs/extensions#installing-extensions).

## Usage

This extension enables SR-IOV (Single Root I/O Virtualization) functionality for Intel integrated GPUs. To use this driver, you need to:

1. **Enable required kernel parameters** in your machine configuration:
   ```yaml
   machine:
     kernel:
       args:
         - i915.enable_guc=3
         - module_blacklist=xe
   ```

2. **Load the kernel modules** by adding them to your machine configuration:
   ```yaml
   machine:
     kernel:
       modules:
         - name: i915
         - name: kvmgt
   ```

## Requirements

- Intel CPU with integrated graphics that supports SR-IOV
- Compatible kernel version (6.8-6.16)
- Host system must have SR-IOV enabled in BIOS/UEFI

## Verifying

You can verify the modules are loaded by checking `/proc/modules`:

```bash
❯ talosctl -n <node-ip> read /proc/modules | grep -E "(i915|kvmgt)"
```

You should see both `i915` and `kvmgt` modules listed as "Live".

To check for SR-IOV Virtual Functions:
```bash
❯ talosctl -n <node-ip> read /sys/class/drm/card0/device/sriov_numvfs
```

## Troubleshooting

If the modules fail to load, check:
- Kernel parameters are correctly set
- Intel integrated graphics supports SR-IOV
- No conflicting drivers (xe driver should be blacklisted)

Check kernel logs for more details:
```bash
❯ talosctl -n <node-ip> dmesg | grep -E "(i915|sriov|gvt)"
```
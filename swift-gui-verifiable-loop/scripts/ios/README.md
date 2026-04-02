# iOS simulator helper scripts

This directory contains helper scripts for repeatable **iOS simulator** runs.

- `simctl_prepare.sh` can erase/boot/shutdown a simulator by UDID.

The core `scripts/ui/ui_loop.sh` orchestration is platform-agnostic; these helpers exist only for workflows that involve iOS simulators.

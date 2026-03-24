# iOS Simulator determinism (devices, permissions, and artifacts)

This skill targets iOS **18** and **26** via the iOS Simulator. When specifying destinations, you will commonly use `OS=18.0` or `OS=26.0`.

## Pin the simulator destination

To avoid “it worked on my machine” drift:

- Prefer an explicit `-destination` that includes `OS=`.
- For strict repeatability (especially in CI), prefer a simulator **UDID** over only a device name.

Enumerate available devices and runtimes:

```bash
xcrun simctl list devices
```

## Start from a known simulator state

Common options:

- Shutdown → erase → boot the same simulator UDID before the run.
- Reuse a pre-provisioned simulator if you have strong evidence it remains stable.

Helper:

```bash
scripts/ios/simctl_prepare.sh --udid <UDID> --shutdown --erase --boot
```

## Permissions (privacy) without clicking system prompts

Where possible, pre-grant simulator permissions before launching the app under test:

```bash
# Reset simulator privacy state
scripts/ios/simctl_privacy.sh --udid <UDID> reset all

# Grant permissions for a bundle id
scripts/ios/simctl_privacy.sh --udid <UDID> grant camera com.example.MyApp
scripts/ios/simctl_privacy.sh --udid <UDID> grant location-always com.example.MyApp
```

Notes:

- `simctl privacy` does not support every permission type on every iOS version.
- Some prompts (for example, tracking/ATT) may still require UI-interruption handling in UI tests.

## Simulator screenshots and videos

When you need extra evidence outside of `.xcresult` attachments:

```bash
xcrun simctl io <UDID> screenshot ./artifacts/sim_screenshot.png
xcrun simctl io <UDID> recordVideo ./artifacts/sim_video.mp4
# Stop recording with Ctrl-C
```

# Keyboard Backlight Idle Auto-Off

An [Omarchy](https://omarchy.org/) Quattro shell service that turns off the
keyboard backlight after a configurable period without keyboard or pointer
input, then restores the saved brightness when input resumes.

The service ignores application idle inhibitors by default, so keyboard
lighting still turns off while watching video. It does not change screensaver,
lock, display-power, or suspend timings.

## Requirements

- Omarchy with the Quattro shell plugin runtime
- A keyboard backlight supported by `brightnessctl`

There are no installers, background services, remote builds, or privileged setup
steps. The plugin runs inside the existing unsandboxed `omarchy-shell` process
with the current user's permissions. Its bundled helper uses `brightnessctl`
and `flock`, both provided by Omarchy.

The helper saves the original brightness under `$XDG_RUNTIME_DIR` before turning
the keyboard light off. Repeated idle events, shell reloads, and suspend/resume
cannot overwrite that saved value with zero. The state lasts for the login
session and is removed after a successful restore.

If you turn the backlight off yourself before the idle timeout, later mouse
activity leaves it off.

## Install

```sh
omarchy plugin add https://github.com/andrewf403/omarchy-keyboard-idle.git --enable
```

No shell restart or manual configuration is required. A fresh installation
uses the defaults listed below.

## Usage

The service starts when the plugin is enabled. Inspect its current state with:

```sh
omarchy shell andrewf.keyboard-idle status
```

## Configure

Configure the service through Omarchy shell IPC:

```sh
omarchy shell andrewf.keyboard-idle setTimeout 30
omarchy shell andrewf.keyboard-idle setEnabled false
omarchy shell andrewf.keyboard-idle setRespectInhibitors true
```

Boolean setters accept `true`/`false`, `on`/`off`, `yes`/`no`, and `1`/`0`.
Changes are written as inline overrides on the plugin entry in
`~/.config/omarchy/shell.json`, hot-reload immediately, and survive shell
restarts.

All settings are optional. A plugin entry with every default shown looks like:

```json
{
  "id": "andrewf.keyboard-idle",
  "timeout": 10,
  "enabled": true,
  "respectInhibitors": false
}
```

| Setting | Default | Description |
| --- | --- | --- |
| `timeout` | `10` | Positive integer seconds before the backlight turns off |
| `enabled` | `true` | Whether the keyboard idle monitor is active |
| `respectInhibitors` | `false` | Whether media and other idle inhibitors keep the backlight on |

Unchanged values do not need to appear in `shell.json`.

## Remove

```sh
bash ~/.config/omarchy/plugins/andrewf.keyboard-idle/keyboard-idle-control restore
omarchy plugin remove andrewf.keyboard-idle
```

Restore the backlight before removing the plugin if it is currently idle.

## Development

Validate the repository and QML before publishing changes:

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" Service.qml
bash tests/keyboard-idle-control.sh
```

## License

[MIT](LICENSE)

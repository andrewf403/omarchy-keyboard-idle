# Keyboard Backlight Idle

An [Omarchy](https://omarchy.org/) Quattro shell service that turns off the
keyboard backlight after a configurable period without keyboard or pointer
input, then restores the saved brightness when input resumes.

The service ignores application idle inhibitors by default, so keyboard
lighting still turns off while watching video. It does not change screensaver,
lock, display-power, or suspend timings.

## Requirements

- Omarchy with the Quattro shell plugin runtime
- A keyboard backlight supported by Omarchy's keyboard-brightness commands

There are no external packages, installers, background services, remote builds,
or privileged setup steps. The plugin runs inside the existing unsandboxed
`omarchy-shell` process with the current user's permissions. It only invokes:

- `omarchy brightness keyboard off`
- `omarchy brightness keyboard restore`

No `sudo` or `pkexec` access is required.

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
omarchy plugin remove andrewf.keyboard-idle
omarchy brightness keyboard restore
```

The explicit restore leaves the keyboard backlight in its saved state even if
the plugin is removed while the keyboard is idle.

## Development

Validate the repository and QML before publishing changes:

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" Service.qml
```

## License

[MIT](LICENSE)

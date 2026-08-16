# Keyboard Backlight Idle

An Omarchy shell service that turns off the keyboard backlight after 10
seconds without keyboard or pointer input and restores the saved level when
input resumes.

The idle monitor deliberately ignores application idle inhibitors, so the
keyboard lighting still turns off while watching video. It does not change
screensaver, lock, display power, or suspend timings.

Backlight control uses Omarchy's hardware-aware commands:

- `omarchy brightness keyboard off`
- `omarchy brightness keyboard restore`

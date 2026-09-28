#!/usr/bin/env bash
set -euo pipefail

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/leds/mockkbd_backlight" "$test_dir/run"

cat >"$test_dir/bin/brightnessctl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case ${3:-} in
  get) cat "$MOCK_BRIGHTNESS_FILE" ;;
  set)
    [[ ${MOCK_FAIL_SET:-} != "${4:-}" ]] || exit 1
    printf '%s\n' "$4" >"$MOCK_BRIGHTNESS_FILE"
    ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$test_dir/bin/brightnessctl"

export PATH="$test_dir/bin:$PATH"
export XDG_RUNTIME_DIR="$test_dir/run"
export KEYBOARD_IDLE_LEDS_DIR="$test_dir/leds"
export MOCK_BRIGHTNESS_FILE="$test_dir/brightness"
control_script=$(dirname "$0")/../keyboard-idle-control
state_file=$XDG_RUNTIME_DIR/andrewf.keyboard-idle/brightness

assert_brightness() {
  [[ $(<"$MOCK_BRIGHTNESS_FILE") == "$1" ]] || {
    echo "Expected brightness $1, got $(<"$MOCK_BRIGHTNESS_FILE")" >&2
    exit 1
  }
}

# Separate helper invocations model idle, reload/resume, and activity.
printf '2\n' >"$MOCK_BRIGHTNESS_FILE"
bash "$control_script" off
assert_brightness 0
bash "$control_script" off
assert_brightness 0
[[ $(<"$state_file") == 'mockkbd_backlight 2' ]]
bash "$control_script" restore
assert_brightness 2
[[ ! -f $state_file ]]

# A keyboard already off belongs to the user, so there is nothing to restore.
printf '0\n' >"$MOCK_BRIGHTNESS_FILE"
bash "$control_script" off
[[ ! -f $state_file ]]
bash "$control_script" restore
assert_brightness 0

# A failed restore must retain the original brightness for another attempt.
printf '3\n' >"$MOCK_BRIGHTNESS_FILE"
bash "$control_script" off
export MOCK_FAIL_SET=3
if bash "$control_script" restore; then
  echo "Expected restore to fail" >&2
  exit 1
fi
[[ -f $state_file ]]
unset MOCK_FAIL_SET
bash "$control_script" restore
assert_brightness 3
[[ ! -f $state_file ]]

echo "keyboard idle control tests passed"

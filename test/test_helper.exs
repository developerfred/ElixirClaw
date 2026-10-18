# Tests tagged :hardware need real camera/screen/notification/GPS tooling on
# the host (v4l2-ctl, scrot, notify-send, gpspipe, screencapture...).
# They are skipped by default; run them with ELIXIR_CLAW_HARDWARE_TESTS=1.
exclude = if System.get_env("ELIXIR_CLAW_HARDWARE_TESTS") == "1", do: [], else: [:hardware]

ExUnit.start(exclude: exclude)

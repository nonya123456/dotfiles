---
name: bevy-run
description: Run and check a Bevy game from the shell without adding anything to the project — launch it, wait for the window, screenshot just the game window, read the logs for panics and warnings, try tuning values by edit-run-compare, and stop it cleanly. Use whenever working in a Bevy project (Cargo.toml depending on bevy) and you need to see a change working, check a mechanic, compare tuning values, or chase a runtime warning, even if the user only says "run it" or "does it look right".
---

# Running a Bevy game from the CLI

Everything here works on the project as it is: no plugins, dependencies or derives get added to the user's game. The only edits are the tuning edits in "Trying values", and those are reverted. BRP tweaking is used only when the project already exposes it.

## Find how the project runs

Read the `justfile` / `Makefile` / `.cargo/config.toml` and `Cargo.toml` first, and reuse the project's own run command: it often adds features (e.g. `bevy/dynamic_linking`), and running without them rebuilds all of Bevy. Building with a different Bevy feature set also rebuilds all of Bevy, so keep the features identical between runs. The binary name is the crate name (or the `[[bin]]` name); the scripts and `pkill` below use it.

## Run, wait, stop

```bash
cargo run <project features> > <log> 2>&1 &     # with Bash run_in_background, or ( … & ) in a script
until grep -q "Creating new window" <log>; do sleep 0.1; done
sleep 3                                          # let assets load and the scene settle
# … screenshots, observations …
pkill -x <binary>
```

macOS has no `timeout`; poll the log as above instead of sleeping a guessed amount. If the log shows `error[E…]` or `could not compile`, the build failed; read it rather than waiting for a window.

## Screenshot the game window

[`shot.sh`](shot.sh) `<binary> <out.png>` captures only the game's window (not the desktop), even when other windows cover it, then prints the path; open it with Read. It needs macOS Screen Recording access for the terminal; if it errors with "no on-screen window", the window isn't up yet or is minimised.

What the picture shows depends on where the game's camera starts. If the subject is off-screen, say so instead of reporting that it's missing, and for a one-off look, temporarily change the camera's starting `Transform` (revert it after).

## Read the logs

Grep the log for `panicked`, ` WARN `, ` ERROR `, and report every hit, including ones that were already there before your change, since a one-off startup warning is easy to wave away.

Bevy warnings carry a code like `B0004`. Find the check that emits it in the Bevy source (`~/.cargo/registry/src/*/bevy_*-<version>/src`) rather than guessing from memory. Without `bevy/debug` the log hides component names (`<Enable the debug feature to see the name>`); infer the component from which entities the warning names and what the check validates.

## Tweaking a running game over BRP

If the project already adds `bevy::remote::RemotePlugin` and `bevy::remote::http::RemoteHttpPlugin` (usually behind a dev-only feature, since `bevy_remote` is not a default Bevy feature), the running game answers JSON-RPC on `127.0.0.1:15702`, and values can be read and changed live without a rebuild. Use what the project exposes; if it doesn't, use "Trying values" below rather than adding the plugin yourself.

```bash
brp() { curl -s 127.0.0.1:15702 -d "{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"$1\",\"params\":${2:-null}}"; echo; }
until [ -n "$(brp rpc.discover)" ]; do sleep 0.1; done   # empty until the server is up
```

| Call | Effect |
| --- | --- |
| `brp world.list_resources` | Every reflected resource's full type name; start here instead of guessing module paths |
| `brp world.get_resources '{"resource":"<T>"}'` | Read a resource |
| `brp world.mutate_resources '{"resource":"<T>","path":"max_speed","value":12.0}'` | Set one field (`path` is a reflect path: `a.b`, `list[0]`, `.0`) |
| `brp world.query '{"data":{"components":["<C>"]},"filter":{"with":["<Marker>"]}}'` | Entities and their component values |
| `brp world.mutate_components '{"entity":<id>,"component":"<C>","path":"translation.y","value":5.0}'` | Set one component field |
| `brp rpc.discover` | Every method the server offers, with its params |

Values use the reflect JSON shape: read a value with `get_resources` first and send back the same shape (an enum is `{"Variant": …}`, e.g. `ClearColor` path `.0` takes `{"Srgba":{"red":0.2,"green":0.5,"blue":0.9,"alpha":1.0}}`). A reply with an `"error"` key failed; read its message. BRP only sees reflected types: engine types (`Transform`, `ClearColor`, `Time<Fixed>`) work as-is, but a game's own resource needs `#[derive(Reflect)]` and `#[reflect(Resource)]` (`#[reflect(Component)]` for a component). If a value the user wants to tweak isn't listed, tell them which derive it lacks rather than adding it unasked.

A tweak run: wait for the server, screenshot, mutate, `sleep` long enough for the change to play out, screenshot again, read back the value, and report the before/after against what you expected.

## Sending input over BRP

To press keys or move the mouse, write Bevy's own input messages with `world.write_message`. Bevy's input systems handle them like real device input, and the window doesn't need focus. OS-level key taps (`osascript … key code`) did not register in testing, so use BRP.

```bash
first() { python3 -c 'import json,sys; r=json.load(sys.stdin)["result"]; print(r[0]["entity"] if r else "")'; }
WIN=$(brp world.query '{"data":{},"filter":{"with":["bevy_window::window::PrimaryWindow"]}}' | first)
[ -n "$WIN" ] || { echo "no PrimaryWindow found" >&2; exit 1; }
key() { brp world.write_message "{\"message\":\"bevy_input::keyboard::KeyboardInput\",\"value\":{\"key_code\":\"$1\",\"logical_key\":\"$1\",\"state\":\"$2\",\"text\":null,\"repeat\":false,\"window\":$WIN}}" >/dev/null; }
key Space Pressed; sleep 1; key Space Released                  # hold for 1s
brp world.write_message '{"message":"bevy_input::mouse::MouseMotion","value":{"delta":[-100.0,0.0]}}'   # pixels; -x left, -y up
```

- `key_code` is a `KeyCode` variant name (`Space`, `KeyW`, `ShiftLeft`). `logical_key` only matters if the game reads `ButtonInput<Key>`. For anything other than a named key like `Space`, read its shape from `brp registry.schema` first.
- A key stays held from `Pressed` until `Released`, so send both. `ButtonInput<KeyCode>` itself is not in the BRP registry, so setting it directly doesn't work.
- `MouseMotion` feeds `AccumulatedMouseMotion` for one frame. Send one large delta, or several over time for a smooth turn.
- To check the result, sample the state over time with `world.query` (velocity, `Transform`, the game's own components) while the input is held. Steer away from obstacles first, because a collision can hide what you are testing.

## Trying values

Without BRP, or for values only read at startup (spawn counts, mesh sizes), edit the value where the game defines it (a `const`, a `Default` impl, a spawn call), then run → wait → screenshot → stop, once per value. Keep the features and the camera identical across runs so the screenshots are comparable. Report each value against what you saw, then restore the original value unless the user picks a new one.

## Measuring performance

FPS means nothing under vsync, and a dev build of the game crate is slow. For a measurement run, temporarily set `present_mode: PresentMode::AutoNoVsync` on the primary window and build with `CARGO_PROFILE_DEV_OPT_LEVEL=3` (optimises the game crate while keeping dev's incremental builds). Let the game warm up a few seconds before measuring, and time `FixedUpdate` work separately from the frame, since it runs zero or several times per frame. Revert the temporary measurement code afterwards.

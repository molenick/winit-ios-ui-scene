# winit-scene-integration

Tests [winit]'s UIScene lifecycle support on the [`uiscene-minimal`][branch] branch across iOS
versions.

It builds the same app twice: `NoManifest` declares no scene manifest, and `SceneManifest`
declares one. Each has UI tests that pass when winit's window is on screen, one of them with the
window fullscreen. `scripts/matrix.sh` runs them on each iOS simulator runtime:

```
                                      iOS 17-2              iOS 26-5              iOS 27-0
NoManifest WindowIsShown              PASS                  PASS                  FAIL (crashed)
NoManifest FullscreenWindowIsShown    PASS                  PASS                  FAIL (crashed)
SceneManifest WindowIsShown           PASS                  PASS                  PASS
SceneManifest FullscreenWindowIsShown PASS                  PASS                  PASS
```

## Requirements

- Xcode 27, with the iOS simulator runtimes to test (17.2, 26.5 and 27.0 by default)
- Rust, with the `aarch64-apple-ios-sim` target
- [XcodeGen], which generates the Xcode project from `project.yml`

## Usage

```sh
scripts/matrix.sh             # or name runtimes: scripts/matrix.sh 17-2 27-0
```

Test results and logs are written to `build/matrix/`.

[winit]: https://github.com/rust-windowing/winit
[branch]: https://github.com/molenick/winit/tree/uiscene-minimal
[XcodeGen]: https://github.com/yonaskolb/XcodeGen

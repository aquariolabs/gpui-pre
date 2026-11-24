# gpui-pre for Chaveiro

[gpui-pre](https://crates.io/crates/gpui-pre) 0.3.12, the published snapshot of Zed's GPUI (zed@d2a4fb6), with the changes [Chaveiro](https://github.com/aquariolabs/chaveiro) needs before they exist upstream.

This isn't a GitHub fork: gpui-pre has no repository of its own, and forking zed-industries/zed would bring the whole editor. The first commit holds the four crates exactly as crates.io serves them, so a diff against it shows every change made here.

| Crate | What it is |
| --- | --- |
| `crates/gpui-pre` | The framework |
| `crates/gpui-pre-apple` | Metal renderer for macOS and iOS |
| `crates/gpui-pre-wgpu` | wgpu renderer for Linux and the web |
| `crates/gpui-pre-windows` | DirectX renderer for Windows |
| `crates/util-macros` | Stands in for Zed's `util_macros` so gpui-pre's own tests build. Not published. |

The other gpui-pre crates come unchanged from crates.io.

## Using it

Point Cargo at a commit of this repository in the app's workspace `Cargo.toml`:

```toml
[patch.crates-io]
gpui-pre = { git = "https://github.com/aquariolabs/gpui-pre", rev = "<commit>" }
gpui-pre-apple = { git = "https://github.com/aquariolabs/gpui-pre", rev = "<commit>" }
gpui-pre-wgpu = { git = "https://github.com/aquariolabs/gpui-pre", rev = "<commit>" }
gpui-pre-windows = { git = "https://github.com/aquariolabs/gpui-pre", rev = "<commit>" }
```

The crates keep version 0.3.12, so everything that asks crates.io for `=0.3.12`, gpui-kit included, gets these copies.

## Tests

```sh
cargo test -p gpui-pre --features test-support --tests
cargo test -p gpui-pre-wgpu --features test-support
```

`--tests` leaves out gpui-pre's examples and doc tests, which need crates from the Zed repository. The wgpu tests draw on a real GPU device. Without one, install a software Vulkan driver (lavapipe: `mesa-vulkan-drivers` on Ubuntu). They also embed Zed's fonts from `assets/fonts`, which isn't in this repository; CI downloads them from zed@d2a4fb6 (see `.github/workflows/ci.yml`).

The Metal and HLSL shaders only compile on their own systems, so CI checks them there:

- macOS: `cargo check -p gpui-pre-apple` compiles `shaders.metal` with `xcrun metal`. Apps built on gpui-kit turn on `runtime_shaders`, which compiles them when the app opens instead, so a mistake there would otherwise only show on a Mac at launch.
- Windows: `cargo check --release -p gpui-pre-windows` compiles `shaders.hlsl` with fxc, which the build script only runs in release builds.

## Updating gpui-pre

1. On a branch, replace the four crate folders with the new version from crates.io, leaving out each crate's `Cargo.toml.orig` and `Cargo.lock`, and commit that alone.
2. Apply the changes below again on top of it, fixing conflicts.
3. `crates/gpui-pre-apple/vendor/gpui/src` holds copies of gpui-pre's `scene.rs`, `window.rs` and `geometry.rs`, which the Apple build script reads to generate the Metal header. Copy them again from `crates/gpui-pre/src` whenever those files change.

## License

Apache-2.0, like gpui-pre. Each crate keeps its `LICENSE-APACHE`, and every file changed here says so in its first lines.

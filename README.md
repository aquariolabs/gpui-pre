# gpui-pre for Chaveiro

[gpui-pre](https://crates.io/crates/gpui-pre) 0.3.12, the published snapshot of Zed's GPUI (zed@d2a4fb6), with the changes [Chaveiro](https://github.com/aquariolabs/chaveiro) needs before they exist upstream.

This isn't a GitHub fork: gpui-pre has no repository of its own, and forking zed-industries/zed would bring the whole editor. The first commit holds the four crates exactly as crates.io serves them, so a diff against it shows every change made here.

| Crate | What it is |
| --- | --- |
| `crates/gpui-pre` | The framework |
| `crates/gpui-pre-apple` | Metal renderer for macOS and iOS |
| `crates/gpui-pre-macos` | The macOS platform: windows, events, menus |
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
gpui-pre-macos = { git = "https://github.com/aquariolabs/gpui-pre", rev = "<commit>" }
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

## Changes

### Fading content at clipped edges

`Styled::overflow_fade`, `overflow_fade_x` and `overflow_fade_y` fade an element's children to transparent over the given distance as they reach its clipped edges, like CSS `mask-image: linear-gradient(...)`. A list can then disappear behind a translucent footer instead of being cut off. The names and behavior match [gpui-ce](https://github.com/gpui-ce/gpui-ce), so moving to gpui-ce later keeps the app's code.

- `Window::with_fade_mask` sets the fade while painting, and the scene stamps it on every primitive painted under it: a `FadeMask` with the faded bounds and the fade distance at each edge, in device pixels.
- The Metal, WGSL (Vulkan, wgpu's Metal and WebGL) and HLSL shaders multiply each pixel's alpha by the fade. Paths fade while they're rasterized, so their antialiased edges fade too.
- A view reused from the previous frame keeps the fades painted inside it, and takes the current fade where it was painted under the outer one.
- Only the axes the element clips fade, and the element's own background and border don't.

### Blurring what fades at the top

`Styled::overflow_fade_blur` blurs content as it fades at the top clipped edge: by the given radius at the edge itself, shrinking to none where the top fade ends. A list scrolling under a translucent search field then goes soft and transparent instead of staying sharp to the last pixel. It isn't a backdrop blur: it blurs the element's own content, not what's behind it.

- `FadeMask` carries the radius as `blur`, so the record sizes grow by 16 bytes.
- Quads, monochrome, subpixel and polychrome sprites near the fade's top grow by the radius so the blur has room. Quads soften their edges by the radius; sprites average 16 atlas samples over a disc, and images weight those samples by their alpha. Shadows, underlines and paths only fade.
- The WebGL decoders read the longer records, and the wgpu tests render the blur on quads and on both kinds of sprites.

### Glass behind the window on Windows

GPUI draws into a DirectComposition target on the window's HWND. It's created as the topmost target here, so an app can put a `Windows.UI.Composition` target of its own under it (a host backdrop brush clipped to rounded corners, for example) and GPUI still draws on top. Upstream creates it as the bottom one, which leaves no room below.

### Shaders beside the program in debug builds

Debug builds compile `shaders.hlsl` when the app opens, from the path the crate was built at. They now look for `shaders.hlsl` (and `alpha_correction.hlsl`) beside the program first, so a debug build made on another machine runs on Windows with the two files copied next to it. Release builds are unchanged: fxc compiles the shaders at build time.

## License

Apache-2.0, like gpui-pre. Each crate keeps its `LICENSE-APACHE`, and every file changed here says so in its first lines.

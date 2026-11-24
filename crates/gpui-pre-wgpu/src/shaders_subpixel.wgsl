// Modified for aquariolabs/gpui-pre: fade masks for Styled::overflow_fade and its top blur.
// --- subpixel sprites --- //

struct SubpixelSprite {
    order: u32,
    pad: u32,
    tile: AtlasTile,
    bounds: Bounds,
    content_mask: Bounds,
    color: Hsla,
    transformation: TransformationMatrix,
    fade: FadeMask,
}
@group(1) @binding(0) var<storage, read> b_subpixel_sprites: array<SubpixelSprite>;

struct SubpixelSpriteOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) tile_position: vec2<f32>,
    @location(1) @interpolate(flat) color: vec4<f32>,
    @location(2) @interpolate(flat) sprite_id: u32,
    @location(3) clip_distances: vec4<f32>,
}

struct SubpixelSpriteFragmentOutput {
    @location(0) @blend_src(0) foreground: vec4<f32>,
    @location(0) @blend_src(1) alpha: vec4<f32>,
}

@vertex
fn vs_subpixel_sprite(@builtin(vertex_index) vertex_id: u32, @builtin(instance_index) instance_id: u32) -> SubpixelSpriteOutput {
    let unit_vertex = vec2<f32>(f32(vertex_id & 1u), 0.5 * f32(vertex_id & 2u));
    let sprite = b_subpixel_sprites[instance_id];

    var out = SubpixelSpriteOutput();
    out.sprite_id = instance_id;
    let outset = fade_outset(sprite.bounds, sprite.fade);
    let grown = outset_bounds(sprite.bounds, outset);
    out.position = to_device_position_transformed(unit_vertex, grown, sprite.transformation);
    out.tile_position = to_tile_position(outset_unit_vertex(unit_vertex, sprite.bounds, outset), sprite.tile);
    out.color = hsla_to_rgba(sprite.color);
    out.clip_distances = distance_from_clip_rect_transformed(unit_vertex, grown, sprite.content_mask, sprite.transformation);
    return out;
}

@fragment
fn fs_subpixel_sprite(input: SubpixelSpriteOutput) -> SubpixelSpriteFragmentOutput {
    let sprite = b_subpixel_sprites[input.sprite_id];
    let radius = fade_blur(input.position.xy, sprite.fade);
    var sample = blurred_tile_sample(input.tile_position, sprite.tile, sprite.bounds.size, radius).rgb;
    if (gamma_params.is_bgr != 0u) {
        sample = sample.bgr;
    }
    let alpha_corrected = apply_contrast_and_gamma_correction3(sample, input.color.rgb, gamma_params.subpixel_enhanced_contrast, gamma_params.gamma_ratios);

    // Alpha clip after using the derivatives.
    if (any(input.clip_distances < vec4<f32>(0.0))) {
        return SubpixelSpriteFragmentOutput(vec4<f32>(0.0), vec4<f32>(0.0));
    }

    var out = SubpixelSpriteFragmentOutput();
    out.foreground = vec4<f32>(input.color.rgb, 1.0);
    let fade = fade_alpha(input.position.xy, sprite.fade);
    out.alpha = vec4<f32>(input.color.a * alpha_corrected * fade, 1.0);
    return out;
}

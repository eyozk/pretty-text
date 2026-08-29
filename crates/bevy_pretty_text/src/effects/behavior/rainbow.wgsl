#import bevy_render::color_operations::hsv_to_rgb;
#import bevy_pretty_text::{
    globals,
    atlas_texture,
    atlas_sampler,
    VertexOutput,
    GLYPH_FLAG_OUTLINE,
    glyph_sample,
    glyph_coverage,
    composite_glyph,
}

struct Uniform {
    speed: f32,
    width: f32,
    _pad0: u32,
    _pad1: u32,
}

@group(2) @binding(0) var<uniform> args: Uniform;

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    let source = textureSample(atlas_texture, atlas_sampler, in.uv);
    let w = 1.0 / (90.0 * args.width);
    let rainbow = hsv_to_rgb(vec3(
        in.position.x * w + 2.0 * args.speed * globals.time,
        1.0,
        0.5,
    ));
    let fill_rgb = source.rgb * rainbow;

    if ((in.flags & GLYPH_FLAG_OUTLINE) == 0u) {
        return vec4<f32>(fill_rgb, source.a * in.color.a);
    }
    let safe_source = glyph_sample(in.uv, in);
    return composite_glyph(
        safe_source.rgb * rainbow,
        glyph_coverage(in),
        in,
    );
}

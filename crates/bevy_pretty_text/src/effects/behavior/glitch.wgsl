#import bevy_pretty_text::{
    globals,
    atlas_texture,
    atlas_sampler,
    VertexOutput,
    GLYPH_FLAG_OUTLINE,
    glyph_sample,
    glyph_coverage_at,
    composite_glyph,
}

fn random(seed: vec2<f32>) -> f32 {
    return fract(sin(dot(seed, vec2<f32>(12.9898, 78.233))) * 43758.5453);
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(random(i + vec2(0.0, 0.0)), random(i + vec2(1.0, 0.0)), u.x),
        mix(random(i + vec2(0.0, 1.0)), random(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

struct Uniform {
    intensity: f32,
    frequency: f32,
    speed: f32,
    threshold: f32,
}

@group(2) @binding(0) var<uniform> args: Uniform;

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    var uv = in.uv;
    let scanline = floor(uv.y * args.frequency);
    let glitch_noise = noise(vec2(scanline * 0.1, globals.time * args.speed));
    let secondary_noise = noise(vec2(
        scanline * 0.03,
        globals.time * args.speed * 0.7,
    ));

    if (glitch_noise > args.threshold) {
        let displacement = (glitch_noise - args.threshold) / (1.0 - args.threshold);
        uv.x += displacement * args.intensity * (secondary_noise - 0.5) * 2.0;
        uv.x = fract(uv.x);
    }

    let source = textureSample(atlas_texture, atlas_sampler, uv);
    if ((in.flags & GLYPH_FLAG_OUTLINE) == 0u) {
        return source * in.color;
    }
    let safe_source = glyph_sample(uv, in);
    return composite_glyph(
        safe_source.rgb * in.color.rgb,
        glyph_coverage_at(uv, in),
        in,
    );
}

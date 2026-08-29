#define_import_path bevy_pretty_text

#import bevy_render::{
    view::View,
    globals::Globals,
}

@group(0) @binding(0) var<uniform> view: View;
@group(0) @binding(1) var<uniform> globals: Globals;

@group(1) @binding(0) var atlas_texture: texture_2d<f32>;
@group(1) @binding(1) var atlas_sampler: sampler;

// Vertex shader input for the `GlyphMaterial` pipeline.
struct VertexInput {
    // vertex-rate fields
    // extracted from the `GlyphVertices` component
    @location(0) position: vec3<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) color: vec4<f32>,

    // Keep these locations stable for existing custom materials.
    @location(3) span_color: vec4<f32>,
    // scalar derived from font_size
    @location(4) size: f32,
    // glyph index in the text block
    @location(5) index: u32,
#ifdef TEXT_OUTLINE
    @location(6) outline_color: vec4<f32>,
    @location(7) source_uv_min: vec2<f32>,
    @location(8) source_uv_max: vec2<f32>,
    @location(9) outline_width: f32,
    @location(10) flags: u32,
#endif
};

// Output of the default shader in the `GlyphMaterial` pipeline.
struct VertexOutput {
    // clip_position
    @builtin(position) position: vec4<f32>,
    // interpolated uv
    @location(0) uv: vec2<f32>,
    // interpolated color, mix of span and glyph color
    @location(1) color: vec4<f32>,
    // scalar derived from font_size
    @location(2) size: f32,
    // glyph index in the text block
    @location(3) index: u32,
#ifdef TEXT_OUTLINE
    @location(4) @interpolate(flat) outline_color: vec4<f32>,
    @location(5) @interpolate(flat) source_uv_min: vec2<f32>,
    @location(6) @interpolate(flat) source_uv_max: vec2<f32>,
    @location(7) @interpolate(flat) outline_width: f32,
    @location(8) @interpolate(flat) flags: u32,
#endif
};

#ifdef TEXT_OUTLINE
const GLYPH_FLAG_OUTLINE: u32 = 1u;
const MAX_OUTLINE_RADIUS: i32 = 4;

struct GlyphCoverage {
    fill: f32,
    outline: f32,
};

fn glyph_sample(uv: vec2<f32>, in: VertexOutput) -> vec4<f32> {
    if (
        uv.x < in.source_uv_min.x ||
        uv.x > in.source_uv_max.x ||
        uv.y < in.source_uv_min.y ||
        uv.y > in.source_uv_max.y
    ) {
        return vec4<f32>(0.0);
    }

    // Keep bilinear filtering inside the glyph's atlas rectangle too.
    let half_texel = 0.5 / vec2<f32>(textureDimensions(atlas_texture));
    let safe_uv = clamp(
        uv,
        in.source_uv_min + half_texel,
        in.source_uv_max - half_texel,
    );
    return textureSampleLevel(atlas_texture, atlas_sampler, safe_uv, 0.0);
}

fn glyph_coverage_at(uv: vec2<f32>, in: VertexOutput) -> GlyphCoverage {
    let fill = glyph_sample(uv, in).a;
    if ((in.flags & GLYPH_FLAG_OUTLINE) == 0u) {
        return GlyphCoverage(fill, 0.0);
    }

    let texel = 1.0 / vec2<f32>(textureDimensions(atlas_texture));
    var dilated = fill;

    for (var y = -MAX_OUTLINE_RADIUS; y <= MAX_OUTLINE_RADIUS; y += 1) {
        for (var x = -MAX_OUTLINE_RADIUS; x <= MAX_OUTLINE_RADIUS; x += 1) {
            let offset = vec2<f32>(f32(x), f32(y));
            if (length(offset) <= in.outline_width + 0.5) {
                dilated = max(dilated, glyph_sample(uv + offset * texel, in).a);
            }
        }
    }

    return GlyphCoverage(fill, max(dilated - fill, 0.0));
}

fn glyph_coverage(in: VertexOutput) -> GlyphCoverage {
    return glyph_coverage_at(in.uv, in);
}

fn composite_glyph(
    fill_rgb: vec3<f32>,
    coverage: GlyphCoverage,
    in: VertexOutput,
) -> vec4<f32> {
    let fill_alpha = coverage.fill * in.color.a;
    if ((in.flags & GLYPH_FLAG_OUTLINE) == 0u) {
        return vec4<f32>(fill_rgb, fill_alpha);
    }

    // TextColor and GlyphVertices alpha fade the completed fill/outline pair.
    let outline_alpha = in.outline_color.a * coverage.outline * in.color.a;
    let alpha = fill_alpha + outline_alpha;
    if (alpha <= 0.0) {
        return vec4<f32>(0.0);
    }

    let rgb = (
        fill_rgb * fill_alpha +
        in.outline_color.rgb * outline_alpha
    ) / alpha;
    return vec4<f32>(rgb, alpha);
}
#endif

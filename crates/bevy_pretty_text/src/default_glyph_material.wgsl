#ifdef TONEMAP_IN_SHADER
#import bevy_core_pipeline::tonemapping
#endif

#import bevy_pretty_text::{
    view,
    globals,
    atlas_texture,
    atlas_sampler,
    VertexInput,
    VertexOutput,
}
#ifdef TEXT_OUTLINE
#import bevy_pretty_text::{
    GLYPH_FLAG_OUTLINE,
    glyph_sample,
    glyph_coverage,
    composite_glyph,
}
#endif

@vertex
fn vertex(vertex: VertexInput) -> VertexOutput {
    var out: VertexOutput;

    out.position = view.clip_from_world * vec4<f32>(vertex.position, 1.0);
    out.uv = vertex.uv;
    // vertex.color acts like a color mask here
    out.color = vertex.color * vertex.span_color;
    out.size = vertex.size;
    out.index = vertex.index;
#ifdef TEXT_OUTLINE
    out.outline_color = vertex.outline_color;
    out.source_uv_min = vertex.source_uv_min;
    out.source_uv_max = vertex.source_uv_max;
    out.outline_width = vertex.outline_width;
    out.flags = vertex.flags;
#endif

    return out;
}

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    // Preserve the original, single-sample path for ordinary text.
    var color = in.color * textureSample(atlas_texture, atlas_sampler, in.uv);
#ifdef TEXT_OUTLINE
    if ((in.flags & GLYPH_FLAG_OUTLINE) != 0u) {
        let source = glyph_sample(in.uv, in);
        color = composite_glyph(
            in.color.rgb * source.rgb,
            glyph_coverage(in),
            in,
        );
    }
#endif

#ifdef TONEMAP_IN_SHADER
    color = tonemapping::tone_mapping(color, view.color_grading);
#endif

    return color;
}

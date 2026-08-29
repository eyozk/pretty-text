use bevy::prelude::*;

use crate::PrettyText;

pub(crate) const MAX_OUTLINE_PHYSICAL_WIDTH: f32 = 4.0;

/// Draws a glyph outline in the same render pass as its fill.
#[derive(Debug, Clone, Copy, Component, Reflect)]
#[require(PrettyText)]
pub struct TextOutline {
    /// Outline color.
    pub color: Color,
    /// Outline width in logical pixels.
    pub width: f32,
}

impl Default for TextOutline {
    fn default() -> Self {
        Self {
            color: Color::BLACK,
            width: 1.0,
        }
    }
}

pub(crate) fn physical_outline_width(logical_width: f32, scale_factor: f32) -> f32 {
    if logical_width > 0.0 {
        (logical_width * scale_factor).clamp(0.0, MAX_OUTLINE_PHYSICAL_WIDTH)
    } else {
        0.0
    }
}

pub(crate) fn expanded_glyph_rect(rect: Rect, padding: f32) -> Rect {
    Rect::from_corners(
        rect.min - Vec2::splat(padding),
        rect.max + Vec2::splat(padding),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn outline_width_is_scaled_and_clamped() {
        assert_eq!(physical_outline_width(-1.0, 1.0), 0.0);
        assert_eq!(physical_outline_width(0.0, 1.0), 0.0);
        assert_eq!(physical_outline_width(1.0, 1.0), 1.0);
        assert_eq!(physical_outline_width(2.0, 2.0), 4.0);
        assert_eq!(physical_outline_width(4.0, 2.0), MAX_OUTLINE_PHYSICAL_WIDTH);
    }

    #[test]
    fn glyph_rect_expands_on_every_side() {
        let rect = Rect::from_corners(Vec2::ZERO, Vec2::new(10.0, 20.0));
        assert_eq!(expanded_glyph_rect(rect, 2.0).size(), Vec2::new(14.0, 24.0));
    }
}

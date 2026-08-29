//! Regression scene for single-pass text outlines.

use bevy::prelude::*;
use bevy::text::FontSmoothing;
use bevy::window::WindowResolution;
use bevy_pretty_text::prelude::*;

const LABELS: [&str; 4] = ["+125", "-42", "CRIT 999", "+$3.5K"];

fn main() {
    App::new()
        .add_plugins((
            DefaultPlugins.set(WindowPlugin {
                primary_window: Some(Window {
                    title: "Pretty Text outlines".into(),
                    resolution: WindowResolution::new(1280, 800),
                    ..default()
                }),
                ..default()
            }),
            PrettyTextPlugin,
        ))
        .insert_resource(SpawnTimer {
            timer: Timer::from_seconds(0.55, TimerMode::Repeating),
            next: 0,
        })
        .add_systems(Startup, setup)
        .add_systems(Update, (spawn_feedback, animate_feedback))
        .run();
}

#[derive(Resource)]
struct SpawnTimer {
    timer: Timer,
    next: usize,
}

#[derive(Component)]
struct FloatingText {
    age: f32,
    fade: bool,
}

fn setup(
    mut commands: Commands,
    mut rainbows: ResMut<Assets<Rainbow>>,
    mut glitches: ResMut<Assets<Glitch>>,
) {
    commands.spawn(Camera2d);

    commands.spawn((
        PrettyStyle("damage"),
        effects![TextOutline {
            color: Color::BLACK,
            width: 2.0,
        }],
    ));

    // UI Text: root, span, and PrettyStyle inheritance.
    commands.spawn((
        Node {
            position_type: PositionType::Absolute,
            left: px(20),
            top: px(15),
            flex_direction: FlexDirection::Column,
            row_gap: px(4),
            ..default()
        },
        children![
            (
                Text::new("Text root outline"),
                TextFont::from_font_size(30.0),
                TextColor(Color::WHITE),
                TextOutline {
                    color: Color::BLACK,
                    width: 2.0,
                },
            ),
            (
                Text::new("TextSpan: "),
                TextFont::from_font_size(30.0),
                children![(
                    TextSpan::new("red outline"),
                    TextColor(Color::WHITE),
                    TextOutline {
                        color: Color::srgb(0.45, 0.0, 0.0),
                        width: 2.0,
                    },
                )],
            ),
            (
                pretty!("[PrettyStyle outline](damage)"),
                TextFont::from_font_size(30.0),
                TextColor(Color::WHITE),
            ),
            (
                Node {
                    width: px(220),
                    height: px(32),
                    overflow: Overflow::clip(),
                    ..default()
                },
                children![(
                    Text::new("UI CLIPPING CUTS THIS OUTLINE"),
                    TextFont::from_font_size(30.0),
                    TextColor(Color::WHITE),
                    TextOutline {
                        color: Color::BLACK,
                        width: 4.0,
                    },
                )],
            ),
        ],
    ));

    let font = TextFont::from_font_size(34.0);
    let samples = [
        ("0 px", 0.0, Color::WHITE, Color::BLACK),
        ("1 px", 1.0, Color::srgb(1.0, 0.2, 0.2), Color::BLACK),
        (
            "2 px",
            2.0,
            Color::srgb(1.0, 0.85, 0.1),
            Color::srgb(0.35, 0.0, 0.0),
        ),
        (
            "4 px / translucent",
            4.0,
            Color::srgba(1.0, 1.0, 1.0, 0.6),
            Color::srgba(0.0, 0.0, 0.0, 0.5),
        ),
    ];
    for (i, (label, width, fill, outline)) in samples.into_iter().enumerate() {
        commands.spawn((
            Text2d::new(label),
            font.clone(),
            TextColor(fill),
            TextOutline {
                color: outline,
                width,
            },
            Transform::from_xyz(-390.0, 150.0 - i as f32 * 48.0, 0.0)
                .with_rotation(Quat::from_rotation_z((i as f32 - 1.5) * 0.035)),
        ));
    }

    // Maximum-width atlas-neighbor regression with both smoothing modes.
    commands.spawn((
        Text2d::new("MW@#18gQj  AntiAliased"),
        TextFont::from_font_size(38.0),
        TextColor(Color::WHITE),
        TextOutline {
            color: Color::BLACK,
            width: 4.0,
        },
        Transform::from_xyz(250.0, 150.0, 0.0),
    ));
    commands.spawn((
        Text2d::new("MW@#18gQj  None"),
        TextFont {
            font_size: 38.0.into(),
            font_smoothing: FontSmoothing::None,
            ..default()
        },
        TextColor(Color::WHITE),
        TextOutline {
            color: Color::BLACK,
            width: 4.0,
        },
        Transform::from_xyz(250.0, 95.0, 0.0),
    ));

    commands.spawn((
        Text2d::new("RAINBOW"),
        font.clone(),
        PrettyTextMaterial(rainbows.add(Rainbow::default())),
        TextOutline {
            color: Color::BLACK,
            width: 2.0,
        },
        Transform::from_xyz(190.0, 30.0, 0.0),
    ));
    commands.spawn((
        Text2d::new("GLITCH"),
        font,
        PrettyTextMaterial(glitches.add(Glitch {
            intensity: 0.01,
            ..default()
        })),
        TextOutline {
            color: Color::BLACK,
            width: 2.0,
        },
        Transform::from_xyz(400.0, 30.0, 0.0),
    ));

    for (i, label) in LABELS.into_iter().enumerate() {
        spawn_label(&mut commands, label, -220.0 + i as f32 * 145.0, false);
    }
}

fn spawn_feedback(time: Res<Time>, mut timer: ResMut<SpawnTimer>, mut commands: Commands) {
    if timer.timer.tick(time.delta()).just_finished() {
        let label = LABELS[timer.next];
        timer.next = (timer.next + 1) % LABELS.len();
        spawn_label(&mut commands, label, -250.0, false);
        spawn_label(&mut commands, label, 250.0, true);
    }
}

fn spawn_label(commands: &mut Commands, label: &str, x: f32, fade: bool) {
    commands.spawn((
        Text2d::new(label),
        TextFont::from_font_size(46.0),
        TextColor(Color::WHITE),
        TextOutline {
            color: Color::BLACK,
            width: 2.0,
        },
        Transform::from_xyz(x, -260.0, 1.0).with_scale(Vec3::splat(1.4)),
        FloatingText { age: 0.0, fade },
    ));
}

fn animate_feedback(
    time: Res<Time>,
    mut commands: Commands,
    mut labels: Query<(Entity, &mut Transform, &mut TextColor, &mut FloatingText)>,
) {
    for (entity, mut transform, mut color, mut label) in &mut labels {
        label.age += time.delta_secs();
        let t = label.age / 2.0;
        if t >= 1.0 {
            commands.entity(entity).despawn();
            continue;
        }

        let scale = if t < 0.15 {
            1.4_f32.lerp(1.6, t / 0.15)
        } else if t < 0.4 {
            1.6_f32.lerp(1.0, (t - 0.15) / 0.25)
        } else {
            1.0_f32.lerp(0.0, (t - 0.4) / 0.6)
        };
        transform.scale = Vec3::splat(scale);
        transform.translation.y = -260.0 + t * 180.0;
        transform.rotation = Quat::from_rotation_z((t - 0.5) * 0.15);

        // The left row proves scale-to-zero without fading; the right also fades.
        if label.fade {
            color.0.set_alpha(1.0 - t);
        }
    }
}

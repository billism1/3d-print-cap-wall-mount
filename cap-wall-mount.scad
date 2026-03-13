// =============================================================================
// Cap Wall Mount – Hat Display System
// =============================================================================
// A parametric wall-mounted cap/hat holder for displaying baseball caps in a
// grid matrix on a wall for display and selection.
//
// The mount consists of a flat backplate (with a keyhole screw slot) and one
// arch-shaped channel (two concentric arc walls with a gap between them).
// A folded baseball cap's edge rides in the channel, with the bill extending
// forward and the logo/front visible.
//
// Model orientation: backplate in XY plane (Z=0..plate_thickness).
// Arch spans from -X to +X, curving upward in +Z.
// User rotates for printing as needed.
// =============================================================================

// ---------------------------------------------------------------------------
// 1. Constants & Parameters
// ---------------------------------------------------------------------------

// Backplate
plate_width              = 40;    // mm – plate width  (X axis)
plate_height             = 40;    // mm – plate height (Y axis)
plate_thickness          = 4;     // mm – plate thickness (Z axis)
plate_corner_radius      = 4;     // mm – fillet radius on plate corners

// Keyhole screw slot
keyhole_total_height     = 13;    // mm – total height of keyhole slot
keyhole_bottom_diameter  = 8;     // mm – wide hole for screw head
keyhole_top_width        = 5;     // mm – narrow slot for screw shaft
keyhole_offset_y         = 0;     // mm – vertical offset from plate centre

// Arch channel (cap cradle) — one arch spanning -X to +X
arc_radius               = 40;    // mm – radius of the arc curve
arc_sweep                = 60;    // deg – sweep angle per side (total arch = 2 × sweep)
arc_wall_thickness       = 4;     // mm – thickness of each arc wall
arc_channel_gap          = 9;     // mm – gap between inner walls (cap fits here)
arc_depth                = 40;    // mm – depth of arcs (Y axis, matches plate height)

// Build flags
build_main               = true;  // Render the mount (backplate on XY plane)

// Resolution
$fn = 80;

// ---------------------------------------------------------------------------
// 2. Derived Dimensions
// ---------------------------------------------------------------------------

// Channel total width = wall + gap + wall
_channel_total           = arc_wall_thickness + arc_channel_gap + arc_wall_thickness;
// Inner wall radius (smaller arc, inside the channel)
_inner_radius            = arc_radius - arc_wall_thickness - arc_channel_gap;
// Arch peak height above plate front face
_arch_peak_z             = plate_thickness + arc_radius * sin(arc_sweep);
// Arch half-span in X
_arch_half_span          = arc_radius * (1 - cos(arc_sweep));

echo(str("Channel total width: ", _channel_total, " mm (target 17)"));
echo(str("Arch peak height: ", _arch_peak_z, " mm above base"));
echo(str("Arch half-span in X: ", _arch_half_span, " mm (plate half = ",
         plate_width / 2, ")"));
echo(str("Inner wall radius: ", _inner_radius, " mm"));

// Keyhole geometry
_keyhole_bottom_r        = keyhole_bottom_diameter / 2;
_keyhole_top_r           = keyhole_top_width / 2;
_keyhole_bottom_cy       = keyhole_offset_y - keyhole_total_height / 2
                           + _keyhole_bottom_r;
_keyhole_top_cy          = _keyhole_bottom_cy + keyhole_total_height
                           - _keyhole_top_r;

// ---------------------------------------------------------------------------
// 3. Helper / Utility Modules
// ---------------------------------------------------------------------------

// Rounded rectangle centred on XY origin, extruded in +Z
module rounded_rect_centred(size, r) {
    translate([-size.x / 2, -size.y / 2, 0])
        hull() {
            for (x = [r, size.x - r], y = [r, size.y - r])
                translate([x, y, 0])
                    cylinder(r = r, h = size.z);
        }
}

// One half of one arch wall (left side: starts at -X edge, curves to X=0 peak).
// Uses rotate_extrude to create a toroidal arc segment, then orients it.
//
// rotate_extrude(angle) sweeps a 2D profile (X≥0 half-plane) around the Z axis
// from +X toward +Y. We transform the result so the arc:
//   - starts at the left plate edge (x = -plate_width/2)
//   - curves upward in +Z
//   - has its depth along the Y axis
//
// Arc centre for left half is at (plate_width/2, 0, plate_thickness).
// Coordinate mapping: re_X → -X, re_Y → +Z, re_Z → +Y.
// This is achieved by rotate([90, 0, 180]).
module arch_wall_half(radius, wall_t, depth, sweep) {
    translate([plate_width / 2, 0, plate_thickness])
        rotate([90, 0, 180])
            translate([0, 0, -depth / 2])
                rotate_extrude(angle = sweep)
                    translate([radius, 0])
                        square([wall_t, depth]);
}

// ---------------------------------------------------------------------------
// 4. Component Modules
// ---------------------------------------------------------------------------

// Keyhole screw slot (cut volume — extends beyond plate surfaces)
module keyhole() {
    translate([0, 0, -0.01]) {
        // Bottom circle (screw head)
        translate([0, _keyhole_bottom_cy, 0])
            cylinder(d = keyhole_bottom_diameter, h = plate_thickness + 0.02);

        // Top narrow slot with semicircle top
        hull() {
            translate([0, _keyhole_bottom_cy, 0])
                cylinder(d = keyhole_top_width, h = plate_thickness + 0.02);
            translate([0, _keyhole_top_cy, 0])
                cylinder(d = keyhole_top_width, h = plate_thickness + 0.02);
        }
    }
}

// Backplate with keyhole
module backplate() {
    difference() {
        rounded_rect_centred(
            [plate_width, plate_height, plate_thickness],
            plate_corner_radius
        );
        keyhole();
    }
}

// Complete arch channel: outer wall + inner wall, left + right halves
module arch_channel() {
    for (radius = [arc_radius, _inner_radius]) {
        // Left half
        arch_wall_half(radius, arc_wall_thickness, arc_depth, arc_sweep);
        // Right half (mirror of left)
        mirror([1, 0, 0])
            arch_wall_half(radius, arc_wall_thickness, arc_depth, arc_sweep);
    }
}

// Full cap mount assembly
module cap_mount() {
    union() {
        backplate();
        arch_channel();
    }
}

// ---------------------------------------------------------------------------
// 5. Assembly (top-level geometry)
// ---------------------------------------------------------------------------

if (build_main) {
    cap_mount();
}

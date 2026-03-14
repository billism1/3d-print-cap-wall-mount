// =============================================================================
// Cap Wall Mount – Hat Display System
// =============================================================================
// A parametric wall-mounted cap/hat holder for displaying baseball caps in a
// grid matrix on a wall for display and selection.
//
// The mount consists of a flat backplate (with a keyhole screw slot) and one
// pair of concentric arc walls forming a channel. The arcs are partial rings
// in the XY plane, with their apex pointing +Y (upward when mounted).
// The arcs are extruded forward in +Z from the plate surface. A folded
// baseball cap's edge rides in the channel between the two walls.
//
// Model orientation: backplate in XY plane (Z=0..plate_thickness).
// Arcs are partial rings in XY, apex at +Y, extruded in +Z.
// =============================================================================

// ---------------------------------------------------------------------------
// 1. Constants & Parameters
// ---------------------------------------------------------------------------

// Backplate
plate_width              = 50;    // mm – plate width  (X axis)
plate_height             = 55;    // mm – plate height (Y axis)
plate_thickness          = 4;     // mm – plate thickness (Z axis)
plate_corner_radius      = 4;     // mm – fillet radius on plate corners

// Keyhole screw slot 
keyhole_total_height     = 13;    // mm – total height of keyhole slot
keyhole_bottom_diameter  = 8;     // mm – wide hole for screw head
keyhole_top_width        = 5;     // mm – narrow slot for screw shaft
keyhole_offset_y         = -5;    // mm – vertical offset from plate centre

// Bottom screw hole (below keyhole)
bottom_screw_hole_enabled = true;  // Whether to include the bottom screw hole
bottom_screw_hole_diameter = 5;    // mm – diameter of bottom screw hole
bottom_screw_hole_offset = 6;     // mm – gap between keyhole bottom edge and screw hole edge

// Arc channel (cap cradle) — concentric partial rings in XY, extruded in Z
arc_radius               = 80;    // mm – outer radius of outer wall
arc_sweep                = 38;    // deg – half-sweep from apex (total swing = 2×this)
arc_wall_thickness       = 3;     // mm – thickness of each arc wall
arc_channel_gap          = 10;    // mm – gap between walls (folded cap fits here)
arc_extrusion            = 25;    // mm – how far arcs extend forward from plate face

// Build flags
build_main               = true;  // Render the mount

// Resolution
$fn = 80;

// ---------------------------------------------------------------------------
// 2. Derived Dimensions
// ---------------------------------------------------------------------------

// Wall radii (measured from arc centre)
_outer_wall_inner_r      = arc_radius - arc_wall_thickness;
_inner_wall_outer_r      = _outer_wall_inner_r - arc_channel_gap;
_inner_wall_inner_r      = _inner_wall_outer_r - arc_wall_thickness;

// Z extent: arcs go through plate and extend forward
_arc_total_z             = plate_thickness + arc_extrusion;

// Arc centre: positioned so apex is at plate top edge (+Y)
_arc_center_y            = plate_height / 2 - arc_radius;

// Arc endpoint positions (where the arc ends meet the plate)
_arc_endpoint_x          = arc_radius * sin(arc_sweep);

echo(str("Channel gap: ", arc_channel_gap, " mm"));
echo(str("Outer wall: R ", _outer_wall_inner_r, " to ", arc_radius));
echo(str("Inner wall: R ", _inner_wall_inner_r, " to ", _inner_wall_outer_r));
echo(str("Arc centre Y: ", _arc_center_y));
echo(str("Arc apex Y: ", _arc_center_y + arc_radius));
echo(str("Arc endpoint X: ±", _arc_endpoint_x, " mm"));

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

// Partial ring in XY plane, symmetric about +Y axis, extruded in +Z.
//   radius : inner radius of the ring wall
//   wall_t : wall thickness (radial direction, outward)
//   height : Z extent (extrusion depth)
//   sweep  : half-sweep angle from +Y apex
module arc_ring(radius, wall_t, height, sweep) {
    rotate([0, 0, 90 - sweep])
        rotate_extrude(angle = 2 * sweep)
            translate([radius, 0])
                square([wall_t, height]);
}

// ---------------------------------------------------------------------------
// 4. Component Modules
// ---------------------------------------------------------------------------

// Keyhole screw slot (cut volume)
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

        // Bottom screw hole
        if (bottom_screw_hole_enabled)
            translate([0, _keyhole_bottom_cy - _keyhole_bottom_r - bottom_screw_hole_diameter / 2 - bottom_screw_hole_offset, 0])
                cylinder(d = bottom_screw_hole_diameter, h = plate_thickness + 0.02);
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

// Concentric arc channel: outer wall + inner wall, clipped to plate width
module arch_channel() {
    intersection() {
        // Clip to plate width in X
        translate([-plate_width / 2, -arc_radius * 2, -0.01])
            cube([plate_width, arc_radius * 4, _arc_total_z + 0.02]);

        translate([0, _arc_center_y, 0])
            union() {
                // Outer wall
                arc_ring(_outer_wall_inner_r, arc_wall_thickness,
                         _arc_total_z, arc_sweep);
                // Inner wall
                arc_ring(_inner_wall_inner_r, arc_wall_thickness,
                         _arc_total_z, arc_sweep);
            }
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

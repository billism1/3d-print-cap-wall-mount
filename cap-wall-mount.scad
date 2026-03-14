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
plate_height             = 50;    // mm – plate height (Y axis)
plate_thickness          = 4;     // mm – plate thickness (Z axis)
plate_corner_radius      = 4;     // mm – fillet radius on plate corners

// Keyhole screw slot 
screw_holes_enabled      = true;  // Whether to include the keyhole and screw holes
keyhole_total_height     = 13;    // mm – total height of keyhole slot
keyhole_bottom_diameter  = 8;     // mm – wide hole for screw head
keyhole_top_width        = 5;     // mm – narrow slot for screw shaft
keyhole_top_inset        = 20;     // mm – distance from plate top edge to keyhole top

// Bottom screw hole (below keyhole)
bottom_screw_hole_enabled = true;  // Whether to include the bottom screw hole
bottom_screw_hole_diameter = 5;    // mm – diameter of bottom screw hole
bottom_screw_hole_offset = 6;     // mm – gap between keyhole bottom edge and screw hole edge

// Countersink (tapered recess for drywall screw heads)
countersink_enabled      = true;  // Whether to add tapered countersinks
countersink_depth        = 2;     // mm – depth of the tapered countersink
countersink_extra_dia    = 4;     // mm – how much wider the countersink is than the hole

// Arc channel (cap cradle) — concentric partial rings in XY, extruded in Z
arc_radius               = 80;    // mm – outer radius of outer wall 
arc_sweep                = 38;    // deg – half-sweep from apex (total swing = 2×this)
arc_wall_thickness       = 2.25;     // mm – thickness of each arc wall
arc_channel_gap          = 10;    // mm – gap between walls (folded cap fits here)
arc_extrusion            = 25;    // mm – how far arcs extend forward from plate face
arc_top_inset            = 2;     // mm – distance from plate top edge to arc apex

// Strap ridge (prevents cap back strap from sliding forward off the arc)
strap_ridge_enabled      = true;  // Whether to add a ridge on the outer arc
strap_ridge_height       = 5;     // mm – how far the ridge protrudes inward (into the channel)
strap_ridge_width        = 4;     // mm – width of the ridge along the Z axis

// Build flags
build_main               = true;  // Render the mount

// Resolution
$fn = 180;

// ---------------------------------------------------------------------------
// 2. Derived Dimensions
// ---------------------------------------------------------------------------

// Wall radii (measured from arc centre)
_outer_wall_inner_r      = arc_radius - arc_wall_thickness;
_inner_wall_outer_r      = _outer_wall_inner_r - arc_channel_gap;
_inner_wall_inner_r      = _inner_wall_outer_r - arc_wall_thickness;

// Z extent: arcs go through plate and extend forward
_arc_total_z             = plate_thickness + arc_extrusion;

// Arc centre: positioned so apex is at plate top edge minus inset (+Y)
_arc_center_y            = plate_height / 2 - arc_top_inset - arc_radius;

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
// Top of keyhole (top of narrow slot semicircle) at plate_height/2 - inset
_keyhole_top_cy          = plate_height / 2 - keyhole_top_inset - _keyhole_top_r;
_keyhole_bottom_cy       = _keyhole_top_cy - keyhole_total_height
                           + _keyhole_top_r + _keyhole_bottom_r;

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

// Partial ring with a curved (quarter-circle) cross-section for smooth ridge.
// Sits at outer radius `radius`, curves outward by `height` and along Z by `width`.
// The tip is rounded by an offset-round technique.
module arc_ridge(radius, height, width, sweep) {
    _ridge_steps = 16;
    _tip_r = min(height, width) * 0.3;  // rounding radius for the sharp tip
    _ext = _tip_r * 2;                  // base extension to hide offset erosion
    rotate([0, 0, 90 - sweep])
        rotate_extrude(angle = 2 * sweep)
            translate([radius, 0])
                intersection() {
                    // Keep only the positive-X region (don't bleed into wall)
                    square([height + 1, width + 1]);
                    // Round outer corners; base edges extend deep into wall
                    // so offset erosion artifacts are fully clipped away
                    offset(r = _tip_r) offset(delta = -_tip_r)
                        polygon([
                            [-_ext, -_ext],
                            [-_ext, 0],
                            for (i = [0 : _ridge_steps])
                                let(a = 90 * i / _ridge_steps)
                                [height * (1 - cos(a)), width * sin(a)],
                            [-_ext, width],
                            [-_ext, width + _ext]
                        ]);
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

        // Countersink on keyhole narrow slot (wall side)
        if (countersink_enabled) {
            // Tapered recess along the narrow slot
            hull() {
                translate([0, _keyhole_bottom_cy, plate_thickness - countersink_depth])
                    cylinder(d1 = keyhole_top_width,
                             d2 = keyhole_top_width + countersink_extra_dia,
                             h = countersink_depth + 0.02);
                translate([0, _keyhole_top_cy, plate_thickness - countersink_depth])
                    cylinder(d1 = keyhole_top_width,
                             d2 = keyhole_top_width + countersink_extra_dia,
                             h = countersink_depth + 0.02);
            }
            // Tapered recess on bottom circle
            translate([0, _keyhole_bottom_cy, plate_thickness - countersink_depth])
                cylinder(d1 = keyhole_bottom_diameter,
                         d2 = keyhole_bottom_diameter + countersink_extra_dia,
                         h = countersink_depth + 0.02);
        }

        // Bottom screw hole
        if (bottom_screw_hole_enabled) {
            translate([0, _keyhole_bottom_cy - _keyhole_bottom_r - bottom_screw_hole_diameter / 2 - bottom_screw_hole_offset, 0])
                cylinder(d = bottom_screw_hole_diameter, h = plate_thickness + 0.02);

            // Countersink on bottom screw hole
            if (countersink_enabled)
                translate([0, _keyhole_bottom_cy - _keyhole_bottom_r - bottom_screw_hole_diameter / 2 - bottom_screw_hole_offset, plate_thickness - countersink_depth])
                    cylinder(d1 = bottom_screw_hole_diameter,
                             d2 = bottom_screw_hole_diameter + countersink_extra_dia,
                             h = countersink_depth + 0.02);
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
        if (screw_holes_enabled)
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

                // Strap ridge on outer face of outer wall at front edge (curved profile)
                if (strap_ridge_enabled)
                    translate([0, 0, _arc_total_z - strap_ridge_width])
                        arc_ridge(arc_radius,
                                  strap_ridge_height,
                                  strap_ridge_width,
                                  arc_sweep);
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

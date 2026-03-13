// =============================================================================
// Cap Wall Mount – Hat Display System
// =============================================================================
// A parametric wall-mounted cap/hat hook for displaying caps in a grid matrix.
// Each mount holds one cap by its rear adjuster strap or crown.
// Print multiple mounts and arrange them in rows and columns on a wall.
// Designed for FDM 3D printing (print backplate flat on bed, no supports).
// =============================================================================

// ---------------------------------------------------------------------------
// 1. Constants & Parameters
// ---------------------------------------------------------------------------

// Backplate
plate_width              = 60;    // mm – backplate width  (X axis)
plate_height             = 60;    // mm – backplate height (Y axis)
plate_thickness          = 5;     // mm – backplate thickness (Z axis, into wall)
plate_edge_radius        = 6;     // mm – fillet radius on backplate corners

// Hook / peg
hook_diameter            = 14;    // mm – diameter of the cylindrical hook peg
hook_length              = 70;    // mm – how far the hook extends from the wall
hook_angle               = 12;    // deg – upward tilt angle (prevents cap sliding off)
hook_tip_diameter        = 18;    // mm – diameter of anti-slip ball at hook tip
hook_tip_length          = 6;     // mm – length of the tip ball/mushroom cap

// Gusset (reinforcement between hook and backplate)
gusset_thickness         = 4;     // mm – thickness of the triangular support rib
gusset_depth             = 25;    // mm – how far along the hook the gusset extends
gusset_height            = 25;    // mm – how far up/down the backplate the gusset extends

// Screw holes (countersunk for flush wall mounting)
screw_hole_diameter      = 4.5;   // mm – through-hole for wall screw (M4 + clearance)
screw_head_diameter      = 9;     // mm – countersink diameter for screw head
screw_head_depth         = 2.5;   // mm – countersink depth
screw_vertical_offset    = 20;    // mm – distance from plate centre to each screw hole

// Grid layout (for reference / echo output)
grid_spacing_x           = 200;   // mm – recommended horizontal spacing between mounts
grid_spacing_y           = 180;   // mm – recommended vertical spacing between mounts

// Build flags
build_mount              = true;  // Whether to render the full mount (plate + hook)
build_hook_only          = false; // Render just the hook peg (if printing separately)

// Resolution
$fn = 96;

// ---------------------------------------------------------------------------
// 2. Derived Dimensions
// ---------------------------------------------------------------------------

// Rod length accounting for the angle
_hook_z_rise     = hook_length * sin(hook_angle);
_hook_y_extent   = hook_length * cos(hook_angle);

// Screw hole positions (two holes, vertically spaced on centreline)
_screw_positions = [
    [0,  screw_vertical_offset],
    [0, -screw_vertical_offset]
];

// Gusset profile points (right triangle in the YZ plane)
_gusset_profile = [
    [0, 0],
    [gusset_depth, 0],
    [0, gusset_height]
];

echo(str("Hook extends ", _hook_y_extent, " mm from wall, rises ",
         _hook_z_rise, " mm"));
echo(str("Suggested grid: ", grid_spacing_x, " mm x ", grid_spacing_y, " mm"));

// ---------------------------------------------------------------------------
// 3. Helper / Utility Modules
// ---------------------------------------------------------------------------

// Rounded rectangle centered on XY origin
module rounded_rect(size, r) {
    hull() {
        for (x = [r - size.x/2, size.x/2 - r],
             y = [r - size.y/2, size.y/2 - r])
            translate([x, y, 0])
                cylinder(r = r, h = size.z);
    }
}

// Countersunk screw hole (cut volume)
module countersunk_hole(d_through, d_head, h_total, h_head) {
    union() {
        // Through-hole
        cylinder(d = d_through, h = h_total + 0.02, center = false);
        // Countersink on top
        translate([0, 0, h_total - h_head])
            cylinder(d1 = d_through, d2 = d_head, h = h_head + 0.01);
    }
}

// ---------------------------------------------------------------------------
// 4. Component Modules
// ---------------------------------------------------------------------------

// The wall backplate with screw holes
module backplate() {
    difference() {
        // Plate body
        rounded_rect([plate_width, plate_height, plate_thickness], plate_edge_radius);

        // Screw holes
        for (pos = _screw_positions) {
            translate([pos.x, pos.y, -0.01])
                countersunk_hole(
                    screw_hole_diameter,
                    screw_head_diameter,
                    plate_thickness + 0.02,
                    screw_head_depth
                );
        }
    }
}

// The hook peg with anti-slip tip
module hook_peg() {
    // Main shaft
    cylinder(d = hook_diameter, h = hook_length);

    // Anti-slip mushroom tip
    translate([0, 0, hook_length])
        union() {
            // Tapered transition
            cylinder(d1 = hook_diameter, d2 = hook_tip_diameter,
                     h = hook_tip_length / 2);
            // Rounded end cap
            translate([0, 0, hook_tip_length / 2])
                resize([hook_tip_diameter, hook_tip_diameter, hook_tip_length])
                    sphere(d = hook_tip_diameter);
        }
}

// Triangular gusset rib for reinforcement
module gusset() {
    linear_extrude(gusset_thickness, center = true)
        polygon(_gusset_profile);
}

// Complete single mount assembly
module cap_mount() {
    union() {
        // Backplate lying in XY plane
        backplate();

        // Hook extending from plate centre, angled upward
        translate([0, 0, plate_thickness])
            rotate([-90 + hook_angle, 0, 0])
                hook_peg();

        // Gusset ribs (left and right of hook)
        translate([0, 0, plate_thickness])
            rotate([-90 + hook_angle, 0, 0])
                gusset();
    }
}

// ---------------------------------------------------------------------------
// 5. Assembly (top-level geometry)
// ---------------------------------------------------------------------------

if (build_mount) {
    cap_mount();
}

if (build_hook_only) {
    // Lay the hook on its side for printing
    translate([plate_width + 20, 0, hook_diameter / 2])
        rotate([0, 0, 0])
            hook_peg();
}

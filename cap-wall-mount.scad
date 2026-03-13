// =============================================================================
// Cap Wall Mount – Hat Display System
// =============================================================================
// A parametric wall-mounted cap/hat holder for displaying baseball caps in a
// grid matrix on a wall for display and selection.
//
// The mount consists of a flat backplate (with a keyhole screw slot) and two
// pairs of curved arc arms that form a channel/cradle. A folded baseball cap's
// edge rides between the inner and outer arc walls, with the bill extending
// forward and the logo visible.
//
// Designed for FDM 3D printing — prints on its side (X axis flat on bed)
// with no supports needed.
// =============================================================================

// ---------------------------------------------------------------------------
// 1. Constants & Parameters
// ---------------------------------------------------------------------------

// Backplate
plate_width              = 40;    // mm – plate width  (X axis)
plate_height             = 40;    // mm – plate height (Y axis, vertical when mounted)
plate_thickness          = 4;     // mm – plate thickness (Z axis, into wall)
plate_corner_radius      = 4;     // mm – fillet radius on plate corners

// Keyhole screw slot
keyhole_total_height     = 13;    // mm – total height of keyhole slot
keyhole_bottom_diameter  = 8;     // mm – wide hole for screw head
keyhole_top_width        = 5;     // mm – narrow slot for screw shaft
keyhole_offset_y         = 0;     // mm – vertical offset from plate centre

// Arc arms (cap cradle)
arc_radius               = 40;    // mm – radius of the arc curve
arc_sweep                = 60;    // deg – sweep angle of the arc
arc_wall_thickness       = 4;     // mm – thickness of each arc wall
arc_channel_gap          = 9;     // mm – gap between inner walls (cap fits here)
arc_width                = 40;    // mm – width of arcs (X axis, matches plate)

// Transition fillet
fillet_radius            = 4;     // mm – fillet where arcs meet backplate

// Build flags
build_main               = true;  // Render the mount in wall-mounted orientation
build_print_orientation  = false; // Render rotated 90° for FDM printing on side

// Resolution
$fn = 80;

// ---------------------------------------------------------------------------
// 2. Derived Dimensions
// ---------------------------------------------------------------------------

// Channel total width = wall + gap + wall
_channel_total           = arc_wall_thickness + arc_channel_gap + arc_wall_thickness;

echo(str("Channel total width: ", _channel_total, " mm"));
echo(str("Arc extension from wall: ", arc_radius * sin(arc_sweep), " mm"));
echo(str("Arc drop/rise from edge: ", arc_radius * (1 - cos(arc_sweep)), " mm"));

// Keyhole geometry
_keyhole_bottom_r        = keyhole_bottom_diameter / 2;
_keyhole_top_r           = keyhole_top_width / 2;
// Bottom circle centre: positioned so total height from bottom of circle
// to top of slot = keyhole_total_height
// Bottom of bottom circle at: centre_y - R_bottom
// Top of top slot at: centre_y - R_bottom + keyhole_total_height
_keyhole_bottom_cy       = keyhole_offset_y - keyhole_total_height / 2 + _keyhole_bottom_r;
_keyhole_top_cy          = _keyhole_bottom_cy + keyhole_total_height - _keyhole_top_r;

// Arc positioning: arcs start at top/bottom edges of plate
_upper_arc_centre_y      = plate_height / 2;
_lower_arc_centre_y      = -plate_height / 2;

// Channel offset: centre the channel on the plate's Z centreline
// The channel straddles the plate thickness centre
_channel_centre_z        = plate_thickness / 2;
_outer_wall_z            = _channel_centre_z - _channel_total / 2;
_inner_wall_z            = _channel_centre_z + arc_channel_gap / 2;

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

// A single arc wall: a curved shell segment
// Centred at origin, curving in the YZ plane.
// start_angle: 0 = pointing along +Y, positive = toward +Z
// Parameters: radius, sweep angle, wall thickness, width (X extent)
module arc_wall(radius, sweep, thickness, width) {
    translate([-width / 2, 0, 0])
        rotate([0, 90, 0])
            rotate_extrude(angle = sweep, $fn = $fn)
                translate([radius, 0, 0])
                    square([thickness, width]);
}

// Arc arm pair: outer wall + inner wall forming a channel
// Oriented so sweep starts along +Y and curves toward +Z
module arc_channel(radius, sweep, wall_t, gap, width) {
    outer_r = radius;
    inner_r = radius - wall_t - gap;

    // Outer wall
    arc_wall(outer_r, sweep, wall_t, width);

    // Inner wall
    arc_wall(inner_r, sweep, wall_t, width);
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
        // Slot from bottom circle centre up to top
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

// A single curved arc arm (outer + inner walls forming channel)
// sweep_direction: 1 = upper (curves from +Y toward +Z),
//                 -1 = lower (curves from -Y toward +Z)
module arc_arm(sweep_direction) {
    // Total channel width centred on plate thickness
    outer_r = arc_radius;
    inner_r = arc_radius - arc_wall_thickness - arc_channel_gap;

    // The arc_wall module uses rotate_extrude which sweeps in XY plane.
    // We need to orient arcs so they start tangent to the plate edge
    // and curve forward (toward +Z).
    //
    // Strategy: build arcs in a local frame then transform.
    // In local frame: rotate_extrude sweeps in XZ from +X toward +Z.
    // We want sweep from +Y toward +Z (upper) or -Y toward +Z (lower).

    // Position at plate edge, sweep forward
    edge_y = sweep_direction * plate_height / 2;

    translate([0, edge_y, 0]) {
        // For upper arc: start pointing along +Y (up), curve toward +Z (forward)
        // rotate_extrude in OpenSCAD sweeps around Z axis in XY plane.
        // We need to use a different approach: build the arc profile and
        // extrude along X.

        // Build each wall as a curved solid using hull of slices
        for (wall = [0, 1]) {
            // wall 0 = outer, wall 1 = inner
            wall_r = (wall == 0)
                ? outer_r
                : inner_r;

            // Arc centre is offset from the plate edge
            // For upper arc: centre is at (0, +arc_radius, 0) — so the arc
            // starts at the edge going along +Y and curves toward +Z
            // Actually: centre at y=0 in local frame means the arc starts
            // at radius distance along -Y (which is the plate edge).

            // Let's think of it differently:
            // Arc centre in local coords is at (0, 0, 0).
            // The plate edge is at distance arc_radius along -Y.
            // The arc sweeps from -Y toward +Z.

            // For the upper arc (sweep_direction=1):
            //   Centre is at y = plate_height/2 + arc_radius (above plate)
            //   No — we want arcs to start AT the plate edge.
            //   Arc centre is arc_radius BEHIND the plate surface (at z = -arc_radius)
            //   so the arc starts at z=0 (plate surface) going along ±Y.

            // Simpler approach: parametric arc in YZ using hull of small segments
        }
    }
}

// Full cap mount (wall-mounted orientation)
// Built using parametric arc segments via hull chains
module cap_mount() {
    union() {
        // --- Backplate ---
        backplate();

        // --- Arc arms ---
        // Each arc is built as a hull-chain of small cuboid slices along
        // the arc path. Two walls per arc (outer + inner) with a gap.

        _seg_count = 12;  // Number of segments for smooth arc
        _seg_angle = arc_sweep / _seg_count;

        for (side = [1, -1]) {
            // side = 1: upper arc (top of plate, curves forward+down)
            // side = -1: lower arc (bottom of plate, curves forward+up)

            // Arc centre: at the plate edge, offset back by arc_radius
            // in the Z direction, so the arc starts at z = 0 (plate front face)
            // pointing along Y (up for upper, down for lower) and curves toward +Z.
            //
            // Centre position:
            //   y = side * plate_height/2
            //   z = plate_thickness  (front face of plate)
            // Arc is in local YZ plane, starts along side*Y, curves to +Z.
            // Parametrically:
            //   point(angle) = centre + R * [0, side*cos(angle), sin(angle)]
            // At angle=0: point at centre + R*[0, side, 0] — but we want start
            // AT the plate edge, so centre must be offset.
            //
            // Let's place arc centre at:
            //   (0, side * (plate_height/2), plate_thickness - but really at 0)
            // No. Let's think physically:
            //
            // The arc starts at the plate front surface (z = plate_thickness)
            // at the top/bottom edge (y = ±plate_height/2).
            // The arc curves forward (increasing z) and inward (toward y=0).
            //
            // Arc centre in YZ:
            //   y_c = side * plate_height/2
            //   z_c = plate_thickness
            // Start angle = side > 0 ? 90° (pointing +Y) : -90° (pointing -Y)
            //   ... relative to +Z axis.
            // The point on the arc: 
            //   y(a) = y_c + R * sin(start + side*a)  -- NO, let's be explicit.
            //
            // Upper arc (side=1):
            //   At angle 0: touch plate edge, pointing up (+Y)
            //   At angle 60°: curved forward and somewhat down
            //   y(a) = y_c + R * cos(a)    -- at a=0, y = y_c + R (above centre)
            //   z(a) = z_c + R * sin(a)    -- at a=0, z = z_c (at plate face)
            //   But we want y(0) = plate_height/2, so y_c = plate_height/2 - R
            //
            // That places the arc centre well below the plate for upper...
            // and the arc goes: at a=0 y=plate_height/2, z=plate_thickness
            //                   at a=60° y=y_c + R*cos60 = y_c + R/2
            //                            z=z_c + R*sin60 = z_c + R*0.866
            //
            // For lower arc (side=-1):
            //   y(a) = y_c - R * cos(a)  with y_c = -plate_height/2 + R
            //   z(a) = z_c + R * sin(a)

            _y_c = side * (plate_height / 2 - arc_radius);
            _z_c = plate_thickness;

            for (wall = [0, 1]) {
                // wall 0 = outer (further from channel centre)
                // wall 1 = inner (closer to channel centre)
                //
                // Channel is centred in X (width) direction — no, the channel
                // exists along the Z/thickness direction.
                //
                // Actually: the two walls are offset in the radial direction.
                // Outer wall: at radius R
                // Inner wall: at radius R - wall_t - gap
                //
                // But we want the channel to grip the cap. The cap material
                // sits between the two walls. So:
                // Outer wall: radius R to R + wall_t (further from cap)
                // Inner wall: radius R - gap to R - gap - wall_t (closer)
                //
                // Let's define: outer wall inner surface at R_outer
                //               inner wall outer surface at R_outer - gap
                // Outer wall: R_outer to R_outer + wall_t
                // Inner wall: R_outer - gap - wall_t to R_outer - gap

                _r_wall = (wall == 0)
                    ? arc_radius                               // Outer wall at R
                    : arc_radius - arc_wall_thickness - arc_channel_gap;  // Inner wall

                // Build arc as hull-chain of slices
                for (i = [0 : _seg_count - 1]) {
                    _a0 = i * _seg_angle;
                    _a1 = (i + 1) * _seg_angle;

                    hull() {
                        for (a = [_a0, _a1]) {
                            // Position along arc for this wall
                            _y = _y_c + side * _r_wall * cos(a);
                            _z = _z_c + _r_wall * sin(a);
                            // Position for wall outer edge
                            _y2 = _y_c + side * (_r_wall + arc_wall_thickness) * cos(a);
                            _z2 = _z_c + (_r_wall + arc_wall_thickness) * sin(a);

                            // Create a thin slice oriented along the arc normal
                            hull() {
                                translate([0, _y, _z])
                                    cube([arc_width, 0.01, 0.01], center = true);
                                translate([0, _y2, _z2])
                                    cube([arc_width, 0.01, 0.01], center = true);
                            }
                        }
                    }
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// 5. Assembly (top-level geometry)
// ---------------------------------------------------------------------------

if (build_main) {
    cap_mount();
}

if (build_print_orientation) {
    // Rotate 90° to lay on side for FDM printing
    // X axis (40mm width) becomes the build height
    rotate([0, -90, 0])
        cap_mount();
}

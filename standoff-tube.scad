// =============================================================================
// Standoff Tube
// =============================================================================
// A simple cylindrical standoff / spacer tube for FDM printing.
// =============================================================================

// ---------------------------------------------------------------------------
// 1. Constants & Parameters
// ---------------------------------------------------------------------------

inner_diameter = 5.5;   // mm – bore diameter
wall_thickness = 4;     // mm – radial wall thickness
length         = 18;    // mm – total tube length (Z axis)
flat_edge      = false; // add a flat along the length for printing on its side

// Resolution
$fn = 180;

// ---------------------------------------------------------------------------
// 2. Derived Dimensions
// ---------------------------------------------------------------------------

outer_diameter = inner_diameter + 2 * wall_thickness;
_flat_cut      = outer_diameter / 2 - wall_thickness * 0.1; // cut depth leaves a flat

// ---------------------------------------------------------------------------
// 3. Assembly
// ---------------------------------------------------------------------------

difference() {
    intersection() {
        cylinder(d = outer_diameter, h = length);
        if (flat_edge)
            translate([-outer_diameter / 2, -_flat_cut, 0])
                cube([outer_diameter, _flat_cut + outer_diameter / 2, length]);
    }
    translate([0, 0, -0.01])
        cylinder(d = inner_diameter, h = length + 0.02);
}

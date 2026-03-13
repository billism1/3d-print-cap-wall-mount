// =============================================================================
// Cap Wall Mount – Hat Display System
// =============================================================================
// A parametric wall-mounted cap/hat holder for displaying caps in a grid matrix
// on a wall for display and selection.
// Designed for FDM 3D printing.
// =============================================================================

// ---------------------------------------------------------------------------
// 1. Constants & Parameters
// ---------------------------------------------------------------------------

// (Add parameters here as the design evolves)

// Build flags
build_main               = true;  // Whether to render the main part

// Resolution
$fn = 96;

// ---------------------------------------------------------------------------
// 2. Derived Dimensions
// ---------------------------------------------------------------------------

// (Computed values go here)

// ---------------------------------------------------------------------------
// 3. Helper / Utility Modules
// ---------------------------------------------------------------------------

// Rounded rectangle in XY plane
module rounded_rect(size, r) {
    hull() {
        for (x = [r, size.x - r], y = [r, size.y - r])
            translate([x, y, 0])
                cylinder(r = r, h = size.z);
    }
}

// ---------------------------------------------------------------------------
// 4. Component Modules
// ---------------------------------------------------------------------------

// (Design components go here)

// ---------------------------------------------------------------------------
// 5. Assembly (top-level geometry)
// ---------------------------------------------------------------------------

if (build_main) {
    // (Assemble components here)
}

# Cap Wall Mount – Hat Display System

A 3D-printable wall mount for displaying baseball caps and hats in a grid/matrix arrangement. Each mount holds one cap by its rear adjuster strap or crown, and multiple mounts can be arranged in rows and columns on a wall for easy selection.

## Features

- **Parametric design** — adjust backplate size, hook length, angle, screw positions, and grid spacing; everything adapts automatically.
- **Single-piece mount** — backplate, hook, and gusset print as one part with no assembly required.
- **Anti-slip tip** — mushroom-shaped hook tip prevents caps from sliding off.
- **Reinforced** — triangular gusset rib distributes load between hook and backplate.
- **FDM-friendly** — prints backplate-down with no supports needed; countersunk screw holes for flush wall mounting.
- **Grid-ready** — recommended spacing parameters for consistent matrix layout.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `plate_width` | 60 mm | Backplate width (X axis) |
| `plate_height` | 60 mm | Backplate height (Y axis) |
| `plate_thickness` | 5 mm | Backplate thickness |
| `plate_edge_radius` | 6 mm | Fillet radius on backplate corners |
| `hook_diameter` | 14 mm | Diameter of the cylindrical hook peg |
| `hook_length` | 70 mm | How far the hook extends from the wall |
| `hook_angle` | 12° | Upward tilt angle (prevents cap sliding off) |
| `hook_tip_diameter` | 18 mm | Diameter of anti-slip mushroom tip |
| `hook_tip_length` | 6 mm | Length of the tip cap |
| `gusset_thickness` | 4 mm | Thickness of the triangular support rib |
| `gusset_depth` | 25 mm | How far along the hook the gusset extends |
| `gusset_height` | 25 mm | How far up the backplate the gusset extends |
| `screw_hole_diameter` | 4.5 mm | Through-hole diameter (M4 + clearance) |
| `screw_head_diameter` | 9 mm | Countersink diameter for screw head |
| `screw_head_depth` | 2.5 mm | Countersink depth |
| `screw_vertical_offset` | 20 mm | Distance from plate centre to each screw hole |
| `grid_spacing_x` | 200 mm | Recommended horizontal spacing between mounts |
| `grid_spacing_y` | 180 mm | Recommended vertical spacing between mounts |
| `build_mount` | true | Whether to render the full mount |
| `build_hook_only` | false | Render just the hook peg separately |

## Wall Layout

Arrange mounts in a grid with the recommended spacing (200 mm × 180 mm) to allow caps to hang without overlapping. A typical layout:

```
    200mm   200mm
  ┌───┐   ┌───┐   ┌───┐
  │ ● │   │ ● │   │ ● │  ─┐
  └───┘   └───┘   └───┘   │ 180mm
  ┌───┐   ┌───┐   ┌───┐   │
  │ ● │   │ ● │   │ ● │  ─┘
  └───┘   └───┘   └───┘
```

For a 3×4 grid (12 caps), you need approximately **600 mm × 720 mm** of wall space.

## Usage

1. Open `cap-wall-mount.scad` in [OpenSCAD](https://openscad.org/).
2. Adjust parameters at the top of the file to suit your caps and wall.
3. Use the build flags to export each part separately if needed.
4. Render (**F6**) and export to STL (**F7**).
5. Slice and print — no supports needed (print with backplate flat on bed).
6. Mount to wall with two screws per mount.

## Printing Tips

- **Material**: PLA or PETG recommended. PETG is stronger for load-bearing.
- **Infill**: 30–50% for good strength on the hook.
- **Layer height**: 0.2 mm works well.
- **Orientation**: Print with the backplate flat on the build plate. The hook and gusset grow upward.

## License

This project is provided as-is for personal and educational use.

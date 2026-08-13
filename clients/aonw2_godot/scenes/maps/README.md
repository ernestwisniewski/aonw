# Generated Map Scenes

The AoNW Map Workbench writes one Godot 3D scene per map in this directory.
Each scene references client-owned resources under `res://assets/generated_maps`.
Logical source content remains in `content/maps/`; Flutter sources remain
unchanged. Godot may reuse their JPG slices as reference artwork,
but it loads logical JSON only from the versioned content root.

"""
Procedurally generate a simple 3D boat model in Blender.

Usage (headless):
  blender --background --factory-startup --python tools/blender_generate_boat.py -- \
    --output /absolute/path/to/boat.glb

You can pass parameters after the `--` separator. Example:
  blender --background --factory-startup --python tools/blender_generate_boat.py -- \
    --length 8 --beam 2.2 --draft 0.9 --stations 28 --segments 18 --output /tmp/boat.glb
"""

from __future__ import annotations

import argparse
import math
import sys
from typing import Optional, Tuple

import bpy
import bmesh
from mathutils import Vector


def _parse_args(argv) -> argparse.Namespace:
    # Blender puts its own args before `--`. Everything after `--` is ours.
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
    else:
        argv = []

    p = argparse.ArgumentParser(description="Generate a simple procedural boat mesh.")
    p.add_argument("--length", type=float, default=8.0, help="Boat length in meters.")
    p.add_argument("--beam", type=float, default=2.2, help="Boat beam (width) in meters.")
    p.add_argument("--draft", type=float, default=0.9, help="Boat draft (keel depth) in meters.")
    p.add_argument("--stations", type=int, default=28, help="Number of lengthwise cross-sections (>= 6).")
    p.add_argument("--segments", type=int, default=18, help="Cross-section segments from starboard to port (>= 8).")
    p.add_argument("--freeboard", type=float, default=0.45, help="Cabin/deck height above deck plane (m).")
    p.add_argument("--cabin", action="store_true", help="Add a simple cabin block.")
    p.add_argument("--mast", action="store_true", help="Add a simple mast.")
    p.add_argument("--output", type=str, default="", help="Optional path to export (.glb or .gltf).")
    p.add_argument("--export_apply_modifiers", action="store_true", help="Apply modifiers when exporting.")
    return p.parse_args(argv)


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

    # Purge orphan data blocks without UI-dependent operators (works headless).
    def _purge_orphans():
        for datablocks in (
            bpy.data.meshes,
            bpy.data.materials,
            bpy.data.images,
            bpy.data.textures,
            bpy.data.curves,
            bpy.data.collections,
        ):
            for block in list(datablocks):
                if block.users == 0:
                    try:
                        datablocks.remove(block)
                    except Exception:
                        pass

    _purge_orphans()
    _purge_orphans()


def ensure_collection(name: str) -> bpy.types.Collection:
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(col)
    return col


def set_active(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)


def make_material(name: str, base_color=(1, 1, 1, 1), roughness=0.6) -> bpy.types.Material:
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Roughness"].default_value = roughness
    return mat


def hull_profile_factors(t: float) -> Tuple[float, float]:
    """
    Return (width_factor, draft_factor) at normalized length position t in [0..1].
    Bow and stern taper to zero width; midship is widest.
    """
    # Smooth "bulb" in the middle; zero at ends.
    w = math.sin(math.pi * t)
    w = w * w  # sharpen a bit

    # Slightly deeper amidships.
    d = 0.75 + 0.25 * math.sin(math.pi * t)
    return w, d


def build_hull_mesh(
    *,
    name: str,
    length: float,
    beam: float,
    draft: float,
    stations: int,
    segments: int,
) -> bpy.types.Object:
    stations = max(6, stations)
    segments = max(8, segments)

    # Create a mesh via bmesh.
    mesh = bpy.data.meshes.new(name + "Mesh")
    obj = bpy.data.objects.new(name, mesh)

    bm = bmesh.new()

    x0 = -length * 0.5
    dx = length / (stations - 1)
    half_beam = beam * 0.5

    # Rings: for each station i, we create (segments+1) verts along theta [0..pi]
    # y = halfWidth * cos(theta), z = -draftLocal * sin(theta)
    ring_verts = []
    for i in range(stations):
        t = i / (stations - 1)
        wf, df = hull_profile_factors(t)
        half_w = max(0.01, half_beam * wf)  # avoid degeneracy at ends
        d = max(0.02, draft * df)
        x = x0 + i * dx

        ring = []
        for j in range(segments + 1):
            theta = (j / segments) * math.pi  # 0..pi
            y = half_w * math.cos(theta)
            z = -d * math.sin(theta)
            ring.append(bm.verts.new((x, y, z)))
        ring_verts.append(ring)

    bm.verts.ensure_lookup_table()

    # Skin faces between rings
    for i in range(stations - 1):
        r0 = ring_verts[i]
        r1 = ring_verts[i + 1]
        for j in range(segments):
            v00 = r0[j]
            v10 = r1[j]
            v11 = r1[j + 1]
            v01 = r0[j + 1]
            # Avoid duplicates if Blender has already created it.
            try:
                bm.faces.new((v00, v10, v11, v01))
            except ValueError:
                pass

    # Finish mesh
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    # Smooth shading (Blender 4.x removed Mesh.use_auto_smooth; keep this version-safe)
    for p in mesh.polygons:
        p.use_smooth = True
    if hasattr(mesh, "use_auto_smooth"):
        mesh.use_auto_smooth = True
        if hasattr(mesh, "auto_smooth_angle"):
            mesh.auto_smooth_angle = math.radians(30.0)
    else:
        # Blender 4.x: try to enable "Shade Auto Smooth" if available; ignore if not.
        try:
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            bpy.ops.object.shade_auto_smooth(angle=math.radians(30.0))
        except Exception:
            pass

    # Add modifiers for nicer silhouette
    subd = obj.modifiers.new(name="Subdivision", type="SUBSURF")
    subd.levels = 2
    subd.render_levels = 2

    bevel = obj.modifiers.new(name="Bevel", type="BEVEL")
    bevel.width = 0.01
    bevel.segments = 2
    bevel.limit_method = "ANGLE"

    return obj


def build_deck(
    *,
    name: str,
    length: float,
    beam: float,
    z: float = 0.0,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, 0, z))
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (length * 0.5, beam * 0.5, 1.0)
    # Slight bevel to avoid razor edges
    bevel = obj.modifiers.new(name="Bevel", type="BEVEL")
    bevel.width = 0.02
    bevel.segments = 2
    bevel.limit_method = "ANGLE"
    return obj


def build_cabin(
    *,
    name: str,
    length: float,
    beam: float,
    freeboard: float,
) -> bpy.types.Object:
    # Small block near stern
    cab_len = length * 0.28
    cab_beam = beam * 0.55
    cab_h = max(0.2, freeboard)
    cab_x = length * -0.10
    cab_z = cab_h * 0.5

    bpy.ops.mesh.primitive_cube_add(location=(cab_x, 0, cab_z))
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (cab_len * 0.5, cab_beam * 0.5, cab_h * 0.5)

    bevel = obj.modifiers.new(name="Bevel", type="BEVEL")
    bevel.width = 0.03
    bevel.segments = 3
    bevel.limit_method = "ANGLE"
    return obj


def build_mast(
    *,
    name: str,
    length: float,
    beam: float,
    height: float,
) -> bpy.types.Object:
    radius = max(0.02, beam * 0.03)
    x = length * 0.12
    z = height * 0.5
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=height, location=(x, 0, z))
    obj = bpy.context.active_object
    obj.name = name
    return obj


def parent_to(parent: bpy.types.Object, child: bpy.types.Object) -> None:
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()


def export_if_requested(path: str, apply_modifiers: bool) -> None:
    if not path:
        return
    lower = path.lower()
    if lower.endswith(".glb") or lower.endswith(".gltf"):
        bpy.ops.export_scene.gltf(
            filepath=path,
            export_format="GLB" if lower.endswith(".glb") else "GLTF_SEPARATE",
            export_apply=apply_modifiers,
            export_yup=True,
            export_normals=True,
            export_materials="EXPORT",
        )
    else:
        raise ValueError("Unsupported export format. Use .glb or .gltf")


def main() -> None:
    args = _parse_args(sys.argv)

    reset_scene()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0

    col = ensure_collection("ProceduralBoat")

    hull = build_hull_mesh(
        name="BoatHull",
        length=args.length,
        beam=args.beam,
        draft=args.draft,
        stations=args.stations,
        segments=args.segments,
    )
    col.objects.link(hull)
    bpy.context.scene.collection.objects.unlink(hull)

    deck = build_deck(name="BoatDeck", length=args.length * 0.92, beam=args.beam * 0.92, z=0.0)
    col.objects.link(deck)
    bpy.context.scene.collection.objects.unlink(deck)

    cabin_obj: Optional[bpy.types.Object] = None
    if args.cabin:
        cabin_obj = build_cabin(
            name="BoatCabin",
            length=args.length,
            beam=args.beam,
            freeboard=args.freeboard,
        )
        col.objects.link(cabin_obj)
        bpy.context.scene.collection.objects.unlink(cabin_obj)

    mast_obj: Optional[bpy.types.Object] = None
    if args.mast:
        mast_obj = build_mast(
            name="BoatMast",
            length=args.length,
            beam=args.beam,
            height=max(1.5, args.length * 0.6),
        )
        col.objects.link(mast_obj)
        bpy.context.scene.collection.objects.unlink(mast_obj)

    # Assign simple materials
    mat_hull = make_material("MAT_Hull", base_color=(0.12, 0.08, 0.05, 1), roughness=0.55)
    mat_deck = make_material("MAT_Deck", base_color=(0.55, 0.46, 0.32, 1), roughness=0.65)
    mat_cabin = make_material("MAT_Cabin", base_color=(0.82, 0.82, 0.85, 1), roughness=0.35)
    mat_mast = make_material("MAT_Mast", base_color=(0.35, 0.28, 0.2, 1), roughness=0.6)

    if hull.data.materials:
        hull.data.materials[0] = mat_hull
    else:
        hull.data.materials.append(mat_hull)

    if deck.data.materials:
        deck.data.materials[0] = mat_deck
    else:
        deck.data.materials.append(mat_deck)

    if cabin_obj:
        if cabin_obj.data.materials:
            cabin_obj.data.materials[0] = mat_cabin
        else:
            cabin_obj.data.materials.append(mat_cabin)

    if mast_obj:
        if mast_obj.data.materials:
            mast_obj.data.materials[0] = mat_mast
        else:
            mast_obj.data.materials.append(mat_mast)

    # Create an empty root for easy moving/export
    root = bpy.data.objects.new("BoatRoot", None)
    col.objects.link(root)
    root.location = Vector((0, 0, 0))

    parent_to(root, hull)
    parent_to(root, deck)
    if cabin_obj:
        parent_to(root, cabin_obj)
    if mast_obj:
        parent_to(root, mast_obj)

    # Frame the scene a bit (helpful if opened interactively)
    bpy.context.scene.frame_set(1)

    export_if_requested(args.output, args.export_apply_modifiers)


if __name__ == "__main__":
    main()



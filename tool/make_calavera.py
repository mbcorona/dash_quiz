#!/usr/bin/env python3
"""Builds assets/calavera.glb: a Day of the Dead sugar skull wearing a
Catrina hat with marigolds.

Everything is generated here, with no dependencies beyond the standard
library: the skull is a deformed sphere, the sugar-skull paint is drawn into
a texture, and the hat and flowers are simple solids.

    python3 tool/make_calavera.py [--front -1|1]

--front picks which way the face points: 1 is +Z (the glTF convention).
"""

import json
import math
import os
import struct
import sys
import zlib

FRONT = 1
if '--front' in sys.argv:
    FRONT = int(sys.argv[sys.argv.index('--front') + 1])

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'calavera.glb')

# ---------------------------------------------------------------- texture

W = H = 1024
TAU = 2 * math.pi

IVORY = (246, 241, 230)
WHITE = (255, 255, 255)
BLACK = (22, 18, 26)
MAGENTA = (214, 30, 110)
ORANGE = (247, 130, 20)
YELLOW = (250, 205, 40)
TEAL = (20, 160, 165)
PURPLE = (110, 40, 150)
RED = (205, 35, 55)

img = bytearray(bytes(IVORY) * (W * H))


# Shapes are described in angles on the sphere: longitude (0 at the front)
# and elevation (0 at the equator, positive up), both in radians. The
# texture is an equirectangular map of those angles.
def to_px(lon, e):
    return (0.5 + lon / TAU) * W, (0.5 - e / math.pi) * H


def draw(color, shape):
    inside, (lon0, lon1, e0, e1) = shape
    x0, y1 = to_px(lon0, e0)
    x1, y0 = to_px(lon1, e1)
    x0 = max(0, int(x0) - 1)
    x1 = min(W - 1, int(x1) + 1)
    y0 = max(0, int(y0) - 1)
    y1 = min(H - 1, int(y1) + 1)
    for py in range(y0, y1 + 1):
        for px in range(x0, x1 + 1):
            cov = 0
            for sy in (0.25, 0.75):
                e = (0.5 - (py + sy) / H) * math.pi
                for sx in (0.25, 0.75):
                    lon = ((px + sx) / W - 0.5) * TAU
                    if inside(lon, e):
                        cov += 1
            if cov:
                a = cov / 4
                i = (py * W + px) * 3
                for k in range(3):
                    img[i + k] = int(img[i + k] * (1 - a) + color[k] * a + 0.5)


def ellipse(cx, cy, a, b, rot=0.0):
    cr, sr = math.cos(rot), math.sin(rot)

    def inside(x, y):
        dx, dy = x - cx, y - cy
        u = dx * cr + dy * sr
        v = -dx * sr + dy * cr
        return (u / a) ** 2 + (v / b) ** 2 <= 1

    m = max(a, b)
    return inside, (cx - m, cx + m, cy - m, cy + m)


def circle(cx, cy, r):
    return ellipse(cx, cy, r, r)


def ring(cx, cy, r, width):
    lo, hi = r - width / 2, r + width / 2

    def inside(x, y):
        d = math.hypot(x - cx, y - cy)
        return lo <= d <= hi

    return inside, (cx - hi, cx + hi, cy - hi, cy + hi)


def capsule(x0, y0, x1, y1, r):
    dx, dy = x1 - x0, y1 - y0
    l2 = dx * dx + dy * dy

    def inside(x, y):
        t = 0 if l2 == 0 else max(0, min(1, ((x - x0) * dx + (y - y0) * dy) / l2))
        return math.hypot(x - (x0 + t * dx), y - (y0 + t * dy)) <= r

    return inside, (
        min(x0, x1) - r, max(x0, x1) + r, min(y0, y1) - r, max(y0, y1) + r,
    )


def polygon(pts):
    def inside(x, y):
        hit = False
        n = len(pts)
        for i in range(n):
            (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % n]
            if (ya > y) != (yb > y):
                xi = xa + (y - ya) * (xb - xa) / (yb - ya)
                if x < xi:
                    hit = not hit
        return hit

    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return inside, (min(xs), max(xs), min(ys), max(ys))


def petals(cx, cy, n, dist, length, width, colors, phase=0.0):
    for k in range(n):
        ang = phase + TAU * k / n
        px = cx + math.cos(ang) * dist
        py = cy + math.sin(ang) * dist
        draw(colors[k % len(colors)], ellipse(px, py, length, width, ang))


def dots(cx, cy, n, dist, r, color, phase=0.0):
    for k in range(n):
        ang = phase + TAU * k / n
        draw(color, circle(cx + math.cos(ang) * dist, cy + math.sin(ang) * dist, r))


def mouth_e(lon):
    """Elevation of the mouth line; it curves up at the ends into a smile."""
    return -0.52 + 0.08 * (lon / 0.55) ** 2


def paint_face():
    # Eyes: a ring of petals and dots around a black socket.
    for side in (-1, 1):
        cx, cy = side * 0.46, 0.10
        petals(cx, cy, 14, 0.36, 0.09, 0.045, [MAGENTA, ORANGE])
        dots(cx, cy, 14, 0.48, 0.022, TEAL, phase=math.pi / 14)
        draw(BLACK, ellipse(cx, cy, 0.28, 0.26))
        draw(YELLOW, ring(cx, cy, 0.19, 0.03))
        draw(TEAL, circle(cx, cy, 0.045))
        # Teardrops under the eye.
        draw(TEAL, ellipse(cx + side * 0.06, -0.24, 0.028, 0.04))
        draw(TEAL, ellipse(cx + side * 0.1, -0.33, 0.02, 0.03))

    # Nose: the upside-down heart of a skull.
    draw(BLACK, polygon([(-0.105, -0.265), (0.105, -0.265), (0, -0.15)]))
    draw(BLACK, circle(-0.055, -0.27, 0.055))
    draw(BLACK, circle(0.055, -0.27, 0.055))

    # Teeth: a white band outlined in black with the stitched tooth lines.
    top = [(lon / 20, mouth_e(lon / 20) + 0.1) for lon in range(-11, 12)]
    bottom = [(lon / 20, mouth_e(lon / 20) - 0.1) for lon in range(11, -12, -1)]
    draw(WHITE, polygon(top + bottom))
    for off in (0.1, 0, -0.1):
        r = 0.012 if off == 0 else 0.008
        for k in range(-11, 11):
            a, b = k / 20, (k + 1) / 20
            draw(BLACK, capsule(a, mouth_e(a) + off, b, mouth_e(b) + off, r))
    for k in range(-4, 5):
        lon = k * 0.11
        draw(BLACK, capsule(lon, mouth_e(lon) + 0.1, lon, mouth_e(lon) - 0.1, 0.008))

    # Forehead marigold with swirls trailing off to each side.
    petals(0, 0.55, 10, 0.14, 0.12, 0.06, [ORANGE])
    draw(YELLOW, circle(0, 0.55, 0.1))
    draw(MAGENTA, circle(0, 0.55, 0.045))
    for side in (-1, 1):
        for k in range(7):
            t = k / 6
            draw(
                TEAL,
                circle(side * (0.32 + 0.3 * t), 0.58 - 0.22 * t * t, 0.032 - 0.016 * t),
            )

    # Cheek flowers.
    for side in (-1, 1):
        cx, cy = side * 0.95, -0.2
        petals(cx, cy, 6, 0.08, 0.07, 0.035, [PURPLE])
        draw(YELLOW, circle(cx, cy, 0.04))
        draw(MAGENTA, circle(cx + side * 0.2, cy + 0.12, 0.03))
        draw(MAGENTA, circle(cx + side * 0.24, cy - 0.04, 0.022))

    # Chin: a web of dots narrowing to a point.
    for row, count in enumerate((5, 3, 1)):
        e = -0.74 - row * 0.1
        for k in range(count):
            lon = (k - (count - 1) / 2) * 0.1
            draw(PURPLE, circle(lon, e, 0.028))

    # Big flowers on the sides of the head.
    for side in (-1, 1):
        cx, cy = side * 2.2, 0.15
        petals(cx, cy, 12, 0.2, 0.16, 0.08, [RED, MAGENTA])
        draw(YELLOW, circle(cx, cy, 0.13))
        draw(TEAL, circle(cx, cy, 0.06))
        dots(cx, cy, 12, 0.42, 0.028, TEAL, phase=math.pi / 12)

    # A ring of dots around the crown, under the hat brim.
    for k in range(36):
        lon = -math.pi + (k + 0.5) * TAU / 36
        draw(ORANGE, circle(lon, 0.78, 0.03))


def png_bytes():
    raw = b''.join(
        b'\x00' + bytes(img[y * W * 3:(y + 1) * W * 3]) for y in range(H)
    )

    def chunk(tag, data):
        return (
            struct.pack('>I', len(data)) + tag + data
            + struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    return (
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0))
        + chunk(b'IDAT', zlib.compress(raw, 9))
        + chunk(b'IEND', b'')
    )


# --------------------------------------------------------------- geometry


class Prim:
    """One glTF primitive being assembled: positions, normals, uvs, indices."""

    def __init__(self, material):
        self.material = material
        self.pos = []
        self.nrm = []
        self.uv = []
        self.idx = []

    def add_grid(self, segs, rings, point, outward):
        """Adds a (segs x rings) surface. point(j, i) returns a position and
        a uv for column j (0..segs) and row i (0..rings). outward is a point
        inside the surface, used to orient the triangles."""
        base = len(self.pos)
        pos = []
        for i in range(rings + 1):
            for j in range(segs + 1):
                p, uv = point(j, i)
                pos.append(p)
                self.uv.append(uv)
        tris = []
        for i in range(rings):
            for j in range(segs):
                a = i * (segs + 1) + j
                b = a + segs + 1
                tris.append((a, b, a + 1))
                tris.append((a + 1, b, b + 1))
        nrm = [[0.0, 0.0, 0.0] for _ in pos]
        for (a, b, c) in tris:
            n = cross(sub(pos[b], pos[a]), sub(pos[c], pos[a]))
            for v in (a, b, c):
                nrm[v] = add(nrm[v], n)
        # Vertices on the seam (first and last column) are the same point.
        for i in range(rings + 1):
            a, b = i * (segs + 1), i * (segs + 1) + segs
            s = add(nrm[a], nrm[b])
            nrm[a] = nrm[b] = s
        # Pole rows share one point too.
        for i in (0, rings):
            row = range(i * (segs + 1), i * (segs + 1) + segs + 1)
            s = [0.0, 0.0, 0.0]
            for v in row:
                s = add(s, nrm[v])
            for v in row:
                nrm[v] = s
        self._commit(base, pos, nrm, tris, outward)

    def add_cap(self, center, radius, normal, segs):
        """A flat disc; normal is +1 for facing up or -1 for down."""
        base = len(self.pos)
        pos = [center]
        self.uv.append((0.5, 0.5))
        for j in range(segs):
            a = TAU * j / segs
            pos.append((center[0] + radius * math.cos(a), center[1],
                        center[2] + radius * math.sin(a)))
            self.uv.append((0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a)))
        tris = [(0, 1 + j, 1 + (j + 1) % segs) for j in range(segs)]
        nrm = [(0.0, float(normal), 0.0)] * len(pos)
        outward = (center[0], center[1] - normal, center[2])
        self._commit(base, pos, nrm, tris, outward)

    def _commit(self, base, pos, nrm, tris, outward):
        # Orient triangles so the computed winding faces away from outward.
        votes = 0
        for (a, b, c) in tris:
            n = cross(sub(pos[b], pos[a]), sub(pos[c], pos[a]))
            votes += 1 if dot(n, sub(pos[a], outward)) >= 0 else -1
        if votes < 0:
            tris = [(a, c, b) for (a, b, c) in tris]
        self.pos.extend(pos)
        self.nrm.extend(normalize(n) for n in nrm)
        self.idx.extend(base + v for t in tris for v in t)


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def normalize(v):
    l = math.sqrt(dot(v, v)) or 1.0
    return (v[0] / l, v[1] / l, v[2] / l)


def smoothstep(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def unit(lon, e):
    """Point on the unit sphere at longitude lon and elevation e."""
    return (math.sin(lon) * math.cos(e), math.sin(e), FRONT * math.cos(lon) * math.cos(e))


def dent(p, lon, e, radius, depth):
    """Scale factor that presses p inward around the direction (lon, e)."""
    ang = math.acos(max(-1.0, min(1.0, dot(p, unit(lon, e)))))
    return 1 - depth * smoothstep(1 - ang / radius)


def skull_point(lon, e):
    p = unit(lon, e)
    x, y, z = p
    # The lower half narrows toward the chin.
    s = smoothstep((-y - 0.1) / 0.9)
    x *= 1 - 0.38 * s
    z *= 1 - 0.12 * s
    # Cheekbones.
    x *= 1 + 0.08 * math.exp(-((y + 0.05) / 0.18) ** 2)
    # The back of the head bulges a little and the top is slightly taller.
    if z * FRONT < 0:
        z *= 1.06
    if y > 0:
        y *= 1.08
    k = 1.0
    for side in (-1, 1):
        k *= dent(p, side * 0.46, 0.10, 0.32, 0.15)
    k *= dent(p, 0, -0.22, 0.14, 0.07)
    return (x * k, y * k, z * k)


def sphere(prim, center, radius, segs, rings, scale=(1, 1, 1), ruffle=0.0):
    def point(j, i):
        lon = -math.pi + TAU * j / segs
        e = math.pi / 2 - math.pi * i / rings
        r = radius * (1 + ruffle * math.sin(6 * lon) * math.sin(4 * e))
        p = unit(lon, e)
        return (
            (center[0] + p[0] * r * scale[0], center[1] + p[1] * r * scale[1],
             center[2] + p[2] * r * scale[2]),
            (j / segs, i / rings),
        )

    prim.add_grid(segs, rings, point, center)


def cylinder(prim, center, r_bottom, r_top, height, segs):
    y0, y1 = center[1] - height / 2, center[1] + height / 2

    def point(j, i):
        a = TAU * j / segs
        r, y = (r_bottom, y0) if i == 0 else (r_top, y1)
        return ((center[0] + r * math.cos(a), y, center[2] + r * math.sin(a)),
                (j / segs, 1 - i))

    prim.add_grid(segs, 1, point, center)
    prim.add_cap((center[0], y1, center[2]), r_top, 1, segs)
    prim.add_cap((center[0], y0, center[2]), r_bottom, -1, segs)


def build_skull():
    prim = Prim('Sugar')

    def point(j, i):
        lon = -math.pi + TAU * j / segs
        e = math.pi / 2 - math.pi * i / rings
        return skull_point(lon, e), (j / segs, i / rings)

    segs, rings = 72, 48
    prim.add_grid(segs, rings, point, (0, 0, 0))
    return prim


def build_hat():
    brim = Prim('Hat')
    cylinder(brim, (0, 0, 0), 1.55, 1.55, 0.08, 64)
    cylinder(brim, (0, 0.04 + 0.5, 0), 0.82, 0.7, 1.0, 48)
    band = Prim('Band')
    cylinder(band, (0, 0.04 + 0.1, 0), 0.84, 0.84, 0.2, 48)
    return brim, band


def build_flowers():
    flowers = Prim('Marigold')
    hearts = Prim('MarigoldHeart')
    leaves = Prim('Leaf')
    # Marigolds bunched at the front of the crown, spilling to one side.
    cluster = [
        (-0.35, 0.34, 1.1), (-0.85, 0.28, 1.12), (0.1, 0.27, 1.08),
        (-1.3, 0.24, 1.1), (0.5, 0.22, 1.06), (-1.75, 0.2, 1.08),
    ]
    for ang, size, dist in cluster:
        x = math.sin(ang) * dist
        z = FRONT * math.cos(ang) * dist
        y = 0.04 + size * 0.6
        sphere(flowers, (x, y, z), size, 24, 14, scale=(1, 0.75, 1), ruffle=0.09)
        sphere(hearts, (x, y + size * 0.55, z), size * 0.32, 12, 8)
        # Two leaves poking out from under each flower.
        for off in (-0.5, 0.5):
            la = ang + off
            lx = math.sin(la) * (dist + size * 0.8)
            lz = FRONT * math.cos(la) * (dist + size * 0.8)
            leaf = Prim('Leaf')
            sphere(leaf, (0, 0, 0), size * 0.9, 12, 6, scale=(0.3, 0.1, 1))
            # Rotate the leaf to point outward, then place it.
            c, s = math.cos(la), math.sin(la)
            for k, p in enumerate(leaf.pos):
                rx = p[0] * c + p[2] * s
                rz = -p[0] * s + p[2] * c
                leaf.pos[k] = (lx + rx, 0.04 + size * 0.15, lz + FRONT * rz)
            for k, n in enumerate(leaf.nrm):
                leaf.nrm[k] = (n[0] * c + n[2] * s, n[1], FRONT * (-n[0] * s + n[2] * c))
            base = len(leaves.pos)
            leaves.pos.extend(leaf.pos)
            leaves.nrm.extend(leaf.nrm)
            leaves.uv.extend(leaf.uv)
            leaves.idx.extend(base + v for v in leaf.idx)
    return flowers, hearts, leaves


# -------------------------------------------------------------------- glb


def srgb_to_linear(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def solid(name, rgb, roughness=0.6, emissive=None):
    m = {
        'name': name,
        'pbrMetallicRoughness': {
            'baseColorFactor': [srgb_to_linear(c) for c in rgb] + [1.0],
            'metallicFactor': 0.0,
            'roughnessFactor': roughness,
        },
    }
    if emissive:
        m['emissiveFactor'] = [srgb_to_linear(c) for c in emissive]
    return m


def quat_axis(axis, angle):
    s = math.sin(angle / 2)
    return [axis[0] * s, axis[1] * s, axis[2] * s, math.cos(angle / 2)]


def quat_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return [
        aw * bx + ax * bw + ay * bz - az * by,
        aw * by - ax * bz + ay * bw + az * bx,
        aw * bz + ax * by - ay * bx + az * bw,
        aw * bw - ax * bx - ay * by - az * bz,
    ]


def write_glb(nodes, materials, texture_png):
    bin_parts = []
    buffer_views = []
    accessors = []

    def view(data, target=None):
        offset = sum(len(p) for p in bin_parts)
        bin_parts.append(data)
        pad = (-len(data)) % 4
        if pad:
            bin_parts.append(b'\x00' * pad)
        v = {'buffer': 0, 'byteOffset': offset, 'byteLength': len(data)}
        if target:
            v['target'] = target
        buffer_views.append(v)
        return len(buffer_views) - 1

    def accessor(values, comp, ctype, count_per, target, with_bounds=False):
        flat = [c for v in values for c in v] if count_per > 1 else list(values)
        data = struct.pack('<%d%s' % (len(flat), comp), *flat)
        a = {
            'bufferView': view(data, target),
            'componentType': ctype,
            'count': len(values),
            'type': {1: 'SCALAR', 2: 'VEC2', 3: 'VEC3'}[count_per],
        }
        if with_bounds:
            a['min'] = [min(v[k] for v in values) for k in range(count_per)]
            a['max'] = [max(v[k] for v in values) for k in range(count_per)]
        accessors.append(a)
        return len(accessors) - 1

    material_index = {m['name']: i for i, m in enumerate(materials)}
    meshes = []
    gltf_nodes = []
    for node in nodes:
        entry = {'name': node['name']}
        for key in ('translation', 'rotation', 'children'):
            if key in node:
                entry[key] = node[key]
        prims = []
        for prim in node.get('prims', []):
            assert len(prim.pos) < 65536, node['name']
            prims.append({
                'attributes': {
                    'POSITION': accessor(prim.pos, 'f', 5126, 3, 34962, True),
                    'NORMAL': accessor(prim.nrm, 'f', 5126, 3, 34962),
                    'TEXCOORD_0': accessor(prim.uv, 'f', 5126, 2, 34962),
                },
                'indices': accessor(prim.idx, 'H', 5123, 1, 34963),
                'material': material_index[prim.material],
            })
        if prims:
            meshes.append({'name': node['name'], 'primitives': prims})
            entry['mesh'] = len(meshes) - 1
        gltf_nodes.append(entry)

    image_view = view(texture_png)
    gltf = {
        'asset': {'version': '2.0', 'generator': 'dash_quiz tool/make_calavera.py'},
        'scene': 0,
        'scenes': [{'name': 'Calavera', 'nodes': [0]}],
        'nodes': gltf_nodes,
        'meshes': meshes,
        'materials': materials,
        'textures': [{'sampler': 0, 'source': 0}],
        'samplers': [{'magFilter': 9729, 'minFilter': 9987, 'wrapS': 10497, 'wrapT': 33071}],
        'images': [{'mimeType': 'image/png', 'bufferView': image_view}],
        'accessors': accessors,
        'bufferViews': buffer_views,
        'buffers': [{'byteLength': sum(len(p) for p in bin_parts)}],
    }
    json_bytes = json.dumps(gltf, separators=(',', ':')).encode()
    json_bytes += b' ' * ((-len(json_bytes)) % 4)
    bin_bytes = b''.join(bin_parts)
    total = 12 + 8 + len(json_bytes) + 8 + len(bin_bytes)
    return (
        struct.pack('<4sII', b'glTF', 2, total)
        + struct.pack('<II', len(json_bytes), 0x4E4F534A) + json_bytes
        + struct.pack('<II', len(bin_bytes), 0x004E4942) + bin_bytes
    )


def main():
    paint_face()
    skull = build_skull()
    brim, band = build_hat()
    flowers, hearts, leaves = build_flowers()

    materials = [
        {
            'name': 'Sugar',
            'pbrMetallicRoughness': {
                'baseColorTexture': {'index': 0},
                'metallicFactor': 0.0,
                'roughnessFactor': 0.55,
            },
        },
        solid('Hat', (48, 20, 70), roughness=0.75),
        solid('Band', (214, 30, 110), roughness=0.5),
        solid('Marigold', (255, 110, 10), roughness=0.7, emissive=(60, 20, 0)),
        solid('MarigoldHeart', (200, 50, 10), roughness=0.8),
        solid('Leaf', (40, 120, 50), roughness=0.7),
    ]

    # The hat sits on the crown, tipped back and a little to one side.
    tilt = quat_mul(
        quat_axis((0, 0, 1), 0.14), quat_axis((1, 0, 0), -0.12 * FRONT),
    )
    nodes = [
        {'name': 'Calavera', 'children': [1]},
        {'name': 'Skull', 'translation': [0, 1.45, 0], 'prims': [skull], 'children': [2]},
        {'name': 'Hat', 'translation': [0, 0.92, -0.1 * FRONT], 'rotation': tilt,
         'prims': [brim, band], 'children': [3]},
        {'name': 'Flowers', 'prims': [flowers, hearts, leaves]},
    ]
    data = write_glb(nodes, materials, png_bytes())
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'wb') as f:
        f.write(data)
    print('wrote', os.path.relpath(OUT, ROOT), len(data), 'bytes')


if __name__ == '__main__':
    main()

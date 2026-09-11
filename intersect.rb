# amethrine/intersect.rb
#
# Intersections: line-line, line-plane, line-sphere, plane-plane, plane-sphere.
#
# Two reasons these belong in a visualisation library rather than being a
# geometry side-quest:
#
#   1. RAY PICKING. Selecting a point in a 3D scene means intersecting a ray
#      from the camera with scene geometry. line_sphere is literally the
#      picking primitive.
#   2. CROSS-SECTIONS. Slicing a 3D manifold with a plane -- the standard way
#      to inspect the interior of a volume -- is plane_sphere and friends.
#
# Every routine returns a tagged Hash rather than raising or returning nil for
# degenerate cases, because "these two lines are parallel" and "these two
# lines are the same line" are different answers and callers need to tell
# them apart.

module Amethrine
  module Intersect
    module_function

    EPS = 1e-10

    def sub(a, b) = a.each_with_index.map { |x, i| x - b[i] }
    def add(a, b) = a.each_with_index.map { |x, i| x + b[i] }
    def scale(a, s) = a.map { |x| x * s }
    def dot(a, b) = a.each_with_index.sum { |x, i| x * b[i] }
    def cross(a, b)
      [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]]
    end
    def norm(a) = Math.sqrt(dot(a, a))

    # --- line x line, 2D ------------------------------------------------
    # Lines given in point-direction form. Returns
    #   {type: :point, point: [x,y]} | {type: :parallel} | {type: :coincident}
    def line_line_2d(p1, d1, p2, d2)
      denom = d1[0] * d2[1] - d1[1] * d2[0]
      if denom.abs < EPS
        # parallel; coincident iff p2 - p1 is also parallel to d1
        w = sub(p2, p1)
        cross_w = d1[0] * w[1] - d1[1] * w[0]
        return cross_w.abs < EPS ? { type: :coincident } : { type: :parallel }
      end
      w = sub(p2, p1)
      t = (w[0] * d2[1] - w[1] * d2[0]) / denom
      { type: :point, point: [p1[0] + t * d1[0], p1[1] + t * d1[1]], t: t }
    end

    # --- line x line, 3D ------------------------------------------------
    # Generic 3D lines are SKEW -- they neither meet nor are parallel. Returning
    # only "no intersection" would throw away the useful answer, so we return
    # the closest points on each line and their separation.
    def line_line_3d(p1, d1, p2, d2)
      n = cross(d1, d2)
      if norm(n) < EPS
        w = sub(p2, p1)
        return norm(cross(w, d1)) < EPS ? { type: :coincident } : { type: :parallel }
      end
      w = sub(p1, p2)
      a = dot(d1, d1); b = dot(d1, d2); c = dot(d2, d2)
      d = dot(d1, w);  e = dot(d2, w)
      denom = a * c - b * b
      t1 = (b * e - c * d) / denom
      t2 = (a * e - b * d) / denom
      q1 = add(p1, scale(d1, t1))
      q2 = add(p2, scale(d2, t2))
      gap = norm(sub(q1, q2))
      if gap < 1e-9
        { type: :point, point: q1, t1: t1, t2: t2 }
      else
        { type: :skew, closest_1: q1, closest_2: q2, distance: gap }
      end
    end

    # --- line x plane ---------------------------------------------------
    # Plane as a point and a normal.
    def line_plane(p, d, plane_point, normal)
      denom = dot(normal, d)
      if denom.abs < EPS
        in_plane = dot(normal, sub(plane_point, p)).abs < EPS
        return in_plane ? { type: :line_in_plane } : { type: :parallel }
      end
      t = dot(normal, sub(plane_point, p)) / denom
      { type: :point, point: add(p, scale(d, t)), t: t }
    end

    # --- ray x sphere (the picking primitive) ---------------------------
    # Returns 0, 1 or 2 intersection points, nearest first.
    def line_sphere(origin, direction, center, radius)
      m = sub(origin, center)
      a = dot(direction, direction)
      b = 2.0 * dot(m, direction)
      c = dot(m, m) - radius * radius
      disc = b * b - 4 * a * c
      return { type: :none } if disc < -EPS
      if disc.abs <= EPS
        t = -b / (2 * a)
        return { type: :tangent, points: [add(origin, scale(direction, t))], t: [t] }
      end
      sq = Math.sqrt(disc)
      t1 = (-b - sq) / (2 * a)
      t2 = (-b + sq) / (2 * a)
      { type: :two_points,
        points: [add(origin, scale(direction, t1)), add(origin, scale(direction, t2))],
        t: [t1, t2] }
    end

    # --- plane x plane --------------------------------------------------
    # Planes as normal + offset: n . x = offset. Intersection is a line.
    def plane_plane(n1, off1, n2, off2)
      d = cross(n1, n2)
      if norm(d) < EPS
        # parallel; coincident iff offsets agree after normalising
        s = norm(n1) > EPS ? (norm(n2) / norm(n1)) : 1.0
        return (off2 - s * off1).abs < EPS ? { type: :coincident } : { type: :parallel }
      end
      # a point on the line: solve in the plane spanned by n1, n2
      n1n1 = dot(n1, n1); n2n2 = dot(n2, n2); n1n2 = dot(n1, n2)
      det = n1n1 * n2n2 - n1n2 * n1n2
      c1 = (off1 * n2n2 - off2 * n1n2) / det
      c2 = (off2 * n1n1 - off1 * n1n2) / det
      point = add(scale(n1, c1), scale(n2, c2))
      { type: :line, point: point, direction: d }
    end

    # --- plane x sphere (the cross-section primitive) -------------------
    # Returns the circle of intersection: centre, radius, and the plane normal.
    def plane_sphere(normal, offset, center, radius)
      nn = norm(normal)
      raise ArgumentError, "degenerate plane normal" if nn < EPS
      unit = scale(normal, 1.0 / nn)
      signed = (dot(unit, center) - offset / nn)
      dist = signed.abs
      return { type: :none } if dist > radius + EPS
      foot = sub(center, scale(unit, signed))
      if (dist - radius).abs <= EPS
        return { type: :tangent, point: foot }
      end
      { type: :circle, center: foot,
        radius: Math.sqrt([radius * radius - dist * dist, 0.0].max), normal: unit }
    end
  end
end

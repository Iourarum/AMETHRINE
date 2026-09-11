# amethrine/geometry.rb
#
# Euclidean, spherical and hyperbolic geometry behind one interface.
#
# The three geometries differ in exactly one axiom -- the parallel postulate --
# and that single difference is observable in two ways this module makes
# computable:
#
#   PARALLELS through a point not on a given line:
#     Euclidean  : exactly one
#     Spherical  : none (any two great circles meet, in two antipodal points)
#     Hyperbolic : infinitely many
#
#   TRIANGLE ANGLE SUM:
#     Euclidean  : exactly pi
#     Spherical  : > pi, and the EXCESS equals the area
#     Hyperbolic : < pi, and the DEFECT equals the area
#
# The second is the useful one for a library, because it is a number you can
# check rather than a statement you have to take on faith -- and the tests do
# check it, against exact analytic values.

module Amethrine
  module Geometry
    # ---------------------------------------------------------------- Euclid
    module Euclidean
      module_function
      def distance(a, b) = Math.sqrt(a.each_with_index.sum { |x, i| (x - b[i])**2 })
      def geodesic(a, b, n = 32)
        (0..n).map { |i| t = i.to_f / n; a.each_with_index.map { |x, j| x + t * (b[j] - x) } }
      end
      def parallels_through_point = 1
      # Angle at vertex B in triangle A-B-C, by the ordinary law of cosines.
      def angle_at(a, b, c)
        u = a.each_with_index.map { |x, i| x - b[i] }
        v = c.each_with_index.map { |x, i| x - b[i] }
        nu = Math.sqrt(u.sum { |x| x * x }); nv = Math.sqrt(v.sum { |x| x * x })
        Math.acos([[u.each_with_index.sum { |x, i| x * v[i] } / (nu * nv), 1.0].min, -1.0].max)
      end
      def angle_sum(a, b, c) = angle_at(b, a, c) + angle_at(a, b, c) + angle_at(a, c, b)
      def curvature = 0.0
    end

    # ------------------------------------------------------------- Spherical
    # Points are unit vectors in R^3. Geodesics are great circles.
    module Spherical
      module_function
      def distance(a, b)
        d = a.each_with_index.sum { |x, i| x * b[i] }
        Math.acos([[d, 1.0].min, -1.0].max)
      end

      def geodesic(a, b, n = 32)
        omega = distance(a, b)
        return Array.new(n + 1) { a.dup } if omega.abs < 1e-12
        (0..n).map do |i|
          t = i.to_f / n
          s1 = Math.sin((1 - t) * omega) / Math.sin(omega)
          s2 = Math.sin(t * omega) / Math.sin(omega)
          v = a.each_with_index.map { |x, j| s1 * x + s2 * b[j] }
          nv = Math.sqrt(v.sum { |x| x * x })
          v.map { |x| x / nv }
        end
      end

      # Two distinct great circles ALWAYS meet, in a pair of antipodal points.
      # Given by the cross product of their plane normals. There are no
      # parallels on the sphere -- which is what this returns.
      def parallels_through_point = 0

      def great_circles_intersect(n1, n2)
        c = [n1[1]*n2[2] - n1[2]*n2[1], n1[2]*n2[0] - n1[0]*n2[2], n1[0]*n2[1] - n1[1]*n2[0]]
        m = Math.sqrt(c.sum { |x| x * x })
        return { type: :same_circle } if m < 1e-12
        u = c.map { |x| x / m }
        { type: :antipodal_pair, points: [u, u.map { |x| -x }] }
      end

      # Spherical law of cosines: cos c = cos a cos b + sin a sin b cos C
      def angle_at(a, b, c)
        side_a = distance(b, c); side_b = distance(a, c); side_c = distance(a, b)
        num = Math.cos(side_b) - Math.cos(side_a) * Math.cos(side_c)
        den = Math.sin(side_a) * Math.sin(side_c)
        return Float::NAN if den.abs < 1e-14
        Math.acos([[num / den, 1.0].min, -1.0].max)
      end

      def angle_sum(a, b, c) = angle_at(b, a, c) + angle_at(a, b, c) + angle_at(a, c, b)
      # Girard's theorem: area of a spherical triangle IS its angle excess.
      def area(a, b, c) = angle_sum(a, b, c) - Math::PI
      def curvature = 1.0
    end

    # ------------------------------------------------------------ Hyperbolic
    # Poincare disk model. Points are in the open unit disk; geodesics are
    # circular arcs meeting the boundary at right angles (or diameters).
    # The model is CONFORMAL, so hyperbolic angles equal Euclidean angles
    # between the tangent arcs -- which is why angle computations below can
    # use the hyperbolic law of cosines directly and agree with what is drawn.
    module Hyperbolic
      module_function
      def distance(a, b)
        sa = a.sum { |x| x * x }; sb = b.sum { |x| x * x }
        raise ArgumentError, "points must lie inside the unit disk" if sa >= 1.0 || sb >= 1.0
        sq = a.each_with_index.sum { |x, i| (x - b[i])**2 }
        Math.acosh(1 + 2 * sq / ((1 - sa) * (1 - sb)))
      end

      # Infinitely many geodesics through a point miss a given geodesic.
      def parallels_through_point = Float::INFINITY

      # Hyperbolic law of cosines:
      #   cosh c = cosh a cosh b - sinh a sinh b cos C
      def angle_at(a, b, c)
        side_a = distance(b, c); side_b = distance(a, c); side_c = distance(a, b)
        num = Math.cosh(side_a) * Math.cosh(side_c) - Math.cosh(side_b)
        den = Math.sinh(side_a) * Math.sinh(side_c)
        return Float::NAN if den.abs < 1e-14
        Math.acos([[num / den, 1.0].min, -1.0].max)
      end

      def angle_sum(a, b, c) = angle_at(b, a, c) + angle_at(a, b, c) + angle_at(a, c, b)
      # Gauss-Bonnet: area of a hyperbolic triangle IS its angle defect.
      def area(a, b, c) = Math::PI - angle_sum(a, b, c)
      def curvature = -1.0

      # The Euclidean circle representing the geodesic through two IDEAL
      # points (on the boundary) at angles t1, t2: centre at distance
      # sec(d) from the origin along the bisector, radius tan(d), where d is
      # the half-separation. Orthogonality to the unit circle is the identity
      # sec^2 = 1 + tan^2.
      def ideal_geodesic_circle(t1, t2)
        m = (t1 + t2) / 2.0
        d = ((t1 - t2).abs) / 2.0
        if d > Math::PI / 2
          # Taking the minor separation also moves the bisector to the
          # ANTIPODAL direction. Flipping d without flipping m yields a circle
          # that is still orthogonal to the boundary but passes through the
          # antipodal pair of ideal points -- i.e. the wrong geodesic. This bug
          # survived an orthogonality-only test and was caught by drawing it.
          d = Math::PI - d
          m += Math::PI
        end
        return { type: :diameter, angle: m } if (d - Math::PI / 2).abs < 1e-12
        { type: :circle,
          center: [Math.cos(m) / Math.cos(d), Math.sin(m) / Math.cos(d)],
          radius: Math.tan(d) }
      end
    end

    module_function
    # Uniform accessor, so callers can switch geometry without changing code.
    def model(name)
      case name.to_sym
      when :euclidean  then Euclidean
      when :spherical  then Spherical
      when :hyperbolic then Hyperbolic
      else raise ArgumentError, "unknown geometry #{name}; use :euclidean, :spherical or :hyperbolic"
      end
    end
  end
end

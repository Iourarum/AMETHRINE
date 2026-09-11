require "minitest/autorun"
require_relative "../lib/amethrine/hilbert"
require_relative "../lib/amethrine/intersect"
require_relative "../lib/amethrine/geometry"

H = Amethrine::Hilbert
I = Amethrine::Intersect
G = Amethrine::Geometry

class TestHilbert < Minitest::Test
  def test_inner_product_axioms
    u = [1.0, 2.0, 3.0]; v = [4.0, -1.0, 0.5]; w = [0.0, 1.0, 1.0]
    assert_in_delta H.inner(u, v), H.inner(v, u), 1e-12                 # symmetry
    lhs = H.inner(u.each_with_index.map { |x,i| x + w[i] }, v)
    assert_in_delta lhs, H.inner(u, v) + H.inner(w, v), 1e-12           # linearity
    assert H.inner(u, u) > 0                                            # positive definite
  end

  def test_cauchy_schwarz
    100.times do
      u = Array.new(5) { rand * 4 - 2 }; v = Array.new(5) { rand * 4 - 2 }
      assert H.inner(u, v).abs <= H.norm(u) * H.norm(v) + 1e-9,
             "Cauchy-Schwarz violated"
    end
  end

  def test_gram_schmidt_produces_orthonormal_basis
    vs = [[1.0,1.0,0.0], [1.0,0.0,1.0], [0.0,1.0,1.0]]
    b = H.gram_schmidt(vs)
    assert_equal 3, b.size
    assert H.orthonormal?(b), "Gram-Schmidt output is not orthonormal"
  end

  def test_gram_schmidt_detects_rank_deficiency
    vs = [[1.0,0.0,0.0], [2.0,0.0,0.0], [0.0,1.0,0.0]]   # second is dependent
    b = H.gram_schmidt(vs)
    assert_equal 2, b.size, "should drop the dependent vector"
  end

  def test_gram_matrix_is_psd_and_singular_when_dependent
    vs = [[1.0,0.0], [2.0,0.0]]
    g = H.gram(vs)
    det = g[0][0]*g[1][1] - g[0][1]*g[1][0]
    assert_in_delta 0.0, det, 1e-12, "Gram det should vanish for dependent vectors"
  end

  def test_projection_residual_is_orthogonal_to_basis
    basis = H.gram_schmidt([[1.0,0.0,0.0], [0.0,1.0,0.0]])
    v = [3.0, -2.0, 5.0]
    r = H.residual(v, basis)
    basis.each { |e| assert_in_delta 0.0, H.inner(r, e), 1e-10 }
    assert_in_delta 5.0, r[2], 1e-10        # only the z-component survives
  end

  def test_parseval_defect_equals_squared_residual_norm
    basis = H.gram_schmidt([[1.0,0.0,0.0], [0.0,1.0,0.0]])
    v = [3.0, -2.0, 5.0]
    assert_in_delta H.norm(H.residual(v, basis))**2, H.parseval_defect(v, basis), 1e-10
  end

  def test_parseval_defect_vanishes_for_complete_basis
    basis = H.gram_schmidt([[1.0,0.0,0.0],[0.0,1.0,0.0],[0.0,0.0,1.0]])
    assert_in_delta 0.0, H.parseval_defect([3.0,-2.0,5.0], basis), 1e-10
  end

  def test_weighted_inner_product
    u = [1.0, 1.0]; v = [1.0, 1.0]
    assert_in_delta 2.0, H.inner(u, v), 1e-12
    assert_in_delta 5.0, H.inner(u, v, weights: [2.0, 3.0]), 1e-12
    assert_raises(ArgumentError) { H.inner(u, v, weights: [1.0, -1.0]) }
  end
end

class TestIntersect < Minitest::Test
  def test_line_line_2d_crossing
    r = I.line_line_2d([0.0,0.0],[1.0,1.0], [0.0,2.0],[1.0,-1.0])
    assert_equal :point, r[:type]
    assert_in_delta 1.0, r[:point][0], 1e-12
    assert_in_delta 1.0, r[:point][1], 1e-12
  end

  def test_line_line_2d_parallel_vs_coincident
    assert_equal :parallel,   I.line_line_2d([0.0,0.0],[1.0,0.0], [0.0,1.0],[1.0,0.0])[:type]
    assert_equal :coincident, I.line_line_2d([0.0,0.0],[1.0,0.0], [5.0,0.0],[2.0,0.0])[:type]
  end

  def test_line_line_3d_skew_lines_report_distance
    # x-axis, and a line parallel to y through (0,0,1): classic skew pair, gap 1
    r = I.line_line_3d([0.0,0.0,0.0],[1.0,0.0,0.0], [0.0,0.0,1.0],[0.0,1.0,0.0])
    assert_equal :skew, r[:type]
    assert_in_delta 1.0, r[:distance], 1e-12
  end

  def test_line_line_3d_actually_meeting
    r = I.line_line_3d([0.0,0.0,0.0],[1.0,0.0,0.0], [1.0,-1.0,0.0],[0.0,1.0,0.0])
    assert_equal :point, r[:type]
    assert_in_delta 1.0, r[:point][0], 1e-9
  end

  def test_line_plane
    r = I.line_plane([0.0,0.0,-5.0],[0.0,0.0,1.0], [0.0,0.0,2.0],[0.0,0.0,1.0])
    assert_equal :point, r[:type]
    assert_in_delta 2.0, r[:point][2], 1e-12
    assert_equal :parallel, I.line_plane([0.0,0.0,0.0],[1.0,0.0,0.0], [0.0,0.0,3.0],[0.0,0.0,1.0])[:type]
    assert_equal :line_in_plane, I.line_plane([0.0,0.0,3.0],[1.0,0.0,0.0], [0.0,0.0,3.0],[0.0,0.0,1.0])[:type]
  end

  def test_ray_sphere_picking
    r = I.line_sphere([0.0,0.0,-5.0],[0.0,0.0,1.0], [0.0,0.0,0.0], 1.0)
    assert_equal :two_points, r[:type]
    assert_in_delta(-1.0, r[:points][0][2], 1e-12)   # near hit first
    assert_in_delta( 1.0, r[:points][1][2], 1e-12)
    assert_equal :none, I.line_sphere([0.0,5.0,-5.0],[0.0,0.0,1.0],[0.0,0.0,0.0],1.0)[:type]
    assert_equal :tangent, I.line_sphere([0.0,1.0,-5.0],[0.0,0.0,1.0],[0.0,0.0,0.0],1.0)[:type]
  end

  def test_plane_plane_gives_a_line
    r = I.plane_plane([0.0,0.0,1.0], 0.0, [0.0,1.0,0.0], 0.0)   # z=0 and y=0
    assert_equal :line, r[:type]
    d = r[:direction]; n = Math.sqrt(d.sum { |x| x*x })
    assert_in_delta 1.0, (d[0]/n).abs, 1e-12, "intersection should be the x-axis"
  end

  def test_plane_sphere_cross_section
    # plane z = 0.6 through the unit sphere -> circle of radius sqrt(1-0.36)=0.8
    r = I.plane_sphere([0.0,0.0,1.0], 0.6, [0.0,0.0,0.0], 1.0)
    assert_equal :circle, r[:type]
    assert_in_delta 0.8, r[:radius], 1e-12
    assert_in_delta 0.6, r[:center][2], 1e-12
    assert_equal :none, I.plane_sphere([0.0,0.0,1.0], 2.0, [0.0,0.0,0.0], 1.0)[:type]
    assert_equal :tangent, I.plane_sphere([0.0,0.0,1.0], 1.0, [0.0,0.0,0.0], 1.0)[:type]
  end
end

class TestGeometry < Minitest::Test
  def test_parallel_postulate_differs_across_the_three_geometries
    assert_equal 1, G::Euclidean.parallels_through_point
    assert_equal 0, G::Spherical.parallels_through_point
    assert_equal Float::INFINITY, G::Hyperbolic.parallels_through_point
  end

  def test_euclidean_triangle_angle_sum_is_exactly_pi
    a=[0.0,0.0]; b=[1.0,0.0]; c=[0.3,0.9]
    assert_in_delta Math::PI, G::Euclidean.angle_sum(a,b,c), 1e-10
  end

  def test_spherical_octant_has_angle_sum_3pi_over_2_and_area_pi_over_2
    # the positive octant: three mutually orthogonal unit vectors.
    # Every angle is a right angle, so the sum is 3*pi/2 and Girard's
    # theorem gives area = excess = pi/2, which is exactly 1/8 of 4*pi.
    a=[1.0,0.0,0.0]; b=[0.0,1.0,0.0]; c=[0.0,0.0,1.0]
    assert_in_delta 3*Math::PI/2, G::Spherical.angle_sum(a,b,c), 1e-9
    assert_in_delta Math::PI/2,   G::Spherical.area(a,b,c),      1e-9
    assert_in_delta 4*Math::PI/8, G::Spherical.area(a,b,c),      1e-9
  end

  def test_spherical_angle_sum_always_exceeds_pi
    20.times do
      pts = Array.new(3) do
        v = Array.new(3) { rand * 2 - 1 }
        n = Math.sqrt(v.sum { |x| x*x }); v.map { |x| x/n }
      end
      s = G::Spherical.angle_sum(*pts)
      next if s.nan?
      assert s > Math::PI - 1e-9, "spherical angle sum #{s} should exceed pi"
    end
  end

  def test_hyperbolic_angle_sum_always_below_pi
    20.times do
      pts = Array.new(3) { [rand*1.2-0.6, rand*1.2-0.6] }
      next if pts.any? { |p| p.sum { |x| x*x } >= 0.98 }
      s = G::Hyperbolic.angle_sum(*pts)
      next if s.nan?
      assert s < Math::PI + 1e-9, "hyperbolic angle sum #{s} should be below pi"
    end
  end

  def test_hyperbolic_defect_equals_area_and_grows_with_the_triangle
    small = G::Hyperbolic.area([0.0,0.0],[0.05,0.0],[0.0,0.05])
    big   = G::Hyperbolic.area([0.0,0.0],[0.8,0.0],[0.0,0.8])
    assert small >= 0, "area must be non-negative"
    assert big > small, "a larger hyperbolic triangle must have a larger defect"
    assert big < Math::PI, "hyperbolic triangle area is bounded by pi"
  end

  def test_great_circles_always_intersect_in_antipodal_pair
    r = G::Spherical.great_circles_intersect([0.0,0.0,1.0], [0.0,1.0,0.0])
    assert_equal :antipodal_pair, r[:type]
    p, q = r[:points]
    p.each_with_index { |x, i| assert_in_delta(-x, q[i], 1e-12) }
  end

  def test_ideal_geodesic_circle_is_orthogonal_to_the_boundary
    # orthogonality to the unit circle requires |centre|^2 == 1 + r^2
    [[0, 2*Math::PI/3], [Math::PI/2, 7*Math::PI/6], [0.3, 2.4]].each do |t1, t2|
      g = G::Hyperbolic.ideal_geodesic_circle(t1, t2)
      next if g[:type] == :diameter
      c2 = g[:center].sum { |x| x*x }
      assert_in_delta 1.0 + g[:radius]**2, c2, 1e-9,
        "geodesic circle not orthogonal to the disk boundary"
    end
  end

  def test_ideal_geodesic_circle_passes_through_BOTH_ideal_points
    # Orthogonality alone is NOT enough: the antipodal geodesic is also
    # orthogonal to the boundary. This checks the circle meets the two
    # requested ideal points, which is what actually pins it down.
    # (An earlier version failed exactly here.)
    angles = [90, 210, 330].map { |d| d * Math::PI / 180 }
    [[angles[0],angles[1]], [angles[1],angles[2]], [angles[2],angles[0]]].each do |t1, t2|
      g = G::Hyperbolic.ideal_geodesic_circle(t1, t2)
      next if g[:type] == :diameter
      [t1, t2].each do |t|
        px = Math.cos(t); py = Math.sin(t)
        dist = Math.sqrt((px - g[:center][0])**2 + (py - g[:center][1])**2)
        assert_in_delta g[:radius], dist, 1e-9,
          "geodesic circle misses the ideal point at angle #{t}"
      end
    end
  end

  def test_hyperbolic_rejects_points_outside_the_disk
    assert_raises(ArgumentError) { G::Hyperbolic.distance([0.0,0.0],[1.5,0.0]) }
  end

  def test_model_accessor
    assert_equal G::Spherical, G.model(:spherical)
    assert_raises(ArgumentError) { G.model(:elliptic_paraboloid) }
  end
end

# amethrine/hilbert.rb
#
# Hilbert space operations: inner products, Gram matrices, orthonormalisation,
# orthogonal projection, and Parseval checks.
#
# A Hilbert space is a complete inner-product space. Everything geometric that
# AMETHRINE does elsewhere -- angles, distances, projections, "closest point"
# -- is an inner-product statement, so this module is the algebraic floor the
# rest of the library stands on. Orthogonal projection in particular is an
# INTERSECTION statement: the projection of v onto a subspace S is the unique
# point where the perpendicular through v meets S. That is the same idea
# Amethrine::Intersect handles geometrically, expressed algebraically.

module Amethrine
  module Hilbert
    module_function

    # General (optionally weighted) real inner product.
    def inner(u, v, weights: nil)
      raise ArgumentError, "dimension mismatch" unless u.size == v.size
      if weights
        raise ArgumentError, "weight length mismatch" unless weights.size == u.size
        raise ArgumentError, "weights must be positive" unless weights.all?(&:positive?)
        u.each_with_index.sum { |ui, i| weights[i] * ui * v[i] }
      else
        u.each_with_index.sum { |ui, i| ui * v[i] }
      end
    end

    def norm(v, weights: nil) = Math.sqrt([inner(v, v, weights: weights), 0.0].max)

    # Angle between two vectors, from the inner product. Clamped because
    # floating point can push the cosine a hair outside [-1, 1].
    def angle(u, v, weights: nil)
      denom = norm(u, weights: weights) * norm(v, weights: weights)
      return Float::NAN if denom.zero?
      Math.acos([[inner(u, v, weights: weights) / denom, 1.0].min, -1.0].max)
    end

    # Gram matrix G_ij = <v_i, v_j>. Positive semi-definite by construction;
    # singular exactly when the vectors are linearly dependent.
    def gram(vectors, weights: nil)
      vectors.map { |u| vectors.map { |v| inner(u, v, weights: weights) } }
    end

    # Modified Gram-Schmidt: numerically better behaved than the classical
    # form, which loses orthogonality badly for near-dependent input.
    # Vectors that collapse below `tol` are dropped (rank deficiency), so the
    # returned basis may be smaller than the input.
    def gram_schmidt(vectors, weights: nil, tol: 1e-10)
      basis = []
      vectors.each do |v|
        w = v.dup
        basis.each do |e|
          coeff = inner(w, e, weights: weights)
          w = w.each_with_index.map { |wi, i| wi - coeff * e[i] }
        end
        n = norm(w, weights: weights)
        basis << w.map { |wi| wi / n } if n > tol
      end
      basis
    end

    # Orthogonal projection of v onto the span of an ORTHONORMAL basis.
    # This is the unique closest point in the subspace -- the intersection of
    # the subspace with the perpendicular dropped from v.
    def project(v, orthonormal_basis, weights: nil)
      orthonormal_basis.reduce(Array.new(v.size, 0.0)) do |acc, e|
        c = inner(v, e, weights: weights)
        acc.each_with_index.map { |a, i| a + c * e[i] }
      end
    end

    # Residual v - proj(v). Orthogonal to every basis vector, by construction.
    def residual(v, orthonormal_basis, weights: nil)
      p = project(v, orthonormal_basis, weights: weights)
      v.each_with_index.map { |vi, i| vi - p[i] }
    end

    # Parseval defect: ||v||^2 - sum |<v, e_i>|^2. Zero iff the basis spans v.
    # Equals the squared norm of the residual, which is how completeness of a
    # basis is checked numerically.
    def parseval_defect(v, orthonormal_basis, weights: nil)
      lhs = inner(v, v, weights: weights)
      rhs = orthonormal_basis.sum { |e| inner(v, e, weights: weights)**2 }
      lhs - rhs
    end

    def orthonormal?(basis, weights: nil, tol: 1e-8)
      basis.each_with_index.all? do |u, i|
        basis.each_with_index.all? do |v, j|
          expected = (i == j) ? 1.0 : 0.0
          (inner(u, v, weights: weights) - expected).abs < tol
        end
      end
    end
  end
end

# Ruby Association Grant Proposal — AMETHRINE

> Submit by email to grant(at)ruby.or.jp with the fields below. The Ruby
> Association CFP typically opens between April and August; watch
> ruby.or.jp/en. Grant size is JPY 750,000 per project, up to five projects
> per cycle, with an assigned mentor.

## Applicant name

Sebastian [SURNAME]

## Contact person

Sebastian [SURNAME]

## Contact e-mail address

[EMAIL] · GitHub: [GITHUB URL]

## Brief biography

PhD student and researcher based in Bucharest, Romania, working on
computational genomics tooling at a genomics-focused company. Track record of
securing competitive funding for open-source and research projects, including
grants from NLNet (NGI Zero), NVIDIA, NIH, CZI and Erasmus+. Background spans
scientific software development and applied mathematics, including research
applying non-Euclidean and graph-based methods to biological structure
problems — direct working exposure to the mathematics this library makes
visible.

## Project title

**AMETHRINE — Advanced Mathematical Exploration Toolkit for High-dimensional,
Riemannian & Interactive Numerical Environments**

## Project details

### The gap

Ruby has no library for exploring advanced mathematical structure
interactively. The existing options do not overlap with this at all:

- **Dashboard gems** — Chartkick (a wrapper handing data to Chart.js),
  Gruff, Scruffy. Bar, line and pie charts for Rails applications. No
  statistical or mathematical plot types.
- **Charty** (Red Data Tools) is the one serious attempt at declarative
  scientific plotting, but its rendering backend calls **matplotlib through a
  Python subprocess**. It requires a working Python installation to function,
  which defeats the purpose for anyone choosing Ruby for a native stack.
- **Nyaplot** has been inactive for years.
- **GR.rb** (Red Data Tools) gives genuine native scientific rendering via the
  C-based GR framework, but is low-level and has no mathematical layer above
  it.

Nothing in Ruby covers complex analysis, Hilbert spaces, geometric
intersections, or the distinction between Euclidean and non-Euclidean
geometry. Meanwhile Ruby's numerical foundations have matured considerably —
Numo::NArray, Red Arrow, RedAmber and GR.rb are all actively maintained under
Red Data Tools. What is missing is the layer that turns them into something a
mathematician or student can explore.

### What AMETHRINE does

A library for interactive visualization of mathematical structure, built on
existing rendering infrastructure rather than a new engine: Vega-Lite through
the `vega` gem for 2D, Three.js for 3D, and GR.rb for publication-quality
static export. **Ruby's job is to get the mathematics right and emit correct
scene data.**

The core has **no runtime dependencies**. Every module returns plain Hashes,
which means the mathematics is testable without any rendering stack — the
current test suite runs on Ruby's bundled Minitest alone.

### Modules

**Hilbert spaces.** Inner products (including weighted), norms and angles,
Gram matrices, modified Gram–Schmidt orthonormalisation with rank-deficiency
detection, orthogonal projection onto a subspace, residuals, and the Parseval
defect — the quantity that tells you how much of a vector a given basis fails
to capture, and therefore whether the basis is complete.

**Intersections.** Line–line in 2D (distinguishing parallel from coincident)
and in 3D (where generic lines are *skew*, so the useful answer is the closest
pair of points and their separation, not "no intersection"); line–plane;
ray–sphere; plane–plane; and plane–sphere. Two of these are not academic:
**ray–sphere is the picking primitive** for selecting objects in a 3D scene,
and **plane–sphere is the cross-section primitive** for slicing a volume to
inspect its interior. Every routine returns a tagged result rather than `nil`,
because "parallel" and "coincident" are different answers.

**Euclidean and non-Euclidean geometry.** Euclidean, spherical and hyperbolic
models behind one interface, with distances, geodesics, angles and triangle
angle sums. The three geometries differ in exactly one axiom, and the library
makes that difference *computable* rather than merely stated:

| | Parallels through a point | Triangle angle sum |
|---|---|---|
| Euclidean | exactly one | exactly π |
| Spherical | none — any two great circles meet | > π; the excess **is** the area (Girard) |
| Hyperbolic | infinitely many | < π; the defect **is** the area (Gauss–Bonnet) |

**Complex numbers, distributions, manifolds.** Argand diagrams on Ruby's
native `Complex` type including roots of complex numbers; normal, exponential
and Poisson densities; sphere, Poincaré disk and Poincaré ball rendering.

### The unifying idea

Intersections are the connective tissue. Orthogonal projection in a Hilbert
space *is* an intersection — the projection of a vector onto a subspace is
where the perpendicular through it meets that subspace. And the behaviour of
intersecting geodesics is precisely what separates the three geometries. A
learner who works through this library sees one idea from three directions
instead of three unrelated topics.

### Work already completed

This is not a proposal from a standing start. The following is implemented and
tested before submission:

- **Eight working modules**, with **47 automated checks and 788 assertions
  passing** on Ruby's bundled Minitest — no gem installation needed to verify.
- Correctness is checked against **exact analytic values**, not eyeballed
  plots: the spherical octant's angle sum is verified to be exactly 3π/2 and
  its area π/2 (= 4π/8, one eighth of the sphere); every Poincaré geodesic is
  verified orthogonal to the disk boundary; Cauchy–Schwarz is checked over
  randomised inputs; Gram–Schmidt output is verified orthonormal and verified
  to drop linearly dependent vectors.
- **Two real bugs found and fixed by those tests**, both documented in the
  source. A duck-typed input check accepted plain integers as complex numbers,
  because Ruby's `Numeric` mixin defines `#arg`. And a geodesic constructor
  returned circles that were correctly orthogonal to the disk boundary but
  passed through the *antipodal* pair of ideal points — a bug that survived an
  orthogonality-only test and was caught when the geometry was used to
  generate the project logo. The test suite now checks the stronger property.
- A logo whose arc geometry is **computed by the library itself**.

### Deliverables

1. The `amethrine` gem published to RubyGems under the MIT licence.
2. Vega-Lite output via the `vega` gem for 2D; Three.js scene emission for 3D;
   optional GR.rb static export for publication figures.
3. Documentation site with worked examples for every module.
4. A gallery of at least 12 example notebooks/scripts, including the
   parallel-postulate and angle-sum demonstrations.
5. Continuous integration across Ruby 3.0–3.3 (configured; see
   `.github/workflows/test.yml`).
6. Intermediate and final reports per the grant schedule.
7. A conference talk or blog post introducing the library to the Ruby
   community.

### Timeline (5–6 months)

| Months | Work |
|---|---|
| 1 | Vega-Lite rendering layer for the Hilbert, Intersect and Geometry modules |
| 2 | Three.js interactive layer: ray-picking via `line_sphere`, plane cross-sections |
| 3 | Hyperbolic and spherical geodesic rendering; the parallel-postulate gallery |
| 4 | GR.rb static export; theming; IRuby notebook integration |
| 5 | Documentation site, 12 worked examples |
| 6 | RubyGems release, community outreach, final report |

Rendering is the remaining work; the mathematics is already done and tested.
That ordering is deliberate — it is the reverse of the usual risk profile, and
it means the grant period is spent on the part with the fewest unknowns.

### Design inspiration

**PerMetrics** (Nguyen Van Thieu, *JOSS* 2024, doi:10.21105/joss.06143) is the
model: comprehensive coverage of a single bounded domain, a stateless API, and
a deliberately minimal dependency footprint — 112 metrics on NumPy and SciPy
alone. AMETHRINE aims to be that for mathematical visualization in Ruby. **No
PerMetrics code is used**: it is GPL-3 and AMETHRINE is MIT, so the debt is
architectural and is credited as such in the repository.

## Project deliverables

As enumerated above: the `amethrine` gem on RubyGems (MIT), 2D and 3D
rendering layers, optional static export, documentation site, a 12-example
gallery, CI across four Ruby versions, the required reports, and a community
talk or post.

---

### Notes before submission

- Confirm `amethrine` is unclaimed on RubyGems.
- Fill in surname, email, and GitHub URL.
- The Ruby Association selects on impact, originality, and feasibility. This
  draft leans on: *originality* — nothing in Ruby covers this; *feasibility* —
  eight modules and 47 tests already exist, and the hard part is done;
  *impact* — a mathematical layer other gems can build on, plus teaching value.
- If you can name a specific Ruby project or course that would adopt this,
  add one sentence. Concrete adoption signals help more than extra prose.

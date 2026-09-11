Gem::Specification.new do |s|
  s.name        = "amethrine"
  s.version     = "0.2.0"
  s.summary     = "Interactive visualization of complex numbers, Hilbert spaces, intersections and non-Euclidean geometry"
  s.description = <<~DESC
    AMETHRINE provides Ruby with interactive visualization of advanced
    mathematical structure: complex numbers on the Argand plane, probability
    distributions, Hilbert space operations (inner products, Gram-Schmidt,
    orthogonal projection, Parseval defect), geometric intersections
    (line-line, line-plane, ray-sphere, plane-plane, plane-sphere), and the
    Euclidean, spherical and hyperbolic geometries behind a single interface.

    The core has no runtime dependencies: it emits plain Hashes that render
    as Vega-Lite specs or Three.js scenes, so it is trivially testable and
    imposes no rendering stack on the caller.
  DESC
  s.authors     = ["Sebastian"]
  s.homepage    = "https://github.com/YOURNAME/amethrine"
  s.license     = "MIT"
  s.files       = Dir["lib/**/*.rb"] + Dir["assets/*.svg"] + ["README.md", "LICENSE"]
  s.required_ruby_version = ">= 3.0"
  s.metadata = {
    "source_code_uri" => "https://github.com/YOURNAME/amethrine",
    "bug_tracker_uri" => "https://github.com/YOURNAME/amethrine/issues"
  }
  # No runtime dependencies by design. `vega` is a caller-side concern.
  s.add_development_dependency "minitest", "~> 5.0"
end

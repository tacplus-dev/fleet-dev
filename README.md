# fleet-dev

The deployment repo of the dev fleet: the small cluster the new design is proven on, with
doppelganger as the first service built outside the platform tree.

`fleet.yaml` names the registries this fleet trusts, the tacplus floor, and every service the
fleet runs with the repo implementing it. `dependencies.yaml` holds the language and tool pins for
everything generated from the fleet's merged protos. `tacplus fleet build` resolves it all and
writes `fleet.lock`, the exact commits; `build/proto` is the merged tree the fleet-side services are
generated from.

Maven resolves each plugin's own dependencies apart from the pins: the Java services override the ones a
pinned plugin brings vulnerable, as [docs/java-plugins.md](docs/java-plugins.md) says, and
`checks/shade.sh` checks that a shaded jar still builds with them, and `checks/plugins.sh` what the antrun,
exec and build-helper plugins run on.

`tools.node` is Node 24 or later without the end-of-life lines (25): `checks/node.sh` resolves the
`lang.typescript` pins at the latest versions in range and at their floors, and checks that it admits only a
Node every resolved package's `engines.node` allows and no line past its end of life in nodejs/Release's
`schedule.json` (#20).

`lang.rust` pins hyper 1.9.0 or later, past the unmaintained pin-utils (RUSTSEC-2026-0441): `checks/rust.sh`
resolves the `lang.rust` pins as exact versions and fails on any crate it denies (#21) or if they do not build
together (`cargo check`, #22: toml 0.8.23, as 0.8.22 does not build against a fresh toml_edit). It needs
`protoc` on PATH (or `PROTOC`), which prost-wkt-types runs in its build script (#23).

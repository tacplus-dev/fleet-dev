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

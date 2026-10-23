# fleet-dev

The deployment repo of the dev fleet: the small cluster the new design is proven on, with
doppelganger as the first service built outside the platform tree.

`fleet.yaml` names the registries this fleet trusts, the tacplus floor, and every service the
fleet runs with the repo implementing it. `dependencies.yaml` holds the language and tool pins for
everything generated from the fleet's merged protos. `tacplus fleet build` resolves it all and
writes `fleet.lock`, the exact commits; `build/proto` is the merged tree the fleet-side services are
generated from.

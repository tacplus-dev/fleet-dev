# Roadmap: fleet-dev

Owned by Jody; changed only by an agent at Jody's request. Loopers propose in PROPOSALS.md.

## Now
Today only `fleet.yaml`, `fleet.lock` and `dependencies.yaml` (13 services, tacplus floor 2.2); no cluster, deploy or tests yet; no releases or tags.
Decided to become THE self-contained test fleet for tacplus-dev: every service, an ephemeral cluster per run, end-to-end tests, no SeaBeam (#3).

## Next
- Nothing unblocked: every approved issue is blocked (see Later).

## Later
- Move the fleet to tacplus 2.4 (#1): blocked on the 2.4 floor in blobstore#1, coop#1, doppelganger#1, kmaker#1, letsencrypt#1, opa#1, operator#1, pigeon#1, tenantecho#1.
- The self-contained test fleet: every service, ephemeral cluster per run, test IdP, end-to-end tests (#3): blocked on #1.
- Pin services by release line, deploy release images (#2): blocked on tacplus#180.
- Go x/crypto, x/net, grpc advisories; fixes need Go 1.26 (#7): blocked on #1.
- Python floors allow vulnerable packages; fixes need Python >=3.10 (#8): blocked on #1.
- Advisories needing breaking changes: jsonwebtoken, rustls-pemfile, hazelcast (#9): blocked on #1.
- Deployment moves to a per-deployment pipeline, with Jody's sign-off (tacplus-dev/roadmap:decisions/deployments-per-cluster-2026-10-26.md).

## Not doing
- A long-lived cluster, SeaBeam project/image/registry, public DNS or Let's Encrypt in test runs: tacplus-dev must work by itself (#3).

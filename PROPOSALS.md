# Proposals: fleet-dev

Written by loopers. Each proposal: what, why, links. Jody promotes accepted ones into ROADMAP.md (via an agent);
the looper then marks it `promoted` or `declined` here with the date.

## Open
- **<title>** (<date>, <issue/run link>): <what and why>
- **CI: an advisory scan of the resolved dependency trees** (2026-10-28, #10): a workflow that resolves the
  `lang.*` pins in `dependencies.yaml` (for Java, a throwaway `pom.xml` and `mvn dependency:list`, plugins
  excluded) and queries OSV (`https://api.osv.dev/v1/querybatch`) for the resolved artifacts, transitive ones
  included. Each advisory so far (#6, #9, #10, #11, #12, #13) was found by hand. Guava in #10 was a transitive
  one, invisible to a scan of the pins alone. Advisories already tracked by an open issue would need an allow-list.
  OSV also covers what an ecosystem auditor misses: block-buffer GHSA-qwgh-2vcv-g2f7 (#14) is not in RustSec, so
  `cargo audit` passed while OSV flagged it (2026-10-29).
  Two more things it should cover (2026-11-02): the Maven plugins' own dependencies, not excluded, since
  maven-compiler-plugin 3.15.0 pulls a vulnerable plexus-utils (#16); and the `>=`/`^` floors resolved as exact
  versions, not just a fresh resolve, since starlette under the fastapi floor (#15) is invisible to a latest-version
  `pip-audit`/`npm audit`.
  And each plugin resolved on its own (`mvn dependency:resolve-plugins` in a pom that binds them), not all the pins
  as dependencies of one pom (2026-11-02, #16): Maven gives each plugin its own classpath, but one pom mediates them
  into a single tree, nearest wins. That hides the plexus-utils 3.5.1 of maven-shade-plugin 3.6.1 behind
  maven-compiler-plugin 3.16.0's 4.0.3, and it is vulnerable to the same GHSA-6fmv-xxpf-w3cw.
- **Release-line pins need the 2.6 floor, not 2.4** (2026-10-29, #2): `version: "MAJOR.MINOR"` in `fleet.yaml`
  and the version/image digest in `fleet.lock` come from tacplus#180, which ships in 2.6.0 (tacplus#213, not
  yet released). #1 moves the floor to 2.4 only, so #2 still cannot relock after #1 closes. #1 could target 2.6
  instead, or a 2.6 floor move could follow it. The relock also needs a token with `read:packages`: the service
  images are private ghcr packages, and the looper's token has only `repo` and `workflow`.
- **The deploy tree is not in this repo** (2026-10-29, #2): #1 and #2 cite `images/build.sh`, `images/pins.yaml`
  and `deploy/build-operator.sh`, but main has none of them and no deploy docs. Image pull secrets for the private
  release images (#2's note: in every namespace running them, including the tenant namespaces nsproxy creates)
  need a home there. Either bring the tree here (with #3's ephemeral cluster) or say where it lives.

## Promoted / declined

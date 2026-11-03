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
  `dependency:resolve-plugins` lists a plugin's own pom dependencies, not a service pom's override of them
  (docs/java-plugins.md, #17): the scan needs the allow-list for those, or reads the realm from `mvn -X`.
- **tacplus: plugin dependencies in `dependencies.yaml`** (2026-11-02, #17): `lang.java.dependencies` pins a
  Maven plugin's version but cannot say what it runs on, so the plexus-utils 3.6.1 override under
  maven-shade-plugin is a convention each Java service's pom keeps by hand (docs/java-plugins.md). A way to
  express it (a plugin's `dependencies:`, say) would let tacplus carry it. A tacplus proposal, as the hub
  said on #17, not a change here.
- **The default-lifecycle plugins bring affected plexus-utils too** (2026-11-02, #17): Maven 3.9.16's
  defaults, which `dependencies.yaml` does not pin, are resources 3.4.0 and jar 3.5.0 (plexus-utils 4.0.2),
  install/deploy 3.1.4 (4.0.1) and site 3.12.1 (3.4.2), all under GHSA-6fmv-xxpf-w3cw. They come from the
  Maven that runs the build unless a pom pins them. Pin releases on 4.0.3 here (and in the service poms) or
  override them as #17 does shade; checks/plugins.sh's realm check (#18) could cover them.
- **The service poms still pin maven-compiler-plugin 3.15.0** (2026-11-02, #17): #16 moved the pin here to
  3.16.0 past GHSA-6fmv-xxpf-w3cw, but the root poms of kernel, stratum and eventbus still set
  `maven-compiler-plugin.version` to 3.15.0, on the affected plexus-utils. The shade overrides (kernel#33,
  stratum#25, eventbus#18) did not touch it, and no issue tracks it: each service needs a `bug` issue to bump it.
- **Drop the shade override when shade is fixed** (2026-11-02, #17): maven-shade-plugin 3.6.2 still asks for
  plexus-utils 3.6.0. Once a release asks for 3.6.1 or later, pin it and remove the override from
  docs/java-plugins.md, checks/shade and the service poms.
- **Drop the antrun override when antrun is fixed** (2026-11-03, #18): maven-antrun-plugin 3.2.0, the newest
  release, still asks for plexus-utils 4.0.2. Once a release asks for 4.0.3 or later, pin it and remove the
  override from docs/java-plugins.md, checks/plugins and the service poms.
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

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
  For Rust, checks/rust.sh (#21) already resolves the `lang.rust` pins into a lockfile but only denies the
  crates named in it (pin-utils, RUSTSEC-2026-0441); running osv-scanner on that lockfile with the allow-list
  (#9's jsonwebtoken and rustls-pemfile, #13's unsafe-libyaml) would catch the next advisory (2026-11-05).
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
- **Drop the plexus-archiver override when jar and plugin-plugin are fixed** (2026-11-03, kernel#37):
  maven-jar-plugin 3.5.0 and maven-plugin-plugin 3.15.1 load aircompressor 0.27 through plexus-archiver 4.10.x
  (GHSA-vx9q-rhv9-3jvg), and only their 4.0.0 betas move past it. Once a release of each asks for plexus-archiver
  4.15.0 or later, pin it and remove the override from docs/java-plugins.md and the service poms. checks/plugins.sh
  could run a jar goal and fail on any aircompressor below 2.0.3 in its realm.
- **Release-line pins need the 2.6 floor, not 2.4** (2026-10-29, #2): `version: "MAJOR.MINOR"` in `fleet.yaml`
  and the version/image digest in `fleet.lock` come from tacplus#180, which ships in 2.6.0 (tacplus#213, not
  yet released). #1 moves the floor to 2.4 only, so #2 still cannot relock after #1 closes. #1 could target 2.6
  instead, or a 2.6 floor move could follow it. The relock also needs a token with `read:packages`: the service
  images are private ghcr packages, and the looper's token has only `repo` and `workflow`.
- **The deploy tree is not in this repo** (2026-10-29, #2): #1 and #2 cite `images/build.sh`, `images/pins.yaml`
  and `deploy/build-operator.sh`, but main has none of them and no deploy docs. Image pull secrets for the private
  release images (#2's note: in every namespace running them, including the tenant namespaces nsproxy creates)
  need a home there. Either bring the tree here (with #3's ephemeral cluster) or say where it lives.
- **The generated TypeScript packages still declare Node 18** (2026-11-04, #20): tacplus's chassis templates
  hardcode `engines.node: '>=18.0.0'` and do not read `tools.node`, so gateway's webapp, generated from the fleet
  tree on Node 24, has seven packages claiming Node 18. A tacplus bug, filed as tacplus-dev/tacplus#318.
- **The fleet has no Node image, and its TypeScript packages declare no engines** (2026-11-04, #20): gateway's
  webapp and webapp-login are its only TypeScript, built on the host's Node (`just webapp`, no `FROM node` in any
  service, no `engines`, no `.nvmrc`), and its image only serves the built files. So nothing pins the Node the
  fleet builds on. gateway could declare `engines.node` (the `tools.node` here) in both package.json files and set
  `engine-strict` in an `.npmrc`, and the build image could carry a Node in the range.
- **Each service's `proto/dependencies.yaml` still says `node: '>=18.0.0'`** (2026-11-04, #20): the copies in
  the service repos (kernel, gateway, oauth and the other ten) are not this file, and #20 moved only this one. If
  they are meant to follow it, they need the same raise (or to be synced from here).
- **Run checks/node.sh on a schedule** (2026-11-04, #20): an end-of-life date passes with no push (24's is
  2028-04-30, 26's later), and a new release in a `^` range can raise an `engines.node` floor. A weekly run would
  catch both before a build does.
- **The default clean and site plugins run on vulnerable commons-io too** (2026-11-05, nightly scan, #18): the
  default-lifecycle entry above lists plexus-utils only. Maven 3.9.16's default maven-clean-plugin 3.2.0 runs on
  commons-io 2.6 (GHSA-78wr-2p64-hpwj, the advisory #18 moved build-helper off), through maven-shared-utils 3.3.4,
  and every `mvn clean` loads it, checks/shade.sh's and checks/plugins.sh's included
  (`mvn -X -f checks/plugins/pom.xml clean`: `Populating class realm plugin>...:maven-clean-plugin:3.2.0`,
  `Included: commons-io:commons-io:jar:2.6`). clean 3.5.0, the newest release, drops commons-io but asks for
  plexus-utils 4.0.2 (GHSA-6fmv-xxpf-w3cw), so it needs the 4.0.3 override that antrun has. The default site
  plugin 3.12.1 brings far more under `mvn site` (Jetty 9.4.46, jsoup 1.10.2, velocity 1.7, commons-compress 1.20,
  dom4j 1.1, commons-beanutils 1.7.0, guava 16.0.1, per `mvn dependency:resolve-plugins` and OSV). Pin clean
  (and site, if the services run it) with overrides here and in the service poms, and have checks/plugins.sh's
  realm check cover clean.

## Promoted / declined

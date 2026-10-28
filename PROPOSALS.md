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

## Promoted / declined

# History: fleet-dev

Append-only: add entries at the end, never edit or remove one (CI enforces it). One line each:
`- <YYYY-MM-DD> <who: looper|agent|jody> <kind: issue|decision|release|deploy> <one line> (<links>)`

- 2026-10-28 looper issue dependencies.yaml: Guava 33.5.0-android (via grpc-java) has GHSA-xxph-c9ww-hj94; pin 33.7.2 (#10, 951518f)
- 2026-11-02 looper issue dependencies.yaml: maven-compiler-plugin 3.15.0 pulls plexus-utils 4.0.2 (GHSA-6fmv-xxpf-w3cw, HIGH); pin 3.16.0 (#16, e57013e)
- 2026-11-02 looper issue dependencies.yaml: maven-shade-plugin 3.6.1 pulls plexus-utils 3.5.1 (GHSA-6fmv-xxpf-w3cw, HIGH); no fixed shade release (#17, 162ec36)
- 2026-11-03 looper issue dependencies.yaml: exec-maven-plugin 3.5.0, maven-antrun-plugin 3.1.0 and build-helper-maven-plugin 3.6.0 run on vulnerable plexus-utils (GHSA-6fmv-xxpf-w3cw) and commons-io; bump exec/build-helper, override antrun (#18, 8c2f6ec)

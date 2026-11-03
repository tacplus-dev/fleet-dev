#!/usr/bin/env bash
# The plugin realm check (#18, docs/java-plugins.md): run a goal of maven-antrun-plugin,
# exec-maven-plugin and build-helper-maven-plugin at the versions dependencies.yaml pins (checks/plugins,
# antrun with its plexus-utils override), and check that the class realm Maven builds for each (mvn -X)
# has no plexus-utils under GHSA-6fmv-xxpf-w3cw (below 3.6.1, or 4.0.0 to 4.0.2) and no commons-io under
# GHSA-78wr-2p64-hpwj (below 2.14.0).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
dir=$root/checks/plugins
log=$(mktemp)
trap 'rm -f "$log"' EXIT

# pin <groupId:artifactId>: its version in dependencies.yaml's lang.java.dependencies.
pin() {
	local v
	v=$(sed -n "s/^ *$1: *\"\{0,1\}\([^\"]*\)\"\{0,1\} *$/\1/p" "$root/dependencies.yaml")
	[ -n "$v" ] || { echo "plugins check: no pin for $1 in dependencies.yaml" >&2; exit 1; }
	echo "$v"
}
antrun=$(pin org.apache.maven.plugins:maven-antrun-plugin)
exec=$(pin org.codehaus.mojo:exec-maven-plugin)
helper=$(pin org.codehaus.mojo:build-helper-maven-plugin)

if ! mvn -B -X -f "$dir/pom.xml" clean validate \
	-Dantrun-plugin.version="$antrun" -Dexec-plugin.version="$exec" -Dbuild-helper-plugin.version="$helper" \
	>"$log" 2>&1; then
	tail -40 "$log" >&2
	echo "plugins check: mvn validate failed" >&2
	exit 1
fi

# lt <a> <b>: version a is below version b.
lt() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]; }

# realm <groupId:artifactId:version>: the artifacts the plugin's class realm includes, groupId:artifactId:version.
realm() {
	awk -v p="plugin>$1" '
		/Populating class realm/ { on = index($0, p) > 0; next }
		on && /Included: / { print; next }
		on { on = 0 }' "$log" | sed -n 's/.*Included: \([^:]*\):\([^:]*\):jar:\([^ ]*\).*/\1:\2:\3/p'
}

fail=0
summary=
for p in org.apache.maven.plugins:maven-antrun-plugin:$antrun org.codehaus.mojo:exec-maven-plugin:$exec \
	org.codehaus.mojo:build-helper-maven-plugin:$helper; do
	r=$(realm "$p")
	[ -n "$r" ] || { echo "plugins check: no class realm for $p in mvn -X" >&2; fail=1; continue; }
	pu= ci=
	for a in $r; do
		v=${a##*:}
		case ${a%:*} in
		org.codehaus.plexus:plexus-utils)
			pu=$v
			if lt "$v" 3.6.1 || { ! lt "$v" 4.0.0 && lt "$v" 4.0.3; }; then
				echo "plugins check: $p runs on plexus-utils $v (GHSA-6fmv-xxpf-w3cw)" >&2
				fail=1
			fi ;;
		commons-io:commons-io)
			ci=$v
			if lt "$v" 2.14.0; then
				echo "plugins check: $p runs on commons-io $v (GHSA-78wr-2p64-hpwj)" >&2
				fail=1
			fi ;;
		esac
	done
	summary="$summary, ${p#*:} on plexus-utils ${pu:-none}${ci:+ and commons-io $ci}"
done
[ "$fail" = 0 ] || exit 1
echo "plugins check: ${summary#, }"

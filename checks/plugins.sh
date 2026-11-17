#!/usr/bin/env bash
# The plugin realm check (#18, docs/java-plugins.md): run a goal of maven-antrun-plugin,
# exec-maven-plugin and build-helper-maven-plugin at the versions dependencies.yaml pins (checks/plugins,
# antrun with its plexus-utils override), and check that each ran and that no plugin class realm of the
# run (mvn -X), maven-clean-plugin's included (#27), has a plexus-utils, commons-io or aircompressor a
# known advisory affects (checks/lib/realms.sh).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
. "$root/checks/lib/realms.sh"
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
clean=$(pin org.apache.maven.plugins:maven-clean-plugin)
resources=$(pin org.apache.maven.plugins:maven-resources-plugin)
jar=$(pin org.apache.maven.plugins:maven-jar-plugin)
install=$(pin org.apache.maven.plugins:maven-install-plugin)
deploy=$(pin org.apache.maven.plugins:maven-deploy-plugin)

if ! mvn -B -X -f "$dir/pom.xml" clean validate \
	-Dantrun-plugin.version="$antrun" -Dexec-plugin.version="$exec" -Dbuild-helper-plugin.version="$helper" \
	-Dclean-plugin.version="$clean" -Dresources-plugin.version="$resources" -Djar-plugin.version="$jar" \
	-Dinstall-plugin.version="$install" -Ddeploy-plugin.version="$deploy" \
	>"$log" 2>&1; then
	tail -40 "$log" >&2
	echo "plugins check: mvn validate failed" >&2
	exit 1
fi

fail=0
advisories plugins "$log" || fail=1
summary=
for p in org.apache.maven.plugins:maven-clean-plugin:$clean org.apache.maven.plugins:maven-antrun-plugin:$antrun \
	org.codehaus.mojo:exec-maven-plugin:$exec org.codehaus.mojo:build-helper-maven-plugin:$helper; do
	r=$(realm "$log" "$p")
	[ -n "$r" ] || { echo "plugins check: no class realm for $p in mvn -X" >&2; fail=1; continue; }
	pu=$(printf '%s\n' $r | sed -n 's/^org\.codehaus\.plexus:plexus-utils://p')
	ci=$(printf '%s\n' $r | sed -n 's/^commons-io:commons-io://p')
	summary="$summary, ${p#*:} on plexus-utils ${pu:-none}${ci:+ and commons-io $ci}"
done
[ "$fail" = 0 ] || exit 1
echo "plugins check: ${summary#, }"

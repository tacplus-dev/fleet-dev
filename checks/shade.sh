#!/usr/bin/env bash
# The shaded-jar check (#17, docs/java-plugins.md): build checks/shade with the maven-shade-plugin,
# maven-compiler-plugin and gson versions dependencies.yaml pins, run the jar, and check that the
# shade plugin's own classpath (its class realm in mvn -X) has plexus-utils 3.6.1, the override, and
# nothing else: 3.5.1, what shade 3.6.1 asks for, has GHSA-6fmv-xxpf-w3cw.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
dir=$root/checks/shade
log=$(mktemp)
trap 'rm -f "$log"' EXIT

# pin <groupId:artifactId>: its version in dependencies.yaml's lang.java.dependencies.
pin() {
	local v
	v=$(sed -n "s/^ *$1: *\"\{0,1\}\([^\"]*\)\"\{0,1\} *$/\1/p" "$root/dependencies.yaml")
	[ -n "$v" ] || { echo "shade check: no pin for $1 in dependencies.yaml" >&2; exit 1; }
	echo "$v"
}
shade=$(pin org.apache.maven.plugins:maven-shade-plugin)
compiler=$(pin org.apache.maven.plugins:maven-compiler-plugin)
gson=$(pin com.google.code.gson:gson)

if ! mvn -B -X -f "$dir/pom.xml" clean package \
	-Dshade-plugin.version="$shade" -Dmaven-compiler-plugin.version="$compiler" -Dgson.version="$gson" \
	>"$log" 2>&1; then
	tail -40 "$log" >&2
	echo "shade check: mvn package failed" >&2
	exit 1
fi

out=$(java -jar "$dir/target/shade-check.jar")
[ "$out" = '["shaded"]' ] || { echo "shade check: the shaded jar printed '$out', not '[\"shaded\"]'" >&2; exit 1; }

# The plexus-utils in the realm Maven builds for the shade plugin (mvn -X lists what it includes).
realm=$(awk -v p="plugin>org.apache.maven.plugins:maven-shade-plugin:$shade" '
	/Populating class realm/ { on = index($0, p) > 0; next }
	on && /Included: / { print; next }
	on { on = 0 }' "$log" | sed -n 's/.*Included: org\.codehaus\.plexus:plexus-utils:jar:\([^ ]*\).*/\1/p')
[ -n "$realm" ] || { echo "shade check: no plexus-utils in the maven-shade-plugin:$shade realm" >&2; exit 1; }
for v in $realm; do
	case $v in
	3.6.1) ;;
	*) echo "shade check: maven-shade-plugin:$shade runs on plexus-utils $v, not 3.6.1 (GHSA-6fmv-xxpf-w3cw)" >&2; exit 1 ;;
	esac
done
echo "shade check: maven-shade-plugin $shade on plexus-utils $realm, compiler $compiler, gson $gson: shaded jar builds and runs"

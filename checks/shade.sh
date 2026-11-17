#!/usr/bin/env bash
# The shaded-jar check (#17, docs/java-plugins.md): build checks/shade with the maven-shade-plugin,
# maven-compiler-plugin and gson versions dependencies.yaml pins, run the jar, and check that the
# shade plugin's own classpath (its class realm in mvn -X) has plexus-utils 3.6.1, the override, and
# nothing else: 3.5.1, what shade 3.6.1 asks for, has GHSA-6fmv-xxpf-w3cw. The build runs through deploy, to a
# scratch file repository, so that every default-lifecycle plugin's realm (clean, resources, jar, install,
# deploy: #27) is read too: none of the run's plugin realms may have a plexus-utils, commons-io or
# aircompressor a known advisory affects (checks/lib/realms.sh).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
. "$root/checks/lib/realms.sh"
dir=$root/checks/shade
log=$(mktemp)
repo=$(mktemp -d)
trap 'rm -rf "$log" "$repo"' EXIT

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
clean=$(pin org.apache.maven.plugins:maven-clean-plugin)
resources=$(pin org.apache.maven.plugins:maven-resources-plugin)
jar=$(pin org.apache.maven.plugins:maven-jar-plugin)
install=$(pin org.apache.maven.plugins:maven-install-plugin)
deploy=$(pin org.apache.maven.plugins:maven-deploy-plugin)

# install puts shade-check 0-SNAPSHOT in the local repository too; deploy, in the scratch one.
if ! mvn -B -X -f "$dir/pom.xml" clean deploy -DaltDeploymentRepository="scratch::file://$repo" \
	-Dshade-plugin.version="$shade" -Dmaven-compiler-plugin.version="$compiler" -Dgson.version="$gson" \
	-Dclean-plugin.version="$clean" -Dresources-plugin.version="$resources" -Djar-plugin.version="$jar" \
	-Dinstall-plugin.version="$install" -Ddeploy-plugin.version="$deploy" \
	>"$log" 2>&1; then
	tail -40 "$log" >&2
	echo "shade check: mvn deploy failed" >&2
	exit 1
fi

out=$(java -jar "$dir/target/shade-check.jar")
[ "$out" = '["shaded"]' ] || { echo "shade check: the shaded jar printed '$out', not '[\"shaded\"]'" >&2; exit 1; }

# The plexus-utils in the realm Maven builds for the shade plugin (mvn -X lists what it includes).
realm=$(realm "$log" "org.apache.maven.plugins:maven-shade-plugin:$shade" | sed -n 's/^org\.codehaus\.plexus:plexus-utils://p')
[ -n "$realm" ] || { echo "shade check: no plexus-utils in the maven-shade-plugin:$shade realm" >&2; exit 1; }
for v in $realm; do
	case $v in
	3.6.1) ;;
	*) echo "shade check: maven-shade-plugin:$shade runs on plexus-utils $v, not 3.6.1 (GHSA-6fmv-xxpf-w3cw)" >&2; exit 1 ;;
	esac
done

# Every default-lifecycle plugin ran at its pin, and no realm of the run falls back to an affected artifact.
fail=0
for p in maven-clean-plugin:$clean maven-resources-plugin:$resources maven-jar-plugin:$jar \
	maven-install-plugin:$install maven-deploy-plugin:$deploy; do
	[ -n "$(realm "$log" "org.apache.maven.plugins:$p")" ] || { echo "shade check: no class realm for $p in mvn -X" >&2; fail=1; }
done
advisories shade "$log" || fail=1
[ "$fail" = 0 ] || exit 1
echo "shade check: maven-shade-plugin $shade on plexus-utils $realm, compiler $compiler, gson $gson: shaded jar builds and runs;" \
	"clean $clean, resources $resources, jar $jar, install $install, deploy $deploy: no affected plugin realm"

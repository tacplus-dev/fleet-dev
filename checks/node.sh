#!/usr/bin/env bash
# The Node floor check (#20): resolve the lang.typescript pins of dependencies.yaml twice, at the latest
# versions in range and with each floor taken as an exact version, and check that tools.node admits only
# Node versions every resolved package runs on (its engines.node) and no line past its end of life.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

tools=$(sed -n "s/^    node: *['\"]\{0,1\}\([^'\"]*\)['\"]\{0,1\} *$/\1/p" "$root/dependencies.yaml")
[ -n "$tools" ] || { echo "node check: no tools.node in dependencies.yaml" >&2; exit 1; }

# The lang.typescript.dependencies block, one "name range" per line.
deps=$(awk '
	/^    typescript:$/ { ts = 1; next }
	ts && /^        dependencies:$/ { on = 1; next }
	on && /^            / { print; next }
	{ on = 0; if (!/^        /) ts = 0 }' "$root/dependencies.yaml" |
	sed "s/^ *['\"]\{0,1\}\([^'\":]*\)['\"]\{0,1\}: *['\"]\{0,1\}\([^'\"]*\)['\"]\{0,1\} *$/\1 \2/")
[ -n "$deps" ] || { echo "node check: no lang.typescript.dependencies in dependencies.yaml" >&2; exit 1; }

# manifest <dir> <floors>: a package.json of the pins in <dir>, each range exact at its floor if <floors>.
manifest() {
	mkdir -p "$1"
	{
		echo '{ "name": "node-check", "private": true, "dependencies": {'
		echo "$deps" | awk -v floors="$2" '{
			v = $2; if (floors) sub(/^(\^|~|>=)/, "", v)
			printf "%s    \"%s\": \"%s\"", (NR > 1 ? ",\n" : ""), $1, v }'
		printf '\n} }\n'
	} >"$1/package.json"
	(cd "$1" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund --loglevel=error >/dev/null)
}
manifest "$tmp/latest" ""
manifest "$tmp/floors" 1
(cd "$tmp" && npm install --prefix "$tmp/semver" --no-audit --no-fund --loglevel=error semver@^7 >/dev/null)
curl -fsSL https://raw.githubusercontent.com/nodejs/Release/main/schedule.json -o "$tmp/schedule.json"

node "$root/checks/node/engines.mjs" "$tmp/semver" "$tools" "$tmp/schedule.json" \
	"$tmp/latest/package-lock.json" "$tmp/floors/package-lock.json"

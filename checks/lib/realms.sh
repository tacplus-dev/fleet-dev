# The plugin realm reader (#27, docs/java-plugins.md), sourced by checks/shade.sh and checks/plugins.sh:
# every plugin class realm of a mvn -X run, the default-lifecycle plugins (clean, resources, jar, install,
# deploy) included, and the known advisories none of them may fall back to.

# lt <a> <b>: version a is below version b.
lt() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]; }

# realms <log>: one line per artifact a plugin's class realm includes, "<plugin g:a:v> <g:a:v>".
realms() {
	awk '
		/Populating class realm plugin>/ { p = $0; sub(/.*plugin>/, "", p); sub(/ .*/, "", p); next }
		/Populating class realm/ { p = ""; next }
		p != "" && /Included: / { a = $0; sub(/.*Included: /, "", a); sub(/ .*/, "", a); print p, a; next }
		{ p = "" }' "$1" | sed -n 's/^\([^ ]*\) \([^:]*\):\([^:]*\):jar:\([^ ]*\)$/\1 \2:\3:\4/p'
}

# realm <log> <plugin g:a:v>: the artifacts that plugin's class realm includes, g:a:v.
realm() { realms "$1" | awk -v p="$2" '$1 == p { print $2 }'; }

# advisories <check> <log>: fail (1), saying which, if any plugin realm of the run includes a plexus-utils
# under GHSA-6fmv-xxpf-w3cw (below 3.6.1, or 4.0.0 to 4.0.2), a commons-io under GHSA-78wr-2p64-hpwj
# (below 2.14.0) or an aircompressor under GHSA-vx9q-rhv9-3jvg (below 2.0.3).
advisories() {
	local fail=0 p a v
	[ -n "$(realms "$2")" ] || { echo "$1 check: no plugin class realm in mvn -X" >&2; return 1; }
	while read -r p a; do
		v=${a##*:}
		case ${a%:*} in
		org.codehaus.plexus:plexus-utils)
			if lt "$v" 3.6.1 || { ! lt "$v" 4.0.0 && lt "$v" 4.0.3; }; then
				echo "$1 check: $p runs on plexus-utils $v (GHSA-6fmv-xxpf-w3cw)" >&2
				fail=1
			fi ;;
		commons-io:commons-io)
			if lt "$v" 2.14.0; then
				echo "$1 check: $p runs on commons-io $v (GHSA-78wr-2p64-hpwj)" >&2
				fail=1
			fi ;;
		io.airlift:aircompressor)
			if lt "$v" 2.0.3; then
				echo "$1 check: $p runs on aircompressor $v (GHSA-vx9q-rhv9-3jvg)" >&2
				fail=1
			fi ;;
		esac
	done < <(realms "$2")
	return $fail
}

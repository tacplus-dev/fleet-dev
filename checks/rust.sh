#!/usr/bin/env bash
# The Rust resolve check (#21): resolve the lang.rust pins of dependencies.yaml, each as an exact version,
# check that the lockfile has none of the crates RustSec flags that the pins must not pull, and that the
# resolved pins build together (#22).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Crates the resolved pins must not contain, each with its advisory.
denied="pin-utils RUSTSEC-2026-0441"

# The lang.rust.dependencies block, one "name = "=version"" per line.
deps=$(awk '
	/^    rust:$/ { rs = 1; next }
	rs && /^        dependencies:$/ { on = 1; next }
	on && /^            / { print; next }
	{ on = 0; if (!/^        /) rs = 0 }' "$root/dependencies.yaml" |
	sed "s/^ *['\"]\{0,1\}\([^'\":]*\)['\"]\{0,1\}: *['\"]\{0,1\}=\{0,1\}\([^'\"]*\)['\"]\{0,1\} *$/\1 = \"=\2\"/")
[ -n "$deps" ] || { echo "rust check: no lang.rust.dependencies in dependencies.yaml" >&2; exit 1; }

mkdir -p "$tmp/src"
echo 'fn main() {}' >"$tmp/src/main.rs"
printf '[package]\nname = "rust-check"\nversion = "0.0.0"\nedition = "2021"\n\n[dependencies]\n%s\n' "$deps" >"$tmp/Cargo.toml"
(cd "$tmp" && cargo generate-lockfile --quiet)

found=
while read -r crate advisory; do
	grep -q "^name = \"$crate\"$" "$tmp/Cargo.lock" || continue
	echo "rust check: the lang.rust pins resolve $crate ($advisory):" >&2
	(cd "$tmp" && cargo tree --quiet -e normal -i "$crate") >&2
	found=1
done <<<"$denied"
[ -z "$found" ] || exit 1
echo "rust check: the lang.rust pins resolve none of: $(cut -d' ' -f1 <<<"$denied" | xargs)"

(cd "$tmp" && cargo check --quiet --keep-going) || { echo "rust check: the resolved lang.rust pins do not build" >&2; exit 1; }
echo "rust check: the resolved lang.rust pins build"

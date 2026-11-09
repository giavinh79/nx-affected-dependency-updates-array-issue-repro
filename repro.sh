#!/usr/bin/env bash
# Shows that an array `projectsAffectedByDependencyUpdates` marks projects
# affected even when no lock file changed.
set -euo pipefail
cd "$(dirname "$0")"
export NX_DAEMON=false NX_TUI=false NX_NO_CLOUD=true

nx() { ./node_modules/.bin/nx "$@" 2>/dev/null; }
or_none() { local s; s=$(cat); echo "${s:-(none)}"; }
affected() { nx show projects --affected --files="$1" --json=false | sort | tr '\n' ' ' | or_none; }
tasks() {
  nx affected -t test --files="$1" --graph=stdout |
    node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(Object.keys(JSON.parse(s).tasks.tasks).sort().join(" ")))' |
    or_none
}
row() { printf '%-62s expected: %-8s actual: %s\n' "$1" "$2" "$3"; }

echo "Nx $(node -p "require('nx/package.json').version"), pluginsConfig: $(node -p "JSON.stringify(require('./nx.json').pluginsConfig)")"
echo
row 'nx show projects --affected --files=README.md' '(none)' "$(affected README.md)"
row 'nx show projects --affected --files=packages/a/index.js' 'a' "$(affected packages/a/index.js)"
row 'nx show projects --affected --files=package-lock.json' 'a c' "$(affected package-lock.json)"
row 'nx affected -t test --files=README.md' '(none)' "$(tasks README.md)"
row 'NX_LEGACY_AFFECTED=true nx affected -t test --files=README.md' '(none)' "$(NX_LEGACY_AFFECTED=true tasks README.md)"

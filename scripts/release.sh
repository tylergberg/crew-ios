#!/usr/bin/env bash
set -euo pipefail

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" != "main" ]]; then
  echo "Release must be run from main. Current: $branch" >&2
  exit 1
fi

git fetch --tags

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree not clean." >&2
  exit 1
fi

version=${1:-}
if [[ -z "$version" ]]; then
  echo "Usage: scripts/release.sh vX.Y.Z" >&2
  exit 1
fi

echo "Tagging $version and pushing..."
git tag -a "$version" -m "Release $version"
git push origin "$version"

echo "Now archive in Xcode from this commit."

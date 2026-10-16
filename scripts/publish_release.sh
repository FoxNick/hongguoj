#!/usr/bin/env bash
set -euo pipefail

assets="$1"
notes="$2"

version=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n1)
if [[ "$version" == *-* ]]; then
  echo "开发快照不能作为最终正式版发布。" >&2
  exit 1
fi
if [ "${GITHUB_REF_TYPE}" = "tag" ]; then
  tag="${GITHUB_REF_NAME}"
else
  tag="app-v${version//+/-}"
fi

rm -rf upload remote checksums
mkdir -p upload remote checksums
for path in "$assets"/*; do
  if [ ! -f "$path" ]; then
    continue
  fi
  name=$(basename "$path")
  if [ "$name" = "SHA256SUMS.txt" ]; then
    continue
  fi
  cp "$path" "upload/$name"
done
(cd upload && for name in *; do sha256sum "$name"; done) > checksums/SHA256SUMS.txt

exists=0
if gh release view "$tag" >/dev/null 2>&1; then
  exists=1
  gh release download "$tag" --pattern SHA256SUMS.txt --dir remote 2>/dev/null || true
  if [ -f remote/SHA256SUMS.txt ]; then
    cat remote/SHA256SUMS.txt >> checksums/SHA256SUMS.txt
  fi
fi
sort -u -k2 checksums/SHA256SUMS.txt -o checksums/SHA256SUMS.txt
cat checksums/SHA256SUMS.txt

if [ "$exists" = "1" ]; then
  gh release upload "$tag" upload/* checksums/SHA256SUMS.txt --clobber
  marker=$(head -n1 "$notes")
  body=$(gh release view "$tag" --json body -q .body)
  if ! printf '%s' "$body" | grep -qF "$marker"; then
    {
      printf '%s\n\n' "$body"
      cat "$notes"
    } > merged-notes.md
    gh release edit "$tag" --notes-file merged-notes.md
  fi
  exit 0
fi

release="${version%%+*}"
section=$(awk -v v="## ${release} " 'index($0, v) == 1 { found = 1; next } found && /^## / { exit } found { print }' README.md)
{
  printf '%s\n\n' "版本 ${version}。本版本包含全站源安装包。"
  if [[ -n "${section//[[:space:]]/}" ]]; then
    printf '%s\n' "$section"
  else
    printf '%s\n' "- 全站源：包含全部已接入站源"
  fi
  printf '\n'
  cat "$notes"
} > initial-notes.md
cat initial-notes.md
gh release create "$tag" upload/* checksums/SHA256SUMS.txt \
  --target "$GITHUB_SHA" --title "短句汇 ${version}" --notes-file initial-notes.md

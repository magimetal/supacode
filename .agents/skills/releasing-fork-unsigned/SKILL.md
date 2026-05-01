---
name: releasing-fork-unsigned
description: "Use when releasing the magimetal/supacode fork as a local unsigned build with a versioned GitHub release. Covers version bump, unsigned Debug build, .app zipping, sha256 checksum, and gh release creation. On-demand. NOT for signed/notarized distribution releases."
---

# Releasing Fork Unsigned

## When to Use / When NOT to Use

Use this skill when cutting a new release of the `magimetal/supacode` fork with an unsigned local `.app` attached to a versioned GitHub release.

Do not use this skill for:

- Signed Developer ID releases.
- Notarized builds.
- Upstream `supabitapp` releases.

## Pre-Flight Checks

Run these checks before changing version state:

```bash
git status --short
git branch --show-current
```

Requirements:

- Working tree is clean, except for intentional release artifacts you will not commit.
- Current branch is `main`.
- If syncing from upstream first, use the repo's upstream sync documentation; do not fold sync work into this release flow.

Read the current app version values:

```bash
awk -F' = ' '/^MARKETING_VERSION = /{print $2}' Configurations/Project.xcconfig
awk -F' = ' '/^CURRENT_PROJECT_VERSION = /{print $2}' Configurations/Project.xcconfig
```

Confirm the prior release pattern:

```bash
gh release list --repo magimetal/supacode
```

## Asset Naming Convention

Release asset names must use this format:

```text
Supacode-{MARKETING_VERSION}-build-{CURRENT_PROJECT_VERSION}-local-unsigned.zip
Supacode-{MARKETING_VERSION}-build-{CURRENT_PROJECT_VERSION}-local-unsigned.zip.sha256
```

Do not invent alternate names. Downstream consumers may depend on the historical pattern. Tiny strings, large blast radius.

## Step-by-Step Flow

### Step 1 — Bump version

Auto-bump patch version and build number:

```bash
make bump-version
```

Or set a specific version and build:

```bash
make bump-version VERSION=x.y.z BUILD=N
```

`make bump-version` updates `Configurations/Project.xcconfig`, commits the change, and creates a signed `v{version}` tag.

If GPG signing fails, use the manual fallback:

1. Edit `Configurations/Project.xcconfig`.
2. Commit and tag without signed commit/tag requirements:

```bash
git add Configurations/Project.xcconfig
git commit -m "bump v{version}"
git tag v{version} -m "v{version}"
```

### Step 2 — Push tag and commit

```bash
git push origin main --follow-tags
```

### Step 3 — Build unsigned Debug .app

```bash
make build-app
```

**Critical:** do not use `make archive` for this unsigned local build flow. `make archive` requires signing environment variables such as `APPLE_TEAM_ID` and `DEVELOPER_ID_IDENTITY_SHA`.

### Step 4 — Locate built .app

```bash
settings=$(xcodebuild -workspace supacode.xcworkspace -scheme supacode -configuration Debug -showBuildSettings -json 2>/dev/null)
build_dir=$(echo "$settings" | jq -r '.[0].buildSettings.BUILT_PRODUCTS_DIR')
product=$(echo "$settings" | jq -r '.[0].buildSettings.FULL_PRODUCT_NAME')
app_path="$build_dir/$product"
```

Optional guardrail:

```bash
test -d "$app_path" || { echo "app not found: $app_path"; exit 1; }
```

### Step 5 — Read version values

```bash
version=$(awk -F' = ' '/^MARKETING_VERSION = /{print $2}' Configurations/Project.xcconfig)
build=$(awk -F' = ' '/^CURRENT_PROJECT_VERSION = /{print $2}' Configurations/Project.xcconfig)
```

### Step 6 — Zip with `ditto`

```bash
mkdir -p build
zip_name="Supacode-${version}-build-${build}-local-unsigned.zip"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "build/$zip_name"
```

Use `ditto`, not `cp -r`, so the `.app` bundle is packaged with macOS metadata preserved.

### Step 7 — Generate sha256 checksum

```bash
(cd build && shasum -a 256 "$zip_name" > "$zip_name.sha256")
```

### Step 8 — Generate release notes

```bash
prev_tag=$(gh release view --repo magimetal/supacode --json tagName -q .tagName)
notes_file=$(mktemp)
gh api "repos/magimetal/supacode/releases/generate-notes" \
  -f tag_name="v${version}" \
  -f previous_tag_name="$prev_tag" \
  --jq '.body' > "$notes_file"
```

Add this Gatekeeper bypass note to the release body for unsigned consumers:

```text
Unsigned local build: macOS Gatekeeper may block first launch. After installing to /Applications, run:

xattr -cr /Applications/supacode.app
```

Edit `$notes_file` before release creation if needed.

### Step 9 — Create release with assets

```bash
gh release create "v${version}" \
  --repo magimetal/supacode \
  --title "Supacode ${version} build ${build}" \
  --notes-file "$notes_file" \
  "build/${zip_name}" "build/${zip_name}.sha256"
```

### Step 10 — Verify

```bash
gh release view "v${version}" --repo magimetal/supacode --json assets --jq '.assets[].name'
```

Expected output includes both:

```text
Supacode-{MARKETING_VERSION}-build-{CURRENT_PROJECT_VERSION}-local-unsigned.zip
Supacode-{MARKETING_VERSION}-build-{CURRENT_PROJECT_VERSION}-local-unsigned.zip.sha256
```

## Common Pitfalls

- `make archive` requires signing env vars; use `make build-app` for unsigned local release assets.
- `cp -r` can strip or mishandle macOS bundle metadata; always use `ditto` for `.app` bundles.
- GPG signed commits/tags fail without local GPG configured; use the manual fallback in Step 1.
- Submodule fetch warnings on `git fetch upstream` for `ThirdParty/ghostty` are harmless if you are only syncing release source.
- Asset names must match the historical pattern for downstream consumers.
- Unsigned builds trigger Gatekeeper; document the `xattr -cr /Applications/supacode.app` workaround in release notes.
- Do not attach raw `.app` bundles. Attach the zipped `.app` and matching `.sha256` file.

## Quick Reference

Use this after the version bump has been committed/tagged and pushed.

```bash
set -euo pipefail

repo="magimetal/supacode"

make build-app

settings=$(xcodebuild -workspace supacode.xcworkspace -scheme supacode -configuration Debug -showBuildSettings -json 2>/dev/null)
build_dir=$(echo "$settings" | jq -r '.[0].buildSettings.BUILT_PRODUCTS_DIR')
product=$(echo "$settings" | jq -r '.[0].buildSettings.FULL_PRODUCT_NAME')
app_path="$build_dir/$product"
test -d "$app_path" || { echo "app not found: $app_path"; exit 1; }

version=$(awk -F' = ' '/^MARKETING_VERSION = /{print $2}' Configurations/Project.xcconfig)
build=$(awk -F' = ' '/^CURRENT_PROJECT_VERSION = /{print $2}' Configurations/Project.xcconfig)
zip_name="Supacode-${version}-build-${build}-local-unsigned.zip"

mkdir -p build
ditto -c -k --sequesterRsrc --keepParent "$app_path" "build/$zip_name"
(cd build && shasum -a 256 "$zip_name" > "$zip_name.sha256")

prev_tag=$(gh release view --repo "$repo" --json tagName -q .tagName)
notes_file=$(mktemp)
gh api "repos/${repo}/releases/generate-notes" \
  -f tag_name="v${version}" \
  -f previous_tag_name="$prev_tag" \
  --jq '.body' > "$notes_file"

cat >> "$notes_file" <<'NOTES'

---

Unsigned local build: macOS Gatekeeper may block first launch. After installing to /Applications, run:

```bash
xattr -cr /Applications/supacode.app
```
NOTES

gh release create "v${version}" \
  --repo "$repo" \
  --title "Supacode ${version} build ${build}" \
  --notes-file "$notes_file" \
  "build/${zip_name}" "build/${zip_name}.sha256"

gh release view "v${version}" --repo "$repo" --json assets --jq '.assets[].name'
```

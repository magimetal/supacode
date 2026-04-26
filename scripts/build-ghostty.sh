#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_path="${script_dir}/$(basename "${BASH_SOURCE[0]}")"
srcroot="${SRCROOT:-$(cd "${script_dir}/.." && pwd)}"
repo_root="${srcroot}"
ghostty_dir="${srcroot}/ThirdParty/ghostty"
ghostty_submodule_path="${ghostty_dir#"${repo_root}/"}"
ghostty_build_root="${srcroot}/.build/ghostty"
ghostty_local_cache_dir="${ghostty_build_root}/.zig-cache"
ghostty_global_cache_dir="${ghostty_build_root}/.zig-global-cache"
ghostty_fingerprint_path="${ghostty_build_root}/fingerprint"
ghostty_legacy_prefix_path="${ghostty_dir}/zig-out"
ghostty_legacy_share_path="${ghostty_legacy_prefix_path}/share"
xcframework_path="${ghostty_build_root}/GhosttyKit.xcframework"
ghostty_resources_path="${ghostty_build_root}/share/ghostty"
ghostty_terminfo_path="${ghostty_build_root}/share/terminfo"

print_fingerprint() {
  (
    cd "${ghostty_dir}"
    {
      git rev-parse HEAD
      git diff --no-ext-diff --no-color HEAD -- . | shasum -a 256
      git ls-files --others --exclude-standard | LC_ALL=C sort | shasum -a 256
      shasum -a 256 "${script_path}" | awk '{print $1}'
      shasum -a 256 "${srcroot}/mise.toml" | awk '{print $1}'
    } | shasum -a 256 | awk '{print $1}'
  )
}

prepare_xcframework() {
  local modulemap
  find "${xcframework_path}" -path '*/Headers/module.modulemap' -print0 | while IFS= read -r -d '' modulemap; do
    cat > "${modulemap}" <<'EOF'
module GhosttyKit {
    header "ghostty.h"
    export *
}
EOF
  done
}

find_libghostty_archive() {
  local arch="$1"
  local archive
  local object_dir
  while IFS= read -r archive; do
    if [ "$(lipo -archs "${archive}" 2>/dev/null)" != "${arch}" ]; then
      continue
    fi

    if ! grep -q '_ghostty_app_new' < <(nm -arch "${arch}" -gU "${archive}" 2>/dev/null); then
      continue
    fi

    object_dir="$(mktemp -d)"
    (
      cd "${object_dir}"
      ar -x "${archive}" libghostty_zcu.o
      chmod u+rw libghostty_zcu.o
      vtool -show-build libghostty_zcu.o 2>/dev/null | grep -q 'platform MACOS'
    ) && {
      rm -rf "${object_dir}"
      printf '%s\n' "${archive}"
      return 0
    }
    rm -rf "${object_dir}"
  done < <(find "${ghostty_local_cache_dir}/o" -name libghostty.a -type f | LC_ALL=C sort)

  echo "error: could not find ${arch} macOS libghostty.a containing Ghostty C API symbols" >&2
  return 1
}

create_complete_macos_archive() {
  local arch="$1"
  local output_archive="$2"
  local work_dir="$3"
  local archive
  local archive_dir
  local object
  local archive_index=0

  mkdir -p "${work_dir}"
  while IFS= read -r archive; do
    if [ "$(lipo -archs "${archive}" 2>/dev/null)" != "${arch}" ]; then
      continue
    fi

    archive_dir="${work_dir}/archive-${archive_index}"
    mkdir -p "${archive_dir}"
    (
      cd "${archive_dir}"
      ar -x "${archive}"
      chmod u+rw ./*.o 2>/dev/null || true
      for object in ./*.o; do
        [ -e "${object}" ] || continue
        if vtool -show-build "${object}" 2>/dev/null | grep -q 'platform MACOS'; then
          mv "${object}" "${archive_index}_${object#./}"
        else
          rm -f "${object}"
        fi
      done
    )
    archive_index=$((archive_index + 1))
  done < <(find "${ghostty_local_cache_dir}/o" -name '*.a' -type f | LC_ALL=C sort)

  if ! find "${work_dir}" -name '*.o' -print -quit | grep -q .; then
    echo "error: could not find ${arch} macOS objects for GhosttyKit" >&2
    return 1
  fi

  find "${work_dir}" -name '*.o' -print0 | xargs -0 ar -q "${output_archive}"
  ranlib "${output_archive}"

  if ! grep -q '_ghostty_app_new' < <(nm -arch "${arch}" -gU "${output_archive}" 2>/dev/null); then
    echo "error: rebuilt ${arch} GhosttyKit archive lacks Ghostty C API symbols" >&2
    return 1
  fi
}

repair_macos_xcframework_library() {
  local macos_library="${xcframework_path}/macos-arm64_x86_64/libghostty.a"
  local tmp_dir

  if [ ! -f "${macos_library}" ]; then
    echo "error: missing ${macos_library}" >&2
    return 1
  fi

  find_libghostty_archive arm64 >/dev/null
  find_libghostty_archive x86_64 >/dev/null

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' RETURN

  create_complete_macos_archive arm64 "${tmp_dir}/merged-arm64.a" "${tmp_dir}/arm64"
  create_complete_macos_archive x86_64 "${tmp_dir}/merged-x86_64.a" "${tmp_dir}/x86_64"
  lipo -create "${tmp_dir}/merged-arm64.a" "${tmp_dir}/merged-x86_64.a" -output "${macos_library}"

  if ! grep -q '_ghostty_app_new' < <(nm -arch arm64 -gU "${macos_library}" 2>/dev/null) ||
    ! grep -q '_ghostty_app_new' < <(nm -arch x86_64 -gU "${macos_library}" 2>/dev/null); then
    echo "error: repaired ${macos_library} still lacks Ghostty C API symbols" >&2
    return 1
  fi
}

ensure_ghostty_checkout() {
  if [ -f "${ghostty_dir}/build.zig" ]; then
    return
  fi

  git -C "${repo_root}" submodule sync --recursive -- "${ghostty_submodule_path}"
  git -C "${repo_root}" submodule update --init --recursive -- "${ghostty_submodule_path}"

  if [ ! -f "${ghostty_dir}/build.zig" ]; then
    echo "error: missing ${ghostty_dir} after submodule update" >&2
    exit 1
  fi
}

ensure_ghostty_checkout

if [ "${1:-}" = "--print-fingerprint" ]; then
  print_fingerprint
  exit 0
fi

fingerprint="$(print_fingerprint)"

rm -rf "${ghostty_legacy_prefix_path}"
mkdir -p "${ghostty_build_root}" "${ghostty_legacy_prefix_path}"
ln -s "${ghostty_build_root}/share" "${ghostty_legacy_share_path}"

if [ -f "${ghostty_fingerprint_path}" ] &&
  [ -d "${xcframework_path}" ] &&
  [ -d "${ghostty_resources_path}" ] &&
  [ -d "${ghostty_terminfo_path}" ] &&
  [ "$(cat "${ghostty_fingerprint_path}")" = "${fingerprint}" ]; then
  repair_macos_xcframework_library
  prepare_xcframework
  exit 0
fi

cd "${ghostty_dir}"
mise exec -- zig build -Doptimize=ReleaseFast -Demit-xcframework=true -Demit-macos-app=false -Dsentry=false --prefix "${ghostty_build_root}" --cache-dir "${ghostty_local_cache_dir}" --global-cache-dir "${ghostty_global_cache_dir}"
rsync -a --delete "${ghostty_dir}/macos/GhosttyKit.xcframework/" "${xcframework_path}/"
repair_macos_xcframework_library
prepare_xcframework
printf '%s\n' "${fingerprint}" > "${ghostty_fingerprint_path}"

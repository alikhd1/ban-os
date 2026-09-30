#!/usr/bin/env bash
# Build the Ban OS ISO for one profile and one variant:
# lb clean -> lb config -> lb build.
# Runs on the Debian 13 build VM only. Normally called through `make build`.
#
# Usage: image/scripts/build-image.sh <development|staging|production> <pos|server>
#
# Profile (config/<profile>/) = how the image is locked down (SSH, sudo, channel).
# Variant (image/variants/<variant>/) = what the image is: pos (graphical kiosk
# with Adad) or server (headless, PostgreSQL + Ban services, ban-console).
#
# Environment:
#   BAN_APT_CACHE  apt-cacher-ng (or full mirror) base URL, default http://127.0.0.1:3142

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LB_DIR="${REPO_ROOT}/image/live-build"
OUT_DIR="${REPO_ROOT}/out"

die() {
  echo "build-image: $*" >&2
  exit 1
}

USAGE="usage: $0 <development|staging|production> <pos|server>"

PROFILE="${1:-}"
case "${PROFILE}" in
  development | staging | production) ;;
  *) die "${USAGE}" ;;
esac

VARIANT="${2:-}"
case "${VARIANT}" in
  pos | server) ;;
  *) die "${USAGE}" ;;
esac

PROFILE_DIR="${REPO_ROOT}/config/${PROFILE}"
[[ -f "${PROFILE_DIR}/profile.env" ]] || die "missing ${PROFILE_DIR}/profile.env"

# shellcheck source=/dev/null
source "${PROFILE_DIR}/profile.env"
[[ "${BAN_PROFILE:-}" == "${PROFILE}" ]] ||
  die "${PROFILE_DIR}/profile.env declares BAN_PROFILE='${BAN_PROFILE:-}', expected '${PROFILE}'"

VARIANT_DIR="${REPO_ROOT}/image/variants/${VARIANT}"
[[ -f "${VARIANT_DIR}/variant.env" ]] || die "missing ${VARIANT_DIR}/variant.env"

# shellcheck source=/dev/null
source "${VARIANT_DIR}/variant.env"
[[ "${BAN_VARIANT:-}" == "${VARIANT}" ]] ||
  die "${VARIANT_DIR}/variant.env declares BAN_VARIANT='${BAN_VARIANT:-}', expected '${VARIANT}'"

VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
[[ -n "${VERSION}" ]] || die "VERSION file is empty"

export BAN_APT_CACHE="${BAN_APT_CACHE:-http://127.0.0.1:3142}"

command -v lb > /dev/null || die "live-build is not installed; run scripts/setup-build-vm.sh"
curl --silent --output /dev/null --max-time 5 "${BAN_APT_CACHE}" ||
  die "apt mirror ${BAN_APT_CACHE} is not reachable; is apt-cacher-ng running?"

SUDO=()
if [[ "${EUID}" -ne 0 ]]; then
  SUDO=(sudo)
fi

cd "${LB_DIR}"

echo "==> lb clean"
"${SUDO[@]}" lb clean

echo "==> staging package lists (profile: ${PROFILE}, variant: ${VARIANT})"
rm -rf config/package-lists
mkdir -p config/package-lists
shopt -s nullglob
for list in \
  "${REPO_ROOT}"/image/packages/*.list.chroot \
  "${VARIANT_DIR}"/package-lists/*.list.chroot \
  "${PROFILE_DIR}"/package-lists/*.list.chroot; do
  # Lists from the three sources are merged into one folder; a name clash
  # would silently drop one of them.
  [[ ! -e "config/package-lists/$(basename "${list}")" ]] ||
    die "package list $(basename "${list}") exists in more than one source (${list})"
  cp "${list}" config/package-lists/
done
shopt -u nullglob

echo "==> lb config"
lb config

echo "==> lb build"
"${SUDO[@]}" lb build 2>&1 | tee build.log

ISO_SRC="${LB_DIR}/live-image-amd64.hybrid.iso"
[[ -f "${ISO_SRC}" ]] || die "lb build finished but ${ISO_SRC} does not exist; see ${LB_DIR}/build.log"

ISO_DST="${OUT_DIR}/ban-os-${VERSION}-${PROFILE}-${VARIANT}-amd64.iso"
mkdir -p "${OUT_DIR}"
"${SUDO[@]}" mv "${ISO_SRC}" "${ISO_DST}"
"${SUDO[@]}" chown "$(id -u):$(id -g)" "${ISO_DST}"

echo "==> ${ISO_DST} ($(du -h "${ISO_DST}" | cut -f1))"

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
command -v grub-mkpasswd-pbkdf2 > /dev/null || die "grub-mkpasswd-pbkdf2 is missing; run scripts/setup-build-vm.sh"
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

# Files of the image root, in increasing precedence: common, variant, profile.
# Unlike package lists, a later source may replace a file of an earlier one.
echo "==> staging image files"
INCLUDES=config/includes.chroot_after_packages
rm -rf "${INCLUDES}"
mkdir -p "${INCLUDES}"
for dir in \
  "${REPO_ROOT}/image/configuration" \
  "${VARIANT_DIR}/configuration" \
  "${PROFILE_DIR}/configuration"; do
  if [[ -d "${dir}" ]]; then
    cp -a "${dir}/." "${INCLUDES}/"
  fi
done
rm -f "${INCLUDES}/README.md"

# Repository files of the variant, "<source> <destination>" per line.
if [[ -f "${VARIANT_DIR}/files.list" ]]; then
  while read -r src dst; do
    [[ -z "${src}" || "${src}" == \#* ]] && continue
    [[ -f "${REPO_ROOT}/${src}" ]] || die "${VARIANT_DIR}/files.list: ${src} does not exist"
    mkdir -p "${INCLUDES}$(dirname "${dst}")"
    cp -a "${REPO_ROOT}/${src}" "${INCLUDES}${dst}"
  done < "${VARIANT_DIR}/files.list"
fi

mkdir -p "${INCLUDES}/usr/lib/systemd/system" "${INCLUDES}/usr/lib/systemd/user"
shopt -s nullglob
for unit in "${REPO_ROOT}"/services/systemd/*.{service,timer,mount,target}; do
  [[ "$(basename "${unit}")" == _template.* ]] && continue
  cp "${unit}" "${INCLUDES}/usr/lib/systemd/system/"
done
for unit in "${REPO_ROOT}"/services/systemd/user/*.{service,timer,target}; do
  cp "${unit}" "${INCLUDES}/usr/lib/systemd/user/"
done
shopt -u nullglob

# /etc/ban/release (step 1.3). APP_VERSION arrives with the Adad package
# (Stage 3), HARDWARE_API_VERSION with ban-hardware (Stage 8).
AGENT_API_VERSION="$(sed -n 's/^version = "\(.*\)"/\1/p' "${REPO_ROOT}/crates/ban-api-types/Cargo.toml" | head -n1)"
[[ -n "${AGENT_API_VERSION}" ]] || die "cannot read the version of crates/ban-api-types"
mkdir -p "${INCLUDES}/etc/ban"
cat > "${INCLUDES}/etc/ban/release" << EOF
OS_VERSION=${VERSION}
OS_VARIANT=${VARIANT}
OS_PROFILE=${PROFILE}
OS_BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
AGENT_API_VERSION=${AGENT_API_VERSION}
EOF

# Build variables for the chroot hooks; live-build mounts config/ at
# /live-build/config inside the chroot. Not part of the image.
mkdir -p config/ban
cat "${PROFILE_DIR}/profile.env" "${VARIANT_DIR}/variant.env" > config/ban/build.env
echo "OS_VERSION=${VERSION}" >> config/ban/build.env

# GRUB password of the ISO menu (step 2.1): the known development password,
# or for staging/production a random one that nobody keeps, so the menu of
# those ISOs cannot be edited at all. Only the hash reaches the image.
if [[ "${PROFILE}" == development ]]; then
  [[ -n "${BAN_DEV_GRUB_PASSWORD:-}" ]] || die "BAN_DEV_GRUB_PASSWORD is not set in ${PROFILE_DIR}/profile.env"
  grub_password="${BAN_DEV_GRUB_PASSWORD}"
else
  grub_password="$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9')"
fi
grub_hash="$(printf '%s\n%s\n' "${grub_password}" "${grub_password}" |
  grub-mkpasswd-pbkdf2 | sed -n 's/^.* is \(grub\.pbkdf2\..*\)$/\1/p')"
unset grub_password
[[ -n "${grub_hash}" ]] || die "grub-mkpasswd-pbkdf2 did not return a hash"
echo "BAN_GRUB_PASSWORD_HASH=${grub_hash}" >> config/ban/build.env

echo "==> staging hooks"
mkdir -p config/hooks/normal
rm -f config/hooks/normal/*-ban-*.hook.*
cp "${REPO_ROOT}"/image/scripts/hooks/*.hook.* config/hooks/normal/

echo "==> lb config"
lb config

# The log goes to out/, not into the live-build tree, which live-build and
# auto/clean manage themselves.
BUILD_LOG="${OUT_DIR}/build-${PROFILE}-${VARIANT}.log"
mkdir -p "${OUT_DIR}"
echo "==> lb build (log: ${BUILD_LOG})"
"${SUDO[@]}" lb build 2>&1 | tee "${BUILD_LOG}"

ISO_SRC="${LB_DIR}/live-image-amd64.hybrid.iso"
[[ -f "${ISO_SRC}" ]] || die "lb build finished but ${ISO_SRC} does not exist; see ${BUILD_LOG}"

ISO_DST="${OUT_DIR}/ban-os-${VERSION}-${PROFILE}-${VARIANT}-amd64.iso"
"${SUDO[@]}" mv "${ISO_SRC}" "${ISO_DST}"
"${SUDO[@]}" chown "$(id -u):$(id -g)" "${ISO_DST}"

echo "==> ${ISO_DST} ($(du -h "${ISO_DST}" | cut -f1))"

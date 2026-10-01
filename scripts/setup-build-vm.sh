#!/usr/bin/env bash
# Prepare a Debian 13 (trixie) VM as the Ban OS build machine
# (plan part 1, steps 0.2 and 0.3). Idempotent: safe to run again.
#
# Run as the normal build user (NOT root); the script uses sudo for the
# system-wide parts. rustup, cargo-deb and tauri-cli are installed for the
# calling user.
#
# Usage: scripts/setup-build-vm.sh

set -euo pipefail

APT_CACHE_PORT=3142

IMAGE_PACKAGES=(
  live-build debootstrap squashfs-tools xorriso grub-efi-amd64-bin grub-common
  mtools dosfstools qemu-system-x86 qemu-utils ovmf git make debhelper devscripts
)
DEV_PACKAGES=(
  nodejs npm
  libwebkit2gtk-4.1-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev
  libssl-dev libsqlite3-dev libdbus-1-dev pkg-config
)
# Not listed in the plan but required by it: a C linker for cargo, curl for
# rustup, the apt cache itself, and shellcheck for the shell-script convention.
SUPPORT_PACKAGES=(build-essential curl ca-certificates apt-cacher-ng shellcheck)

info() { echo "==> $*"; }
warn() { echo "WARNING: $*" >&2; }
die() {
  echo "ERROR: $*" >&2
  exit 1
}

check_platform() {
  [[ "${EUID}" -ne 0 ]] || die "run this script as the build user, not as root"

  if ! command -v sudo > /dev/null; then
    die "sudo is missing. As root run: apt install sudo && usermod -aG sudo ${USER}; then log in again"
  fi

  # shellcheck source=/dev/null
  source /etc/os-release
  if [[ "${ID:-}" != "debian" || "${VERSION_CODENAME:-}" != "trixie" ]]; then
    die "this script targets Debian 13 (trixie); found ${PRETTY_NAME:-unknown}"
  fi
  [[ "$(dpkg --print-architecture)" == "amd64" ]] || die "amd64 is required"
}

install_packages() {
  info "Installing apt packages"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    "${IMAGE_PACKAGES[@]}" "${DEV_PACKAGES[@]}" "${SUPPORT_PACKAGES[@]}"
}

check_kvm() {
  if [[ ! -e /dev/kvm ]]; then
    warn "/dev/kvm is missing. Enable nested virtualization for this VM on the hypervisor."
    warn "Without it 'make run-vm' and 'make test-boot' fall back to slow emulation."
    return
  fi
  info "/dev/kvm present"
  if ! id -nG "${USER}" | tr ' ' '\n' | grep -qx kvm; then
    info "Adding ${USER} to the kvm group (log out and in again to apply)"
    sudo usermod -aG kvm "${USER}"
  fi
}

setup_apt_cache() {
  info "Configuring apt-cacher-ng on port ${APT_CACHE_PORT}"
  local conf=/etc/apt-cacher-ng/zz-ban.conf
  if ! sudo test -f "${conf}" || ! sudo grep -qx "Port: ${APT_CACHE_PORT}" "${conf}"; then
    echo "Port: ${APT_CACHE_PORT}" | sudo tee "${conf}" > /dev/null
    sudo systemctl restart apt-cacher-ng
  fi
  sudo systemctl enable --now apt-cacher-ng

  local tries
  for ((tries = 0; tries < 10; tries++)); do
    if curl --silent --output /dev/null --max-time 2 "http://127.0.0.1:${APT_CACHE_PORT}"; then
      info "apt-cacher-ng answers on 127.0.0.1:${APT_CACHE_PORT}"
      return
    fi
    sleep 1
  done
  die "apt-cacher-ng does not answer on 127.0.0.1:${APT_CACHE_PORT}"
}

setup_pnpm() {
  if command -v pnpm > /dev/null; then
    info "pnpm already installed ($(pnpm --version))"
  else
    info "Installing pnpm"
    sudo npm install --global pnpm
  fi
  info "node $(node --version)"
}

setup_rust() {
  export PATH="${HOME}/.cargo/bin:${PATH}"
  # Debian 13 mounts /tmp as a RAM-backed tmpfs (half of RAM). `cargo install`
  # builds there by default and tauri-cli needs more than that, so build on disk.
  local target_dir="${HOME}/.cache/ban-os/cargo-install"
  mkdir -p "${target_dir}"
  if command -v rustup > /dev/null; then
    info "Updating Rust stable"
    rustup toolchain install stable
    rustup default stable
  else
    info "Installing rustup (stable)"
    curl --proto '=https' --tlsv1.2 --silent --show-error --fail https://sh.rustup.rs |
      sh -s -- -y --default-toolchain stable
  fi

  if cargo deb --version > /dev/null 2>&1; then
    info "cargo-deb already installed"
  else
    info "Installing cargo-deb"
    cargo install --locked --target-dir "${target_dir}" cargo-deb
  fi

  if cargo tauri --version > /dev/null 2>&1; then
    info "tauri-cli already installed"
  else
    info "Installing tauri-cli (this takes a while)"
    cargo install --locked --target-dir "${target_dir}" tauri-cli
  fi
}

summary() {
  info "Done."
  echo "    rustc:  $(rustc --version)"
  echo "    lb:     $(lb --version)"
  echo "    qemu:   $(qemu-system-x86_64 --version | head -n1)"
  echo "    cache:  http://127.0.0.1:${APT_CACHE_PORT}"
  echo "Open a new shell (for PATH and group changes), then: make build PROFILE=development"
}

check_platform
install_packages
check_kvm
setup_apt_cache
setup_pnpm
setup_rust
summary

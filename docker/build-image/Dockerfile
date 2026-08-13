# Arisa Build Image
#
# Custom image for the Arisa Arch repository build matrix.
# Pre-installs every base makepkg/paru tool so matrix jobs no longer
# re-install them on every run (GitHub Actions pulls the image layers from
# GHCR instead, saving roughly 20 minutes of wasted CI time per day).
#
# Base: CachyOS v3 container (x86-64-v3 optimised makepkg profile).
# Pinned digest 2026-08-13 (reproducible base). Bump deliberately, e.g.:
#   docker manifest inspect cachyos/cachyos-v3:latest
FROM cachyos/cachyos-v3@sha256:bf6368c8fa289031756e7cb92dd6e6da0a6de6f3fd514b1bbc0d52d5d479aa74

# 1. Sync + install all tools the build job previously installed ad-hoc.
RUN pacman -Syu --noconfirm --needed \
        git subversion mercurial sudo rsync github-cli fakeroot gnupg \
        binutils pacman-contrib ccache paru curl awk tar jq \
    && pacman -Scc --noconfirm

# 2. Create the unprivileged builder user used by makepkg/paru.
RUN id builder >/dev/null 2>&1 || useradd -m builder

# 3. Grant passwordless sudo to builder (same as the old workflow step).
RUN grep -q '^builder ALL=(ALL) NOPASSWD: ALL$' /etc/sudoers \
    || echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# 4. Make pacman a little more CI-friendly inside the container.
RUN sed -i '/^\[options\]/a DisableSandboxNetwork' /etc/pacman.conf
# Arisa Build Image
#
# Custom image for the Arisa Arch repository build matrix.
# Pre-installs every base makepkg/paru tool so matrix jobs no longer
# re-install them on every run (GitHub Actions pulls the image layers from
# GHCR instead, saving roughly 20 minutes of wasted CI time per day).
#
# Base: CachyOS v3 container (x86-64-v3 optimised makepkg profile).
# Pinned digest 2026-08-13 (reproducible base). update-image.yml checks the
# upstream digest on a daily schedule and opens a bump PR when it changes.
# Bump deliberately, e.g.:
#   docker manifest inspect cachyos/cachyos-v3:latest
FROM cachyos/cachyos-v3@sha256:17dbb9c1013efe6caaa77b91eadd7ef6fb024c2031c96f9d0e0f1ac417a76325

# Build config baked into the image (previously downloaded from
# raw.githubusercontent.com at job runtime). Sources: CachyOS/docker-makepkg
# @ 9b0259d9 — see the header comments in the files. PKGDEST/LOGDEST/
# PACKAGECARCH are pre-commented so built packages land in the workspace
# build dir and are tagged arch x86_64 for the [arisa] repository.
COPY makepkg.conf /etc/makepkg.conf
COPY rust.conf /etc/makepkg.conf.d/rust.conf

# 1. Sync + install all tools the build job previously installed ad-hoc.
#    Full -Syu keeps the daily base snapshot fully upgraded (Arch forbids
#    partial upgrades), then the package cache is dropped to keep the image
#    lean. pacman preserves the modified /etc/makepkg.conf (writes a
#    .pacnew) when it ships its own copy.
RUN pacman -Syu --noconfirm --needed \
        git subversion mercurial sudo rsync github-cli fakeroot gnupg \
        binutils pacman-contrib ccache paru curl awk tar jq \
    && pacman -Scc --noconfirm

# 2. Create the unprivileged builder user used by makepkg/paru.
RUN id builder >/dev/null 2>&1 || useradd -m builder

# 3. Grant passwordless sudo to builder (same as the old workflow step).
RUN grep -q '^builder ALL=(ALL) NOPASSWD: ALL$' /etc/sudoers \
    || echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# 4. Make pacman a little more CI-friendly inside the container. Kept only
#    here (the prepare-env action used to duplicate this) — idempotent so
#    rebuilds on newer bases never insert it twice.
RUN if ! grep -q '^DisableSandboxNetwork' /etc/pacman.conf; then \
        sed -i '/^\[options\]/a DisableSandboxNetwork' /etc/pacman.conf; \
    fi

# 5. Stable locale for reproducible builds.
ENV LANG=C.UTF-8
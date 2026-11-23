# SPDX-License-Identifier: ISC
#
# Builds libkaihen's pacman package in devkitPro's image, against libounce's
# released package. From the repository's top folder:
#   docker build -f packaging/Dockerfile --build-arg VERSION=20261118 --output out .
# writes out/libkaihen-20261118-1-any.pkg.tar.zst. The release workflow
# publishes it with kaiHEN's zip.
FROM docker.io/devkitpro/devkita64:20260219 AS build

ARG VERSION
# The libounce release that libkaihen builds against.
ARG LIBOUNCE_VERSION=20261123
# The commit time, so that the package's file times do not depend on the
# build.
ARG SOURCE_DATE_EPOCH=0

# makepkg packages with fakeroot and zstd, and does not run as root.
RUN apt-get update && \
    apt-get install -y --no-install-recommends fakeroot zstd curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# libounce's package, checked against the SHA-256 of its release.
RUN release="https://github.com/ouncebrew/libounce/releases/download/$LIBOUNCE_VERSION" && \
    package="libounce-$LIBOUNCE_VERSION-1-any.pkg.tar.zst" && \
    cd /tmp && \
    curl -fsSLO "$release/$package" && \
    curl -fsSL "$release/$package.sha256" | sha256sum -c && \
    dkp-pacman -U --noconfirm "$package" && \
    rm "$package"

# Everything builds under /build, which the debug information names.
RUN useradd --create-home --home-dir /build/builder builder && \
    mkdir -p /build/makepkg /build/out && chown builder /build/makepkg /build/out
COPY --chown=builder . /build/kaihen
USER builder
WORKDIR /build/kaihen/packaging
RUN test -n "$VERSION" && \
    LIBKAIHEN_VERSION="$VERSION" SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
    BUILDDIR=/build/makepkg PKGDEST=/build/out PACKAGER=ouncebrew \
    dkp-makepkg --nodeps --noconfirm

FROM scratch
COPY --from=build /build/out/ /

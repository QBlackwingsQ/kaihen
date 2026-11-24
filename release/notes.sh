#!/bin/sh
# SPDX-License-Identifier: ISC
#
# Prints the notes of a kaiHEN release: the annotated tag's message, then the
# zip's layout, the sources that the Dockerfile pins and the zip's SHA-256.
# PACKAGES is `dkp-pacman -Q libounce ouncevk libkaihen` in the build image.
#   sh release/notes.sh VERSION ZIP PACKAGES
set -eu

version="${1:?usage: notes.sh VERSION ZIP PACKAGES}"
zip="${2:?usage: notes.sh VERSION ZIP PACKAGES}"
packages="${3:?usage: notes.sh VERSION ZIP PACKAGES}"
top=$(cd "$(dirname "$0")/.." && pwd)

# The installed version of a devkit package.
installed() {
    sed -n "s/^$1 //p" "$packages"
}
devkit="libounce $(installed libounce), OunceVK $(installed ouncevk) and libkaihen $(installed libkaihen)"

# The value of an ARG in the Dockerfile.
pin() {
    sed -n "s/^ARG $1=//p" "$top/Dockerfile"
}

if [ "$(git -C "$top" cat-file -t "refs/tags/$version" 2> /dev/null)" = tag ]; then
    git -C "$top" tag -l --format='%(contents)' "$version"
    echo
fi

cat <<NOTES
**Warning:** this is still a work in progress, and might have bugs. kaiHEN allows full access to the system, including the system NAND. A malicious homebrew might write to your Switch 2 and brick it forever.

**Known issue:** files whose names have non-ASCII characters (accents, Japanese, emoji) do not show in folder listings, in OunceShell or over FTP. They can still be opened, downloaded and deleted by name.

**If a program does not start,** the menu shows a number for the reason:

- \`2346-0200\`: the program needs shared libraries and this kaiHEN is older than they are. Update kaiHEN.
- \`2346-0201\`: a shared library that the program needs is not on the SD card. Copy \`sdcard/\` of this zip to the SD card's root.
- \`2346-0202\`, \`2346-0203\`, \`2346-0204\`: a shared library on the SD card does not fit the program: it is older or newer than the one the program was built with. Copy \`sdcard/\` of this zip again, or update the program.
- \`2346-0205\`: a library in \`sdmc:/kaihen/preload\` could not be loaded. Remove it.

kaiHEN-$version.zip layout:

- \`sdcard/\`: copy its contents to the SD card's root. The acquisition tool copies this folder for you.
  - \`hbmenu.nro\`
  - \`kaihen/bin/hen/main\` (kaiHEN) and \`kaihen/bin/game/main\` (nx-hbloader)
  - \`kaihen/lib/\`: the shared libraries of dynamically linked programs: \`libounce.so.1\`, \`libstdc++.so.6\`, Vulkan (\`libouncevk.so.1\`), OpenGL (\`libouncevk-gl.so.1\`), and \`libvulkan.so.1\`, \`libEGL.so.1\`, \`libGLESv2.so.2\` and \`libGL.so.1\` for programs that load those names. nx-hbloader looks for a program's libraries in the program's folder and then in \`sdmc:/kaihen/lib\`.
  - \`switch/ounceshell.nro\`: OunceShell
- \`ro/main\`, \`bootstrap.bin\`: the acquisition tool reads these itself; they do not go on the SD card.
- \`licenses/\`: the licenses of everything above

Built with \`docker build --build-arg RELEASE=1 --output out .\` at this tag, in ounce-devkit's image with $devkit from the [ounce] repository.

\`libkaihen-$version-1-any.pkg.tar.zst\`: libkaihen (\`kaihen.h\`, \`-lkaihen\`, \`-lkaihen_plugin\`) for devkitPro's pacman, built with \`packaging/Dockerfile\`. It is also in the [ounce] repository at https://pkg.ouncebrew.org.

## Source

- kaiHEN: this repository at this tag.
- nx-hbloader: [ouncebrew/ounce-hbloader](https://github.com/ouncebrew/ounce-hbloader) at \`$(pin HBLOADER_COMMIT)\`.
- nx-hbmenu: [ouncebrew/ounce-hbmenu](https://github.com/ouncebrew/ounce-hbmenu) at \`$(pin HBMENU_COMMIT)\`.
- OunceShell (GPL-3.0-or-later): [kurumuz/ounceshell](https://github.com/kurumuz/ounceshell) at \`$(pin OUNCESHELL_COMMIT)\`, built with its \`switch2/Makefile\`. Its FTP server is [mtheall/ftpd](https://github.com/mtheall/ftpd) v2.3.1 (public domain), modified.
- \`libstdc++.so.6\` (GPL-3.0-or-later with the GCC Runtime Library Exception): GCC's C++ library as devkitA64 builds it, linked as a shared library by libounce's package. Its source is devkitPro's [buildscripts](https://github.com/devkitPro/buildscripts) for the devkitA64 release of the build image.
- $devkit: the packages of [ouncebrew/libounce](https://github.com/ouncebrew/libounce), [ouncebrew/ouncevk](https://github.com/ouncebrew/ouncevk) and this repository's releases of those versions.
- The devkitPro portlibs linked into hbmenu and OunceShell, from devkitPro's packages: libconfig 1.7.2, freetype 2.13.3, harfbuzz 10.0.1, libjpeg-turbo 2.1.2, libpng 1.6.48, bzip2 1.0.8, zlib 1.3.1, physfs 3.2.0, SDL2 2.28.5, SDL2_ttf 2.22.0, SDL2_image 2.0.4, libwebp 1.0.2, libarchive 3.7.2, expat 2.2.5, lz4 1.9.3, zstd 1.5.7, liblzma 5.8.2, libvorbis 1.3.7, libogg 1.3.4, Oniguruma 6.9.2.

SHA-256: $(sha256sum "$zip" | cut -d' ' -f1)
NOTES

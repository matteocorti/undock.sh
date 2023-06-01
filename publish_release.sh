#!/bin/sh

VERSION=$(grep '^VERSION' undock.sh | sed 's/.*=//')

echo "Version ${VERSION}"
echo 'Did you update the RELEASE_NOTES.md? '
echo '------------------------------------------------------------------------------'
cat RELEASE_NOTES.md
echo '------------------------------------------------------------------------------'
read -r ANSWER
if [ "${ANSWER}" = "y" ]; then

    make &&
        gh release create "v${VERSION}" --title "undock.sh-${VERSION}" --notes-file RELEASE_NOTES.md "undock.sh-${VERSION}.tar.gz" "undock.sh-${VERSION}.tar.bz2"

fi

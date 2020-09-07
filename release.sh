#!/bin/bash
set -e
# Build the script
make test
make docs
# Get current version number
rm -f gxadmin
make gxadmin
CURRENT_VERSION=$(./gxadmin --version)
NEW_VERSION=$(( CURRENT_VERSION + 1 ))
NEXT_VERSION=$(( CURRENT_VERSION + 2 ))
echo $CURRENT_VERSION $NEW_VERSION
# Update version number in changelog
sed -i "s/# ${NEW_VERSION}-pre/# ${NEXT_VERSION}-pre\n\n# ${NEW_VERSION}/g" CHANGELOG.md
# Update version number in gxadmin
sed -i "s/echo ${CURRENT_VERSION}/echo ${NEW_VERSION}/" parts/00-header.sh
# Fetch changelog
release_body=$(mktemp)
sed -n "/# ${NEW_VERSION}/,/# ${CURRENT_VERSION}/{/# ${CURRENT_VERSION}/b;p}" CHANGELOG.md > $release_body

make test
make docs
make gxadmin

git add parts/00-header.sh CHANGELOG.md
git commit -a -m "Release v${NEW_VERSION}"
git tag v${NEW_VERSION}

echo "Ok, release built. Please open a new terminal and confirm! Then come back here and hit enter, to proceed with uploading + release publishing"
read garbage

git push --follow-tags
ghr v${NEW_VERSION} gxadmin -b "$(cat $release_body)"

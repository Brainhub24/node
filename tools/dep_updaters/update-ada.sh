#!/bin/sh
set -e
# Shell script to update ada in the source tree to a specific version

BASE_DIR=$(cd "$(dirname "$0")/../.." && pwd)
DEPS_DIR="$BASE_DIR/deps"
[ -z "$NODE" ] && NODE="$BASE_DIR/out/Release/node"
[ -x "$NODE" ] || NODE=$(command -v node)

NEW_VERSION="$("$NODE" --input-type=module <<'EOF'
const res = await fetch('https://api.github.com/repos/ada-url/ada/releases/latest');
if (!res.ok) throw new Error(`FetchError: ${res.status} ${res.statusText}`, { cause: res });
const { tag_name } = await res.json();
console.log(tag_name.replace('v', ''));
EOF
)"

CURRENT_VERSION=$(grep "#define ADA_VERSION" "$DEPS_DIR/ada/ada.h" | sed -n "s/^.*VERSION \"\(.*\)\"/\1/p")

echo "Comparing $NEW_VERSION with $CURRENT_VERSION"

if [ "$NEW_VERSION" = "$CURRENT_VERSION" ]; then
  echo "Skipped because ada is on the latest version."
  exit 0
fi

echo "Making temporary workspace..."

WORKSPACE=$(mktemp -d 2> /dev/null || mktemp -d -t 'tmp')

cleanup () {
  EXIT_CODE=$?
  [ -d "$WORKSPACE" ] && rm -rf "$WORKSPACE"
  exit $EXIT_CODE
}

trap cleanup INT TERM EXIT

ADA_REF="v$NEW_VERSION"
ADA_ZIP="ada-$NEW_VERSION.zip"
ADA_LICENSE="LICENSE-MIT"

cd "$WORKSPACE"

echo "Fetching ada source archive..."
curl -sL -o "$ADA_ZIP" "https://github.com/ada-url/ada/releases/download/$ADA_REF/singleheader.zip"
unzip "$ADA_ZIP"
rm "$ADA_ZIP"

curl -sL -o "$ADA_LICENSE" "https://raw.githubusercontent.com/ada-url/ada/HEAD/LICENSE-MIT"

echo "Replacing existing ada (except GYP build files)"
mv "$DEPS_DIR/ada/"*.gyp "$DEPS_DIR/ada/README.md" "$WORKSPACE/"
rm -rf "$DEPS_DIR/ada"
mv "$WORKSPACE" "$DEPS_DIR/ada"

echo "All done!"
echo ""
echo "Please git add ada, commit the new version:"
echo ""
echo "$ git add -A deps/ada"
echo "$ git commit -m \"deps: update ada to $NEW_VERSION\""
echo ""

# The last line of the script should always print the new version,
# as we need to add it to $GITHUB_ENV variable.
echo "NEW_VERSION=$NEW_VERSION"

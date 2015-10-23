#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Usage: create_mapbox_package.sh https://api.your.mapserver.com [mapbox branch name] [require API key: true or false (default)]"
    exit 1
fi

api_url=$1
branch="master"
require_api_key="false"

if [ $# -eq 2 ]
  then
    branch=$2
fi

if [ $# -eq 3 ]
  then
  	shopt -s nocasematch
	if [ "$3" != "true" ] && [ "$3" != "false" ]
	then
  		echo "Wrong argument \"$3\" for API key usage. Requiring either true or false."
  		exit 1
  	fi
	shopt -u nocasematch
fi

# Helper method to replace a line in the config file (sed -i doesn't work on OS X the easy way)
function escape_slashes {
    sed 's/\//\\\//g' 
}

function change_line {
    local OLD_LINE_PATTERN=$1; shift
    local NEW_LINE=$1; shift
    local FILE=$1

    local NEW=$(echo "${NEW_LINE}" | escape_slashes)
    sed -i .bak '/'"${OLD_LINE_PATTERN}"'/s/.*/'"${NEW}"'/' "${FILE}"
    mv "${FILE}.bak" /tmp/
}

# Make sure the script is executed from the project dir
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $dir

# cleanup first
rm -rf mapbox-gl-js
rm -rf mapbox_package
rm -rf mapbox-gl-styles

# Fetch mapbox-gl-js
git clone -b $branch https://github.com/mapbox/mapbox-gl-js.git
pushd mapbox-gl-js
git submodule update --init --recursive

# We change the mapbox-g-js default config: 
# disable requiring an API key, set specified API host URL
change_line "API_URL" "    API_URL: '$api_url'," js/util/config.js
change_line "REQUIRE_ACCESS_TOKEN" "    REQUIRE_ACCESS_TOKEN: $require_api_key" js/util/config.js

# build mapbox-gl-js
npm install

popd # mapbox-gl-js

# Fetch prebuilt styles
git clone https://github.com/mapbox/mapbox-gl-styles.git
# Create sprites for each style
pushd mapbox-gl-styles/sprites
styles="$(find . -maxdepth 1 -type d | awk -F/ '{print $NF}')"
for style in $styles
do
	if [ "$style" != "." ]
	then
		echo "Creating sprites for $style..."
		$(cd $style && spritezero sprite _svg)
		$(cd $style && spritezero --retina sprite@2x _svg)
	fi
done
popd # mapbox-gl-styles/sprites

# Copy all scripts and assets into mapbox_package to allow to statically reference this folder
mkdir mapbox_package
cp -r mapbox-gl-js/dist/* mapbox_package
mkdir -p mapbox_package/styles/v1/mapbox
cp -r mapbox-gl-styles/styles/* mapbox_package/styles/v1/mapbox
cp -r mapbox-gl-styles/sprites/* mapbox_package/styles/v1/mapbox
# Delete original images, we just need the sprites
find mapbox_package/styles -name _svg -type d -exec rm -rf {} \; 2> /dev/null
# fontstack Open Sans Semibold,Arial Unicode MS Bold
mkdir -p mapbox_package/fonts/v1/mapbox
cp -r mapbox-gl-js/node_modules/mapbox-gl-test-suite/glyphs/* mapbox_package/fonts/v1/mapbox

# sources for static files:
# https://github.com/mapbox/mapbox-gl-native/blob/ddc4a8193e775d9cd9280ad7d9bb6975b4a323ee/ios/benchmark/assets/tiles/mapbox.mapbox-terrain-v2%2Cmapbox.mapbox-streets-v6.json
cp -r static/* mapbox_package

# fonts
# https://github.com/mapbox/mapbox-gl-native/blob/ddc4a8193e775d9cd9280ad7d9bb6975b4a323ee/ios/benchmark/assets/glyphs/download.sh
DRAFT

# mapbox-gl-js-packager
Package mapbox-gl-js to enable hosting it on your own server

Pre requirements:
spritezero

git clone https://github.com/mapbox/spritezero-cli.git
cd spritezero-cli
sudo npm install -g spritezero-cli

Usage:
./create_mapbox_package.sh "https://your.vector.tileserver.com" MapBoxGitBranch RequireAPIKey

Example:
./create_mapbox_package.sh "https://api.mapbox.com" "v0.11.1" true

You will find a folder mapbox_package. This folder contains all required and generated assets.
The contents of this must be copied to the root of the URL you provided. 

...

License
See https://github.com/mapbox/mapbox-gl-js/blob/master/LICENSE.txt

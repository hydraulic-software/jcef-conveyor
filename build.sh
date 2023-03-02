#!/usr/bin/env bash

# Run Maven to build the app, then ensure Conveyor has the files it needs and then build the site.
#
# This targets Conveyor 7.

set -e

mvn package

jcef_version=110.0.25
jcef_hash=87476e9
chromium_version=110.0.5481.78
chromium_hash=g75b1c96

natives_dir=target/jcef-natives

mkdir -p "$natives_dir"
pushd "$natives_dir" >/dev/null

function gen_filename_root() {
  echo "jcef-natives-$1-jcef-$jcef_hash+cef-$jcef_version+$chromium_hash+chromium-$chromium_version"
}

function dl_jcef_mac_natives() {
  filename_root=$( gen_filename_root $1 )
  jar="$filename_root.jar"
  tarball="$filename_root.tar.gz"
  if [ -d "$1" ]; then
    # Nothing to do
    return
  fi

  # JCEF wraps the files we need in a tarball inside a JAR. Conveyor isn't smart enough to undo that just with config so we do it here.
  # Also we have to modify the contents to work around bugs, so we extract the tarball and patch it up.
  echo
  echo "> Download jcef natives for $1"
  echo
  wget "https://github.com/jcefmaven/jcefmaven/releases/download/$jcef_version/$jar"
  jar xf "$jar"
  rm -r "$jar" me META-INF
  mkdir "$1"
  pushd "$1" >/dev/null
  tar xzf "../$tarball"
  rm "../$tarball"

  # The "Chromium Embedded Framework.framework" doesn't follow the normal layout for a framework that Apple's tools make,
  # and current Conveyors don't like it, so we fix it up here to be a versioned framework.  (CO-354)
  files=( "Chromium Embedded Framework.framework/"* )
  mkdir -p "Chromium Embedded Framework.framework/Versions/$jcef_version"
  for f in "${files[@]}"; do
    mv "$f" "Chromium Embedded Framework.framework/Versions/$jcef_version"
  done
  pushd "Chromium Embedded Framework.framework/Versions" >/dev/null
  ln -s -s "$jcef_version" Current
  # Get rid of the signature from the developer.
  rm -r Current/_CodeSignature
  # Fix up the plist (CO-355)
  plutil -insert CFBundleName -string "org.cef.framework" Current/Resources/Info.plist
  popd >/dev/null

  # The helper app comes pre-notarized but this is wrong (it's nonsensical to notarize a framework helper) and Conveyor doesn't correctly
  # strip it. We could drop it with a remap spec but it's easier to just delete the errant file here.  (CO-353)
  for app in *.app; do
    rm -f "$app/Contents/CodeResources"
  done

  popd
}

dl_jcef_mac_natives macosx-amd64
dl_jcef_mac_natives macosx-arm64

popd >/dev/null

extra_keys="-Ktemp.jcef.mac.amd64=$natives_dir/macosx-amd64 -Ktemp.jcef.mac.aarch64=$natives_dir/macosx-arm64"

conveyor $@ $extra_keys make notarized-mac-app

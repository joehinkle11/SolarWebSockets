#!/bin/bash -e

path=$(dirname "$0")

OUTPUT_DIR=$1
TARGET_NAME=plugin_library
OUTPUT_SUFFIX=a
CONFIG=Release

#
# Checks exit value for error
#
checkError() {
	if [ $? -ne 0 ]
	then
		echo "Exiting due to errors (above)"
		exit -1
	fi
}

#
# Canonicalize relative paths to absolute paths
#
pushd "$path" > /dev/null
dir=$(pwd)
path=$dir
popd > /dev/null

if [ -z "$OUTPUT_DIR" ]
then
	OUTPUT_DIR=.
fi

pushd "$OUTPUT_DIR" > /dev/null
dir=$(pwd)
OUTPUT_DIR=$dir
popd > /dev/null

echo "OUTPUT_DIR: $OUTPUT_DIR"

# Clean
xcodebuild -project "$path/Plugin.xcodeproj" -configuration $CONFIG clean
checkError

# iOS
xcodebuild -project "$path/Plugin.xcodeproj" -configuration $CONFIG -sdk iphoneos
checkError

# iOS-sim
xcodebuild -project "$path/Plugin.xcodeproj" -configuration $CONFIG -sdk iphonesimulator
checkError

# create universal binary
lipo -create "$path"/build/$CONFIG-iphoneos/lib$TARGET_NAME.$OUTPUT_SUFFIX "$path"/build/$CONFIG-iphonesimulator/lib$TARGET_NAME.$OUTPUT_SUFFIX -output "$OUTPUT_DIR"/lib$TARGET_NAME.$OUTPUT_SUFFIX
checkError


# copy corona plugin structure

build_plugin_structure() {

	PLUGIN_DEST=$1
	mkdir -p "$PLUGIN_DEST"
	PLATFORM=$2
	ARCH=$3

	cp "$path/build/$CONFIG-$PLATFORM/lib$TARGET_NAME.$OUTPUT_SUFFIX" "$PLUGIN_DEST/"
	cp "$path"/metadata.lua "$PLUGIN_DEST/"

	if ls "$path/build/$CONFIG-$PLATFORM/"*.framework 1> /dev/null 2>&1; then
		echo "Copying bult frameworks for $PLATFORM"
		mkdir -p "$PLUGIN_DEST"/resources/Frameworks
		"$(xcrun -f rsync)"  --exclude _CodeSignature --exclude .DS_Store --exclude CVS --exclude .svn --exclude .git --exclude .hg --exclude Headers --exclude PrivateHeaders --exclude Modules -resolve-src-symlinks "$path/build/$CONFIG-$PLATFORM"/*.framework  "$PLUGIN_DEST"/resources/Frameworks
	else
		echo "No built frameworks"
	fi


	if ls "$path"/EmbeddedFrameworks/*.framework 1> /dev/null 2>&1; then
		echo "Copying Embedded frameworks frameworks for $PLATFORM:"

		for f in "$path"/EmbeddedFrameworks/*.framework; do
			FRAMEWORK_NAME=$(basename "$f")
			BIN_NAME=${FRAMEWORK_NAME%.framework}
			SRC_BIN="$f"/$BIN_NAME

			if [[ $(file "$SRC_BIN" | grep -c "ar archive") -ne 0 ]]; then
				echo " - $FRAMEWORK_NAME: is a static Framework, extracting."

				DEST_BIN="$PLUGIN_DEST"/$FRAMEWORK_NAME/$BIN_NAME
				"$(xcrun -f rsync)" --links --exclude '*.xcconfig' --exclude _CodeSignature --exclude .DS_Store --exclude CVS --exclude .svn --exclude .git --exclude .hg --exclude Headers --exclude PrivateHeaders --exclude Modules -resolve-src-symlinks "$f"  "$PLUGIN_DEST"
				rm "$DEST_BIN"
				lipo "$SRC_BIN" $ARCH -o "$DEST_BIN.tmp"
				$(xcrun -f bitcode_strip) "$DEST_BIN.tmp" -r -o "$DEST_BIN"
				rm "$DEST_BIN.tmp"
				rm -rf "$PLUGIN_DEST/$FRAMEWORK_NAME/Versions"
			else
				echo " + $FRAMEWORK_NAME: embedding"

				mkdir -p "$PLUGIN_DEST"/resources/Frameworks
				DEST_BIN="$PLUGIN_DEST"/resources/Frameworks/$FRAMEWORK_NAME/$BIN_NAME
				"$(xcrun -f rsync)" --links --exclude '*.xcconfig' --exclude _CodeSignature --exclude .DS_Store --exclude CVS --exclude .svn --exclude .git --exclude .hg --exclude Headers --exclude PrivateHeaders --exclude Modules -resolve-src-symlinks "$f"  "$PLUGIN_DEST"/resources/Frameworks
				rm "$DEST_BIN"
				lipo "$SRC_BIN" $ARCH -o "$DEST_BIN.tmp"
				$(xcrun -f bitcode_strip) "$DEST_BIN.tmp" -r -o "$DEST_BIN"
				rm "$DEST_BIN.tmp"
				rm -rf "$PLUGIN_DEST/$FRAMEWORK_NAME/Versions"
			fi
		done
	else
		echo "No 3rd party frameworks"
	fi
}



build_plugin_structure "$OUTPUT_DIR/BuiltPlugin/iphone" iphoneos  " -extract armv7 -extract  arm64 "

build_plugin_structure "$OUTPUT_DIR/BuiltPlugin/iphone-sim" iphonesimulator  " -extract i386  -extract  x86_64 "




echo "$OUTPUT_DIR"/lib$TARGET_NAME.$OUTPUT_SUFFIX

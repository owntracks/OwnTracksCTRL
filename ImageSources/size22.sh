#!/bin/bash

INK=/Applications/Inkscape.app/Contents/Resources/bin/inkscape
IMAGEW=imagew

if [[ -z "$1" ]] 
then
	echo "SVG file needed."
	exit;
fi

BASE=`basename "$1" .svg`
SVG="$1"
MYPWD=`pwd`

# need to use absolute paths in OSX

$INK -z -C -e "$MYPWD/$BASE-22.png" -f 		$MYPWD/$SVG -w 22 -h 22
$INK -z -C -e "$MYPWD/$BASE-22@2x.png" -f 	$MYPWD/$SVG -w 44 -h 44
$INK -z -C -e "$MYPWD/$BASE-22@3x.png" -f 	$MYPWD/$SVG -w 66 -h 66
$IMAGEW "$MYPWD/$BASE-22.png" "$MYPWD/$BASE-22-noalpha.png"
$IMAGEW "$MYPWD/$BASE-22@2x.png" "$MYPWD/$BASE-22-noalpha@2x.png"
$IMAGEW "$MYPWD/$BASE-22@3x.png" "$MYPWD/$BASE-22-noalpha@3x.png"

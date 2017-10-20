#!/bin/sh
#
#
#
# TODO: ensure app store images converted to png

function usage() {
cat << EOF
NAME
    $(basename "$0") -- generate app icons and app sets for xcode

USAGE
    $(basename "$0") [-paulwmv] source_image output_path

DESCRIPTION
    This script uses ImageMagick to resize an image into all of the 
    required sizes for iPhone, iPad, Universal, iWatch and iMessage 
    applications. By default everything is generated except for 
    iMessage.
    
    -p    Generate iPhone assets
    -a    Generate iPad assets
    -u    Generate universal assets
    -l    Generate iOS 6.1 and below icons
    -w    Generate iWatch assets
    -m    Generate iMessage assets

    -s    Skip the creation of AppIcon.appiconset containers
    -v    Be verbose when generating the assets, listing each item.

EOF
}

# usage
optional_arg="/AppIcon/"
verbose=0

while getopts 'paulwmsv' option; do
  case "$option" in
    f) echo "f"
       ;;
    b) echo "b"
       ;;
    :) echo "missing argument for -%s\n" "$OPTARG" >&2
       # usage >&2
       exit 1
       ;;
    *) usage 
       exit 1
       ;;
  esac
done

echo "$2"

exit 0

function generate_icons(){
    local range proto port
    for fields in ${connections[@]}
    do
            IFS=$'|' read -r range proto port <<< "$fields"
            echo "$range" 
            echo "$proto" 
            echo "$port"
            convert "$base" -resize 29x29!     "Icon-Small.png"
    done
}

generate_icons

exit 0;
# watchos

# Check imagemagick command is available
command -v convert >/dev/null 2>&1 || { echo >&2 "ImageMagick is required to run this script"; exit -1; }

base=$1

test -z $base && echo "Must pass an image name." 1>&2 && exit 1

dimension_string=`identify -ping -format "%wx%h" "$base"`
IFS='x' read -r -a dimensions <<< "$dimension_string"
# //`identify -ping -format "%wx%h" "$base"`

#  Check image file
if [ ${dimensions[0]} -ne ${dimensions[1]} ]; then
  echo "Image dimensions are not equal: ${dimension_string}"
  exit -1
elif [ `identify -format '%[channels]' "$base"` -eq "rgba" ]; then
  echo "Image contains an alpha channel."
elif [ ${dimensions[0]} -lt 1024 ]; then
  echo "Warning! Currrent image size of ${dimension_string} will be upscaled."
fi


exit 0
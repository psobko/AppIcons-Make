#!/bin/sh

# TODO: ensure app store images converted to png if src is not

function usage() {
cat << EOF
NAME
    $(basename "$0") -- generate app icons and app sets for xcode

USAGE
    $(basename "$0") source_image output_path

DESCRIPTION
    This script uses ImageMagick to resize an image into all of the 
    required sizes for iPhone, iPad, Universal, and iWatch applications. 

EOF
}
echo "---------------"
# Check imagemagick command is available
command -v convert >/dev/null 2>&1 || { echo >&2 "ImageMagick is required to run this script"; exit -1; }

base=$1
output_path=${2:-AppIcon}
current_path=""

# Check arguments
test -z $base && echo "Must pass an image name." 1>&2 && exit 1

# Check image file
dimension_string=`identify -ping -format "%wx%h" "$base"`
IFS='x' read -r -a dimensions <<< "$dimension_string"

if [ ${dimensions[0]} -ne ${dimensions[1]} ]; then
  echo "Image dimensions are not equal: ${dimension_string}"
  exit -1
elif [ `identify -format '%[channels]' "$base"` == "rgba" ]; then
  echo "Image contains an alpha channel."
elif [ ${dimensions[0]} -lt 1024 ]; then
  echo "Warning! Currrent image size of ${dimension_string} will be upscaled."
fi

# As of January 30 2016
# https://developer.apple.com/library/content/qa/qa1686/_index.html

readonly appstore=(
  '512x512|iTunesArtwork' # App list in iTunes
  '1024x1024|iTunesArtwork@2x' #App list in iTunes on devices with retina display
  )

readonly iphone=(
  '120x120|Icon-60@2x.png' # Home screen on iPhone/iPod Touch with retina display
  '180x180|Icon-60@3x.png' # Home screen on iPhone with retina HD display
  '76x76|Icon-76.png' # Home screen on iPad
  '152x152|Icon-76@2x.png' # Home screen on iPad with retina display
  '167x167|Icon-83.5@2x.png' # Home screen on iPad Pro
  '40x40|Icon-Small-40.png' # Spotlight
  '80x80|Icon-Small-40@2x.png' # Spotlight on devices with retina display
  '120x120|Icon-Small-40@3x.png' # Spotlight on devices with retina HD display
  '29x29|Icon-Small.png' # Settings
  '58x58|Icon-Small@2x.png' # Settings on devices with retina display
  '87x87|Icon-Small@3x.png' # Settings on devices with retina HD display
)

readonly iphone_legacy=(
  '57x57|Icon.png' # Home screen on iPhone/iPod touch (iOS 6.1 and earlier)
  '114x114|Icon@2x.png' # Home screen on iPhone/iPod Touch with retina display (iOS 6.1 and earlier)
  '72x72|Icon-72.png' # Home screen on iPad (iOS 6.1 and earlier)
  '144x144|Icon-72@2x.png' # Home screen on iPad with retina display (iOS 6.1 and earlier)
  '29x29|Icon-Small.png' # Spotlight on iPhone/iPod Touch (iOS 6.1 and earlier), and Settings on all devices
  '58x58|Icon-Small@2x.png' # Spotlight on iPhone/iPod Touch with retina display (iOS 6.1 and earlier), and Settings on all devices with retina display
  '50x50|Icon-Small-50.png' # Spotlight on iPad (iOS 6.1 and earlier)
  '100x100|Icon-Small-50@2x.png' # Spotlight on iPad with retina display (iOS 6.1 and earlier)
)

readonly ipad=(
  '76x76|Icon-76.png' # Home screen on iPad
  '152x152|Icon-76@2x.png' # Home screen on iPad with retina display
  '167x167|Icon-83.5@2x.png' # Home screen on iPad Pro
  '40x40|Icon-Small-40.png' # Spotlight
  '80x80|Icon-Small-40@2x.png' # Spotlight on devices with retina display
  '29x29|Icon-Small.png' # Settings
  '58x58|Icon-Small@2x.png' # Settings on devices with retina display
)

readonly ipad_legacy=(
  '72x72|Icon-72.png' # Home screen on iPad (iOS 6.1 and earlier)
  '144x144|Icon-72@2x.png' # Home screen on iPad with retina display (iOS 6.1 and earlier)
  '50x50|Icon-Small-50.png' # Spotlight on iPad (iOS 6.1 and earlier)
  '100x100|Icon-Small-50@2x.png' # Spotlight on iPad with retina display (iOS 6.1 and earlier)
)

readonly ios_universal=(
  '120x120|Icon-60@2x.png' # Home screen on iPhone/iPod Touch with retina display
  '180x180|Icon-60@3x.png' # Home screen on iPhone with retina HD display
  '76x76|Icon-76.png' # Home screen on iPad
  '152x152|Icon-76@2x.png' # Home screen on iPad with retina display
  '167x167|Icon-83.5@2x.png' # Home screen on iPad Pro
  '40x40|Icon-Small-40.png' # Spotlight
  '80x80|Icon-Small-40@2x.png' # Spotlight on devices with retina display
  '120x120|Icon-Small-40@3x.png' # Spotlight on devices with retina HD display
  '29x29|Icon-Small.png' # Settings
  '58x58|Icon-Small@2x.png' # Settings on devices with retina display
  '87x87|Icon-Small@3x.png' # Settings on devices with retina HD display
)

readonly iwatch=(
  '80x80|AppIcon40x40@2x.png' # Home screen on Apple Watch (38mm/42mm), Long-Look notification on Apple Watch (38mm)
  '88x88|AppIcon44x44@2x.png' # Long-Look notification on Apple Watch (42mm)
  '172x172|AppIcon86x86@2x.png' # Short-Look notification on Apple Watch (38mm)
  '196x196|AppIcon98x98@2x.png' # Short-Look notification on Apple Watch (42mm)
  '48x48|AppIcon24x24@2x.png' # Notification center on Apple Watch (38mm)
  '55x55|AppIcon27.5x27.5@2x.png' # Notification center on Apple Watch (42mm)
  '58x58|AppIcon29x29@2x.png' # Settings in the Apple Watch companion app on iPhone
  '87x87|AppIcon29x29@3x.png' # Settings in the Apple Watch companion app on iPhone 6 Plus
)

# readonly imessage=(
#   '1024x768|Messages1024x768.png' # Messages App Store
#   '120x90|Messages60x45@2x.png' # Messages app drawer on iPhone/iPod Touch with retina display
#   '180x135|Messages60x45@3x.png' # Messages app drawer on iPhone with retina HD display
#   '134x100|Messages67x50@2x.png' # Messages app drawer on iPad with retina display
#   '148x110|Messages74x55@2x.png' # Messages app drawer on iPad Pro
#   '54x40|Messages27x20@2x.png' # Breadcrumb icons in the chat transcript on devices with retina display.
#   '81x60|Messages27x20@3x.png' # Breadcrumb icons in the chat transcript on iPhone with retina HD display
#   '64x48|Messages32x24@2x.png' # Messages app management screen, message bubble branding on devices with retina display
#   '96x72|Messages32x24@3x.png' # Messages app management screen, message bubble branding on iPhone with retina HD display
# )

# # Create the dir if it doesn't exist
# `mkdir -p "${output_path}"`

# Generate the icons

function generate_icons(){
  `mkdir -p "${output_path}/${current_path}"`
    local image_size file_name arr
    arr=("$@")
    for fields in "${arr[@]}"
    do
            IFS=$'|' read -r image_size file_name <<< "$fields"
            convert "$base" -resize "$image_size"! "${output_path}/${current_path}/${file_name}" 
    done
}

current_path="appstore"
generate_icons "${appstore[@]}"

current_path="iphone"
generate_icons "${iphone[@]}"

current_path="iphone_legacy"
generate_icons "${iphone_legacy[@]}"

current_path="ipad"
generate_icons "${ipad[@]}"

current_path="ipad_legacy"
generate_icons "${ipad_legacy[@]}"

current_path="ios_universal"
generate_icons "${ios_universal[@]}"

current_path="iwatch"
generate_icons "${iwatch[@]}"

#TODO: add non-legacy icons to appiconset
#TODO: create assets json

exit 0
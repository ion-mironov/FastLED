#!/bin/bash
set -e

compile() {
    pio run
}

# Function to insert the header
insert_header() {
    local file="$1"
    # Remove any existing include of _exports.hpp
    sed -i '/#include "platforms\/stub\/wasm\/_exports.hpp"/d' "$file"
    # Add the include at the beginning of the file
    sed -i '1i#include "_exports.hpp"' "$file"
    echo "Processed: $file"
}

# Copy the contents of the hosts mapped directory to the container
mkdir -p /js/src
cp -r /mapped/* /js/src



# If there is an ino file in the src directory, then rename it to main.cpp. Add
# a special case if there already is a main.cpp file, in this case we will
# rename it to main2.hpp, then generate the main.cpp file and then include the main2.hpp
# file in the main.cpp file.
if [ -f /js/src/*.ino ]; then
    # Check if main.cpp already exists
    if [ -f /js/src/main.cpp ]; then
        # special case, main.cpp exists, so we want to rename it to main2.hpp
        mv /js/src/main.cpp /js/src/main2.hpp
    fi
    mv /js/src/*.ino /js/src/main.cpp
    # If main2.hpp exists (because it was renamed, then append it to main.cpp)
    if [ -f /js/src/main2.hpp ]; then
        # the main2.hpp file was created, so include it.
        echo '#include "main2.hpp"' >> /js/src/main.cpp
    fi
fi




# Remove the .pio directory copy, if it exists because this could contain build
# artifacts from a previous build
rm -rf /js/.pio
cp -r /wasm/* /js/
cd /js


# Find all .ino, .h, .hpp, and .cpp files recursively and process them
find src -type f \( -name "*.ino" -o -name "*.h" -o -name "*.hpp" -o -name "*.cpp" \) | while read -r file; do
    insert_header "$file"
done




# copy _header.hpp to the src directory
cp /js/_exports.hpp /js/src/_exports.hpp
cp /js/message_queue.h /js/src/message_queue.h
cp /js/_timer.hpp /js/src/_timer.hpp


#############################################
compile
#############################################


# Ensure the directory exists
mkdir -p /mapped/fastled_js

# Copy (overwrite if exists) the files
cp -f ./.pio/build/*/fastled.js /mapped/fastled_js/fastled.js
cp -f ./.pio/build/*/fastled.wasm /mapped/fastled_js/fastled.wasm
cp -f ./index.html /mapped/fastled_js/index.html

# now open the files and write them a second time just to be safe
cat ./.pio/build/*/fastled.js > /mapped/fastled_js/fastled.js
cat ./.pio/build/*/fastled.wasm > /mapped/fastled_js/fastled.wasm
cat ./index.html > /mapped/fastled_js/index.html


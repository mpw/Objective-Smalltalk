#!/bin/sh

source ~/Library/Android/GNUstep/arm64-v8a/share/GNUstep/Makefiles/GNUstep.sh
export SDK=/Users/marcel/programming/Examples/Android/Android-from-Scratch/android_sdk
export CC="$SDK/ndk/26.2.11394342/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android33-clang"



make $1

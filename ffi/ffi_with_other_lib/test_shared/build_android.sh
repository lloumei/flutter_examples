#! /usr/bin/env bash

# 参考：
# https://developer.android.com/ndk/guides/cmake?hl=zh-cn
# https://juejin.cn/post/6844904070352732173

set -e

SOURCE_DIR=`realpath .`
OUTPUT_DIR=$SOURCE_DIR/output/android
BUILD_DIR=$SOURCE_DIR/build/android

if [[ -d "$OUTPUT_DIR" ]]; then
  rm -rf $OUTPUT_DIR
fi

if [[ -d "$BUILD_DIR" ]]; then
  rm -rf $BUILD_DIR
fi

mkdir -p $OUTPUT_DIR
mkdir -p $BUILD_DIR

ALL_ABIS="armeabi-v7a arm64-v8a x86 x86_64"

TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/$NDK_PLATFORM
TARGET=
API=21

create_makefile() {
    local abi=$1
    cmake \
        -DANDROID_ABI=$abi \
        -DANDROID_PLATFORM=android-$API \
        -DCMAKE_BUILD_TYPE=release \
        -DANDROID_NDK=$ANDROID_NDK \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
        -DANDROID_TOOLCHAIN=clang -B $BUILD_DIR -S .
}

function collect_header {

    local abi=$1
    local target_dir=$OUTPUT_DIR/jniLibs/$abi

    mkdir -p ${target_dir}
    mkdir -p ${target_dir}/include

    cp $SOURCE_DIR/*.h ${target_dir}/include
}

for ABI in $ALL_ABIS
do
    create_makefile $ABI
    cd $BUILD_DIR
    make clean
    make 
    collect_header $ABI
    cd -
done
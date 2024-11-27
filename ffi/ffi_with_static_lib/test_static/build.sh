#! /usr/bin/env bash

set -e

OUTPUT_DIR=./output

if [[ -d "$OUTPUT_DIR" ]]; then
  rm -rf $OUTPUT_DIR
fi

mkdir $OUTPUT_DIR
cd $OUTPUT_DIR

ALL_ARCH="arm64 x86_64"
ALL_SDK="iphoneos iphonesimulator"

for ARCH in $ALL_ARCH
do

  for SDK in $ALL_SDK
  do

      if [[ "$ARCH" = "x86_64" && "$SDK" = "iphoneos" ]]; then
        continue
      fi

      mkdir -p $ARCH-$SDK
      cd $ARCH-$SDK

      OUTPUT_NAME="libtest_static.a"
      OS_VERSION=
      if [[ "$SDK" = "iphonesimulator" ]]; then
        OS_VERSION="-mios-simulator-version-min=12.0"
      else
        OS_VERSION="-miphoneos-version-min=12.0"
      fi

      export CC="xcrun -sdk $SDK clang -arch $ARCH -fembed-bitcode $OS_VERSION"

      echo "ARCH=$ARCH"
      echo "SDK=$SDK"
      echo "OUTPUT_NAME=$OUTPUT_NAME"
      echo "OS_VERSION=$OS_VERSION"
      echo "CC=$CC"

      $CC -c ../../test_static.c
      ar -rv $OUTPUT_NAME test_static.o

      cd -
  done

done

mkdir ./iphonesimulator
lipo -create \
  ./arm64-iphonesimulator/libtest_static.a \
  ./x86_64-iphonesimulator/libtest_static.a \
  -output ./iphonesimulator/libtest_static.a
lipo -info ./iphonesimulator/libtest_static.a

xcodebuild -create-xcframework \
  -output libtest_static.xcframework \
  -library ./arm64-iphoneos/libtest_static.a \
  -headers ../test_static.h \
  -library ./iphonesimulator/libtest_static.a \
  -headers ../test_static.h

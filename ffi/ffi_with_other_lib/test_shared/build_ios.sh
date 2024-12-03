#! /usr/bin/env bash

# 注意：
# IOS不支持动态库，但是编译和打包成xcframework是可以的，就是不能引入工程。
# 参考：
# https://rhonabwy.com/2023/02/10/creating-an-xcframework/

set -e

SOURCE_DIR=`realpath .`
OUTPUT_DIR=$SOURCE_DIR/output/ios

if [[ -d "$OUTPUT_DIR" ]]; then
  rm -rf $OUTPUT_DIR
fi

mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

ALL_ARCH="arm64 x86_64"
ALL_SDK="iphoneos iphonesimulator"

for ARCH in $ALL_ARCH
do

  for SDK in $ALL_SDK
  do

      # iphoneos是没有x86_64架构的，所以这里要跳过，否则会报找不到架构的错误
      if [[ "$ARCH" = "x86_64" && "$SDK" = "iphoneos" ]]; then
        continue
      fi

      mkdir -p $OUTPUT_DIR/$ARCH-$SDK
      cd $OUTPUT_DIR/$ARCH-$SDK

      OUTPUT_NAME="libtest_shared.dylib"
      OS_VERSION=
      if [[ "$SDK" = "iphonesimulator" ]]; then
        # 注意iphonesimulator必须搭配-mios-simulator-version-min属性，否则编译出来的库在虚拟机上运行会报错
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

      $CC -c $SOURCE_DIR/test_shared.c
      $CC -o $OUTPUT_NAME -dynamiclib -fPIC test_shared.o

      cd -
  done

done

mkdir $OUTPUT_DIR/iphonesimulator

# 使用lipo命令将不同架构的库文件整合成单个库文件
# 注意lipo命令只能对相同sdk不同架构的库文件进行进行整合，例如下面两个静态库文件的sdk都是iphonesimulator
lipo -create \
  $OUTPUT_DIR/arm64-iphonesimulator/libtest_shared.dylib \
  $OUTPUT_DIR/x86_64-iphonesimulator/libtest_shared.dylib \
  -output $OUTPUT_DIR/iphonesimulator/libtest_shared.dylib
lipo -info $OUTPUT_DIR/iphonesimulator/libtest_shared.dylib

xcodebuild -create-xcframework \
  -output $OUTPUT_DIR/libtest_shared.xcframework \
  -library $OUTPUT_DIR/arm64-iphoneos/libtest_shared.dylib \
  -headers $SOURCE_DIR/test_shared.h \
  -library $OUTPUT_DIR/iphonesimulator/libtest_shared.dylib \
  -headers $SOURCE_DIR/test_shared.h

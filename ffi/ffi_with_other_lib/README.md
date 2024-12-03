## 编译测试静态库和动态库

正式开始测试前，我们先要准备测试所需的静态库和动态库文件。在这里，我准备了两个简单的测试C语言工程：

* test_static
* test_shared

测试工程中仅包含一个c文件和一个头文件，以及两个编译脚本，分别用来构建Android平台和IOS平台的库文件。

### 准备编译环境

由于需要同时测试Android和IOS两个平台，我使用了苹果电脑来作为开发机器，电脑CPU为M2。

电脑需要安装好Xcode，以及Android开发相关的SDK和NDK，在这里NDK选择了r19c版本。

### 开始编译

编译Android的测试静态库：

```bash
cd test_static
export ANDROID_NDK=/your/android/ndk/path
export NDK_PLATFORM=darwin-x86_64
./build_android.sh  
```

编译Android的测试动态库：

```bash
cd test_shared
export ANDROID_NDK=/your/android/ndk/path
export NDK_PLATFORM=darwin-x86_64
./build_android.sh
```

编译IOS的测试静态库：

```bash
cd test_static
./build_ios.sh  
```

## 工程引用库文件

编译好测试静态库和动态库后，需要将库文件引入到工程中。

### Android工程引用

将 test_static 和 test_shared 文件夹下的 output/android/jniLibs 文件夹合并复制到 android/src/main/jniLibs ，文件结构如下：

```
jniLibs
├── arm64-v8a
│   ├── include
│   │   ├── test_shared.h
│   │   └── test_static.h
│   ├── libtest_shared.so
│   └── libtest_static.a
├── armeabi-v7a
│   ├── include
│   │   ├── test_shared.h
│   │   └── test_static.h
│   ├── libtest_shared.so
│   └── libtest_static.a
├── x86
│   ├── include
│   │   ├── test_shared.h
│   │   └── test_static.h
│   ├── libtest_shared.so
│   └── libtest_static.a
└── x86_64
    ├── include
    │   ├── test_shared.h
    │   └── test_static.h
    ├── libtest_shared.so
    └── libtest_static.a
```

回到根目录下的 src 文件夹，编辑 CMakeLists.txt 文件，添加库文件依赖：

```cmake

include_directories(${CMAKE_SOURCE_DIR}/../android/src/main/jniLibs/${ANDROID_ABI}/include)

add_library(libtest_shared SHARED IMPORTED)
set_target_properties(libtest_shared PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/../android/src/main/jniLibs/${ANDROID_ABI}/libtest_shared.so)

add_library(libtest_static STATIC IMPORTED)
set_target_properties(libtest_static PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/../android/src/main/jniLibs/${ANDROID_ABI}/libtest_static.a)

target_link_libraries(
  test_ffi
  ${LIB-LOG}
  libtest_shared
  libtest_static
)

```

这个 CMakeLists.txt 只有Android工程使用到，所以不做区分平台的操作。

### IOS工程引用

将 test_static 文件夹下的 output/ios/libtest_static.xcframework 复制到 ios/Frameworks/libtest_static.xcframework ，如果 Frameworks 文件夹不存在就创建一个。

编辑 ios 文件夹下的 .podspec 文件：

```podspec
s.vendored_frameworks = [
'Frameworks/libtest_static.xcframework'
]
```

## 使用库文件方法

创建ffi工程的时候，src文件夹下默认自带一个c文件和头文件，我们以这两个文件为入口，添加自己的方法实现。

修改头文件，添加方法声明：

```c
FFI_PLUGIN_EXPORT const char * platform();

FFI_PLUGIN_EXPORT int min(int a, int b);

FFI_PLUGIN_EXPORT int max(int a, int b);
```

然后修改c文件，添加方法的实现：

```c
#include "test_static.h"

#if defined(ANDROID) || defined(_ANDROID_)
#include "test_shared.h"
#endif

FFI_PLUGIN_EXPORT const char * platform() {
#if defined(ANDROID) || defined(_ANDROID_)
  return "ANDROID";
#elif defined(__APPLE__) || defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
  return "IOS";
#else
  return "OTHER";
#endif
}

FFI_PLUGIN_EXPORT int min(int a, int b) {
#if defined(ANDROID) || defined(_ANDROID_)
  return test_shared_min(a, b);
#else
  return -1;
#endif
}

FFI_PLUGIN_EXPORT int max(int a, int b) {
  return test_static_max(a, b);
}

```

由于IOS不支持动态库引用，所以上面的c文件需要使用宏判断平台来决定是否使用测试动态库。

### 使用ffigen生成Dart代码

在Mac中使用ffigen生成Dart代码时会有很多警告，导致代码生成失败：

```
warning: pointer is missing a nullability type specifier (_Nonnull, _Nullable, or _Null_unspecified) [Nullability Issue]
```

所以我们需要修改一下工程根目录下的 ffigen.yaml 文件，目的是禁用上面的警告：

```yaml
compiler-opts:
  - "-Wno-nullability-completeness"   # 在苹果系统编译会报错：https://juejin.cn/post/6934524023342628877
```

然后用以下命令来生成代码：

```bash
dart run ffigen --config ffigen.yaml
```

### 在Dart中使用原生库功能

最后我们在Dart中就可以使用测试静态库和动态库的方法了：

```dart
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'test_ffi_bindings_generated.dart';

const String _libName = 'test_ffi';

/// The dynamic library in which the symbols for [TestFfiBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    // DynamicLibrary.open('libtest_shared.so');
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final TestFfiBindings _bindings = TestFfiBindings(_dylib);

String platform() {
  Pointer<Char> p = _bindings.platform();
  return p.cast<Utf8>().toDartString();
}

int min(int a, int b) => _bindings.min(a, b);

int max(int a, int b) => _bindings.max(a, b);

```

## 参考

* [How to use GoLang in Flutter Application - Golang FFI](https://dev.to/leehack/how-to-use-golang-in-flutter-application-golang-ffi-1950)
* [Using FFI on Flutter Plugins to run native Rust code](https://medium.com/flutter-community/using-ffi-on-flutter-plugins-to-run-native-rust-code-d64c0f14f9c2)
* [The Architecture Mismatch Dilemma in iOS: Solving the ‘Could Not Find Module *** for Target x86_64-apple-ios-simulator’ Issue on Apple Silicon](https://medium.com/@magdy.zamel/the-architecture-mismatch-dilemma-b72adf2db374)
* [Using dart:ffi with a xcframework containing static binaries (iOS)](https://github.com/dart-lang/native/issues/934)
* [Simulator ARM64 Support for Static Libraries in M1 Machines](https://forums.developer.apple.com/forums/thread/673387)
* [Both ios-arm64-simulator and ios-x86_64-simulator represent two equivalent library definitions](https://developer.apple.com/forums/thread/666335?answerId=685927022#685927022)
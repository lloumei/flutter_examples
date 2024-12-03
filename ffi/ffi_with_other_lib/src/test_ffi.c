#include "test_ffi.h"
#include "test_static.h"

#if defined(ANDROID) || defined(_ANDROID_)
#include "test_shared.h"
#endif

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT int sum(int a, int b) { return a + b; }

// A longer-lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT int sum_long_running(int a, int b) {
  // Simulate work.
#if _WIN32
  Sleep(5000);
#else
  usleep(5000 * 1000);
#endif
  return a + b;
}

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

# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(test_ffi_library VERSION 0.0.1 LANGUAGES C)

add_library(test_ffi SHARED
  "test_ffi.c"
)

set_target_properties(test_ffi PROPERTIES
  PUBLIC_HEADER test_ffi.h
  OUTPUT_NAME "test_ffi"
)

target_compile_definitions(test_ffi PUBLIC DART_SHARED_LIB)

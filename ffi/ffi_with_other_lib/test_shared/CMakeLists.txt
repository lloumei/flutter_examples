cmake_minimum_required(VERSION 3.10)

project(test_shared_library VERSION 0.0.1 LANGUAGES C)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/output/android/jniLibs/${ANDROID_ABI})

add_library(test_shared SHARED
  "test_shared.c"
)

set_target_properties(test_shared PROPERTIES
  PUBLIC_HEADER test_shared.h
  OUTPUT_NAME "test_shared"
)


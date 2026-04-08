# This file controls Flutter-level build steps.
cmake_minimum_required(VERSION 3.13)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# Serves the same purpose as list(TRANSFORM ... PREPEND ...) for CMake < 3.12.
function(list_prepend LIST_NAME PREFIX)
    set(NEW_LIST "")
    foreach(element ${${LIST_NAME}})
        list(APPEND NEW_LIST "${PREFIX}${element}")
    endforeach(element)
    set(${LIST_NAME} "${NEW_LIST}" PARENT_SCOPE)
endfunction()

# === Flutter Library ===
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}/cpp_client_wrapper/include"
  "${EPHEMERAL_DIR}/include"
  "${CMAKE_SOURCE_DIR}"
)
set_target_properties(flutter PROPERTIES
  INTERFACE_COMPILE_OPTIONS ""
)
target_link_libraries(flutter INTERFACE "${EPHEMERAL_DIR}/libflutter_linux_gtk.so")
add_dependencies(flutter flutter_assemble)

# === Flutter tool backend ===
add_custom_target(flutter_assemble DEPENDS
  "${EPHEMERAL_DIR}/libflutter_linux_gtk.so"
  "${EPHEMERAL_DIR}/icudtl.dat"
  "${EPHEMERAL_DIR}/cpp_client_wrapper/include/flutter/dart_project.h"
)
add_custom_command(
  OUTPUT
    "${EPHEMERAL_DIR}/libflutter_linux_gtk.so"
    "${EPHEMERAL_DIR}/icudtl.dat"
    "${EPHEMERAL_DIR}/cpp_client_wrapper/include/flutter/dart_project.h"
  COMMAND ${CMAKE_COMMAND} -E env
    "FLUTTER_ROOT=${FLUTTER_ROOT}"
    "PROJECT_DIR=${CMAKE_SOURCE_DIR}/.."
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
    linux-x64 ${CMAKE_BUILD_TYPE}
  VERBATIM
)

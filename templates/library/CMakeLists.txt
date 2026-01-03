cmake_minimum_required(VERSION 3.25.0)

# Enable optimized variable evaluation
if(POLICY CMP0053)
    cmake_policy(SET CMP0053 NEW)
endif()

# Enable global GENERATED property
if(POLICY CMP0118)
    cmake_policy(SET CMP0118 NEW)
endif()

# Log active toolchain
message(STATUS "Using toolchain file: ${CMAKE_TOOLCHAIN_FILE}")

# PROJECT #
project("library" LANGUAGES CXX C ASM)

# Debugging variables:
#set(CMAKE_MESSAGE_LOG_LEVEL VERBOSE) # Log target info
#set(CMAKE_VERBOSE_MAKEFILE ON) # Log actual commands run when building
#set(CMAKE_FIND_DEBUG_MODE ON) # Log debugging info for find commands

# Set the default search path for modules when using include / find_package
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake")

# Examples root contains devkitpro config package
set(devkitpro_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/devkitpro")
find_package(devkitpro CONFIG REQUIRED)

# Global Compiler Flags
set(warning_flags "-Winline" "-Wall" "-Wextra")
set(cpp_flags "-fno-rtti" "-fno-exceptions")
set(debug_flags "-g" "-O0")
set(minSizeRel_flags "-g" "-Oz")
set(release_flags "-O3" "-fomit-frame-pointer" "-ffast-math")
set(releaseWithDebInfo_flags "-g" ${release_flags})
add_compile_options(
    ${warning_flags}
    "$<$<COMPILE_LANGUAGE:CXX>:${cpp_flags}>"
    "$<$<CONFIG:Debug>:${debug_flags}>"
    "$<$<CONFIG:MinSizeRel>:${minSizeRel_flags}>"
    "$<$<CONFIG:Release>:${release_flags}>"
    "$<$<CONFIG:RelWithDebInfo>:${releaseWithDebInfo_flags}>"
)
add_link_options(
    ${warning_flags}
    "$<$<COMPILE_LANGUAGE:CXX>:${cpp_flags}>"
    "$<$<CONFIG:Debug>:${debug_flags}>"
    "$<$<CONFIG:MinSizeRel>:${minSizeRel_flags}>"
    "$<$<CONFIG:Release>:${release_flags}>"
    "$<$<CONFIG:RelWithDebInfo>:${releaseWithDebInfo_flags}>"
)

# SOURCE #
add_library("${PROJECT_NAME}" STATIC
    "source/templatelib.c"
)
target_include_directories("${PROJECT_NAME}"
    PRIVATE "include"
)
dkp_target_generate_symbol_table("${PROJECT_NAME}")

target_link_libraries("${PROJECT_NAME}"
    PRIVATE "dkp::gamecube"
)

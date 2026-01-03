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
cmake_path(GET CMAKE_CURRENT_SOURCE_DIR FILENAME PROJECT_NAME)
project(${PROJECT_NAME} LANGUAGES CXX C ASM)

# Debugging variables:
#set(CMAKE_MESSAGE_LOG_LEVEL VERBOSE) # Log target info
#set(CMAKE_VERBOSE_MAKEFILE ON) # Log actual commands run when building
#set(CMAKE_FIND_DEBUG_MODE ON) # Log debugging info for find commands

# Set the default search path for modules when using include / find_package
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../../cmake")

# Examples root contains devkitpro config package
set(devkitpro_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../cmake/devkitpro")
find_package(devkitpro CONFIG REQUIRED COMPONENTS libogc elf2dol)

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
add_executable(source_executable
    "source/triangle.c"
)
dkp_target_generate_symbol_table(source_executable)

target_link_libraries(source_executable
    PRIVATE "$<$<CONFIG:Debug,RelWithDebInfo>:dkp::libogc::gamecube::db>" # Note: db library must be linked first (see https://wiibrew.org/wiki/Debugging)
    PRIVATE "dkp::gamecube"
    PRIVATE "dkp::libogc::gamecube::ogc"
    PRIVATE "m"
)

# elf2dol - .dol executable
dkp_add_elf2dol("${PROJECT_NAME}_dol" "${PROJECT_NAME}.dol" $<TARGET_FILE:source_executable> TRUE)


# ==========================================
#   Copyright (c) 2016-2021 dynamic_static
#     Patrick Purcell
#       Licensed under the MIT license
#     http://opensource.org/licenses/MIT
# ==========================================

include_guard()

include(CheckCxxCompilerFlag)
include(CmakeParseArguments)
include(ExternalProject)
include(FetchContent)

# TODO : Documentation
function(dst_create_file_group files)
    set_property(GLOBAL PROPERTY USE_FOLDERS ON)
    foreach(file ${files})
        string(REPLACE "${PROJECT_SOURCE_DIR}" "" groupName "${directory}")
        string(REPLACE "${CMAKE_SOURCE_DIR}" "" groupName "${groupName}")
        if(MSVC)
            string(REPLACE "/" "\\" groupName "${groupName}")
        endif()
        source_group("${groupName}" FILES "${file}")
    endforeach()
endfunction()

# TODO : Documentation
function(dst_setup_target_folders)
    cmake_parse_arguments(args "" "target;folder" "files" ${ARGN})
    dst_create_file_group("${args_files}")
    if(args_folder)
        set_target_properties(${args_target} PROPERTIES FOLDER ${args_folder})
    else()
        set_target_properties(${args_target} PROPERTIES FOLDER ${args_target})
    endif()
endfunction()

# TODO : Documentation
function(dst_setup_target)
    cmake_parse_arguments(args "" "target;folder" "includeDirectories;includeFiles;sourceFiles;linkLibraries;compileDefinitions" ${ARGN})
    target_include_directories(${args_target} PUBLIC "${args_includeDirectories}")
    target_compile_definitions(${args_target} PUBLIC "${args_compileDefinitions}")
    target_link_libraries(${args_target} PUBLIC "${args_linkLibraries}")
    set_target_properties(${args_target} PROPERTIES LINKER_LANGUAGE CXX)
    dst_setup_target_folders(target ${args_target} folder ${args_folder} files "${args_includeFiles}" "${args_sourceFiles}")
endfunction()

# TODO : Documentation
function(dst_add_executable)
    cmake_parse_arguments(args "" "target" "includeFiles;sourceFiles;compileDefinitions" ${ARGN})
    add_executable(${args_target} "${args_includeFiles}" "${args_sourceFiles}")
    dst_setup_target(${ARGN})
endfunction()

# TODO : Documentation
function(dst_add_interface_library)
    cmake_parse_arguments(args "" "target;folder" "includeDirectories;includeFiles;linkLibraries;compileDefinitions" ${ARGN})
    add_library(${args_target} INTERFACE "${args_includeFiles}")
    target_include_directories(${args_target} INTERFACE "${args_includeDirectories}")
    target_compile_definitions(${args_target} INTERFACE "${args_compileDefinitions}")
    target_link_libraries(${args_target} INTERFACE "${args_linkLibraries}")
    set_target_properties(${args_target} PROPERTIES LINKER_LANGUAGE CXX)
    dst_setup_target_folders(target ${args_target} folder ${args_folder} files "${args_includeFiles}")
endfunction()

# TODO : Documentation
function(dst_add_shared_library)
    cmake_parse_arguments(args "" "target" "includeFiles;sourceFiles;compileDefinitions" ${ARGN})
    add_library(${args_target} SHARED "${args_includeFiles}" "${args_sourceFiles}")
    dst_setup_target(${ARGN})
endfunction()

# TODO : Documentation
function(dst_add_static_library)
    cmake_parse_arguments(args "" "target" "includeFiles;sourceFiles;compileDefinitions" ${ARGN})
    add_library(${args_target} STATIC "${args_includeFiles}" "${args_sourceFiles}")
    dst_setup_target(${ARGN})
endfunction()

# TODO : Documentation
function(dst_add_target_test_suite)
    cmake_parse_arguments(args "" "target" "includeDirectories;includeFiles;sourceFiles;compileDefinitions" ${ARGN})
    FetchContent_Declare(Catch2 GIT_REPOSITORY "https://github.com/catchorg/Catch2.git" GIT_TAG v2.13.6 GIT_PROGRESS TRUE)
    FetchContent_MakeAvailable(Catch2)
    FetchContent_GetProperties(Catch2 BINARY_DIR catchBinaryDirectory)
    set(catchCpp "${catchBinaryDirectory}/catch.cpp")
    if(NOT EXISTS ${catchCpp})
        file(WRITE "${catchCpp}" "\n#define CATCH_CONFIG_MAIN\n#include \"catch2/catch.hpp\"\n")
    endif()
    dst_add_executable(
        target ${args_target}.tests
        folder ${args_target}
        linkLibraries ${args_target} Catch2
        includeDirectories "${args_includeDirectories}"
        includeFiles "${args_includeFiles}"
        sourceFiles "${args_sourceFiles}" "${catchCpp}"
    )
    enable_testing()
    add_test(NAME ${args_target}.tests COMMAND ${args_target}.tests)
endfunction()

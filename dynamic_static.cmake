
# ==========================================
#   Copyright (c) 2016-2020 Dynamic_Static
#     Patrick Purcell
#       Licensed under the MIT license
#     http://opensource.org/licenses/MIT
# ==========================================

include_guard()

include(CheckCxxCompilerFlag)
include(CmakeParseArguments)
include(ExternalProject)

# TODO : Documentation
function(dst_create_file_group files)
    set_property(GLOBAL PROPERTY USE_FOLDERS ON)
    foreach(file ${files})
        get_filename_component(directory "${file}" DIRECTORY)
        string(REPLACE "${PROJECT_SOURCE_DIR}" "" groupName "${directory}")
        string(REPLACE "${CMAKE_SOURCE_DIR}" "" groupName "${groupName}")
        if(MSVC)
            string(REPLACE "/" "\\" groupName "${groupName}")
        endif()
        source_group("${groupName}" FILES "${file}")
    endforeach()
endfunction()

# TODO : Documentation
function(dst_setup_target)
    cmake_parse_arguments(args "" "target;folder" "includeDirectories;includeFiles;sourceFiles;linkLibraries;compileDefinitions" ${ARGN})
    target_include_directories(${args_target} "${args_includeDirectories}")
    target_link_libraries(${args_target} "${args_linkLibraries}")
    target_compile_definitions(${args_target} "${args_compileDefinitions}")
    set_target_properties(${args_target} PROPERTIES LINKER_LANGUAGE CXX)
    target_compile_features(${args_target} PUBLIC cxx_std_17)
    dst_create_file_group("${args_includeFiles}")
    dst_create_file_group("${args_sourceFiles}")
    if(args_folder)
        set_target_properties(${args_target} PROPERTIES FOLDER ${args_folder})
    else()
        set_target_properties(${args_target} PROPERTIES FOLDER ${args_target})
    endif()
endfunction()

# TODO : Documentation
function(dst_add_executable)
    cmake_parse_arguments(args "" "target" "includeFiles;sourceFiles;compileDefinitions" ${ARGN})
    add_executable(${args_target} "${args_includeFiles}" "${args_sourceFiles}")
    dst_setup_target(${ARGN})
endfunction()

# TODO : Documentation
function(dst_add_interface_library)
    cmake_parse_arguments(args "" "target" "includeFiles;sourceFiles;compileDefinitions" ${ARGN})
    add_library(${args_target} INTERFACE "${args_includeFiles}" "${args_sourceFiles}")
    dst_setup_target(${ARGN})
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


# ==========================================
#   Copyright (c) 2016-2020 Dynamic_Static
#     Patrick Purcell
#       Licensed under the MIT license
#     http://opensource.org/licenses/MIT
# ==========================================

message("Pre include_guard() : ${CMAKE_CURRENT_LIST_DIR}")

include_guard()

message("Post include_guard() : ${CMAKE_CURRENT_LIST_DIR}")

include(CheckCxxCompilerFlag)
include(CmakeParseArguments)
include(ExternalProject)

# TODO : Documentation
function(dst_add_subdirectory dstDependency)
    set(dstDependencySourceDirectory "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../${dstDependency}/")
    get_filename_component(dstDependencySourceDirectory "${dstDependencySourceDirectory}" REALPATH)
    get_directory_property(subdirectories DIRECTORY "${CMAKE_SOURCE_DIR}" SUBDIRECTORIES)
    if(NOT "${dstDependencySourceDirectory}" IN_LIST subdirectories)
        add_subdirectory("${dstDependencySourceDirectory}" "${CMAKE_BINARY_DIR}/dynamic_static/${dstDependency}")
    endif()
endfunction()

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
    target_include_directories(${args_target} PUBLIC "${args_includeDirectories}")
    target_link_libraries(${args_target} "${args_linkLibraries}")
    target_compile_definitions(${args_target} PUBLIC "${args_compileDefinitions}")
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

# TODO : Documentation
function(dst_add_target_test_suite)
    cmake_parse_arguments(args "" "target" "includeDirectories;includeFiles;sourceFiles;compileDefinitions" ${ARGN})
    set(catchSourceDirectory "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/external/Catch2/")
    set(catchBinaryDirectory "${CMAKE_CURRENT_BINARY_DIR}/catch2/")
    set(catchCpp "${catchBinaryDirectory}/catch.cpp")
    if(NOT TARGET Catch2::Catch2)
        add_subdirectory("${catchSourceDirectory}" "${catchBinaryDirectory}")
    endif()
    if(NOT EXISTS ${catchCpp})
        file(WRITE "${catchCpp}" "\n#define CATCH_CONFIG_MAIN\n#include \"catch2/catch.hpp\"\n")
    endif()
    dst_add_executable(
        target ${args_target}.tests
        folder ${args_target}
        linkLibraries ${args_target} Catch2::Catch2
        includeDirectories "${args_includeDirectories}"
        sourceFiles "${args_sourceFiles}" "${catchCpp}"
    )
    enable_testing()
    add_test(NAME ${args_target}.tests COMMAND ${args_target}.tests)
endfunction()

# TODO : Documentation
function(dst_add_external_cmake_project)
    cmake_parse_arguments(args "" "project;sourceDirectory;buildDirectory" "options" ${ARGN})
    add_library(${args_project} INTERFACE)
    if(NOT TARGET external)
        add_custom_target(external ALL)
    ENDIF()
    add_dependencies(${args_project} external)
    file(MAKE_DIRECTORY ${args_buildDirectory})
    execute_process(
        COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" ${args_options} "${args_sourceDirectory}"
        WORKING_DIRECTORY "${args_buildDirectory}"
        RESULT_VARIABLE error
    )
    if(error)
        message(FATAL_ERROR "CMake configuration for ${args_project} failed [${error}]")
    endif()
    if(MSVC)
        add_custom_command(
            PRE_BUILD
            TARGET external
            COMMAND ${CMAKE_COMMAND} --build . --config $<CONFIG> -- /verbosity:minimal
            WORKING_DIRECTORY "${args_buildDirectory}"
        )
    else()
        add_custom_command(
            PRE_BUILD
            TARGET external
            COMMAND "$(MAKE)"
            WORKING_DIRECTORY "${args_buildDirectory}"
        )
    endif()
endfunction()

# Util.cmake
# License: Unlicense

include(BuildOptions)

macro(ASSERT condition message)
    if(NOT ${condition})
        message(FATAL_ERROR ${message})
    endif()
endmacro()

function(git_setup_submodules)
    find_package(Git QUIET)
    if(GIT_FOUND AND EXISTS "${CMAKE_SOURCE_DIR}/.git")
        option(GIT_SUBMODULE "Check submodules during build" ON)
        if(GIT_SUBMODULE)
            message(STATUS "Git submodule update")
            execute_process(COMMAND
            ${GIT_EXECUTABLE} submodule update --init --recursive
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                RESULT_VARIABLE GIT_SUBMOD_RESULT)
            if(NOT GIT_SUBMOD_RESULT EQUAL "0")
                message(FATAL_ERROR
                    "git submodule update --init --recursive " ..
                    "failed with ${GIT_SUBMOD_RESULT}, please " ..
                    "checkout submodules")
            endif()
        endif()
    else()
        message(FATAL_ERROR "Git not found or .git directory not found")
    endif()
endfunction() # git_setup_submodules

function(git_setup_hooks hooks_dir)
    find_package(Git QUIET)

    if(GIT_FOUND)
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" config core.hooksPath ${hooks_dir}
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            RESULT_VARIABLE _githookscfg_result
        )
        if(NOT _githookscfg_result EQUAL 0)
            message(WARNING
                "Git Config: Failed to set core.hooksPath. Is Git installed??")
        endif()
        message("-- Git Config: hooksPath has been set to `${hooks_dir}`")
    endif()
endfunction() # git_setup_hooks

macro(prevent_in_source_build)
    # Prevent in-source builds
    if(CMAKE_BINARY_DIR STREQUAL CMAKE_SOURCE_DIR)
        message(FATAL_ERROR "Source and build directories cannot be the same.")
    endif()
endmacro()

macro(disable_deprecated_features)
    # Use new timestamp behavior when extracting files archives
    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
        cmake_policy(SET CMP0135 NEW)
    endif()
endmacro()

macro(disable_tests_if_subproject)
    if(DEFINED PROJECT_NAME)
        set(BUILD_TESTING OFF)
    endif()
endmacro()

macro(package_library_headers LibraryTarget HeadersPath)
    message(DEPRECATION
        "package_library_headers() is deprecated, use publish_library_headers()"
    )
    publish_library_headers(
        LIBRARY ${LibraryTarget}
        HEADERS_DIR ${HeadersPath}
    )
endmacro()

macro(publish_library_headers)
    cmake_parse_arguments(PLH
        ""                  # options (flags)
        "LIBRARY;HEADERS_DIR"  # single-value keywords
        "GLOB"              # multi-value keywords (GLOB takes a pattern list)
        ${ARGN}
    )

    # Validate required args
    if(NOT DEFINED PLH_LIBRARY)
        message(FATAL_ERROR "publish_library_headers: LIBRARY is required")
    endif()
    if(NOT DEFINED PLH_HEADERS_DIR AND NOT DEFINED PLH_GLOB)
        message(FATAL_ERROR "publish_library_headers: HEADERS_DIR or GLOB is required")
    endif()

    if(NOT DEFINED ${PROJECT_NAME}_INCLUDE_OUTPUT_DIR)
        message(FATAL_ERROR
            "Before calling publish_library_headers, "
            "set the artifact directory using set_artifact_dir()"
        )
    endif()

    set(target_name "${PLH_LIBRARY}_public_include_directory")
    set(output_dir "${${PROJECT_NAME}_INCLUDE_OUTPUT_DIR}/${PLH_LIBRARY}")

    set(custom_commands
        COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir})

    if(DEFINED PLH_GLOB)
        # Expand glob patterns at configure time
        file(GLOB_RECURSE resolved_headers
            "${PLH_HEADERS_DIR}/*.hpp"
            "${PLH_HEADERS_DIR}/*.h"
        )

        list(APPEND custom_commands
            COMMAND ${CMAKE_COMMAND} -E copy
            ${resolved_headers} ${output_dir}
        )
    else()
        list(APPEND custom_commands
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${PLH_HEADERS_DIR} ${output_dir}
        )
    endif()

    add_custom_target(${target_name} ALL
        ${custom_commands}
        COMMENT "Copying headers for ${PLH_LIBRARY} to ${output_dir}"
    )

    add_dependencies(${PLH_LIBRARY} ${target_name})
endmacro()

# Detects a Homebrew‑installed LLVM toolchain and adds the correct
# libc++ library directory to the link path.  It does so by:
#   1. Finding the Clang compiler that CMake is using.
#   2. Removing the trailing `/bin` component to obtain the root of the
#      Homebrew package (e.g. /opt/homebrew/Cellar/llvm/21.1.8).
#   3. Appending `/lib/c++` (or `/lib/clang/<ver>/lib/c++` on some
#      systems) to that root and adding it to the link directories.
# ------------------------------------------------------------------
function(macos_use_correct_stdlib)
    # --------------------------------------------------------------------
    # 1. Resolve the clang executable that CMake is using
    # --------------------------------------------------------------------
    # Prefer the compiler that CMake itself has chosen
    if(CMAKE_C_COMPILER AND EXISTS "${CMAKE_C_COMPILER}")
        set(CLANG_EXECUTABLE "${CMAKE_C_COMPILER}")
    elseif(DEFINED ENV{CC} AND NOT "$ENV{CC}" STREQUAL "")
        # If the user explicitly set CC, try that first
        if(EXISTS "$ENV{CC}")
            set(CLANG_EXECUTABLE "$ENV{CC}")
        else()
            # Treat CC as a hint/path; let CMake search it
            find_program(
                CLANG_EXECUTABLE clang
                HINTS "$ENV{CC}" NO_DEFAULT_PATH)
        endif()
    else()
        # Fallback to the default search
        find_program(CLANG_EXECUTABLE clang)
    endif()

    if(NOT CLANG_EXECUTABLE)
        message(STATUS
            "clang not found – skipping Homebrew LLVM stdlib detection")
        return()
    endif()

    # --------------------------------------------------------------------
    # 2. Check whether this clang comes from Xcode
    # --------------------------------------------------------------------
    # 2a – Path‑based detection
    get_filename_component(ClangAbsPath "${CLANG_EXECUTABLE}" ABSOLUTE)
    string(FIND "${ClangAbsPath}" "/Applications/Xcode.app" XcodeInPath)
    if(NOT XcodeInPath EQUAL -1)
        message(STATUS
            "Using Xcode clang (${ClangAbsPath}) –"
            " Homebrew stdlib detection skipped"
        )
        return()
    endif()

    # 2b – Version‑string detection (fallback safety net)
    execute_process(
        COMMAND "${CLANG_EXECUTABLE}" --version
        OUTPUT_VARIABLE CLANG_VER
        ERROR_VARIABLE CLANG_VER
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    string(FIND "${CLANG_VER}" "Apple clang" AppleClangIdx)
    if(NOT AppleClangIdx EQUAL -1)
        message(STATUS
            "Detected Apple clang from --version output"
            " Homebrew stdlib detection skipped"
        )
        return()
    endif()

    # --------------------------------------------------------------------
    # 3. Strip the trailing `/bin` to get the Homebrew package root
    # --------------------------------------------------------------------
    get_filename_component(ClangDir "${CLANG_EXECUTABLE}" PATH)
    string(REGEX REPLACE "/bin$" "" LLVM_ROOT "${ClangDir}")

    # --------------------------------------------------------------------
    # 4. Verify that we actually found a plausible root
    # --------------------------------------------------------------------
    if(NOT LLVM_ROOT OR NOT IS_DIRECTORY "${LLVM_ROOT}")
        message(STATUS
            "Could not determine Homebrew LLVM root from ${ClangDir}")
        return()
    endif()

    # --------------------------------------------------------------------
    # 5. Construct the lib directory path and add it to the link directories
    # --------------------------------------------------------------------
    set(LLVM_LIBRARY_DIR "${LLVM_ROOT}/lib")
    if(EXISTS "${LLVM_LIBRARY_DIR}/c++")
        message(STATUS
            "Detected Homebrew LLVM library directory: ${LLVM_LIBRARY_DIR}")
        link_directories("${LLVM_LIBRARY_DIR}/c++")
    else()
        message(STATUS
            "Expected ${LLVM_LIBRARY_DIR}/c++ not found – ignoring")
    endif()
endfunction()


# vim: set sw=4 ts=4 sts=4 et foldmethod=indent :

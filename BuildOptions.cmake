# BuildOptions.cmake
# License: Unlicense (https://unlicense.org)
option(USE_CCACHE "Use ccache compiler cache to speed up builds" OFF)
option(USE_MOLD "Use the mold/sold parallel linker for faster builds" OFF)
option(BUILD_TESTING "Build unit tests" ON)

function(add_ccache_support)
    if(USE_CCACHE)
        message(CHECK_START "Detecting cacche")

        find_program(CCACHE_PATH ccache)
        if(CCACHE_PATH)
            message(STATUS "ccache found: ${CCACHE_PATH}")

            if(DEFINED CMAKE_C_COMPILER_LAUNCHER)
                set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PATH};${CMAKE_C_COMPILER_LAUNCHER}")
            else()
                set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PATH}")
            endif()

            if(DEFINED CMAKE_CXX_COMPILER_LAUNCHER)
                set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PATH};${CMAKE_CXX_COMPILER_LAUNCHER}")
            else()
                set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PATH}")
            endif()
        endif()
    endif()
endfunction()

function(check_and_set_linker)
    if(USE_MOLD)
        # Determine if the compiler is GCC or Clang
        if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
            message(STATUS "Detected GCC/Clang, checking for mold/sold linker...")

            # Check for mold linker on general systems mold on macOS
            find_program(MOLD_LINKER mold)

            if(MOLD_LINKER)
                set(CMAKE_LINKER_TYPE MOLD)
                message(STATUS "LINKER_TYPE set to ${CMAKE_LINKER_TYPE} for faster builds")
                list(APPEND CMAKE_MESSAGE_INDENT " ")
                message(STATUS "(set -DUSE_MOLD=OFF to disable)")
                list(POP_BACK CMAKE_MESSAGE_INDENT)
            else()
                message(STATUS "  -- No suitable mold linker found. Using default linker.")
            endif()
        else()
            message(STATUS "Compiler is neither GCC nor Clang. Skipping mold linker check.")
        endif()
    endif()
endfunction()

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
            find_program(CLANG_EXECUTABLE clang
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
            "Using Xcode clang (${ClangAbsPath}) – Homebrew stdlib detection skipped")
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
            "Detected Apple clang from --version output – Homebrew stdlib detection skipped")
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

# vim: set ts=4 sw=4 sts=4 expandtab :

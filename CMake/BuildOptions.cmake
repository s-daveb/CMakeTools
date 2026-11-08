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
                set(CMAKE_C_COMPILER_LAUNCHER
                    "${CCACHE_PATH};${CMAKE_C_COMPILER_LAUNCHER}")
            else()
                set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PATH}")
            endif()

            if(DEFINED CMAKE_CXX_COMPILER_LAUNCHER)
                set(CMAKE_CXX_COMPILER_LAUNCHER
                    "${CCACHE_PATH};${CMAKE_CXX_COMPILER_LAUNCHER}")
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
            message(STATUS
                "Detected GCC/Clang, checking for mold/sold linker...")

            # Check for mold linker on general systems mold on macOS
            find_program(MOLD_LINKER mold)

            if(MOLD_LINKER)
                set(CMAKE_LINKER_TYPE MOLD)
                message(STATUS
                    "LINKER_TYPE set to ${CMAKE_LINKER_TYPE} for faster builds")
                list(APPEND CMAKE_MESSAGE_INDENT " ")
                message(STATUS "(set -DUSE_MOLD=OFF to disable)")
                list(POP_BACK CMAKE_MESSAGE_INDENT)
            else()
                message(STATUS
                    "  -- No suitable mold linker found. Using default linker.")
            endif()
        else()
            message(STATUS
                "Compiler is neither GCC nor Clang."
                " Skipping mold linker check."
            )
        endif()
    endif()
endfunction()

# vim: set ts=4 sw=4 sts=4 expandtab :

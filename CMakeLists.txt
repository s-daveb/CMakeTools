cmake_minimum_required(VERSION 3.22)
project(strict
    VERSION 0.1.0
    LANGUAGES C CXX
    DESCRIPTION "Strict — a C++20 Slack clone (web app)"
)

# --- Global language settings ----------------------------------------------
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Default to Release if not specified — agents: do not build Debug in CI.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# Position-independent code — required for shared libs and FreeBSD PIC defaults.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Compatibility shim: some older FetchContent deps set cmake_minimum_required < 3.5
if(POLICY CMP0000)
    set(CMAKE_POLICY_VERSION_MINIMUM 3.5 CACHE STRING "" FORCE)
endif()

# --- Dependencies via FetchContent -----------------------------------------
include(FetchContent)

# libwebsockets: HTTP server + WebSocket in one event loop.
# Pin the version; do not float on main.
FetchContent_Declare(
    libwebsockets
    GIT_REPOSITORY https://github.com/warmcat/libwebsockets.git
    GIT_TAG        v4.3.5
    GIT_SHALLOW    TRUE
)
set(LWS_WITHOUT_TESTAPPS ON CACHE BOOL "" FORCE)
set(LWS_WITH_MINIMAL_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LWS_WITH_SHARED OFF CACHE BOOL "" FORCE)
set(LWS_WITH_STATIC ON CACHE BOOL "" FORCE)
set(LWS_WITH_SSL OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(libwebsockets)

# --- strict library (core logic) -------------------------------------------
add_library(strict_core STATIC
    src/core/server.cpp
    src/core/ws_handler.c
)
target_include_directories(strict_core PUBLIC src)
target_link_libraries(strict_core PUBLIC websockets)

# --- strict executable ------------------------------------------------------
add_executable(strict src/main.cpp)
target_link_libraries(strict PRIVATE strict_core)

# --- Install layout (FreeBSD Ports expects bin/, etc/, share/) -------------
include(GNUInstallDirs)
install(TARGETS strict RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY static/ DESTINATION ${CMAKE_INSTALL_DATADIR}/strict/static)
install(FILES etc/strict.conf.example DESTINATION ${CMAKE_INSTALL_SYSCONFDIR})

# --- Tests (optional, gated by BUILD_TESTING) ------------------------------
include(CTest)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

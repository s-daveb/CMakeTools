FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.14.0
    GIT_SHALLOW    TRUE
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

add_executable(strict_tests
    core/server_test.cpp
)
target_link_libraries(strict_tests PRIVATE strict_core gtest_main)

include(GoogleTest)
gtest_discover_tests(strict_tests)

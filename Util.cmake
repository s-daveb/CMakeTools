# Util.cmake
# License: Unlicense

macro(ASSERT condition message)
    if(NOT ${condition})
        message(FATAL_ERROR ${message})
    endif()
endmacro()

macro(git_setup_submodules)
	find_package(Git QUIET)
	if(GIT_FOUND AND EXISTS "${CMAKE_SOURCE_DIR}/.git")
		option(GIT_SUBMODULE "Check submodules during build" ON)
		if(GIT_SUBMODULE)
			message(STATUS "Git submodule update")
			execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
				WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
				RESULT_VARIABLE GIT_SUBMOD_RESULT)
			if(NOT GIT_SUBMOD_RESULT EQUAL "0")
				message(FATAL_ERROR "git submodule update --init --recursive failed with ${GIT_SUBMOD_RESULT}, please checkout submodules")
			endif()
		endif()
	else()
		message(FATAL_ERROR "Git not found or .git directory not found")
	endif()
endmacro()

macro(prevent_in_source_build)
	# Prevent in-source builds
	if (CMAKE_BINARY_DIR STREQUAL CMAKE_SOURCE_DIR)
		message(FATAL_ERROR "Source and build directories cannot be the same.")
	endif()
endmacro()

macro(disable_deprecated_features)
	# Use new timestamp behavior when extracting files archives
	if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
		cmake_policy(SET CMP0135 NEW)
	endif()
endmacro()

macro(disable_tests_if_subproject)
	option(BUILD_TESTING "Build unit tests" ON)

	if (DEFINED PROJECT_NAME)
		set(BUILD_TESTING OFF PARENT_SCOPE)
	endif()
endmacro()



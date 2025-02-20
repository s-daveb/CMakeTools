# BuildOptions.cmake
# License: Unlicense (https://unlicense.org)
option(USE_MOLD "Use the mold/sold parallel linker for faster builds" ON)
option(BUILD_TESTING "Build unit tests" ON)
option(GIT_SUBMODULE "Check submodules during build" ON)


# Enable the use of ccache and distcc
option(USE_CCACHE "Use ccache compiler cache to speed up builds" OFF)
option(USE_DISTCC "Use distcc to distribute compilation and speed up builds" OFF)

# Function to set up compiler launchers
function(setup_compiler_launchers)
	set(launchers "")

	if (USE_CCACHE)
		find_program(CCACHE_PROGRAM ccache)
		if (CCACHE_PROGRAM)
			list(APPEND launchers ${CCACHE_PROGRAM})
			message(STATUS "ccache found: ${CCACHE_PROGRAM}")
		else()
			message(WARNING "ccache not found; proceeding without it.")
		endif()
	endif()

	if (USE_DISTCC)
		find_program(DISTCC_PROGRAM distcc)
		if (DISTCC_PROGRAM)
			list(APPEND launchers ${DISTCC_PROGRAM})
			message(STATUS "distcc found: ${DISTCC_PROGRAM}")
		else()
			message(WARNING "distcc not found; proceeding without it.")
		endif()
	endif()

	if (launchers)
		set(CMAKE_C_COMPILER_LAUNCHER ${launchers} PARENT_SCOPE)
		set(CMAKE_CXX_COMPILER_LAUNCHER ${launchers} PARENT_SCOPE)
		if(NOT DEFINED CC)
		  set(CC clang)
		endif()
		execute_process(
			COMMAND ${CC} -dumpmachine
			OUTPUT_VARIABLE TARGET
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		set(TARGET ${TARGET} PARENT_SCOPE)
		message(STATUS "Compiler launchers set: ${launchers}")
		message(STATUS "Compiler target set: ${TARGET}")
	else()
		message(STATUS "No compiler launchers enabled.")
	endif()
endfunction()

function(check_and_set_linker)
	if(USE_MOLD)
		# Determine if the compiler is GCC or Clang
		if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
			message(STATUS "Detected GCC/Clang, checking for mold/sold linker...")

			# Check for mold linker on general systems and ld64.mold on macOS
			if(APPLE)
				find_program(MOLD_LINKER ld64.mold)
				set(CMAKE_LINKER_TYPE SOLD)
			else()
				find_program(MOLD_LINKER mold)
				set(CMAKE_LINKER_TYPE MOLD)
			endif()

			if(MOLD_LINKER)
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

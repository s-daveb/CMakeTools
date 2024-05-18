# BuildOptions.cmake
# License: Unlicense (https://unlicense.org)
option(USE_CCACHE "Use ccache compiler cache to speed up builds" ON)
option(USE_MOLD "Use the mold/sold parallel linker for faster builds" ON)
option(BUILD_TESTING "Build unit tests" ON)

function(use_ccache)
	if (USE_CCACHE)
		message(CHECK_START "Detecting cacche")

		find_program(CCACHE_PATH ccache)
		if(CCACHE_PATH)
				message(CHECK_PASS("found"))
				set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CCACHE_PATH})
				set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ${CCACHE_PATH})
		endif()

		list(APPEND CMAKE_MESSAGE_INDENT " ")
			message(STATUS "(set -DUSE_CCACHE=Off to disable)")
		list(POP_BACK CMAKE_MESSAGE_INDENT)
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

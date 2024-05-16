# BuildPreferences.cmake
# Copyright (c) 2024 Saul D Beniquez
# License: MIT
#
# This module defines a function prevent_in_source_build() that prevents in-source builds
# and sets a policy for CMake version 3.24.0 and above.

function(prevent_in_source_build)
	# Prevent in-source builds
	if (CMAKE_BINARY_DIR STREQUAL CMAKE_SOURCE_DIR)
		message(FATAL_ERROR "Source and build directories cannot be the same.")
	endif()
endfunction()

function(disable_deprecated_features)
	# Use new timestamp behavior when extracting files archives
	if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
		cmake_policy(SET CMP0135 NEW)
	endif()
endfunction()



function(set_artifact_dir path)
    # Set local variable, not necessary to be parent scope since it's not used outside this function
    set(ARTIFACT_DIR "${path}")

    # Set project-specific artifact directory in parent scope
    set(${PROJECT_NAME}_ARTIFACT_DIR "${path}" PARENT_SCOPE)
    set(${PROJECT_NAME}_INCLUDE_OUTPUT_DIR "${path}/include" PARENT_SCOPE)

    # Set output directories in parent scope using the provided path directly
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${path}/lib" PARENT_SCOPE)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${path}/lib" PARENT_SCOPE)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${path}/bin" PARENT_SCOPE)
endfunction()

function(package_library_headers LibraryTarget)

	if (NOT DEFINED ${PROJECT_NAME}_INCLUDE_OUTPUT_DIR)
		message(FATAL_ERROR "Before calling package_library_headers, set the artifact directory using set_artifact_dir()")
	endif()

    # Create the custom target name
    set(target_name "${LibraryTarget}_copy_include_directory")
    set(output_dir "${${PROJECT_NAME}_INCLUDE_OUTPUT_DIR}")

    # Create a list to hold custom commands
    set(custom_commands
		COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir}/${LibraryTarget} )

    set(is_glob false)
    # Iterate over each argument to copy them
    foreach(item IN LISTS ARGN)
        if (IS_DIRECTORY ${item})
            get_filename_component(item_name ${item} NAME)
            list(APPEND custom_commands
                COMMAND ${CMAKE_COMMAND} -E copy_directory ${item} ${output_dir}/${LibraryTarget}/${item_name}
            )
        else()
 	 	 	if (${is_glob})
            	file(GLOB glob_files ${item})
            	list(APPEND expanded_items ${glob_files})
            	message(STATUS "glob_files" ${glob_files})
            	set(is_glob false)
        		foreach(expanded IN LISTS expanded_items)
					get_filename_component(item_name ${expanded} NAME)
					list(APPEND custom_commands
						COMMAND ${CMAKE_COMMAND} -E copy ${expanded} ${output_dir}/${LibraryTarget}/${item_name}
					)
				endforeach()
			elseif (item STREQUAL "GLOB")
            	set(is_glob true)
            else()
            	get_filename_component(item_name ${item} NAME)
            	list(APPEND custom_commands
                	COMMAND ${CMAKE_COMMAND} -E copy ${item} ${output_dir}/${LibraryTarget}/${item_name}
            	)
    		endif()
    	endif()
    endforeach()

    # Create the target to copy directories and files
    add_custom_target(${target_name} ALL
        ${custom_commands}
        COMMENT "Copying files and directories to ${output_dir}/include/${LibraryTarget}/"
    )

    # Add the custom target as a dependency of the library target
    add_dependencies(${LibraryTarget} ${target_name})
endfunction()

function(disable_tests_if_subproject)
	option(BUILD_TESTING "Build unit tests" ON)

	if (DEFINED PROJECT_NAME)
		set(BUILD_TESTING OFF PARENT_SCOPE)
	endif()
endfunction()


# vim: ts=4 sts=4 sw=4 noet foldmethod=indent :

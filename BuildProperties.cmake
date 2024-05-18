# BuildProperties.cmake
# License: Unlicense (https://unlicense.org)

macro(set_binary_output_path path)
	set_artifact_dir(path)
endmacro()

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

function(package_library_headers LibraryTarget HeadersPath)
	if (NOT DEFINED ${PROJECT_NAME}_INCLUDE_OUTPUT_DIR)
		message(FATAL_ERROR "Before calling package_library_headers, set the artifact directory using set_artifact_dir()")
	endif()

    # Create the custom target name
    set(target_name "${LibraryTarget}_copy_include_directory")
    set(output_dir "${${PROJECT_NAME}_INCLUDE_OUTPUT_DIR}")

    # Create a list to hold custom commands
    set(custom_commands
		COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir} )
    list(APPEND custom_commands
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${HeadersPath} ${output_dir}/${LibraryTarget}
    )

    # Create the target to copy directories and files
    add_custom_target(${target_name} ALL
        ${custom_commands}
        COMMENT "Copying files and directories to ${output_dir}/include/${LibraryTarget}/"
    )

    # Add the custom target as a dependency of the library target
    add_dependencies(${LibraryTarget} ${target_name})
endfunction()


# vim: ts=4 sts=4 sw=4 noet foldmethod=indent :

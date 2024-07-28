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




# vim: ts=4 sts=4 sw=4 noet foldmethod=indent :

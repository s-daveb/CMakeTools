# BuildPreferences.cmake
# License: Unlicense (https://unlicense.org)

include(BuildOptions)
include(Util)

git_setup_submodules()
prevent_in_source_build()
disable_deprecated_Features()


# vim: ts=4 sts=4 sw=4 noet foldmethod=indent :

# BuildPreferences.cmake
# License: Unlicense (https://unlicense.org)

include(BuildOptions)
include(Util)

prevent_in_source_build()
disable_deprecated_features()

# When this package is included as a subproject, there's no need to
# build and run the unit-tests.
# Sets -DBUILD_TESTING to false by default if this is a third-party lib build
# This check must appear beforezR project()
disable_tests_if_subproject()

# vim: ts=4 sts=4 sw=4 noet foldmethod=indent :

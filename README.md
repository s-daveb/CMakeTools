# CmakeTools

[![License](https://img.shields.io/badge/License-Unlicense-lightgrey.svg)](https://unlicense.org/)
[![CMake](https://img.shields.io/badge/CMake-3.26.0-blue.svg)](https://cmake.org/)

## Overview

This repository contains CMake scripts I use in my projects to 
manage build options, preferences, properties, and utilities for a CMake-based project. 

The main scripts included are:

- `BuildOptions.cmake`
- `Util.cmake`

Additional third-party scripts included are:
- [![GitHub](https://img.shields.io/badge/GitHub-CPM.cmake-yellow.svg)](https://github.com/cpm-cmake/CPM.cmake) ![MIT](https://img.shields.io/badge/License-MIT-red.svg)

A convenience .cmake file with some default behavior is also included:
- `DefaultConfig.cmake`
    - _Contains some sane defaults to reduce repetitive typing_


## Getting Started

### Prerequisites

- CMake 3.26.0 or above. Might work with lesser verisons, but not tested.

### Setup

1. Create a project repository and a directory to contain these scripts. (e.g `CMake`)
2. ```sh
    $ git submodule add ${REPO_URL} CMake # You can use any directory name you wish
    ```

### Usage

1. Create your `CMakeLists.txt`
2. Add this at the top:

    ```cmake
    # CMakeLists.txt
    cmake_minimum_required(VERSION 3.26)

    list(PREPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/CMake)
    include(Util)
    git_setup_submodules()

    include(BuildPreferences)
    iunclude(BuildOptions)

    prevent_in_source_build()
    disable_deprecated_features()

    ## or 
    # include(DefaultConfig)

    project(MyProject)
    ```

### License
The .cmake scripts in this repository are disstributed under the Unlicense - see the [LICENSE](LICENSE) file for details.

The included CPM.cmake module is © Lars Melchior and contributors, and is distributed under the MIT License - see the [LICENSE](https://github.com/cpm-cmake/CPM.cmake/blob/33bdbae902df5365ad545a7d082949883bd8d99d/LICENSE) file for details.

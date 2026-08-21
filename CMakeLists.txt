# Specify the minimum version for CMake
cmake_minimum_required(VERSION 3.10)

# Project's name and version
project(SID VERSION 1.0.0 LANGUAGES CXX)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None Debug GProf Valgrind Release RelWithDebInfo MinSizeRel." FORCE)
endif()

# Find either mariadb_config or mysql_config
find_program(DB_CONFIG_EXECUTABLE NAMES mariadb_config mysql_config)
if(NOT DB_CONFIG_EXECUTABLE)
    message(FATAL_ERROR "Could not find mariadb_config or mysql_config. Please install MariaDB/MySQL development packages.")
endif()

# Get DB flags and plugin directory
execute_process(COMMAND ${DB_CONFIG_EXECUTABLE} --include
                OUTPUT_VARIABLE DB_INCLUDE_FLAGS
                OUTPUT_STRIP_TRAILING_WHITESPACE)

execute_process(COMMAND ${DB_CONFIG_EXECUTABLE} --plugindir
                OUTPUT_VARIABLE DB_PLUGINDIR
                OUTPUT_STRIP_TRAILING_WHITESPACE)

# Convert raw "-I/path" string into a list CMake can process
separate_arguments(DB_INCLUDE_FLAGS_LIST UNIX_COMMAND "${DB_INCLUDE_FLAGS}")

# Custom targets for the contrib libraries
add_custom_target(contribClean
   COMMAND ${CMAKE_MAKE_PROGRAM} clean
   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/contrib)

add_custom_target(staticLibHtm
   COMMAND ${CMAKE_MAKE_PROGRAM}
   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HtmIndex)

add_custom_target(staticLibHpx
   COMMAND ${CMAKE_MAKE_PROGRAM}
   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HealPix3)

# 4. Define the library
add_library(udf_sid SHARED
    src/htmCircleRegion.cpp
    src/htmRectRegion.cpp
    src/getHTMid.cpp
    src/getHTMidByName.cpp
    src/getHTMnameById.cpp
    src/getHTMNeighb.cpp
    src/getHTMNeighbC.cpp
    src/getHTMsNeighb.cpp
    src/getHTMBary.cpp
    src/getHTMBaryC.cpp
    src/getHTMBaryDist.cpp
    src/getHealPid.cpp
    src/getHealPBaryDist.cpp
    src/getHealPMaxS.cpp
    src/getHealPBary.cpp
    src/getHealPNeighbC.cpp
    src/getHealPNeighb.cpp
    src/getHealPBaryC.cpp
    src/getHealPBound.cpp
    src/getHealPBoundC.cpp
    src/myHealPCone.cpp
    src/myHealPRect.cpp
    src/myHealPRect4v.cpp
    src/difflist_ui.cpp
    src/skysep_h.cpp
    src/udf.cc
)

# Target-specific properties
set_target_properties(udf_sid PROPERTIES
    VERSION ${PROJECT_VERSION}
    CXX_STANDARD 11
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS YES # This enables gnu++11 instead of just c++11
)

# Add includes specifically for this target
target_include_directories(udf_sid PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HtmIndex/include
    ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HealPix3
)

# Apply the MySQL/MariaDB include flags directly to this target
target_compile_options(udf_sid PRIVATE ${DB_INCLUDE_FLAGS_LIST})

# Link dependencies
add_dependencies(udf_sid staticLibHtm staticLibHpx)

target_link_libraries(udf_sid PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HtmIndex/lib/libSpatialIndex.a
    ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HealPix3/lib/libHealP3.a
)

# Install
install(TARGETS udf_sid LIBRARY DESTINATION ${DB_PLUGINDIR})

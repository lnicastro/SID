# Specify the minimum version for CMake
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

# Project's name
PROJECT(SID)
SET(VERSION "1.0.0")

IF(NOT CMAKE_BUILD_TYPE)
     SET(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None Debug GProf Valgrind Release RelWithDebInfo MinSizeRel." FORCE)
ENDIF()

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/contrib/HtmIndex/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/contrib/HealPix3)
include_directories(${MYSQL_CFLAGS})

execute_process(COMMAND mysql_config --include OUTPUT_VARIABLE MYSQL_CFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND mysql_config --plugindir OUTPUT_VARIABLE MYSQL_PLUGINDIR OUTPUT_STRIP_TRAILING_WHITESPACE)
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${MYSQL_CFLAGS}" ) 

# A "clean" command for the contrib libraries
add_custom_target(
   contribClean
   COMMAND make clean
   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/contrib)

add_custom_target(
   staticLibHtm
   COMMAND make
   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HtmIndex)


add_custom_target(
   staticLibHpx
   COMMAND make
   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HealPix3)


set(CMAKE_SHARED_LIBRARY_SUFFIX ".so")

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

add_dependencies(udf_sid contribClean)
add_dependencies(udf_sid staticLibHtm)
add_dependencies(udf_sid staticLibHpx)

set_target_properties(udf_sid PROPERTIES VERSION ${VERSION})
target_link_libraries(udf_sid ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HtmIndex/lib/libSpatialIndex.a)
target_link_libraries(udf_sid ${CMAKE_CURRENT_SOURCE_DIR}/contrib/HealPix3/lib/libHealP3.a)

install(TARGETS udf_sid LIBRARY DESTINATION ${MYSQL_PLUGINDIR})

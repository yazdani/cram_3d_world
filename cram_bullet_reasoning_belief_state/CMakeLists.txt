cmake_minimum_required(VERSION 2.8.3)
project(cram_bullet_reasoning_belief_state)

find_package(catkin REQUIRED COMPONENTS)

#set the default path for built executables to the "bin" directory
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
#set the default path for built libraries to the "lib" directory
set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)

catkin_package()


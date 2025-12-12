#!/bin/bash
# shellcheck disable=SC1090,SC1091
set -e

# Additional environment setup for specific packages
export RMW_IMPLEMENTATION=rmw_zenoh_cpp
export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/projects/robotology-superbuild/build/install/share/ecargo
export GAZEBO_RESOURCE_PATH=${GAZEBO_RESOURCE_PATH}:/projects/robotology-superbuild/build/install/share/ecargo
export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:/projects/robotology-superbuild/build/install/share
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/projects/robotology-superbuild/build/install/lib
export ROS_DOMAIN_ID=42

exec "$@"
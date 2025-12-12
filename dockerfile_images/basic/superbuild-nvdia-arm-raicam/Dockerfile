#start from image passed by argument during build process. Usually it is an ubuntu image plus mesa library.
ARG START_IMG="none"

ARG METADATA_FILE=/usr/local/bin/setup_metadata.sh
ARG PROJECTS_DIR=/projects
ARG INSTALL_DIR=${PROJECTS_DIR}/robotology-superbuild/build/install
ARG release="v2025.02.0"
ARG sbtag="Custom"
ARG ROBOTOLOGY_PROJECT_TAGS_CUSTOM=${PROJECTS_DIR}/robotology-superbuild/releases/${release}.yaml
ARG metadata="data"
ARG ROBOTOLOGY_INITIALIZATION_FILE=/usr/local/bin/setup_robotology_tdd.sh
ARG ROS_INITIALIZATION_FILE=/usr/local/bin/ros_entrypoint.sh

FROM $START_IMG AS nvidia_builder

LABEL maintainer="valentina.gaggero@iit.it, jacopo.losi@iit.it"

ARG METADATA_FILE
ARG INSTALL_DIR
ARG PROJECTS_DIR
ARG CMAKE_GENERATOR="Unix Makefiles"
ARG BUILD_TYPE=Release
ARG CMAKE_EXTRA_OPTIONS=-j4
ARG release
ARG sbtag
ARG metadata
ARG ROBOTOLOGY_PROJECT_TAGS_CUSTOM

ENV ROS_DISTRO=humble
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies given in documentation in superbuild
# https://github.com/robotology/robotology-superbuild#linux
RUN mkdir -p /etc/bash_completion.d/ && \
    apt-get update &&\
    apt-get install -y -q --no-install-recommends\
        # MISC
        apt-utils \
        dpkg \
        bash-completion \
        git \
        wget \
        apt-transport-https \
        ca-certificates \
        vim &&\
    update-ca-certificates

# Print debug info to check if relevant build args are taken correctly from conf_build.ini
RUN echo "DEBUG ==>  Release:" ${release} &&\
    echo "DEBUG ==>  TAG:" ${sbtag} &&\
    echo "DEBUG ==>  metadata:" ${metadata} &&\
    echo "DEBUG ==>  METADATA_FILE:" ${METADATA_FILE} &&\
    echo "DEBUG ==>  INSTALL_DIR:" ${INSTALL_DIR}


# Set up locale for ROS2:humble installation
# check for UTF-8 support
RUN locale  &&\
    apt update &&\
    apt install -y locales &&\
    locale-gen en_US en_US.UTF-8 &&\
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

# verify settings
RUN locale  

# Verify ubuntu universe repository is enabled
RUN apt install -y software-properties-common &&\
    add-apt-repository universe

# Installing the ros2-apt-source package
RUN apt update && apt install -y curl &&\
    export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}') &&\
    curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb" &&\
    dpkg -i /tmp/ros2-apt-source.deb &&\
    apt update && \
    apt install -y --no-install-recommends \
    ros-humble-rqt ros-humble-rqt-common-plugins ros-humble-test-msgs ros-humble-desktop ros-dev-tools \
    ros-humble-rmw-cyclonedds-cpp ros-humble-ament-cmake-clang-format ros-humble-hardware-interface ros-humble-controller-manager ros-humble-ros2-control \
    ros-humble-ament-cmake && \
    rm -rf /var/lib/apt/lists/*

# Install development tools and ROS tools
RUN apt update && apt install -y \
  python3-flake8-docstrings \
  python3-pip \
  python3-pytest-cov \
  ros-dev-tools &&\
  rm -rf /var/lib/apt/lists/*

# Setup entrypoint
ARG ROBOTOLOGY_INITIALIZATION_FILE
ARG ROS_INITIALIZATION_FILE
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY setup.sh ${ROBOTOLOGY_INITIALIZATION_FILE}
COPY ros_entrypoint.sh ${ROS_INITIALIZATION_FILE}

ENV AMENT_PREFIX_PATH=/opt/ros/${ROS_DISTRO}

RUN bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && \
    echo 'AMENT_PREFIX_PATH:' \$AMENT_PREFIX_PATH && \
    echo 'AMENT_CURRENT_PREFIX:' \$AMENT_CURRENT_PREFIX"
    
# Add ros setup.bash to bashrc
RUN echo "\n\
source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc

# The bashrc is read only when opening an interactive shell. Let other projects find packages contained in the superbuild.
ENV CMAKE_PREFIX_PATH=${INSTALL_DIR}

RUN bash -c "mkdir ${PROJECTS_DIR} && cd ${PROJECTS_DIR} &&\
    git clone https://github.com/robotology/robotology-superbuild.git --branch ${release} &&\
    cd robotology-superbuild &&\
    apt update &&\
    ./scripts/install_apt_dependencies.sh &&\
    mkdir build &&\
    cd build &&\ 
    source /opt/ros/${ROS_DISTRO}/setup.bash &&\
    cmake .. \
        -G '$CMAKE_GENERATOR' \
        -DCMAKE_PREFIX_PATH='/opt/ros/${ROS_DISTRO}:/projects/robotology-superbuild/build/install' \
        -DCMAKE_INSTALL_PREFIX='/usr/local' \
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DROBOTOLOGY_PROJECT_TAGS=${sbtag} \
        -DROBOTOLOGY_PROJECT_TAGS_CUSTOM=${ROBOTOLOGY_PROJECT_TAGS_CUSTOM} \
        -DNON_INTERACTIVE_BUILD:BOOL=ON \
        -DROBOTOLOGY_ENABLE_CORE:BOOL=ON \
        -DROBOTOLOGY_ENABLE_ICUB_HEAD:BOOL=ON \
        -DROBOTOLOGY_ENABLE_DYNAMICS:BOOL=ON \
        -DYCM_USE_DEPRECATED:BOOL=OFF \
        -DROBOTOLOGY_USES_MUJOCO:BOOL=OFF \
        -DROBOTOLOGY_USES_GAZEBO:BOOL=OFF \
        -DROBOTOLOGY_USES_GZ:BOOL=OFF \
        -DROBOTOLOGY_USES_ROS2:BOOL=ON &&\
    cmake --build . -- ${CMAKE_EXTRA_OPTIONS}"
    

# --------------------------------------------------------------------------- #
# 4. Realsense yarp device                                                    #
# --------------------------------------------------------------------------- #
WORKDIR /usr/src
# Builder dependencies installation
ARG LIBRS_VERSION=2.57.5
RUN apt-get update \
    && apt-get install -qq -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    libssl-dev \
    libusb-1.0-0-dev \
    pkg-config \
    libgtk-3-dev \
    libglfw3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev &&\
    rm -rf /var/lib/apt/lists/*

RUN curl https://codeload.github.com/realsenseai/librealsense/tar.gz/refs/tags/v$LIBRS_VERSION -o librealsense.tar.gz 
RUN tar -zxf librealsense.tar.gz \
    && rm librealsense.tar.gz 
RUN ln -s /usr/src/librealsense-$LIBRS_VERSION /usr/src/librealsense

# Build and install
RUN cd /usr/src/librealsense \
    && mkdir build && cd build \
    && cmake \
    -DCMAKE_C_FLAGS_RELEASE="${CMAKE_C_FLAGS_RELEASE} -s" \
    -DCMAKE_CXX_FLAGS_RELEASE="${CMAKE_CXX_FLAGS_RELEASE} -s" \
    -DCMAKE_INSTALL_PREFIX=/opt/librealsense \  
    -DCHECK_FOR_UPDATES=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DFORCE_LIBUVC=ON \
    -DFORCE_RSUSB_BACKEND=ON \
    -DBUILD_WITH_CUDA=ON \
    -DBUILD_PYTHON_BINDINGS=OFF \
    -DCMAKE_BUILD_TYPE=Release ../ \
    && make -j$(($(nproc)-1)) all \
    && make install 

# Copy binaries 
RUN cp -r /opt/librealsense/* /usr/local/
RUN cp /usr/src/librealsense/config/99-realsense-libusb.rules /etc/udev/rules.d/
RUN cp /usr/src/librealsense/config/99-realsense-d4xx-mipi-dfu.rules /etc/udev/rules.d/
COPY 10-usb-devices.rules /etc/udev/rules.d/
RUN bash -c "udevadm control --reload-rules && udevadm trigger || true"

# Install dep packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \	
    libusb-1.0-0 \
    udev \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*


WORKDIR ${PROJECTS_DIR}
RUN git clone --depth 1 --branch v0.4.0 https://github.com/robotology/yarp-device-realsense2.git

# Build and install yarp-device-realsense2
WORKDIR ${PROJECTS_DIR}
RUN cd ${PROJECTS_DIR}/yarp-device-realsense2 &&\
    mkdir -p build && cd build &&\
        cmake .. \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DCMAKE_BUILD_TYPE=Release &&\
    make -j$(nproc) install

# # --------------------------------------------------------------------------- #
# # 5. RPLIDAR yarp device                                                      #
# # --------------------------------------------------------------------------- #
WORKDIR ${PROJECTS_DIR}
# We need to temporarily clone a fork of the report since a critical fix related to CMakeLists of lidar4 has been made there but not yet merged in the original repo
RUN git clone https://github.com/kaidegast/yarp-device-rplidar.git

WORKDIR ${PROJECTS_DIR}/yarp-device-rplidar
RUN git checkout fix_sdk_missing_component && \
    mkdir -p build && cd build && \
    cmake .. \
        -DENABLE_rpLidar:BOOL=OFF \
        -DENABLE_rpLidar2:BOOL=OFF \ 
        -DENABLE_rpLidar3:BOOL=OFF \
        -DENABLE_rpLidar4:BOOL=ON \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} && \
    make -j$(nproc) install

# --------------------------------------------------------------------------- #

# --------------------------------------------------------------------------- #
# 6. ECargo project dependencies                                              #
# --------------------------------------------------------------------------- #
# ROS/Gazebo packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-rmw-zenoh-cpp \
        ros-${ROS_DISTRO}-navigation2 \
        ros-${ROS_DISTRO}-nav2-bringup \
        ros-${ROS_DISTRO}-pcl-conversions \
        ros-${ROS_DISTRO}-pcl-ros \
        ros-${ROS_DISTRO}-pointcloud-to-laserscan \
        ros-${ROS_DISTRO}-foxglove-bridge \
        ros-${ROS_DISTRO}-tf-transformations \
        ros-${ROS_DISTRO}-xacro \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 7. Finalization
# This steps should theoretically help cleaning unecessary post-build files that are already installed and that can be eventually re-generated
RUN rm -rf ${PROJECTS_DIR}/robotology-superbuild/build/src &&\
    echo "source ${INSTALL_DIR}/share/robotology-superbuild/setup.sh" >> $ROBOTOLOGY_INITIALIZATION_FILE

#The EXPOSE instruction does not actually publish the port.
#It functions as a type of documentation between the person who builds the image and the person who runs the container, about which ports are intended to be published.
#To actually publish the port when running the container, use the -p flag on docker run to publish and map one or more ports, or the -P flag to publish all exposed ports and map them to high-order ports.
EXPOSE 10000/tcp 10000/udp

# Some QT-Apps don't show controls without this
ENV QT_X11_NO_MITSHM=1
ENV YARP_COLORED_OUTPUT=1

RUN echo 'echo 'This images has release=$release and is built with superbuild_tag=$sbtag. Metadata=$metadata' '  >> ${METADATA_FILE} &&\
    echo "source ${METADATA_FILE}" >> ${ROBOTOLOGY_INITIALIZATION_FILE} &&\
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >>  ${ROBOTOLOGY_INITIALIZATION_FILE} 

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

CMD ["bash"]

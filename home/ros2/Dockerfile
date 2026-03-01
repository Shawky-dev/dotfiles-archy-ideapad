FROM osrf/ros:jazzy-desktop-full

RUN apt update && apt install -y \
    ros-jazzy-turtlebot3* \
    ros-jazzy-ros-gz \
    ros-jazzy-ros-gz-sim \
 && rm -rf /var/lib/apt/lists/*

ENV TURTLEBOT3_MODEL=burger
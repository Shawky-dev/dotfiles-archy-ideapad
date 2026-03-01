source /opt/ros/jazzy/setup.bash

# overlay workspace if built
if [ -f /ros2/ws/install/setup.bash ]; then
    source /ros2/ws/install/setup.bash
fi

export TURTLEBOT3_MODEL=burger
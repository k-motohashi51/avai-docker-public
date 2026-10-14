# AVAI on Apple Silicon — public image build

An unofficial ROS 2 Humble / Gazebo Fortress desktop for the RUB AVAI lab.
This builds a new image from public sources and a small set of configuration files.
It does not copy the previous working container or your Mac home folder.

**Status:** published on [Docker Hub](https://hub.docker.com/r/k0ichi/avai-humble).
Tested on an M2 Mac: turtlesim movement, car WASD control, LiDAR at about 20 Hz
with finite distance readings, and Gazebo startup after restarting the container.
This covers basic simulation checks, not every course task.

## Use the ready-made image

Open Docker Desktop, then run in your Mac terminal:

```bash
docker pull --platform linux/arm64 k0ichi/avai-humble:humble-arm64-20261014
docker run -d --name avai-humble --platform linux/arm64 \
  -p 127.0.0.1:6080:80 --shm-size=512m \
  k0ichi/avai-humble:humble-arm64-20261014
```

Open http://127.0.0.1:6080/ and click Connect. The desktop password is `ubuntu`.
Keep the port bound to localhost. Run the creation command only once; next time,
use `docker start avai-humble`. Stop it with `docker stop avai-humble`.
Saved files remain in the container, but deleting the container removes files
stored only inside it. Start ROS/Gazebo programs again after resuming.

The [Docker Hub overview](https://hub.docker.com/r/k0ichi/avai-humble)
has the quick walkthrough for turtlesim, driving, and LiDAR.

Published tag: `humble-arm64-20261014` (ARM64; no `latest` tag).
Manifest digest: `sha256:23a476faa2ad40812785ae5a0a05a91b0ceafeb0f2d3e6bbde77f3c774944a63`.


## Build (Mac Terminal)

Open Docker Desktop first.

```bash
git clone https://github.com/k-motohashi51/avai-docker-public.git
cd avai-docker-public
docker build --platform linux/arm64 -t avai-humble:public-test .
```

The first build downloads and compiles packages, so allow time and disk space.
The base image and AVAI source commit are fixed. Python compatibility constraints
are included, but apt packages and all transitive dependencies are not fully locked.

## Try it without replacing your existing container

```bash
docker run -d --name avai-public-test --platform linux/arm64 \
  -p 127.0.0.1:6081:80 --shm-size=512m avai-humble:public-test
```

Open http://127.0.0.1:6081/ and connect. This test uses a separate name and port.
The desktop's upstream default account is ubuntu, with password ubuntu;
keep the browser port bound to localhost as shown.

## Start Gazebo (Ubuntu terminal)

```bash
source /opt/ros/humble/setup.bash
source ~/avai-autonomous-race-car/race_car_ws/install/setup.bash
export IGN_GAZEBO_RESOURCE_PATH="$HOME/avai-autonomous-race-car/race_car_ws/src/gazebo/gazebo_f110/model"
ros2 launch gazebo_f110 gazebo_min.launch.py world:=circle
```

Press Play. In a second Ubuntu terminal:

```bash
source /opt/ros/humble/setup.bash
source ~/avai-autonomous-race-car/race_car_ws/install/setup.bash
ros2 run test_package wasd_control_node
```

Try w, w+a, and w+d briefly; release the keys to stop.
The speed is 0.5 m/s. Stop the WASD program with Ctrl+C before typing other commands;
its listener also sees keyboard input in other Ubuntu windows.

## Checks for future builds

- Task 1: turtlesim opens and responds to its arrow-key teleop program.
- Task 2: the car and cones appear; forward, left, right, and stopping work.
- LiDAR: `ros2 topic hz /scan` receives scans; `ros2 topic echo /scan --once` shows finite distances.
- In Visualize lidar, refresh, choose /scan, and turn off Show Non Hitting Rays.
- Stop/start the test container and check the launch again.
- Review the final image contents and bundled third-party license obligations before pushing.

Repeat these checks when changing the recipe. The published version passed the basic
checks listed above; the full course workflow and other Macs have not been tested.
The GitHub README may receive documentation updates after an image is published;
the README bundled inside a published image reflects its build time.

## Notes about the recipe

- The ubuntu account is created during the build; desktop startup reuses it.
- test_m2p is an unresolved test-only rosdep key in the pinned course source; it is skipped.
- Updated Python build tools and --no-build-isolation handle the course package's pyproject.toml.
- NumPy 1.24.4 is kept compatible with Ubuntu's SciPy 1.8.0.
- The minimal launch avoids the full launch's extra autonomy nodes and developer-specific map path.
- The source tree stays editable inside the container; its .git directory is removed.
- No Docker Hub credentials or workstation files are build inputs.
- ARM64 only; Intel Macs and GPU passthrough have not been tested.

## Upstream credits

- [AVAI course repository](https://github.com/isselab/avai-autonomous-race-car), MIT.
  Commit: d52fc0a2a225eea173fac7af79217420a7bee514.
  Its license and source files remain under /home/ubuntu/avai-autonomous-race-car.
- [Tiryoh/docker-ros2-desktop-vnc](https://github.com/Tiryoh/docker-ros2-desktop-vnc),
  Apache-2.0 for that repository. The image includes Ubuntu, ROS, Gazebo and other
  software with their own licenses; this README does not relicense those components.
  Preserve their copyright notices and license files when distributing.

This is a community setup, not an official RUB or Docker image.

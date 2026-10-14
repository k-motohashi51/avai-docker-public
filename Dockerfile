FROM tiryoh/ros2-desktop-vnc:humble@sha256:42d777e03d548352514d2dfbfcd10e869950dd909af653d7c6f8172a6129c753

LABEL org.opencontainers.image.title="AVAI Humble desktop for Apple Silicon" \
      org.opencontainers.image.description="Unofficial AVAI simulation environment. See /opt/avai/README.md for usage and upstream credits."

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       git python3-pip python3-scipy ros-humble-ros-gz \
    && rm -rf /var/lib/apt/lists/*

# The base image normally creates this account only at container startup.
RUN useradd --create-home --shell /bin/bash --user-group --groups adm,sudo ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/avai-ubuntu \
    && chmod 0440 /etc/sudoers.d/avai-ubuntu \
    && python3 - <<'PYENTRY'
from pathlib import Path
entry = Path('/entrypoint.sh')
s = entry.read_text()
old = '    useradd --create-home --shell /bin/bash --user-group --groups adm,sudo $USER'
assert s.count(old) == 1, 'Unexpected upstream user creation command'
s = s.replace(old, '    id -u "$USER" >/dev/null 2>&1 || useradd --create-home --shell /bin/bash --user-group --groups adm,sudo "$USER"')
entry.write_text(s)
PYENTRY

ARG AVAI_COMMIT=d52fc0a2a225eea173fac7af79217420a7bee514
USER ubuntu
WORKDIR /home/ubuntu
RUN git init avai-autonomous-race-car \
    && cd avai-autonomous-race-car \
    && git remote add origin https://github.com/isselab/avai-autonomous-race-car.git \
    && git fetch --depth 1 origin "${AVAI_COMMIT}" \
    && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "${AVAI_COMMIT}" \
    && printf '%s\n' "${AVAI_COMMIT}" > AVAI_SOURCE_COMMIT \
    && rm -rf .git

RUN rosdep update --rosdistro humble \
    && sudo apt-get update \
    && rosdep install \
       --from-paths /home/ubuntu/avai-autonomous-race-car/race_car_ws/src \
       --ignore-src --rosdistro humble --skip-keys test_m2p -y \
    && sudo rm -rf /var/lib/apt/lists/*

ENV PATH="/home/ubuntu/.local/bin:${PATH}"
RUN python3 -m pip install --user --no-cache-dir \
      "pip==26.2.1" "setuptools==79.0.1" "packaging==26.3" "wheel==0.48.0"

COPY --chown=ubuntu:ubuntu python-constraints.txt /tmp/avai-python-constraints.txt
RUN python3 -m pip install --user --no-cache-dir --no-build-isolation \
      --constraint /tmp/avai-python-constraints.txt \
      "numpy==1.24.4" -e /home/ubuntu/avai-autonomous-race-car/avai_lab

COPY --chown=ubuntu:ubuntu buggy-busters-config.toml /home/ubuntu/buggy-busters-config.toml

WORKDIR /home/ubuntu/avai-autonomous-race-car/race_car_ws
RUN source /opt/ros/humble/setup.bash \
    && colcon build --symlink-install --executor sequential \
    && python3 -c "import numpy, scipy; import avai_lab.config; import avai_lab.utils; assert numpy.__version__ == '1.24.4'" \
    && rm -rf log /home/ubuntu/.cache/pip /tmp/avai-python-constraints.txt

COPY README.md /opt/avai/README.md

# The upstream desktop startup needs root. Keep its original ENTRYPOINT and CMD.
USER root
WORKDIR /

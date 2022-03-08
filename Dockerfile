ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

RUN apt-get update && \
    apt-get install -y \
      wget \
      python3.9 \
      # python3.9-distutils is required to install pip
      # it unfortunately has to install python3.8-minimal as well...
      python3.9-distutils \
      # python-is-python3 creates a symlink for python to python3
      python-is-python3 && \
    rm -rf /var/lib/apt/lists/*

# Set python3 to python3.9 (otherwise, it will be python3.8)
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

# Never use a cache directory for pip, both here in this Dockerfile
# and when we run the container.
ENV PIP_NO_CACHE_DIR=1

# Install and upgrade pip
RUN wget -q -O- https://bootstrap.pypa.io/get-pip.py | python3.9 && \
    pip install -U pip

# Install launcher app
RUN pip install trame-launcher-nomad

ENTRYPOINT ["trame-launcher-nomad"]
# syntax=docker/dockerfile:1

# HOST machine needs nvidia drivers installed and nvidia-container-* packages:
# https://docs.docker.com/config/containers/resource_constraints/#gpu
#
# BUILD: in order to build this dockerfile it is required that the nvidia-container-runtime
#        is properly declared in /etc/docker/daemon.json: https://github.com/nvidia/nvidia-container-runtime#installation
#
# RUN: in order to run the resulting image add the --gpus flag 
#      to allow gpus usage inside a docker container:
#      example: docker run --gpus all ...

# from the nvidia NGC container with Ubuntu 16.04, python 3.6, pytorch 0.4.1 and CUDA 9.0.176:
# https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/rel_18.08.html
FROM nvcr.io/nvidia/pytorch:18.08-py3

# setting bash shell, allows 'source' command
SHELL ["/bin/bash", "-c"]

# update conda to get rid of the InvalidVersionSpecError:
# https://github.com/conda/conda/issues/10618
RUN conda install -v --channel defaults conda python=3.6 --yes
RUN conda update --channel defaults --all --yes

# cloning repo with '-std=c++11' added on setup scripts
RUN git clone https://github.com/leCaTo/GenRe-ShapeHD.git
WORKDIR GenRe-ShapeHD

# clearing PYTHONPATH as conda do not uses it
# and might bring package resolution problems 
ENV PYTHONPATH=
RUN conda init bash

# create shaperecon env
RUN conda env create -f environment.yml

# RUN commands start a new subshell everytime and 'conda activate' has no effect
# override shell for conda environment prefix on every subsequent run commands
SHELL ["conda", "run", "-n", "shaperecon", "/bin/bash", "-c"]

# building genre and shapehd
RUN ./install_trimesh.sh
RUN ./build_toolbox.sh

# download genre and shapehd pre-trained models
RUN wget http://genre.csail.mit.edu/downloads/genre_shapehd_models.tar -P downloads/models/ \
    && tar -xvf downloads/models/genre_shapehd_models.tar -C downloads/models/

# test setup and trigger resnet model download
RUN ./scripts/test_genre.sh 0
RUN ./scripts/test_shapehd.sh 0

SHELL ["/bin/bash", "-c"]

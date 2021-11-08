FROM jupyter/minimal-notebook:ubuntu-20.04 as service-base

# TODO: Newest image does not build well jupyterlab extensions
## ARG JUPYTER_MINIMAL_VERSION=54462805efcb@sha256:41c266e7024edd7a9efbae62c4a61527556621366c6eaad170d9c0ff6febc402

LABEL maintainer="KZzizzle" \
    org.opencontainers.image.authors="Benjamin D. Evans" \
    org.opencontainers.image.url="https://github.com/Chaste/chaste-docker" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.title="Chaste Docker Image" \
    org.opencontainers.image.description="Chaste: Cancer, Heart and Soft Tissue Environment" \
    org.opencontainers.image.documentation="http://www.cs.ox.ac.uk/chaste/"

ENV JUPYTER_ENABLE_LAB="yes"
ENV NOTEBOOK_TOKEN="simcore"
ENV NOTEBOOK_BASE_DIR="$HOME/work"

USER root

# ffmpeg for matplotlib anim & dvipng for latex labels
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg \
    dvipng \
    apt-utils \
    apt-transport-https \
    ca-certificates \
    gnupg \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install the Chaste repo list and key
# https://chaste.cs.ox.ac.uk/trac/wiki/InstallGuides/UbuntuPackage
RUN echo "deb http://www.cs.ox.ac.uk/chaste/ubuntu focal/" >> /etc/apt/sources.list.d/chaste.list && \
  apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 422C4D99

RUN pip --no-cache --quiet install --upgrade \
      pip \
      setuptools \
      wheel

# Install dependencies with recommended, applicable suggested and other useful packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    chaste-dependencies \
    cmake \
    scons \
    libvtk7-dev \
    python3-dev \
    python3-venv \
    python3-pip \
    python3-setuptools \
    git \
    valgrind \
    "libpetsc-real*-dbg" \
    # libfltk1.1 \
    hdf5-tools \
    cmake-curses-gui \
    libgoogle-perftools-dev \
    doxygen \
    graphviz \
    gnuplot \
    sudo \
    nano \
    curl \
    wget \
    rsync \
    mencoder \
    mplayer && \
    rm -rf /var/lib/apt/lists/*

# Fix CMake warnings: https://github.com/autowarefoundation/autoware/issues/795
RUN update-alternatives --install /usr/bin/vtk vtk /usr/bin/vtk7 7

# Update system to use Python3 by default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
RUN pip install --upgrade pip

# Install TextTest for regression testing (this requires pygtk)
RUN pip install texttest
ENV TEXTTEST_HOME /usr/local/bin/texttest


# Allow CHASTE_DIR to be set at build time if desired
ARG CHASTE_DIR="/home/jovyan/chaste"
ENV CHASTE_DIR=${CHASTE_DIR}


# Add scripts
COPY --chown=$NB_UID:$NB_UID kernels/chaste/scripts "${CHASTE_DIR}/scripts"
# WORKDIR ${CHASTE_DIR}
ENV PATH "${CHASTE_DIR}/scripts:${PATH}"

# Set environment variables
# RUN source /home/chaste/scripts/set_env_vars.sh
ENV CHASTE_SOURCE_DIR="${CHASTE_DIR}/src" \
    CHASTE_BUILD_DIR="${CHASTE_DIR}/lib" \
    CHASTE_PROJECTS_DIR="${CHASTE_DIR}/src/projects" \
    CHASTE_TEST_OUTPUT="${CHASTE_DIR}/testoutput"

# CMake environment variables
ARG CMAKE_BUILD_TYPE="Release"
ARG Chaste_ERROR_ON_WARNING="OFF"
ARG Chaste_UPDATE_PROVENANCE="OFF"
ENV CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    Chaste_ERROR_ON_WARNING=${Chaste_ERROR_ON_WARNING} \
    Chaste_UPDATE_PROVENANCE=${Chaste_UPDATE_PROVENANCE}

# Create Chaste build, projects and output folders
RUN mkdir -p "${CHASTE_SOURCE_DIR}" "${CHASTE_BUILD_DIR}" "${CHASTE_TEST_OUTPUT}" && \
    chown -R $NB_UID:$NB_UID ${CHASTE_DIR}

USER $NB_UID

CMD ["bash"]

# jupyter customizations
RUN conda install --quiet --yes \
    'jupyterlab-git~=0.20.0' \
    && \
    conda clean --all -f -y && \
    # lab extensions
    # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
    jupyter labextension install @jupyter-widgets/jupyterlab-manager@^2.0.0 --no-build && \
    # https://github.com/matplotlib/ipympl
    jupyter labextension install jupyter-matplotlib@^0.7.2 --no-build && \
    # https://www.npmjs.com/package/jupyterlab-plotly
    jupyter labextension install jupyterlab-plotly@^4.8.1 --no-build &&\
    # ---
    jupyter lab build -y && \
    jupyter lab clean -y && \
    npm cache clean --force && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER


# sidecar functionality -------------------------------------

# set up oSparc env variables
ENV INPUTS_FOLDER="${NOTEBOOK_BASE_DIR}/inputs" \
  OUTPUTS_FOLDER="${NOTEBOOK_BASE_DIR}/outputs" \
  SIMCORE_NODE_UUID="-1" \
  SIMCORE_USER_ID="-1" \
  SIMCORE_NODE_BASEPATH="" \
  SIMCORE_NODE_APP_STATE_PATH="${NOTEBOOK_BASE_DIR}" \
    STORAGE_ENDPOINT="-1" \
    S3_ENDPOINT="-1" \
    S3_ACCESS_KEY="-1" \
    S3_SECRET_KEY="-1" \
    S3_BUCKET_NAME="-1" \
    POSTGRES_ENDPOINT="-1" \
    POSTGRES_USER="-1" \
    POSTGRES_PASSWORD="-1" \
    POSTGRES_DB="-1"

# Copying boot scripts
COPY --chown=$NB_UID:$NB_GID docker /docker

# Copying packages/common
COPY --chown=$NB_UID:$NB_GID packages/jupyter-commons /packages/jupyter-commons
COPY --chown=$NB_UID:$NB_GID packages/jupyter-commons/common_jupyter_notebook_config.py /home/$NB_USER/.jupyter/jupyter_notebook_config.py
COPY --chown=$NB_UID:$NB_GID packages/jupyter-commons/state_puller.py /docker/state_puller.py

# Installing all dependences to run handlers & remove packages
RUN pip install /packages/jupyter-commons
USER root
RUN rm -rf /packages
USER $NB_USER

ENV PYTHONPATH="/src:$PYTHONPATH"
RUN mkdir --parents --verbose "${INPUTS_FOLDER}"; \
  mkdir --parents --verbose "${OUTPUTS_FOLDER}/output_1" \
  mkdir --parents --verbose "${OUTPUTS_FOLDER}/output_2" \
  mkdir --parents --verbose "${OUTPUTS_FOLDER}/output_3" \
  mkdir --parents --verbose "${OUTPUTS_FOLDER}/output_4"

EXPOSE 8888

ENTRYPOINT [ "/bin/bash", "/docker/run.bash" ]

# --------------------------------------------------------------------
FROM service-base as service-with-kernel

# Install kernel in virtual-env
ENV HOME="/home/$NB_USER"

USER root

# TODO: [optimize] install/uninstall in single run when used only?
RUN apt-get update \
  && apt-get install -yq --no-install-recommends \
    zip \
    unzip \
  && apt-get clean && rm -rf /var/lib/apt/lists/* 

RUN conda install --quiet --yes \
  'texinfo' \
  'xeus-cling=0.13.0' \
  'xtensor=0.23.10' \
  'notebook=6.4.4' \
  && \
  conda update -y --force conda && \
  conda clean -tipsy && \
  jupyter lab build -y && \
  # fix-permissions $CONDA_DIR && \
  fix-permissions /home/$NB_USER

USER $NB_UID

# Building Chaste
WORKDIR ${CHASTE_DIR}
RUN build_chaste.sh && \
  ln -s ${CHASTE_DIR}/src/projects/ ${NOTEBOOK_BASE_DIR} && \
  ln -s ${CHASTE_DIR}/testoutput/ ${NOTEBOOK_BASE_DIR}

WORKDIR ${NOTEBOOK_BASE_DIR}

COPY --chown=$NB_UID:$NB_GID CHANGELOG.md ${NOTEBOOK_BASE_DIR}/CHANGELOG.md





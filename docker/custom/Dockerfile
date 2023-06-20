ARG JUPYTER_MINIMAL_VERSION=lab-3.3.2@sha256:a4bf48221bfa864759e0f248affec3df1af0a68ee3e43dfc7435d84926ec92e8
FROM jupyter/minimal-notebook:${JUPYTER_MINIMAL_VERSION}

# From https://github.com/Chaste/chaste-docker/blob/master/Dockerfile
LABEL maintainer="elisabettai" \
    author.orcid="https://orcid.org/0000-0002-1734-6070" \
    image.publication="https://doi.org/10.21105/joss.01848" \
    org.opencontainers.image.authors="Benjamin D. Evans" \
    org.opencontainers.image.url="https://github.com/Chaste/chaste-docker" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.title="Chaste Docker Image" \
    org.opencontainers.image.description="Chaste: Cancer, Heart and Soft Tissue Environment" \
    org.opencontainers.image.documentation="http://www.cs.ox.ac.uk/chaste/"


ENV JUPYTER_ENABLE_LAB="yes"
# autentication is disabled for now
ENV NOTEBOOK_TOKEN=""
ENV NOTEBOOK_BASE_DIR="$HOME/work"

USER root

# Usual oSPARC JupyterLab dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  gfortran \
  ffmpeg \
  make \
  gnupg \
  dvipng \
  gosu \
  gnuplot \
  liboctave-dev \
  bc \
  curl \
  ghostscript \
  texlive-xetex \
  texlive-fonts-recommended \
  texlive-latex-recommended \
  texlive-fonts-extra \
  zip \
  fonts-freefont-otf \
  && \
  apt-get clean && rm -rf /var/lib/apt/lists/* 

# Install the Chaste repo list and key
# https://chaste.cs.ox.ac.uk/trac/wiki/InstallGuides/UbuntuPackage
RUN echo "deb [signed-by=/usr/share/keyrings/chaste.asc] http://www.cs.ox.ac.uk/chaste/ubuntu focal/" >> /etc/apt/sources.list.d/chaste.list
RUN wget -O /usr/share/keyrings/chaste.asc https://www.cs.ox.ac.uk/chaste/ubuntu/Chaste%20Team.asc

# From chaste-docker: Add signing key to install GitHub CLI
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Install dependencies with recommended, applicable suggested and other useful packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    chaste-dependencies \
    cmake \
    libvtk7-dev \
    python3-dev \
    python3-venv \
    python3-pip \
    python3-setuptools \
    gh \
    git \
    valgrind \
    "libpetsc-real*-dbg" \
    hdf5-tools \
    cmake-curses-gui \
    libgoogle-perftools-dev \
    doxygen \
    graphviz \
    gnuplot \
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

# Installed by CMake
RUN pip install chaste-codegen

ARG TODO-remove=""

# Allow CHASTE_DIR to be set at build time if desired
ARG CHASTE_DIR="/home/jovyan/chaste"
ENV CHASTE_DIR=${CHASTE_DIR}
WORKDIR ${CHASTE_DIR}


RUN apt-cache show chaste-dependencies > chaste-dependencies.txt

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

ENV PYTHONPATH="${CHASTE_BUILD_DIR}/python:$PYTHONPATH"


# Create Chaste build, projects and output folders
RUN mkdir -p "${CHASTE_SOURCE_DIR}" "${CHASTE_BUILD_DIR}" "${CHASTE_TEST_OUTPUT}" "${CHASTE_PROJECTS_DIR}" && \
    chown -R $NB_UID:$NB_UID ${CHASTE_DIR}

USER $NB_UID


RUN git config --global --add safe.directory "${CHASTE_SOURCE_DIR}"

RUN ctest --verbose -R TestChasteBuildInfo$

# Building Chaste

# Build Chaste: GIT_TAG can be a branch or release ('-' skips by default)
WORKDIR ${CHASTE_DIR}
ARG GIT_TAG=-
ENV GIT_TAG=${GIT_TAG}
RUN build_chaste.sh ${GIT_TAG}

# --------------------------------------------------------------------

# Install Python kernel in virtual-env
ENV HOME="/home/$NB_USER"

USER root

WORKDIR ${HOME}

RUN python -m venv .venv &&\
  .venv/bin/pip --no-cache --quiet install --upgrade pip~=21.3 wheel setuptools &&\
  .venv/bin/pip --no-cache --quiet install ipykernel &&\
  .venv/bin/python -m ipykernel install \
  --user \
  --name "python-maths" \
  --display-name "python (maths)" \
  && \
  echo y | .venv/bin/python -m jupyter kernelspec uninstall python3 &&\
  .venv/bin/python -m jupyter kernelspec list

# copy and resolve dependecies to be up to date
COPY --chown=$NB_UID:$NB_GID kernels/python-maths/requirements.txt ${NOTEBOOK_BASE_DIR}/requirements.txt
RUN .venv/bin/pip --no-cache install pip-tools && \
  .venv/bin/pip --no-cache install -r ${NOTEBOOK_BASE_DIR}/requirements.txt

RUN jupyter serverextension enable voila && \
  jupyter server extension enable voila

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg .venv/bin/python -c "import matplotlib.pyplot" 

# Install C++ kernels in Jupyterlab, see https://github.com/jupyter-xeus/xeus-cling
RUN mamba install -y -c conda-forge \
   xeus-cling=0.15.1 \
   xtensor=0.23.10 \
   texinfo

RUN fix-permissions /home/$NB_USER/.local/share/jupyter && \
     fix-permissions /home/$NB_USER/.ipython
#RUN fix-permissions /home/$NB_USER
#   # run fix permissions only once. This can be probably optimized, so it is faster to build

# copy README and CHANGELOG
COPY --chown=$NB_UID:$NB_GID CHANGELOG.md ${NOTEBOOK_BASE_DIR}/CHANGELOG.md
COPY --chown=$NB_UID:$NB_GID README.ipynb ${NOTEBOOK_BASE_DIR}/README.ipynb
# remove write permissions from files which are not supposed to be edited
RUN chmod gu-w ${NOTEBOOK_BASE_DIR}/CHANGELOG.md && \
  chmod gu-w ${NOTEBOOK_BASE_DIR}/requirements.txt

RUN mkdir --parents "/home/${NB_USER}/.virtual_documents" && \
  chown --recursive "$NB_USER" "/home/${NB_USER}/.virtual_documents"
ENV JP_LSP_VIRTUAL_DIR="/home/${NB_USER}/.virtual_documents"

# Copying boot scripts
COPY --chown=$NB_UID:$NB_GID docker /docker

RUN echo 'export PATH="/home/${NB_USER}/.venv/bin:$PATH"' >> "/home/${NB_USER}/.bashrc"

EXPOSE 8888

ENTRYPOINT [ "/bin/bash", "/docker/entrypoint.bash" ]
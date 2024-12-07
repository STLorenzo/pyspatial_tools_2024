##############
# BASE
##############

# Use the official Python image as the base image
ARG PYTHON_VERSION=3.13
FROM python:${PYTHON_VERSION} AS base

# Install OS libraries
RUN apt-get update && apt-get install -y awscli

# Update pip and Install Uv
RUN pip install pip --upgrade && pip install uv

ARG install_dir=/tmp/install

ARG JDK_VERSION
# ---------- INSTALL System Libraries ----------
# Needed for Pyspark
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  sudo \
  openjdk-${JDK_VERSION}-jdk \
  build-essential \
  software-properties-common \
  openssh-client openssh-server \
  gdal-bin \
  libgdal-dev \
  ssh \
  wget

# ---------- SPARK ----------
# Setup the directories for Spark/Hadoop installation
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}

# Create spark folder
RUN mkdir -p ${SPARK_HOME}
WORKDIR ${SPARK_HOME}

ARG SPARK_VERSION=3.5.3
# Download and install Spark
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz \
  && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
  && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz

ENV SPARK_VERSION=${SPARK_VERSION}

# ---------- SEDONA ----------
# Args
ARG SCALA_VERSION=2.12
ARG SEDONA_VERSION=1.7.0
ARG GEOTOOLS_WRAPPER_VERSION=28.2

ENV SCALA_VERSION=${SCALA_VERSION}
ENV SEDONA_VERSION=${SEDONA_VERSION}
ENV GEOTOOLS_WRAPPER_VERSION=${GEOTOOLS_WRAPPER_VERSION}

# Install sedona jars
COPY resources/scripts/install_sedona_jars.sh ${install_dir}/scripts/install_sedona_jars.sh
RUN ${install_dir}/scripts/install_sedona_jars.sh ${SPARK_VERSION} ${SCALA_VERSION} ${SEDONA_VERSION} ${GEOTOOLS_WRAPPER_VERSION} 

# ---------------------------------

# Install python dependencies
COPY pyproject.toml ${install_dir}/pyproject.toml
RUN uv pip install --system -r ${install_dir}/pyproject.toml

# -------- Cleanup -------
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -rf ${install_dir}

# -------- RUNTIME --------
# Set PYTHONPATH
ENV PATH="${PATH}:$SPARK_HOME/bin:$SPARK_HOME/sbin"
ENV PYTHONPATH=/opt/app
EXPOSE 4040
EXPOSE 18080

# Set working directory
WORKDIR /opt/app


##############
# DEV
##############
FROM base AS dev

# Install dev OS libs
RUN apt-get update && apt-get install -y git nano
ENV GIT_EDITOR=nano

# Set default user
ARG DOCKER_USER
RUN groupadd -r ${DOCKER_USER} && useradd -r -g ${DOCKER_USER} ${DOCKER_USER}

ARG install_dir=/tmp/install
# Install dev python dependencies
COPY pyproject.toml ${install_dir}/pyproject.toml
RUN uv pip install --system -r ${install_dir}/pyproject.toml --extra=dev

# -------- Cleanup --------
RUN apt-get clean && rm -rf /var/lib/apt/lists/*



##############
# DEV
##############
FROM base AS prod

COPY src/app /opt/app

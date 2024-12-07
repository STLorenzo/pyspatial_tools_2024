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
# Install python dependencies
COPY pyproject.toml ${install_dir}/pyproject.toml
RUN uv pip install --system -r ${install_dir}/pyproject.toml

# -------- Cleanup --------
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -rf ${install_dir}

# -------- RUNTIME --------
# Set PYTHONPATH
ENV PYTHONPATH=/opt/app

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

FROM jenkins/jenkins:2.528-jdk21

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends docker.io && \
    rm -rf /var/lib/apt/lists/*

USER jenkins
FROM ubuntu:18.04 as base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install systemd bash g++ cmake git default-jre curl apt-transport-https
# RUN apt-get install default-jre java-1.8.0-openjdk curl bash
ENV WORKSPACE /home/


# Default to UTF-8 file.encoding https://github.com/docker-library/openjdk/issues/32
ENV LANG C.UTF-8

# ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV JAVA_HOME /usr/lib/jvm/java-1.11.0-openjdk-amd64  
ENV PATH="$PATH:/usr/lib/jvm/java-1.11.0-openjdk-amd64/bin"

# RUN curl -o ./kafka_2.11-2.0.0.tgz http://mirrors.ocf.berkeley.edu/apache/kafka/2.0.0/kafka_2.11-2.0.0.tgz \
#     && tar -xzvf ./kafka_2.11-2.0.0.tgz \
#     && mv kafka_2.11-2.0.0.tgz /opt/kafka

# COPY . /home




RUN ["ls"]
FROM amazonlinux:latest

RUN yum update -y \
  && yum install -y autoconf \
    automake \
    bison \
    flex \
    gcc \
    gcc-c++ \
    gdbm-devel \
    gettext \
    git \
    kernel-devel \
    libffi-devel \
    libyaml-devel \
    m4 \
    make \
    ncurses-devel \
    openssl-devel \
    patch \
    readline-devel \
    rpm-b uild \
    sudo \
    wget \
    zlib-devel \
  && amazon-linux-extras install -y ruby2.4 \
  && groupadd ec2-user \
  && adduser -g ec2-user ec2-user \
  && groupadd omnibus \
  && adduser -g omnibus omnibus

COPY --chown=ec2-user:ec2-user RPM-chef-cinc-16.0.287.sh /tmp/install-cinc.sh
RUN chmod +x /tmp/install-cinc.sh

RUN echo 'omnibus  ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
RUN echo 'ec2-user  ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers

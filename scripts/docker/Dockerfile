FROM debian:stretch

ENV LOCALE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV USER=build

RUN id build 2>/dev/null || \
    useradd --uid 1000 --create-home --home-dir /home/build build

RUN mkdir /home/build/isar_build

RUN apt-get update && apt-get install -y locales && \
    sed -i -e "s/# $LOCALE.*/$LOCALE UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales

RUN apt-get -y install gawk wget git-core diffstat unzip \
                       texinfo gcc-multilib build-essential \
                       chrpath socat cpio python python3 \
                       libsdl1.2-dev xterm tar bzip2 curl \
                       dosfstools mtools parted syslinux tree \
                       python3-pip schroot dosfstools mtools multistrap \
                       sudo mtd-utils util-linux flex bison \
                       qemu-user-static dh-make device-tree-compiler bc \
                       u-boot-tools

RUN usermod -a -G sudo build
RUN chmod 0740 /etc/sudoers
RUN echo "%sudo ALL=NOPASSWD: ALL" >> /etc/sudoers
RUN chmod 0440 /etc/sudoers

ADD .gitconfig /home/build/
ADD .git-credentials /home/build

RUN chown build:build /home/build/.gitconfig /home/build/.git-credentials

USER build
WORKDIR /home/build/isar_build




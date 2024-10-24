FROM ubuntu:22.04

RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
    sed -i "s@http://.*\.ubuntu\.com@https://mirrors.aliyun.com@g" /etc/apt/sources.list

RUN apt update -o "Acquire::https::Verify-Peer=false" && \
    apt install -o "Acquire::https::Verify-Peer=false" -y ca-certificates 

# set TIMEZONE
ENV TZ="Asia/Shanghai"
RUN apt-get update && \
    apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# 中文支持
ENV LANG="zh_CN.UTF-8"
RUN apt-get update && \
    apt-get install -y locales locales-all && \
    locale-gen zh_CN.UTF-8

# 安装依赖，配置基本环境
RUN apt update && \
    apt-get install -y \
    curl \
    git \
    bash-completion \
    gawk \
    vim \
    locales \
    fzf \
    make \
    jq \
    build-essential 


# Create the user
# https://github.com/microsoft/vscode-remote-release/issues/7284
ARG USERNAME=vscode
ARG USER_UID=8888
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && groupdel users

RUN mkdir -p /opt

#######################
# install nodejs 
#######################

ARG NODEJS_VERSION=20.18.0
ENV PATH=/opt/node/bin:$PATH
RUN arch=$(uname -m) && \
    if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ] || echo "$arch" | grep -q "^arm"; then arch="arm64"; else arch="x86"; fi && \
    curl -LO https://mirrors.aliyun.com/nodejs-release/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.gz && \
    tar -xzvf node-v${NODEJS_VERSION}-linux-x64.tar.gz -C /opt && \
    ln -s /opt/node-v${NODEJS_VERSION}-linux-x64 /opt/node && \
    rm node-v${NODEJS_VERSION}-linux-x64.tar.gz
RUN npm config set registry https://registry.npmmirror.com && \
    mkdir -p /home/${USERNAME} && \
    cp ${HOME}/.npmrc /home/${USERNAME}/.npmrc
RUN npm install @serverless-devs/s3 -g --registry=https://registry.npmmirror.com


#######################
# install golang 
#######################

ENV GO_VERSION=1.21.11
ENV PATH=/opt/go/bin:$PATH
RUN if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ] || echo "$arch" | grep -q "^arm"; then arch="arm64"; else arch="amd64"; fi && \
    curl -LO "https://mirrors.aliyun.com/golang/go${GO_VERSION}.linux-${arch}.tar.gz" && \
    tar -xzf go${GO_VERSION}.linux-${arch}.tar.gz -C /opt && \
    mv /opt/go /opt/go-${GO_VERSION} && \
    ln -s /opt/go-${GO_VERSION} /opt/go && \
    rm go${GO_VERSION}.linux-${arch}.tar.gz
RUN go env -w "GOPRIVATE=*.alibaba-inc.com" && \
    go env -w "GOPROXY=https://mirrors.aliyun.com/goproxy/,direct" && \
    mkdir -p /home/${USERNAME}/.config/go && \
    cp /root/.config/go/env /home/${USERNAME}/.config/go/env 
RUN go install github.com/cweill/gotests/gotests@latest && \
    go install github.com/fatih/gomodifytags@latest && \
    go install github.com/josharian/impl@latest && \
    go install github.com/haya14busa/goplay/cmd/goplay@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install golang.org/x/lint/golint@latest && \
    go install golang.org/x/tools/gopls@latest && \
    go install github.com/rogpeppe/godef@latest && \
    go install github.com/vektra/mockery/v2@v2.43.2 && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest


#########################
# install Python and pip
#########################

ARG PYTHON_VERSION=3.10.9
ENV PATH=/opt/python/bin:$PATH
RUN apt update && \
    apt install -y \
    bzip2 \
    libbz2-dev \
    sqlite3 \
    libsqlite3-dev \
    libreadline-dev \
    libgdbm-dev \
    uuid-dev \
    tk-dev \
    libffi-dev \
    libncursesw5-dev \
    libssl-dev \
    libc6-dev
RUN curl -LO https://mirrors.aliyun.com/python-release/source/Python-${PYTHON_VERSION}.tgz && \
    tar xzvf Python-${PYTHON_VERSION}.tgz -C /opt && \
    cd /opt/Python-${PYTHON_VERSION} && \
    ./configure --prefix=/opt/python-${PYTHON_VERSION} --enable-optimizations && \
    make -j8 && \
    make install -j8 && \
    ln -s /opt/python-${PYTHON_VERSION}/ /opt/python && \
    rm -rf /opt/Python-${PYTHON_VERSION}.tgz Python-${PYTHON_VERSION} && \
    chmod 777 /opt/node/lib/node_modules /opt/node/bin
    RUN mkdir -p ${HOME}/.pip && \
    echo -e "[global]\nindex-url = http://mirrors.aliyun.com/pypi/simple/\n[install]\ntrusted-host=mirrors.aliyun.com\n" > ${HOME}/.pip/pip.conf && \ 
    mkdir -p /home/${USERNAME}/.pip

#######################
# chmod user
#######################
RUN chown -R ${USERNAME} /home/${USERNAME} && chown -R ${USERNAME} /home/${USERNAME}

#######################
# change user
#######################

USER ${USERNAME}

ENV TZ="Asia/Shanghai"
ENV LANG="zh_CN.UTF-8"

RUN curl -o ${HOME}/.bashrc -k \
    "https://proxy.ohyee.cc/gist.githubusercontent.com/OhYee/87228bbce831b4b7027e3d6407e7b2f8/raw/.bashrc"

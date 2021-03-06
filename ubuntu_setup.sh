#! /bin/bash

# Update and install packages
sudo apt update && sudo apt upgrade -y && \
sudo apt install -y python3 python3-dev python3-pip python3-venv \
    docker-compose htop tmux fonts-powerline build-essential libssl-dev \
    uuid-dev libgpgme11-dev squashfs-tools libseccomp-dev wget pkg-config git cryptsetup && \
sudo apt autoremove -y  && \
sudo apt clean -y  && \
sudo pip3 install flake8 autopep8 pytest

# Create a sudo user (josh)
adduser josh && usermod -aG sudo josh && \
    mkdir /home/josh/.ssh && cp /root/.ssh/authorized_keys /home/josh/.ssh && \
    sudo chown -R josh /home/josh/.ssh/authorized_keys && \
    sudo chgrp josh /home/josh/.ssh/authorized_keys && \
    sudo usermod -aG docker josh && \
    su josh && cd /home/josh

# Setup firewall
sudo ufw allow OpenSSH && \
    sudo ufw allow http && \
    sudo ufw allow https && \
    sudo ufw allow in on cni0 && sudo ufw allow out on cni0 && \
    sudo ufw default allow routed && \
    sudo ufw enable && \
    sudo ufw status

# Install base miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh --no-check-certificate && \
    bash miniconda.sh -b && rm miniconda.sh

# Install singularity
export VERSION=1.13 OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz && \
    echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc && \
    source ~/.bashrc && \
    export VERSION=3.5.2 && \
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz && \
    tar -xzf singularity-${VERSION}.tar.gz && \
    cd singularity && \
    ./mconfig && \
    make -C builddir && \
    sudo make -C builddir install && \
    cd && rm -rf singularity-3.5.2.tar.gz singularity/

# Setup tmux with oh my tmux
git clone https://github.com/gpakosz/.tmux.git && \
    ln -s -f .tmux/.tmux.conf && \
    cp .tmux/.tmux.conf.local .

# Install microk8s
sudo snap install microk8s --classic --channel=latest/stable && \
    sudo microk8s status --wait-ready && \
    sudo snap alias microk8s.kubectl kubectl && echo 'export PATH=$PATH:/snap/bin/' >> ~/.bashrc && \
    sudo usermod -a -G microk8s josh && sudo chown -f -R josh ~/.kube && \
    sudo microk8s enable dns storage ingress helm3 metrics-server dashboard && \
    sudo kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.2/cert-manager.crds.yaml && \
    sudo kubectl create namespace cert-manager && \
    sudo snap alias microk8s.helm3 helm3 && \
    sudo helm3 repo add jetstack https://charts.jetstack.io && sudo helm3 repo update && \
    sudo helm3 install cert-manager jetstack/cert-manager --namespace cert-manager --version v0.14.2 && \
    microk8s.config

# You can then use that config to reach the cluster remotely

# Can access the dashboard with...
# token=$(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
# microk8s kubectl -n kube-system describe secret $token
# microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443
# Go to https://localhost:10443 and use the token




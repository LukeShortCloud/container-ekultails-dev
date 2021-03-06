FROM debian:bullseye-20220328

ENV CODE_SERVER_VER="3.12.0"
ENV CMD_APT_INSTALL="apt-get install -y --no-install-recommends"

RUN apt-get update
# Install useful tools.
## 'sudo' is required for the TCE installer.
RUN ${CMD_APT_INSTALL} apt-file clamav clamav-freshclam jq less man-db mlocate software-properties-common sudo vim
# Install compression tools.
RUN ${CMD_APT_INSTALL} gzip zip zstd
# Install network tools.
RUN ${CMD_APT_INSTALL} curl dnsutils iproute2 iputils-ping netcat nmap openssh-client openssl wget
# Install programming languages and tools.
RUN ${CMD_APT_INSTALL} git git-review gcc golang make openjdk-11-jre-headless python3 python3-pip python3-virtualenv virtualenv
## GitHub CLI ('gh' command).
## https://github.com/cli/cli/blob/trunk/docs/install_linux.md
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >> /etc/apt/sources.list.d/github-cli.list && apt-get update && ${CMD_APT_INSTALL} gh
## Install programming language linters.
RUN ${CMD_APT_INSTALL} golint python3-pylint-common shellcheck
### golangci-lint, a more advanced Go linter.
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/v1.43.0/install.sh | sh -s -- -b /usr/local/bin v1.43.0
# Install ZSH.
RUN ${CMD_APT_INSTALL} zsh
ENV RUNZSH=no
RUN curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
# Install code-server (Microsoft Visual Studio Code).
RUN wget https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VER}/code-server_${CODE_SERVER_VER}_amd64.deb
RUN ${CMD_APT_INSTALL} ./code-server_${CODE_SERVER_VER}_amd64.deb
# Install Kubernetes tools.
## kubectl supports kube-apiserver versions that are 1 major version ahead and behind.
RUN wget https://dl.k8s.io/release/v1.19.16/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl-1.19 && chmod +x /usr/local/bin/kubectl-1.19
RUN wget https://dl.k8s.io/release/v1.22.9/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl-1.22 && chmod +x /usr/local/bin/kubectl-1.22
RUN ln -s /usr/local/bin/kubectl-1.22 /usr/local/bin/kubectl
### Autocompletion for 'kubectl'.
### https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/
RUN ${CMD_APT_INSTALL} bash-completion
RUN echo 'source /usr/share/bash-completion/bash_completion' >> /root/.bashrc
RUN echo 'source <(kubectl completion bash)' >> /root/.bashrc
### Krew.
RUN wget https://github.com/kubernetes-sigs/krew/releases/download/v0.4.2/krew-linux_amd64.tar.gz && tar -xvf krew-linux_amd64.tar.gz ./krew-linux_amd64 && mv ./krew-linux_amd64 /usr/local/bin/krew && chmod +x /usr/local/bin/krew
### Kustomize. This will install the latest version into the current working directory.
### https://kubectl.docs.kubernetes.io/installation/kustomize/binaries/
RUN cd /usr/local/bin/ && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
## Carvel/k14s tools for Kubernetes.
RUN wget -O- https://carvel.dev/install.sh | bash
## kpack-cli ('kp' command).
ENV KPACK_CLI_VER="0.5.0"
RUN wget https://github.com/vmware-tanzu/kpack-cli/releases/download/v${KPACK_CLI_VER}/kp-linux-${KPACK_CLI_VER} -O /usr/local/bin/kp && chmod +x /usr/local/bin/kp
## Helm for Kubernetes.
RUN wget -O- https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
## Knative client.
RUN wget https://github.com/knative/client/releases/download/knative-v1.1.0/kn-linux-amd64 -O /usr/local/bin/kn && chmod +x /usr/local/bin/kn
## Tanzu Community Edition (TCE).
ENV ALLOW_INSTALL_AS_ROOT=true TCE_VER=v0.11.0
RUN wget https://github.com/vmware-tanzu/community-edition/releases/download/${TCE_VER}/tce-linux-amd64-${TCE_VER}.tar.gz && tar -x -v -f tce-linux-amd64-${TCE_VER}.tar.gz && ./tce-linux-amd64-${TCE_VER}/install.sh
## kind.
ENV KIND_VER="v0.12.0"
RUN wget https://kind.sigs.k8s.io/dl/${KIND_VER}/kind-linux-amd64 -O /usr/local/bin/kind && chmod +x /usr/local/bin/kind
# Install the Docker Engine.
RUN ${CMD_APT_INSTALL} docker.io
# Cleanup.
RUN rm -rf ./code-server_${CODE_SERVER_VER}_amd64.deb ./krew-linux_amd64.tar.gz ./tce-linux-amd64-${TCE_VER} ./tce-linux-amd64-${TCE_VER}.tar.gz
RUN apt-get clean all

VOLUME ["/mnt"]

# code-server.
EXPOSE 2003

CMD code-server --bind-addr 0.0.0.0:2003

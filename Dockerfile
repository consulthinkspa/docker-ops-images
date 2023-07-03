FROM ubuntu:jammy
HEALTHCHECK --interval=30s --timeout=5s CMD echo "Hello World" || exit 1

LABEL "author"="Luca Capanna"
LABEL "licenze"="MIT License"
LABEL "image.version"="0.4.0"
LABEL "image.name"="lukecottage/ops-image"

ENV PATH $PATH:/home/linuxbrew/.linuxbrew/bin

USER root

# KICS envs
ARG KICS_URL=https://github.com/Checkmarx/kics.git
ARG KICS_VERSION=v1.5.5
ENV KICS_HOME=/opt/kics

# Sonar scanner envs
ARG SONAR_SCANNER_URL=https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
ARG SONAR_SCANNER_ASC=https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip.asc
ARG SONAR_SCANNER_PUBKEY=https://binaries.sonarsource.com/sonarsource-public.key
ENV SONAR_SCANNER_HOME=/usr/local/sonar-scanner
ENV SONAR_USER_HOME=${SONAR_SCANNER_HOME}/.sonar

# Dependency-Check envs
ARG DEPENDENCY_CHECK_URL=https://github.com/jeremylong/DependencyCheck/releases/download/v8.3.1/dependency-check-8.3.1-release.zip
ARG DEPENDENCY_CHECK_ASC=https://github.com/jeremylong/DependencyCheck/releases/download/v8.3.1/dependency-check-8.3.1-release.zip.asc
ENV DEPENDENCY_CHECK_HOME=/usr/local/dependency-check

# GOlang envs
ARG GOLANG_URL=https://go.dev/dl/go1.20.5.linux-amd64.tar.gz
ARG GOLANG_SHA256SUM=d7ec48cde0d3d2be2c69203bc3e0a44de8660b9c09a6e85c4732a3f7dc442612

# System envs
ENV PATH=${JAVA_HOME}/bin:${GOLANG_HOME}/bin:${SONAR_SCANNER_HOME}/bin::${DEPENDENCY_CHECK_HOME}/bin:${DEPENDENCY_CHECK_HOME}/bin:${KICS_HOME}/bin:${PATH}
ENV JAVA_HOME=/usr/local/openjdk-11
#${NODEJS_HOME}/bin
#ENV NODE_PATH=${NODEJS_HOME}/lib/node_modules
ENV SRC_PATH=/usr/src
ENV XDG_CONFIG_HOME=/tmp

# init
WORKDIR /opt
RUN mkdir -p /opt/scripts
COPY ./scripts/* /opt/scripts/
RUN chmod a+x /opt/scripts/*

# Workout TZ database setup
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Minimum requirements
RUN apt-get update
RUN /opt/scripts/requirements.sh

# Install Azure CLI
RUN /opt/scripts/install_azurecli.sh

# Install GOlang
RUN /opt/scripts/install_golang.sh $GOLANG_URL

# Install KICS
RUN /opt/scripts/install_kics.sh $KICS_URL $KICS_VERSION

# Install OWASP Dependency-Check
RUN /opt/scripts/install_dependency-check.sh $DEPENDENCY_CHECK_URL $DEPENDENCY_CHECK_HOME

# Install Sonarqube Scanner
RUN /opt/scripts/install_sonar-scanner.sh $SONAR_SCANNER_URL $SONAR_SCANNER_HOME $SONAR_SCANNER_ASC $SONAR_SCANNER_PUBKEY

# Install Chef InSpec
RUN /opt/scripts/install_inspec.sh

# Install kubernetes CLI (and utilies/plugins)
RUN /opt/scripts/install_kubectl.sh

# Install Helm CLI
RUN /opt/scripts/install_helm.sh

# Install FluxCD CLI
RUN /opt/scripts/install_fluxcd.sh

# Install Azure CLI
RUN /opt/scripts/install_azurecli.sh

# Create OPS user and workspace
RUN useradd -rm -d /home/operator -s /bin/bash -g root -G sudo -u 1042 operator
#RUN useradd -ms /bin/bash operator
RUN mkdir -p /workspace && chown operator -R /workspace

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ending
USER operator
WORKDIR /workspace
CMD ["/bin/bash"]

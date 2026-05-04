FROM jenkins/jenkins:2.541.3-lts-jdk17

# OCI Metadata Labels
LABEL org.opencontainers.image.title="Jenkins Controller (JCasC + Conjur)"
LABEL org.opencontainers.image.authors="Assaf Hazan"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Custom Jenkins Controller with JCasC and CyberArk Conjur integration"
LABEL org.opencontainers.image.licenses="MIT"

# Disable setup wizard  
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Set CASC path OUTSIDE of the jenkins_home volume to prevent masking
ENV CASC_JENKINS_CONFIG="/usr/share/jenkins/ref/casc.yml"

# Install plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt --verbose

# Copy CASC config to the reference directory
COPY casc.yml /usr/share/jenkins/ref/casc.yml
FROM debian:stable-slim

ENV DOWNLOAD_URL https://download.unimus.net/unimus/-%20Latest/Unimus.jar

RUN apt-get update && apt-get install -y curl vim less wget tzdata

#
# Unimus
RUN curl -L -o /opt/unimus.jar $DOWNLOAD_URL
# JDK install and check
RUN apt-get install -y openjdk-11-jdk-headless && \
    jarsigner -verify /opt/unimus.jar | grep -i "jar verified" || { echo "Unimus binary is not verified"; exit 1; } && \
    apt-get purge -y openjdk-11-jdk-headless
# JRE install
RUN apt-get install -y openjdk-11-jre-headless && \
    wget -O /opt/elastic-apm-agent.jar https://repo1.maven.org/maven2/co/elastic/apm/elastic-apm-agent/1.32.0/elastic-apm-agent-1.32.0.jar
#
# Start script
COPY files/start.sh /opt/start.sh
RUN chmod 755 /opt/start.sh
#
ENTRYPOINT /opt/start.sh

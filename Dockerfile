# Nest Data Collector
#
# VERSION               2.2.1
#
# RUN THE CONTAINER WITH THE FOLLOWING COMMAND
# docker run -d -p 4242:4242 -p 3000:3000 -v /opt/nestdata:/data --restart unless-stopped jeff89179/nest-graph-v2.2
#
# TAG THE IMAGE WITH THE FOLLOWING COMMAND
# docker tag [image id] jeff89179/nest-graph-v2.2
#
# CONFIGURE THE LOGIN WITH THE FOLLOWING COMMAND
# docker exec -it [container id] /usr/bin/python3 /opt/nest-auth.py

FROM ubuntu:24.04
LABEL maintainer="jeff89179"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils unzip wget openjdk-8-jdk gnuplot supervisor adduser libfontconfig curl \
    python3 python3-pip && rm -rf /var/lib/apt/lists/*
RUN mkdir -p  /var/run/sshd /var/log/supervisor /data/hbase /data/zookeeper

# Install HBase...1.1.0 is current as of 2018-10-17
WORKDIR /opt
RUN wget http://archive.apache.org/dist/hbase/hbase-1.1.0/hbase-1.1.0-bin.tar.gz && \
    tar -xzvf hbase-1.1.0-bin.tar.gz && \
    rm hbase-*.gz

ADD hbase-site.xml /opt/hbase-1.1.0/conf/
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/" >> /opt/hbase-1.1.0/conf/hbase-env.sh

# Install OpenTSDB...2.3.1 is current as of 2018-10-17
ADD https://github.com/OpenTSDB/opentsdb/releases/download/v2.3.1/opentsdb-2.3.1_all.deb /tmp/
RUN dpkg -i /tmp/opentsdb-2.3.1_all.deb && rm /tmp/opentsdb-2.3.1_all.deb
ADD opentsdb.sh /opt/

# Install Grafana...5.3.1 is current as of 2018-10-17
ADD  https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_5.3.1_amd64.deb  /tmp/
RUN dpkg -i /tmp/grafana_5.3.1_amd64.deb && rm /tmp/grafana_5.3.1_amd64.deb
ADD grafana.sh /opt/
ADD dashboards /opt/dashboards


# Install tCollector by a recent commit given that last release from 2020
# (i.e. https://github.com/OpenTSDB/tcollector/releases/tag/v1.3.3.1), is
# seemingly not compatible with python 3.12.3 in the container.
RUN wget https://github.com/OpenTSDB/tcollector/archive/6b7a4253b2f8d91b81ce725c8e74b5f162fbd0f9.tar.gz \
    && tar xzf 6b7a4253b2f8d91b81ce725c8e74b5f162fbd0f9.tar.gz \
    && rm 6b7a4253b2f8d91b81ce725c8e74b5f162fbd0f9.tar.gz \
    && mv tcollector-6b7a4253b2f8d91b81ce725c8e74b5f162fbd0f9 tcollector
ADD home_collectors /opt/home_collectors

RUN pip3 install python-google-nest --break-system-packages
ADD tCollector.sh /opt/
ADD nest-auth.py /opt/

# Configure Supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 3000 4242
CMD ["/usr/bin/supervisord"]

VOLUME /data

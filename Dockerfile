FROM centos:8
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo  && \
    sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*  && \
    sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*  && \
    yum clean all && yum makecache  && \
    mkdir -p /var/log/proxy  && \
    yum install -y golang  && \
COPY /influx-proxy-2.5.8-linux-arm64/ influx-proxy
WORKDIR influx-proxy
EXPOSE 7076
CMD ["/influx-proxy/influx-proxy"]

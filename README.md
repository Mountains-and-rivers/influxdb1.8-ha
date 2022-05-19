# influxdb1.8高可用集群搭建

制作镜像

```
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
```

```
docker build -t influx-proxy:2.5.6 .
```

部署influxdb influxdb-proxy

```
rm -rf /root/influxdb/data
rm -rf /root/influxdb/meta
rm -rf /root/influxdb/wal
rm -rf /var/log/influxdb
rm -rf /home/influxdb
mkdir  /home/influxdb
cp -rf influxdb.conf /home/influxdb/influxdb.conf
docker stop influxdb_1
docker rm influxdb_1
docker run -it -d -p 8088:8086 \
--name influxdb_1 \
--expose 8090 --expose 8099 \
-v /home/influxdb/influxdb_3/data:/root/influxdb/data \
-v /home/influxdb/influxdb_3/meta:/root/influxdb/meta \
-v /home/influxdb/influxdb_3/wal:/root/influxdb/wal \
-v /home/influxdb/influxdb_3/log:/var/log/influxdb \
-v /home/influxdb/influxdb.conf:/etc/influxdb/influxdb.conf \
influxdb:1.8

rm -rf /home/influxdb/influx_proxy_1
rm -rf /home/influxdb/proxy.json
cp -rf  proxy.json /home/influxdb/proxy.json
docker stop influx_proxy_1
docker rm influx_proxy_1
docker run -it -d -p 7076:7076 \
--name influx_proxy_1 \
-v /home/influxdb/proxy.json:/influx-proxy/proxy.json \
-v /home/influxdb/influx_proxy_1/data:/influx-proxy/data \
influx-proxy:2.5.6


rm -rf /root/influxdb/data
rm -rf /root/influxdb/meta
rm -rf /root/influxdb/wal
rm -rf /var/log/influxdb
rm -rf /home/influxdb
mkdir  /home/influxdb
cp -rf influxdb.conf /home/influxdb/influxdb.conf
docker stop influxdb_2
docker rm influxdb_2
docker run -it -d -p 8087:8086 \
--name influxdb_2 \
--expose 8090 --expose 8099 \
-v /home/influxdb/influxdb_3/data:/root/influxdb/data \
-v /home/influxdb/influxdb_3/meta:/root/influxdb/meta \
-v /home/influxdb/influxdb_3/wal:/root/influxdb/wal \
-v /home/influxdb/influxdb_3/log:/var/log/influxdb \
-v /home/influxdb/influxdb.conf:/etc/influxdb/influxdb.conf \
influxdb:1.8

rm -rf /home/influxdb/influx_proxy_2
rm -rf /home/influxdb/proxy.json
cp -rf  proxy.json /home/influxdb/proxy.json

docker stop influx_proxy_2
docker rm influx_proxy_2
docker run -it -d -p 7077:7076 \
--name influx_proxy_2 \
-v /home/influxdb/proxy.json:/influx-proxy/proxy.json \
-v /home/influxdb/influx_proxy_2/data:/influx-proxy/data \
influx-proxy:2.5.6
```

nginx 编译

```
./configure --prefix=/usr/local/nginx \
--sbin-path=/usr/local/nginx \
--conf-path=/usr/local/nginx/nginx.conf \
--error-log-path=/usr/local/nginx/error.log \
--http-log-path=/usr/local/nginx/access.log \
--http-proxy-temp-path=/usr/local/nginx/tmp/proxy \
--pid-path=/usr/local/nginx/logs/nginx.pid \
--lock-path=/usr/local/nginx/nginx.lock \
--user=nginx \
--group=nginx \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_sub_module \
--with-http_gzip_static_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_v2_module \
--with-mail \
--with-mail_ssl_module \
--with-http_addition_module \
--with-cpp_test_module \
--with-stream \
--with-stream_ssl_module \
--with-stream_realip_module \
--with-stream_ssl_preread_module \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_gunzip_module \
--with-http_degradation_module \
--with-http_slice_module \
--with-threads \
--user=nginx \
--group=nginx \
--with-pcre=/usr/local/pcre-8.43 \
--with-zlib=/usr/local/zlib-1.2.11 \
--with-openssl=/usr/local/openssl-1.1.1c
```

influxdb 配置

```
reporting-disabled = true         # 禁用报告，默认为 false

[meta]

dir = "/root/influxdb/meta"    # 元信息目录

[data]

dir = "/root/influxdb/data"    # 数据目录

wal-dir = "/root/influxdb/wal" # 预写目录

wal-fsync-delay = "10ms"          # SSD 设置为 0s，非 SSD 推荐设置为 0ms-100ms

index-version = "tsi1"            # tsi1 磁盘索引，inmem 内存索引需要大量内存

query-log-enabled = true          # 查询的日志，默认是 true

cache-max-memory-size = "1g"      # 分片缓存写入的最大内存大小，默认是 1g

[coordinator]

write-timeout = "20s"             # 写入请求超时时间，默认为 10s

[http]

# bind-address = ":8086"            # 绑定地址，需要绑定 ip:port 时使用

auth-enabled = false              # 认证开关，默认是 false

log-enabled = true                # http 请求日志，默认是 true

access-log-path = "/var/log/influxdb"

[logging]

level = "info"                    # 日志等级，error、warn、info(默认)、debug

```

nginx配置

```

user  root;
worker_processes  2;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile on;

    tcp_nopush on;

    tcp_nodelay on;

    keepalive_timeout 65;
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;
    upstream myserver {
        server 192.168.31.230:7076;

        server 192.168.31.28:7077;
    }

    server {
        listen 8080;

        server_name localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;
        location / {
            proxy_redirect off;

            proxy_pass http://myserver;

            proxy_set_header Host $host;

            proxy_set_header X-Real-IP $remote_addr;

            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }
    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}
}
```

集群代理配置

```
{

	"circles": [

		{

			"name": "circle-1",

			"backends": [

				{

					"name": "influxdb-1-1",

					"url": "http://192.168.31.230:8088",

					"username": "",

					"password": "",

					"auth_encrypt": false

				},
				{

					"name": "influxdb-1-2",

					"url": "http://192.168.31.28:8087",

					"username": "",

					"password": "",

					"auth_encrypt": false

				}

			]

		}

	],

	"listen_addr": ":7076",

	"db_list": [],

	"data_dir": "data",

	"tlog_dir": "log",

	"hash_key": "idx",

	"flush_size": 10000,

	"flush_time": 1,

	"check_interval": 1,

	"rewrite_interval": 10,

	"conn_pool_size": 20,

	"write_timeout": 10,

	"idle_timeout": 10,

	"username": "",

	"password": "",

	"auth_encrypt": false,

	"write_tracing": false,

	"query_tracing": false,

	"https_enabled": false,

	"https_cert": "",

	"https_key": ""

}
```

启动

```
mkdir -p /usr/local/nginx/tmp/proxy
/usr/local/nginx/nginx -t 
/usr/local/nginx/nginx 
```

创建数据库

```
curl -X POST 'http://192.168.31.132:8080/query?q=create+database+%22jmeter%22&db=_internal'
```

使用1.1.0 web ui 连接

图片

## dujiaoka V5 LTS

### dujiaoka V5 LTS版本已经发布，欢迎使用和反馈问题。

# V5 LTS版本说明：

```
1、缝缝补补又三年！  
2、只做漏洞修复和安全加固，长期支持版本，适合钉子户。
```

# V5 LTS版本如何运行（无需准备MySQL & Redis）：

```
# 安装运行：
1. 修改 .env 里的 APP_URL、DB_ROOT_PASSWORD、DB_PASSWORD、APP_PORT
2. 首次安装：INSTALL=true ADMIN_HTTPS=false docker compose up -d --force-recreate
3. 打开站点完成安装
4. 安装完成后http访问：INSTALL=false ADMIN_HTTPS=false docker compose up -d
5. 安装完成后https反向代理访问：INSTALL=false ADMIN_HTTPS=true docker compose restart

# 注意事项：
数据库保存目录为：./mysql
Redis保存目录为：./redis
应用数据保存目录为：./dujiaoka_storage
上传文件保存目录为：./dujiaoka_uploads
```

# V5 LTS版本如何运行（自己准备MySQL & Redis）：

```
# 安装运行：
1. 修改 .env 里的 APP_URL、DB_ROOT_PASSWORD、DB_PASSWORD、APP_PORT
2. 首次安装：INSTALL=true ADMIN_HTTPS=false docker compose -f docker-compose-no-db.yml up -d --force-recreate
3. 打开站点完成安装
4. 安装完成后http访问：INSTALL=false ADMIN_HTTPS=false docker compose -f docker-compose-no-db.yml restart
5. 安装完成后https反向代理访问：INSTALL=false ADMIN_HTTPS=true docker compose -f docker-compose-no-db.yml restart

# 注意事项：
数据库保存目录为：你自己的数据库
Redis保存目录为：你自己的Redis
应用数据保存目录为：./dujiaoka_storage
上传文件保存目录为：./dujiaoka_uploads
```


# Nginx 反向代理

```nginx
# 为了安全，请务必正确配置APP_URL和ADMIN_HTTPS，避免使用sub_filter造成的潜在问题。例：APP_URL=https://my.cloudcpp.com, ADMIN_HTTPS=true
    location ^~ / {
        proxy_pass http://127.0.0.1:56789;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header REMOTE-HOST $remote_addr;
        proxy_set_header X-Forwarded-Proto  $scheme;

        add_header X-Cache $upstream_cache_status;

        proxy_set_header Accept-Encoding "";
        sub_filter "http://" "https://";
        sub_filter_once off;
    }
```

---
# Refer EndOfLife:

```
EndOfLife: 停止更新和维护，请前往新版[Dujiao-Next(dujiao-next.com)](https://dujiao-next.com)
Origin： https://github.com/assimon/dujiaoka
```
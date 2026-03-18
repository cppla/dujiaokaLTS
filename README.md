## dujiaoka V5 LTS

### dujiaoka V5 LTS版本已经发布，欢迎使用和反馈问题。Power by AI

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

> **安全提示：**
> 1. `sub_filter "http://" "https://"` 是一个应急兼容方案，可能破坏 JSON 响应体中的 URL（如支付回调地址、API 响应等）。强烈建议在 `.env` 中正确配置 `APP_URL=https://your-domain.com` 并启用 `ADMIN_HTTPS=true`，让应用本身生成正确的 HTTPS URL，而不依赖反向代理文本替换。
> 2. 请将 `Content-Security-Policy` 设置为合适的值，避免使用 `default-src * 'unsafe-eval' 'unsafe-inline'`，该配置会完全禁用 CSP 保护。参考下方示例。

```nginx
# 最重要的是location ^~ /中的相关配置。
    location ^~ / {
        proxy_pass http://127.0.0.1:56789;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header REMOTE-HOST $remote_addr;
        proxy_set_header X-Forwarded-Proto  $scheme;

        add_header X-Cache $upstream_cache_status;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        # 建议收紧 CSP，以下为示例值，根据实际使用的第三方资源调整：
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; frame-src 'self' https://js.stripe.com; connect-src 'self'" always;

        # 如果应用已正确配置 APP_URL 为 https，无需 sub_filter
        # proxy_set_header Accept-Encoding "";
        # sub_filter "http://" "https://";
        # sub_filter_once off;
    }
```

---
# Refer EndOfLife:

```
EndOfLife: 停止更新和维护，请前往新版[Dujiao-Next(dujiao-next.com)](https://dujiao-next.com)
Origin： https://github.com/assimon/dujiaoka
```
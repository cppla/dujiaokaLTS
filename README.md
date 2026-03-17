## dujiaoka V5 LTS

### dujiaoka V5 LTS版本已经发布，欢迎使用和反馈问题。Power by AI

# V5 LTS版本说明：

```
1、缝缝补补又三年！  
2、只做漏洞修复和安全加固，长期支持版本，适合钉子户。
```

# V5 LTS版本如何运行：

```
1. 修改 .env 里的 APP_URL、DB_ROOT_PASSWORD、DB_PASSWORD、APP_PORT
2. 首次安装：INSTALL=true ADMIN_HTTPS=false docker compose up -d --force-recreate
3. 打开站点完成安装
4. 安装完成后http访问：INSTALL=false ADMIN_HTTPS=false docker compose up -d
5. 安装完成后https反向代理访问：INSTALL=false ADMIN_HTTPS=true docker compose restart

```



---
# Refer EndOfLife:

```
EndOfLife: 停止更新和维护，请前往新版[Dujiao-Next(dujiao-next.com)](https://dujiao-next.com)
Origin： https://github.com/assimon/dujiaoka
```
# DOMjudge 中文汉化

适用于 DOMjudge 9.0.0 - 9.0.1 的中文汉化模板，采用机翻 + 人工优化方案，主要优化在使用 XCPC 中更常用的术语以及部分口语化的翻译。原理是替换 twig 模板

> 部分功能由于不常用，所以就照着原本的意思直译了(
>
> 例如影子评测

## 目录说明

- `templates_zh/`：中文语言模板，共 181 个文件。包含 public、jury、team、security、bundles 等全部页面，以及表单主题和公共 partial。
- `templates/`：当前服务器上的英文模板。包含此前对公共计分板等页面做的直接修改，作为对照和恢复基线。
- `src/Twig/LocaleAwareLoader.php`：根据 `domjudge_lang` cookie 在 `templates` / `templates_zh` 之间切换 Twig 模板加载器。
- `src/DependencyInjection/Compiler/LocaleAwareTwigLoaderPass.php`：替换 Twig 文件系统加载器，同时保留 KnpPaginator、NelmioApiDoc 等 bundle 的模板路径。
- `src/Kernel.php`：注册 `LocaleAwareTwigLoaderPass` 编译器插件。
- `config/services.yaml`：排除 `LocaleAwareLoader` 的自动装配，避免自定义加载器被重复注册。
- `config/packages/twig.yaml`：Twig 配置。
- `config/`：服务器当前完整配置文件快照。
- `etc/mysql/mariadb.conf.d/99-domjudge.cnf`：MariaDB 调优配置，解决 Configuration checker 提示的连接数和包大小问题。

## 已包含的修复

1. 中英文模板切换：访问端设置 cookie `domjudge_lang=zh` 使用中文，`en` 或未设置时使用英文。
2. 修复 jury 页面 500：添加 locale-aware Twig loader 并注册编译器插件，同时保留所有 bundle Twig 路径。
3. 公共计分板汉化：包括队伍、排名、颜色图例、分类、筛选按钮等。
4. Team 页面汉化：导航、首页、提交、提交详情、提交弹窗、打印、题目列表、排行榜、文档、Clar 列表/卡片/回复表单、队伍信息。
5. Jury 页面汉化：用户、队伍、题目、提交、判题、比赛、配置检查等页面。
6. Public 页面汉化：榜单、题目、队伍信息、提交弹窗。
7. MariaDB 调优：`max_connections=300`、`innodb_log_file_size=512M`、`max_allowed_packet=128M`。
8. 图片上传目录权限：`/opt/domjudge/domserver/webapp/public/images/{affiliations,banners,countries,teams}` 设置为 `domjudge:www-data`、`2775`。

## 安装方式

### 自动化脚本

1. 在服务器上安装好 DOMjudge 9.0.1
2. 将仓库 clone 下来并解压到任意位置
3. 给仓库目录下 `run.sh` 脚本权限

   ```bash
   chmod +x ./run.sh
   ./run.sh
   ```

4. 直接运行脚本，在提示输入 DOMjudge 安装目录时手动输入即可(默认为 `/opt/domjudge/domserver`)
5. 等待脚本运行完成即可

### 手动安装

以下步骤适用于已经安装好一套全新 DOMjudge，且不使用 `run.sh` 自动脚本的情况。clone 位置为 `/root/i18n-DOMjudge-Template`，DOMjudge 安装目录为 `/opt/domjudge/domserver`。

1. 将仓库 clone 下来并解压
2. 复制中英文模板
   ```bash
   cd /root/i18n-DOMjudge-Template
   WEBAPP=/opt/domjudge/domserver/webapp
   
   mkdir -p "$WEBAPP/templates" "$WEBAPP/templates_zh"
   cp -a templates_zh/. "$WEBAPP/templates_zh/"
   cp -a templates/. "$WEBAPP/templates/"
   ```

3. 复制语言切换源码和配置
   ```bash
   mkdir -p "$WEBAPP/src/Twig" "$WEBAPP/src/DependencyInjection/Compiler"
   
   cp src/Twig/LocaleAwareLoader.php "$WEBAPP/src/Twig/"
   cp src/DependencyInjection/Compiler/LocaleAwareTwigLoaderPass.php \
     "$WEBAPP/src/DependencyInjection/Compiler/"
   cp src/Kernel.php "$WEBAPP/src/"
   cp config/services.yaml "$WEBAPP/config/"
   cp config/packages/twig.yaml "$WEBAPP/config/packages/"
   ```

   

4. 复制 Composer 配置并重建 classmap
   DOMjudge 服务器使用 Composer 的 authoritative classmap，新增的 PHP 类必须重新生成自动加载映射，否则会出现 `LocaleAwareTwigLoaderPass not found`。
   
   ```bash
   cp composer.json composer.lock "$WEBAPP/"
   
   cd "$WEBAPP"
   COMPOSER_ALLOW_SUPERUSER=1 composer dump-autoload --classmap-authoritative --no-interaction
   ```
   验证类是否已被识别：
   ```bash
   php -r "require '$WEBAPP/vendor/autoload.php'; var_dump(class_exists('App\\DependencyInjection\\Compiler\\LocaleAwareTwigLoaderPass'));"
   ```
   
   输出应为 `bool(true)`。

5. 设置模板权限
   ```bash
   chown -R root:www-data "$WEBAPP/templates" "$WEBAPP/templates_zh"
   
   find "$WEBAPP/templates" "$WEBAPP/templates_zh" -type d -exec chmod 755 {} +
   find "$WEBAPP/templates" "$WEBAPP/templates_zh" -type f -exec chmod 644 {} +
   ```

   

6. 清理缓存并检查模板
   ```bash
   cd "$WEBAPP"
   sudo -u www-data bin/console cache:clear
   sudo -u www-data bin/console lint:twig templates_zh
   ```

   

7. 可选：恢复 MariaDB 调优和图片目录权限
   ```bash
   cp /root/18n-DOMjudge-Template/etc/mysql/mariadb.conf.d/99-domjudge.cnf /etc/mysql/mariadb.conf.d/
   systemctl restart mariadb
   
   chown domjudge:www-data \
     "$WEBAPP/public/images/affiliations" \
     "$WEBAPP/public/images/banners" \
     "$WEBAPP/public/images/countries" \
     "$WEBAPP/public/images/teams"
   
   chmod 2775 \
     "$WEBAPP/public/images/affiliations" \
     "$WEBAPP/public/images/banners" \
     "$WEBAPP/public/images/countries" \
     "$WEBAPP/public/images/teams"
   ```

9. 验证
   ```bash
   cd /opt/domjudge/domserver/webapp
   sudo -u www-data bin/console cache:clear
   sudo -u www-data bin/console lint:twig templates_zh
   ```

   

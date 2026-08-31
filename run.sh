#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo " DOMjudge Chinese localization deploy script"
echo "=================================================="
echo
echo "Enter the DOMjudge install directory."
echo "Example: /opt/domjudge/domserver"
read -r -p "DOMjudge install directory: " DOMJUDGE_DIR

if [ -z "$DOMJUDGE_DIR" ]; then
    echo "Error: no directory entered." >&2
    exit 1
fi

DOMJUDGE_DIR="${DOMJUDGE_DIR%/}"
WEBAPP="$DOMJUDGE_DIR/webapp"

if [ ! -d "$WEBAPP" ]; then
    echo "Error: $WEBAPP does not exist." >&2
    echo "Make sure you entered the DOMjudge install directory, not the webapp directory." >&2
    exit 1
fi

echo
echo "Using DOMjudge webapp: $WEBAPP"
echo

mkdir -p "$WEBAPP/templates" "$WEBAPP/templates_zh"

echo "[1/7] Copying Chinese templates..."
cp -a "$SCRIPT_DIR/templates_zh/." "$WEBAPP/templates_zh/"

echo "[2/7] Copying English template baseline..."
cp -a "$SCRIPT_DIR/templates/." "$WEBAPP/templates/"

echo "[3/7] Copying language switch source and config..."
mkdir -p "$WEBAPP/src/Twig" "$WEBAPP/src/DependencyInjection/Compiler"

if [ -f "$SCRIPT_DIR/src/Twig/LocaleAwareLoader.php" ]; then
    cp -a "$SCRIPT_DIR/src/Twig/LocaleAwareLoader.php" "$WEBAPP/src/Twig/"
fi
if [ -f "$SCRIPT_DIR/src/DependencyInjection/Compiler/LocaleAwareTwigLoaderPass.php" ]; then
    cp -a "$SCRIPT_DIR/src/DependencyInjection/Compiler/LocaleAwareTwigLoaderPass.php" \
        "$WEBAPP/src/DependencyInjection/Compiler/"
fi
if [ -f "$SCRIPT_DIR/src/Kernel.php" ]; then
    cp -a "$SCRIPT_DIR/src/Kernel.php" "$WEBAPP/src/"
fi
if [ -f "$SCRIPT_DIR/config/services.yaml" ]; then
    cp -a "$SCRIPT_DIR/config/services.yaml" "$WEBAPP/config/"
fi
if [ -f "$SCRIPT_DIR/config/packages/twig.yaml" ]; then
    cp -a "$SCRIPT_DIR/config/packages/twig.yaml" "$WEBAPP/config/packages/"
fi

if [ -f "$SCRIPT_DIR/composer.json" ]; then
    cp -a "$SCRIPT_DIR/composer.json" "$WEBAPP/composer.json"
fi
if [ -f "$SCRIPT_DIR/composer.lock" ]; then
    cp -a "$SCRIPT_DIR/composer.lock" "$WEBAPP/composer.lock"
fi

echo "[4/8] Regenerating Composer classmap..."
if command -v composer >/dev/null 2>&1; then
    cd "$WEBAPP"
    COMPOSER_ALLOW_SUPERUSER=1 composer dump-autoload --classmap-authoritative --no-interaction
else
    echo "Warning: composer not found, classmap may be stale." >&2
fi

echo "[5/8] Setting template permissions..."
if id www-data >/dev/null 2>&1; then
    chown -R root:www-data "$WEBAPP/templates" "$WEBAPP/templates_zh"
else
    echo "Warning: www-data user not found, keeping current ownership." >&2
fi

find "$WEBAPP/templates" "$WEBAPP/templates_zh" -type d -exec chmod 755 {} +
find "$WEBAPP/templates" "$WEBAPP/templates_zh" -type f -exec chmod 644 {} +

echo "[6/8] Clearing cache and linting Twig templates..."
cd "$WEBAPP"
if id www-data >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    sudo -u www-data "$WEBAPP/bin/console" cache:clear
    sudo -u www-data "$WEBAPP/bin/console" lint:twig templates_zh
else
    "$WEBAPP/bin/console" cache:clear
    "$WEBAPP/bin/console" lint:twig templates_zh
fi

echo "[7/8] Applying optional MariaDB tuning..."
if [ -d /etc/mysql/mariadb.conf.d ] && [ -f "$SCRIPT_DIR/etc/mysql/mariadb.conf.d/99-domjudge.cnf" ]; then
    cp -a "$SCRIPT_DIR/etc/mysql/mariadb.conf.d/99-domjudge.cnf" /etc/mysql/mariadb.conf.d/
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart mariadb || echo "Warning: could not restart MariaDB, please restart it manually." >&2
    elif command -v service >/dev/null 2>&1; then
        service mariadb restart || echo "Warning: could not restart MariaDB, please restart it manually." >&2
    else
        echo "Please restart MariaDB manually."
    fi
else
    echo "Skipped: MariaDB config directory or backup file not found."
fi

echo "[8/8] Setting image upload directory permissions..."
IMAGE_OWNER="root:www-data"
if id domjudge >/dev/null 2>&1; then
    IMAGE_OWNER="domjudge:www-data"
fi

for dir in affiliations banners countries teams; do
    target="$WEBAPP/public/images/$dir"
    if [ -d "$target" ]; then
        chown "$IMAGE_OWNER" "$target"
        chmod 2775 "$target"
    else
        echo "Skipped: $target does not exist."
    fi
done

echo
echo "=================================================="
echo " Deployment finished."
echo " Set cookie domjudge_lang=zh to use Chinese UI."
echo " Remove the cookie or set it to en for English."
echo "=================================================="

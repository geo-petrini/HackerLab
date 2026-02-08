#!/bin/bash
set -e

# Default root password if not set
: ${MYSQL_ROOT_PASSWORD:=root}

# Ensure mysqld runtime dir exists
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql || true

# Initialize database if needed
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MySQL data directory..."
  mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
fi

# Start MySQL in background
echo "Starting MySQL..."
mysqld_safe --datadir=/var/lib/mysql &

# Wait for MySQL socket
for i in {1..30}; do
  mysqladmin ping >/dev/null 2>&1 && break
  echo "Waiting for MySQL... ($i)"
  sleep 1
done

# Set root password and remove anonymous users
if mysql -uroot -e "SELECT 1" >/dev/null 2>&1; then
  echo "Configuring root user..."
  mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';FLUSH PRIVILEGES;";
fi

# Import database.sql if present and not empty
if [ -f /var/www/html/database.sql ] && [ -s /var/www/html/database.sql ]; then
  echo "Importing database.sql..."
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" < /var/www/html/database.sql || true
fi

# Install composer deps if composer.json exists
if [ -f /var/www/html/composer.json ]; then
  echo "Running composer install (no-dev)..."
  composer install --no-dev --optimize-autoloader --no-interaction || true
fi

# Ensure permissions
chown -R www-data:www-data /var/www/html || true

# Exec Apache in foreground
exec docker-php-entrypoint apache2-foreground

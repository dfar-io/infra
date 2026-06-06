# Configure WordPress on the VM (SSH)

This guide assumes you are connected to the VM over SSH and running a Debian/Ubuntu-based image.

In this repository, the VM startup script already installs and enables these dependencies during VM creation:

- NGINX
- PHP 7.4 + PHP-FPM + common PHP extensions
- MariaDB

## 1) Check external browser connectivity first

Open:

```text
http://EXTERNAL_IP
```

Replace `EXTERNAL_IP` with the VM external IP from Google Cloud Console.

## 2) Generate a password, then create the WordPress database and user

Generate a strong password and store it in a shell variable:

```bash
WP_DB_PASSWORD="$(openssl rand -base64 24)"
echo "$WP_DB_PASSWORD"
```

Save this value for step 4 (`DB_PASSWORD`), then create the database and user:

```bash
sudo mysql <<SQL
CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY '${WP_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
SQL
```

## 3) Download and place WordPress files

```bash
cd /tmp
curl -LO https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo mkdir -p /var/www/wordpress
sudo rsync -avP /tmp/wordpress/ /var/www/wordpress/
sudo chown -R www-data:www-data /var/www/wordpress
sudo find /var/www/wordpress -type d -exec chmod 755 {} \;
sudo find /var/www/wordpress -type f -exec chmod 644 {} \;
```

## 4) Create WordPress config

```bash
cd /var/www/wordpress
sudo cp wp-config-sample.php wp-config.php
sudo nano /var/www/wordpress/wp-config.php
```

Update at least these fields:

- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_HOST` (keep `localhost`)

Optional but recommended: replace WordPress salts from https://api.wordpress.org/secret-key/1.1/salt/.

## 5) Create an NGINX site for WordPress

Create a new site file:

```bash
sudo nano /etc/nginx/sites-available/wordpress
```

Paste and adjust `server_name`:

```nginx
server {
    listen 80;
    server_name _;

    root /var/www/wordpress;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

Enable the new site and disable default:

```bash
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress
sudo rm -f /etc/nginx/sites-enabled/default
```

If your PHP version differs, update the `fastcgi_pass` socket path.

## 6) Apply NGINX changes

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 7) Complete WordPress setup in browser

Open:

```text
http://EXTERNAL_IP
```

Follow the installation wizard to create the admin user and site details.

## 8) Point your domain to the VM

Before enabling HTTPS, create DNS records at your domain provider:

- `A` record: `@` -> `EXTERNAL_IP`
- `A` record: `www` -> `EXTERNAL_IP` (optional)

## 9) Update NGINX server_name for your domain

Edit:

```bash
sudo nano /etc/nginx/sites-available/wordpress
```

Change this line:

```nginx
server_name yourdomain.com www.yourdomain.com;
```

Then reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 10) Install and run Certbot

```bash
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Choose the redirect option when prompted so HTTP traffic is redirected to HTTPS.

## 11) Verify HTTPS

Open:

```text
https://yourdomain.com
```

## Troubleshooting

Use these checks if any step fails.

### Connectivity and network

```bash
curl -I http://localhost
sudo ss -tulpn | grep ':80'
```

### Service status checks

```bash
sudo systemctl status nginx --no-pager
sudo systemctl status mariadb --no-pager
php -v
systemctl list-unit-files | grep php.*fpm
```

### NGINX error logs

View recent NGINX error log lines:

```bash
sudo tail -n 100 /var/log/nginx/error.log
```

Follow NGINX errors live while reproducing an issue:

```bash
sudo tail -f /var/log/nginx/error.log
```

You can also check service-level logs from systemd:

```bash
sudo journalctl -u nginx -n 100 --no-pager
```

### Service recovery commands

```bash
sudo systemctl enable --now nginx
sudo systemctl enable --now mariadb
sudo systemctl enable --now php7.4-fpm
sudo systemctl status php7.4-fpm --no-pager
```

If your VM uses a different PHP version, replace `php7.4-fpm` with the installed service name.

### NGINX and PHP validation

```bash
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl restart php7.4-fpm
echo "<?php phpinfo();" | sudo tee /var/www/html/info.php
```

Then open:

```text
http://EXTERNAL_IP/info.php
```

After testing, remove it:

```bash
sudo rm /var/www/html/info.php
```

### MariaDB initialization

```bash
sudo mysql_secure_installation
```

### DNS and HTTPS checks

```bash
dig +short yourdomain.com
dig +short www.yourdomain.com
sudo certbot renew --dry-run
systemctl list-timers | grep certbot
```

## Notes

- Terraform in this repo applies HTTP/HTTPS firewall access (`80` and `443`) for instances tagged `maprodj`.
- HTTPS with Certbot requires domain DNS records to point to the VM before certificate issuance.

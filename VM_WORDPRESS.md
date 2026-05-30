# Install NGINX and PHP on the VM (SSH)

This guide assumes you are already connected to the VM over SSH and running a Debian/Ubuntu-based image.

## 1) Update package indexes

```bash
sudo apt update
```

## 2) Install NGINX

```bash
sudo apt install -y nginx
```

## 3) Start and enable NGINX

```bash
sudo systemctl enable --now nginx
```

## 4) Confirm service status

```bash
sudo systemctl status nginx --no-pager
```

You should see `active (running)` in the output.

## 5) Check that NGINX is listening on port 80

```bash
sudo ss -tulpn | grep ':80'
```

## 6) Test from inside the VM

```bash
curl -I http://localhost
```

Expected result: an HTTP response like `HTTP/1.1 200 OK`.

## 7) Test from your browser

Open:

```text
http://EXTERNAL_IP
```

Replace `EXTERNAL_IP` with the VM's external IP from Google Cloud Console.

## 8) Install PHP and common extensions

```bash
sudo apt install -y php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip
```

## 9) Enable and verify PHP-FPM

```bash
sudo systemctl enable --now php8.2-fpm
sudo systemctl status php8.2-fpm --no-pager
```

If your VM image uses a different PHP version, replace `php8.2-fpm` with the installed version.

You can check available PHP-FPM services with:

```bash
systemctl list-unit-files | grep php.*fpm
```

## 10) Configure NGINX for PHP (default site)

Edit the default site config:

```bash
sudo nano /etc/nginx/sites-available/default
```

Inside the `server { ... }` block, ensure this section exists (uncomment or add it):

```nginx
index index.php index.html index.htm;

location ~ \.php$ {
	include snippets/fastcgi-php.conf;
	fastcgi_pass unix:/run/php/php8.2-fpm.sock;
}
```

If your PHP version is different, update the socket path accordingly.

## 11) Test NGINX config and reload

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 12) Verify PHP is processed by NGINX

```bash
echo "<?php phpinfo();" | sudo tee /var/www/html/info.php
```

Then open:

```text
http://EXTERNAL_IP/info.php
```

After confirming it works, remove the file for security:

```bash
sudo rm /var/www/html/info.php
```

## 13) Install and start MariaDB

```bash
sudo apt install -y mariadb-server
sudo systemctl enable --now mariadb
sudo systemctl status mariadb --no-pager
```

Run the basic hardening flow:

```bash
sudo mysql_secure_installation
```

## 14) Create a WordPress database and user

Replace the placeholder values before running:

```bash
sudo mysql <<'SQL'
CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'CHANGE_ME_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
SQL
```

## 15) Download and place WordPress files

```bash
cd /tmp
curl -LO https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo mkdir -p /var/www/wordpress
sudo rsync -avP /tmp/wordpress/ /var/www/wordpress/
```

Set ownership and baseline permissions:

```bash
sudo chown -R www-data:www-data /var/www/wordpress
sudo find /var/www/wordpress -type d -exec chmod 755 {} \;
sudo find /var/www/wordpress -type f -exec chmod 644 {} \;
```

## 16) Create WordPress config

```bash
cd /var/www/wordpress
sudo cp wp-config-sample.php wp-config.php
```

Edit config values:

```bash
sudo nano /var/www/wordpress/wp-config.php
```

Update at least these fields to match your database setup:

- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_HOST` (keep `localhost`)

Optional but recommended: replace WordPress salts from https://api.wordpress.org/secret-key/1.1/salt/.

## 17) Create an NGINX site for WordPress

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
		fastcgi_pass unix:/run/php/php8.2-fpm.sock;
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

## 18) Validate and reload services

```bash
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl restart php8.2-fpm
```

## 19) Complete WordPress setup in browser

Open:

```text
http://EXTERNAL_IP
```

Follow the installation wizard to create the admin user and site details.

## 20) Point your domain to the VM

Before enabling HTTPS, create DNS records at your domain provider:

- `A` record: `@` -> `EXTERNAL_IP`
- `A` record: `www` -> `EXTERNAL_IP` (optional)

Verify DNS has propagated:

```bash
dig +short yourdomain.com
dig +short www.yourdomain.com
```

Both should return your VM external IP.

## 21) Update NGINX server_name for your domain

Edit:

```bash
sudo nano /etc/nginx/sites-available/wordpress
```

Change this line:

```nginx
server_name yourdomain.com www.yourdomain.com;
```

Then validate and reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 22) Install Certbot for NGINX

```bash
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
```

## 23) Request and install TLS certificate

Run Certbot for your domain names:

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Choose the redirect option when prompted so HTTP traffic is redirected to HTTPS.

## 24) Verify HTTPS and renewal

Test in browser:

```text
https://yourdomain.com
```

Test renewal flow:

```bash
sudo certbot renew --dry-run
```

Optional: check Certbot timer status:

```bash
systemctl list-timers | grep certbot
```

## Notes

- Your Terraform already applies a firewall rule for HTTP/HTTPS (`80` and `443`) to instances tagged `maprodj`.
- HTTPS with Certbot requires your domain DNS to point to the VM before certificate issuance.

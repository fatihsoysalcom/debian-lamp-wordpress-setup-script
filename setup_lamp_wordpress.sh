IyEvYmFzaC9iYXNo

# Debian 9 Üzerinde LAMP Stack ile WordPress Kurulumu: Adım Adım Tam Kılavuz
# Bu script, Debian 9 üzerinde LAMP yığınını (Apache, MariaDB, PHP) kurar
# ve ardından WordPress'i yapılandırır.

# Scripti çalıştırırken root yetkilerine sahip olmanız gerekir.
if [ "$EUID" -ne 0 ]; then
  echo "Lütfen bu scripti root olarak çalıştırın."
  exit
fi

# Paket listesini güncelle
apt update

# LAMP yığınını kur (Apache, MariaDB, PHP)
# Apache web sunucusu
apt install -y apache2

# MariaDB veritabanı sunucusu
apt install -y mariadb-server

# PHP ve gerekli modülleri kur
apt install -y php libapache2-mod-php php-mysql

# Apache'yi yeniden başlatarak PHP modülünü etkinleştir
systemctl restart apache2

# MariaDB güvenliğini yapılandır (interaktif değil, varsayılanlarla)
# Bu adımda varsayılan root şifresi kullanılır. Gerçek bir kurulumda
# bu bölümü daha güvenli hale getirmek için interaktif veya
# önceden tanımlanmış şifrelerle özelleştirin.
mariadb-secure-installation --use-default --root-password=""

# WordPress veritabanı oluştur
# Gerçek bir kurulumda veritabanı adı, kullanıcı adı ve şifreyi özelleştirin.
DB_NAME="wordpress_db"
DB_USER="wordpress_user"
DB_PASS="your_strong_password"

mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# WordPress'i indir
cd /var/www/html/
apt install -y wget unzip
wget https://wordpress.org/latest.zip
unzip latest.zip
mv wordpress/* .
rm latest.zip

# WordPress yapılandırma dosyasını oluştur
cp wp-config-sample.php wp-config.php

# wp-config.php dosyasında veritabanı bilgilerini güncelle
sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_PASS/" wp-config.php

# WordPress dosyalarının sahipliğini ve izinlerini ayarla
chown -R www-data:www-data /var/www/html/
find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;

# Apache sanal konak (Virtual Host) yapılandırması (basit örnek)
# Gerçek bir kurulumda bu bölümü kendi alan adınıza göre özelleştirin.
cat <<EOF > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/html/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Yeni sanal konağı etkinleştir ve varsayılanı devre dışı bırak
a2ensite wordpress.conf
a2dissite 000-default.conf

# Apache'yi yeniden yükle
systemctl reload apache2

echo "LAMP yığını ve WordPress kurulumu tamamlandı."
echo "Tarayıcınızda sunucu IP adresinizi veya alan adınızı ziyaret ederek WordPress kurulumunu tamamlayabilirsiniz."

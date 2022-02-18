#!/bin/bash

echo "configurando el resolv.conf con cat"
cat <<TEST> /etc/resolv.conf
nameserver 8.8.8.8
TEST

echo "instalando un servidor vsftpd"
sudo apt-get install vsftpd -y

echo "instalando un servidor ftp"
sudo apt-get install ftp -y

echo "Modificando vsftpd.conf con sed"
sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf

echo "Cambiar banner de bienvenida"
sed -i 's/ftpd_banner=Bienvenido práctica provision ftp./ftpd_banner=Bienvenido práctica provision ftp./g' /etc/vsftpd.conf

echo "configurando ip forwarding con echo"
sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

echo "Instalar servicios"
apt update -y
apt install -y apache2
echo "Crear usuario"
sudo useradd -p $(openssl passwd lau) -d /home/lau -m -s /bin/bash lau
passwd lau

echo "Restringir el acceso a usuarios anónimos"
sed -i 's/#anonymous_enable=NO/anonymous_enable=NO/g' /etc/vsftpd.conf

echo "Habilitar usuarios locales"
sed -i 's/#local_enable=YES/local_enable=YES/g' /etc/vsftpd.conf

echo "Establecer permisos al usuario local"
sudo chmod -R 777 /home/lau/
sudo chmod 555 /var/

echo "Reiniciamos servicios"
sudo service vsftpd start 


#Instalación del contenedor

echo "Instalamos LXD"
sudo apt-get install lxd -y

echo "Iniciar LXD"
sudo lxd init --auto
sleep 10

echo "Crear un contenedor"
sudo lxc launch ubuntu:20.04 ftp3
sleep 10

echo "Aplicar un límite de memoria a su contenedor"
sudo lxc config set ftp3 limits.memory 64MB

echo "Instalar Apache"
sudo lxc exec ftp3 -- apt-get install apache2 -y

echo "Crear página de prueba"
sudo touch index.html /var/www/html

cat <<TEST> /var/www/html/index.html
<!DOCTYPE html>
<html>
<body>
<h1>Pagina de prueba</h1>
<p>Bienvenidos a mi contenedor LXD</p>
<p>Probando el funcionamiento del container con aprovisionamiento</p>
</body>
</html>
TEST

echo "Reemplazar archivo"
lxc file push /var/www/html/index.html ftp3/var/www/html/index.html

echo "Reinciar el servicio apache"
lxc exec ftp3 -- systemctl restart apache2

echo "Reenvío de puertos"
lxc config device add ftp3 myport80 proxy listen=tcp:192.168.100.3:5080 connect=tcp:127.0.0.1:80



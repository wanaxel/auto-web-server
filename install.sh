#!/bin/bash

set -e


if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS=$ID
    OS_NAME=$PRETTY_NAME
else
    echo "Unsupported OS"
    exit 1
fi

echo "Detected OS: $OS_NAME ($OS)"


choose_web_server() {
    while true; do
        echo "Choose a web server to install:"
        echo "1) Apache"
        echo "2) Nginx"
        read -rp "Enter choice (1 or 2): " choice

        case $choice in
            1)
                WEB_SERVER="apache"
                break
                ;;
            2)
                WEB_SERVER="nginx"
                break
                ;;
            *)
                echo "Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
}

choose_web_server


if [[ $OS == "ubuntu" || $OS == "debian" ]]; then
    sudo apt update
    if [[ $WEB_SERVER == "apache" ]]; then
        sudo apt install -y apache2
        sudo systemctl enable --now apache2
        sudo ufw allow 'Apache Full'
    else
        sudo apt install -y nginx
        sudo systemctl enable --now nginx
        sudo ufw allow 'Nginx Full'
    fi
    sudo ufw enable
elif [[ $OS == "arch" ]]; then
    sudo pacman -Syu --noconfirm
    if [[ $WEB_SERVER == "apache" ]]; then
        sudo pacman -S --noconfirm apache
        sudo systemctl enable --now httpd
        sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    else
        sudo pacman -S --noconfirm nginx
        sudo systemctl enable --now nginx
        sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    fi
elif [[ $OS == "centos" || $OS == "rhel" || $OS == "fedora" ]]; then
    sudo dnf install -y firewalld
    sudo systemctl enable --now firewalld
    if [[ $WEB_SERVER == "apache" ]]; then
        sudo dnf install -y httpd
        sudo systemctl enable --now httpd
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
    else
        sudo dnf install -y nginx
        sudo systemctl enable --now nginx
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
    fi
    sudo firewall-cmd --reload
else
    echo "Unsupported OS"
    exit 1
fi


echo "Do you want to enable SSL with Let's Encrypt? (y/n)"
read -rp "Enter choice: " ssl_choice
if [[ $ssl_choice == "y" ]]; then
    sudo apt install -y certbot python3-certbot-${WEB_SERVER}
    read -rp "Enter your domain name: " domain
    sudo certbot --${WEB_SERVER} -d "$domain"
    sudo systemctl reload ${WEB_SERVER}
fi

echo "Installation complete. Your $WEB_SERVER web server is now running."

#!/usr/bin/env bash
# À lancer sur srv-cible (192.168.100.10).
# Prépare les sources de logs, puis génère des événements système locaux.

echo "[*] Préparation des sources de logs (nginx, ufw logging, fail2ban)..."
sudo apt-get update -qq
sudo apt-get install -y -qq nginx >/dev/null 2>&1
sudo systemctl enable --now nginx >/dev/null 2>&1
sudo ufw logging on >/dev/null 2>&1
sudo systemctl restart fail2ban >/dev/null 2>&1

echo "[*] Génération d'événements locaux..."
# Commandes sudo (tracées dans auth.log)
sudo cat /etc/shadow >/dev/null 2>&1
sudo systemctl status ssh >/dev/null 2>&1

# Création puis suppression d'un compte de test (tracées dans auth.log)
sudo useradd -m compte_test >/dev/null 2>&1
echo "compte_test:Test1234" | sudo chpasswd >/dev/null 2>&1
sudo userdel -r compte_test >/dev/null 2>&1

# Arrêt puis redémarrage d'un service (tracés dans le journal)
sudo systemctl stop fail2ban >/dev/null 2>&1
sleep 1
sudo systemctl start fail2ban >/dev/null 2>&1

# Tentative d'authentification sudo échouée (tracée dans auth.log), en dernier
sudo -k
echo "mauvais_mot_de_passe" | sudo -S -p "" id >/dev/null 2>&1

echo "[*] Termine. Evenements generes dans auth.log, le journal systemd et syslog."

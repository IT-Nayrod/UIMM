#!/usr/bin/env bash
#
# install-lab.sh
# Met un serveur Ubuntu dans un etat volontairement VULNERABLE pour le TP de durcissement.
#
# ATTENTION :
#   - A executer UNIQUEMENT dans une VM jetable et ISOLEE (aucun acces a un vrai reseau).
#   - Ce script AFFAIBLIT la machine. Ne jamais l'utiliser sur un serveur reel.
#   - Il n'installe RIEN via apt : il n'utilise que les outils d'une installation de base.
#     Il fonctionne donc hors ligne (une fois l'OS installe avec OpenSSH).
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Ce script doit etre lance en root : sudo bash install-lab.sh" >&2
  exit 1
fi

echo "==> Mise en place du serveur volontairement vulnerable..."

# 1) Comptes faibles + compte cache avec les droits root (uid 0)
echo "  - comptes faibles"
useradd -m -s /bin/bash stagiaire 2>/dev/null || true
echo 'stagiaire:azerty' | chpasswd
# "support" : compte pirate discret, meme uid que root => droits root complets
useradd -o -u 0 -g 0 -M -d /root -s /bin/bash support 2>/dev/null || true
echo 'support:support' | chpasswd

# 2) sudo sans mot de passe pour stagiaire
echo "  - sudo NOPASSWD"
cat > /etc/sudoers.d/90-lab <<'EOF'
stagiaire ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/90-lab

# 3) SSH mal configure (root autorise, mots de passe vides autorises)
echo "  - SSH permissif"
# on neutralise d'eventuels drop-ins qui prendraient le dessus, pour que le
# fichier principal fasse foi (ce que l'etudiant editera).
if compgen -G "/etc/ssh/sshd_config.d/*.conf" >/dev/null; then
  sed -i -E '/^[[:space:]]*(PermitRootLogin|PasswordAuthentication|PermitEmptyPasswords)\b/Id' /etc/ssh/sshd_config.d/*.conf
fi
set_sshd() {
  local key="$1" val="$2" f=/etc/ssh/sshd_config
  if grep -qiE "^[[:space:]]*#?[[:space:]]*${key}\b" "$f"; then
    sed -i -E "s|^[[:space:]]*#?[[:space:]]*${key}\b.*|${key} ${val}|I" "$f"
  else
    printf '%s %s\n' "$key" "$val" >> "$f"
  fi
}
set_sshd PermitRootLogin yes
set_sshd PasswordAuthentication yes
set_sshd PermitEmptyPasswords yes
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

# 4) Pare-feu desactive
echo "  - pare-feu desactive"
ufw --force disable 2>/dev/null || true

# 5) Service de partage de fichiers NON CHIFFRE expose sur le reseau (port 8000)
echo "  - service de partage en clair (port 8000)"
mkdir -p /srv/partage
echo "Mot de passe admin du NAS : Nas@2024"            > /srv/partage/mots_de_passe.txt
echo "Liste clients confidentielle - ne pas diffuser"  > /srv/partage/clients.csv
cat > /etc/systemd/system/partage.service <<'EOF'
[Unit]
Description=Partage de fichiers (non securise, TP)
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8000 --directory /srv/partage --bind 0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload 2>/dev/null || true
systemctl enable --now partage.service 2>/dev/null || true

# 6) Secret en clair, lisible par tout le monde
echo "  - secret lisible par tous"
mkdir -p /opt/app
cat > /opt/app/config.env <<'EOF'
DB_HOST=127.0.0.1
DB_USER=root
DB_PASSWORD=Sup3rSecret!
EOF
chmod 644 /opt/app/config.env

# 7) Binaire SUID root (escalade de privileges triviale)
echo "  - binaire SUID pirate"
cp /bin/bash /usr/local/bin/maint-shell
chmod 4755 /usr/local/bin/maint-shell

# 8) Tache planifiee lancant, en root, un script modifiable par tout le monde
echo "  - cron root sur script modifiable par tous"
cat > /opt/app/maintenance.sh <<'EOF'
#!/bin/bash
# menage quotidien
find /tmp -type f -mtime +7 -delete 2>/dev/null
EOF
chmod 777 /opt/app/maintenance.sh
cat > /etc/cron.d/maintenance <<'EOF'
*/10 * * * * root /opt/app/maintenance.sh
EOF
chmod 644 /etc/cron.d/maintenance

# 9) Historique laissant fuiter un mot de passe
echo "  - fuite de mot de passe dans l'historique"
touch /home/stagiaire/.bash_history
cat >> /home/stagiaire/.bash_history <<'EOF'
cd /opt/app
mysql -u root -pSup3rSecret! -e "show databases;"
EOF
chown stagiaire:stagiaire /home/stagiaire/.bash_history 2>/dev/null || true

echo "==> Termine. Le serveur est maintenant volontairement vulnerable."
echo "    Lance 'sudo bash verif.sh' pour voir la liste des points a corriger."

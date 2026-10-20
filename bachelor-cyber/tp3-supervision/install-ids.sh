#!/usr/bin/env bash
#
# install-ids.sh
# Prepare l'environnement de supervision reseau (Suricata) pour le TP3.
# VM Ubuntu jetable et ISOLEE. A lancer en root : sudo bash install-ids.sh
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Lance ce script en root : sudo bash install-ids.sh" >&2
  exit 1
fi

TPUSER="${SUDO_USER:-root}"
TPHOME="$(getent passwd "$TPUSER" | cut -d: -f6)"
[[ -z "$TPHOME" ]] && TPHOME=/root

echo "==> Installation de Suricata et des outils d'analyse..."
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y suricata tcpdump nmap curl jq

echo "==> Mise a jour des regles Suricata (ET Open)..."
suricata-update || echo "  (maj des regles ignoree : pas d'acces reseau. Les regles par defaut et tes regles custom suffiront.)"

echo "==> Mise en place d'un service web local a surveiller (127.0.0.1:8080)..."
mkdir -p /srv/web
# Fichier de test antivirus standard (chaine EICAR, totalement inoffensive)
cat > /srv/web/eicar.txt <<'EOF'
X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
EOF
cat > /srv/web/index.html <<'EOF'
<!doctype html><html><body><h1>Portail interne Solmetal</h1></body></html>
EOF
# Petit pixel pour le trafic de balise (le serveur repond 200 au lieu de 404)
printf 'GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\xff\xff\xff!\xf9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;' > /srv/web/pixel.gif
cat > /etc/systemd/system/web-interne.service <<'EOF'
[Unit]
Description=Portail web interne (pour TP supervision)
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --directory /srv/web --bind 127.0.0.1
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now web-interne.service

echo "==> Creation d'un dossier de travail : $TPHOME/tp3-ids"
mkdir -p "$TPHOME/tp3-ids"
chown "$TPUSER":"$TPUSER" "$TPHOME/tp3-ids" 2>/dev/null || true

echo "==> Pret."
echo "    Un service web local tourne sur 127.0.0.1:8080."
echo "    A toi de capturer le trafic suspect et de l'analyser avec Suricata."

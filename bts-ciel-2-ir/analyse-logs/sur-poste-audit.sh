#!/usr/bin/env bash
# À lancer sur poste-audit (192.168.100.20).
# Génère des attaques vers srv-cible ; les traces apparaîtront dans les logs du serveur.
CIBLE="192.168.100.10"

echo "[*] Installation des outils si besoin (nmap, curl)..."
sudo apt-get update -qq
sudo apt-get install -y -qq nmap curl >/dev/null 2>&1

echo "[*] 1/3 Sondage SSH avec des utilisateurs invalides..."
for u in admin root test oracle postgres backup user1 guest; do
  ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$u@$CIBLE" true 2>/dev/null
done

echo "[*] 2/3 Scan de ports (declenche le pare-feu)..."
nmap -Pn -T4 "$CIBLE" >/dev/null 2>&1

echo "[*] 3/3 Requetes web suspectes..."
for chemin in /admin /wp-login.php /.env /phpmyadmin "/index.php?id=1'OR'1'='1"; do
  curl -s -o /dev/null "http://$CIBLE$chemin"
  curl -k -s -o /dev/null "https://$CIBLE$chemin"
done

echo "[*] Termine. Traces attendues : auth.log (Invalid user), ufw.log (BLOCK), logs Nginx (404/403), Fail2ban."

#!/usr/bin/env bash
#
# simuler-attaque.sh
# Met en scene une intrusion sur la VM de TP : traces dans les journaux + persistance reelle.
# A lancer en root dans la VM de TP (jetable et ISOLEE) :
#   sudo bash simuler-attaque.sh
# Deuxieme mode, apres avoir configure Fail2ban, pour le tester :
#   sudo bash simuler-attaque.sh rejouer
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Lance ce script en root : sudo bash simuler-attaque.sh" >&2
  exit 1
fi

AUTH=/var/log/auth.log
HOST="$(hostname)"
ATTACKER="185.220.101.47"            # IP malveillante (pour l'exercice)
USERS=(root admin oracle test postgres ubuntu)

ts() { date "+%b %e %H:%M:%S"; }     # format d'horodatage syslog

inject_bruteforce() {
  local ip="$1" n="${2:-25}" i u pid
  for ((i = 0; i < n; i++)); do
    u="${USERS[$((RANDOM % ${#USERS[@]}))]}"
    pid=$((RANDOM % 9000 + 1000))
    printf '%s %s sshd[%s]: Failed password for invalid user %s from %s port %s ssh2\n' \
      "$(ts)" "$HOST" "$pid" "$u" "$ip" "$((RANDOM % 60000 + 1024))" >> "$AUTH"
    sleep 0.05
  done
}

# Mode "rejouer" : une rafale fraiche pour declencher Fail2ban une fois la jail en place
if [[ "${1:-}" == "rejouer" ]]; then
  echo "==> Nouvelle rafale depuis $ATTACKER (test de Fail2ban)..."
  inject_bruteforce "$ATTACKER" 8
  echo "    Patiente quelques secondes puis : sudo fail2ban-client status sshd"
  exit 0
fi

if [[ ! -f "$AUTH" ]]; then
  echo "ERREUR : $AUTH introuvable. Verifie que rsyslog est installe et actif." >&2
  echo "         (sudo apt install -y rsyslog && sudo systemctl enable --now rsyslog)" >&2
  exit 1
fi

echo "==> Injection d'un scenario d'intrusion dans $AUTH ..."

# 1) Reconnaissance : balayage de comptes (echecs en rafale)
inject_bruteforce "$ATTACKER" 30

# 2) Compromission : connexion reussie sur un compte faible (stagiaire du TP precedent)
pid=$((RANDOM % 9000 + 1000))
printf '%s %s sshd[%s]: Accepted password for stagiaire from %s port %s ssh2\n' \
  "$(ts)" "$HOST" "$pid" "$ATTACKER" "$((RANDOM % 60000 + 1024))" >> "$AUTH"
printf '%s %s sshd[%s]: pam_unix(sshd:session): session opened for user stagiaire by (uid=0)\n' \
  "$(ts)" "$HOST" "$pid" >> "$AUTH"

# 3) Elevation : lecture du fichier des mots de passe via sudo
printf '%s %s sudo: stagiaire : TTY=pts/1 ; PWD=/home/stagiaire ; USER=root ; COMMAND=/usr/bin/cat /etc/shadow\n' \
  "$(ts)" "$HOST" >> "$AUTH"

# 4) Persistance (trace dans le journal)
printf '%s %s useradd[%s]: new user: name=svc-update, UID=0, GID=0, home=/home/svc-update, shell=/bin/bash\n' \
  "$(ts)" "$HOST" "$((RANDOM % 9000 + 1000))" >> "$AUTH"

# 4bis) Persistance REELLE a trouver et eradiquer : compte backdoor uid 0 + tache planifiee
echo "==> Mise en place de la persistance de l'attaquant..."
useradd -o -u 0 -g 0 -M -d /home/svc-update -s /bin/bash svc-update 2>/dev/null || true
echo 'svc-update:Backdoor2024!' | chpasswd
cat > /usr/local/bin/.sync <<'EOF'
#!/bin/bash
# balise de persistance (inoffensive, pour le TP)
echo "beacon $(date)" >> /tmp/.beacon
EOF
chmod 755 /usr/local/bin/.sync
cat > /etc/cron.d/svc-update <<'EOF'
*/5 * * * * root /usr/local/bin/.sync >/dev/null 2>&1
EOF
chmod 644 /etc/cron.d/svc-update

echo "==> Scenario en place. A toi d'enqueter, puis de nettoyer et de renforcer la detection."

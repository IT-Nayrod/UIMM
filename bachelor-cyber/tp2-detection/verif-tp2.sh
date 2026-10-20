#!/usr/bin/env bash
#
# verif-tp2.sh
# Verifie l'investigation et la remediation de l'incident, et affiche un score.
# A lancer en root : sudo bash verif-tp2.sh
#
set -uo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Lance ce script en root : sudo bash verif-tp2.sh" >&2
  exit 1
fi

GREEN=$'\e[32m'; RED=$'\e[31m'; BOLD=$'\e[1m'; NC=$'\e[0m'
score=0; total=0

check() {
  local label="$1"; shift
  total=$((total + 1))
  if "$@"; then
    printf "%s[ OK  ]%s %s\n" "$GREEN" "$NC" "$label"
    score=$((score + 1))
  else
    printf "%s[ECHEC]%s %s\n" "$RED" "$NC" "$label"
  fi
}

# L'etudiant doit avoir consigne son analyse dans un rapport
RAPPORT="${RAPPORT:-$HOME/rapport-incident.md}"
[[ -f ./rapport-incident.md ]] && RAPPORT=./rapport-incident.md

# --- Controles : 0 = point correctement traite ---

c_rapport_existe() {
  [[ -s "$RAPPORT" ]]
}

c_rapport_ip() {
  # l'IP de l'attaquant a ete identifiee dans le rapport
  grep -q '185\.220\.101\.47' "$RAPPORT" 2>/dev/null
}

c_rapport_compte() {
  # le compte utilise pour l'intrusion a ete identifie
  grep -qi 'stagiaire' "$RAPPORT" 2>/dev/null
}

c_backdoor_compte() {
  # le compte de persistance uid 0 a ete supprime
  ! awk -F: '($3==0){print $1}' /etc/passwd | grep -qx 'svc-update'
}

c_backdoor_cron() {
  # la tache planifiee de persistance a ete supprimee
  [[ ! -e /etc/cron.d/svc-update ]]
}

c_backdoor_script() {
  # le script de persistance a ete supprime
  [[ ! -e /usr/local/bin/.sync ]]
}

c_fail2ban_actif() {
  # Fail2ban est installe et en cours d'execution
  systemctl is-active --quiet fail2ban
}

c_fail2ban_jail() {
  # la jail sshd est active
  fail2ban-client status sshd >/dev/null 2>&1
}

# --- Execution ---

echo "${BOLD}=== Verification : investigation et reponse a incident ===${NC}"
check "Un rapport d'incident a ete redige"                     c_rapport_existe
check "L'adresse IP de l'attaquant est identifiee"             c_rapport_ip
check "Le compte utilise pour l'intrusion est identifie"       c_rapport_compte
check "Le compte de persistance (uid 0) a ete supprime"        c_backdoor_compte
check "La tache planifiee malveillante a ete supprimee"        c_backdoor_cron
check "Le script de persistance a ete supprime"                c_backdoor_script
check "Fail2ban est installe et actif"                         c_fail2ban_actif
check "La jail SSH de Fail2ban est en place"                   c_fail2ban_jail

echo "-------------------------------------------------"
if [[ "$score" -eq "$total" ]]; then
  printf "%sScore : %s/%s. Incident traite, detection en place, bravo.%s\n" "$GREEN$BOLD" "$score" "$total" "$NC"
else
  printf "%sScore : %s/%s. Corrige les lignes [ECHEC] puis relance.%s\n" "$BOLD" "$score" "$total" "$NC"
  echo "Astuce : le rapport est cherche dans ./rapport-incident.md ou ~/rapport-incident.md"
fi

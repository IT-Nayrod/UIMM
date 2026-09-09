#!/usr/bin/env bash
#
# verif.sh
# Verifie le durcissement du serveur et affiche un score.
# A lancer en root (lecture de la config SSH, des permissions, etc.) :
#   sudo bash verif.sh
# N'utilise que des outils de base : fonctionne hors ligne.
#
set -uo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Lance ce script en root : sudo bash verif.sh" >&2
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

# --- Controles (chaque fonction renvoie 0 si le point est correctement securise) ---

c_uid0() {
  # aucun compte a uid 0 autre que root
  local autres
  autres="$(awk -F: '($3==0){print $1}' /etc/passwd | grep -vx 'root' || true)"
  [[ -z "$autres" ]]
}

c_nopasswd() {
  # plus aucune regle sudo NOPASSWD active (hors commentaires)
  ! grep -Rhn 'NOPASSWD' /etc/sudoers /etc/sudoers.d 2>/dev/null \
    | grep -vE '^[0-9]*:[[:space:]]*#' | grep -q 'NOPASSWD'
}

c_ssh_root() {
  sshd -T 2>/dev/null | grep -qi '^permitrootlogin no'
}

c_ssh_empty() {
  sshd -T 2>/dev/null | grep -qi '^permitemptypasswords no'
}

c_ufw() {
  ufw status verbose 2>/dev/null | grep -qi 'Status: active' \
    && ufw status verbose 2>/dev/null | grep -qiE 'Default:.*deny \(incoming\)'
}

c_partage() {
  # le service de partage en clair (port 8000) ne doit plus ecouter
  ! ss -tlnH 2>/dev/null | grep -q ':8000[[:space:]]'
}

c_secret() {
  # /opt/app/config.env supprime, ou plus lisible par groupe/autres
  local f=/opt/app/config.env
  [[ ! -e "$f" ]] && return 0
  [[ -z "$(find "$f" -perm /044 2>/dev/null)" ]]
}

c_suid() {
  # le binaire SUID pirate est supprime ou n'a plus le bit SUID
  [[ -z "$(find /usr/local/bin/maint-shell -perm -4000 2>/dev/null)" ]]
}

c_cron() {
  # cron supprime, ou script non modifiable par tout le monde
  [[ ! -e /etc/cron.d/maintenance ]] && return 0
  local s=/opt/app/maintenance.sh
  [[ ! -e "$s" ]] && return 0
  [[ -z "$(find "$s" -perm /0002 2>/dev/null)" ]]
}

c_history() {
  # le mot de passe en clair a ete retire de l'historique
  ! grep -q 'Sup3rSecret' /home/stagiaire/.bash_history 2>/dev/null
}

# --- Execution ---

echo "${BOLD}=== Verification du durcissement du serveur ===${NC}"
check "Aucun compte cache avec les droits root (uid 0)"        c_uid0
check "Plus de sudo sans mot de passe (NOPASSWD)"              c_nopasswd
check "SSH : connexion directe de root interdite"             c_ssh_root
check "SSH : mots de passe vides interdits"                   c_ssh_empty
check "Pare-feu actif et trafic entrant refuse par defaut"    c_ufw
check "Service de partage en clair (port 8000) arrete"        c_partage
check "Secret /opt/app/config.env protege"                    c_secret
check "Binaire SUID pirate neutralise"                        c_suid
check "Script planifie non modifiable par tout le monde"      c_cron
check "Mot de passe en clair retire de l'historique"          c_history

echo "-------------------------------------------------"
if [[ "$score" -eq "$total" ]]; then
  printf "%sScore : %s/%s. Serveur durci, bravo.%s\n" "$GREEN$BOLD" "$score" "$total" "$NC"
else
  printf "%sScore : %s/%s. Corrige les lignes [ECHEC] puis relance.%s\n" "$BOLD" "$score" "$total" "$NC"
fi

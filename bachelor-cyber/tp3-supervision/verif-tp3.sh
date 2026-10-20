#!/usr/bin/env bash
#
# verif-tp3.sh
# Verifie le travail de supervision : detection, regles custom, regle avancee,
# decouverte de la menace furtive, analyse, rapport.
# A lancer en root : sudo bash verif-tp3.sh
#
set -uo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Lance ce script en root : sudo bash verif-tp3.sh" >&2
  exit 1
fi

GREEN=$'\e[32m'; RED=$'\e[31m'; BOLD=$'\e[1m'; NC=$'\e[0m'
score=0; total=0

TPUSER="${SUDO_USER:-root}"
TPHOME="$(getent passwd "$TPUSER" | cut -d: -f6)"; [[ -z "$TPHOME" ]] && TPHOME=/root
WORK="$TPHOME/tp3-ids"

EVE_CANDIDATES=("$WORK/eve.json" "./eve.json" "/var/log/suricata/eve.json")
FASTLOG_CANDIDATES=("$WORK/fast.log" "./fast.log" "/var/log/suricata/fast.log")
RULE_CANDIDATES=("$WORK/local.rules" "./local.rules" "/etc/suricata/rules/local.rules")
RAPPORT_CANDIDATES=("$WORK/rapport-supervision.md" "./rapport-supervision.md" "$TPHOME/rapport-supervision.md")

first_existing() { local f; for f in "$@"; do [[ -s "$f" ]] && { echo "$f"; return 0; }; done; return 1; }

check() {
  local label="$1"; shift
  total=$((total + 1))
  if "$@"; then
    printf "%s[ OK  ]%s %s\n" "$GREEN" "$NC" "$label"; score=$((score + 1))
  else
    printf "%s[ECHEC]%s %s\n" "$RED" "$NC" "$label"
  fi
}

c_suricata() { command -v suricata >/dev/null 2>&1; }

c_capture() { [[ -n "$(find "$WORK" . -maxdepth 2 -name '*.pcap' 2>/dev/null | head -n1)" ]]; }

c_custom_rules() {
  local f; f="$(first_existing "${RULE_CANDIDATES[@]}")" || return 1
  local n; n="$(grep -cE 'sid:[[:space:]]*100[0-9]{4,}' "$f" 2>/dev/null)"
  [[ "${n:-0}" -ge 6 ]]
}

c_advanced_rule() {
  # au moins une regle avancee : seuil (threshold/detection_filter) ou correlation (flowbits)
  local f; f="$(first_existing "${RULE_CANDIDATES[@]}")" || return 1
  grep -qE 'threshold|detection_filter|flowbits' "$f" 2>/dev/null
}

c_alerts() {
  local eve fast
  eve="$(first_existing "${EVE_CANDIDATES[@]}")" && grep -q '"event_type":[[:space:]]*"alert"' "$eve" 2>/dev/null && return 0
  fast="$(first_existing "${FASTLOG_CANDIDATES[@]}")" && [[ -s "$fast" ]] && return 0
  return 1
}

c_rapport() { first_existing "${RAPPORT_CANDIDATES[@]}" >/dev/null; }

c_rapport_attaques() {
  local f; f="$(first_existing "${RAPPORT_CANDIDATES[@]}")" || return 1
  local hits=0
  grep -qiE 'sql' "$f" && hits=$((hits+1))
  grep -qiE 'shellshock|user-agent|user agent' "$f" && hits=$((hits+1))
  grep -qiE 'eicar' "$f" && hits=$((hits+1))
  grep -qiE 'nikto|scan|balayage|nmap' "$f" && hits=$((hits+1))
  grep -qiE 'traversee|traversal|passwd' "$f" && hits=$((hits+1))
  grep -qiE 'force brute|brute' "$f" && hits=$((hits+1))
  [[ "$hits" -ge 4 ]]
}

c_rapport_furtif() {
  # la menace furtive (balise C2 / exfiltration) a ete decouverte et documentee
  local f; f="$(first_existing "${RAPPORT_CANDIDATES[@]}")" || return 1
  grep -qiE 'balise|beacon|c2|c&c|command.?and.?control|exfiltrat|base64' "$f" 2>/dev/null
}

c_rapport_tuning() {
  local f; f="$(first_existing "${RAPPORT_CANDIDATES[@]}")" || return 1
  grep -qiE 'faux positif|false positive|tuning|affinage|affiner' "$f" 2>/dev/null
}

c_rapport_attack() {
  local f; f="$(first_existing "${RAPPORT_CANDIDATES[@]}")" || return 1
  grep -qE 'T[0-9]{4}' "$f" 2>/dev/null
}

echo "${BOLD}=== Verification : supervision et detection reseau (Suricata) ===${NC}"
check "Suricata est installe"                                   c_suricata
check "Une capture reseau (.pcap) a ete realisee"              c_capture
check "Au moins 6 regles Suricata personnelles ecrites"       c_custom_rules
check "Au moins une regle avancee (seuil ou flowbits)"        c_advanced_rule
check "La detection a produit des alertes"                    c_alerts
check "Un rapport de supervision a ete redige"                c_rapport
check "Le rapport identifie les attaques evidentes"           c_rapport_attaques
check "La menace furtive (balise C2 / exfiltration) est trouvee" c_rapport_furtif
check "Le rapport traite les faux positifs / l'affinage"      c_rapport_tuning
check "Le rapport contient un mapping MITRE ATT&CK"           c_rapport_attack

echo "-------------------------------------------------"
if [[ "$score" -eq "$total" ]]; then
  printf "%sScore : %s/%s. Supervision complete, menace furtive comprise, bravo.%s\n" "$GREEN$BOLD" "$score" "$total" "$NC"
else
  printf "%sScore : %s/%s. Corrige les lignes [ECHEC] puis relance.%s\n" "$BOLD" "$score" "$total" "$NC"
  echo "Dossier de travail attendu : $WORK (capture.pcap, local.rules, rapport-supervision.md)"
fi

#!/usr/bin/env bash
# Incident simule : charge processeur anormale.
cd "$(dirname "$0")" || exit 1
source ./glpi.env 2>/dev/null
source ./lib-glpi.sh

POSTE=$(hostname)
DATE=$(date "+%d/%m/%Y %H:%M")
CHARGE=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | tr -d ' ')
COEURS=$(nproc)

TITRE="[$POSTE] Charge processeur elevee"
CONTENU="Alerte automatique du poste $POSTE.\nLa charge moyenne sur 1 minute est de $CHARGE pour $COEURS coeur(s).\nLe poste est anormalement lent, a verifier.\nReleve le $DATE."

creer_ticket "$TITRE" "$CONTENU"

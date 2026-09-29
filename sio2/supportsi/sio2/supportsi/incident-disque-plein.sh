#!/usr/bin/env bash
# Incident simule : disque presque plein.
cd "$(dirname "$0")" || exit 1
source ./glpi.env 2>/dev/null
source ./lib-glpi.sh

POSTE=$(hostname)
DATE=$(date "+%d/%m/%Y %H:%M")
DISQUE=$(df -h / | awk 'NR==2 {print "utilisation "$5" sur "$1", espace libre "$4}')

TITRE="[$POSTE] Disque presque plein"
CONTENU="Alerte automatique du poste $POSTE.\nLe disque systeme approche de la saturation.\nDetail : $DISQUE.\nReleve le $DATE.\nAction attendue : liberer de l'espace ou etendre le volume."

creer_ticket "$TITRE" "$CONTENU"

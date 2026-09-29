#!/usr/bin/env bash
# Incident simule : imprimante reseau injoignable.
cd "$(dirname "$0")" || exit 1
source ./glpi.env 2>/dev/null
source ./lib-glpi.sh

POSTE=$(hostname)
DATE=$(date "+%d/%m/%Y %H:%M")
IMPRIMANTE="192.168.70.200"   # adresse fictive d'une imprimante reseau

if ping -c 2 -W 1 "$IMPRIMANTE" > /dev/null 2>&1; then
    echo "L'imprimante repond, aucun incident."
    exit 0
fi

TITRE="[$POSTE] Imprimante reseau injoignable"
CONTENU="Alerte automatique du poste $POSTE.\nL'imprimante reseau ($IMPRIMANTE) ne repond plus au ping.\nLes utilisateurs ne peuvent plus imprimer.\nReleve le $DATE."

creer_ticket "$TITRE" "$CONTENU"

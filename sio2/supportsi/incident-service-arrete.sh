#!/usr/bin/env bash
# Incident simule : un service important est arrete.
cd "$(dirname "$0")" || exit 1
source ./glpi.env 2>/dev/null
source ./lib-glpi.sh

POSTE=$(hostname)
DATE=$(date "+%d/%m/%Y %H:%M")
SERVICE="cups"   # service d'impression

if systemctl is-active --quiet "$SERVICE"; then
    ETAT="actif (incident simule pour la demonstration)"
else
    ETAT="arrete"
fi

TITRE="[$POSTE] Service $SERVICE arrete"
CONTENU="Alerte automatique du poste $POSTE.\nLe service $SERVICE est signale comme $ETAT.\nUn service critique interrompu doit etre relance et surveille.\nReleve le $DATE."

creer_ticket "$TITRE" "$CONTENU"

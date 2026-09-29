#!/usr/bin/env bash
# Incident simule : service interne inaccessible.
cd "$(dirname "$0")" || exit 1
source ./glpi.env 2>/dev/null
source ./lib-glpi.sh

POSTE=$(hostname)
DATE=$(date "+%d/%m/%Y %H:%M")
CIBLE="serveur-intranet.local"   # nom fictif d'un service interne

if ping -c 2 -W 1 "$CIBLE" > /dev/null 2>&1; then
    echo "Le service repond, aucun incident."
    exit 0
fi

TITRE="[$POSTE] Service intranet inaccessible"
CONTENU="Alerte automatique du poste $POSTE.\nLe service interne ($CIBLE) est injoignable depuis ce poste.\nLes utilisateurs signalent qu'ils n'accedent plus a l'intranet.\nReleve le $DATE."

creer_ticket "$TITRE" "$CONTENU"

#!/usr/bin/env bash
# Incident simule : tentatives de connexion suspectes.
cd "$(dirname "$0")" || exit 1
source ./glpi.env 2>/dev/null
source ./lib-glpi.sh

POSTE=$(hostname)
DATE=$(date "+%d/%m/%Y %H:%M")
# Compte les echecs d'authentification SSH des dernieres 24h (plus complet avec sudo)
ECHECS=$(journalctl -q _COMM=sshd --since "-24h" 2>/dev/null | grep -c -i "Failed password")
[ -z "$ECHECS" ] && ECHECS=0

TITRE="[$POSTE] Tentatives de connexion suspectes"
CONTENU="Alerte automatique du poste $POSTE.\nDes echecs d'authentification ont ete detectes : $ECHECS tentative(s) echouee(s) sur les dernieres 24h.\nUne activite de force brute est possible, a investiguer.\nReleve le $DATE."

creer_ticket "$TITRE" "$CONTENU"

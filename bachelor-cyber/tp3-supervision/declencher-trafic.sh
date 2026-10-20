#!/usr/bin/env bash
#
# declencher-trafic.sh
# Genere un trafic realiste et bruite vers le service local, pour que tu l'analyses
# avec Suricata. A lancer PENDANT une capture (tcpdump sur l'interface de loopback).
# Tout vise 127.0.0.1 et reste inoffensif. Duree : environ une minute.
#
# ATTENTION : ce script melange du trafic legitime, des attaques evidentes, ET une
# activite furtive qui N'EST PAS annoncee dans le sujet. A toi de la reperer.
#
# Usage : sudo bash declencher-trafic.sh
#
set -uo pipefail

TARGET=127.0.0.1
WEB="http://$TARGET:8080"
NORMAL_UA="Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0"

echo "==> Generation du trafic (environ 1 minute)..."

# --- Bruit de fond legitime ---
echo "  - trafic legitime"
for i in 1 2 3 4 5 6; do
  curl -s -A "$NORMAL_UA" "$WEB/" >/dev/null 2>&1 || true
  curl -s -A "$NORMAL_UA" "$WEB/index.html" >/dev/null 2>&1 || true
  sleep 0.2
done

# --- Reconnaissance ---
echo "  - balayage de ports"
nmap -sT -p 1-1000 "$TARGET" >/dev/null 2>&1 || true

# --- Force brute sur le formulaire de connexion (rafale) ---
echo "  - rafale d'authentification (force brute)"
for i in $(seq 1 35); do
  curl -s "$WEB/login.php?user=admin&pass=pass$i" >/dev/null 2>&1 || true
  sleep 0.08
done

# --- Tentatives d'exploitation evidentes ---
echo "  - injection SQL"
curl -s "$WEB/login.php?user=admin%27%20OR%20%271%27%3D%271" >/dev/null 2>&1 || true
echo "  - User-Agent Shellshock"
curl -s -A "() { :; }; echo vulnerable" "$WEB/" >/dev/null 2>&1 || true
echo "  - User-Agent Nikto"
curl -s -A "Mozilla/5.00 (Nikto/2.1.6)" "$WEB/admin/" >/dev/null 2>&1 || true
echo "  - traversee de repertoire"
curl -s "$WEB/../../../../etc/passwd" >/dev/null 2>&1 || true
echo "  - fichier de test EICAR"
curl -s "$WEB/eicar.txt" >/dev/null 2>&1 || true

# --- Activite furtive post-compromission (NON annoncee : a decouvrir) ---
# Balise C2 : memes petites requetes repetees a intervalle regulier.
echo "  - trafic de fond (suite)"
for i in $(seq 1 24); do
  curl -s -H "X-Session: 7f3a2b9c" "$WEB/pixel.gif?c=7f3a2b9c" >/dev/null 2>&1 || true
  sleep 0.4
done
# Exfiltration : une requete transportant une grosse charge encodee en base64.
BLOB="$(head -c 400 /dev/urandom | base64 | tr -d '\n')"
curl -s "$WEB/upload?token=7f3a2b9c&d=$BLOB" >/dev/null 2>&1 || true

echo "==> Trafic genere. Arrete ta capture, puis analyse-la avec Suricata."

# 🕵️ TP : Détecter et traiter une intrusion (blue team)

**Formation :** Bachelor SRC (Systèmes, Réseaux et Cybersécurité)
**Niveau :** 3e année, avancé
**Type :** TP, formatif
**Environnement :** la VM Ubuntu Server du TP précédent, dans VirtualBox

---

## 🎯 Le scénario

Le serveur que tu as durci la dernière fois présente un comportement suspect : des connexions inhabituelles, un compte que personne n'a créé. L'attaquant a profité d'une faiblesse que tu as depuis corrigée, mais il était déjà entré : durcir un serveur ferme la porte, ça n'expulse pas quelqu'un qui est déjà à l'intérieur. La direction te demande de mener l'**investigation** : comprendre ce qui s'est passé, par où l'attaquant est entré, ce qu'il a fait, puis **nettoyer** sa présence et **renforcer la détection** pour que ça ne se reproduise pas.

C'est le travail d'une équipe **blue team** : analyser les journaux, reconstituer la chronologie d'un incident, éradiquer la persistance, améliorer la surveillance. Un script d'auto-correction, `verif-tp2.sh`, valide ton travail.

> ⚠️ **Cadre.** Tu travailles sur **ta** VM, jetable et isolée.

---

## 🧰 Mise en place

> 💻 **Sur ta VM**

Récupère la dernière version du dépôt et place-toi dans le dossier de ce TP :

```bash
cd ~/UIMM && git pull
cd bachelor-cyber/tp2-detection
```

🧠 **Pourquoi des journaux ?** Tout ce qui se passe sur un serveur Linux laisse une trace dans des fichiers de journalisation (les logs). Les connexions, les authentifications et l'usage de `sudo` sont enregistrés dans `/var/log/auth.log`. C'est la première source d'un analyste. Assure-toi que la journalisation tourne :

```bash
sudo apt update && sudo apt install -y rsyslog
sudo systemctl enable --now rsyslog
```

Lance ensuite la mise en scène de l'incident :

```bash
sudo bash simuler-attaque.sh
```

🧠 **Ce que fait le script.** Il écrit dans les journaux les traces d'une attaque réelle (balayage de comptes, connexion réussie, élévation de privilèges) et installe une véritable persistance que tu devras retrouver et supprimer. Rien de destructeur.

---

## 🔍 TP 1 : Repérer l'attaque dans les journaux

**Objectif :** détecter l'anomalie et mesurer son ampleur.

🧠 **Attaque par force brute.** Un attaquant qui essaie des quantités de mots de passe à la suite génère une avalanche d'échecs d'authentification. C'est un signal très visible dans les journaux.

> 💻 **Sur ta VM**

Compte les échecs de connexion SSH :

```bash
sudo grep "Failed password" /var/log/auth.log | wc -l
```

Qui est responsable ? Classe les adresses IP par nombre de tentatives :

```bash
sudo grep "Failed password" /var/log/auth.log | grep -oE "from [0-9.]+" | sort | uniq -c | sort -rn
```

👉 Note l'**adresse IP** qui ressort nettement. C'est celle de l'attaquant.

🧠 **Comptes visés.** Observer quels noms d'utilisateur l'attaquant a tentés renseigne sur sa méthode (dictionnaire de comptes classiques).

```bash
sudo grep "Failed password" /var/log/auth.log | grep -oE "user [a-z]+" | sort | uniq -c | sort -rn
```

---

## 🧩 TP 2 : Reconstituer la chronologie

**Objectif :** passer d'un tas d'échecs à une histoire : entrée, action, persistance.

🧠 **Le tournant.** Au milieu des échecs, une seule ligne change tout : un `Accepted password`. C'est le moment où l'attaquant a réussi à entrer.

> 💻 **Sur ta VM**

Trouve la connexion réussie et le compte concerné :

```bash
sudo grep "Accepted password" /var/log/auth.log
```

👉 Note le **compte** par lequel l'attaquant est entré. Tu le reconnais : c'est celui dont le mot de passe trivial t'avait occupé au TP précédent.

🧠 **Le point important.** Tu as depuis durci ce compte, mais l'attaquant était déjà passé. Corriger la faille d'entrée après coup ne supprime pas ce qu'il a laissé derrière lui : c'est tout l'objet de l'étape suivante.

Qu'a-t-il fait ensuite avec les droits root ? Cherche l'usage de `sudo` :

```bash
sudo grep "sudo:" /var/log/auth.log
```

A-t-il créé un compte ? Cherche la trace :

```bash
sudo grep "new user" /var/log/auth.log
```

👉 Tu tiens maintenant la chronologie : balayage, intrusion via un compte faible, élévation, puis création d'un compte de persistance.

---

## 🧹 TP 3 : Éradiquer la persistance

**Objectif :** retirer tout ce que l'attaquant a laissé pour revenir.

🧠 **Persistance.** Après une intrusion, un attaquant installe des moyens de revenir même si la faille d'entrée est corrigée : un compte caché, une tâche planifiée, un script discret. Nettoyer l'incident, c'est traquer et supprimer chacun de ces éléments.

> 💻 **Sur ta VM**

D'abord le compte de persistance. Tu as vu son nom dans les journaux ; confirme qu'il a bien les droits root et supprime-le. Attention, comme au TP précédent, un compte à uid 0 ne se supprime pas avec `userdel` :

```bash
awk -F: '($3==0){print $1}' /etc/passwd            # il ne doit rester que root
sudo sed -i '/^svc-update:/d' /etc/passwd /etc/shadow
```

Cherche ensuite une tâche planifiée suspecte et le script qu'elle lance :

```bash
ls -la /etc/cron.d/
cat /etc/cron.d/svc-update
```

👉 Supprime la tâche et le script associé :

```bash
sudo rm /etc/cron.d/svc-update
sudo rm /usr/local/bin/.sync
```

🧠 **Fichiers cachés.** Un nom commençant par un point n'apparaît pas dans un `ls` classique. Les attaquants s'en servent pour se dissimuler. Pense au `-a` de `ls` pour les voir.

---

## 🛡️ TP 4 : Renforcer la détection avec Fail2ban

**Objectif :** mettre en place une défense qui bloque automatiquement ce type d'attaque à l'avenir.

🧠 **Fail2ban.** C'est un outil qui surveille les journaux en temps réel et bannit automatiquement, via le pare-feu, une adresse IP qui accumule les échecs d'authentification. C'est la réponse directe à l'attaque par force brute que tu viens d'analyser.

> 💻 **Sur ta VM**

Installe Fail2ban :

```bash
sudo apt install -y fail2ban
```

🧠 **Jail.** Dans Fail2ban, une « jail » associe un service à surveiller (ici SSH) à une règle de bannissement. On la configure dans un fichier local pour ne pas écraser la configuration par défaut.

👉 Crée la configuration de la jail SSH :

```bash
sudo nano /etc/fail2ban/jail.local
```

Avec le contenu :

```
[sshd]
enabled = true
maxretry = 4
bantime = 1h
findtime = 10m
```

👉 Active et démarre le service :

```bash
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

🧠 **Mise à l'épreuve.** Une défense se teste. Rejoue une rafale d'attaque et vérifie que Fail2ban réagit :

```bash
sudo bash simuler-attaque.sh rejouer
sleep 10
sudo fail2ban-client status sshd
```

👉 L'adresse de l'attaquant doit apparaître dans la liste des IP bannies.

---

## 🧾 TP 5 : Rédiger le rapport d'incident

**Objectif :** formaliser ton analyse, comme attendu après tout incident réel.

🧠 **Pourquoi un rapport ?** Un incident doit être documenté : pour la direction, pour d'éventuelles suites, et pour en tirer des leçons. C'est un livrable à part entière du métier.

> 💻 **Sur ta VM**

Crée le rapport (le script de correction le cherche à cet emplacement) :

```bash
nano ~/rapport-incident.md
```

Il doit couvrir, dans tes mots :

- la **chronologie** de l'attaque (balayage, intrusion, élévation, persistance),
- l'**adresse IP** de l'attaquant et le **compte** utilisé pour entrer,
- ce que l'attaquant a laissé et comment tu l'as **éradiqué**,
- la **mesure de détection** mise en place et la preuve qu'elle fonctionne,
- une **recommandation** pour éviter ce type d'intrusion à l'avenir.

---

## ✅ Vérifier et conclure

👉 Lance l'auto-correction :

```bash
sudo bash verif-tp2.sh
```

**Livrable :** ton `rapport-incident.md` et une capture du score.

---

## 🧰 Commandes utiles (récapitulatif)

```bash
# Analyse des journaux
sudo grep "Failed password" /var/log/auth.log | wc -l
sudo grep "Failed password" /var/log/auth.log | grep -oE "from [0-9.]+" | sort | uniq -c | sort -rn
sudo grep "Accepted password" /var/log/auth.log
sudo grep "sudo:" /var/log/auth.log

# Eradication de la persistance
awk -F: '($3==0){print $1}' /etc/passwd
sudo sed -i '/^svc-update:/d' /etc/passwd /etc/shadow
ls -la /etc/cron.d/

# Detection
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

---

## ✅ Conclusion

Tu viens de parcourir le cycle de réponse à un incident : **détecter** l'attaque dans les journaux, **reconstituer** la chronologie, **éradiquer** la persistance de l'attaquant, **renforcer** la détection, et **documenter** le tout dans un rapport. C'est exactement la démarche d'un analyste en SOC. La prochaine étape logique sera la supervision centralisée, pour détecter ce genre d'événement en temps réel plutôt qu'après coup.

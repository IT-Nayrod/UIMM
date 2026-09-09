# Lab de durcissement Linux (Bachelor SRC)

Maquette pour un TP de **sécurisation d'un serveur Linux**. Deux scripts :

- `install-lab.sh` place le serveur dans un état volontairement vulnérable.
- `verif.sh` contrôle le durcissement et affiche un score sur 10.

Les deux scripts **n'installent rien** (aucun `apt install`). Ils n'utilisent que les outils d'une installation Ubuntu Server de base, donc **tout fonctionne hors ligne** une fois la VM créée.

## Prérequis

- Une **VM Ubuntu Server 22.04 ou 24.04 LTS**, jetable, dans VirtualBox.
- À l'installation de l'OS, **cocher "Install OpenSSH server"**.
- Réseau de la VM en **NAT** (aucune exposition vers un vrai réseau).

> ⚠️ `install-lab.sh` affaiblit délibérément la machine (compte root caché, SSH permissif, service en clair, binaire SUID, etc.). À n'exécuter **que** dans une VM isolée. Ne jamais l'utiliser sur un serveur réel.

## Mise en place

Idéalement une fois, en amont, avec une bonne connexion (création de la VM, OpenSSH, récupération du dépôt). Ensuite le TP se fait hors ligne.

```bash
# récupérer le dépôt (ou copier les deux scripts depuis le partage de la classe)
git clone <URL_DU_DEPOT> lab-securisation
cd lab-securisation

# rendre le serveur vulnérable
sudo bash install-lab.sh
```

## Déroulé du TP

1. `sudo bash verif.sh` pour voir l'état de départ et la liste des points à corriger.
2. Durcir le serveur (voir le sujet du TP).
3. Relancer `sudo bash verif.sh` jusqu'à obtenir **10/10**.

## Contenu

| Fichier | Rôle |
|---------|------|
| `install-lab.sh` | Provisionne le serveur vulnérable (hors ligne) |
| `verif.sh` | Vérifie le durcissement, note sur 10 |
| `TP-securisation-serveur.md` | Sujet du TP pour les étudiants |

## Note formateur

`verif.sh` fait aussi office de checklist d'objectifs pour les étudiants et d'auto-correction (gain de temps à la notation).

Si tu préfères une version « découverte » où les étudiants doivent trouver les failles eux-mêmes sans indice, ne distribue pas `verif.sh` et lance-le toi-même en fin de séance : `install-lab.sh` seul suffit alors côté étudiant.

> ⚠️ `install-lab.sh` révèle toutes les failles à la lecture. Pour une évaluation notée, garde-le côté formateur et ne fournis aux étudiants qu'une VM déjà provisionnée.

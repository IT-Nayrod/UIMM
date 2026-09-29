# Scripts d'incidents - centre de services GLPI (BTS SIO 2, Support SI)

Ces scripts simulent des incidents sur un poste et ouvrent automatiquement
un ticket dans GLPI via son API REST.

## Prérequis
- git et curl installés : `sudo apt install -y git curl`
- Un serveur GLPI avec l'API REST activée, un client API (app-token) et un
  compte de service dont on a la clé d'accès distant (user-token).

## Mise en route
1. Copier le fichier d'exemple et renseigner ses valeurs :
   `cp glpi.env.exemple glpi.env`
   puis éditer `glpi.env`.
2. Rendre les scripts exécutables :
   `chmod +x *.sh`
3. Lancer un scénario, par exemple :
   `./incident-disque-plein.sh`

## Quel script sur quel poste
- Poste bureautique (client2) : `incident-disque-plein.sh`,
  `incident-imprimante-injoignable.sh`, `incident-connexion-internet.sh`
- Poste technique (client3) : `incident-service-arrete.sh`,
  `incident-connexions-suspectes.sh`, `incident-charge-cpu.sh`

## Notes
- Les scripts acceptent un serveur en HTTPS avec certificat auto-signe
  (option -k de curl). Adapter GLPI_URL en http ou https selon le serveur.
- Le fichier glpi.env contient des secrets : il n'est jamais versionne.
- Certains scripts (connexions suspectes) remontent davantage avec sudo.

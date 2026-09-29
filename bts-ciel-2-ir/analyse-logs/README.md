# TP analyse de logs (remise en forme) - BTS CIEL 2

Scripts de simulation qui generent des traces dans les logs, a analyser ensuite.

## Machines (lab intnet-secu)
- srv-cible : 192.168.100.10 (serveur, contient les logs a analyser)
- poste-audit : 192.168.100.20 (attaquant)

## Utilisation
1. Sur srv-cible : `./sur-srv-cible.sh` (prepare les sources de logs et genere des evenements locaux)
2. Sur poste-audit : `./sur-poste-audit.sh` (lance les attaques vers srv-cible)
3. Sur srv-cible : analyser les logs et rediger le rapport.

Les scripts sont sans danger : le compte de test cree est supprime, l'analyse reste en lecture seule.

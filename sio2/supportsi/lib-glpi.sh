#!/usr/bin/env bash
# Fonctions communes pour dialoguer avec l'API REST de GLPI.
# Ce fichier n'est pas lance directement : il est charge (source) par les scripts d'incident.

# Verifie que la configuration est bien chargee
verifier_config() {
    if [ -z "$GLPI_URL" ] || [ -z "$APP_TOKEN" ] || [ -z "$USER_TOKEN" ]; then
        echo "Erreur : configuration manquante. As-tu cree et rempli le fichier glpi.env ?"
        exit 1
    fi
}

# Ouvre une session et renvoie le jeton de session
ouvrir_session() {
    curl -sk -X GET "$GLPI_URL/initSession" \
        -H "Content-Type: application/json" \
        -H "Authorization: user_token $USER_TOKEN" \
        -H "App-Token: $APP_TOKEN" \
        | grep -o '"session_token":"[^"]*"' | cut -d'"' -f4
}

# Ferme la session ( $1 = jeton de session )
fermer_session() {
    curl -sk -X GET "$GLPI_URL/killSession" \
        -H "Session-Token: $1" \
        -H "App-Token: $APP_TOKEN" > /dev/null
}

# Cree un ticket ( $1 = titre, $2 = description )
creer_ticket() {
    local titre="$1"
    local description="$2"
    verifier_config

    local session
    session=$(ouvrir_session)
    if [ -z "$session" ]; then
        echo "Erreur : impossible d'ouvrir une session GLPI. Verifie GLPI_URL et les jetons."
        exit 1
    fi

    local reponse
    reponse=$(curl -sk -X POST "$GLPI_URL/Ticket" \
        -H "Content-Type: application/json" \
        -H "Session-Token: $session" \
        -H "App-Token: $APP_TOKEN" \
        -d "{\"input\": {\"name\": \"$titre\", \"content\": \"$description\"}}")

    fermer_session "$session"

    if echo "$reponse" | grep -q '"id"'; then
        local id
        id=$(echo "$reponse" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
        echo "Ticket cree dans GLPI (numero $id)."
    else
        echo "Echec de la creation du ticket. Reponse : $reponse"
    fi
}

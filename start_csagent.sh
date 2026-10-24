#!/usr/bin/env bash
# start_csagent.sh - mode "CSAgent lance CSFlow" (MCP).
#  1. un CSAgent "worker" en arriere-plan (--api, port 8080) : il sert les etapes `agent` des workflows ;
#  2. le CSAgent interactif au premier plan, avec CSFlow declare comme serveur MCP (mcp.json).
# Le CSAgent interactif tourne SANS --yes : chaque appel MCP vous est demande.
# Fermer le CSAgent interactif arrete le worker.

cd "$(dirname "$0")"

CSAGENT_BIN="${CSAGENT_BIN:-csagent}"
PORT="${PORT:-8080}"
API_KEY="${API_KEY:-demo-secret}"
MODEL="${MODEL:-}"          # ex : MODEL=mon-modele-rapide (vide = routage automatique)

if [ -z "$ALBERT_API_KEY" ]; then
    echo " ERREUR : ALBERT_API_KEY n'est pas definie (export ALBERT_API_KEY=ta-cle)."; exit 1
fi
if ! command -v "$CSAGENT_BIN" >/dev/null 2>&1; then
    echo " ERREUR : $CSAGENT_BIN est introuvable dans le PATH (adapte CSAGENT_BIN)."; exit 1
fi
if [ ! -f mcp.json ]; then
    # Meme logique que start_csagent.bat : l'exe s'il est la, sinon le mode sources.
    if   [ -x ./CSFlow ]; then cp mcp.json.example mcp.json
    elif [ -f app.py ];   then cp mcp.linux.source.example mcp.json
    else
        echo " ERREUR : mcp.json introuvable (et ni CSFlow ni app.py a cote de ce fichier)."; exit 1
    fi
    echo "  mcp.json cree (verifiez la commande si besoin)."
fi

# Worker : memoire separee (--mem) pour ne pas melanger avec votre conversation
"$CSAGENT_BIN" --api --yes --port "$PORT" --api-key "$API_KEY" ${MODEL:+--model "$MODEL"} --mem csflow_worker --no-distill >csagent_worker.log 2>&1 &
WORKER_PID=$!
trap 'kill "$WORKER_PID" 2>/dev/null' EXIT INT TERM
sleep 3
if ! kill -0 "$WORKER_PID" 2>/dev/null; then
    echo " ERREUR : le worker CSAgent s'est arrete (voir csagent_worker.log)."; exit 1
fi

echo "  Worker CSAgent : http://localhost:$PORT   (log : csagent_worker.log)"
echo "  CSAgent interactif avec le serveur MCP CSFlow..."
"$CSAGENT_BIN" --mcp-config mcp.json
echo "  CSAgent ferme -- arret du worker."
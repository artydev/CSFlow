# Poor Man's n8n — Python × CSAgent

> Workflow automation where Python wires the steps and CSAgent handles the reasoning.

---

## Démarrage rapide (Windows)

**1. Installer les dépendances** (Python 3.10+)

```bat
pip install -r requirements.txt
```

**2. Lancer CSAgent** dans un terminal dédié — *depuis ce dossier* `workflow\`
(CSAgent n'écrit que dans son dossier courant ; `start_agent.bat` s'y place tout seul)

```bat
set ALBERT_API_KEY=ta-cle
start_agent.bat
```

**3. Lancer un workflow**

Interface graphique (EEL, ouvre Chrome ou Edge) :

```bat
python app.py
```

L'interface comprend : une barre latérale (workflows et étapes avec leur état), le **graphe** du workflow
(calculé depuis `next` / `on_approve` / `on_reject`), le **détail de l'étape** (onglets Détails,
Entrées / Sorties, Historique), l'**éditeur YAML** (l'étape choisie est surlignée) et les **événements**
d'exécution. Au-dessus de 1400 px de large, YAML et événements sont côte à côte ; en dessous, ils
passent en onglets.

Accessibilité : texte de 13 à 15 px minimum (en `rem`, il suit la taille de texte du navigateur),
contrastes WCAG AA, état toujours indiqué par un libellé et un symbole (jamais la couleur seule),
navigation complète au clavier (la liste des étapes remplace le graphe), anneau de focus visible,
bouton « Approuver » qui prend le focus à la demande de validation, animations coupées si le système
demande « réduire les animations ».

ou en ligne de commande :

```bat
python engine.py workflows\demo_autofix.yaml
python engine.py workflows\demo_report.yaml
python engine.py workflows\demo_code_review.yaml
```

### Conventions Windows des workflows

- Les chemins sont **relatifs** à `workflow\` (`tmp\sales.csv`), jamais absolus (`C:\temp\...`) :
  l'agent ne peut pas écrire en dehors de son dossier courant.
- Dans le YAML, les commandes shell contenant `\` s'écrivent entre **quotes simples** :
  `cmd: 'python tmp\broken.py'` (en quotes doubles, `\` serait interprété comme un échappement).
- Les commandes shell sont exécutées par `cmd.exe` (`type`, `dir`, `find`, ...).
  Pour compter les lignes d'un fichier : `type fichier | find /c /v ""`.

### Écrire un workflow : quels mots-clés ai-je le droit d'utiliser ?

Le vocabulaire est défini à un seul endroit : le décorateur `@register(..., params={...})` de chaque
nœud (dossier `nodes/`), complété par les mots-clés communs de `schema.py`. Trois outils en découlent :

```bat
python engine.py --nodes                  :: liste les types d'étape et leurs paramètres (REFERENCE.md = même contenu)
python engine.py --check workflows\*.yaml :: valide sans exécuter : types inconnus, clé mal orthographiée,
                                          :: paramètre obligatoire absent, next / on_approve vers une étape inexistante,
                                          :: {{variable}} qui ne correspond à rien. Chaque message donne la ligne.
python engine.py --schema > csflow.schema.json   :: régénère le schéma JSON de l'éditeur
```

- **Autocomplétion dans VS Code** : installer l'extension « YAML » (Red Hat). La première ligne de chaque
  workflow, `# yaml-language-server: $schema=../csflow.schema.json`, suffit : VS Code propose les types,
  les clés de l'étape en cours et affiche leur description au survol.
- **Contrôle automatique** : `python engine.py fichier.yaml` et l'interface valident le fichier avant de
  l'exécuter. Les erreurs bloquent le lancement, les avertissements (clé inconnue, variable vide) s'affichent
  dans le log.
- **Ajouter un type d'étape** : créer `nodes/mon_node.py` avec `@register("mon_type", summary="...", params={...})`,
  l'importer dans `nodes/__init__.py`, puis régénérer `REFERENCE.md` et `csflow.schema.json`.

### Confirmations de CSAgent (`Auto-approve: OFF`)

Sans `--yes`, CSAgent demande une confirmation avant chaque outil destructeur
(`write_file`, `edit_file`, ...) et **attend** `POST /api/confirm`. Le nœud `agent` répond :

- par défaut, la demande apparaît dans l'interface (barre **Approuver / Rejeter**) ou au terminal (`y/n`) ;
- avec `auto_confirm: true` sur l'étape (ou `set CSFLOW_AUTO_CONFIRM=1`), elle est approuvée automatiquement ;
- ou lance CSAgent avec `--yes` (c'est ce que fait `start_agent.bat`) : aucune confirmation n'est alors émise.

```yaml
- id: fix_with_agent
  type: agent
  auto_confirm: true        # équivalent de csagent --yes pour cette étape
  prompt: ...
```

Si CSAgent reste silencieux plus de 15 s, le log affiche `⏳ en attente de CSAgent…` ;
au-delà de `timeout` (180 s par défaut) l'étape échoue au lieu de rester bloquée.

### Démo pour un chef de projet : `copil_projet.yaml`

Workflow en français (14 étapes) : « Préparation du COPIL » pour un projet fictif au bord du dérapage.

| Étape | Qui travaille | Ce que ça démontre |
|---|---|---|
| Plan de projet, notes de réunion | Python (`file_write`) | en vrai : un export Jira / Excel / MS Project |
| Indicateurs de pilotage, statut RAG | **Python** (`shell`) | les chiffres (valeur acquise, CPI, dérive en jours et en €) sont calculés exactement, jamais par une IA |
| Analyse des risques, actions et décisions, rapport COPIL | **CSAgent** (`agent`) | lecture de notes libres, rédaction pour la direction, chaque chiffre repris des fichiers |
| Note d'escalade au sponsor | CSAgent, **seulement si le statut est ROUGE** (`skip_if`) | branche conditionnelle |
| Validation de la cheffe de projet | **Humain** (`human_approval`) | rien n'est diffusé sans accord ; refus = diffusion annulée |

Lancer : `python app.py`, choisir « Préparation du COPIL », cliquer sur Run. Livrables dans `tmp\copil\`.
La date de référence (`date_reference`) est fixée au 16/10/2026 pour que la démo soit reproductible ; la modifier dans le YAML pour rejouer à une autre date.

---

## What you will see

```
╔══════════════════════════════════════════════════════════╗
║  🔧  auto-fix-demo                                       ║
╚══════════════════════════════════════════════════════════╝

────────────────────────────────────────────────────────────────
  [1/5] create_broken_script  (file_write)
  ✓  Written 312 chars → tmp/broken.py

────────────────────────────────────────────────────────────────
  [2/5] first_run  (shell)
  ✗  ZeroDivisionError: division by zero ⏎ …

────────────────────────────────────────────────────────────────
  [3/5] fix_with_agent  (agent)
  💭 There are two bugs: compute_average([]) and a typo 'totla'.
  🔧 read_file  {"path": "tmp/broken.py"}
  ✓  # Sales report…
  🔧 write_file {"path": "tmp/broken.py", "content": "…"}
  ✓  written

────────────────────────────────────────────────────────────────
  [4/5] verify_run  (shell)
  ✓  Average revenue :  11,175.00 ⏎ Total revenue   :  44,700.00

────────────────────────────────────────────────────────────────
  [5/5] done  (log)

  Script fixed and verified ✓
  Output:
  Average revenue :  11,175.00
  Total revenue   :  44,700.00

────────────────────────────────────────────────────────────────
  ✅  Workflow complete.
```

---

## How it works

```
workflow.yaml
     │
     ▼
 engine.py ── resolves {{variables}} ── dispatches to node handlers
     │
     ├── file_write / file_read    →  Python pathlib
     ├── shell                     →  Python subprocess
     ├── http_get / http_post      →  Python urllib
     ├── transform                 →  Python eval (restricted)
     ├── log                       →  print()
     └── agent                     →  CSAgent /api/chat  (SSE stream)
                                           ↑
                                     C# reasoning engine
                                     reads files, runs shell,
                                     writes fixes back to disk
```

The `agent` node is what sets this apart from a plain shell script. It receives
the prompt (with variables already resolved) and autonomously reasons through
it — reading files, running commands, rewriting code — while streaming every
thought and tool call back to the terminal.

---

## Node reference

| Type | What it does | Key params |
|---|---|---|
| `file_read` | Read a file | `path` |
| `file_write` | Write a file (creates dirs) | `path`, `content` |
| `shell` | Run a shell command | `cmd`, `timeout` |
| `http_get` | HTTP GET | `url`, `headers` |
| `http_post` | HTTP POST | `url`, `body`, `headers` |
| `agent` | CSAgent reasoning step | `prompt`, `csagent_url`, `csagent_key` |
| `transform` | Python expression | `expression` |
| `log` | Print a message | `message`, `level` |

---

## Workflow syntax

```yaml
name: my-workflow

steps:

  - id: fetch                     # referenced as {{fetch.output}}
    type: http_get
    url: "https://api.example.com/data"

  - id: process
    type: agent
    skip_if: "{{fetch.status_code}} != 200"   # skip this step if condition is true
    prompt: |
      Analyse this data: {{fetch.body}}
      Write a summary to tmp/summary.md.

  - id: read_back
    type: file_read
    path: "tmp/summary.md"

  - id: show
    type: log
    message: "{{read_back.output}}"
```

### Built-in variables

| Token | Value |
|---|---|
| `{{today}}` | Current date — `2026-10-16` |
| `{{now}}` | Current datetime — `2026-10-16T13:45:00` |
| `{{env.MY_VAR}}` | Environment variable |

### Step output fields

Every node returns at least `output` and `status`.  Node-specific extras:

| Node | Extra fields |
|---|---|
| `shell` | `stdout`, `stderr`, `returncode` (int) |
| `http_get/post` | `body`, `status_code` (int) |
| `file_read` | `content` (alias for `output`) |
| `file_write` | `path` |
| `agent` | `thoughts` |
| `transform` | `value` (raw Python value) |

### `skip_if`

Any step can be skipped based on a condition:
```yaml
skip_if: "{{prev.returncode}} == 0"
skip_if: "{{fetch.status_code}} == 404"
```

### `continue_on_error`

Set to `true` to keep the workflow running even when a step fails:
```yaml
- id: first_attempt
  type: shell
  cmd: "python script.py"
  continue_on_error: true
```

---

## Files

```
workflow/
├── app.py                   ← interface EEL + UmaiJS (python app.py)
├── engine.py                ← workflow runner (--check, --nodes, --schema)
├── schema.py                ← vocabulaire du YAML : validation, aide, schéma JSON
├── csflow.schema.json       ← schéma pour l'autocomplétion VS Code (généré)
├── REFERENCE.md             ← liste des types et paramètres (générée)
├── start_agent.bat          ← lance CSAgent depuis ce dossier
├── ui/index.html            ← interface (Umai embarqué, aucun CDN)
├── nodes/
│   ├── __init__.py          ← registry
│   ├── file_node.py
│   ├── shell_node.py
│   ├── http_node.py
│   ├── agent_node.py        ← CSAgent SSE integration
│   ├── log_node.py
│   └── transform_node.py
├── workflows/
│   ├── copil_projet.yaml    ← DÉMO CHEF DE PROJET : préparation d'un COPIL (en français)
│   ├── demo_autofix.yaml    ← corrige un script cassé
│   ├── demo_report.yaml     ← analyse un CSV → rapport markdown
│   ├── demo_code_review.yaml← inspection + validation humaine + correction
│   └── dev_fix_tests.yaml   ← tests → CSAgent corrige → re-test → validation → commit
├── tmp/                     ← workflows write their artefacts here
└── requirements.txt         ← pyyaml + eel
```

---

## Requirements

- Python 3.10+ et `pip install -r requirements.txt` (pyyaml + eel) **pour lancer depuis les sources** ; inutile avec l'exe compilé (`build_nuitka.bat`), qui embarque l'interpréteur (voir le nœud `python`)
- [CSAgent](https://github.com/artydev/CSAgent) running with `--api --yes`
- An `ALBERT_API_KEY` (or any OpenAI-compatible endpoint via `--endpoint`)

## Workflow développeur : `dev_fix_tests.yaml`

Lance les tests d'un petit projet (dépôt git dans `tmp\devfix`), laisse CSAgent corriger le code
sans toucher aux tests, relance les tests, affiche `git diff --stat`, puis committe seulement
après votre validation (rejet : `git checkout`). Pour votre code, changez `inputs.project` et la
commande de test (`python -m unittest`).

## Disposition réglable

Les panneaux de l'interface se règlent à la souris comme au clavier (les réglages sont mémorisés dans le navigateur) :

- **Poignées** entre le graphe et les panneaux du bas (hauteur) et entre « Éditeur YAML » et « Événements » (largeur, écrans ≥ 1400 px). Souris : glisser. Clavier : Tab jusqu'à la poignée, puis flèches (2 %), Maj + flèches (10 %), Début / Fin (limites). Entrée ou double-clic : taille par défaut.
- **Masquer le détail** : le bouton à gauche de « Lancer le workflow » cache le panneau de détail de l'étape (à droite) pour donner plus de place au graphe. Le choix est mémorisé.
- **Agrandir** sur chaque panneau (graphe, YAML, événements) : il occupe toute la zone centrale. Échap ou « Restaurer » revient à la disposition normale.

## Console de développement du navigateur

Dans l'application, F12, Ctrl+Maj+I / J / C, Ctrl+U et le clic droit (« Inspecter ») sont désactivés. Ce confort d'usage n'est pas une protection : la page reste accessible dans un onglet normal du navigateur. Pour les réactiver (débogage de l'interface) :

```bat
set CSFLOW_DEBUG=1
python app.py
```

## Scripts Python sans Python installé : le nœud `python`

Les scripts intégrés aux workflows (`file_write` d'un `.py`, puis exécution) n'ont plus besoin de
Python sur le poste : le nœud `python` les exécute avec l'interpréteur **embarqué dans l'exe**.

```yaml
- id: indicateurs
  type: python
  script: 'tmp\copil\kpi.py'            # ou  code: |  (Python inline)
  args: ['tmp\copil\taches.csv', '{{date_reference}}']
  # cwd: 'tmp\projet'   timeout: 60
```

Sorties identiques à `shell` : `output`, `stdout`, `stderr`, `returncode`. Dans l'exe compilé, CSFlow
se relance lui-même (`CSFlow.exe --csflow-python …`), ce qui donne isolation et `timeout`.

Limites : seuls les modules de la bibliothèque standard listés dans `build_nuitka.bat`
(`--include-module`) sont disponibles — ajoutez-y les vôtres — et pas de `pip install` à l'exécution.
Les démos `copil_projet`, `demo_autofix` et `dev_fix_tests` utilisent ce nœud ; `shell` reste là
pour les autres commandes (git, etc.).

**CSAgent et Python :** l'agent exécute ses propres commandes (`sh`) et ne voit pas l'interpréteur embarqué.
Sur un poste sans Python, un agent qui tente `python` ou `py` échoue. Dans les prompts des étapes
`agent`, interdisez-lui d'exécuter du code (« n'exécute rien, utilise read_file/edit_file ») : c'est
l'étape `python` du workflow qui relance le script et rapporte le résultat.

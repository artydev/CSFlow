# Référence du YAML CSFlow
_Générée par `python engine.py --nodes --md` à partir des `@register` de `nodes/`._

## Fichier

- `name` : nom du workflow (affiché dans l'interface)
- `description` : description du workflow
- `inputs` : variables d'entrée, utilisables dans tout le workflow avec {{nom}}
- `steps` *(obligatoire)* : liste des étapes

## Mots-clés de toute étape

- `id` *(obligatoire)* : identifiant unique de l'étape ; son résultat s'utilise avec {{id.output}}
- `type` *(obligatoire)* : type d'étape (liste : python engine.py --nodes)
- `description` : libellé affiché dans l'interface
- `skip_if` : expression Python ; si elle est vraie, l'étape est ignorée. Ex : "'{{statut.output}}' != 'ROUGE'"
- `continue_on_error` : true = le workflow continue même si l'étape échoue
- `next` : id de l'étape suivante (défaut : l'étape suivante dans la liste)
- `on_approve` : human_approval : id de l'étape suivante si approuvé
- `on_reject` : human_approval : id de l'étape suivante si rejeté

## Types d'étape (valeurs de `type:`)


### agent
Envoie une instruction à CSAgent et suit son raisonnement en direct ; sortie : sa dernière réponse.

- `prompt` *(obligatoire)* : instruction en langage naturel envoyée à CSAgent
- `csagent_url` : URL de CSAgent (défaut http://localhost:8080)
- `csagent_key` : clé d'API (défaut demo-secret)
- `timeout` : secondes sans donnée avant abandon (défaut 180)
- `auto_confirm` : true = approuver automatiquement les demandes de confirmation de CSAgent

### end
Termine le workflow (étape finale, aucune étape ne peut la suivre).

- `message` : message affiché à la fin du workflow

### file_read
Lit un fichier texte ; sortie : output (le contenu).

- `path` *(obligatoire)* : chemin du fichier à lire (relatif au dossier workflow)

### file_write
Écrit (ou remplace) un fichier texte ; les dossiers manquants sont créés.

- `path` *(obligatoire)* : fichier à écrire (les dossiers sont créés)
- `content` *(obligatoire)* : texte à écrire

### http_get
Requête HTTP GET ; sorties : body, status_code.

- `url` *(obligatoire)* : adresse à appeler
- `headers` : en-têtes HTTP (dictionnaire)
- `timeout` : secondes avant abandon (défaut 30)

### http_post
Requête HTTP POST ; sorties : body, status_code.

- `url` *(obligatoire)* : adresse à appeler
- `body` : corps de la requête
- `headers` : en-têtes HTTP (dictionnaire)
- `timeout` : secondes avant abandon (défaut 30)

### human_approval
Met le workflow en pause jusqu'à ce qu'un humain approuve ou rejette.

- `message` : question posée à l'humain (défaut « Approve to continue? »)

### log
Affiche un message dans la console et dans le log de l'interface.

- `message` *(obligatoire)* : texte affiché (accepte les {{variables}})
- `level` : info | success | warn | error (défaut info)

### python
Exécute un script Python (fichier ou code inline) avec l'interpréteur embarqué : aucun Python à installer.

- `script` : chemin d'un fichier .py (relatif au dossier de travail)
- `code` : code Python inline (alternative à script)
- `args` : arguments passés au script (liste YAML ou chaîne)
- `cwd` : dossier d'exécution (défaut : dossier de travail)
- `timeout` : secondes avant arrêt du processus (défaut 60)

### shell
Exécute une commande shell (cmd.exe sous Windows, bash ailleurs).

- `cmd` *(obligatoire)* : commande exécutée par cmd.exe (Windows) ou bash ; sorties : output, stdout, stderr, returncode
- `timeout` : secondes avant arrêt du processus (défaut 60)

### transform
Évalue une expression Python pour transformer des données.

- `expression` *(obligatoire)* : expression Python évaluée ; les {{variables}} sont substituées avant

## Variables {{…}}

- `{{today}}` : date du jour (AAAA-MM-JJ)
- `{{now}}` : date et heure (AAAA-MM-JJTHH:MM:SS)
- `{{env.NOM}}` : variable d'environnement NOM
- `{{id.output}}` : résultat de l'étape « id » ; autres champs : {{id.returncode}}, {{id.stdout}}, {{id.status}}... selon le type
- `{{nom}}` : variable déclarée dans `inputs`


# Contribuer à AI Gate

Merci de votre intérêt pour AI Gate !

## Principes
- Petits PRs, messages de commit en français (conventional commits)
- Tests, type-check et lint doivent passer
- Respect du Code de Conduite
- DCO (Signed-off-by) requis sur chaque commit

## Démarrage rapide (monorepo)
- Cloner avec submodules: `git clone --recursive`
- Web (luna-proxy-web): `npm ci && npm run validate`
- API (luna-proxy-api): voir README du sous-repo

## Workflow (aligné au fichier luna-proxy-web/.claude/workflow.md)
1) Planifier (todo list si 3+ étapes) et valider l’approche
2) Marquer in_progress, coder par étapes avec tests
3) `npm run validate` avant chaque commit
4) Commits: `type: description courte` (feat, fix, refactor, docs, test, chore)
5) Ouvrir une PR, compléter le template, lier les issues

## DCO (Developer Certificate of Origin)
Ajoutez une ligne Signed-off-by à chaque commit:

```
Signed-off-by: Prénom Nom <email@example.com>
```

Configurer git pour signer automatiquement:

```
git config --global user.name "Prénom Nom"
git config --global user.email "email@example.com"
git commit -s -m "feat: ajouter X"
```

## Tests et validation
- Web: `cd luna-proxy-web && npm run validate`
- API: se référer au sous-repo

## Signalement de bugs et demandes
- Bugs: Issues (template Bug)
- Features: Issues (template Feature)
- Questions: Discussions ou template Question
- Sécurité: voir SECURITY.md (ne pas créer d’issue publique)

## Communication
- Directe et concise
- Poser des questions si incertain
- Respect du Code de Conduite

## Contact
- Support: support@ai-gate.dev

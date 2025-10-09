#!/usr/bin/env bash
set -euo pipefail

# GitHub org/repo configuration
ORG="luna-assistant-ai"
REPOS=("ai-gate")  # Cible uniquement le monorepo ici. Ajoutez "luna-proxy-web" "luna-proxy-api" si souhaité.

# Team configuration
TEAM_SLUG="maintainers"
# Fournissez les usernames via MAINTAINERS_USERS_CSV="user1,user2" en variable d'env, sinon vide
MAINTAINERS_USERS_CSV=${MAINTAINERS_USERS_CSV:-""}
IFS=',' read -r -a MAINTAINERS_USERS <<< "$MAINTAINERS_USERS_CSV"

info() { echo "[info] $*"; }
warn() { echo "[warn] $*" >&2; }

info "Vérification de l'authentification gh..."
if ! gh auth status >/dev/null 2>&1; then
  warn "GitHub CLI non connecté. Exécutez: gh auth login"
  exit 1
fi

enable_discussions() {
  local repo="$1"
  info "Activer Discussions sur $ORG/$repo"
  local repo_id
  repo_id=$(gh api graphql -F owner="$ORG" -F name="$repo" -f query='
    query($owner:String!,$name:String!){ repository(owner:$owner,name:$name){ id hasDiscussionsEnabled } }' \
    -q .data.repository.id)

  gh api graphql -F id="$repo_id" -f query='
    mutation($id:ID!){ updateRepository(input:{repositoryId:$id,hasDiscussionsEnabled:true}){ repository{ hasDiscussionsEnabled } } }'
  >/dev/null

  info "(Facultatif) Création de catégories: non supportée via API publique — saute."
}

ensure_team_and_access() {
  info "Créer/assurer l'équipe $TEAM_SLUG"
  gh api --method POST "/orgs/$ORG/teams" \
    -f name="$TEAM_SLUG" -f privacy="closed" \
    -f description="Maintainers of $ORG" >/dev/null || true

  if (( ${#MAINTAINERS_USERS[@]} > 0 )); then
    info "Ajouter les membres mainteneurs: ${MAINTAINERS_USERS[*]}"
    for u in "${MAINTAINERS_USERS[@]}"; do
      [[ -z "$u" ]] && continue
      gh api --method PUT "/orgs/$ORG/teams/$TEAM_SLUG/memberships/$u" \
        -f role="maintainer" >/dev/null || true
    done
  else
    warn "Aucun maintainer fourni (MAINTAINERS_USERS_CSV vide). Vous pouvez l'exécuter avec MAINTAINERS_USERS_CSV=\"user1,user2\" ..."
  fi

  info "Donner l'accès 'maintain' sur les repos cibles"
  for repo in "${REPOS[@]}"; do
    gh api --method PUT "/orgs/$ORG/teams/$TEAM_SLUG/repos/$ORG/$repo" \
      -f permission="maintain" >/dev/null
  done
}

protect_main_branch() {
  local repo="$1"
  info "Protéger main sur $ORG/$repo (checks CI + DCO, review CODEOWNERS)"
  # IMPORTANT: adaptez les 'contexts' aux noms de checks visibles dans vos PR (ex: "CI", "DCO")
  read -r -d '' PAYLOAD <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI", "DCO"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null
}
JSON
  echo "$PAYLOAD" | gh api --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/$ORG/$repo/branches/main/protection" \
    --input - >/dev/null
}

main() {
  for repo in "${REPOS[@]}"; do
    enable_discussions "$repo"
  done

  ensure_team_and_access

  for repo in "${REPOS[@]}"; do
    protect_main_branch "$repo"
  done

  info "Terminé. Vérifiez: Discussions activées, équipe mainteneurs assignée, protection main appliquée."
}

main "$@"

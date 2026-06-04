#!/bin/bash
# ============================================================
# Finaliser la publication GitHub
# ============================================================
# Étape 1 : Pusher sample.env
# Étape 2 : Créer le profil GitHub README
# ============================================================

set -e
unset HISTFILE

GITHUB_USER="chekibjomni-design"

echo "=========================================="
echo "  Finalisation publication GitHub"
echo "=========================================="

# --- Token ---
echo ""
echo "Entrez votre token GitHub (scope repo):"
read -rs GITHUB_TOKEN
echo ""

# --- Étape 1: Pusher sample.env ---
echo ""
echo "[1/2] Push sample.env vers sage-x3-connector..."
cd "$(dirname "$0")"

# Ajouter !sample.env au .gitignore pour que sample.env ne soit plus ignoré
if ! grep -q "!sample.env" .gitignore; then
  echo "" >> .gitignore
  echo "# Allow sample.env to be tracked" >> .gitignore
  echo "!sample.env" >> .gitignore
fi

git remote set-url origin https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/sage-x3-connector.git
git push -u origin main
echo "  ✅ sample.env pushé"

# --- Étape 2: Créer le profil GitHub ---
echo ""
echo "[2/2] Création du profil GitHub README..."

# Créer le repo de profil
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_USER/$GITHUB_USER)

if [ "$HTTP_CODE" = "404" ]; then
  # Créer le repo avec auto_init
  curl -sf -H "Authorization: token $GITHUB_TOKEN" \
    -X POST https://api.github.com/user/repos \
    -d "{
      \"name\": \"$GITHUB_USER\",
      \"description\": \"Profile README - Chekib Jomni\",
      \"private\": false,
      \"auto_init\": true
    }" > /dev/null
  echo "  ✅ Repo de profil créé"
elif [ "$HTTP_CODE" = "200" ]; then
  echo "  ✅ Repo de profil existe déjà"
fi

# Lire le README_profile.md et le mettre à jour via GitHub API
README_CONTENT=$(cat README_profile.md | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")

# Récupérer le SHA du README actuel s'il existe
SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_USER/$GITHUB_USER/contents/README.md" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sha',''))" 2>/dev/null || echo "")

# Mettre à jour ou créer le README.md du profil
if [ -n "$SHA" ]; then
  # Mettre à jour
  curl -sf -H "Authorization: token $GITHUB_TOKEN" \
    -X PUT "https://api.github.com/repos/$GITHUB_USER/$GITHUB_USER/contents/README.md" \
    -d "{
      \"message\": \"Update profile README\",
      \"content\": \"$(cat README_profile.md | base64 -w0)\",
      \"sha\": \"$SHA\"
    }" > /dev/null
else
  # Créer
  curl -sf -H "Authorization: token $GITHUB_TOKEN" \
    -X PUT "https://api.github.com/repos/$GITHUB_USER/$GITHUB_USER/contents/README.md" \
    -d "{
      \"message\": \"Create profile README\",
      \"content\": \"$(cat README_profile.md | base64 -w0)\"
    }" > /dev/null
fi
echo "  ✅ Profile README mis à jour"
echo "  https://github.com/$GITHUB_USER"

# Nettoyer
git remote set-url origin https://github.com/$GITHUB_USER/sage-x3-connector.git
GITHUB_TOKEN=""

echo ""
echo "=========================================="
echo "  ✅ Tout est terminé !"
echo "=========================================="
echo "  Repo: https://github.com/$GITHUB_USER/sage-x3-connector"
echo "  Profil: https://github.com/$GITHUB_USER"
echo ""
echo "  ⚠️  N'oubliez pas de révoquer l'ancien token"
echo "     sur https://github.com/settings/tokens"
echo ""

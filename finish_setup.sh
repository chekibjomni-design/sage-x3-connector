#!/bin/bash
# ============================================================
# Finaliser la publication GitHub
# - Push du workflow GitHub Actions
# - Création du profil GitHub README
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

# --- Étape 1: Commit & Push workflow + sample.env ---
echo ""
echo "[1/3] Commit et push des fichiers restants..."
cd "$(dirname "$0")"

git add .github/workflows/python-check.yml
git add -f sample.env 2>/dev/null || true

# Vérifier s'il y a quelque chose à commiter
if git status --short | grep -q .; then
  git commit -m "Add GitHub Actions workflow + sample.env template"
  git remote set-url origin https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/sage-x3-connector.git
  git push
  echo "  ✅ Fichiers pushés"
else
  echo "  ✅ Rien de nouveau à commiter"
fi

# --- Étape 2: Créer le profil GitHub ---
echo ""
echo "[2/3] Création du profil GitHub README..."

# Vérifier ou créer le repo de profil
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_USER/$GITHUB_USER)

if [ "$HTTP_CODE" = "404" ]; then
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

# Lire le README_profile.md et encoder en base64 (portable: tr -d '\\n')
README_B64=$(cat README_profile.md | base64 | tr -d '\n')

# Récupérer le SHA du README actuel s'il existe
SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_USER/$GITHUB_USER/contents/README.md" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sha',''))" 2>/dev/null || echo "")

# Mettre à jour ou créer le README.md du profil
if [ -n "$SHA" ]; then
  curl -sf -H "Authorization: token $GITHUB_TOKEN" \
    -X PUT "https://api.github.com/repos/$GITHUB_USER/$GITHUB_USER/contents/README.md" \
    -d "{
      \"message\": \"Update profile README\",
      \"content\": \"$README_B64\",
      \"sha\": \"$SHA\"
    }" > /dev/null
  echo "  ✅ Profile README mis à jour"
else
  curl -sf -H "Authorization: token $GITHUB_TOKEN" \
    -X PUT "https://api.github.com/repos/$GITHUB_USER/$GITHUB_USER/contents/README.md" \
    -d "{
      \"message\": \"Create profile README\",
      \"content\": \"$README_B64\"
    }" > /dev/null
  echo "  ✅ Profile README créé"
fi

# --- Étape 3: Nettoyage ---
echo ""
echo "[3/3] Nettoyage..."
git remote set-url origin https://github.com/$GITHUB_USER/sage-x3-connector.git
GITHUB_TOKEN=""
unset GITHUB_TOKEN

echo ""
echo "=========================================="
echo "  ✅ Tout est terminé !"
echo "=========================================="
echo "  Repo:  https://github.com/$GITHUB_USER/sage-x3-connector"
echo "  Profil: https://github.com/$GITHUB_USER"
echo ""
echo "  ⚠️  Révoquez l'ancien token sur"
echo "     https://github.com/settings/tokens"
echo ""

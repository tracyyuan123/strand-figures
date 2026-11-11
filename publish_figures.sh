#!/bin/bash
# Publish figures to the public tracyyuan123/strand-figures repo, so Google Slides can fetch them by URL.
#
# Usage:  publish_figures.sh "commit message" /abs/path/fig1.png [/abs/path/fig2.png ...]
#
# Narrow by construction, so that one permission rule for this script cannot become a general git permission:
#   - it only ever touches the strand-figures repo named in REPO below, and only its figures/ directory;
#   - it only accepts .png files that live under Tracy's own tree (ROOT), and refuses anything else;
#   - it stages figures/ only, and aborts if anything outside figures/ ended up staged;
#   - it pushes exactly one branch (main) of exactly one remote (origin), with the read-write deploy key;
#   - it never deletes, moves, rebases, force-pushes, or changes any other repository.
set -euo pipefail

REPO=/n/holylfs06/LABS/mzitnik_lab/Users/jyuan/strand_manuscript_evidence/strand-figures
ROOT=/n/holylfs06/LABS/mzitnik_lab/Users/jyuan
KEY=/n/home11/jiayiyuan/.ssh/strand_figures_deploy
BRANCH=main
RAW=https://raw.githubusercontent.com/tracyyuan123/strand-figures/main/figures

if [ $# -lt 2 ]; then
    echo "usage: $(basename "$0") \"commit message\" fig1.png [fig2.png ...]" >&2
    exit 2
fi
MSG=$1
shift

names=()
for f in "$@"; do
    abs=$(readlink -f "$f")
    case "$abs" in
        "$ROOT"/*) ;;
        *) echo "refusing: $abs is outside $ROOT" >&2; exit 3 ;;
    esac
    case "$abs" in
        *.png) ;;
        *) echo "refusing: $abs is not a .png" >&2; exit 3 ;;
    esac
    if [ ! -f "$abs" ]; then
        echo "refusing: $abs does not exist" >&2
        exit 3
    fi
    cp -- "$abs" "$REPO/figures/"
    names+=("$(basename -- "$abs")")
done

cd "$REPO"
git add -- figures
if git diff --cached --quiet; then
    echo "nothing to publish: the figures in the repo are already identical"
    exit 0
fi
if git diff --cached --name-only | grep -qv '^figures/'; then
    echo "refusing: something outside figures/ is staged" >&2
    git diff --cached --name-only >&2
    exit 4
fi
git -c user.name="Tracy Yuan" -c user.email="tracyjiayiyuan@outlook.com" commit -q -m "$MSG

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
GIT_SSH_COMMAND="ssh -i $KEY -o IdentitiesOnly=yes" git push -q origin "$BRANCH"

echo "published $(git log --oneline -1)"
for n in "${names[@]}"; do
    echo "  $RAW/$n"
done

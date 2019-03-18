#!/bin/bash

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
REPO="$(git remote get-url origin | sed -nE 's;(git@|https://)github.com[:/]([^.]+)(\.git)?$;\2;gp')"

git push --set-upstream origin "${BRANCH}" || exit 1

URL="https://github.com/${REPO}/pull/new/${BRANCH}"

if which xdg-open >/dev/null; then
  xdg-open "${URL}"
elif which gnome-open >/dev/null; then
  gnome-open "${URL}"
elif which open >/dev/null; then
  open "${URL}"
elif which python >/dev/null; then
  python -mwebbrowser "${URL}"
fi

#!/usr/bin/env bash
# Publish site/ to the web root that Caddy serves on MightyAtom.
#
# Every publish is a new release directory; the live site is a relative
# symlink swapped atomically, so a visitor never sees a half-copied site
# and the previous version is one command away.
#
#   scripts/publish.sh               check, release, switch, verify
#   scripts/publish.sh --dry-run     only run the checks
#   scripts/publish.sh --allow-dirty publish uncommitted changes too
#   scripts/publish.sh --rollback    switch back to the previous release
#   scripts/publish.sh --list        show releases, marking the live one
set -euo pipefail

WEB_ROOT="${WEB_ROOT:-/opt/docker-data/www}"
SITE_NAME="lordkada.it"
DOMAIN="lordkada.it"
KEEP=5

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO/site"
RELEASES="$WEB_ROOT/releases/$SITE_NAME"
LIVE="$WEB_ROOT/$SITE_NAME"

die() { echo "error: $*" >&2; exit 1; }
say() { echo "==> $*"; }

dry_run=0 allow_dirty=0 mode=publish
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    --allow-dirty) allow_dirty=1 ;;
    --rollback) mode=rollback ;;
    --list) mode=list ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $arg" ;;
  esac
done

live_release() { [ -L "$LIVE" ] && basename "$(readlink "$LIVE")" || true; }

# Point the live symlink at a release, atomically (rename over the old link).
switch_to() {
  ln -sfn "releases/$SITE_NAME/$1" "$LIVE.tmp"
  mv -Tf "$LIVE.tmp" "$LIVE"
}

# Every page in site/, as a path relative to site/ (index.html, en/index.html, ...).
pages() { (cd "$1" && find . -name '*.html' -printf '%P\n' | sort); }

# The URL path a page is served at: en/index.html -> /en/
url_path() { local p="/$1"; echo "${p%index.html}"; }

verify() {
  local page path expected actual ok
  while read -r page; do
    path="$(url_path "$page")"
    expected="$(sha256sum "$LIVE/$page" | cut -d' ' -f1)"
    ok=0
    for attempt in 1 2 3; do
      actual="$(curl -fsS --max-time 10 --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN$path" | sha256sum | cut -d' ' -f1)" || actual=""
      [ "$actual" = "$expected" ] && { ok=1; break; }
      sleep 1
    done
    [ "$ok" = 1 ] || die "https://$DOMAIN$path does not serve the live $page (is Caddy up and mounting $WEB_ROOT?)"
  done < <(pages "$LIVE/")
  say "verified: https://$DOMAIN/ serves release $(live_release) ($(pages "$LIVE/" | wc -l) pages)"
}

check_site() {
  [ -f "$SRC/index.html" ] || die "missing $SRC/index.html"
  # Every local href/src in every page must exist in site/: absolute refs from
  # site/, relative ones from the page's directory, a trailing / means index.html.
  local missing=0 page dir ref target
  while read -r page; do
    dir="$(dirname "$page")"
    while read -r ref; do
      case "$ref" in
        /*) target="$SRC$ref" ;;
        *) target="$SRC/$dir/$ref" ;;
      esac
      case "$target" in */) target="${target}index.html" ;; esac
      [ -e "$target" ] || { echo "  missing in $page: $ref" >&2; missing=1; }
    done < <(grep -oE '(href|src|srcset)="[^"#:]+"' "$SRC/$page" | sed -E 's/^[a-z]+="//; s/"$//' | sort -u)
  done < <(pages "$SRC")
  [ "$missing" = 0 ] || die "pages reference files that are not in site/"
  say "site/ checks passed ($(pages "$SRC" | wc -l) pages)"
}

case "$mode" in
  list)
    live="$(live_release)"
    for r in $(ls -1 "$RELEASES" 2>/dev/null | sort); do
      [ "$r" = "$live" ] && echo "* $r (live)" || echo "  $r"
    done
    exit 0 ;;
  rollback)
    live="$(live_release)"
    [ -n "$live" ] || die "nothing is published yet"
    prev="$(ls -1 "$RELEASES" | sort | grep -B1 -x "$live" | head -n1)"
    [ -n "$prev" ] && [ "$prev" != "$live" ] || die "no release older than $live"
    switch_to "$prev"
    say "rolled back: $live -> $prev"
    verify
    exit 0 ;;
esac

if [ "$allow_dirty" = 0 ] && [ -n "$(git -C "$REPO" status --porcelain -- site)" ]; then
  die "site/ has uncommitted changes (commit them, or pass --allow-dirty)"
fi

check_site
[ -d "$WEB_ROOT" ] && [ -w "$WEB_ROOT" ] || die "$WEB_ROOT must exist and be writable by $(id -un)"
[ "$dry_run" = 1 ] && { say "dry run: nothing published"; exit 0; }

release="$(date +%Y%m%d-%H%M%S)-$(git -C "$REPO" rev-parse --short HEAD)"
[ -z "$(git -C "$REPO" status --porcelain -- site)" ] || release="$release-dirty"

mkdir -p "$RELEASES"
rsync -a --delete --chmod=D755,F644 "$SRC/" "$RELEASES/$release/"
switch_to "$release"
say "published release $release"

# Prune old releases, never the live one.
ls -1 "$RELEASES" | sort | head -n "-$KEEP" | while read -r old; do
  [ "$old" = "$release" ] || rm -rf "${RELEASES:?}/$old"
done

verify

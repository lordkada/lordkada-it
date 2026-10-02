# lordkada.it

Personal single-page site for Carlo Alberto Degli Atti, served as static files by Caddy on MightyAtom.

## Layout

- `site/` — everything that gets deployed. No build step.
  - `index.html` — Italian, the default at `/`.
  - `en/index.html` — English, at `/en/`.
  - `assets/` — CSS, JS and images shared by both pages, always referenced as `/assets/…`.

The two pages are hand-maintained translations of each other: a content change goes in both.
They link each other through the `IT · EN` switch in the header and `hreflang` alternates; there
is no redirect based on the browser language.
- `scripts/publish.sh` — publishes `site/` to the web root Caddy serves.

The Caddy site block lives with the rest of the server config, in
`/opt/mightyatom-config/docker/caddy/Caddyfile` (repo `mightyatom-config`).

## Preview locally

```sh
python3 -m http.server 8080 --directory site
```

Then open <http://localhost:8080>.

## Publish

```sh
scripts/publish.sh --dry-run   # checks only
scripts/publish.sh             # publish the committed site/
scripts/publish.sh --list      # releases, live one marked
scripts/publish.sh --rollback  # back to the previous release
```

Each publish copies `site/` into a new release under `/opt/docker-data/www/releases/lordkada.it/`
and atomically repoints the `/opt/docker-data/www/lordkada.it` symlink to it; the last 5 releases
are kept. Caddy mounts `/opt/docker-data/www` read-only at `/srv/www`, so publishing needs neither
a Caddy reload nor sudo. The script refuses uncommitted changes in `site/` unless `--allow-dirty`
is given, checks that every local file each page references exists, and finally verifies that
`https://lordkada.it/` serves the new release, page by page.

One-time setup on MightyAtom (web root owned by the publishing user):

```sh
sudo install -d -o lordkada -g lordkada /opt/docker-data/www
```

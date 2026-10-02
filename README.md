# lordkada.it

Personal single-page site for Carlo Alberto Degli Atti, served as static files by Caddy.

## Layout

- `site/` — everything that gets deployed (`index.html`, `assets/`). No build step.
- `Caddyfile` — site block for the production server.

## Preview locally

```sh
python3 -m http.server 8080 --directory site
```

Then open <http://localhost:8080>.

## Deploy

Copy the contents of `site/` to the server's web root (default in the Caddyfile: `/var/www/lordkada.it`),
add the site block to the server's Caddyfile, then `sudo systemctl reload caddy`.
DNS for `lordkada.it` and `www.lordkada.it` must point to the server for Caddy to obtain certificates.

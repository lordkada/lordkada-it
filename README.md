# lordkada.it

Personal single-page site for Carlo Alberto Degli Atti, served by GitHub Pages on <https://lordkada.it>.

## Layout

- `site/` — everything that gets deployed. No build step.
  - `index.html` — Italian, the default at `/`.
  - `en/index.html` — English, at `/en/`.
  - `assets/` — CSS, JS and images shared by both pages, always referenced as `/assets/…`.
- `.github/workflows/pages.yml` — deploys `site/` to GitHub Pages.

The two pages are hand-maintained translations of each other: a content change goes in both.
They link each other through the `IT · EN` switch in the header and `hreflang` alternates; there
is no redirect based on the browser language.

## Preview locally

```sh
python3 -m http.server 8080 --directory site
```

Then open <http://localhost:8080>.

## Publish

Pushing to `main` publishes: the workflow uploads `site/` as the Pages artifact and deploys it.
Follow it with `gh run watch`; to redeploy without a new commit, `gh workflow run pages.yml`.
To roll back, revert the commit and push.

GitHub Pages cannot set response headers, so the Content-Security-Policy and the referrer policy
are `<meta>` tags in each page. Keep them in sync between the two pages.

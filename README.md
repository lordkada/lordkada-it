# lordkada.it

Personal single-page site for Carlo Alberto Degli Atti, served by GitHub Pages on <https://lordkada.it>.

## Layout

- `site/` — everything that gets deployed. No build step.
  - `index.html` — Italian, the default at `/`.
  - `en/index.html` — English, at `/en/`.
  - `assets/` — CSS, JS, images and the CV PDFs shared by both pages, always referenced as `/assets/…`.
  - `llms.txt` — a Markdown summary of the profile for LLMs and AI crawlers.
- `cv/` — the CV sources (`cv-it.html`, `cv-en.html`, `cv.css`). Not deployed.
- `scripts/build-cv.sh` — renders `cv/` to `site/assets/carlo-alberto-degli-atti-cv{,-en}.pdf`.
- `.github/workflows/pages.yml` — deploys `site/` to GitHub Pages.

The two pages are hand-maintained translations of each other: a content change goes in both.
They link each other through the `IT · EN` switch in the header and `hreflang` alternates; there
is no redirect based on the browser language.

Each page carries a schema.org JSON-LD block (`ProfilePage` + `Person`) in its `<head>`. It is a
data block, not a script, so the `script-src 'self'` policy does not block it.

## CV

The PDFs are a second copy of the page content, laid out for A4. When the experience, education or
principles change on the site, update `cv/cv-it.html` and `cv/cv-en.html` too, then rebuild and
commit the PDFs:

```sh
scripts/build-cv.sh
```

It needs [uv](https://docs.astral.sh/uv/): WeasyPrint runs through `uvx`, pinned to one version, so
nothing is installed system-wide. `llms.txt` repeats the highlights as well, so keep it in step.

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

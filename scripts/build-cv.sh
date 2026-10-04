#!/usr/bin/env bash
# Render the CV sources in cv/ to the PDFs published under site/assets/.
# Needs uv (https://docs.astral.sh/uv/): WeasyPrint runs in a throwaway environment via uvx.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
weasyprint=(uvx --from "weasyprint==70.0" weasyprint)

"${weasyprint[@]}" "$root/cv/cv-it.html" "$root/site/assets/carlo-alberto-degli-atti-cv.pdf"
"${weasyprint[@]}" "$root/cv/cv-en.html" "$root/site/assets/carlo-alberto-degli-atti-cv-en.pdf"

echo "CV rendered to site/assets/carlo-alberto-degli-atti-cv{,-en}.pdf"

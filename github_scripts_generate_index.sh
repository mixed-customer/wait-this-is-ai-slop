#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-index.html}"
DIR="stories"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

cat > "$TMP" <<'HTML_HEAD'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Stories Index</title>
  <style>
    body { font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial; padding: 2rem; max-width: 800px; margin: auto; }
    ul { list-style: none; padding-left: 0; }
    li { margin: 0.5rem 0; }
    a { color: #0366d6; text-decoration: none; }
  </style>
</head>
<body>
  <h1>Stories</h1>
  <ul>
HTML_HEAD

if [ -d "$DIR" ]; then
  # find files, sort them, and iterate (handles filenames with spaces)
  IFS=$'\n'
  files=( $(find "$DIR" -maxdepth 1 -type f -name '*.html' -print | sort) )
  unset IFS
  for f in "${files[@]:-}"; do
    name="$(basename "$f")"
    # try to extract <title>...</title>, fallback to filename
    title="$(grep -m1 -oP '(?<=<title>).*?(?=</title>)' "$f" 2>/dev/null || true)"
    if [ -z "$title" ]; then title="$name"; fi
    # Escape any HTML-sensitive chars in title (minimal)
    esc_title="$(printf '%s' "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"
    printf '    <li><a href="%s">%s</a></li>\n' "$f" "$esc_title" >> "$TMP"
  done
else
  printf '    <li><em>No stories found. Add HTML files to the "%s" directory.</em></li>\n' "$DIR" >> "$TMP"
fi

cat >> "$TMP" <<'HTML_FOOT'
  </ul>
</body>
</html>
HTML_FOOT

mv "$TMP" "$OUT"
echo "Wrote $OUT"
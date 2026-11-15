#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! -f "$1" ]]; then
    printf 'Usage: %s IMAGE\n' "$0" >&2
    exit 2
fi

wallpaper=$(realpath "$1")
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/lumen"
mkdir -p "$cache_dir"

palette_file="$cache_dir/matugen.json"
wallpaper_file="$HOME/.cache/current-wall"
mkdir -p "$(dirname "$wallpaper_file")"
palette_tmp=$(mktemp "$cache_dir/matugen.XXXXXX")
wallpaper_tmp=$(mktemp "$cache_dir/wallpaper.XXXXXX")
trap 'rm -f "$palette_tmp" "$wallpaper_tmp"' EXIT

matugen image "$wallpaper" \
    --source-color-index 0 \
    --mode dark \
    --json hex \
    --dry-run \
    --quiet > "$palette_tmp"

if [[ ! -s "$palette_tmp" ]]; then
    printf 'Matugen returned an empty palette.\n' >&2
    exit 1
fi

awww img "$wallpaper" \
    --transition-type wipe \
    --transition-duration 1 \
    --transition-fps 60

printf '%s\n' "$wallpaper" > "$wallpaper_tmp"
mv "$palette_tmp" "$palette_file"
mv "$wallpaper_tmp" "$wallpaper_file"
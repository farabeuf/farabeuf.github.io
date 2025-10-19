#!/usr/bin/env bash
set -euo pipefail

# Ejecutar desde la carpeta que contiene las imágenes o ajustar DIR
DIR="."
cd "$DIR" || { echo "No se puede entrar a $DIR"; exit 1; }

# 1) detectar el mayor número ya existente (maneja ceros a la izquierda)
max=0
shopt -s nullglob
for f in img_chidas_*.jpg img_chidas_*.JPG; do
  # extraer número
  num=$(printf '%s\n' "$f" | sed -E 's/^.*img_chidas_0*([0-9]+)\.jpg$/\1/I' || true)
  if [[ $num =~ ^[0-9]+$ ]]; then
    if (( num > max )); then max=$num; fi
  fi
done
shopt -u nullglob

echo "Último número detectado: $max"
echo

# 2) construir lista de archivos nuevos (no img_chidas_*.jpg), con timestamp (DateTimeOriginal o FileModifyDate)
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

while IFS= read -r -d '' file; do
  # quitar prefijo "./" si existe
  fname="${file#./}"
  # intentar DateTimeOriginal -> epoch
  dto=$(exiftool -s3 -d '%s' -DateTimeOriginal "$file" 2>/dev/null | head -n1 || true)
  if [ -z "$dto" ]; then
    # si no hay DateTimeOriginal, usar FileModifyDate (epoch) o stat como fallback
    dto=$(exiftool -s3 -d '%s' -FileModifyDate "$file" 2>/dev/null | head -n1 || true)
  fi
  if [ -z "$dto" ]; then
    # fallback a mtime del sistema
    dto=$(stat -c %Y "$file" 2>/dev/null || echo 0)
  fi
  # Escribimos "timestamp<TAB>filename" (sin ningún '|' ni caracteres extra)
  printf '%s\t%s\n' "$dto" "$fname" >> "$tmp"
done < <(find . -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.JPG' \) ! -iname 'img_chidas_*.jpg' -print0)

# Si no hay nuevos archivos, salir
if [ ! -s "$tmp" ]; then
  echo "No hay archivos nuevos para renombrar."
  exit 0
fi

# 3) ordenar por timestamp numérico
sort -n "$tmp" -o "$tmp"

# 4) vista previa
echo "Vista previa (qué renombrados se harán):"
n=$max
while IFS=$'\t' read -r ts name; do
  n=$((n+1))
  new=$(printf 'img_chidas_%02d.jpg' "$n")
  printf '%s -> %s\n' "$name" "$new"
done < "$tmp"

echo
read -p "¿Aplicar estos renombrados? (s/N) " resp
if [[ ! "$resp" =~ ^[sS]$ ]]; then
  echo "Cancelado por el usuario. No se hicieron cambios."
  exit 0
fi

# 5) renombrado real evitando colisiones
n=$max
while IFS=$'\t' read -r ts name; do
  n=$((n+1))
  new=$(printf 'img_chidas_%02d.jpg' "$n")
  # si ya existe el archivo new, buscar siguiente libre
  while [ -e "$new" ]; do
    n=$((n+1))
    new=$(printf 'img_chidas_%02d.jpg' "$n")
  done
  mv -- "$name" "$new"
  echo "Renombrado: $name -> $new"
done < "$tmp"

echo "✔ Renombrado completado."


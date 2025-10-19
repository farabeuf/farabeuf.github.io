#!/usr/bin/env bash
set -euo pipefail

DIR="."
cd "$DIR" || { echo "No se puede entrar a $DIR"; exit 1; }

echo "=== Renumerar img_chidas_*.jpg ==="

# buscar archivos actuales
shopt -s nullglob
files=(img_chidas_*.jpg img_chidas_*.JPG)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
  echo "No hay archivos img_chidas_*.jpg en este directorio."
  exit 0
fi

# ordenar por número extraído del nombre
sorted=($(printf '%s\n' "${files[@]}" | sort -t_ -k3,3n))

echo "Archivos encontrados: ${#sorted[@]}"
echo
echo "Vista previa del nuevo orden:"
i=0
for f in "${sorted[@]}"; do
  i=$((i+1))
  new=$(printf 'img_chidas_%02d.jpg' "$i")
  printf '%s -> %s\n' "$f" "$new"
done

echo
read -p "¿Aplicar renumeración? (s/N) " resp
if [[ ! "$resp" =~ ^[sS]$ ]]; then
  echo "Cancelado por el usuario. No se hicieron cambios."
  exit 0
fi

# renombrado seguro: temporal primero (evita colisiones)
for f in "${sorted[@]}"; do
  mv -n -- "$f" "${f}.tmp"
done

i=0
for f in "${sorted[@]}"; do
  i=$((i+1))
  new=$(printf 'img_chidas_%02d.jpg' "$i")
  mv -- "${f}.tmp" "$new"
  echo "✔ $f -> $new"
done

echo "✔ Renumeración completada correctamente."


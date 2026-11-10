#!/usr/bin/env bash
# bin/render-build.sh
# Script de build que ejecuta Render.com en cada despliegue
# Se configura como "Build Command" en el panel de Render
set -o errexit   # Salir si cualquier comando falla

echo "=== [1/4] Instalando gemas de producción ==="
bundle install

echo "=== [2/4] Precompilando assets (Tailwind + Sprockets) ==="
bundle exec rails tailwindcss:build
bundle exec rails assets:precompile
bundle exec rails assets:clean

echo "=== [3/4] Corriendo migraciones de base de datos ==="
bundle exec rails db:migrate

echo "=== [4/4] Creando datos iniciales si la BD está vacía ==="
bundle exec rails db:seed

echo "=== ✅ Build completado con éxito ==="

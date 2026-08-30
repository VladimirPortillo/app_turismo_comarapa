#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."

while true; do
  clear
  echo "============================================================"
  echo "PROYECTO FINAL 360 - SESION 2 - LINUX / MX"
  echo "============================================================"
  echo "1. Ejecutar en dispositivo"
  echo "2. Ejecutar en Chrome"
  echo "3. Ejecutar en Linux desktop"
  echo "4. Ver dispositivos"
  echo "5. Reparar Ninja"
  echo "0. Salir"
  echo "============================================================"
  read -r -p "Opcion: " option

  case "$option" in
    1) flutter run ;;
    2) flutter run -d chrome ;;
    3) flutter run -d linux ;;
    4) flutter devices ;;
    5) bash scripts/98_REPARAR_NINJA_LINUX.sh ;;
    0) exit 0 ;;
    *) echo "Opcion invalida" ;;
  esac

  echo
  read -r -p "ENTER para volver..."
done

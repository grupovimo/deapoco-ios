#!/bin/zsh
# Saca capturas de cada pantalla en el simulador ya instalado (no crea ni borra simuladores).
# Uso: ./capturar.sh [pantalla ...]   (sin argumentos, todas las de pantallas-*.txt y el onboarding)
# Cada línea de pantallas-nutri.txt y pantallas-paciente.txt: «nombre hora [oscuro]».
# Antes de usarlo, tomá el candado del simulador (ver README).
set -e
SIM=${SIM:-762618FE-D6AB-4A56-BC66-248224D158DC}
APP=${APP:-build/dd/Build/Products/Debug-iphonesimulator/DeAPoco.app}
cd "$(dirname "$0")"
mkdir -p capturas
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" -b >/dev/null
xcrun simctl install "$SIM" "$APP"
typeset -A horas oscuras
for f in pantallas-*.txt(N); do
  while read -r n h o; do
    [[ -z "$n" || "$n" == \#* ]] && continue
    horas[$n]=$h; [[ "$o" == oscuro ]] && oscuras[$n]=1
  done < $f
done
if (( $# )); then lista=($@); else lista=(${(k)horas}); fi
for p in $lista; do
  nombre=$p; osc=NO
  if [[ $p == *.oscuro ]]; then nombre=${p%.oscuro}; osc=YES; fi
  [[ -n "${oscuras[$p]}" ]] && osc=YES
  xcrun simctl status_bar "$SIM" override --time "${horas[$p]:-9:41}" --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null
  xcrun simctl terminate "$SIM" ar.com.deapoco.app 2>/dev/null || true
  xcrun simctl launch "$SIM" ar.com.deapoco.app -pantalla "$nombre" -oscuro $osc >/dev/null
  sleep ${ESPERA:-3}
  xcrun simctl io "$SIM" screenshot "capturas/$p.png" >/dev/null 2>&1
  echo "capturas/$p.png"
done
# Onboarding: cada paso de cada lado (ONB=0 para saltearlo).
if [[ "${ONB:-1}" == 1 && $# -eq 0 ]]; then
  typeset -A cant=(nutri 8 paciente 11)
  for l in nutri paciente; do
    for ((i=0; i<${cant[$l]}; i++)); do
      xcrun simctl status_bar "$SIM" override --time 10:02 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null
      xcrun simctl terminate "$SIM" ar.com.deapoco.app 2>/dev/null || true
      xcrun simctl launch "$SIM" ar.com.deapoco.app -pantalla onboarding -paso $i -ladoOnb $l -oscuro NO >/dev/null
      sleep ${ESPERA:-3}
      f=$(printf "capturas/onboarding-%s-%02d.png" $l $((i+1)))
      xcrun simctl io "$SIM" screenshot "$f" >/dev/null 2>&1
      echo "$f"
    done
  done
fi

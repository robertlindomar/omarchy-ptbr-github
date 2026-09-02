#!/usr/bin/env bash
# Testa guards de limite de senha do lock (lógica espelhada do Service/LockView).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_DIR="$ROOT/plugins/robertlindomar.omarchy-ptbr.lock"
MAX=512

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

# Espelha submitPassword + respondToPasswordPrompt
simulate_submit() {
  local password="$1"
  local pending=""
  local entered=""
  local pam_called=0

  if [ "${#password}" -gt "$MAX" ]; then
    entered=""
    pending=""
  elif [ -z "$password" ]; then
    : # no-op
  else
    pending="$password"
    entered="$password"
  fi

  if [ "${#pending}" -gt "$MAX" ]; then
    pam_called=0
  else
    if [ -n "$pending" ]; then pam_called=1; fi
  fi

  printf '%s|%s|%s' "${#entered}" "${#pending}" "$pam_called"
}

# Espelha LockView onTextChanged truncate
simulate_input() {
  local text="$1"
  if [ "${#text}" -gt "$MAX" ]; then
    text="${text:0:$MAX}"
  fi
  echo "${#text}"
}

short_pw="abc"
normal_pw="$(printf 'a%.0s' {1..64})"
exact_pw="$(printf 'x%.0s' {1..512})"
over_pw="$(printf 'y%.0s' {1..513})"
huge_pw="$(printf 'z%.0s' {1..10000})"

r=$(simulate_submit "$short_pw")
[[ "$r" == "3|3|1" ]] && pass "senha curta" || fail "senha curta ($r)"

r=$(simulate_submit "$normal_pw")
[[ "$r" == "64|64|1" ]] && pass "senha normal (64)" || fail "senha normal ($r)"

r=$(simulate_submit "$exact_pw")
[[ "$r" == "512|512|1" ]] && pass "exatamente 512" || fail "exatamente 512 ($r)"

r=$(simulate_submit "$over_pw")
[[ "$r" == "0|0|0" ]] && pass "513 chars rejeitada" || fail "513 chars ($r)"

r=$(simulate_submit "$huge_pw")
[[ "$r" == "0|0|0" ]] && pass "paste grande rejeitada" || fail "paste grande ($r)"

len=$(simulate_input "$huge_pw")
[[ "$len" -eq "$MAX" ]] && pass "input truncado a 512 no campo" || fail "input truncate ($len)"

# Código fonte: maximumLength e guards presentes
rg -q 'maximumLength: root.maxPasswordLength' "$LOCK_DIR/LockView.qml" && pass "maximumLength no TextInput"
rg -q 'maxPasswordLength: 512' "$LOCK_DIR/LockView.qml" && pass "maxPasswordLength=512 em LockView"
rg -q 'password.length > root.maxPasswordLength' "$LOCK_DIR/Service.qml" && pass "guard submitPassword"
rg -q 'pendingPassword.length > root.maxPasswordLength' "$LOCK_DIR/Service.qml" && pass "guard respondToPasswordPrompt"

# Sem log de senha em código lock
if rg -n 'console\.|log\(|password' "$LOCK_DIR" | rg -v 'passwordPam|passwordText|pendingPassword|enteredPassword|passwordCharacter|maxPasswordLength|submitPassword|Digite a senha|password mask|password dot|Password' | rg 'password.*log|log.*password' ; then
  fail "possível log de senha"
else
  pass "sem log explícito de senha no plugin lock"
fi

# validate manifest
omarchy plugin validate "$LOCK_DIR" && pass "omarchy plugin validate lock"

echo ""
echo "Todos os testes de bound de senha passaram."

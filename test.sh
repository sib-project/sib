#!/usr/bin/env bash

set -u

SIB_DIR=$(mktemp -d)/sib
export SIB_DIR
trap 'rm -rf "$(dirname "$SIB_DIR")"' EXIT

SIB=./sib

run() {
    echo
    echo "$ $*"
    eval "$@"
    echo "[exit: $?]"
}

run_stdin() {
    local input=$1; shift
    echo
    echo "\$ echo '$input' | $*"
    echo "$input" | eval "$@"
    echo "[exit: $?]"
}

echo "===== init ====="
run "$SIB init"

echo
echo "===== mktrace (empty) ====="
T0=$(echo -n | $SIB mktrace)
echo "empty trace: $T0"
run "$SIB ls-trace $T0"

echo
echo "===== mktrace (manual key-hash lines) ====="
H1=$(echo -n 'hello' | $SIB git hash-object -w --stdin)
H2=$(echo -n 'world' | $SIB git hash-object -w --stdin)
echo "blob hello: $H1"
echo "blob world: $H2"
T1=$(printf 'a %s\nb %s\n' "$H1" "$H2" | $SIB mktrace)
echo "trace: $T1"
run "$SIB ls-trace $T1"

echo
echo "===== mktrace duplicate key (should fail) ====="
echo "\$ printf 'a %s\\na %s\\n' \"\$H1\" \"\$H2\" | \$SIB mktrace"
printf 'a %s\na %s\n' "$H1" "$H2" | $SIB mktrace
echo "[exit: $?]"

echo
echo "===== mktrace-json ====="
JSON='{"role":"user","content":"hello world","raw":"{\"id\":1}"}'
T2=$(echo "$JSON" | $SIB mktrace-json)
echo "input: $JSON"
echo "trace: $T2"
run "$SIB ls-trace $T2"
run "$SIB ls-trace-json $T2"

echo
echo "===== mktrace-json non-object (should fail) ====="
echo '$ echo "[1,2,3]" | $SIB mktrace-json'
echo '[1,2,3]' | $SIB mktrace-json
echo "[exit: $?]"

echo
echo "===== mktrace-json reserved prefix (should fail) ====="
echo "\$ echo '{\"${TRACE_MAGIC:-_SIBTRACE}foo\":\"x\"}' | \$SIB mktrace-json"
echo '{"_SIBTRACEfoo":"x"}' | $SIB mktrace-json
echo "[exit: $?]"

echo
echo "===== mktrace-json with special chars ====="
JSON='{"k":"line1\nline2\t\"quoted\"\\backslash"}'
T3=$(echo "$JSON" | $SIB mktrace-json)
echo "input: $JSON"
echo "trace: $T3"
run "$SIB ls-trace-json $T3"

echo
echo "===== ls-trace on non-trace tree (should fail) ====="
EMPTY_TREE=$($SIB git mktree </dev/null)
echo "empty git tree: $EMPTY_TREE"
echo "\$ \$SIB ls-trace $EMPTY_TREE"
$SIB ls-trace "$EMPTY_TREE"
echo "[exit: $?]"

echo
echo "===== chain-trace (root) ====="
C1=$(echo '{"role":"user","content":"hi"}' | $SIB mktrace-json | xargs -I{} $SIB chain-trace {})
echo "chain (root): $C1"
run "$SIB ls-chain $C1"

echo
echo "===== chain-trace (with parent) ====="
T_A=$(echo '{"role":"user","content":"first"}' | $SIB mktrace-json)
T_B=$(echo '{"role":"assistant","content":"reply"}' | $SIB mktrace-json)
T_C=$(echo '{"role":"user","content":"second"}' | $SIB mktrace-json)
CA=$($SIB chain-trace $T_A)
CB=$($SIB chain-trace -p $CA $T_B)
CC=$($SIB chain-trace -p $CB $T_C)
echo "C_A (root):   $CA  (trace $T_A)"
echo "C_B (parent): $CB  (trace $T_B)"
echo "C_C (head):   $CC  (trace $T_C)"
run "$SIB ls-chain $CC"

echo
echo "===== chain-trace-json (mktrace-json + chain-trace) ====="
echo '$ echo "{...}" | $SIB chain-trace-json -p $CC'
CD=$(echo '{"role":"assistant","content":"second reply"}' | $SIB chain-trace-json -p $CC)
echo "C_D: $CD"
run "$SIB ls-chain $CD"

echo
echo "===== rev-jsonl (full chain, oldest first) ====="
run "$SIB rev-jsonl $CD"

echo
echo "===== rev-jsonl on root (single trace) ====="
run "$SIB rev-jsonl $CA"

echo
echo "===== done ====="

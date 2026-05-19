SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export PATH="$SCRIPT_DIR:$SCRIPT_DIR/plm:$PATH"
NAME=$(basename -- "$0")

die() {
    [ $# -eq 0 ] || echo fatal: "$@" >&2
    exit 1
}

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export PATH="$SCRIPT_DIR:$SCRIPT_DIR/plm:$PATH"
NAME=$(basename -- "$0")

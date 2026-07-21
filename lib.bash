set -euo pipefail

NAME="$(basename -- $0)"

die() {
    [ $# -eq 0 ] || echo fatal: "$@" >&2
    exit 1
}

key_is_valid() {
    [[ $1 =~ ^[A-Za-z_][A-Za-z0-9._-]*$ ]]
}

tf_key() {
    local line key hash extra n=0

    while IFS= read -r line || [[ -n $line ]]; do
        n=$((n + 1))

        read -r key hash extra <<<"$line"

        [[ -n $key && -n $hash && -z $extra ]] || {
            echo "invalid trace entry at line $n" >&2
            return 1
        }

        key_is_valid "$key" || {
            echo "invalid trace key at line $n: $key" >&2
            return 1
        }

        printf '%s\n' "$key"
    done
}

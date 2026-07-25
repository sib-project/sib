NAME="$(basename -- $0)"

die() {
    [ $# -eq 0 ] || echo fatal: "$@" >&2
    exit 1
}

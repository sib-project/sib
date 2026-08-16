# Copyright 2026 Hee-Suk Kim <hskim@dilluti0n.com>
# SPDX-License-Identifier: GPL-3.0-only

NAME="$(basename -- $0)"

die() {
    [ $# -eq 0 ] || echo fatal: "$@" >&2
    exit 1
}

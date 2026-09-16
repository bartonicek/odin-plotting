#!/bin/bash -eu

# Paths below are relative to the repo root, so go there first -- that way the
# script works no matter where it is invoked from.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

OUT_DIR="build/tests"

mkdir -p $OUT_DIR

status=0

for dir in $(find . -path ./build -prune -o -name 'test_*.odin' -print | xargs -r -n1 dirname | sort -u); do
	echo "==> $dir"
	name=$(echo "$dir" | sed 's|^\./||; s|/|_|g')
	odin test "$dir" -out:$OUT_DIR/$name || status=1
done

exit $status

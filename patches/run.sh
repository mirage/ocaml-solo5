#!/bin/sh

#to be executed from <TOP>/ocaml

patch_dir="../patches/"$(ocaml -vnum)

if [ -d $patch_dir ]; then
    for x in $(ls $patch_dir); do
        echo "applying patch $x";
        patch -p1 < $patch_dir/$x
    done
else
    echo "no patch directory found at $patch_dir (unsupported OCaml version?)";
    exit 1
fi

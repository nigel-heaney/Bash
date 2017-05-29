#!/bin/bash
# usage: rollserial <new Serial to amend>

newserial=$1
for i in `ls -1 *.dns | grep -v arpa`; do
        echo -en "Working on $i: "
        cp -f $i $i.bak
        awk -v serial=$newserial '/hostmaster.domain.local/ { print >"roll.tmp"; getline; sub($1,serial); } { print >"roll.tmp" }' $i
        mv -f roll.tmp $i
        echo "Done!"
done

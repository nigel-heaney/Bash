#!/bin/bash
#  fsync: script to rsync files  but recover from failures like mac corruption.

status=-1

trap escape INT

function escape() {
        #exit quietly.
        exit 0
}

until [ $status -eq 0 ]; do
    /usr/bin/rsync -Pz $* 
    status=$?
done


#!/bin/bash
#
# usage : 
#
#
#
#

function interval ()
{
	echo $(date '+%y%m%d %H%M%S') $cnt
	cnt=0
}
declare -i cnt=0
trap interval SIGUSR1
shopt -s lastpipe

tail -f --pid=$$ ${1:-log.file} | while read aline
do
	let cnt++
done





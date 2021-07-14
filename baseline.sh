function usageErr ()
{
	echo 'usage: baseline.sh [-dpath] file1 [file2]
	echo 'creates or compares a baseline from path'
	echo 'default path is /'
	exit 2
}

function dosumming ()
{
	find "${DIR[@]}" -type f | xargs -d '\n' sha1sum
}

function parseArgs ()
{
	while getopts "d:"MYOPT
	do
		DIR+=( "$OPTARG" )
	done
	shift $((OPTIND-1))
	(( $# == 0 || $# > 2 )) &&  usageErr
	(( ${#DIR[*]} == 0 )) && DIR=( "/" )
}
declare -a DIR
parseArgs
BASE="$1"
B2ND="$2"

if (($# == 1))
then
	# $BASE is the file content
	dosumming>  "$BASE"
	exit
fi

if [[ ! -e "$BASE" ]]
then
	usageErr
fi

#如果兩個檔案揭存在就比較兩者
#不然就建立一個且填滿
if [[ ! -e "$B2ND" ]]
then
	echo creating "$B2ND"
	dosumming > "$B2ND"
fi

#現在我們有兩個用sha1sum建立的檔案
declare -A BYPATH BYHASH INUSE

while read HNUM FN
do
	BYPATH["$FN"]=$HNUM
	BYHASH["$HNUM"]="$FN"
	INUSE["$FN"]="X"
done < "$BASE"


#---- 開始輸出
printf '<<filesystem host="%s" dir="%s">\n' "$HOSTNAME" "${DIR[*]}"


while read HNUM FN
do
	WASHASH="${BYPATH[${FN}]}"
	#找不對就會是NULL	
	if [[ -z $WASHASH ]]
	then
		ALTFN="${BYHASH[$HNUM]}"
		if [[ -z ALTFN ]]
		then
			printf '  <new> %s</new>\n' "$FN"
		else
			printf ' <relocated orig="%s">%s</relocated>\n' "$ALTFN" "$FN"
			INUSE["$ALTFN"]='_'
		fi
	else
		INUSE["$FN"]='_'
		if [[ $HNUM == $WASHASH ]]
		then
			continue;
		else
			printf ' <changed>z5s</changed>\n' "$FN"
		fi
	fi
done < "$B2ND"

for FN in "${!INUSE[@]}"
do
	if [[ "${INUSE[$FN]}" == 'X']]
	then
		printf ' <removed>\n' "$FN"
	fi
done
printf '<filesystem>\n'


#!/bin/bash

_help () {
        echo "Usage:"
        echo -e "\t -f dump_file"
        echo -e "\t"
        echo -e "\t -x temp_file_db // optional"
        echo -e "\t"
        echo -e "\t -z temp_file_table // optional"
        echo -e "\t"
        echo -e "\t -i // interactive mode"
        echo -e "\t"
        echo -e "\t -a // print all databases and tables"
        echo -e "\t"
        echo -e "\t -d // print array values for debug resons or so"
        echo -e "\t"
        echo -e "\t -k // keep temp files"
        echo -e "\t"
        echo -e "\t -h // well..."
        echo -e "\t"
        echo -e "\t $0 -f /root/dump.sql -a -k"
        echo -e "\t $0 -x /tmp/... -z /tmp/... -a" 
}

while getopts f:iadhkt:x:z: aaa 
do
case $aaa in
f)	DUMP=$OPTARG;;
i)	INT=1;;
a)	ALL=1;;
d)	DEBUG=1;;
h)	HELP=1;;
k)	KEEP=1;;
x)	tempfile_db=$OPTARG && DBT=1;;
z)	tempfile_tab=$OPTARG && TBT=1;;
?)	_help && echo "chill"
	exit 2
	;;
esac
done

[[ $HELP -eq 1 ]] && _help && exit 0

#### functions and variables

IFS=$'\n'
A='`'
I=0
make_tmp () {
[[ $DBT -eq 1 ]] || tempfile_db=`mktemp`
[[ $TBT -eq 1 ]] || tempfile_tab=`mktemp`
}
echo_tmp () {
	echo $tempfile_db dbs
	echo $tempfile_tab tables
}
rm_tmp () {
	rm -f $tempfile_db
	rm -f $tempfile_tab
}

feed () {
for line in `egrep -n "^-- Current Database|^-- Table structure|^-- Dump completed" $DUMP`
do
	case $line in
		*Current\ Database*)	
			echo $line >> "$tempfile_db" 
			;;
		*Table\ structure*)	
			echo $line >> "$tempfile_tab" 
			;;
		*Dump\ completed*)	
			echo $line >> "$tempfile_tab"
			echo $line >> "$tempfile_db"
	esac
done
}

sort_ () {
for line in `awk -F ":" '{print $1}' $tempfile_db`
do
	dbs+=($line)
done
for line in `awk -F "$A" '{print $2}' $tempfile_db | sed "\$d" | sed "s#$A##g"`
do
	db_names+=($line)
done
for line in `awk -F ":" '{print $1}' $tempfile_tab`
do
	tables+=($line)
done
for line in `awk -F "$A" '{print $2}' $tempfile_tab | sed "\$d" | sed "s#$A##g"`
do
	table_names+=($line)
done
}

split_dump () {
for ((j=0;j<$((${#dbs[@]}-1));j++))
do
	[[ $INT -eq 1 ]] && echo $j')' splitting ${db_names[j]}...
 	dabs+=("$(echo "sed -n ${dbs[j]},$((${dbs[j+1]}-1))p $DUMP : ${db_names[j]}")")
	for ((i=$I;i<$((${#tables[@]}-1));i++))
	do
		if [[ ${dbs[j+1]} -ge ${tables[i+1]} ]]
		then
			tabs+=("$(echo "sed -n ${tables[i]},$((${tables[i+1]}-1))p $DUMP : ${db_names[j]}.${table_names[i]}")")
		fi
		[[ ${dbs[j+1]} -lt ${tables[i+1]} ]] && I=i && break
	done
done
}

dabs () {
for i in ${dabs[@]}
do 
	echo $i
done
}
tabs () {
for i in ${tabs[@]}
do
	echo $i
done
}

tabs_in_dabs () {
	echo "enter db index number"
	read DAB
for i in ${tabs[@]}
do
	[[ ! -z $(echo `echo $i | awk '{print $NF}' | awk -F "." '{print $1}'` | grep `echo ${dabs[$DAB]} | awk '{print $NF}'`) ]] && echo $i
done
}

#### stuff happening

make_tmp
feed
sort_
split_dump
[[ $KEEP -eq 1 ]] || rm_tmp && echo_tmp

[[ $INT -eq 1 ]] && tabs_in_dabs
[[ $ALL -eq 1 ]] && dabs && tabs 

#### debug prints

debug () {
	echo ${dbs[@]} 		dbs
	echo ${db_names[@]} 	db_names
	echo ${tables[@]}	tables
	echo ${table_names[@]}	table_names
	echo ${dabs[@]}		dabs
	echo ${tabs[@]}		tabs
}
debug_val () {
	echo ${#dbs[@]} 	dbs_val
	echo ${#db_names[@]} 	db_names_val
	echo ${#tables[@]} 	tables_val
	echo ${#table_names[@]} table_name_val
	echo ${#dabs[@]}	dabs_val
	echo ${#tabs[@]}	tabs_val
}

[[ $DEBUG -eq 1 ]] && debug && debug_val

unset IFS

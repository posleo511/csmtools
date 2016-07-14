#!/bin/sh

function contains_element () {
  local e
  for e in "${@:2}"; do 
    [[ "$e" == "$1" ]] && return 0; 
  done
  return 1
}

function convertsecs () {
  ((h=${1}/3600))
  ((m=(${1}%3600)/60))
  ((s=${1}%60))
  printf "%02d:%02d:%02d\n" $h $m $s
}

function log_resolution () {
  exec > /dev/null
  tmp=$( mktemp )
  prelog=$1
  log=$2
  if [[ -f $log ]]; then
    cat $prelog $log > $tmp
  else
    cat $prelog > $tmp
  fi
  mv $tmp $log
  # rm $prelog
}

function switch_logs () {
  exec > /dev/null 2>&1
  mv $1 $2
  exec >> $2 2>&1
}

function loud_exit_code () {
  if [[ "$?" == "0" ]]; then
    echo "Success!"
    for msg in "$@"; do
      echo "${msg}"
    done
  else
    echo "Failed!"
    exit 1
  fi
}

function read_xml () {
  grep -oP "(?<=$1>)[^<]+" $2
}


function usage () {
  echo "Incorrect command line parameter usage! Consult the help file."
  exit 1
}

function submit_and_wait () {
  script=$1
  wait_time=$2
  shift 2
  names=( $@ )
  echo -e "\n== Submissions ============================ $( date +%H:%M:%S ) ==\n"
  
  for el in "${names[@]}"; do
    echo -ne "Submitting ${el}... "
    . ${script} ${el} > /dev/null 2>&1 &
    lr=$! # record the process ID
    disown -h $lr # nohup the process
    pids+=( ${lr} ) # add to list of process ids
    echo "Done."
    sleep ${wait_time}
  done

  echo -e "\n== Output ================================= $( date +%H:%M:%S ) ==\n"
  fails=0
  for k in $(seq 0 $(( ${#pids[@]} - 1)) ); do
    echo -n "Waiting for ${names[$k]}... "
    wait ${pids[$k]}
    if [[ "$?" != "0" ]]; then
      fails=$(( ${fails} + 1 ))
      echo "Failed!"
    else
      echo "Success!"
    fi
  done
  
  if [[ ${fails} != 0 ]]; then
    return 1
  else
    return 0
  fi
}


function usage () {
  echo $@ 1>&2
  exit 1
}

function create_hive_table () {
  local msg="Usage [ -o) <true|false> ] [ -d) <delimiter> ] [ -n) <nullstr> ]
  [ -f) <storage-format> ] [ -h) <num-header-rows>] <schema> <tablename> <structure>"
  local OPTIND
  local delim=\|
  local nullstr=
  local mod=
  local header=0
  local headmod=""
  local external=
  local overwrite=
  local filefmt=TEXTFILE
  local choices=( true false )
  while getopts ":o:e:d:f:n:h:" o; do
    case "${o}" in
        d) delim=${OPTARG};;
        f) filefmt=${OPTARG};;
        n) nullstr=${OPTARG};;
        h) header=${OPTARG};;
        e) external=${OPTARG};;
        o)
            overwrite=${OPTARG}
            contains_element "${overwrite}" "${choices[@]}"
            [[ "$?" != "0" ]] \
              && usage ${msg}
            ;;
        *) 
            usage ${msg}
            ;;
    esac
  done
  shift $((OPTIND-1))
  local schema=$1
  local tablename=$2
  shift 2
  local format="$@"
  
  [[ "${external}" == "true" ]] && mod=EXTERNAL
  [[ ${header} > 0 ]] && headmod="tblproperties ('skip.header.line.count'='${header}')" 
  
  local cmd="CREATE ${mod} TABLE IF NOT EXISTS ${schema}.${tablename} (
      ${format}
    )
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '${delim}'
    NULL DEFINED AS '${nullstr}'
    STORED AS ${filefmt}
    ${headmod}"
  
  if [[ "${overwrite}" == "true" ]]; then
    hive -S -e "DROP TABLE IF EXISTS ${schema}.${tablename}"
  fi 
  
  hive -S -e "${cmd}"
}

function load_hive_table () {
  local OPTIND
  local mod=
  local msg="Usage [ -o) <true|false> ] <schema> <tablename> <inpath>"
  while getopts ":o:" o; do
    case "${o}" in
        o)
            local overwrite=${OPTARG}
            choices=( true false )
            contains_element "${overwrite}" "${choices[@]}"
            [[ "$?" != "0" ]] \
              && usage ${msg}
            ;;
        *) 
            usage ${msg}
            ;;
    esac
  done
  shift $((OPTIND-1))
  
  if [[ "${overwrite}]" == "true" ]]; then
    mod=OVERWRITE
  fi
  
  hive -S -e "
    LOAD DATA INPATH '$3' 
    ${mod} INTO TABLE $1.$2"
}

function create_hive_schema () {
  local OPTIND
  local msg="Usage [ -o) <true|false> ] <schema> <location>"
  while getopts ":o:" o; do
    case "${o}" in
        o)
            local overwrite=${OPTARG}
            choices=( true false )
            contains_element "${overwrite}" "${choices[@]}"
            [[ "$?" != "0" ]] \
              && usage ${msg}
            ;;
        *) 
            usage ${msg}
            ;;
    esac
  done
  
  shift $((OPTIND-1))
  local schema=$1
  local location=$2
  
  if [[ "${overwrite}" == "true" ]]; then
    local cmd="
      DROP SCHEMA IF EXISTS ${schema} CASCADE;
      
      CREATE SCHEMA ${schema}
      LOCATION '${location}'"
  else
    local cmd="CREATE SCHEMA IF NOT EXISTS ${schema} LOCATION '${location}'"
  fi
    
  hive -S -e "${cmd}"
  
}

function notify () {
  mailx -a $3 -s "$2" $1
}

function name_map () {
  awk -F"|" '$2 != "" { print "s/"$2"/"$1"/Ig" }' $1 | sed -i -f - $2
}

function header_map () {
  awk -F"|" '$2 != "" { print "1 s/"$2"/"$1"/Ig" }' $1 | sed -i -f - $2
}
  
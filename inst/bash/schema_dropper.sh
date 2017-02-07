#!/bin/bash

tmpfile=$( mktemp /tmp/${USER}_hive_street_sweeper.XXXXXXXX )
cmdfile=$( mktemp /tmp/${USER}_hive_street_sweeper_cmd.XXXXXXXX )
touch $tmpfile $cmdfile

# trap any cancel-y signals to immediately exit
trap "exit" 1 2 3 4 6 8 9 15

# follow up by removing the temporary files
trap "rm $tmpfile $cmdfile" EXIT

# create the command file by parsing each line in the incoming file to two
# separate lines; one echoing the table/schema name and one executing the drop
command_file() {
  if [[ -f $1 ]]; then
    rm $1
  fi

  if [[ "${drop_type}" == "table" ]]; then
    echo "USE ${schema_name};" > $1
    casc=""
  else
    casc="CASCADE"
  fi

  awk -v dtype="${drop_type^^}" -v co="${casc}" '{

    for(i = 0; i < 2; i++) {
      if (i < 1) {
        print "!echo Dropping "$0"...;"
      } else {
        print "DROP "dtype" "$0" "co";"
      }
    }
  }' $tmpfile >> $1
}

# create the script and names list
creator() {
  echo -e "\nCreating ./hive_drop.hql"
  command_file ./hive_drop.hql
  echo "Creating ./hive_drop.dat"
  cp $tmpfile ./hive_drop.dat
  echo -e "\n-- DONE ----------\n"
}

# create and execute the command file
dropper() {
  echo -e "\nExecuting Hive Script...\n"
  command_file $cmdfile
  hive -S -f $cmdfile
  echo -e "\n-- DONE ----------\n"
}

# begin interactivity
while true; do
  while read -p "Search for (t)ables or (s)chemas? "
  do
    case $REPLY in
      s ) drop_type=schema; break;;
      t ) drop_type=table;
          while read -p "What schema? "
          do
            echo -n "Checking schema exists... "
            hive -S -e "USE $REPLY" 2> /dev/null
            if [[ "$?" == "88" ]]; then
              echo "Failed!"
              continue
            else
              echo "Success!"
              schema_name=$REPLY
              break
            fi
          done; #/ schema name while
          break;;
      *) echo "Please choose one of: (t)able or (s)chema";;
     esac
  done #/ tables or schemas while

  read -p "What pattern to look for? " pattern
  echo -n "Searching... "

  if [[ "${drop_type}" == "table" ]]; then
    hive -S -e "use $schema_name; show tables like \"${pattern}\";" > $tmpfile
  else
    hive -S -e "show schemas like \"${pattern}\";" > $tmpfile
  fi

  sc=$( grep -c ^ $tmpfile )
  if [[ $sc == 0 ]]; then
    echo -e "No ${drop_type}s found.\n"
    continue
  else
    echo -e "found $sc ${drop_type}s:\n"
    if [[ $sc -gt 10 ]]; then
      head -5 $tmpfile
      echo "  ...   "
      tail -5 $tmpfile
    else
      cat $tmpfile
    fi
  fi

  echo ""

  while read -p "Do you want to just create the hive drop script (create), create and run the hive drop script (run) or exit (exit) ? "
  do
    case "$REPLY" in
      "create" ) creator; break;;
      "run" ) dropper; break;;
      "exit" ) exit;;
      *) echo "Please answer 'create', 'run', 'exit'";;
    esac
  done
done

exit 0

#!/bin/bash

file=""
filter=""
comm=""

help() {
        echo ""
        echo "          $0 - web log analyzer"
        echo "Usage:"
        echo "          $0 [FILTER] [COMMAND] [LOG1 [LOG2 [...]]"
        echo ""
        echo "Options:"
        echo "Commands: Maximum of one per run."
        echo "                  'list-ip' - lists all source IP addresses"
        echo "                  'list-hosts' - lists all source domains"
        echo "                  'list-uri' - lists all URIs"
        echo "                  'hist-ip' - draws a histogram of IP addr. visits"
        echo "                  'hist-load' - draws a histogram of visits related to time"
        echo "Filters: Any combination of the following."
        echo "                  '-a DATETIME' - all logs after DATETIME (excluding)"
        echo "                  '-b DATETIME' - all logs before DATETIME (excluding)"
        echo "                          DATETIME is YYYY-MM-DD HH:MM:SS"
        echo "                  '-ip IPADDR' - all logs with corresponding IP addr."
        echo "                          IPADDR is IPv4 or IPv6"
        echo "                  '-uri URI' - all logs with corresponding URI"
        echo "                          URI is a non-extended REGEXP"
        echo ""
        exit 1
}

dateParse(){
         what=$(echo "$filter" | awk 'NR==1{print $2" "$3}')
         year=$(echo "$what" | cut -c 1-4)
         month=$(echo "$what" | cut -c 6-7)
         day=$(echo "$what" | cut -c 9-10)
         hour=$(echo "$what" | cut -c 12-13)
         min=$(echo "$what" | cut -c 15-16)
         sec=$(echo "$what" | cut -c 18-19)
         cmp=$(echo -n "$year$month$day$hour$min$sec")
}

dateBefore(){
        while true; do
                if [ -z "$fileNew" ]; then
                        break;
                else
                        line=$(echo "$fileNew" | sed '1q')
                        line_good="$line"
                        fileNew=$(echo "$fileNew" | sed '1d')
                        line=$(echo "$line" | awk '{print $4}' | tr -d ':'| tr -d '-'|
                        tr -d '[' | tr -d '\" \""'| cut -c 1-20 |
                        sed -e 's/Jan/01/g' -e 's/Feb/02/g' -e 's/Mar/03/g' |
                        sed -e 's/Apr/04/g' -e 's/May/05/g' -e 's/Jun/06/g' |
                        sed -e 's/Jul/07/g' -e 's/Aug/08/g' -e 's/Sep/09/g' |
                        sed -e 's/Oct/10/g' -e 's/Nov/11/g' -e 's/Dec/12/g')
                        year=$(echo "$line" | cut -c 7-10)
                        month=$(echo "$line" | cut -c 4-5)
                        day=$(echo "$line" | cut -c 1-2)
                        rest=$(echo "$line" | cut -c 11-16)
                        line="$year$month$day$rest"

                        if [ -z "$line" ]; then
                                line=0
                        fi
                        if [ $line -lt $cmp ]; then
                                file=$(printf "%s\n%s" "$file" "$line_good")
                        fi
                fi
        done
        file=$(echo "$file" | sed -e '/^ *$/d' )
}

dateAfter(){
        while true; do
                if [ -z "$fileNew" ]; then
                        break;
                else
                        line=$(echo "$fileNew" | sed '1q')
                        line_good="$line"
                        fileNew=$(echo "$fileNew" | sed '1d')
                        line=$(echo "$line" | awk '{print $4}' | tr -d ':'|
                        tr -d '-'| tr -d '[' | tr -d '\" \"'| cut -c 1-20 |
                        sed -e 's/Jan/01/g' -e 's/Feb/02/g' -e 's/Mar/03/g' |
                        sed -e 's/Apr/04/g' -e 's/May/05/g' -e 's/Jun/06/g' |
                        sed -e 's/Jul/07/g' -e 's/Aug/08/g' -e 's/Sep/09/g' |
                        sed -e 's/Oct/10/g' -e 's/Nov/11/g' -e 's/Dec/12/g')
                        year=$(echo "$line" | cut -c 7-10)
                        month=$(echo "$line" | cut -c 4-5)
                        day=$(echo "$line" | cut -c 1-2)
                        rest=$(echo "$line" | cut -c 11-16)
                        line="$year$month$day$rest"

                        if [ -z "$line" ]; then
                                line=0
                        fi
                        if [ $line -gt $cmp ]; then
                                file=$(printf "%s\n%s" "$file" "$line_good")
                        fi
                fi
         done
         file=$(echo "$file" | sed -e '/^ *$/d' )
}

if [ -z "$1" ]; then
        help
fi

while true; do
        if [ -z "$1" ]; then
                break
        fi

        case "$1" in
        list-ip | list-hosts | list-uri | hist-ip | hist-load)
                if [ "$file_count" == "1" ]; then
                        echo "Wrong order"
                        help
                fi
                if [ "$command_count" == "1" ]; then
                        echo "Too many commands"
                        help
                fi
                command_count=1
                comm=$1;;
        *".gz"*)
                file_count=1
                file="$file$(gunzip -c "$1")";;
        *".log"*)
                file_count=1
                file="$file$(cat "$1")";;
        -a)
                if [ "$a_count" == "1" ]; then
                        echo "Second use of -a"
                        help
                fi
                if [ "$file_count" == "1" ]; then
                        echo "Wrong order"
                        help
                fi
                if [ "$command_count" == "1" ]; then
                        echo "Wrong order"
                        help
                fi
                prom=$(echo "$2" |
                grep "^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9] [0-9][0-9]\:[0-9][0-9]:[0-9][0-9]$")
                if [ -z "$prom" ]; then
                        echo "Wrong -a format"
                        help
                fi
                filter=$(printf "%s%s %s\n " "$filter" "$1" "$2")
                shift 1
                a_count=1;;
        -b)
                if [ "$b_count" == "1" ]; then
                        echo "Second use of -b"
                        help
                fi
                if [ "$file_count" == "1" ]; then
                        echo "Wrong order"
                        help
                fi
                if [ "$command_count" == "1" ]; then
                        echo "Wrong order"
                        help
                fi
                prom=$(echo "$2" |
                grep "^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9] [0-9][0-9]\:[0-9][0-9]:[0-9][0-9]$")
                if [ -z "$prom" ]; then
                        echo "Wrong -b format"
                        help
                fi
                filter=$(printf "%s%s %s\n " "$filter" "$1" "$2")
                shift 1
                b_count=1;;
        -uri)
                if [ "$uri_count" == "1" ]; then
                        echo "Second use of IP"
                        help
                fi
                if [ "$file_count" == "1" ]; then
                        echo "Wrong order"
                        help
                fi
                if [ "$command_count" == "1" ]; then
                        echo "Wrong order"
                        help
                fi
                prom=$(echo "$2" | grep "^\/.*$")
                if [ -z "$prom" ]; then
                        echo "Wrong URI format"
                        help
                fi
                filter=$(printf "%s%s %s\n " "$filter" "$1" "$2")
                shift 1
                uri_count=1;;
        -ip)
                if [ "$ip_count" == "1" ]; then
                        echo "Second use of IP"
                        help
                fi
                if [ "$file_count" == "1" ]; then
                        echo "Wrong order"
                        help
                fi
                if [ "$command_count" == "1" ]; then
                        echo "Wrong order"
                        help
                fi
                prom=$(echo "$2" | grep "^[0-9].*$")
                if [ -z "$prom" ]; then
                        echo "Wrong IP format"
                        help
                fi
                filter=$(printf "%s%s %s\n " "$filter" "$1" "$2")
                shift 1
                ip_count=1;;
        *)
                echo "Wrong command"
                help;;
        esac
        shift 1
done

case $comm in
        list-ip)
                while true; do
                  type=$(echo "$filter" | awk 'NR==1{print $1}')
                  what=$(echo "$filter" | awk 'NR==1{print $2}')
                  case $type in
                        -uri | -ip)
                                 file=$(echo "$file" | grep "$what ");;
                        -a)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateAfter;;
                        -b)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateBefore;;
                  esac
                  filter=$(echo "$filter" | sed '1d')
                  if [ -z "$filter" ]; then
                        break
                  fi
                done
                echo "$file" | awk '{print $1}' | sort -u | sed -e '/^ *$/d' |
                sed -e '/^"*$/d';;
        list-hosts)
                while true; do
                  type=$(echo "$filter" | awk 'NR==1{print $1}')
                  what=$(echo "$filter" | awk 'NR==1{print $2}')
                  case $type in
                        -uri | -ip)
                                file=$(echo "$file" | grep "$what ");;
                        -a)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateAfter;;
                        -b)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateBefore;;
                  esac
                  filter=$(echo "$filter" | sed '1d')
                  if [ -z "$filter" ]; then
                        break
                  fi
                done
                hosts=$(echo "$file" | awk '{print $1}' | sort -u | sed -e '/^ *$/d')
                hist_ip=$(echo "$hosts" | tr -s ' ' '\n')

                while true; do
                  line=$(echo "$hosts" | sed '1q')
                  hosts=$(echo "$hosts" | sed '1d')
                  if [ -z "$line" ]; then
                        break
                  fi
                  notF=$(host -W 1 "$line" | cut -d " " -f 5)
                  case $notF in
                        *\(*\) | no)
                                echo "$line";;
                        *)
                                host "$line" | cut -d " " -f 5;;
                  esac
                done;;
        list-uri)
                while true; do
                  type=$(echo "$filter" | awk 'NR==1{print $1}')
                  what=$(echo "$filter" | awk 'NR==1{print $2}')
                  case $type in
                        -uri | -ip)
                                file=$(echo "$file" | grep "$what ");;
                        -a)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateAfter;;
                        -b)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateBefore;;
                  esac
                  filter=$(echo "$filter" | sed '1d')
                  if [ -z "$filter" ]; then
                        break
                  fi
                done
                echo "$file" | cut -d "\"" -f 2 | sort -u | sed -e '/^ *$/d' |
                sed -e '/^-$/d' |  cut -d " " -f 2 | cut -d " " -f 1 | sort -u;;
        hist-ip)
                while true; do
                  type=$(echo "$filter" | awk 'NR==1{print $1}')
                  what=$(echo "$filter" | awk 'NR==1{print $2}')
                  case $type in
                        -ip | -uri)
                                file=$(echo "$file" | grep "$what ");;
                        -a)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateAfter;;
                        -b)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateBefore;;
                  esac
                  filter=$(echo "$filter" | sed '1d')
                  if [ -z "$filter" ]; then
                        break
                  fi
                done
                hist_ip=$(echo "$file" | awk '{print $1}' | sort | sed -e '/^ *$/d' |
                uniq -c | sort -n -r)
                hist_ip=$(echo $hist_ip | tr -s ' ' '\n')
                count_ip=$(echo "$hist_ip" | awk 'NR % 2 == 1')
                hist_ip=$(echo "$hist_ip" | awk 'NR % 2 == 0')

                while true; do
                  if [ -z "$count_ip" ]; then
                        break
                  fi
                  hash=""
                  line=$(echo "$hist_ip" | sed '1q')
                  hist_ip=$(echo "$hist_ip" | sed '1d')
                  num=$(echo "$count_ip" | sed '1q')
                  count_ip=$(echo "$count_ip" | sed '1d')
                  numH="$num"
                  while true; do
                        if [ "$numH" == "0" ]; then
                                break
                        fi
                        numH=$((numH-1))
                        hash=$hash\#
                  done
                  echo "$line ($num): $hash"
                done;;
        hist-load)
                while true; do
                  type=$(echo "$filter" | awk 'NR==1{print $1}')
                  what=$(echo "$filter" | awk 'NR==1{print $2}')
                  case $type in
                        -ip | -uri)
                                file=$(echo "$file" | grep "$what ");;
                        -a)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateAfter;;
                        -b)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateBefore;;
                  esac
                  filter=$(echo "$filter" | sed '1d')
                  if [ -z "$filter" ]; then
                        break
                  fi
                done
                hist_load=$(echo "$file" | awk '{print $4}' | tr -d '-'| tr -d '[' |
                tr -d '\" \""'| cut -c 1-14 | sed 's/Jan/01/g' | sed 's/Feb/02/g' |
                sed 's/Mar/03/g' | sed 's/Apr/04/g' | sed 's/May/05/g' | sed 's/Jun/06/g' |
                sed 's/Jul/07/g' | sed 's/Aug/08/g' | sed 's/Sep/09/g' | sed 's/Oct/10/g' |
                sed 's/Nov/11/g' | sed 's/Dec/12/g')
                hist_load=$(echo "$hist_load" | sort | sed -e '/^ *$/d' | uniq -c)
                hist_load=$(echo $hist_load | tr -s ' ' '\n')
                count_ip=$(echo "$hist_load" | awk 'NR % 2 == 1')
                hist_load=$(echo "$hist_load" | awk 'NR % 2 == 0')

                while true; do
                  if [ -z "$count_ip" ]; then
                        break
                  fi
                  hash=""
                  line=$(echo "$hist_load" | sed '1q')
                  year=$(echo "$line" | cut -c 7-10)
                  month=$(echo "$line" | cut -c 4-5)
                  day=$(echo "$line" | cut -c 1-2)
                  hour=$(echo "$line" | cut -c 12-13)
                  line=$(echo "$year-$month-$day $hour:00")
                  hist_load=$(echo "$hist_load" | sed '1d')
                  num=$(echo "$count_ip" | sed '1q')
                  count_ip=$(echo "$count_ip" | sed '1d')
                  numH="$num"
                  while true; do
                        if [ "$numH" == "0" ]; then
                                break
                        fi
                        numH=$((numH-1))
                        hash=$hash\#
                  done
                  echo "$line ($num): $hash"
                done;;
        *)
                while true; do
                  if [ -z "$filter" ]; then
                        break
                  fi
                  type=$(echo "$filter" | awk 'NR==1{print $1}')
                  what=$(echo "$filter" | awk 'NR==1{print $2}')
                  case $type in
                        -ip | -uri)
                                file=$(echo "$file" | grep "$what ");;
                        -a)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateAfter;;
                        -b)
                                fileNew="$file"
                                file=""
                                dateParse
                                dateBefore;;
                  esac
                  filter=$(echo "$filter" | sed '1d')
                done
                #no filter, no command
                echo "$file";;
esac

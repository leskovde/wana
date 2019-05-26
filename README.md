# WANA - Web Server Analyser

WANA is a log file analysing script. It filters these files and provides the user with a complete analysis based on his needs.

## Usage

```
wana [FILTER] [COMMAND] [LOG [LOG2 [...]] 
```

## Options

```
Commands: Maximum of one per run.
     list-ip - lists all source IP addresses
     list-hosts - lists all source domains
     list-uri - lists all URIs"
     hist-ip - draws a histogram of IP address visits
     hist-load - draws a histogram of visits over time
Filters: Any combination of the following.
     -a DATETIME - all logs after DATETIME (excluding)
     -b DATETIME - all logs before DATETIME (excluding)
        (DATETIME is YYYY-MM-DD HH:MM:SS)
     -ip IPADDR' - all logs with corresponding IP address
        (IPADDR is IPv4 or IPv6)
     -uri URI - all logs with corresponding URI
        (URI is a non-extended REGEXP)
```

## Features

The script filters web server log files. If a command is passed as an argument, the script will execute the command based on the filtered results.

In case neither the filter or the command is specified, the script prints the content of all log files to the standard output.

The script can use gzip to process compressed files (if these files end with .gz).

In case no log file is specified, the script uses lines of the standard input instead.

The output is printed with no duplicities.

The histogram is drawn using ASCII. Every line of the histogram denotes a category (e.g. IP address or time interval). 

Frequency of this category is shown using a sequence of #. The format is “%s (%d): %s”. The first argument identifies the category, the second represents enumerated frequency and the third is a sequence of #, which represents frequency.

The IP address histogram is sorted based on frequency (and is descending).

The load histogram is divided into hour-long intervals, each of which has logs which began on that specific hour. Only logs non-zero occurrence are shown by the histogram.

The format is YYYY-MM-DD HH:00. Total timespan is based on either input or filtered logs.

The script does not modify any files. It also does not create any temporary files.

IP address follows the RFC 1884 2.2 format; therefore it can be either IPv4, IPv6, or IPv6 compressed.

The script does not take the significance of any IP address into consideration. IP addresses are distinguished based on their alphanumerical representation.

The script does not take time zones into consideration. It presumes that every log has its timestamp in the same time zone.

## Return Value
The script returns 0 whenever it runs successfuly. Otherwise it returns 1 accompanied by a message that specifies the error.

### Examples

```
$ ./wana.sh -a "2019-02-22 09:00:00" -b "2019-02-22 09:44:54" example.log 
147.229.13.201 - - [22/Feb/2019:09:24:33 +0100] "-" 408 3275 "-" "-" 
147.229.13.201 - - [22/Feb/2019:09:24:33 +0100] "-" 408 3275 "-" "-" 
198.27.69.191 - - [22/Feb/2019:09:43:13 +0100] "GET / HTTP/1.1" 200 22311 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:64.0) Gecko/20100101 Firefox/64.0" 
198.27.69.191 - - [22/Feb/2019:09:43:24 +0100] "GET / HTTP/1.1" 200 22313 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:64.0) Gecko/20100101 Firefox/64.0" 
198.27.69.191 - - [22/Feb/2019:09:43:42 +0100] "GET /?gf_page=upload HTTP/1.1" 200 22304 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:64.0) Gecko/20100101 Firefox/64.0" 
198.27.69.191 - - [22/Feb/2019:09:44:07 +0100] "GET / HTTP/1.1" 200 22313 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:64.0) Gecko/20100101 Firefox/64.0" 
198.27.69.191 - - [22/Feb/2019:09:44:37 +0100] "GET /?up_auto_log=true HTTP/1.1" 200 22315 "-" "Mozilla/5.0 (Windows NT 6.1; rv:36.0) Gecko/20100101 Firefox/36.0"

$ ./wana.sh -ip 2001:67c:1220:808::93e5:8ad hist-load example.log.1 
2019-02-21 08:00 (1): # 
2019-02-21 10:00 (1): # 
2019-02-21 14:00 (1): # 
2019-02-21 16:00 (1): # 
2019-02-21 19:00 (1): # 
2019-02-21 20:00 (1): # 
2019-02-21 22:00 (1): # 
2019-02-21 23:00 (1): # 
2019-02-22 02:00 (1): # 
2019-02-22 03:00 (2): ## 
2019-02-22 05:00 (1): # 
2019-02-22 07:00 (1): #
```

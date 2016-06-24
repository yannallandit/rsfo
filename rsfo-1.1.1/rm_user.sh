# $Id: rm_user.sh  1.0.4 2004/07/26 12:02:00 Yann Allandit $
#==============================================================================
#       (c) Copyright 2004 Hewlett-Packard Development Company, L.P.
#    The information contained herein is subject to change without notice.
#==============================================================================
#
#  MM/DD/YY  BY                Modification History
#  04/07/26  Yann Allandit     Creation
#  04/07/28  Yann Allandit     Add rsh services unsetting	
#  16/03/09  Yann Allandit     Beta version. Do not use with 2016 implementation
##############################################################################
#!/bin/bash

export `grep ORACLE_BASE= /home/oracle/.bash_profile`
echo "The directory $ORACLE_BASE will be erased. Do you Accept? (Yy/Nn)"
read answer
if [ "X${answer}" == "XY" ] || [ "X${answer}" == "Xy" ]
then
  rm -fR $ORACLE_BASE
fi 

userdel oracle
userdel grid
groupdel dba
groupdel oinstall
groupdel asmadmin
groupdel asmdba

rm -f /var/opt/oracle

if [ -f /usr/bin/gcc.RSFO ]
then
  mv /usr/bin/gcc.RSFO /usr/bin/gcc
fi 

if [ -f /usr/bin/g++.RSFO ]
then
  mv /usr/bin/g++.RSFO /usr/bin/g++
fi
 
if [ -f /etc/sysctl.conf.RSFO ]
then 
  cp -f /etc/sysctl.conf.RSFO /etc/sysctl.conf
  /sbin/sysctl -p
fi
 
if [ -f /etc/securetty.RSFO ]
then 
  mv /etc/securetty.RSFO /etc/securetty
fi

if [ -f /etc/security/limits.conf.RSFO ]
then 
  mv /etc/security/limits.conf.RSFO /etc/security/limits.conf
fi
 
if [ -f /tmp/scripts/packages_added.txt ]
then
  read -r P1 P2 P3 P4 P5 P6 P7 P8 P9 P10 P11 P12 P13 P14 < /tmp/scripts/packages_added.txt

  for ((i=1; i<=14; i++))
  do
    show_name="P${i}"
    eval show_name=\$$show_name
    if [ "X${show_name}" != "X" ]
    then
      rpm -e ${show_name}
      echo "package ${show_name} uninstalled"
      echo
    fi
  done
  mv -f /tmp/scripts/packages_added.txt /tmp/scripts/packages_added.txt.old
fi 

rm -fr /tmp/scripts

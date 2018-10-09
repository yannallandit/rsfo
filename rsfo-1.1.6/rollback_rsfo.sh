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
#  16/06/28  Yann Allandit     2016 version of the "remove rsfo script"
##############################################################################
#!/bin/bash

SilentInstall="N"
file_nname=/tmp/scripts/nod_list.txt
file_param=/tmp/scripts/rsfoparam.txt
file_log=/tmp/scripts/log_rac.txt
file_rhosts=/tmp/scripts/rhosts.txt
file_pack=/tmp/scripts/packages_added.txt

if [ "X${SilentInstall}" = "XN" ]
then
  if [ -f $file_nname ]
  then
    node_number=$(wc -w $file_nname | cut -f 1 -d " ")
    echo "There is ""${node_number}"" nodes in this cluster"
    read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

    for ((i=1; i<=node_number; i++))
    do
      show_name="N${i}"
      eval show_name=\$$show_name
      echo "Private node ${i} name is ${show_name}"
    done

    echo
    echo "Is this list correct (Y/N)?"
    read name_check
    while [ "X${name_check}" != "XN" ] && [ "X${name_check}" != "XY" ]
    do
      echo "The answer can only be Y or N"
      echo "Is this list correct (Y/N)?"
      read name_check
    done

    if [ "X${name_check}" = "XY" ]
    then
      input_nodes=N
    else
      : > ${file_nname}
    fi
  fi

  if [ "X${input_nodes}" != "XN" ]
  then
    echo
    echo "######################################################################"
    echo " The script will ask you to define the number of nodes in the cluster"
    echo

    echo "Enter the number of nodes in your cluster (min 1, max 12):"
    read node_number

    while [ -z $node_number ]
    do
      echo "The number can't be null"
      echo "Enter the number of nodes:"
      read node_number
    done

    while (($node_number<1)) || (($node_number>12))
    do
      echo "The number need to be 0<n<13"
      echo "Enter the number of nodes:"
      read node_number

      while [ -z $node_number ]
      do
        echo "The number can't be null"
        echo "Enter the number of nodes:"
        read node_number
      done
    done
  fi
fi

##########################################
# Register name of each node
##########################################

if [ "X${SilentInstall}" = "XN" ]
then
  if [ "X${input_nodes}" != "XN" ]
  then
    echo
    echo "#############################################################"
    echo " You will now enter the private name of the cluster nodes"
    echo " The private name is the name linked to the interconnect port"
    echo

    while [ ${name_input} == "N" ]
    do
      for ((i=1; i<=node_number; i++))
      do
        if [ $i = 1 ]
        then
          : > $file_nname
        fi

        node_name=""
        while [ -z $node_name ]
        do
          echo "Enter the private node name of the node Number $i:"
          read node_name
          if [ -n $node_name ]
          then
            list_node=`head -1 $file_nname`
            list_node=`echo "${list_node} ${node_name}"`
            echo $list_node>$file_nname
          else
            echo "Node name cant be null"
          fi
        done
      done

# Check node name
      read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

      for ((i=1; i<=node_number; i++))
      do
        show_name="N${i}"
        eval show_name=\$$show_name
        echo " Node number $i name is $show_name"
      done

      echo "Is this list correct (Y/N)?"
      read name_check
      while [ "X${name_check}" != "XN" ] && [ "X${name_check}" != "XY" ]
      do
        echo "The answer can only be Y or N"
        echo "Is this list correct (Y/N)?"
        read name_check
      done
      name_input=${name_check}
    done
  fi
fi

#################################################
# Check if ssh works
#################################################

echo
echo "################################################################"
echo " The script will now test the ssh setting"
echo " If the script hang, it means that the ssh doesn't work properly"
echo

sshd_check=`ps -ef|grep /usr/sbin/sshd|grep -v grep|wc|awk '{print $1}'`
if [ "$sshd_check" -lt 1 ]
then
  echo "ssh daemon is not running on the local node."
  echo "start it before running this script."
  exit
fi

################# RSA security checking ######
if [[ ! -f /root/.ssh/authorized_keys ]]
then
  local_node_name=`uname -a|awk '{print $2}'`
  echo "ssh with RSA security level is not correctly set on ${local_node_name}"
  echo "perform the steps describes in the SSH_setting.txt file"
  echo
  exit
fi

################# Test ssh between nodes #########
read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh $show_name date>/dev/null 2>$file_log
  ssh_valid=$?
  if [ $ssh_valid -ne 0 ]
  then
    echo "ssh doesn't work with $show_name"
    exit 1
  else
    echo "ssh works with $show_name"
  fi
done


####################################################
# Remove RSFO setting
####################################################

echo "Do you want to remove the oracle and grid users, groups and directory? (Yy/Nn)"
read answer
if [ "X${answer}" == "XY" ] || [ "X${answer}" == "Xy" ]
then
  for ((i=1; i<=node_number; i++))
  do
    show_name="N${i}"
    eval show_name=\$$show_name
    ORACLE_BASE=`ssh ${show_name} grep ORACLE_BASE= /home/oracle/.bash_profile`
    GRID_BASE=`ssh ${show_name} grep ORACLE_BASE= /home/grid/.bash_profile`
    HOME_BASE=`ssh ${show_name} grep ORACLE_HOME= /home/grid/.bash_profile`
    ssh ${show_name}  rm -fR ${ORACLE_BASE}
    ssh ${show_name}  rm -fR ${GRID_BASE}
    ssh ${show_name}  rm -fR ${GRID_HOME}
    ssh ${show_name}  userdel oracle
    ssh ${show_name}  userdel grid
    ssh ${show_name}  groupdel dba
    ssh ${show_name}  groupdel oinstall
    ssh ${show_name}  groupdel asmadmin
    ssh ${show_name}  groupdel asmdba
    ssh ${show_name}  "rm -f /etc/oraInst.loc"

    ssh ${show_name} "tuned-adm profile latency-performance" >/dev/null 2>${file_log}
    ssh ${show_name} "rm -f /var/opt/oracle"

    if ssh ${show_name} stat /etc/pam.d/login.RSFO \> /dev/null 2\>\&1
    then
      ssh ${show_name} "mv /etc/pam.d/login.RSFO /etc/pam.d/login"
    fi

    if ssh ${show_name} stat /etc/profile.RSFO \> /dev/null 2\>\&1
    then
      ssh ${show_name} "mv /etc/profile.RSFO /etc/profile"
    fi
  
    if ssh ${show_name} stat /etc/sysconfig/grub.RSFO \> /dev/null 2\>\&1
    then
      ssh ${show_name} "mv /etc/sysconfig/grub.RSFO /etc/sysconfig/grub"
      ssh ${show_name} "grub2-mkconfig -o /boot/grub2/grub.cfg"
    fi

    if ssh ${show_name} stat /etc/selinux/config.RSFO \> /dev/null 2\>\&1
    then
      ssh ${show_name}  "mv /etc/selinux/config.RSFO /etc/selinux/config"
    fi

    if ssh ${show_name} stat /etc/sysctl.conf.RSFO \> /dev/null 2\>\&1
    then
      ssh ${show_name} "cp -f /etc/sysctl.conf.RSFO /etc/sysctl.conf"
      ssh ${show_name} "/sbin/sysctl -p"
    fi

    if ssh ${show_name} stat /etc/securetty.RSFO \> /dev/null 2\>\&1
    then
      ssh ${show_name} "mv /etc/securetty.RSFO /etc/securetty"
    fi

    if ssh ${show_name} stat /etc/security/limits.conf.RSFO \> /dev/null 2\>\&1
    then 
      ssh ${show_name} "mv /etc/security/limits.conf.RSFO /etc/security/limits.conf"
    fi

    rm -fr /tmp/scripts

  done
fi


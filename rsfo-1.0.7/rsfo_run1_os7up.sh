# User creation file :
#
# $Id: OS7.sh  1.0.6 2004/08/02 18:02:00 Yann Allandit $
#==============================================================================
#       (c) Copyright 2004 Hewlett-Packard Development Company, L.P.
#    The information contained herein is subject to change without notice.
#==============================================================================
#
#  YY/MM/DD  BY                Modification History
#  04/04/23  Yann Allandit     Creation
#  04/04/26  Yann Allandit     Add kernel parameters setting
#  04/04/27  Yann Allandit     Compilor release managment
#  04/07/23  Yann Allandit     Compilor release managment update
#  04/07/23  Yann Allandit     Pre-requisites packages appication
#  04/07/26  Yann Allandit     Undo setting for updated files and packages
#  04/07/28  Yann Allandit     Nodes list managment update - avoid double input -
#  04/08/02  Yann Allandit     gcc and g++ release managment updated
#  16/03/02  Yann Allandit     Port to RHEL/CentOS 7.x
#  16/04/06  Yann Allandit     Improved memory kernel setting
#  16/04/06  Yann Allandit     Added support for RHEL/CentOS 6.x
###############################################################################
#!/bin/bash
#!/usr/bin/perl


################### Variable definition #################
node_number=0           # Number of nodes in the cluster
node_name=empty         # Node name
list_node=empty         # List of all nodes name
i=0                     # Loop counter
name_input=N            # Boolean value for name nodes checking
name_check=N            # Temp Boolean value for name nodes checking
ssh_valid=0             # Check the ssh setting
sshd_check=0	        # Check if sshd is running
user_test=X             # Check the user running the script
local_node_name="empty" # Local node name got by "uname -a"
kparam="empty"          # Kernel parameter name
kvalue=0                # Kernel parameter value
kparam_exist=0          # Boolean for kernel param existence
perl_order1="empty"     # Variable for perl command (used for kernel param)
pack_check=0            # Check if package is installed or not
pack_name=""		# Package name to be installed
list_pack=""		# Temporary list of packages aplied to the system
input_nodes=Y		# Boolean for input of nodes name
rhrelease="empty"	# Collect the version of the OS
SELinuxSet="empty"	# Current setting of SELinux 
repolist="empty"	# Check if a YUM repository was defined on the system
OSversion="empty"	# Check the OS version used for this installation


#############################################
# Check Environment
#############################################

##################### need to be root to run this script ###########
clear
user_test=`whoami`
if [ "X${user_test}" != "Xroot" ]
then
  echo "You need to be root to run this script"
  exit 1
fi

#################### Check the Red Hat release ####################
if [ ! -f /etc/os-release ]; then
  if [ ! -f /etc/redhat-release ]; then
    echo "Unable to identify the OS release!"
    echo "check if /etc/os-release exists"
    exit 1
  fi
fi

rhrelease=`cat /etc/os-release |grep Maipo`
if [ "X${rhrelease}" = "X" ]
then
  rhrelease=`cat /etc/os-release |grep Santiago`
  if [ "X${rhrelease}" = "X" ]
  then
    echo "This server does not run a Red Hat/CentOS 6.x or 7.x release"
    echo "Check /etc/os-release"
    exit 1
  else
    OSversion=RH6
  fi
else
  OSversion=RH7  
fi

#################### Check if a Yum repository is available #######
repolist=`yum repolist|grep repolist|awk '{print $2}'`
if [ "X${repolist}" = "X0" ]
then
  echo "There is no YUM repository defined on your system. Please enable"
  exit 1
fi


########################################
# Files definition 
########################################
if [[ ! -d /tmp/scripts ]]
then
  mkdir -p /tmp/scripts
fi

# /tmp/scripts/nod_list.txt : Temp file for list of nodes name
file_nname=/tmp/scripts/nod_list.txt

# /tmp/scripts/log_rac.txt : log file
file_log=/tmp/scripts/log_rac.txt
: > /tmp/scripts/file_log.txt 

# /tmp/scripts/rhosts.txt : .rhosts template file
file_rhosts=/tmp/scripts/rhosts.txt
: > /tmp/scripts/rhosts.txt

# /tmp/scripts/packages_added.txt : List of added packages
file_pack=/tmp/scripts/packages_added.txt

###########################################
# Define the number of nodes in the cluster
###########################################

################ Check if a list of node file already exist ##############
if [ -f $file_nname ]
then
  node_number=`more ${file_nname}|wc|awk '{print $2}'`
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

##########################################
# Register name of each node
##########################################

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


#######################################################
# Trace file directory creation on remote nodes
#######################################################

read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

for ((i=2; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  if [ -n "`ssh ${show_name} \"test ! -d /etc/scripts && echo exists\"`" ]
  then
    ssh ${show_name} mkdir -p /tmp/scripts
    ssh ${show_name} : >/tmp/scripts/packages_added.txt
  fi
done

############################################################
# Set kernel parameters
############################################################
 
echo
echo "################################################"
echo "The script will now set the kernel parameters"
echo "on all nodes of your cluster."
echo

for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh ${show_name} cp -f /etc/sysctl.conf /etc/sysctl.conf.RSFO
  ssh ${show_name} "echo \"# Update done by RSFO scripts\">>/etc/sysctl.conf"

  for kparam in "kernel.sem" "kernel.shmall" "kernel.shmmax" "kernel.shmmni" "fs.file-max" "net.ipv4.ip_local_port_range" "net.core.rmem_default" "net.core.wmem_default" "net.core.rmem_max" "net.core.wmem_max" "fs.aio-max-nr" "vm.swappiness" "vm.dirty_background_ratio" "vm.dirty_ratio" "vm.dirty_expire_centisecs" "vm.dirty_writeback_centisecs"
  do
    case $kparam in
    kernel.sem)
      kvalue="250 32000 100 128"
      ;;
    kernel.shmall)
      kvalue=`ssh ${show_name} free -k|grep Mem:|awk '{print $2}'`
      kvalue=`expr ${kvalue} / 5 \* 4`
      ;;
    kernel.shmmax)
      kvalue=`ssh ${show_name} free -b|grep Mem:|awk '{print $2}'`
      kvalue=`expr ${kvalue} / 10 \* 7`
      ;;
    kernel.shmmni)
      kvalue=4096
      ;;
    fs.file-max)
      kvalue=6815744
      ;;
    net.ipv4.ip_local_port_range)
      kvalue="9000 65500"
      ;;
    net.core.rmem_default)
      kvalue="262144"
      ;;
    net.core.wmem_default)
      kvalue="262144"
      ;;
    net.core.rmem_max)
      kvalue="4194304"
      ;;
    net.core.wmem_max)
      kvalue="4194304"
      ;;
    fs.aio-max-nr)
      kvalue="1048576"
      ;;
    vm.swappiness)
      kvalue="0"
      ;;
    vm.dirty_background_ratio)
      kvalue="3"
      ;;
    vm.dirty_ratio)
      kvalue="80"
      ;;
    vm.dirty_expire_centisecs)
      kvalue="500"
      ;;
    vm.dirty_writeback_centisecs)
      kvalue="100"
      ;;
    esac
   
    kparam_exist=`ssh ${show_name} grep ${kparam} /etc/sysctl.conf|grep -v grep|wc|awk '{print $1}'` 
    if [ $kparam_exist -ne 0 ]
    then
      perl_order1="ssh ${show_name} perl -pi -e \"s/${kparam}/# ${kparam}/g\" /etc/sysctl.conf"
      $perl_order1
    fi

    ssh ${show_name} "echo \"${kparam} = ${kvalue}\">>/etc/sysctl.conf"
    echo "${show_name} : ${kparam} = ${kvalue}"
  done
  ssh ${show_name} "/sbin/sysctl -p" >/dev/null 2>${file_log}
  echo "new kernel parameters were loaded on node ${show_name}"
done


###########################################################
# Alter SELinux setting
###########################################################
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  SELinuxSet=`ssh ${show_name} getenforce`
  if [ "X${SELinuxSet}" = "XEnforcing" ]
  then
    ssh ${show_name} setenforce 0 >/dev/null 2>${file_log}
    ssh ${show_name} sed -i -e "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config >/dev/null 2>${file_log}
    echo "SELinux was set to permissive on ${show_name}"
  fi
done


###########################################################
# Deactivating the firewall
###########################################################
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh ${show_name} systemctl stop firewalld >/dev/null 2>${file_log}
  ssh ${show_name} systemctl disable firewalld >/dev/null 2>${file_log}
  echo "firewalld was stopped & disabled on ${show_name}"
done


###########################################################
# Set the limits
###########################################################
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh ${show_name} cp /etc/security/limits.conf /etc/security/limits.conf.rsfo.bkp
  limitend=`ssh ${show_name} tail -1 /etc/security/limits.conf`
  if [ "X${limitend}" = "X# End of file" ]
  then
    ssh ${show_name} "sed -i'.bak' '\$d' /etc/security/limits.conf" 
  fi
  ssh ${show_name} "echo 'grid                 soft    nproc   2047'>>/etc/security/limits.conf"
  ssh ${show_name} "echo 'grid                 hard    nproc   16384'>>/etc/security/limits.conf"
  ssh ${show_name} "echo 'grid                 soft    nofile  1024'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'grid                 hard    nofile  65536'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'grid                 soft    stack   10240'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'grid                 hard    stack   32768'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'grid                 soft    memlock  41984000'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'grid                 hard    memlock  41984000'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'oracle               soft    memlock  41984000'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'oracle               hard    memlock  41984000'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'oracle               soft    nproc   2047'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'oracle               hard    nproc   16384'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'oracle               soft    nofile  1024'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'oracle               hard    nofile  65536'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'oracle               soft    stack   10240'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo 'oracle               hard    stack   32768'>>/etc/security/limits.conf" 
  ssh ${show_name} "echo '# End of file'>>/etc/security/limits.conf" 
  echo "Limits were set for grid and oracle users on ${show_name}"
done


###########################################################
# Installation of the prerequisites packages
###########################################################

if [ $OSversion = "RH7" ]
then
  for ((i=1; i<=node_number; i++))
  do
    show_name="N${i}"
    eval show_name=\$$show_name
    ssh ${show_name} yum install -y binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.i686 compat-libstdc++-33.x86_64 gcc.x86_64 gcc-c++.x86_64 glibc.i686 glibc.x86_64 glibc-devel.i686 glibc-devel.x86_64 ksh.x86_64 libgcc.i686 libgcc.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++-devel.i686  libstdc++-devel.x86_64 libaio.i686 libaio.x86_64 libaio-devel.i686 libaio-devel.x86_64 libXext.i686 libXext.x86_64 libXtst.i686 libXtst.x86_64 libX11.i686 libX11.x86_64 libXau.i686 libXau.x86_64 libxcb.i686 libxcb.x86_64 libXi.i686 libXi.x86_64 make.x86_64 sysstat.x86_64 unixODBC-devel.x86_64 unixODBC.x86_64 >/dev/null 2>${file_log}
    echo "Oracle needed packages were installed on ${show_name}"
  done

elif [ $OSversion = "RH6" ]
then
  for ((i=1; i<=node_number; i++))
  do
    show_name="N${i}"
    eval show_name=\$$show_name
    ssh ${show_name} yum install -y binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.i686 compat-libstdc++-33.x86_64 gcc.x86_64 gcc-c++.x86_64 glibc.i686 glibc.x86_64 glibc-devel.i686 glibc-devel.x86_64 ksh.x86_64 libgcc.i686 libgcc.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++-devel.i686  libstdc++-devel.x86_64 libaio.x86_64 libaio-devel.x86_64 libXext.x86_64 libXtst.x86_64 libX11.x86_64 libXau.x86_64 libxcb.x86_64 libXi.x86_64 make.x86_64 sysstat.x86_64 unixODBC-devel.x86_64 unixODBC.x86_64 glibc-devel.x86_64 cpp.x86_64 glibc-headers.x86_64 kernel-headers.x86_64 mpfr.x86_64 redhat-release-server.x86_64 cloog-ppl.x86_64 libstdc++.x86_64 libstdc++-devel.x86_64 ppl.x86_64 >/dev/null 2>${file_log}
    echo "Oracle needed packages were installed on ${show_name}"
  done
fi



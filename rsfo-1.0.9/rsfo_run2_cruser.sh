# User creation file :
#
# $Id: create_user.sh  2.0.9 2004/08/11 18:08:00 Yann Allandit $
#==============================================================================
#       (c) Copyright 2004 Hewlett-Packard Development Company, L.P. 
#    The information contained herein is subject to change without notice. 
#==============================================================================
#
#  YY/MM/DD  BY                Modification History
#  04/02/24  Yann Allandit     Created
#  04/04/10  Yann Allandit     Extension to 6 nodes 
#  04/04/11  Yann Allandit     Input and store nodes name
#  04/04/15  Yann Allandit     ID and SSH checking 
#  04/04/16  Yann Allandit     RSH for Oracle setting
#  04/04/16  Yann Allandit     Groups and user creation
#  04/04/21  Yann Allandit     Updatable $ORACLE_BASE
#  04/04/26  Yann Allandit     Add setting limits.conf
#  04/07/23  Yann Allandit     Add OPatch utility installation
#  04/07/23  Yann Allandit     Pre-requisite patch 3006854 application
#  04/07/23  Yann Allandit     Automatic rsh enabling
#  04/07/26  Yann Allandit     Undo setting for updated files
#  04/07/28  Yann Allandit     Fix rsh setup problem for oracle user
#  04/07/28  Yann Allandit     Nodes list managment update - avoid double input -
#  04/07/29  Yann Allandit     .rhosts file definition update. contain both private and public port
#  04/08/02  Yann Allandit     Automatic ssh setting for oracle user added
#  04/08/11  Yann Allandit     Fix limits.conf typo - nproc vs noproc -
#  05/04/27  Yann Allandit     Update variable increment counter
#  16/03/03  Yann Allandit     Support of 12c on RHEL7 and CentOS7
#  16/03/03  Yann Allandit     Support of 12 nodes cluster 
#  16/03/07  Yann Allandit     Include the grid user creation
#  16/04/06  Yann Allandit     Add ssh setup for the grid user
#  16/04/12  Yann Allandit     Define "password" as default pwd for oracle & grid users
#  16/04/27  Yann Allandit     gid management for hugepages setting 
###############################################################################
#!/bin/bash


################### Variable definition #################
node_number=0          # Number of nodes in the cluster
node_name=empty        # Node name
list_node=empty        # List of all nodes name
i=0                    # Loop counter
j=0                    # Loop counter
k=0                    # Loop counter
name_input=N           # Boolean value for name nodes checking
name_check=N           # Temp Boolean value for name nodes checking
ssh_valid=0            # Check the ssh setting
sshd_check=0	       # Check if sshd is running
local_node_name=empty  # Value of uname -a
user_test=X            # Check the user running the script
dba_exist=0            # Check if the group exists
oinstall_exist=0       # Check if the group exists
oracle_exist=0         # Check if the user exists
group_check=0          # Exit if group or user exist
asmdba_exist=0         # Check if the group exists
asmadmin_exist=0       # Check if the group exists
grid_exist=0           # Check if the user exists
dba_number=500         # Synchronized groupid value
oinstall_number=501    # Synchronized groupid value
asmdba_number=502      # Synchronized groupid value
asmadmin_number=503    # Synchronized groupid value
oracle_number=500      # Synchronized uid value
grid_number=501        # Synchronized uid value
avail_number=F         # Boolean for available uid or gid
exist_number=0         # Loop checking for uid and gid
OORABASE="/u02/app/oracle"    # Current $ORACLE_BASE
NORABASE="/u02/app/oracle"    # New $ORACLE_BASE
NORABASE2="/u02/app/oracle"   # Temporary New $ORACLE_BASE
OGRIDBASE="/u01/app/grid"     # Current $ORACLE_BASE
NGRIDBASE="/u01/app/grid"     # New $ORACLE_BASE
NGRIDBASE2="/u01/app/grid"    # Temporary New $ORACLE_BASE
obase_input=N          # Valid new ORACLE_BASE
obase_check=Y          # Want to change the ORACLE_BASE
hosts_equiv_exist=0    # Check if hosts.equiv has to be updated
limits_status=0	       # Check if limits are set or not
limits_val=0	       # Value to be inserted in limits.conf	
rsh_service=""         # Remote connection service name for loop
rsh_status=""          # Remote connection service status (on/off)
rsh_trace=""           # Tag file for uninstall
input_nodes=Y	       # Boolean for input node list
nb_eth=0	       # Define the number of ethernet port on the system
ipaddr=0	       # Store temporarely an ip address for .rhost definition	



#############################################
# Check Environment
#############################################

clear
user_test=`whoami`
if [ "X${user_test}" != "Xroot" ]
then
  echo "You need to be root to run this script"
  exit 1
fi


########################################
# Files definition on local node
########################################
if [[ ! -d /tmp/scripts ]]
then
  mkdir -p /tmp/scripts
fi

# /tmp/scripts/ : Temp & log directory 
temp_dir=/tmp/scripts/

# /tmp/scripts/nod_list.txt : Temp file for list of nodes name
file_nname=/tmp/scripts/nod_list.txt

# /tmp/scripts/log_rac.txt : log file
file_log=/tmp/scripts/log_rac.txt
: > /tmp/scripts/file_log.txt 

# /tmp/scripts/rhosts.txt : .rhosts template file
file_rhosts=/tmp/scripts/rhosts.txt
: > /tmp/scripts/rhosts.txt

# ./ora_profile : file provided with this script, template of .bash_profile
ora_profile=./ora_profile

# ./grid_profile : file provided with this script, template of .bash_profile
grid_profile=./grid_profile


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
  fi
done


#######################################################
# dba & oinstall groups synchronization + user creation
#######################################################

echo
echo "################################################"
echo " The script will now create the Oracle user"
echo

##### check if the group and user exist
read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name

  dba_exist="`ssh ${show_name} grep -c dba /etc/group`"
  if [ $dba_exist != 0 ]
  then 
    echo "dba group already exists on ${show_name}"
    group_check=1
  fi

  oinstall_exist="`ssh ${show_name} grep -c oinstall /etc/group`"
  if [ $oinstall_exist != 0 ]
  then 
    echo "oinstall group already exists on ${show_name}"
    group_check=1
  fi

  asmdba_exist="`ssh ${show_name} grep -c asmdba /etc/group`"
  if [ $asmdba_exist != 0 ]
  then 
    echo "asmdba group already exists on ${show_name}"
    group_check=1
  fi

  asmadmin_exist="`ssh ${show_name} grep -c asmadmin /etc/group`"
  if [ $asmadmin_exist != 0 ]
  then 
    echo "asmadmin group already exists on ${show_name}"
    group_check=1
  fi

  oracle_exist="`ssh ${show_name} grep -c oracle /etc/passwd`"
  if [ $oracle_exist != 0 ]
  then 
    echo "oracle user already exists on ${show_name}"
    group_check=1
  fi

  grid_exist="`ssh ${show_name} grep -c grid /etc/passwd`"
  if [ $grid_exist != 0 ]
  then 
    echo "grid user already exists on ${show_name}"
    group_check=1
  fi
done

if [ $group_check = 1 ]
then
  echo
  echo "user or group already exist. Can't continue."
  exit 1
fi


####### Define uid and gid #############

for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  avail_number=F
  while [ ${avail_number} = "F" ]
  do 
    exist_number="`ssh ${show_name} grep -c $dba_number /etc/group`"
    if [ $exist_number = 0 ]
    then
      avail_number=T
    else
     dba_number=`expr ${dba_number} + 1`
    fi
  done
done

oinstall_number=`expr ${dba_number} + 1`
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  avail_number=F 
  while [ ${avail_number} = "F" ]
  do
    exist_number="`ssh ${show_name} grep -c $oinstall_number /etc/group`"
    if [ $exist_number = 0 ]
    then
      avail_number=T
    else
      oinstall_number=`expr ${oinstall_number} + 1`
    fi
  done
done

asmdba_number=`expr ${oinstall_number} + 1`
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  avail_number=F 
  while [ ${avail_number} = "F" ]
  do
    exist_number="`ssh ${show_name} grep -c $asmdba_number /etc/group`"
    if [ $exist_number = 0 ]
    then
      avail_number=T
    else
      asmdba_number=`expr ${asmdba_number} + 1`
    fi
  done
done

asmadmin_number=`expr ${asmdba_number} + 1`
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  avail_number=F 
  while [ ${avail_number} = "F" ]
  do
    exist_number="`ssh ${show_name} grep -c $asmadmin_number /etc/group`"
    if [ $exist_number = 0 ]
    then
      avail_number=T
    else
      asmadmin_number=`expr ${asmadmin_number} + 1`
    fi
  done
done


for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  avail_number=F
  while [ ${avail_number} = "F" ]
  do
    exist_number="`ssh ${show_name} grep -c $oracle_number /etc/passwd`"
    if [ $exist_number = 0 ]
    then
      avail_number=T
    else
      oracle_number=`expr ${oracle_number} + 1`
    fi
  done
done

grid_number=`expr ${oracle_number} + 1`
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  avail_number=F
  while [ ${avail_number} = "F" ]
  do
    exist_number="`ssh ${show_name} grep -c $grid_number /etc/passwd`"
    if [ $exist_number = 0 ]
    then
      avail_number=T
    else
      grid_number=`expr ${grid_number} + 1`
    fi
  done
done


############# oracle user bash_profile setting #######

OORABASE=`grep ORACLE_BASE= $ora_profile`

echo "Database \$ORACLE_BASE is ${OORABASE}"
echo "Do you want to change it (Y/N)?"
read obase_check
while [ "X${obase_check}" != "XN" ] && [ "X${obase_check}" != "XY" ]
do
  echo "The answer can only be Y or N"
  echo "Is this list correct (Y/N)?"
  read obase_check
done


obase_input=N

if [ "X${obase_check}" == "XY" ]
then
  while [ ${obase_input} == "N" ]
  do
    NORABASE=""
    while [ -z $NORABASE ]
    do
    echo "Enter the new path for the database ORACLE_BASE:"
    echo "Format is ""/directory_path"" without / at the end"
    read NORABASE
    NORABASE2=${NORABASE}
echo $NORABASE2

    if [ "X${NORABASE}" != "X" ]
    then
      NORABASE="ORACLE_BASE=${NORABASE}"
      echo " the new database ORACLE_BASE value is $NORABASE"
      echo "Is it correct (Y/N)?"
      read obase_check
        while [ "X${obase_check}" != "XN" ] && [ "X${obase_check}" != "XY" ]
        do
          echo "The answer can only be Y or N"
          echo "Is this list correct (Y/N)?"
          read obase_check
        done
      if [ "X${obase_check}" = "XY" ]
      then
        obase_input=Y
      fi
    fi
  done
  done

  OORABASE=`echo ${OORABASE}|sed -e 's/\//\\\\\//g'`
  NORABASE=`echo ${NORABASE}|sed -e 's/\//\\\\\//g'`
  var="perl -pi -e ""s/${OORABASE}/${NORABASE}/"" ${ora_profile}"
  $var
else
  NORABASE2=`echo ${OORABASE}|sed -e "s/ORACLE_BASE=//"`
fi


############# grid user bash_profile setting #######

OGRIDBASE=`grep ORACLE_BASE= $grid_profile`

echo "Grid \$ORACLE_BASE is ${OGRIDBASE}"
echo "Do you want to change it (Y/N)?"
read obase_check
while [ "X${obase_check}" != "XN" ] && [ "X${obase_check}" != "XY" ]
do
  echo "The answer can only be Y or N"
  echo "Is this list correct (Y/N)?"
  read obase_check
done

obase_input=N

if [ "X${obase_check}" == "XY" ]
then
  while [ ${obase_input} == "N" ]
  do
    NGRIDBASE=""
    while [ -z $NGRIDBASE ]
    do
    echo "Enter the new path for the grid ORACLE_BASE:"
    echo "Format is ""/directory_path"" without / at the end"
    read NGRIDBASE
    NGRIDBASE2=${NGRIDBASE}
echo $NGRIDBASE2

    if [ "X${NGRIDBASE}" != "X" ]
    then
      NGRIDBASE="ORACLE_BASE=${NGRIDBASE}"
      echo " the new Grid ORACLE_BASE value is $NGRIDBASE"
      echo "Is it correct (Y/N)?"
      read obase_check
        while [ "X${obase_check}" != "XN" ] && [ "X${obase_check}" != "XY" ]
        do
          echo "The answer can only be Y or N"
          echo "Is this list correct (Y/N)?"
          read obase_check
        done
      if [ "X${obase_check}" = "XY" ]
      then
        obase_input=Y
      fi
    fi
  done
  done

  OGRIDBASE=`echo ${OGRIDBASE}|sed -e 's/\//\\\\\//g'`
  NGRIDBASE=`echo ${NGRIDBASE}|sed -e 's/\//\\\\\//g'`
  var="perl -pi -e ""s/${OGRIDBASE}/${NGRIDBASE}/"" ${grid_profile}"
  $var
else
  NGRIDBASE2=`echo ${OGRIDBASE}|sed -e "s/ORACLE_BASE=//"`
fi

############# Groups and User creation ############
for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh ${show_name} /usr/sbin/groupadd -g ${dba_number} dba
  echo "dba group added on ${show_name} with gid ${dba_number}"
  ssh ${show_name} /usr/sbin/groupadd -g ${oinstall_number} oinstall
  echo "oinstall group added on ${show_name} with gid ${oinstall_number}"
  ssh ${show_name} /usr/sbin/groupadd -g ${asmdba_number} asmdba
  echo "asmdba group added on ${show_name} with gid ${asmdba_number}"
  ssh ${show_name} /usr/sbin/groupadd -g ${asmadmin_number} asmadmin
  echo "asmadmin group added on ${show_name} with gid ${asmadmin_number}"
  ssh ${show_name} /usr/sbin/useradd -G dba,asmdba -g oinstall -p oracle -s /bin/bash -u ${oracle_number} oracle
  ssh ${show_name} echo "oracle:oracle|/usr/sbin/chpasswd"
  echo "oracle user added on ${show_name} with uid ${oracle_number}. Password is oracle."
  ssh ${show_name} /usr/sbin/useradd -G dba,asmdba,asmadmin -g oinstall -p oracle -s /bin/bash -u ${grid_number} grid
  ssh ${show_name} echo "grid:oracle|/usr/sbin/chpasswd"
  echo "grid user added on ${show_name} with uid ${grid_number}. Password is oracle."
  ssh ${show_name} "echo password | passwd grid --stdin"
  ssh ${show_name} "echo password | passwd oracle --stdin"
  
  if [[ ! -d /opt/oracle ]]
  then
    ssh ${show_name} /bin/ln -s /home/oracle /var/opt/oracle
  else
    ssh ${show_name} /bin/ln -s /opt/oracle /var/opt/oracle
  fi

  ssh ${show_name} /bin/chown oracle:dba /var/opt/oracle
  ssh ${show_name} /bin/mkdir -p ${NORABASE2}/12c ${NGRIDBASE2}/12c 

  ssh ${show_name} /bin/chown -R oracle:oinstall ${NORABASE2}
  ssh ${show_name} /bin/chown -R grid:oinstall ${NGRIDBASE2}
  scp ${ora_profile} ${show_name}:/home/oracle/.bash_profile
  ssh ${show_name} /bin/chown oracle:oinstall /home/oracle/.bash_profile
  scp ${grid_profile} ${show_name}:/home/grid/.bash_profile
  ssh ${show_name} /bin/chown grid:oinstall /home/grid/.bash_profile
done


###############################################################
# sysctl.conf upadte for the gid allowing the hugepages access
###############################################################

if [ ${oinstall_number} != 501 ]
then
  echo "################################################"
  echo " Change gid for hugepages access."
  echo
 
  read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

  for ((i=1; i<=node_number; i++))
  do
    show_name="N${i}"
    eval show_name=\$$show_name
    ssh ${show_name} "sed -i -e 's@vm.hugetlb_shm_group = 501@vm.hugetlb_shm_group = ${oinstall_number}@' /etc/sysctl.conf"
    ssh ${show_name} sysctl -p
  done
fi


###############################################################
# Update /etc/profile with limit values 
###############################################################

echo
echo "################################################"
echo " RSFO will now update the /etc/profile file"
echo

read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh ${show_name} "echo ' ' >> /etc/profile"
  ssh ${show_name} "echo '# Grid Requirements' >> /etc/profile"
  ssh ${show_name} "echo 'if [ $USER = \"grid\" ]; then' >> /etc/profile"
  ssh ${show_name} "echo ' if [ $SHELL = \"/bin/ksh\" ]; then' >> /etc/profile"
  ssh ${show_name} "echo '  ulimit -p 16384' >> /etc/profile"
  ssh ${show_name} "echo '  ulimit -n 65536' >> /etc/profile"
  ssh ${show_name} "echo ' else' >> /etc/profile"
  ssh ${show_name} "echo '  ulimit -u 16384 -n 65536' >> /etc/profile"
  ssh ${show_name} "echo ' fi' >> /etc/profile"
  ssh ${show_name} "echo 'fi' >> /etc/profile"
  ssh ${show_name} "echo ' ' >> /etc/profile"
  ssh ${show_name} "echo ' ' >> /etc/profile"
  ssh ${show_name} "echo '# Oracle Requirements' >> /etc/profile"
  ssh ${show_name} "echo 'if [ $USER = \"oracle\" ]; then' >> /etc/profile"
  ssh ${show_name} "echo ' if [ $SHELL = \"/bin/ksh\" ]; then' >> /etc/profile"
  ssh ${show_name} "echo '  ulimit -p 16384' >> /etc/profile"
  ssh ${show_name} "echo '  ulimit -n 65536' >> /etc/profile"
  ssh ${show_name} "echo ' else' >> /etc/profile"
  ssh ${show_name} "echo '  ulimit -u 16384 -n 65536' >> /etc/profile"
  ssh ${show_name} "echo ' fi' >> /etc/profile"
  ssh ${show_name} "echo 'fi' >> /etc/profile"
done


###############################################################
# ssh setting for the oracle & grid users
###############################################################

echo
echo "################################################"
echo " RSFO will now enable ssh for the Oracle user."
echo

read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh ${show_name} cp -R /root/.ssh /home/oracle/.ssh
  ssh ${show_name} chown -R oracle:oinstall /home/oracle/.ssh
  echo "ssh enabled for oracle on ${show_name}"
done 
echo

echo
echo "################################################"
echo " RSFO will now enable ssh for the grid user."
echo

read -r N1 N2 N3 N4 N5 N6 N7 N8 N9 N10 N11 N12 < $file_nname

for ((i=1; i<=node_number; i++))
do
  show_name="N${i}"
  eval show_name=\$$show_name
  ssh ${show_name} cp -R /root/.ssh /home/grid/.ssh
  ssh ${show_name} chown -R grid:oinstall /home/grid/.ssh
  echo "ssh enabled for grid on ${show_name}"
done
echo


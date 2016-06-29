#==============================================================================
#       (c) Copyright 2004 Hewlett-Packard Development Company, L.P.
#    The information contained herein is subject to change without notice.
#==============================================================================
#

HP Rapid Setting For Oracle - RSFO -
====================================
Current version 1.1.2

Object:
--------
RSFO goal is to provide a set of scripts to enable a REDHAT 7 environment for Oracle 12c Single Instance or RAC.
RSFO will set the Oracle pre-requesites except:
- The storage configuration
- The root ssh without password needed for deployement
- The network setting

Restriction:
------------
- Maximum nodes in the cluster: 12.
- These scripts has been designed for RedHat 7.
- Only the RH7 Update 1 is tested with the current build. However, nothing should prevent to use it with any RH7.x release. 
- The ssh as to be set before you run the scripts.
- A YUM repository need to be reachable for the installation of the packages required by Oracle

Installation procedure:
-----------------------
1/ configure the cluster interconnect or the network in case of multiple single instance installation.

2/ configure the ssh for root without password nor passphrase (look at the SSH_setting.txt for more details).

3/ run rsfo_run1_os7up.sh (previously OS7.sh)

4/ run rsfo_run2_cruser.sh

5/ configure manually the shared storage

Silent installation:
--------------------
In order to perform an installation without user interaction, you need, before starting the procedure to setup the configuration files as describe below:
1/ Copy the rsfoparam.txt & the nod_list.txt files in /tmp/scripts/

2/ update the nod_list.txt by adding the list of nodes where rsfo will run. Include the nodes name reachable by ssh without password.

3/ Update the rsfoparam.txt with the accurate parameters.

Uninstallation of RSFO:
-----------------------
1/ Run rollback_rsfo.sh first in order to remove all the updates made by RSFO. The Oracle and Grid users will be removed or not based on your choice.

2/ run rpm -e rsfo-xxxx in order to remove the package

Scripts:
--------

1/ rsfo_run2_cruser.sh: This script is cluster aware. It will create the oracle user, the oinstall group and the dba group on all cluster nodes with id equivalence. It will set the rsh and the ssh, the variable environment in .bash_profile and the directory structure based on the ORACLE_BASE provided by the administrator. 

2/ rsfo_run1_os7up.sh: Perform the kernel parameter setting, the packages installation if necessary, set the limits, change the compilor release. 

3/ rollback_rsfo.sh: Script to use if you want to remove the work done by the "rsfo_run1_os7up.sh" and the "rsfo_run2_cruser.sh" scripts. This file is not yest validated. 

4/ ora_profile: Template for the .bash_profile of the Oracle user.

5/ grid_profile: Template for the .bash_profile of the Grid user.


Contacts:
---------
Send your questions or comments to yann.allandit@hpe.com. 

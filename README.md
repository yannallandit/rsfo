# rsfo
======

Rapid Setting For Oracle (RAC)
------------------------------

### How to use RSFO

1. Download the latest rpm from the Github page https://github.com/yannallandit/rsfo 
2. Install the rpm: yum install –y rsfo-1.0.8-1.el7.noarch.rpm
3. Go to the location directory: # cd /opt/hpe/rsfo/
4. Run the first script: # ./rsfo_run1_os7up.sh
	* Provides the list of nodes where Oracle will be installed
5. Run the second scripts: # ./rsfo_run2_cruser.sh
	* Confirm the targeted nodes
	* Provide the location of the Grid and the Oracle BASE location

More information in the RSFO_introduction.pdf document.

### New in version 1.1.2
- The "Remove RSFO" script was updated. It is fully functionnal & clusterware now.
- Add Oracle firewalld rules (instead of firewall disablement).
- Fix oraInventory issue
- rpm -e update

### New in version 1.1.1
- Add Oracle Inventory location
- Update $O and $OH location for the GRID user
- Update the rpm list
- Change the shm and hugepages parameters setting

### New in version 1.1.0
- Silent installation mode
- Look at the /opt/hpe/rsfo/README.txt for implementation detail
- Bug fixes with THP and hugepages setting

### New in version 1.0.9
- pam.d management for Oracle and Grid
- /etc/profile update for Oracle and Grid
- hugepages setup
- transparent hugepages disabled
- change order in answering $H question

### New in version 1.0.8

- A default password defined for oracle and grid users

### New in version 1.0.7

- Support of Red Hat EL 6.x
- Smart shm kernel parameters setting
- ssh for the grid user
- A Video tutorial shows the entire process


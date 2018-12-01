![alt tag](https://github.com/yannallandit/rsfo/blob/master/Logo2Medium.jpg)
======

Rapid Setting For Oracle (RAC)
------------------------------

### How to use RSFO

1. Download the latest rpm from the Github page https://github.com/yannallandit/rsfo/releases 
2. Install the rpm: yum install –y rsfo-1.1.7-8.el7.noarch.rpm
3. Go to the location directory: # cd /opt/hpe/rsfo/
4. Run the first script: # ./rsfo_run1_os7up.sh
	* Provides the list of nodes where Oracle will be installed
5. Run the second scripts: # ./rsfo_run2_cruser.sh
	* Confirm the targeted nodes
	* Provide the location of the Grid and the Oracle BASE location

More information in the RSFO_introduction.pdf document.

### New in version 1.1.7
- Version validated with Oracle 18c RAC
- Add smartmontools package
- Change firewall setting
- Check availability of the server-option-rpms yum repo
- Stop and disable avahi-daemon
- Set no zero config network
- Change value for GRID $OH
- Reduce hugepages from 70 to 60% of the RAM
- Fix sched_wakeup parameter typo and add vm.min_free_kbytes in sysctl.conf
- Add RemoveIPC=no in /etc/systemd/logind.conf

### New in version 1.1.6
- Change the kernel semaphores setting in order to match scale up server requirements
- Fix sched_wakeup_granularity_ns typo

### New in version 1.1.5
- Fix a silent installation issue (occurs only with the Ansible playbook version)

### New in version 1.1.4
- Add numa balancing support
- Add transparent_huepages=none in boot parameters using grubby
- Change source plan for oracle-rsfo tuned profile

### New in version 1.1.3
- Updated tuned-adm profile
- Updated information messages broadcast

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

[![GitHub Download Count](https://img.shields.io/github/downloads/yannallandit/rsfo/total.svg)]() 

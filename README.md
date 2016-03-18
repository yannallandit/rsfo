# rsfo
======

Rapid Setting For Oracle (RAC)
------------------------------

### How to use RSFO

1. Download the latest rpm from the Github page https://github.com/yannallandit/rsfo 
2. Install the rpm: yum install –y rsfo-1.0.6-2.el7.noarch.rpm
3. Go to the location directory: # cd /opt/hpe/rsfo/
4. Run the first script: # ./rsfo_run1_os7up.sh
	* Provides the list of nodes where Oracle will be installed
5. Run the second scripts: # ./rsfo_run2_cruser.sh
	* Confirm the targeted nodes
	* Provide the location of the Grid and the Oracle BASE location

More information in the RSFO_introduction.pdf document.

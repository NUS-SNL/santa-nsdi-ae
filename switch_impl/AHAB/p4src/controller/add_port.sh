#!/bin/bash

curr='/home/cirlab/archit/santa/switch_impl/AHAB/p4src/controller'

# Add Ports using bfrt_python
# must run run_bfshell at the directory itself
cd $SDE # go to the directory
./run_bfshell.sh -b $curr/bf_port.py

# Set default settings based on scripts
cd $curr
./default_settings.sh

# Add Table Entries to for the Match Action Table.
# -u is for UDP and -t is for TCP. 
# Port is ternary: port_num &&& port_mask -> port_mask = 0 to match any ports
# -v is vlink_id or commonly known as dev_port in tofino switches. 

# ./add_vlink_rules.py -i '10.1.1.1/32' -v 25 -u '7575&&&0' -w 0
# ./add_vlink_rules.py -i '10.1.1.2/32' -v 24 -u '7575&&&0' -w 0
./add_vlink_rules.py -i '10.1.1.1/32' -v 25 -t '7575&&&0' -w 0
./add_vlink_rules.py -i '10.1.1.2/32' -v 24 -t '7575&&&0' -w 0

# Since ping is neither TCP nor UDP (ICMP), we will need to add a special entry for it.
./add_vlink_rules.py -i '10.1.1.1/32' -v 25 -w 0
./add_vlink_rules.py -i '10.1.1.2/32' -v 24 -w 0 
# 24 is the egress port

# Write to Register allows you to hardcode a value to the Register.
# In this case we want to change the threshold of a certain vlink so we can use this.
# Because the default is -n stored_thresholds which is the register we want, we do not have
# to incldue that flag.
# 10Mbits = 2000 
# ./write_to_register.py -v 6000 -i 164 -j 166

# Guranteed Flow write to register
# 1 = guranteed, 0 = normal flow

# Run Script to fix the Queue Size and Processing Rate
# python3 /home/cirlab/archit/santa/switch_impl/basic_impl/control_plane/setup_scripts/set_rate_ahab.py
cd $SDE
./run_pd_rpc.py /home/cirlab/archit/santa/switch_impl/basic_impl/control_plane/setup_scripts/set_rate_ahab.py
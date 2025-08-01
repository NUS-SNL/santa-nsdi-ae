#!/bin/bash
# source set_pythonpath.sh
./add_mirror_session.py
./update_capacities.py -f 3220
# ./update_capacities.py -c 6450 -v -O '24,25' -o
# 6450 for 100 Mbps
./add_lpf_rules.py -d 4e6 -s 3 -n rate_estimator
./add_lpf_rules.py -d 16e6 -s 5 -n link_rate_tracker
./add_delta_rules.py -d 4

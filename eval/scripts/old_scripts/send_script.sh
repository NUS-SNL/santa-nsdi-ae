#!/bin/bash

# TCP flows
iperf -c 10.1.1.2 -p 5000 -Z cubic -t 200 &
iperf -c 10.1.1.2 -p 6000 -Z bbr -t 200 &
iperf -c 10.1.1.2 -p 7000 -Z reno -t 200 &
iperf -c 10.1.1.2 -p 8000 -Z vegas -t 200 &

# # UDP flows with reduced bandwidth
# iperf -c 10.1.1.2 -u -p 7000 -b 10M -t 100 &
# iperf -c 10.1.1.2 -u -p 8000 -b 10M -t 100 &

# Wait for all background processes to finish
wait
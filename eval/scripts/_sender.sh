#!/bin/bash
cca="$1"
port="$2"
c_port="$3"

# ip a
iperf -c 10.1.1.2 -t 60 -B 10.1.1.1:$c_port -p $port -Z $cca

wait
#!/bin/bash

trap 'cleanup' INT TERM EXIT

cleanup() {
    echo "Received interrupt signal. Cleaning up..."
    sudo pkill -9 iperf
    sudo pkill -9 tcpdump
    echo "Finished cleaning up"
    exit
}

disable_tso_gro() {
    echo "Disabling TSO and GRO"
    sudo ip netns exec send sudo ethtool -K ens2f0 tso off gro off
    sudo ip netns exec recv sudo ethtool -K ens2f1 tso off gro off
}

disable_tso_gro

initial_port=5000
client_increment=5
num_clients=5
max_port=$((initial_port + num_clients))

while true; do
    echo "Starting $num_clients clients and servers..."
    for (( port=$initial_port; port<$max_port; port++ )); do
        sudo ip netns exec recv iperf -s -p $port >/dev/null 2>&1 &
        sudo ip netns exec send iperf -c 10.0.0.2 -p $port -t 3 >/dev/null 2>&1 &
    done

    sleep 3
    echo "Stopping current test..."
    sudo pkill -f "iperf -s"
    sudo pkill -f "iperf -c"

    num_clients=$((num_clients + client_increment))
    max_port=$((initial_port + num_clients))

    echo "Increasing number of clients/servers to $num_clients..."
done

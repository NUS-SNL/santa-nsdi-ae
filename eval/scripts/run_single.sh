#!/bin/bash

trap 'cleanup' INT TERM EXIT

cleanup() {
    echo "Received interrupt signal. Cleaning up..."
    sudo pkill -9 iperf
    sudo pkill --signal SIGINT tcpdump
    sleep 1
    sudo pkill -9 tcpdump

    wait
    echo "Finished running flows"
    # exit
}

disable_tso_gro() {
    echo "Disabling TSO and GRO"
    sudo ip netns exec send sudo ethtool -K ens2f0 tso off
    sudo ip netns exec send sudo ethtool -K ens2f0 gro off
    sudo ip netns exec recv sudo ethtool -K ens2f1 tso off
    sudo ip netns exec recv sudo ethtool -K ens2f1 gro off
    sudo ethtool -K ens1f0 tso off
    sudo ethtool -K ens1f0 gro off
}

launch_single_flow() {
    cca="$1"
    rtt="$2"
    port="$3"
    client_port="$4"
    trial_dir="$5"

    owd=$(($rtt / 2))

    echo "Launching a single flow for CCA: ${cca} with RTT: ${rtt}ms"
    echo "Results will be stored in: ${trial_dir}"

    mkdir -p "${trial_dir}"

    sudo ip netns exec recv iperf -s -p $port -i 10 &
    sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port -w ${trial_dir}/recv_${cca}_${rtt}ms_flow.pcap &
    sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port -w ${trial_dir}/send_${cca}_${rtt}ms_flow.pcap &

    sudo ip netns exec send su --command="mm-delay $owd sudo ip netns exec send ./_sender.sh $cca $port $client_port" $USER &
    sleep 0.01
}

sudo sysctl net.ipv4.tcp_timestamps=0

disable_tso_gro

# List of CCAs to test
ccas=("cubic" "bbr" "vegas")

# Base port numbers
base_port=5000
base_client_port=10000
rtt=20

# Run experiments for each CCA
for cca in "${ccas[@]}"; do
    dir_name="pcap_single_codel_${cca}"
    trial_dir="$HOME/eval/${dir_name}"

    echo "Starting single-flow experiment for ${cca}"
    sudo tcpdump -i ens1f0 tcp -w ${trial_dir}/total_drop.pcap &
    launch_single_flow ${cca} ${rtt} ${base_port} ${base_client_port} ${trial_dir}
    sleep 100
    cleanup
done

cleanup
exit
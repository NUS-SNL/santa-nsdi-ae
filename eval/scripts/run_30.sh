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
    exit
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

launch_thirty_flows() {
    cca="$1"
    rtt="$2"
    base_port="$3"
    base_client_port="$4"

    owd=$(($rtt / 2))

    echo "Launching 10 flows for CCA: ${cca} with RTT: ${rtt}ms"

    for i in {0..29}; do
        port=$(($base_port + $i))
        client_port=$(($base_client_port + $i))

        sudo ip netns exec recv iperf -s -p $port -i 10 &
        sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port -w ~/eval/pcap_90_flow_santa_6q_2/recv_${cca}_${rtt}ms_flow${i}.pcap &
        # capturing on the sender side for packets going to the receiver ports
        sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port -w ~/eval/pcap_90_flow_santa_6q_2/send_${cca}_${rtt}ms_flow${i}.pcap &

        sudo ip netns exec send su --command="mm-delay $owd sudo ip netns exec send ./_sender.sh $cca $port $client_port" $USER &
        # sleep 0.01
    done
}

mkdir -p ~/eval/pcap_90_flow_santa_6q_2
sudo sysctl net.ipv4.tcp_timestamps=0

disable_tso_gro
sudo tcpdump -i ens1f0 tcp -w ~/eval/pcap_90_flow_santa_6q_2/total_drop.pcap &

launch_thirty_flows cubic 20 5000 10000
launch_thirty_flows bbr 20 6000 11000
launch_thirty_flows vegas 20 7000 12000

sleep 100
cleanup

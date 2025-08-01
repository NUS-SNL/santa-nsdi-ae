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

launch_three_flows() {
    cca="$1"
    rtt="$2"
    base_port="$3"
    base_client_port="$4"

    owd=$(($rtt / 2))

    echo "Launching 2 flows for CCA: ${cca} with RTT: ${rtt}ms"

    for i in {0..2}; do
        port=$(($base_port + $i))
        client_port=$(($base_client_port + $i))

        sudo ip netns exec recv iperf -s -p $port -i 10 &
        sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port -w ~/eval/pcap_18_flow_santa_stagger_2s/recv_${cca}_${rtt}ms_flow${i}.pcap &
        # capturing on the sender side for packets going to the receiver ports
        sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port -w ~/eval/pcap_18_flow_santa_stagger_2s/send_${cca}_${rtt}ms_flow${i}.pcap &

        sudo ip netns exec send su --command="mm-delay $owd sudo ip netns exec send ./_sender.sh $cca $port $client_port" $USER &
        # sleep 0.01
    done
}

launch_three_flows_stagger() {
    cca="$1"
    rtt="$2"
    base_port="$3"
    base_client_port="$4"

    owd=$(($rtt / 2))

    echo "Launching 2 flows for CCA: ${cca} with RTT: ${rtt}ms"

    for i in {0..2}; do
        port=$(($base_port + $i))
        client_port=$(($base_client_port + $i))

        sudo ip netns exec recv iperf -s -p $port -i 10 &
        sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port -w ~/eval/pcap_18_flow_santa_stagger_2s/recv_${cca}_${rtt}ms_flow_stagger_${i}.pcap &
        # capturing on the sender side for packets going to the receiver ports
        sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port -w ~/eval/pcap_18_flow_santa_stagger_2s/send_${cca}_${rtt}ms_flow_stagger_${i}.pcap &

        sudo ip netns exec send su --command="mm-delay $owd sudo ip netns exec send ./_sender.sh $cca $port $client_port" $USER &
        # sleep 0.01
    done
}

mkdir -p ~/eval/pcap_18_flow_santa_stagger_2s
sudo sysctl net.ipv4.tcp_timestamps=0

disable_tso_gro
sudo tcpdump -i ens1f0 tcp -w ~/eval/pcap_18_flow_santa_stagger_2s/total_drop.pcap &

launch_three_flows vegas 20 7000 12000
launch_three_flows bbr 20 6000 11000
launch_three_flows cubic 20 5000 10000
sleep 22
launch_three_flows_stagger cubic 20 5500 10500
sleep 20
launch_three_flows_stagger bbr 20 6500 11500
sleep 20
launch_three_flows_stagger vegas 20 7500 12500
sleep 20
cleanup

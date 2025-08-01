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
    sudo sysctl net.ipv4.tcp_timestamps=0
}

launch_three_flows() {
    cca="$1"
    rtt="$2"
    base_port="$3"
    base_client_port="$4"
    trial="$5"
    trial_dir="$HOME/eval/pcap_9_flow_fq_1bdp_${trial}"

    owd=$(($rtt / 2))

    echo "Launching 3 flows for CCA: ${cca} with RTT: ${rtt}ms (Trial ${trial})"

    for i in {0..2}; do
        port=$(($base_port + $i))
        client_port=$(($base_client_port + $i))

        sudo ip netns exec recv iperf -s -p $port -i 10 &
        sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port -w ${trial_dir}/recv_${cca}_${rtt}ms_flow${i}.pcap &
        sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port -w ${trial_dir}/send_${cca}_${rtt}ms_flow${i}.pcap &

        sudo ip netns exec send su --command="mm-delay $owd sudo ip netns exec send ./_sender.sh $cca $port $client_port" $USER &
        sleep 0.01
    done
}

run_trials() {
    trials=(1 2 3)
    cca_orders=(
        "bbr vegas cubic"
        "vegas cubic bbr"
        "cubic bbr vegas"
    )

    for trial in "${trials[@]}"; do
        trial_dir="$HOME/eval/pcap_9_flow_fq_1bdp_${trial}"
        mkdir -p ${trial_dir}
        disable_tso_gro
        sudo tcpdump -i ens1f0 tcp -w ${trial_dir}/total_drop.pcap &

        cca_order=(${cca_orders[$((trial - 1))]})
        launch_three_flows ${cca_order[0]} 20 6000 11000 ${trial}
        launch_three_flows ${cca_order[1]} 20 7000 12000 ${trial}
        launch_three_flows ${cca_order[2]} 20 5000 10000 ${trial}

        sleep 100
        cleanup
        # sleep 5
    done
}

run_trials

cleanup
exit

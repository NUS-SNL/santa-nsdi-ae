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

launch_pairwise_flows() {
    cca1="$1"
    cca2="$2"
    rtt="$3"
    base_port="$4"
    base_client_port="$5"
    trial_dir="$6"

    owd=$(($rtt / 2))

    echo "Launching pairwise flows for CCAs: ${cca1} and ${cca2} with RTT: ${rtt}ms"

    # Flow 1 (CCA1)
    port1=$base_port
    client_port1=$base_client_port
    sudo ip netns exec recv iperf -s -p $port1 -i 10 &
    sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port1 -w ${trial_dir}/recv_${cca1}_${rtt}ms_flow.pcap &
    sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port1 -w ${trial_dir}/send_${cca1}_${rtt}ms_flow.pcap &
    sudo ip netns exec send su --command="mm-delay $owd sudo ip netns exec send ./_sender.sh $cca1 $port1 $client_port1" $USER &

    sleep 0.01
    # Flow 2 (CCA2)
    port2=$(($base_port + 1))
    client_port2=$(($base_client_port + 1))
    sudo ip netns exec recv iperf -s -p $port2 -i 10 &
    sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port2 -w ${trial_dir}/recv_${cca2}_${rtt}ms_flow.pcap &
    sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port2 -w ${trial_dir}/send_${cca2}_${rtt}ms_flow.pcap &
    sudo ip netns exec send su --command="mm-delay $owd sudo ip netns exec send ./_sender.sh $cca2 $port2 $client_port2" $USER &

}

sudo sysctl net.ipv4.tcp_timestamps=0

disable_tso_gro

# Define pairwise combinations of CCAs
pairs=(
    # "cubic bbr"
    # "cubic vegas"
    "bbr vegas"
)

for pair in "${pairs[@]}"; do
    IFS=" " read -r cca1 cca2 <<< "$pair"
    dir_name="pcap_2_flow_sfq_${cca1}_${cca2}"
    trial_dir="$HOME/eval/${dir_name}"
    mkdir -p ${trial_dir}

    echo "Starting pairwise run for ${cca1} and ${cca2}, storing in ${dir_name}"

    sudo tcpdump -i ens1f0 tcp -w ${trial_dir}/total_drop.pcap &
    launch_pairwise_flows ${cca1} ${cca2} 20 5000 10000 ${trial_dir}
    sleep 60
    cleanup
done

cleanup
exit
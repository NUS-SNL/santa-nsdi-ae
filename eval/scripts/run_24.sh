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

launch_eight_flows() {
    cca="$1"
    rtt="$2"
    base_port="$3"
    base_client_port="$4"

    owd=$(($rtt / 2))

    echo "Launching 10 flows for CCA: ${cca} with RTT: ${rtt}ms"

    for i in {0..7}; do
        port=$(($base_port + $i))
        client_port=$(($base_client_port + $i))

        sudo ip netns exec recv iperf -s -p $port -i 10 &
        sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port -w ~/eval/pcap_24_flow_santa/recv_${cca}_${rtt}ms_flow${i}.pcap &
        # capturing on the sender side for packets going to the receiver ports
        sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port -w ~/eval/pcap_24_flow_santa/send_${cca}_${rtt}ms_flow${i}.pcap &

        sudo ip netns exec send su --command="mm-delay $owd sudo ip netns exec send ./_sender.sh $cca $port $client_port" $USER &
        # sleep 0.01
    done
}

mkdir -p ~/eval/pcap_24_flow_santa
sudo sysctl net.ipv4.tcp_timestamps=0

disable_tso_gro
sudo tcpdump -i ens1f0 tcp -w ~/eval/pcap_24_flow_santa/total_drop.pcap &

launch_eight_flows cubic 20 5000 10000
launch_eight_flows bbr 20 6000 11000
launch_eight_flows vegas 20 7000 12000


sleep 100
cleanup

# #!/bin/bash

# trap 'cleanup' INT TERM EXIT

# cleanup() {
#     echo "Received interrupt signal. Cleaning up..."
#     sudo pkill -9 iperf
#     sudo pkill --signal SIGINT tcpdump
#     sleep 1
#     sudo pkill -9 tcpdump

#     wait
#     echo "Finished running flows"
#     exit
# }

# disable_tso_gro() {
#     echo "Disabling TSO and GRO"
#     sudo ip netns exec send sudo ethtool -K ens2f0 tso off
#     sudo ip netns exec send sudo ethtool -K ens2f0 gro off
#     sudo ip netns exec recv sudo ethtool -K ens2f1 tso off
#     sudo ip netns exec recv sudo ethtool -K ens2f1 gro off
#     sudo ethtool -K ens1f0 tso off
#     sudo ethtool -K ens1f0 gro off
# }

# single_flow() {
#     cca="$1"
#     rtt="$2"
#     port="$3"

#     owd=$(($rtt / 2))

#     echo "Running - RTT: ${rtt}ms CCA: ${cca}"

#     sudo ip netns exec recv iperf -s -p $port &

#     sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port -w recv_${cca}_${rtt}ms.pcap &

#     # sleep 1
    
#     sudo ip netns exec send su --command="mm-delay $owd ./_sender.sh $cca $port" $USER &
# }

# double_flow() {
#     cca="$1"
#     rtt_1="$2"
#     rtt_2="$3"
#     port_1="$4"
#     port_2="$5"
#     c_port_1="$6"
#     c_port_2="$7"

#     owd_1=$(($rtt_1 / 2))
#     owd_2=$(($rtt_2 / 2))

#     echo "Running - RTT: ${rtt}ms CCA: ${cca}"

#     sudo ip netns exec recv iperf -s -p $port_1 -i 10 &
#     sudo ip netns exec recv iperf -s -p $port_2 -i 10 &

#     sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port_1 -w ~/eval/pcap_6_flow/recv_${cca}_1_${rtt_1}ms.pcap &
#     sudo ip netns exec recv tcpdump -i ens2f1 tcp and dst port $port_2 -w ~/eval/pcap_6_flow/recv_${cca}_2_${rtt_2}ms.pcap &
    
#     # capturing on the sender side for packets going to the receiver ports
#     sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port_1 -w ~/eval/pcap_6_flow/send_${cca}_1_${rtt_1}ms.pcap &
#     sudo ip netns exec send tcpdump -i ens2f0 tcp and dst port $port_2 -w ~/eval/pcap_6_flow/send_${cca}_2_${rtt_2}ms.pcap &
    
#     sudo ip netns exec send su --command="mm-delay $owd_1 sudo ip netns exec send ./_sender.sh $cca $port_1 $c_port_1" $USER &
#     sleep 0.01
#     sudo ip netns exec send su --command="mm-delay $owd_2 sudo ip netns exec send ./_sender.sh $cca $port_2 $c_port_2" $USER &
# }

# mkdir -p ~/eval/pcap_24_flow

# disable_tso_gro
# # here the traffic flows from port 10000 (at client) to port 5000 (at server)
# sudo tcpdump -i ens1f0 tcp -w ~/eval/pcap_24_flow/total_drop.pcap &

# double_flow cubic 40 80 5000 5001 10000 10001
# sleep 0.01
# double_flow bbr 40 80 6000 6001 11000 11001
# sleep 0.01
# # double_flow reno 40 80 7000 7001 12000 12001
# # sleep 0.01
# double_flow vegas 40 80 8000 8001 13000 13001


# sleep 100
# cleanup

# # wait
# # echo "Finished running flows"
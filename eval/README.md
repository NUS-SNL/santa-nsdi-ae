# Server setup 
We connect a server to 2 ports in the switch (sending traffic into one switch port and receving it back from another), and another for reconrding the packet drops. 

## Configuring the interfaces
1) 2 namespaces -- send (ens2f0- 10.1.1.1/24) & recv (ens2f1- 10.1.1.2/24), we use another interface (ensf10) for recording the dropped packets (forwarded from the switch), and also disable GSO & TRO (currently these are done in the running scripts themselves)
    ```
    sudo ifconfig ens1f0 up
    sudo ifconfig ens1f1 up
    sudo ifconfig ens2f0 up
    sudo ifconfig ens2f1 up
    sudo ip netns add send
    sudo ip netns add recv
    sudo ip link set ens2f0 netns send
    sudo ip link set ens2f1 netns recv
    netnsctl switch send
    sudo ifconfig ens2f0 10.1.1.1/24
    exit
    netnsctl switch recv
    sudo ifconfig ens2f1 10.1.1.2/24
    exit
    ```

2) Disable tcp options--
    sudo sysctl net.ipv4.tcp_timestamps=0

## Running
The script - ./run.sh (or other variants), both launches the flows using iperf and also sets up the tcpdump, for changing RTTs configure the owd (one-way delay) parameter, can further setup scatter flows using sleep betwen each launch and can also modify the order of launching specific CCAs. We also record the dropped packets (using deflect_on_drop at the switch) using a third port.

## Converting into plotting metadata-
We use the tcp_options field to store metadata like the queue taken and the queue depths and further parse it using pcapplusplus. We further combine the information about the dropped packets corresponding to each flow to evaluate the loss rates.

Depending on the path for pcap setup the names in run_pcap_tput.sh list to convert the pcaps to the required throughput and loss rate metrics.
./run_pcap_tput.sh


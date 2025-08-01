#!/bin/bash

# Base directory where PCAP files are stored
base_dir=~/eval

# List of directories to process
directories=(
    "pcap_9_flow_santa_1bdp_5q_1"
    "pcap_9_flow_santa_1bdp_5q_2"
    "pcap_9_flow_santa_1bdp_5q_3"
    # "pcap_9_flow_fifo_1bdp_1"
    # "pcap_9_flow_fifo_1bdp_2"
    # "pcap_9_flow_fifo_1bdp_3"
    # "pcap_9_flow_santa_1bdp_1"
    # "pcap_9_flow_santa_1bdp_2"
    # "pcap_9_flow_santa_1bdp_3"
    # "pcap_9_flow_santa_1bdp_4q_1"
    # "pcap_9_flow_santa_1bdp_4q_2"
    # "pcap_9_flow_santa_1bdp_4q_3"
    # "pcap_9_flow_fq_1bdp_1"
    # "pcap_9_flow_fq_1bdp_2"
    # "pcap_9_flow_fq_1bdp_3"
    # "pcap_9_flow_sfq"
    # "pcap_18_flow_santa_stagger"
    # "pcap_18_flow_santa_stagger_5s"
    # "pcap_18_flow_santa_stagger_2s"
    # "pcap_2_flow_sfq_bbr_vegas"
    # "pcap_single_sfq_bbr"
    # "pcap_single_sfq_cubic"
    # "pcap_single_sfq_vegas"
)

# Path to the pcap_to_tput.sh script
pcap_to_tput_script="./pcap_to_tput.sh"

# Check if the script exists and is executable
if [[ ! -x $pcap_to_tput_script ]]; then
    echo "Error: $pcap_to_tput_script does not exist or is not executable."
    exit 1
fi

# Iterate over directories and call pcap_to_tput.sh for each
for dir in "${directories[@]}"; do
    pcap_dir="${base_dir}/${dir}"
    
    if [[ -d $pcap_dir ]]; then
        echo "Processing directory: $pcap_dir"
        $pcap_to_tput_script "$dir" "$pcap_dir"
    else
        echo "Warning: Directory $pcap_dir does not exist. Skipping."
    fi
done

echo "All directories processed."
#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: ./$0 <config_name> <pcap_directory_path>"
    exit 1
fi

config_name=$1
directory_path=$2

# Ensure the base directory for conversions exists
output_base_dir="$HOME/eval/$config_name/convert_new"
mkdir -p "$output_base_dir"

# total_drop_output="$HOME/eval/convert_new/total_drop.txt"

# Process total_drop.pcap separately
total_drop_pcap="$directory_path/total_drop.pcap"
if [ -f "$total_drop_pcap" ]; then
    total_drop_output="$output_base_dir/total_drop.txt"
    echo "frame.time_epoch    ip.src    ip.dst    ip.proto    srcport    dstport    frame.len   tcp.seq_raw " > "$total_drop_output"
    tshark -r "$total_drop_pcap" -T fields -e frame.time_epoch -e ip.src -e ip.dst -e ip.proto -e tcp.srcport -e tcp.dstport -e frame.len -e tcp.seq_raw | awk 'BEGIN {OFS="\t"} {print $1, $2, $3, $4, $5, $6, $7, $8}' >> "$total_drop_output"
    echo "Conversion completed for $total_drop_pcap. Output saved to $total_drop_output"
fi

for pcap_file in "$directory_path"/recv*.pcap; do
    if [ -f "$pcap_file" ]; then
        base_output_file="$output_base_dir/$(basename "${pcap_file%.*}")"
        output_file="${base_output_file}.txt"
        santa_output_file="${base_output_file}_santa.txt"  # File for Santa header fields

        echo "frame.time_epoch    ip.src    ip.dst    ip.proto    srcport    dstport    frame.len   tcp.seq_raw " > "$output_file"

        tshark -r "$pcap_file" -T fields -e frame.time_epoch -e ip.src -e ip.dst -e ip.proto -e tcp.srcport -e tcp.dstport -e frame.len -e tcp.seq_raw | awk 'BEGIN {OFS="\t"} {print $1, $2, $3, $4, $5, $6, $7, $8}' >> "$output_file"

        # # Call the C++ executable to parse the Santa header and save to a separate file
        # ./parseSantaHeader "$pcap_file" "$santa_output_file"
        # # Merge the original output file with the Santa header fields
        # paste "$output_file" "$santa_output_file" > "${base_output_file}_merged.txt"

        # rm -rf "$santa_output_file"
        # echo "Conversion completed for $pcap_file. Output saved to ${base_output_file}_merged.txt"

        # for computing the throughput
        # python3 eval_tput_single.py "${base_output_file}_merged.txt" "$HOME/eval/$config_name" &
    fi
done

# Process sender PCAPs
for pcap_file in "$directory_path"/send*.pcap; do
    if [ -f "$pcap_file" ]; then
        base_output_file="$output_base_dir/$(basename "${pcap_file%.*}")"
        send_output_file="${base_output_file}.txt"

        echo "frame.time_epoch    ip.src    ip.dst    ip.proto    srcport    dstport    frame.len   tcp.seq_raw " > "$send_output_file"

        # Use frame.time_epoch for consistent timestamps
        
        tshark -r "$pcap_file" -T fields -e frame.time_epoch -e ip.src -e ip.dst -e ip.proto -e tcp.srcport -e tcp.dstport -e frame.len -e tcp.seq_raw | awk 'BEGIN {OFS="\t"} {print $1, $2, $3, $4, $5, $6, $7, $8}' >> "$send_output_file"

        echo "Conversion completed for $pcap_file. Output saved to $send_output_file"

        echo $send_output_file
        # Find the corresponding receiver file
        recv_file="${send_output_file//send_/recv_}"

        if [ -f "$recv_file" ]; then
            python3 eval_metrics.py "$send_output_file" "$recv_file" "$total_drop_output" "$HOME/eval/$config_name" &
        else
            echo "Corresponding receiver file not found for $send_output_file"
        fi

        # if [ -f "$recv_file" ]; then
        #     # Calculate Bytes in Flight
        #     bif_output_file="${send_output_file//send_/bif_}"
        #     python3 calculate_bif.py "$send_output_file" "$recv_file" "$total_drop_output" "$bif_output_file"&
        #     echo "BIF calculation completed for $pcap_file. Output saved to $bif_output_file"
        # else
        #     echo "Corresponding receiver file not found for BIF calculation."
        # fi
    fi
done

wait

# rm $HOME/eval/q_log.txt
# scp cirlab@tf1c:/home/cirlab/archit/santa/switch_impl/basic_impl/control_plane/q_log.txt $HOME/eval/

echo "All conversions finished."

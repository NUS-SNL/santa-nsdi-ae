from binascii import crc32
import time
import os
import glob
import csv
import pandas as pd
import matplotlib.pyplot as plt

def calculate_crc32(source_ip, dest_ip, ip_protocol, src_port, dest_port):
    """Calculates the CRC32 hash for a given set of network parameters."""

    # Convert IP addresses to byte arrays
    source_ip_bytes = [int(byte) for byte in source_ip.split(".")]
    dest_ip_bytes = [int(byte) for byte in dest_ip.split(".")]

    # Combine all parameters into a single byte array
    data = bytearray()
    data.extend(source_ip_bytes)
    data.extend(dest_ip_bytes)
    data.extend(ip_protocol.to_bytes(1, byteorder="big"))
    data.extend(src_port.to_bytes(2, byteorder="big"))
    data.extend(dest_port.to_bytes(2, byteorder="big"))

    # Calculate the CRC32 hash
    crc_hash = crc32(data) & 0xFFFFFFFF
    # Convert the hash value to a hexadecimal string
    hex_hash = hex(crc_hash)[2:]
    # Pad the hash with leading zeros if necessary
    hex_hash = hex_hash.zfill(8)
    return crc_hash

def plot_throughput_vs_time(csv_directory, crc_hashes, queue_info):
    print(csv_directory)
    ccas = ['bbr_1_40ms', 'bbr_2_80ms', 'cubic_1_40ms', 'cubic_2_80ms', 'reno_1_40ms', 'reno_2_80ms', 'vegas_1_40ms', 'vegas_2_80ms']
    # ccas = ['bbr_1_40ms', 'bbr_2_80ms', 'cubic_1_40ms', 'cubic_2_80ms']
    num_subplots = len(ccas)
    fig, axs = plt.subplots(num_subplots, 1, figsize=(10, 3 * num_subplots), sharex=True)

    # custom_colors = ['red', 'blue', 'orange', 'purple']
    custom_colors = ['red', 'blue']

    # Create a centralized legend for queue numbers
    # Create a centralized legend for queue numbers
    fig.legend(handles=[plt.Line2D([0], [0], color=c, label=f'Queue {i + 1}') for i, c in enumerate(custom_colors)], loc='lower center', ncol=4)

    for i, cca in enumerate(ccas):
        crc_hash = crc_hashes[cca]  # Get the CRC-32 hash for the CCA
        queue_changes = queue_info[crc_hash]  # Get queue changes for the flow


        files = glob.glob(os.path.join(csv_directory, f'recv_{cca}_tput_20ms_10ms*.csv'))
        # files = glob.glob(os.path.join(csv_directory, f'recv_{cca}_tput_10ms_5ms*.csv'))
        files.sort()
        times = []
        throughputs = []
        prev_queue = None

        for csv_file in files:  # Process in chunks for efficiency
            print(csv_file)
            df = pd.read_csv(csv_file)
            times.extend(df['Time'].tolist())
            throughputs.extend(df[' Throughput'].tolist())

            # Convert throughput to Mbps outside the loop
        throughputs = [t / 1e6 for t in throughputs]

        # Assign colors and line styles based on queue changes
        for j, time_val in enumerate(times):
            queue_num = 0  # Default queue
            for round_time, queue in queue_changes:
                if time_val <= round_time:
                    queue_num = queue
                    break

            # Update line style and color based on queue changes
            if queue_num != prev_queue:
                prev_queue = queue_num
                color = custom_colors[queue_num]
                # line_style = line_styles[queue_num % len(line_styles)]
                axs[i].plot(times[j:], throughputs[j:], color=color, label=f'Throughput (Mbps) - {cca} - Queue {queue_num}')
                
        axs[i].set_ylabel(f'Throughput (Mbps) - {cca}')
        axs[i].set_xlim(0, 80)  # Set x-axis limits
        axs[i].set_ylim(0, 200)  # Set y-axis limits
        axs[i].grid(True)

    plt.xlabel('Time(s)')
    plt.suptitle('Throughput vs Time for Different CCAs', y=0.99)
    plt.tight_layout()  # Add tight layout
    plt.savefig("combined_plot.pdf")

# ... (CRC-32 hash generation code) ...
cca_configs = [
   ("cubic_1_40ms", 5000, 10000),
   ("cubic_2_80ms", 5001, 10001),
   ("bbr_1_40ms", 6000, 11000),
   ("bbr_2_80ms", 6001, 11001),
   ("reno_1_40ms", 7000, 12000),
   ("reno_2_80ms", 7001, 12001),
   ("vegas_1_40ms", 8000, 13000),
   ("vegas_2_80ms", 8001, 13001),
]
source_ip = "10.1.1.1"
dest_ip = "10.1.1.2"
crc_hashes = {}
for cca_name, dst_port, src_port in cca_configs:
    crc_hash = calculate_crc32(source_ip, dest_ip, 6, src_port, dst_port)
    crc_hashes[cca_name] = crc_hash

# Print the stored CRC-32 hashes
print("\nCRC-32 hashes:")
for cca_name, crc_hash in crc_hashes.items():
    print(f"{cca_name}: {crc_hash}")



# Load queue information from q_log.txt
queue_info = {}
with open("eval/q_log.txt") as f:
    for line in f:
        if line.startswith("Round:"):
            round_time = int(line.split()[1])
            continue
        flow_hash, queue_num = line.split(", ")
        flow_hash = int(flow_hash.strip())
        queue_num = int(queue_num)
        # convert ms to sec
        queue_info.setdefault(flow_hash, []).append((round_time/1000 + 2, queue_num))

# print(queue_info)
# Plot the throughputs with color-coding based on queue information
plot_throughput_vs_time("eval/tput", crc_hashes, queue_info)



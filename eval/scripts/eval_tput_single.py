import sys
import os
import concurrent.futures
from collections import Counter

def read_packets_from_text_file(file_path):
    packets = []
    with open(file_path, 'r') as file:
        next(file)  # Skip the header
        for line in file:
            try:
                fields = line.strip().split('\t')
                timestamp = float(fields[0])
                pkt_len = int(fields[6])
                queue_num = int(fields[7])
                packets.append((timestamp, pkt_len, queue_num))
            except Exception as e:
                # print(f"Error reading line: {e}")
                continue        
    return packets

def process_tput_segment(start_time, end_time, packets, window, stride, output_file_path):
    current_time = start_time
    window_end = current_time + window

    while current_time <= end_time:
        # Filter packets within the current time window and extract queue numbers
        window_packets = [(ts, pkt_len, queue_num) for ts, pkt_len, queue_num in packets if current_time <= ts < window_end]

        if window_packets:
            # Calculate throughput, add 24 bytes of IFG, Preamble, SFD and FCS to the packet as well
            throughput = sum((pkt_len + 24) * 8 for _, pkt_len, _ in window_packets) / window  # in bits/s
            
            # Find the most common queue number in the window
            queue_numbers = [queue_num for _, _, queue_num in window_packets]
            most_common_queue_num, _ = Counter(queue_numbers).most_common(1)[0]

            with open(output_file_path, 'a') as outfile:
                outfile.write(f"{current_time}, {throughput}, {most_common_queue_num}\n")

        current_time += stride
        window_end = current_time + window

def main(file_path, out_path):
    output_directory = os.path.expanduser(f'{out_path}/tput')
    os.makedirs(output_directory, exist_ok=True)
    window = 0.08  # seconds
    stride = 0.02  # seconds
    segment_duration = 100  # seconds

    file_name = os.path.basename(file_path)
    if not file_name.endswith('.txt'):
        print("Error: Please provide a valid .txt file.")
        return

    packets = read_packets_from_text_file(file_path)
    print(f"Processing {file_path}")

    num_segments = int((packets[-1][0] - packets[0][0]) / segment_duration) + 1

    with concurrent.futures.ProcessPoolExecutor(max_workers=num_segments) as executor:
        futures = []
        for i in range(num_segments):
            start_time = packets[0][0] + i * segment_duration
            end_time = start_time + segment_duration
            output_file_name = f"{file_name.split('.')[0]}_tput_{int(window * 1000)}ms_{int(stride * 1000)}ms_{i}.csv"
            output_file_path = os.path.join(output_directory, output_file_name)

            with open(output_file_path, 'w') as output_file:
                output_file.write("Time,Throughput,Queue_Number\n")

            segment_packets = [pkt for pkt in packets if start_time <= pkt[0] < end_time]
            futures.append(executor.submit(process_tput_segment, start_time, end_time, segment_packets, window, stride, output_file_path))

        concurrent.futures.wait(futures)

    print(f"Throughput data saved as {output_file_name} to '{output_directory}' directory for {file_name}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <file_path> <out_path>")
    else:
        main(sys.argv[1], sys.argv[2])

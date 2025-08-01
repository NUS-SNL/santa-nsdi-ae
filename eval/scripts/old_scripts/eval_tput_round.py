import sys
import os
import concurrent.futures

def read_packets_from_text_file(file_path):
    packets = []
    with open(file_path, 'r') as file:
        next(file)  # Skip the header
        for line in file:
            try :
                fields = line.strip().split('\t')
                timestamp = float(fields[0])
                pkt_len = int(fields[6])
                packets.append((timestamp, pkt_len))
            except:
                continue        
    return packets


def process_tput_segment(start_time, end_time, packets, window, stride, output_file_path):
    current_time = start_time
    window_end = current_time + window

    while current_time <= end_time:
        # Filter packets within the current time window
        window_data = [(ts, pkt_len) for ts, pkt_len in packets if current_time <= ts < window_end]

        if window_data:
            # add 24 bytes of IFG, Preamble, SFD and FCS to the packet as well 
            throughput = sum((pkt_len + 24) for _, pkt_len in window_data) * 8 / window  # in bits/s
            with open(output_file_path, 'a') as outfile:
                outfile.write(f"{current_time}, {throughput}\n")

        current_time += stride
        window_end = current_time + window


def main(file_path):
    # traces_directory = 'eval/'
    output_directory = 'eval/tput_round'
    os.makedirs(output_directory, exist_ok=True)
    window = 10
    stride = 10
    segment_duration = 100  # seconds

    # Iterate over all .txt files in the traces directory

    # Extract file name from the provided file path
    file_name = os.path.basename(file_path)

    # Ensure the provided file is a .txt file
    if not file_name.endswith('.txt'):
        print("Error: Please provide a valid .txt file.")
        return

    # Read packets from the specified file
    packets = read_packets_from_text_file(file_path)
    print(f"Processing {file_path}")

            
    # Calculate the number of segments
    num_segments = int((packets[-1][0] - packets[0][0]) / segment_duration) + 1
    
    with concurrent.futures.ProcessPoolExecutor(max_workers=num_segments) as executor:
        futures = []
        for i in range(num_segments):
            start_time = packets[0][0] + i * segment_duration
            end_time = start_time + segment_duration
            output_file_name = f"{file_name.split('.')[0]}_tput_{int(window * 1000)}ms_{int(stride * 1000)}ms_{i}.csv"
            print(output_file_name)
            output_file_path = os.path.join(output_directory, output_file_name)

            # Save the results to a CSV file
            with open(output_file_path, 'w') as output_file:
                output_file.write("Time, Throughput\n")

            # Filter packets for the current segment and submit to the executor
            segment_packets = [(ts, pkt_len) for ts, pkt_len in packets if start_time <= ts < end_time]
            futures.append(executor.submit(process_tput_segment, start_time, end_time, segment_packets, window, stride, output_file_path))

        # Wait for all processes to finish
        concurrent.futures.wait(futures)

    print(f"Throughput data saved as {output_file_name} to '{output_directory}' directory for {file_name}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <file_path>")
    else:
        main(sys.argv[1])
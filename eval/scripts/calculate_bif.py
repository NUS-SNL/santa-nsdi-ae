import sys
import pandas as pd

def read_packets_from_text_file(file_path):
    packets = []
    src_dst_ports = None
    with open(file_path, 'r') as file:
        next(file)  # Skip the header
        for line in file:
            try:
                fields = line.strip().split('\t')
                timestamp = float(fields[0])
                pkt_len = int(fields[6])
                # Record src/dst ports from the first packet
                if src_dst_ports is None:
                    src_port = int(fields[4])
                    dst_port = int(fields[5])
                    src_dst_ports = (src_port, dst_port)
                packets.append((timestamp, pkt_len))
            except Exception as e:
                print(e)
                continue
    return packets, src_dst_ports

def read_dropped_packets(file_path, src_dst_ports):
    dropped_packets = []
    with open(file_path, 'r') as file:
        next(file)  # Skip the header
        for line in file:
            try:
                fields = line.strip().split('\t')
                timestamp = float(fields[0])
                src_port = int(fields[4])
                dst_port = int(fields[5])
                pkt_len = int(fields[6])
                # Only append packets that match the initially recorded src/dst ports
                if (src_port, dst_port) == src_dst_ports:
                    dropped_packets.append((timestamp, pkt_len))
            except Exception as e:
                print(e)
                continue
    return dropped_packets

def calculate_bytes_difference(send_packets, recv_packets, dropped_packets, window_size=0.01):
    times = [pkt[0] for pkt in send_packets + recv_packets + dropped_packets]
    start_time = min(times) if times else 0
    end_time = max(times) if times else 0

    time = start_time
    differences = []

    while time <= end_time:
        window_end = time + window_size
        send_bytes = sum(pkt_len for timestamp, pkt_len in send_packets if timestamp < window_end)
        recv_bytes = sum(pkt_len for timestamp, pkt_len in recv_packets if timestamp < window_end)
        dropped_bytes = sum(pkt_len for timestamp, pkt_len in dropped_packets if timestamp < window_end)
        
        bytes_difference = send_bytes - recv_bytes - dropped_bytes
        differences.append((time, bytes_difference))
        time += window_size

    return differences

def main(send_file_path, recv_file_path, dropped_file_path, output_file_path):
    send_packets, src_dst_ports = read_packets_from_text_file(send_file_path)
    recv_packets, _ = read_packets_from_text_file(recv_file_path)
    dropped_packets = read_dropped_packets(dropped_file_path, src_dst_ports) if src_dst_ports else []
    
    differences = calculate_bytes_difference(send_packets, recv_packets, dropped_packets)

    df = pd.DataFrame(differences, columns=['Time', 'Bytes Difference'])
    df.to_csv(output_file_path, index=False)

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python calculate_bif.py <send_trace_path> <recv_trace_path> <dropped_packets_path> <output_csv_path>")
    else:
        main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])

import sys
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os

WINDOW_SIZE = 0.04  # Window size in seconds
STRIDE = 0.01       # Stride in seconds

def read_pcap_file(file_path):
    """Reads a parsed PCAP text file into a DataFrame."""
    return pd.read_csv(
        file_path,
        sep="\t",
        header=0,
        names=["time", "src_ip", "dst_ip", "proto", "src_port", "dst_port", "length", "seq"]
    )

def compute_metrics(send_df, recv_df, total_drop_df):
    """Computes throughput, delay, and loss metrics for the given flow."""
    send_df['time'] = send_df['time'].astype(float)
    recv_df['time'] = recv_df['time'].astype(float)
    total_drop_df['time'] = total_drop_df['time'].astype(float)

    # Build lookup for send times using sequence numbers
    send_times = dict(zip(send_df['seq'], send_df['time']))
    send_src_ports = send_df['src_port'].unique()  # Get unique src_ports from send_df
    print(send_src_ports)
    metrics = []

    # Set window start to the first packet time in the send file
    start_time = send_df['time'].min() + 0.5
    max_time = max(send_df['time'].max(), recv_df['time'].max())
    window_start = start_time

    while window_start < max_time:
        window_end = window_start + WINDOW_SIZE

        # Filter packets within the window
        send_window = send_df[(send_df['time'] >= window_start) & (send_df['time'] < window_end)]
        recv_window = recv_df[(recv_df['time'] >= window_start) & (recv_df['time'] < window_end)]
        drop_window = total_drop_df[(total_drop_df['time'] >= window_start) & (total_drop_df['time'] < window_end)]

        # Throughput calculation (Mbps)
        total_bytes = recv_window['length'].sum()
        throughput = (total_bytes * 8) / (WINDOW_SIZE * 1e6)  # Convert to Mbps

        # Delay calculation (ms)
        delays = []
        for _, row in recv_window.iterrows():
            seq = row['seq']
            if seq in send_times:
                delays.append((row['time'] - send_times[seq]) * 1000)  # Convert to milliseconds
        avg_delay = np.mean(delays) if delays else 0

        # Loss calculation (ratio of dropped packets to sent packets in the window)
        sent_packets = len(send_window)
        
        # Count only dropped packets that match the sender's src_port
        dropped_packets = len(drop_window[drop_window['src_port'].isin(send_src_ports)])
        
        loss_rate = dropped_packets / sent_packets if sent_packets > 0 else 0

        metrics.append([window_start, throughput, avg_delay, loss_rate])
        window_start += STRIDE

    # Return metrics as a DataFrame
    return pd.DataFrame(metrics, columns=["time", "throughput", "avg_delay", "loss_rate"])

def plot_metrics(metrics_df, output_dir, base_name):
    """Plots scatter plots with throughput on the y-axis for delay and loss metrics."""
    # Predefined limits
    throughput_limit = 100  # Mbps
    delay_limit = 200      # ms
    loss_limit = 5       # Loss rate

    # Adjust the flow name
    flow_name = base_name.replace("send", "").strip("_")

    plt.figure(figsize=(10, 5))
    plt.scatter(metrics_df["avg_delay"], metrics_df["throughput"], alpha=0.7)
    plt.ylim(0, throughput_limit)
    plt.xlim(0, delay_limit)
    plt.ylabel("Throughput (Mbps)")
    plt.xlabel("Average Delay (ms)")
    plt.title(f"Delay vs. Throughput ({flow_name})")
    plt.grid(True)
    plt.gca().spines['top'].set_visible(False)
    plt.gca().spines['right'].set_visible(False)
    plt.savefig(f"{output_dir}/{base_name}_throughput_vs_delay.png")
    plt.close()

    plt.figure(figsize=(10, 5))
    plt.scatter(metrics_df["loss_rate"], metrics_df["throughput"], alpha=0.7, color='orange')
    plt.ylim(0, throughput_limit)
    plt.xlim(0, loss_limit)
    plt.ylabel("Throughput (Mbps)")
    plt.xlabel("Loss Rate")
    plt.title(f"Loss vs. Throughput ({flow_name})")
    plt.grid(True)
    plt.gca().spines['top'].set_visible(False)
    plt.gca().spines['right'].set_visible(False)
    plt.savefig(f"{output_dir}/{base_name}_throughput_vs_loss.png")
    plt.close()

def main():
    if len(sys.argv) != 5:
        print("Usage: python3 eval_metrics.py <send_file> <recv_file> <total_drop_file> <output_dir>")
        sys.exit(1)

    send_file = sys.argv[1]
    recv_file = sys.argv[2]
    total_drop_file = sys.argv[3]
    output_dir = sys.argv[4]

    send_df = read_pcap_file(send_file)
    recv_df = read_pcap_file(recv_file)
    total_drop_df = read_pcap_file(total_drop_file)

    metrics_df = compute_metrics(send_df, recv_df, total_drop_df)

    # Use base filename (without extension) to name the plots
    base_name = os.path.splitext(os.path.basename(send_file))[0]

    # Save metrics to CSV
    metrics_df.to_csv(f"{output_dir}/{base_name}_metrics.csv", index=False)

    # Generate plots
    plot_metrics(metrics_df, output_dir, base_name)

if __name__ == "__main__":
    main()

import os
import glob
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

def find_global_min_time(files):
    min_times = []
    for file in files:
        df = pd.read_csv(file)
        min_times.append(df['Time'].min())
    return min(min_times)

def plot_throughput_vs_time(csv_directory):
    custom_colors = ['#a6cee3','#1f78b4','#b2df8a','#33a02c','#fb9a99','#e31a1c','#fdbf6f','#ff7f00','#cab2d6']  # Extended color palette
    files = glob.glob(os.path.join(csv_directory, '*merged_tput_80ms_20ms*.csv'))
    files.sort()
    global_min_time = find_global_min_time(files)

    total_bandwidth = 200  # Total bandwidth to distribute in Mbps
    plt.figure(figsize=(10, 6))  # Set figure size

    # Iterate over each file and plot
    for i, csv_file in enumerate(files):
        df = pd.read_csv(csv_file)
        df['Time'] -= global_min_time
        df['Throughput'] /= 1e6
        flow_name = os.path.basename(csv_file).split('_merged')[0]
        flow_name = flow_name.split('recv_')[1]

        # Use modulo to cycle through colors if there are more files than colors
        plt.plot(df['Time'], df['Throughput'], label=flow_name, color=custom_colors[i % len(custom_colors)])

    stagger_time = 10
    # Plot fair share lines for each flow over time
    timeline = np.arange(0, 150, stagger_time)
    fair_share_timeline = np.zeros_like(timeline, dtype=float)

    for i, time_point in enumerate(timeline):
        if time_point < stagger_time*8:  # Increase in the number of active flows
            num_active_flows = i + 1
        else:  # Decrease in the number of active flows
            num_active_flows = 15 - i
        fair_share_timeline[i] = total_bandwidth / num_active_flows

    # Plot the fair share as a function of time
    plt.step(timeline, fair_share_timeline, where='post', color='black', label='Fair Share')

    # for start_time in range(0, 70, 10):
    #     num_active_flows = start_time/10 + 1
    #     fair_share = total_bandwidth / num_active_flows
    #     plt.hlines(fair_share, xmin=start_time, xmax=start_time + 10, colors='black', linestyles='dotted', label='Fair Share' if start_time == 0 else "")

    # for start_time in range(70, 140, 10):
    #     num_active_flows = 14 - start_time/10
    #     fair_share = total_bandwidth / num_active_flows
    #     plt.hlines(fair_share, xmin=start_time, xmax=start_time + 10, colors='black', linestyles='dotted', label='Fair Share' if start_time == 0 else "")

    plt.title('Throughput vs Time Combined')
    plt.xlabel('Time (s)')
    plt.ylabel('Throughput (Mbps)')
    plt.xlim(left=0)
    plt.ylim(bottom=0, top=total_bandwidth)  # Adjust upper limit to total bandwidth for visibility
    plt.grid(True)
    plt.legend()

    plt.tight_layout()
    plt.savefig(os.path.expanduser("~/eval/plots/combined_tput_8_flows_10_s.pdf"))
    plt.show()  # Show the plot for interactive mode or debugging

if __name__ == "__main__":
    csv_directory = os.path.expanduser("~/eval/tput")
    plot_throughput_vs_time(csv_directory)

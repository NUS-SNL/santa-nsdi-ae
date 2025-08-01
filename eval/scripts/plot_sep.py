import os
import glob
import csv
import pandas as pd
import matplotlib.pyplot as plt

def plot_throughput_vs_time(csv_directory):
    print(csv_directory)
    # ccas = ['bbr_1_20ms', 'bbr_2_40ms', 'cubic_1_20ms', 'cubic_2_40ms', 'reno_1_20ms', 'reno_2_40ms', 'vegas_1_20ms', 'vegas_2_40ms']  # Add more CCAs as needed
    # ccas = ['bbr_1_40ms', 'bbr_2_80ms', 'cubic_1_40ms', 'cubic_2_80ms', 'reno_1_40ms', 'reno_2_80ms', 'vegas_1_40ms', 'vegas_2_80ms']  # Add more CCAs as needed
    ccas = ['bbr_1_40ms', 'bbr_2_80ms', 'cubic_1_40ms', 'cubic_2_80ms']
    # Set up subplots based on the number of CCAs
    num_subplots = len(ccas)
    fig, axs = plt.subplots(num_subplots, 1, figsize=(10, 3 * num_subplots), sharex=True)

    custom_colors = ['red', 'blue', 'green', 'orange', 'purple', 'brown', 'pink', 'gray']
    
    for i, cca in enumerate(ccas):
        files = glob.glob(os.path.join(csv_directory, f'recv_{cca}_tput_10ms_5ms*.csv'))
        files.sort()
        times = []
        throughputs = []
        # colors = plt.cm.viridis(i / num_subplots)  # Use a colormap to get different colors
        
        for csv_file in files:
            df = pd.read_csv(csv_file)
            times.extend(df['Time'].tolist())
            throughputs.extend(df[' Throughput'].tolist())
            throughputs = [t / 1e6 for t in throughputs]
        
        # Plot on the respective subplot with different colors
        axs[i].plot(times, throughputs, label=f'{cca}', color=custom_colors[i])
        axs[i].set_ylabel(f'Throughput (Mbps) - {cca}')
        axs[i].set_ylim(0, 100)  # Set y-axis limits
        axs[i].grid(True)
        axs[i].legend()

    plt.xlabel('Time(s)')
    plt.suptitle('Throughput vs Time for Different CCAs', y=0.92)
    plt.tight_layout()  # Add tight layout
    plt.savefig("4_flow_sep_plot.pdf")

if __name__ == "__main__":
    csv_directory = 'eval/tput'
    plot_throughput_vs_time(csv_directory)

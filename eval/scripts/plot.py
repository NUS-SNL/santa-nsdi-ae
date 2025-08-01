import os
import glob
import sys
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator

def set_xaxis_ticks(axs, interval=10):
    for ax in axs:
        ax.xaxis.set_major_locator(MultipleLocator(interval))
        ax.grid(True)  # Ensuring the grid is enabled to align with new ticks

cca_queue_changes = {}

def find_global_min_time(files):
    min_times = []
    for file in files:
        df = pd.read_csv(file)
        min_times.append(df['Time'].min())
    return min(min_times)

# NOTE: the csv path taken is sensitive to window and stride
def plot_throughput_vs_time(axs, csv_directory, num_queues):
    # custom_colors = {0: 'red', 1: 'blue', 2: 'purple', 3: 'orange', 4: 'green'}
    custom_colors = {0: 'red', 1: 'blue', 2: 'orange', 3: 'magenta', 4: 'teal', 5: 'slategray'}
    files = glob.glob(os.path.join(csv_directory, '*merged_tput_80ms_20ms*.csv'))
    files.sort()
    global_min_time = find_global_min_time(files)

    # Iterate over each file and plot on its respective subplot
    for ax, csv_file in zip(axs, files):
        df = pd.read_csv(csv_file)
        df['Time'] -= global_min_time
        df['Throughput'] /= 1e6
        flow_name = os.path.basename(csv_file).split('_merged')[0]
        flow_name = flow_name.split('recv_')[1]
        cca_queue_changes[flow_name] = []
        # prev_queue = int(0)
        segments = []
        init = True
        # for starting the segments (helps in case a flow maintains queue throughout)
        # cca_queue_changes[flow_name].append((0, prev_queue))
        legend_labels = set()  # Track labels that have been added to the legend

        for idx, row in df.iterrows():
            queue_num = row['Queue_Number']
            if queue_num >= num_queues:
                continue
            if init:
                cca_queue_changes[flow_name].append((0, queue_num))
                prev_queue = queue_num
                init= False
            if queue_num != prev_queue:
                cca_queue_changes[flow_name].append((row['Time'], queue_num))
                if segments:
                    df_segment = pd.concat(segments)
                    label = f'Queue {int(prev_queue)}'
                    if label not in legend_labels:  # Check if the label has already been used
                        ax.plot(df_segment['Time'], df_segment['Throughput'], label=label, color=custom_colors.get(prev_queue, 'black'))
                        legend_labels.add(label)  # Mark this label as used
                    else:
                        ax.plot(df_segment['Time'], df_segment['Throughput'], color=custom_colors.get(prev_queue, 'black'))
                    segments = []
                prev_queue = queue_num
            segments.append(row.to_frame().T)

        if segments:
            df_segment = pd.concat(segments)
            label = f'Queue {int(prev_queue)}'
            if label not in legend_labels:
                ax.plot(df_segment['Time'], df_segment['Throughput'], label=label, color=custom_colors.get(prev_queue, 'black'))
                legend_labels.add(label)
            else:
                ax.plot(df_segment['Time'], df_segment['Throughput'], color=custom_colors.get(prev_queue, 'black'))

        ax.set_title(f'Throughput vs Time - {flow_name}')
        ax.set_ylabel('Throughput (Mbps)')
        ax.set_xlim(0, 160)
        ax.set_ylim(0, 190)
        ax.grid(True)
        ax.legend()

def find_global_min_timestamp(files):
    """Finds the global minimum timestamp across all provided files."""
    min_timestamps = []
    for file in files:
        df = pd.read_csv(file, delim_whitespace=True, usecols=['frame.time_epoch']).dropna()
        min_timestamps.append(df['frame.time_epoch'].min())
    return min(min_timestamps)

def process_files_and_plot_queue_depth(ax, directory, num_queues, granularity='10ms'):
    # colors = ['green', 'orange', 'purple', 'cyan', 'magenta', 'lime', 'brown', 'navy', 'teal', 'olive']
    colors = {0: 'red', 1: 'blue', 2: 'orange', 3: 'magenta', 4: 'teal', 5: 'slategray'}
    files = glob.glob(os.path.join(directory, '*_merged.txt'))
    files.sort()

    # Find the global minimum timestamp across all files.
    global_min_time = find_global_min_timestamp(files)

    combined_data = []
    for file in files:
        df = pd.read_csv(file, delim_whitespace=True, usecols=['frame.time_epoch', 'q_num', 'q_depth']).dropna()
        df['q_num'] = df['q_num'].astype(int)
        df = df[df['q_num'] < num_queues]  # Assuming queues are zero-indexed.
        df['q_depth'] = df['q_depth'] * 80 / 1e6  # Convert to MBytes
        df['frame.time_epoch'] = pd.to_datetime(df['frame.time_epoch'], unit='s')
        # Adjust time_offset using the global minimum time.
        df['time_offset'] = (df['frame.time_epoch'] - pd.to_datetime(global_min_time, unit='s')).dt.total_seconds()
        combined_data.append(df)

    combined_data = pd.concat(combined_data)

    # Now plot each queue's data.
    for q_num, group in combined_data.groupby('q_num'):
        group.set_index(pd.to_timedelta(group['time_offset'], unit='s'), inplace=True)
        resampled = group.resample(granularity).max()['q_depth'].reset_index()
        resampled['time_offset'] = resampled['time_offset'].dt.total_seconds()
        ax.plot(resampled['time_offset'], resampled['q_depth'], label=f'Queue {q_num}', color=colors[q_num % len(colors)])

    ax.set_xlabel('Time (s)')
    ax.set_ylabel('Q Depth (MBytes)')
    ax.set_title('Queue Depth vs Time for Different Queues')
    ax.legend(title='Queue Numbers', loc='upper right')
    ax.grid(True)


def plot_bytes_in_flight(axs, directory, num_queues):
    bif_files = glob.glob(os.path.join(directory, 'bif_*.txt'))
    bif_files.sort()
    global_min_time = find_global_min_time(bif_files)

    flow_color_map = {}  # Map to store colors for each flow
    colors = ['#1f77b4',  # muted blue
            '#9467bd',  # muted purple
            '#8c564b',  # chestnut brown
            '#ff7f0e',  # safety orange
            '#2ca02c',  # cooked asparagus green
            '#e377c2',  # raspberry yogurt pink
            '#7f7f7f',  # middle gray
            '#bcbd22',  # curry yellow-green
            '#17becf'   # blue-teal
    ]
    for bif_file in bif_files:
        df = pd.read_csv(bif_file)
        df['Time'] -= global_min_time
        df['Bytes Difference'] /= 1e6
        flow_name = os.path.basename(bif_file).replace('bif_', '').replace('.txt', '')

        # Ensure each flow has a unique color
        if flow_name not in flow_color_map:
            flow_color_map[flow_name] = colors[len(flow_color_map) % len(colors)]
        flow_color = flow_color_map[flow_name]

        # Get queue changes for the flow
        queue_changes = cca_queue_changes.get(flow_name, [])

        print(flow_name,queue_changes)
        # Plot segments based on queue changes
        prev_time = 0
        prev_queue = 0
        for time, queue_num in queue_changes:
            # Filter BIF data for the current segment
            segment_df = df[(df['Time'] >= prev_time) & (df['Time'] < time)]
            try:
                if not segment_df.empty:
                    axs[int(prev_queue)].plot(segment_df['Time'], segment_df['Bytes Difference'], label=flow_name, color=flow_color)
            except:
                print("mice queue initial pkts")
            prev_time = time
            prev_queue = queue_num
        
        # Plot the last segment (from the last queue change to the end)
        if queue_changes:
            last_queue_num = prev_queue
            segment_df = df[df['Time'] >= prev_time]
            if not segment_df.empty:
                axs[int(last_queue_num)].plot(segment_df['Time'], segment_df['Bytes Difference'], label=flow_name, color=flow_color)

    # Finalize each subplot
    for i, ax in enumerate(axs):
        ax.set_xlabel('Time (s)')
        ax.set_ylabel('MBytes')
        ax.set_title(f'Bytes in Flight - Queue {i}')
        ax.grid(True)
        # Here we handle legend duplication. Create a custom legend based on the flow_color_map
        handles, labels = ax.get_legend_handles_labels()
        by_label = dict(zip(labels, handles))  # Remove duplicates
        ax.legend(by_label.values(), by_label.keys())

def main(config_name):
    num_queues = 4  # Predefined number of queues
    
    csv_directory = os.path.expanduser(f"~/eval/{config_name}/tput")
    queue_depth_directory = os.path.expanduser(f"~/eval/{config_name}/convert_new")
    bif_directory = os.path.expanduser(f"~/eval/{config_name}/convert_new")

    num_flows = len(glob.glob(os.path.join(csv_directory, '*merged_tput_80ms_20ms*.csv')))
    fig, axs = plt.subplots(num_flows + num_queues + 1, 1, figsize=(11, 3 * (num_flows + num_queues + 1)), sharex=True)

    print(num_flows)
    plot_throughput_vs_time(axs[:num_flows], csv_directory, num_queues)
    process_files_and_plot_queue_depth(axs[num_flows], queue_depth_directory, num_queues)
    plot_bytes_in_flight(axs[num_flows + 1:], bif_directory, num_queues)

    max_time = 100  # This should be replaced with the actual max time across all your plots

    # Add dotted vertical lines at every 5 seconds
    round_interval = 10
    for x in range(0, max_time + 1, round_interval):
        for ax in axs:
            ax.axvline(x=x, color='gray', linestyle='--', linewidth=1)

    set_xaxis_ticks(axs, interval=10)
    plt.tight_layout()
    plt.savefig(os.path.expanduser("~/eval/plots/6_flow_5_q_10s.pdf"))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <config_name>")
        sys.exit(1)
    config_name = sys.argv[1]
    main(config_name)

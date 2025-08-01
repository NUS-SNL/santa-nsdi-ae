import os
import glob
import pandas as pd
import matplotlib.pyplot as plt

def process_files_and_plot_queue_depth(directory, granularity='10ms'):
    colors = ['red', 'blue', 'green', 'orange', 'purple', 'cyan', 'magenta', 'yellow', 'black', 'grey']
    
    combined_data = []

    files = glob.glob(os.path.join(directory, '*_merged.txt'))
    files.sort()

    for file in files:
        df = pd.read_csv(file, delim_whitespace=True, usecols=['frame.time_epoch', 'q_num', 'q_depth']).dropna()

        df['q_num'] = df['q_num'].astype(int)

        # Convert 'frame.time_epoch' to datetime and normalize to start from 0
        df['frame.time_epoch'] = pd.to_datetime(df['frame.time_epoch'], unit='s')
        df['time_offset'] = (df['frame.time_epoch'] - df['frame.time_epoch'].min()).dt.total_seconds()

        combined_data.append(df)

    combined_data = pd.concat(combined_data)

    plt.figure(figsize=(10, 6))
    for q_num, group in combined_data.groupby('q_num'):
        # Convert 'time_offset' to TimedeltaIndex for resampling
        group['time_offset'] = pd.to_timedelta(group['time_offset'], unit='s')
        group.set_index('time_offset', inplace=True)

        # Resample and get the maximum 'q_depth' within each bin
        resampled = group.resample(granularity)['q_depth'].max().reset_index()

        # Convert the 'time_offset' back to seconds for plotting
        resampled['time_offset'] = resampled['time_offset'].dt.total_seconds()

        plt.plot(resampled['time_offset'], resampled['q_depth'], label=f'Queue {q_num}', color=colors[q_num % len(colors)])

    plt.xlabel('Time (s)')
    plt.ylabel('Queue Depth')
    plt.title('Queue Depth vs Time for Different Queues')
    plt.legend(title='Queue Numbers')
    plt.grid(True)
    plt.tight_layout()
    plt.savefig("4_flow_net_qd.pdf")
    plt.show()

if __name__ == "__main__":
    directory = "eval/convert_new"
    process_files_and_plot_queue_depth(directory)

import os
import glob
import pandas as pd
import matplotlib.pyplot as plt

def plot_bytes_in_flight(directory):
    # Set up the figure for plotting
    plt.figure(figsize=(14, 7))

    # Get a list of all BIF files
    bif_files = glob.glob(os.path.join(directory, 'bif_*.txt'))
    bif_files.sort()
    # Iterate over each file and plot it
    for bif_file in bif_files:
        df = pd.read_csv(bif_file)
        
        # Normalize time to start from the minimum time in the dataset
        df['Time'] -= df['Time'].min()
        df['Bytes Difference'] /= 1e6
        # Extract the flow name from the file name for the legend
        flow_name = os.path.basename(bif_file).replace('bif_', '').replace('.txt', '')

        # Plot the 'Bytes Difference' for each flow
        plt.plot(df['Time'], df['Bytes Difference'], label=flow_name)

    # Label the plot
    plt.xlim(0,)
    plt.xlabel('Time (s)')
    plt.ylabel('MBytes')
    plt.title('Bytes in Flight for Different Flows')
    plt.legend()
    plt.grid(True)

    # Show the plot
    plt.tight_layout()
    plt.savefig("4_flow_bif.pdf")

if __name__ == "__main__":
    directory = "eval/convert_new"  # Update this to your directory containing BIF files
    plot_bytes_in_flight(directory)

from scapy.all import *
from scapy.layers.inet import TCP
import sys

class SantaHeader(Packet):
    name = "SantaHeader"
    fields_desc = [
        ByteField("q_num", 0),
        X3BytesField("q_depth", 0)
    ]

bind_layers(TCP, SantaHeader)

def parse_pcap(file_name, output_file):
    packets = rdpcap(file_name)
    with open(output_file, "w") as f:  # Note the change to "w" to create/overwrite a new file
        for packet in packets:
            if TCP in packet and len(packet[TCP].payload) >= 4:
                santa_header = SantaHeader(bytes(packet[TCP].payload)[:4])
                f.write(f"{santa_header.q_num}\t{santa_header.q_depth}\n")
            else:
                f.write(f"N/A\tN/A\n")  # Write placeholders if no Santa header is found

if __name__ == "__main__":
    pcap_file = sys.argv[1]
    output_file = sys.argv[2] + "_santa.txt"  # Append "_santa" to differentiate this file
    parse_pcap(pcap_file, output_file)

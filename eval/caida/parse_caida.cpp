#include <iostream>
#include "stdlib.h"
#include "SystemUtils.h"
#include "Packet.h"
#include "EthLayer.h"
#include "IPv4Layer.h"
#include "IPv6Layer.h"
#include "PcapFileDevice.h"
#include <arpa/inet.h>

int main() {
    // Open the pcap file
    pcpp::IFileReaderDevice* reader = pcpp::IFileReaderDevice::getReader("./equinix-nyc.dirA.20190117-130000.UTC.anon.pcap");
    
    if (!reader->open()) {
        std::cerr << "Error opening input pcap file\n";
        delete reader;
        return 1;
    }

    // Create a pcap file writer with link layer Ethernet to match the added Ethernet layers
    pcpp::PcapFileWriterDevice writer("./pcpp_caida_rewrite.pcap", pcpp::LINKTYPE_ETHERNET);
    if (!writer.open()) {
        std::cerr << "Error opening output pcap file\n";
        delete reader;
        return 1;
    }

    pcpp::RawPacket rawPacket;
    while (reader->getNextPacket(rawPacket)) {
        pcpp::Packet parsedPacket(&rawPacket);

        // Skip non-IP packets (including IPv6 if that's your intent) 
        if (!parsedPacket.isPacketOfType(pcpp::IPv4) && !parsedPacket.isPacketOfType(pcpp::IPv6)) {
            continue;
        }

        // For IPv4 packets, or if you want to handle IPv6 packets similarly, add an Ethernet layer
        if (parsedPacket.isPacketOfType(pcpp::IPv4)) {
            // Create a new Ethernet layer
            pcpp::MacAddress srcMac("b8:ce:f6:04:6b:d0");
            pcpp::MacAddress dstMac("b8:ce:f6:04:6b:d1");
            pcpp::EthLayer newEthLayer(srcMac, dstMac, PCPP_ETHERTYPE_IP); // ETH_P_IP for IPv4

            // Add the Ethernet layer to the beginning of the packet
            parsedPacket.addLayer(&newEthLayer, true);

            // Recompute packet layers
            parsedPacket.computeCalculateFields();
        }

        // Optionally, handle IPv6 packets similarly here if needed

        // Write the modified packet to the output file
        if (parsedPacket.isPacketOfType(pcpp::IPv4)) {
            parsedPacket.computeCalculateFields();
            writer.writePacket(*parsedPacket.getRawPacket());
        }
    }

    // Cleanup
    reader->close();
    writer.close();
    delete reader;

    return 0;
}

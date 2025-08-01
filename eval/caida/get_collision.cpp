#include <iostream>
#include <fstream> // Include for file writing
#include <unordered_map>
#include <string>
#include <map>
#include "PcapFileDevice.h"
#include "Packet.h"
#include "IPv4Layer.h"
#include "TcpLayer.h"
#include "UdpLayer.h"
#include <arpa/inet.h>

struct WindowStats {
    std::unordered_map<std::string, int> collisionFlows, nonCollisionFlows, otherFlows;
    int collisionPackets = 0, nonCollisionPackets = 0, otherPackets = 0;
};

std::string createFlowKey(pcpp::IPv4Layer* ipv4Layer, pcpp::Packet& packet) {
    std::string srcIp = ipv4Layer->getSrcIPAddress().toString();
    std::string dstIp = ipv4Layer->getDstIPAddress().toString();
    uint16_t srcPort = 0, dstPort = 0;
    uint8_t protocol = ipv4Layer->getIPv4Header()->protocol;

    if (packet.isPacketOfType(pcpp::TCP)) {
        pcpp::TcpLayer* tcpLayer = packet.getLayerOfType<pcpp::TcpLayer>();
        srcPort = ntohs(tcpLayer->getTcpHeader()->portSrc);
        dstPort = ntohs(tcpLayer->getTcpHeader()->portDst);
    } else if (packet.isPacketOfType(pcpp::UDP)) {
        pcpp::UdpLayer* udpLayer = packet.getLayerOfType<pcpp::UdpLayer>();
        srcPort = ntohs(udpLayer->getUdpHeader()->portSrc);
        dstPort = ntohs(udpLayer->getUdpHeader()->portDst);
    }

    return srcIp + ":" + std::to_string(srcPort) + "->" + dstIp + ":" + std::to_string(dstPort) + ":" + std::to_string(protocol);
}

int main() {
    pcpp::IFileReaderDevice* reader = pcpp::IFileReaderDevice::getReader("./normal_capture.pcap");

    if (!reader->open()) {
        std::cerr << "Error opening input pcap file\n";
        delete reader;
        return 1;
    }

    bool firstPacket = true;
    uint32_t baseTime = 0;
    std::map<uint32_t, WindowStats> windows;

    // Open output file
    std::ofstream outputFile("output_stats.txt");
    outputFile << "Total Packets, Collisions, Other Packets, Total Unique Flows, Total Collided Flows, Non Santa Flows\n";

    pcpp::RawPacket rawPacket;
    while (reader->getNextPacket(rawPacket)) {
        if (firstPacket) {
            baseTime = rawPacket.getPacketTimeStamp().tv_sec;
            firstPacket = false;
        }

        uint32_t timeDiff = rawPacket.getPacketTimeStamp().tv_sec - baseTime;
        uint32_t windowIndex = timeDiff / 10; // Calculate the index of the current 10-second window

        pcpp::Packet parsedPacket(&rawPacket);
        pcpp::IPv4Layer* ipv4Layer = parsedPacket.getLayerOfType<pcpp::IPv4Layer>();

        if (ipv4Layer) {
            uint16_t identification = ntohs(ipv4Layer->getIPv4Header()->ipId);
            std::string flowKey = createFlowKey(ipv4Layer, parsedPacket);

            WindowStats& stats = windows[windowIndex]; // Reference to the stats for the current window

            if (identification == 1) {
                stats.collisionFlows[flowKey]++;
                stats.collisionPackets++;
            } else if (identification == 2) {
                stats.nonCollisionFlows[flowKey]++;
                stats.nonCollisionPackets++;
            } else {
                stats.otherFlows[flowKey]++;
                stats.otherPackets++;
            }
        }
    }

    reader->close();
    delete reader;

    // Write collected statistics to the file
    for (const auto& entry : windows) {
        const WindowStats& stats = entry.second;
        outputFile << stats.collisionPackets + stats.nonCollisionPackets << ","
                   << stats.collisionPackets << ","
                   << stats.otherPackets << ","
                   << stats.nonCollisionFlows.size() + stats.collisionFlows.size() << ","
                   << stats.collisionFlows.size() << ","
                   << stats.otherFlows.size() << "\n";
    }

    outputFile.close();

    return 0;
}

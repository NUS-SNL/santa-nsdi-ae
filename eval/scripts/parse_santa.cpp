#include <iostream>
#include "stdlib.h"
#include "SystemUtils.h"
#include "Packet.h"
#include "EthLayer.h"
#include "IPv4Layer.h"
#include "TcpLayer.h"
#include "HttpLayer.h"
#include "PcapFileDevice.h"
#include <arpa/inet.h>

using namespace pcpp;

class SantaHeaderLayer : public Layer {
public:
    SantaHeaderLayer(uint8_t* data, size_t dataLen, Layer* prevLayer, Packet* packet)
        : Layer(data, dataLen, prevLayer, packet) { m_Protocol = GenericPayload; }

    // Required by the Layer base class
    size_t getHeaderLen() const override {
        return 4; // Assuming SantaHeader is always 4 bytes
    }

    void computeCalculateFields() override {
        // If your layer requires calculation/updating of fields before packet is sent,
        // implement this logic here. Otherwise, leave it empty for static layers.
    }

    OsiModelLayer getOsiModelLayer() const override {
        // Assuming it acts as an extension to the Transport Layer, but adjust as necessary
        return OsiModelTransportLayer;
    }

    uint8_t getQNum() { return m_Data[0]; }
    uint32_t getQDepth() {
        if (m_DataLen < 4)
            return 0;
        uint32_t qDepth = 0;
        memcpy(&qDepth, m_Data + 1, 3);
        return ntohl(qDepth) >> 8; // Adjust for endianess and the 3-byte depth
    }

    void parseNextLayer() override {
    }

    std::string toString() const override {
        return "SantaHeaderLayer";
    }
};

int main(int argc, char* argv[])
{
    if (argc != 3)
    {
        std::cerr << "Usage: " << argv[0] << " <input pcap file> <output file>" << std::endl;
        return 1;
    }

    // Open the pcap file
    IFileReaderDevice* reader = IFileReaderDevice::getReader(argv[1]);

    if (!reader->open())
    {
        std::cerr << "Error opening the pcap file: " << argv[1] << std::endl;
        return 1;
    }

    RawPacket rawPacket;
    std::ofstream outFile(argv[2], std::ios::out);

    outFile << "q_num\tq_depth" << std::endl;

    // Read all packets one by one and parse the "Santa" header
    while (reader->getNextPacket(rawPacket))
    {
        Packet parsedPacket(&rawPacket);
        if (parsedPacket.isPacketOfType(IPv4))
        {
            // Check for TCP layer
            TcpLayer* tcpLayer = parsedPacket.getLayerOfType<TcpLayer>();
            if (tcpLayer != NULL && tcpLayer->getLayerPayloadSize() > 4)
            {
                SantaHeaderLayer santaLayer(tcpLayer->getLayerPayload(), tcpLayer->getLayerPayloadSize(), tcpLayer, &parsedPacket);
                outFile << (int)santaLayer.getQNum() << "\t" << santaLayer.getQDepth() << std::endl;
                // printf("Hello\n");
            } else {
                outFile << " "<< "\t" << " " << std::endl;
            }
        }
    }

    reader->close();
    outFile.close();

    return 0;
}

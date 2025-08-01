#pragma once

#include "define.h"

//== Constants
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_VLAN = 16w0x0810;
const ether_type_t ETHERTYPE_ARP  = 16w0x0806;
const ether_type_t ETHERTYPE_THRESHOLD_UPDATE = 16w0x0901;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

typedef bit<8> tcp_flags_t;
const tcp_flags_t TCP_FLAGS_F = 1;
const tcp_flags_t TCP_FLAGS_S = 2;
const tcp_flags_t TCP_FLAGS_R = 4;
const tcp_flags_t TCP_FLAGS_P = 8;
const tcp_flags_t TCP_FLAGS_A = 16;

//== Special Headers
// Header for sending updates from egress to ingress
@pa_no_overlay("ingress", "hdr.afd_update.new_threshold")
@pa_no_overlay("egress", "hdr.afd_update.new_threshold")
header afd_recirc_h {
    vlink_index_t vlink_id;
    byterate_t new_threshold;
    @padding bit<7> _pad0;
    bit<1> congestion_flag;
}
// Header for mirrored packets from ingress to egress
header mirror_h {
    bridged_metadata_type_t bmd_type;
    vlink_index_t   vlink_id;
}

//== Headers
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}
header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header arp_h {
    bit<16>       htype;
    bit<16>       ptype;
    bit<8>        hlen;
    bit<8>        plen;
    bit<16>       opcode;
    mac_addr_t    hw_src_addr;
    bit<32>       proto_src_addr;
    mac_addr_t    hw_dst_addr;
    bit<32>       proto_dst_addr;
}
header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;

    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_lenght;
    bit<16> checksum;
}

struct header_t {
    ethernet_h fake_ethernet;  // For signalling to ingress that this is an update
    afd_recirc_h afd_update;  // Update contents
    ethernet_h ethernet;
    ipv4_h ipv4;
    tcp_h tcp;
    udp_h udp;
    arp_h arp;
}

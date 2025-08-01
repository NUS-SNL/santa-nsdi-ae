#ifndef _HEADERS_
#define _HEADERS_

struct ig_hash_table_entry {
    bit<16> fp;  // fingerprint 
    bit<16> q_alloc;  // q_num
}

struct hash_table_entry {
    bit<32> fp;  // fingerprint 
    bit<32> q_delay;  // timestamp
}

enum bit<16> ether_type_t {
    TPID       = 0x8100,
    IPV4       = 0x0800,
    IPV6       = 0x86DD,
    TO_CPU     = 0xBF01,
    ARP        = 0x0806
}

enum bit<8>  ip_proto_t {
    ICMP  = 1,
    IGMP  = 2,
    TCP   = 6,
    UDP   = 17
}
struct ports {
    bit<16>  sp;
    bit<16>  dp;
}


typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
header ethernet_h {
    mac_addr_t    dst_addr;
    mac_addr_t    src_addr;
    ether_type_t  ether_type;
}

header vlan_tag_h {
    bit<3>        pcp;
    bit<1>        cfi;
    bit<12>       vid;
    ether_type_t  ether_type;
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

header ipv4_h {
    bit<4>       version;
    bit<4>       ihl;
    bit<7>       diffserv;
    bit<1>       res;
    bit<16>      total_len;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    bit<8>       protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t      src_addr;
    ipv4_addr_t      dst_addr;
}

header icmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header igmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header tcp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<32>  seq_no;
    bit<32>  ack_no;
    bit<4>   data_offset;
    bit<4>   res;
    bit<8>   flags;
    bit<16>  window;
    bit<16>  checksum;
    bit<16>  urgent_ptr;
}

header tcp_options_h {
    varbit<320> data;
}

header udp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<16>  len;
    bit<16>  checksum;
}

header santa_h {
    bit<8>   q_num;
    bit<24>  q_depth;
}

/*** Internal Headers ***/
typedef bit<4> internal_hdr_type_t;
typedef bit<4> internal_hdr_info_t;

const internal_hdr_type_t INTERNAL_HDR_TYPE_BRIDGED_META = 0xA;
const internal_hdr_type_t INTERNAL_HDR_TYPE_IG_MIRROR = 0xB;
const internal_hdr_type_t INTERNAL_HDR_TYPE_EG_MIRROR = 0xC;


#define INTERNAL_HEADER           \
    internal_hdr_type_t type; \
    internal_hdr_info_t info

header internal_hdr_h {
    INTERNAL_HEADER;
}

// TODO: add the bridge header here for taking any metadata
/* Any metadata to be bridged from ig to eg */
header bridge_h {
    INTERNAL_HEADER;
    bit<48> ingress_timestamp;
    bit<8> pkt_flag;
    /* Add any metadata to be bridged from ig to eg */
}

//------------------- METADATA AND HDR LAYOUT ------------------------------------


struct my_ingress_headers_t{
    bridge_h           bridge;
    ethernet_h         ethernet;
    arp_h              arp;
    vlan_tag_h[2]      vlan_tag;
    ipv4_h             ipv4;
    icmp_h             icmp;
    igmp_h             igmp;
    tcp_h              tcp;
    udp_h              udp;
    // santa_h            santa;
}


/******  G L O B A L   I N G R E S S   M E T A D A T A  *********/
struct my_ingress_metadata_t {
    bit<16>            src_port;
    bit<16>            dst_port;
    // bit<32>            pkt_fingerprint;
}

/* struct old_my_ingress_metadata_t {
    bit<8>          mirror_header_type;
    bit<8>          mirror_header_info;
    PortId_t        ingress_port;
    MirrorId_t      mirror_session;
} */

struct my_egress_headers_t {
    bridge_h           bridge;
    ethernet_h         ethernet;
    arp_h              arp;
    vlan_tag_h[2]      vlan_tag;
    ipv4_h             ipv4;
    icmp_h             icmp;
    igmp_h             igmp;
    tcp_h              tcp;
    // tcp_options_h      tcp_options;
    udp_h              udp;
    santa_h            santa;
}

/********  G L O B A L    bit<32> pkt_fingerprint;   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
    bridge_h           bridge_meta;  
    bit<16>            src_port;
    bit<16>            dst_port;
    bit<16>            l4_payload_csum;
    // bit<32> pkt_fingerprint;
    // bit<32> queuing_delay;
    // bit<8>  entry_flag;
}


#endif /* _HEADERS_ */

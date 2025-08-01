#include <core.p4>
#include <tofino1_specs.p4>
#include <tofino1_base.p4>
#include <tofino1_arch.p4>


// ALL TH HEADERS AND METADATA
struct compiler_generated_metadata_t {
    bit<10> mirror_id;
    bit<8>  mirror_source;
    bit<8>  resubmit_source;
    bit<4>  clone_src;
    bit<4>  clone_digest_id;
    bit<32> instance_type;
}

struct node_meta_t {
    bit<8> clone_md;
}

struct meta_t {
    bit<32> cc;
    bit<32> per_tenant_A;
    bit<32> total_A;
    bit<32> total_F;
    bit<4>  randv;
    bit<4>  randv2;
    bit<8>  per_tenant_true_flag;
    bit<8>  per_tenant_false_flag;
    bit<8>  total_true_flag;
    bit<8>  total_false_flag;
    bit<32> per_tenant_F;
    bit<32> per_tenant_F_prev;
    bit<32> total_F_prev;
    bit<16> halflen;
    bit<16> weight_len;
    bit<32> label;
    bit<32> label_shl_1;
    bit<32> label_shl_2;
    bit<32> label_shl_3;
    bit<32> alpha_shl_4;
    bit<32> alpha_times_15;
    bit<32> label_times_randv;
    bit<32> min_alphatimes15_labeltimesrand;
    bit<4>  uncongest_state_predicate;
    bit<4>  total_uncongest_state_predicate;
    bit<4>  to_drop;
    bit<2>  to_resubmit;
    bit<2>  to_resubmit_2;
    bit<2>  to_resubmit_3;
    bit<32> tsp;
    bit<32> min_pertenantF_totalalpha;
    bit<32> delta_total_alpha;
    bit<8>  pertenantF_leq_totalalpha;
    bit<32> total_alpha_mini;
    bit<32> per_tenant_alpha_mini;
    bit<32> per_tenant_alpha_mini_w2;
    bit<16> fraction_factor;
    bit<2>  w2;
    bit<32> delta_c;
}

struct standard_metadata_t {
    bit<9>  ingress_port;
    bit<32> packet_length;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<16> egress_instance;
    bit<32> instance_type;
    bit<8>  parser_status;
    bit<8>  parser_error_location;
}

header ethernet_t {
    bit<16> dstAddr_lower;
    bit<32> dstAddr_upper;
    bit<16> srcAddr_lower;
    bit<32> srcAddr_upper;
    bit<16> etherType;
}

header ig_mirror_header_1_t {
    bit<8> mirror_source;
    @flexible
    bit<8> current_node_meta_clone_md;
}

@name("generator_metadata_t") header generator_metadata_t_0 {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header info_hdr_t {
    bit<32> tsp;
    bit<32> label;
    bit<32> per_tenant_A;
    bit<32> total_A;
    bit<16> flow_id;
    bit<16> tenant_id;
    bit<1>  recirc_flag;
    bit<1>  update_alpha;
    bit<1>  update_total_alpha;
    bit<8>  update_rate;
    bit<1>  label_smaller_than_alpha;
    bit<4>  padding;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  diffserv;
    bit<2>  ecn_flag;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header recirculate_hdr_t {
    bit<8>  congested;
    bit<8>  to_drop;
    bit<8>  pertenantF_leq_totalalpha;
    bit<32> per_tenant_F;
    bit<32> total_F;
    bit<32> per_tenant_alpha;
    bit<32> total_alpha;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> pkt_length;
    bit<16> checksum;
}

struct metadata {
    @name(".__bfp4c_compiler_generated_meta")
    compiler_generated_metadata_t               __bfp4c_compiler_generated_meta;
    @name(".current_node_meta")
    node_meta_t                                 current_node_meta;
    @name(".eg_intr_md")
    egress_intrinsic_metadata_t                 eg_intr_md;
    @name(".eg_intr_md_for_dprsr")
    egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr;
    @name(".eg_intr_md_for_oport")
    egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport;
    @name(".eg_intr_md_from_parser_aux")
    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_parser_aux;
    @name(".ig_intr_md")
    ingress_intrinsic_metadata_t                ig_intr_md;
    @name(".ig_intr_md_for_tm")
    ingress_intrinsic_metadata_for_tm_t         ig_intr_md_for_tm;
    @name(".ig_intr_md_from_parser_aux")
    ingress_intrinsic_metadata_from_parser_t    ig_intr_md_from_parser_aux;
    @name(".meta")
    meta_t                                      meta;
    @name(".standard_metadata")
    standard_metadata_t                         standard_metadata;
    bit<32>                                     temp;
}

struct headers {
    @name(".ethernet")
    ethernet_t           ethernet;
    @name(".ig_mirror_header_1")
    ig_mirror_header_1_t ig_mirror_header_1;
    @name(".info_hdr")
    info_hdr_t           info_hdr;
    @name(".ipv4")
    ipv4_t               ipv4;
    @name(".recirculate_hdr")
    recirculate_hdr_t    recirculate_hdr;
    @name(".tcp")
    tcp_t                tcp;
    @name(".udp")
    udp_t                udp;
}


// ----------------- END OF HEADERS ------------------//

parser IngressParserImpl(packet_in pkt, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md, out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr) {
    @name("parse_ethernet") state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name("parse_info_hdr") state parse_info_hdr {
        pkt.extract(hdr.info_hdr);
        transition parse_recirculate_hdr;
    }
    @name("parse_ipv4") state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w6: parse_tcp;
            8w17: parse_udp;
            default: accept;
        }
    }
    @name("parse_recirculate_hdr") state parse_recirculate_hdr {
        pkt.extract(hdr.recirculate_hdr);
        transition accept;
    }
    @name("parse_tcp") state parse_tcp {
        pkt.extract(hdr.tcp);
        transition select(hdr.tcp.res) {
            3w1: parse_info_hdr;
            default: accept;
        }
    }
    @name("parse_udp") state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            16w8888: parse_info_hdr;
            default: accept;
        }
    }
    @name("start") state __ingress_p4_entry_point {
        transition parse_ethernet;
    }
    @name("$skip_to_packet") state __skip_to_packet {
        pkt.advance(32w0);
        transition __ingress_p4_entry_point;
    }
    @name("$phase0") state __phase0 {
        pkt.advance(32w64);
        transition __skip_to_packet;
    }
    @name("$resubmit") state __resubmit {
        transition __ingress_p4_entry_point;
    }
    @name("$check_resubmit") state __check_resubmit {
        transition select(ig_intr_md.resubmit_flag) {
            1w0 &&& 1w1: __phase0;
            1w1 &&& 1w1: __resubmit;
        }
    }
    @name("$ingress_metadata") state __ingress_metadata {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition __check_resubmit;
    }
    @name("$ingress_tna_entry_point") state start {
        transition __ingress_metadata;
    }
}

parser EgressParserImpl(packet_in pkt, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md, out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser_aux) {
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_info_hdr {
        pkt.extract(hdr.info_hdr);
        transition parse_recirculate_hdr;
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w6: parse_tcp;
            8w17: parse_udp;
            default: accept;
        }
    }
    state parse_recirculate_hdr {
        pkt.extract(hdr.recirculate_hdr);
        transition accept;
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition select(hdr.tcp.res) {
            3w1: parse_info_hdr;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            16w8888: parse_info_hdr;
            default: accept;
        }
    }
    state __egress_p4_entry_point {
        transition parse_ethernet;
    }
    @name("$bridged_metadata") state __bridged_metadata {
        transition __egress_p4_entry_point;
    }
    @name("$parse_ingress_mirror_header_1") state __parse_ingress_mirror_header_1 {
        ig_mirror_header_1_t ingress_mirror_1;
        pkt.extract<ig_mirror_header_1_t>(ingress_mirror_1);
        meta.__bfp4c_compiler_generated_meta.clone_src = 4w1;
        meta.__bfp4c_compiler_generated_meta.mirror_source = 8w9;
        meta.current_node_meta.clone_md = ingress_mirror_1.current_node_meta_clone_md;
        transition __egress_p4_entry_point;
    }
    @name("$mirrored") state __mirrored {
        transition select(pkt.lookahead<bit<8>>()) {
            8w9 &&& 8w31: __parse_ingress_mirror_header_1;
        }
    }
    @name("$check_mirrored") state __check_mirrored {
        transition select(pkt.lookahead<bit<8>>()) {
            8w0 &&& 8w8: __bridged_metadata;
            8w8 &&& 8w8: __mirrored;
        }
    }
    @name("$egress_metadata") state __egress_metadata {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        transition __check_mirrored;
    }
    @name("$egress_tna_entry_point") state start {
        transition __egress_metadata;
    }
}

struct set_ecn_byq_layout { // For dst_up_reg (used in egress)
    bit<32> hi; // Not used in this action
    bit<32> lo; // ECN value (2 or 3)
}

Register<bit<64>, bit<32>>(32w1) dst_up_reg;
control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser_aux, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
     // Register Action to set ECN based on egress queue depth
    RegisterAction<set_ecn_byq_layout, bit<32>, bit<32>>(dst_up_reg) set_ecn_byq_logic = {
        void apply(inout set_ecn_byq_layout reg_value, out bit<32> result) {
            // result = reg_value.lo; // Return current value (or 0 if not needed)
            if (eg_intr_md.deq_qdepth > 2000) { // Threshold queue depth
                reg_value.lo = 3; // Mark Congested (ECN=11)
            } else {
                reg_value.lo = 2; // Mark Not Congested (ECN=10) - if ECT was set
            }
            result = reg_value.lo; // Return the new ECN value
        }
    };

    action set_ecn_by_queue() {
        // Execute the register action and set IPv4 ECN field
        // Only mark if packet is ECN capable (ecn_flag = 1 or 2 initially)
        if (hdr.ipv4.ecn_flag == 1 || hdr.ipv4.ecn_flag == 2) {
           hdr.ipv4.ecn_flag = (bit<2>)set_ecn_byq_logic.execute(0); // Index 0 for the single register entry
        }
    }

    table set_ecn_by_queue_table {
        actions = {
            set_ecn_by_queue;
            NoAction;
        }
        key = {
            hdr.ipv4.protocol: exact; // Apply only to IPv4 packets
        }
        default_action = NoAction; // Don't modify non-IPv4 or non-ECN packets
        size = 1; // Simple table, just triggers the action for IPv4
    }

    apply {
        // If ECN based on queue depth is enabled
        set_ecn_by_queue_table.apply();
    }
}


// MAIN PIPE
// --- Layout Structs for Register Actions ---
// These define the fields within the 64-bit registers used by RegisterActions
// Used by: estimate_total_accepted_rate_2_alu, estimate_total_accepted_rate_alu
struct estimate_total_accepted_rate_2_alu_layout {
    bit<32> hi; // Stored rate or other high-order data
    bit<32> lo; // Timestamp or other low-order data
}

// Used by: estimate_total_aggregate_arrival_rate_alu
struct estimate_total_aggregate_arrival_rate_alu_layout {
    bit<32> hi; // Stored rate or other high-order data
    bit<32> lo; // Timestamp or other low-order data
}

// Used by: get_accepted_rate_alu, get_accepted_rate_times_7_alu, accepted_rate_times_7_alu (recirc)
struct get_accepted_rate_alu_layout {
    bit<32> hi; // Stored rate value
    bit<32> lo; // Temporary calculation value (e.g., for EWMA sum)
}

// Used by: get_aggregate_arrival_rate_alu, get_aggregate_arrival_rate_times_7_alu, aggregate_arrival_rate_times_7_alu (recirc)
struct get_aggregate_arrival_rate_alu_layout {
    bit<32> hi; // Stored rate value
    bit<32> lo; // Temporary calculation value
}

// Used by: get_per_flow_rate_alu, get_per_flow_rate_times_7_alu, label_times_7_alu (recirc)
struct get_per_flow_rate_alu_layout {
    bit<32> hi; // Stored rate value
    bit<32> lo; // Temporary calculation value
}

// Used by: get_total_accepted_rate_alu, get_total_accepted_rate_times_7_alu, total_accepted_rate_times_7_alu (recirc)
struct get_total_accepted_rate_alu_layout {
    bit<32> hi; // Stored rate value
    bit<32> lo; // Temporary calculation value
}

// Used by: get_total_aggregate_arrival_rate_alu, get_total_aggregate_arrival_rate_times_7_alu, total_aggregate_arrival_rate_times_7_alu (recirc)
struct get_total_aggregate_arrival_rate_alu_layout {
    bit<32> hi; // Stored rate value
    bit<32> lo; // Temporary calculation value
}

// Used by: maintain_congest_state_alu, maintain_uncongest_state_alu
struct maintain_congest_state_alu_layout {
    bit<32> hi; // Congestion state flag (e.g., 1=congested)
    bit<32> lo; // Timestamp
}

// Used by: maintain_total_congest_state_alu, maintain_total_uncongest_state_alu
struct maintain_total_congest_state_alu_layout {
    bit<32> hi; // Congestion state flag
    bit<32> lo; // Timestamp
}

// Used by: put_src_up_alu
struct put_src_up_alu_layout {
    bit<32> hi; // Typically total packet length
    bit<32> lo; // Typically weighted or half packet length
}

struct estimate_agg_arrival_rate_layout { // For aggregate_arrival_rate_reg
    bit<32> hi; // Stored rate
    bit<32> lo; // Timestamp
}
struct estimate_per_flow_rate_alu_layout { // For per_flow_rate_reg
    bit<32> hi; // Stored rate
    bit<32> lo; // Timestamp
}
struct estimate_total_accepted_rate_layout { // For total_accepted_rate_reg
    bit<32> hi; // Stored rate
    bit<32> lo; // Timestamp
}
struct estimate_total_agg_arrival_rate_layout { // For total_aggregate_arrival_rate_reg
    bit<32> hi; // Stored rate
    bit<32> lo; // Timestamp
}
struct get_accepted_rate_layout { // For stored_accepted_rate_reg
    bit<32> hi; // Rate value
    bit<32> lo; // Temp calculation value
}
struct get_agg_arrival_rate_layout { // For stored_aggregate_arrival_rate_reg
    bit<32> hi; // Rate value
    bit<32> lo; // Temp calculation value
}
struct get_per_flow_rate_layout { // For stored_per_flow_rate_reg
    bit<32> hi; // Rate value
    bit<32> lo; // Temp calculation value
}
struct get_total_accepted_rate_layout { // For total_stored_accepted_rate_reg
    bit<32> hi; // Rate value
    bit<32> lo; // Temp calculation value
}
struct get_total_agg_arrival_rate_layout { // For total_stored_aggregate_arrival_rate_reg
    bit<32> hi; // Rate value
    bit<32> lo; // Temp calculation value
}
struct maintain_congest_state_layout { // For congest_state_reg
    bit<32> hi; // Congestion state flag (1=congested)
    bit<32> lo; // Timestamp
}
struct maintain_total_congest_state_layout { // For total_congest_state_reg
    bit<32> hi; // Congestion state flag (1=congested)
    bit<32> lo; // Timestamp
}
struct put_src_up_layout { // For src_up_reg
    bit<32> hi; // Total length
    bit<32> lo; // Half length (or weighted length)
}

struct estimate_accepted_rate_2_alu_layout {
    bit<32> hi; // Total length
    bit<32> lo; // Half length (or weighted length)
}

struct estimate_aggregate_arrival_rate_alu_layout {
    bit<32> hi; // Total length
    bit<32> lo; // Half length (or weighted length)
}

@name(".accepted_rate_reg") Register<bit<64>, bit<32>>(32w10) accepted_rate_reg;
@name(".aggregate_arrival_rate_reg") Register<bit<64>, bit<32>>(32w10) aggregate_arrival_rate_reg;
@name(".alpha_reg") Register<bit<32>, bit<32>>(32w10) alpha_reg;
@name(".congest_state_reg") Register<bit<64>, bit<32>>(32w10) congest_state_reg;
@name(".counter_reg") Register<bit<8>, bit<32>>(32w600) counter_reg;
@name(".fraction_factor_reg") Register<bit<16>, bit<32>>(32w1) fraction_factor_reg;
@name(".per_flow_rate_reg") Register<bit<64>, bit<32>>(32w600) per_flow_rate_reg;
@name(".src_up_reg") Register<bit<64>, bit<32>>(32w1) src_up_reg;
@name(".stored_accepted_rate_reg") Register<bit<64>, bit<32>>(32w10) stored_accepted_rate_reg;
@name(".stored_aggregate_arrival_rate_reg") Register<bit<64>, bit<32>>(32w10) stored_aggregate_arrival_rate_reg;
@name(".stored_per_flow_rate_reg") Register<bit<64>, bit<32>>(32w600) stored_per_flow_rate_reg;
@name(".timestamp_reg") Register<bit<32>, bit<32>>(32w1) timestamp_reg;
@name(".tmp_alpha_reg") Register<bit<32>, bit<32>>(32w10) tmp_alpha_reg;
@name(".tmp_total_alpha_reg") Register<bit<32>, bit<32>>(32w1) tmp_total_alpha_reg;
@name(".total_accepted_rate_reg") Register<bit<64>, bit<32>>(32w1) total_accepted_rate_reg;
@name(".total_aggregate_arrival_rate_reg") Register<bit<64>, bit<32>>(32w1) total_aggregate_arrival_rate_reg;
@name(".total_alpha_reg") Register<bit<32>, bit<32>>(32w1) total_alpha_reg;
@name(".total_congest_state_reg") Register<bit<64>, bit<32>>(32w1) total_congest_state_reg;
@name(".total_stored_accepted_rate_reg") Register<bit<64>, bit<32>>(32w1) total_stored_accepted_rate_reg;
@name(".total_stored_aggregate_arrival_rate_reg") Register<bit<64>, bit<32>>(32w1) total_stored_aggregate_arrival_rate_reg;
control main_pipe(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Random<bit<4>>() random_2;
    Random<bit<4>>() random_3;
    @name(".check_total_uncongest_state_0_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_total_alpha_reg) check_total_uncongest_state_0_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = 32w21514000;
        }
    };
    @name(".check_total_uncongest_state_1_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_total_alpha_reg) check_total_uncongest_state_1_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = (bit<32>)hdr.recirculate_hdr.per_tenant_F;
        }
    };
    @name(".check_total_uncongest_state_23_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_total_alpha_reg) check_total_uncongest_state_23_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = 32w21514000;
        }
    };
    @name(".check_uncongest_state_0_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_alpha_reg) check_uncongest_state_0_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = 32w21514000;
        }
    };
    @name(".check_uncongest_state_1_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_alpha_reg) check_uncongest_state_1_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = (bit<32>)hdr.info_hdr.label;
        }
    };
    @name(".check_uncongest_state_23_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_alpha_reg) check_uncongest_state_23_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = 32w21514000;
        }
    };
    @name(".counter_alu") RegisterAction<bit<8>, bit<32>, bit<8>>(counter_reg) counter_alu = {
        void apply(inout bit<8> value, out bit<8> rv) {
            rv = 8w0;
            bit<8> in_value;
            in_value = value;
            if (in_value == 8w24) {
                value = 8w0;
            } else if (!(in_value == 8w24)) {
                value = in_value + 8w1;
            }
            rv = value;
        }
    };
    @name(".estimate_accepted_rate_2_alu") RegisterAction<estimate_accepted_rate_2_alu_layout, bit<32>, bit<32>>(accepted_rate_reg) estimate_accepted_rate_2_alu = {
        void apply(inout estimate_accepted_rate_2_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            estimate_accepted_rate_2_alu_layout in_value;
            in_value = value;
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                rv = in_value.hi;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.lo = in_value.lo;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.hi = in_value.hi;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.hi = 32w0;
            }
        }
    };
    @name(".estimate_accepted_rate_alu") RegisterAction<estimate_accepted_rate_2_alu_layout, bit<32>, bit<32>>(accepted_rate_reg) estimate_accepted_rate_alu = {
        void apply(inout estimate_accepted_rate_2_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            estimate_accepted_rate_2_alu_layout in_value;
            in_value = value;
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                rv = in_value.hi;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.lo = in_value.lo;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.hi = in_value.hi + (bit<32>)meta.meta.halflen;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.hi = 32w0;
            }
        }
    };
    @name(".estimate_aggregate_arrival_rate_alu") RegisterAction<estimate_aggregate_arrival_rate_alu_layout, bit<32>, bit<32>>(aggregate_arrival_rate_reg) estimate_aggregate_arrival_rate_alu = {
        void apply(inout estimate_aggregate_arrival_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            estimate_aggregate_arrival_rate_alu_layout in_value;
            in_value = value;
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                rv = in_value.hi;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.lo = in_value.lo;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.hi = in_value.hi + (bit<32>)meta.meta.halflen;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.hi = 32w0;
            }
        }
    };
    @name(".estimate_per_flow_rate_alu") RegisterAction<estimate_per_flow_rate_alu_layout, bit<32>, bit<32>>(per_flow_rate_reg) estimate_per_flow_rate_alu = {
        void apply(inout estimate_per_flow_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            estimate_per_flow_rate_alu_layout in_value;
            in_value = value;
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w800000)) {
                rv = in_value.hi;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w800000) {
                value.lo = in_value.lo;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w800000)) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w800000) {
                value.hi = in_value.hi + (bit<32>)meta.meta.weight_len;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w800000)) {
                value.hi = 32w0;
            }
        }
    };
    @name(".estimate_total_accepted_rate_2_alu") RegisterAction<estimate_total_accepted_rate_2_alu_layout, bit<32>, bit<32>>(total_accepted_rate_reg) estimate_total_accepted_rate_2_alu = {
        void apply(inout estimate_total_accepted_rate_2_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            estimate_total_accepted_rate_2_alu_layout in_value;
            in_value = value;
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                rv = in_value.hi;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.lo = in_value.lo;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.hi = in_value.hi;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.hi = 32w0;
            }
        }
    };
    @name(".estimate_total_accepted_rate_alu") RegisterAction<estimate_total_accepted_rate_2_alu_layout, bit<32>, bit<32>>(total_accepted_rate_reg) estimate_total_accepted_rate_alu = {
        void apply(inout estimate_total_accepted_rate_2_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            estimate_total_accepted_rate_2_alu_layout in_value;
            in_value = value;
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                rv = in_value.hi;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.lo = in_value.lo;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.hi = in_value.hi + (bit<32>)meta.meta.halflen;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.hi = 32w0;
            }
        }
    };
    @name(".estimate_total_aggregate_arrival_rate_alu") RegisterAction<estimate_total_aggregate_arrival_rate_alu_layout, bit<32>, bit<32>>(total_aggregate_arrival_rate_reg) estimate_total_aggregate_arrival_rate_alu = {
        void apply(inout estimate_total_aggregate_arrival_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            estimate_total_aggregate_arrival_rate_alu_layout in_value;
            in_value = value;
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                rv = in_value.hi;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.lo = in_value.lo;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) {
                value.hi = in_value.hi + (bit<32>)meta.meta.halflen;
            } else if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200)) {
                value.hi = 32w0;
            }
        }
    };
    @name(".get_accepted_rate_alu") RegisterAction<get_accepted_rate_alu_layout, bit<32>, bit<32>>(stored_accepted_rate_reg) get_accepted_rate_alu = {
        void apply(inout get_accepted_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_accepted_rate_alu_layout in_value;
            in_value = value;
            rv = in_value.hi;
        }
    };
    @name(".get_accepted_rate_times_7_alu") RegisterAction<get_accepted_rate_alu_layout, bit<32>, bit<32>>(stored_accepted_rate_reg) get_accepted_rate_times_7_alu = {
        void apply(inout get_accepted_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_accepted_rate_alu_layout in_value;
            in_value = value;
            value.lo = (bit<32>)((bit<32>)in_value.lo + meta.meta.per_tenant_F);
            rv = value.lo;
        }
    };
    @name(".get_aggregate_arrival_rate_alu") RegisterAction<get_aggregate_arrival_rate_alu_layout, bit<32>, bit<32>>(stored_aggregate_arrival_rate_reg) get_aggregate_arrival_rate_alu = {
        void apply(inout get_aggregate_arrival_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_aggregate_arrival_rate_alu_layout in_value;
            in_value = value;
            rv = in_value.hi;
        }
    };
    @name(".get_aggregate_arrival_rate_times_7_alu") RegisterAction<get_aggregate_arrival_rate_alu_layout, bit<32>, bit<32>>(stored_aggregate_arrival_rate_reg) get_aggregate_arrival_rate_times_7_alu = {
        void apply(inout get_aggregate_arrival_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_aggregate_arrival_rate_alu_layout in_value;
            in_value = value;
            value.lo = (bit<32>)((bit<32>)in_value.lo + meta.meta.per_tenant_A);
            rv = value.lo;
        }
    };
    @name(".get_alpha_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(alpha_reg) get_alpha_alu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> in_value;
            in_value = value;
            rv = in_value;
        }
    };
    @name(".get_fraction_factor_alu") RegisterAction<bit<16>, bit<32>, bit<16>>(fraction_factor_reg) get_fraction_factor_alu = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            rv = in_value;
        }
    };
    @name(".get_per_flow_rate_alu") RegisterAction<get_per_flow_rate_alu_layout, bit<32>, bit<32>>(stored_per_flow_rate_reg) get_per_flow_rate_alu = {
        void apply(inout get_per_flow_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_per_flow_rate_alu_layout in_value;
            in_value = value;
            rv = in_value.hi;
        }
    };
    @name(".get_per_flow_rate_times_7_alu") RegisterAction<get_per_flow_rate_alu_layout, bit<32>, bit<32>>(stored_per_flow_rate_reg) get_per_flow_rate_times_7_alu = {
        void apply(inout get_per_flow_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_per_flow_rate_alu_layout in_value;
            in_value = value;
            value.lo = (bit<32>)((bit<32>)in_value.lo + meta.meta.label);
            rv = value.lo;
        }
    };
    @name(".get_time_stamp_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_reg) get_time_stamp_alu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> in_value;
            in_value = value;
            value = (bit<32>)ig_intr_md.ingress_mac_tstamp;
            rv = value;
        }
    };
    @name(".get_total_accepted_rate_alu") RegisterAction<get_total_accepted_rate_alu_layout, bit<32>, bit<32>>(total_stored_accepted_rate_reg) get_total_accepted_rate_alu = {
        void apply(inout get_total_accepted_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_total_accepted_rate_alu_layout in_value;
            in_value = value;
            rv = in_value.hi;
        }
    };
    @name(".get_total_accepted_rate_times_7_alu") RegisterAction<get_total_accepted_rate_alu_layout, bit<32>, bit<32>>(total_stored_accepted_rate_reg) get_total_accepted_rate_times_7_alu = {
        void apply(inout get_total_accepted_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_total_accepted_rate_alu_layout in_value;
            in_value = value;
            value.lo = (bit<32>)((bit<32>)in_value.lo + meta.meta.total_F);
            rv = value.lo;
        }
    };
    @name(".get_total_aggregate_arrival_rate_alu") RegisterAction<get_total_aggregate_arrival_rate_alu_layout, bit<32>, bit<32>>(total_stored_aggregate_arrival_rate_reg) get_total_aggregate_arrival_rate_alu = {
        void apply(inout get_total_aggregate_arrival_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_total_aggregate_arrival_rate_alu_layout in_value;
            in_value = value;
            rv = in_value.hi;
        }
    };
    @name(".get_total_aggregate_arrival_rate_times_7_alu") RegisterAction<get_total_aggregate_arrival_rate_alu_layout, bit<32>, bit<32>>(total_stored_aggregate_arrival_rate_reg) get_total_aggregate_arrival_rate_times_7_alu = {
        void apply(inout get_total_aggregate_arrival_rate_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            get_total_aggregate_arrival_rate_alu_layout in_value;
            in_value = value;
            value.lo = (bit<32>)((bit<32>)in_value.lo + meta.meta.total_A);
            rv = value.lo;
        }
    };
    @name(".get_total_alpha_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(total_alpha_reg) get_total_alpha_alu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> in_value;
            in_value = value;
            if (in_value > 32w115200000) {
                value = 32w115200000;
            }
            rv = value;
        }
    };
    @name(".maintain_congest_state_alu") RegisterAction<maintain_congest_state_alu_layout, bit<32>, bit<32>>(congest_state_reg) maintain_congest_state_alu = {
        void apply(inout maintain_congest_state_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            maintain_congest_state_alu_layout in_value;
            in_value = value;
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) && !(in_value.hi == 32w0)) {
                rv = in_value.hi;
            }
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) || in_value.hi == 32w0) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (in_value.hi == 32w0) {
                value.hi = 32w1;
            }
        }
    };
    @name(".maintain_total_congest_state_alu") RegisterAction<maintain_total_congest_state_alu_layout, bit<32>, bit<32>>(total_congest_state_reg) maintain_total_congest_state_alu = {
        void apply(inout maintain_total_congest_state_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            maintain_total_congest_state_alu_layout in_value;
            in_value = value;
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) && !(in_value.hi == 32w0)) {
                rv = in_value.hi;
            }
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) || in_value.hi == 32w0) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (in_value.hi == 32w0) {
                value.hi = 32w1;
            }
        }
    };
    @name(".maintain_total_uncongest_state_alu") RegisterAction<maintain_total_congest_state_alu_layout, bit<32>, bit<32>>(total_congest_state_reg) maintain_total_uncongest_state_alu = {
        void apply(inout maintain_total_congest_state_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            maintain_total_congest_state_alu_layout in_value;
            in_value = value;
            rv = (bit<32>)this.predicate(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200, in_value.hi > 32w0);
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) || in_value.hi > 32w0) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (in_value.hi > 32w0) {
                value.hi = 32w0;
            }
        }
    };
    @name(".maintain_uncongest_state_alu") RegisterAction<maintain_congest_state_alu_layout, bit<32>, bit<32>>(congest_state_reg) maintain_uncongest_state_alu = {
        void apply(inout maintain_congest_state_alu_layout value, out bit<32> rv) {
            rv = 32w0;
            maintain_congest_state_alu_layout in_value;
            in_value = value;
            rv = (bit<32>)this.predicate(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200, in_value.hi > 32w0);
            if (!(meta.meta.tsp - (bit<32>)in_value.lo < 32w838200) || in_value.hi > 32w0) {
                value.lo = (bit<32>)meta.meta.tsp;
            }
            if (in_value.hi > 32w0) {
                value.hi = 32w0;
            }
        }
    };
    @name(".put_src_up_alu") RegisterAction<put_src_up_alu_layout, bit<32>, bit<32>>(src_up_reg) put_src_up_alu = {
        void apply(inout put_src_up_alu_layout value) {
            put_src_up_alu_layout in_value;
            in_value = value;
            value.lo = (bit<32>)meta.meta.halflen;
            value.hi = (bit<32>)hdr.ipv4.totalLen;
        }
    };
    @name(".add_info_hdr_action") action add_info_hdr_action(bit<16> flow_id, bit<16> tenant_id) {
        hdr.info_hdr.setValid();
        hdr.recirculate_hdr.setValid();
        hdr.info_hdr.label_smaller_than_alpha = 1w0;
        hdr.info_hdr.flow_id = flow_id;
        hdr.info_hdr.tenant_id = tenant_id;
        hdr.info_hdr.recirc_flag = 1w0;
        hdr.info_hdr.update_alpha = 1w0;
        hdr.info_hdr.update_rate = 8w0;
        meta.meta.per_tenant_true_flag = 8w9;
        meta.meta.per_tenant_false_flag = 8w8;
        meta.meta.total_true_flag = 8w20;
        meta.meta.total_false_flag = 8w16;
    }
    @name(".add_info_hdr_default_action") action add_info_hdr_default_action() {
        hdr.info_hdr.setValid();
        hdr.recirculate_hdr.setValid();
        hdr.info_hdr.label_smaller_than_alpha = 1w0;
        hdr.info_hdr.flow_id = 16w99;
        hdr.info_hdr.tenant_id = 16w9;
        hdr.info_hdr.recirc_flag = 1w0;
        hdr.info_hdr.update_alpha = 1w0;
        hdr.info_hdr.update_rate = 8w0;
        meta.meta.per_tenant_true_flag = 8w9;
        meta.meta.per_tenant_false_flag = 8w8;
        meta.meta.total_true_flag = 8w20;
        meta.meta.total_false_flag = 8w16;
    }
    @name(".add_info_hdr_udp_action") action add_info_hdr_udp_action(bit<16> flow_id, bit<16> tenant_id) {
        hdr.info_hdr.setValid();
        hdr.recirculate_hdr.setValid();
        hdr.info_hdr.label_smaller_than_alpha = 1w0;
        hdr.info_hdr.flow_id = flow_id;
        hdr.info_hdr.tenant_id = tenant_id;
        hdr.info_hdr.recirc_flag = 1w0;
        hdr.info_hdr.update_alpha = 1w0;
        hdr.info_hdr.update_rate = 8w0;
        meta.meta.per_tenant_true_flag = 8w9;
        meta.meta.per_tenant_false_flag = 8w8;
        meta.meta.total_true_flag = 8w20;
        meta.meta.total_false_flag = 8w16;
    }
    @name(".add_info_hdr_udp_default_action") action add_info_hdr_udp_default_action() {
        hdr.info_hdr.setValid();
        hdr.recirculate_hdr.setValid();
        hdr.info_hdr.label_smaller_than_alpha = 1w0;
        hdr.info_hdr.flow_id = 16w0;
        hdr.info_hdr.tenant_id = 16w0;
        hdr.info_hdr.recirc_flag = 1w0;
        hdr.info_hdr.update_alpha = 1w0;
        hdr.info_hdr.update_rate = 8w0;
        meta.meta.per_tenant_true_flag = 8w9;
        meta.meta.per_tenant_false_flag = 8w8;
        meta.meta.total_true_flag = 8w20;
        meta.meta.total_false_flag = 8w16;
    }
    @name(".alpha_shl_4_action") action alpha_shl_4_action() {
        meta.meta.alpha_shl_4 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha << 4);
    }
    @name(".alpha_times_15_action") action alpha_times_15_action() {
        meta.meta.alpha_times_15 = (bit<32>)meta.meta.alpha_shl_4 - (bit<32>)hdr.recirculate_hdr.per_tenant_alpha;
    }
    @name(".check_total_uncongest_state_0_action") action check_total_uncongest_state_0_action() {
        check_total_uncongest_state_0_alu.execute(32w0);
        meta.meta.to_resubmit_2 = 2w1;
        hdr.recirculate_hdr.congested = hdr.recirculate_hdr.congested | (bit<8>)meta.meta.total_false_flag;
    }
    @name(".check_total_uncongest_state_23_action") action check_total_uncongest_state_23_action() {
        check_total_uncongest_state_23_alu.execute(32w0);
    }
    @name(".check_total_uncongest_state_1_action") action check_total_uncongest_state_1_action() {
        check_total_uncongest_state_1_alu.execute(32w0);
    }
    @name(".check_uncongest_state_0_action") action check_uncongest_state_0_action() {
        check_uncongest_state_0_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
        meta.meta.to_resubmit = 2w1;
        hdr.recirculate_hdr.congested = hdr.recirculate_hdr.congested | (bit<8>)meta.meta.per_tenant_false_flag;
    }
    @name(".check_uncongest_state_23_action") action check_uncongest_state_23_action() {
        check_uncongest_state_23_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".check_uncongest_state_1_action") action check_uncongest_state_1_action() {
        check_uncongest_state_1_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".counter_action") action counter_action() {
        hdr.info_hdr.update_rate = (bit<8>)counter_alu.execute((bit<32>)hdr.info_hdr.flow_id);
    }
    @name(".div_accepted_rate_action") action div_accepted_rate_action() {
        hdr.recirculate_hdr.per_tenant_F = hdr.recirculate_hdr.per_tenant_F >> 3;
    }
    @name(".div_aggregate_arrival_rate_action") action div_aggregate_arrival_rate_action() {
        hdr.info_hdr.per_tenant_A = hdr.info_hdr.per_tenant_A >> 3;
    }
    @name(".div_per_flow_rate_action") action div_per_flow_rate_action() {
        hdr.info_hdr.label = hdr.info_hdr.label >> 3;
    }
    @name(".div_total_accepted_rate_action") action div_total_accepted_rate_action() {
        hdr.recirculate_hdr.total_F = hdr.recirculate_hdr.total_F >> 3;
    }
    @name(".div_total_aggregate_arrival_rate_action") action div_total_aggregate_arrival_rate_action() {
        hdr.info_hdr.total_A = hdr.info_hdr.total_A >> 3;
        meta.meta.to_resubmit_3 = 2w1;
    }
    @name("._drop") action _drop() {
        ig_intr_md_for_dprsr.drop_ctl = 3w1;
    }
    @name(".estimate_accepted_rate_2_action") action estimate_accepted_rate_2_action() {
        meta.meta.per_tenant_F = (bit<32>)estimate_accepted_rate_2_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".estimate_accepted_rate_action") action estimate_accepted_rate_action() {
        meta.meta.per_tenant_F = (bit<32>)estimate_accepted_rate_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".estimate_aggregate_arrival_rate_action") action estimate_aggregate_arrival_rate_action() {
        meta.meta.per_tenant_A = (bit<32>)estimate_aggregate_arrival_rate_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".estimate_per_flow_rate_action") action estimate_per_flow_rate_action() {
        meta.meta.label = (bit<32>)estimate_per_flow_rate_alu.execute((bit<32>)hdr.info_hdr.flow_id);
    }
    @name(".estimate_total_accepted_rate_2_action") action estimate_total_accepted_rate_2_action() {
        meta.meta.total_F = (bit<32>)estimate_total_accepted_rate_2_alu.execute(32w0);
    }
    @name(".estimate_total_accepted_rate_action") action estimate_total_accepted_rate_action() {
        meta.meta.total_F = (bit<32>)estimate_total_accepted_rate_alu.execute(32w0);
    }
    @name(".estimate_total_aggregate_arrival_rate_action") action estimate_total_aggregate_arrival_rate_action() {
        meta.meta.total_A = (bit<32>)estimate_total_aggregate_arrival_rate_alu.execute(32w0);
    }
    @name(".flowrate_shl_action") action flowrate_shl_action() {
        meta.meta.label_shl_1 = (bit<32>)(hdr.info_hdr.label << 1);
        meta.meta.label_shl_2 = (bit<32>)(hdr.info_hdr.label << 2);
        meta.meta.label_shl_3 = (bit<32>)(hdr.info_hdr.label << 3);
    }
    @name(".flowrate_sum_01_01_action") action flowrate_sum_01_01_action() {
        meta.meta.label_shl_1 = (bit<32>)hdr.info_hdr.label + meta.meta.label_shl_1;
    }
    @name(".flowrate_sum_01_0_action") action flowrate_sum_01_0_action() {
        meta.meta.label_shl_1 = (bit<32>)hdr.info_hdr.label + 32w0;
    }
    @name(".flowrate_sum_01_1_action") action flowrate_sum_01_1_action() {
        meta.meta.label_shl_1 = meta.meta.label_shl_1 + 32w0;
    }
    @name(".flowrate_sum_01_none_action") action flowrate_sum_01_none_action() {
        meta.meta.label_shl_1 = 32w0;
    }
    @name(".flowrate_sum_23_23_action") action flowrate_sum_23_23_action() {
        meta.meta.label_shl_2 = meta.meta.label_shl_2 + (bit<32>)meta.meta.label_shl_3;
    }
    @name(".flowrate_sum_23_2_action") action flowrate_sum_23_2_action() {
        meta.meta.label_shl_2 = meta.meta.label_shl_2 + 32w0;
    }
    @name(".flowrate_sum_23_3_action") action flowrate_sum_23_3_action() {
        meta.meta.label_shl_2 = (bit<32>)meta.meta.label_shl_3 + 32w0;
    }
    @name(".flowrate_sum_23_none_action") action flowrate_sum_23_none_action() {
        meta.meta.label_shl_2 = 32w0;
    }
    @name(".flowrate_times_randv_action") action flowrate_times_randv_action() {
        meta.meta.label_times_randv = (bit<32>)meta.meta.label_shl_1 + (bit<32>)meta.meta.label_shl_2;
    }
    @name(".get_14_alpha_action") action get_14_alpha_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 9);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 10);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 11);
    }
    @name(".get_14_alpha_2_action") action get_14_alpha_2_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 1);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 2);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 3);
    }
    @name(".get_14_alpha_3_action") action get_14_alpha_3_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 2);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 3);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 4);
    }
    @name(".get_14_alpha_4_action") action get_14_alpha_4_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 3);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 4);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 5);
    }
    @name(".get_14_alpha_5_action") action get_14_alpha_5_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 4);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 5);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 6);
    }
    @name(".get_14_alpha_6_action") action get_14_alpha_6_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 5);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 6);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 7);
    }
    @name(".get_14_alpha_7_action") action get_14_alpha_7_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 6);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 7);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 8);
    }
    @name(".get_14_alpha_8_action") action get_14_alpha_8_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 7);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 8);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 9);
    }
    @name(".get_14_alpha_9_action") action get_14_alpha_9_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 9);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 9);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 10);
    }
    @name(".get_14_alpha_10_action") action get_14_alpha_10_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 10);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 10);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 11);
    }
    @name(".get_14_alpha_11_action") action get_14_alpha_11_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 11);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 11);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 12);
    }
    @name(".get_14_alpha_12_action") action get_14_alpha_12_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 11);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 12);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 13);
    }
    @name(".get_14_alpha_13_action") action get_14_alpha_13_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 13);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 13);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 14);
    }
    @name(".get_14_alpha_14_action") action get_14_alpha_14_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 14);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 14);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 15);
    }
    @name(".get_14_alpha_15_action") action get_14_alpha_15_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 14);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 15);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 16);
    }
    @name(".get_14_alpha_16_action") action get_14_alpha_16_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 15);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 16);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 17);
    }
    @name(".get_14_alpha_17_action") action get_14_alpha_17_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 16);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 17);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 18);
    }
    @name(".get_14_alpha_18_action") action get_14_alpha_18_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 17);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 18);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 19);
    }
    @name(".get_14_alpha_19_action") action get_14_alpha_19_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 18);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 19);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 20);
    }
    @name(".get_14_alpha_20_action") action get_14_alpha_20_action() {
        meta.meta.total_alpha_mini = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 19);
        meta.meta.per_tenant_alpha_mini = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 20);
        meta.meta.per_tenant_alpha_mini_w2 = (bit<32>)(hdr.recirculate_hdr.per_tenant_alpha >> 21);
    }
    @name(".get_34_alpha_action") action get_34_alpha_action() {
        hdr.recirculate_hdr.total_alpha = hdr.recirculate_hdr.total_alpha - (bit<32>)meta.meta.total_alpha_mini;
        hdr.recirculate_hdr.per_tenant_alpha = hdr.recirculate_hdr.per_tenant_alpha - (bit<32>)meta.meta.per_tenant_alpha_mini;
    }
    @name(".get_34_alpha_w2_action") action get_34_alpha_w2_action() {
        hdr.recirculate_hdr.total_alpha = hdr.recirculate_hdr.total_alpha - (bit<32>)meta.meta.total_alpha_mini;
        hdr.recirculate_hdr.per_tenant_alpha = hdr.recirculate_hdr.per_tenant_alpha - (bit<32>)meta.meta.per_tenant_alpha_mini_w2;
    }
    @name(".get_accepted_rate_action") action get_accepted_rate_action() {
        hdr.recirculate_hdr.per_tenant_F = (bit<32>)get_accepted_rate_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".get_accepted_rate_times_7_action") action get_accepted_rate_times_7_action() {
        hdr.recirculate_hdr.per_tenant_F = (bit<32>)get_accepted_rate_times_7_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".get_aggregate_arrival_rate_action") action get_aggregate_arrival_rate_action() {
        hdr.info_hdr.per_tenant_A = (bit<32>)get_aggregate_arrival_rate_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".get_aggregate_arrival_rate_times_7_action") action get_aggregate_arrival_rate_times_7_action() {
        hdr.info_hdr.per_tenant_A = (bit<32>)get_aggregate_arrival_rate_times_7_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
        meta.meta.to_resubmit_3 = 2w1;
    }
    @name(".get_alpha_action") action get_alpha_action() {
        hdr.recirculate_hdr.per_tenant_alpha = (bit<32>)get_alpha_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".get_fraction_factor_action") action get_fraction_factor_action() {
        meta.meta.fraction_factor = (bit<16>)get_fraction_factor_alu.execute(32w0);
    }
    @name(".get_half_pktlen_action") action get_half_pktlen_action() {
        meta.meta.weight_len = (bit<16>)(hdr.ipv4.totalLen >> 3);
        meta.meta.halflen = (bit<16>)(hdr.ipv4.totalLen >> 3);
    }
    @name(".get_half_pktlen_w2_action") action get_half_pktlen_w2_action() {
        meta.meta.weight_len = (bit<16>)(hdr.ipv4.totalLen >> 4);
        meta.meta.halflen = (bit<16>)(hdr.ipv4.totalLen >> 3);
        meta.meta.w2 = 2w1;
    }
    @name(".get_half_pktlen_w4_action") action get_half_pktlen_w4_action() {
        meta.meta.weight_len = (bit<16>)(hdr.ipv4.totalLen >> 5);
        meta.meta.halflen = (bit<16>)(hdr.ipv4.totalLen >> 3);
    }
    @name(".get_minv_0_2_action") action get_minv_0_2_action() {
        meta.meta.label_shl_3 = ((bit<32>)hdr.info_hdr.total_A <= 32w115200000 ? (bit<32>)hdr.info_hdr.total_A : 32w115200000);
    }
    @name(".get_minv_0_action") action get_minv_0_action() {
        meta.meta.label = ((bit<32>)hdr.info_hdr.per_tenant_A <= (bit<32>)hdr.recirculate_hdr.total_alpha ? (bit<32>)hdr.info_hdr.per_tenant_A : (bit<32>)hdr.recirculate_hdr.total_alpha);
    }
    @name(".get_minv_action") action get_minv_action() {
        meta.meta.min_alphatimes15_labeltimesrand = ((bit<32>)meta.meta.alpha_times_15 <= (bit<32>)meta.meta.label_times_randv ? (bit<32>)meta.meta.alpha_times_15 : (bit<32>)meta.meta.label_times_randv);
    }
    @name(".get_per_flow_rate_action") action get_per_flow_rate_action() {
        hdr.info_hdr.label = (bit<32>)get_per_flow_rate_alu.execute((bit<32>)hdr.info_hdr.flow_id);
    }
    @name(".get_per_flow_rate_times_7_action") action get_per_flow_rate_times_7_action() {
        hdr.info_hdr.label = (bit<32>)get_per_flow_rate_times_7_alu.execute((bit<32>)hdr.info_hdr.flow_id);
        meta.meta.to_resubmit_3 = 2w1;
    }
    @name(".get_random_value_action") action get_random_value_action() {
        {
            random_2.get();
        }
        {
            random_3.get();
        }
    }
    @name(".get_time_stamp_action") action get_time_stamp_action() {
        meta.meta.tsp = (bit<32>)get_time_stamp_alu.execute(32w0);
    }
    @name(".get_total_accepted_rate_action") action get_total_accepted_rate_action() {
        hdr.recirculate_hdr.total_F = (bit<32>)get_total_accepted_rate_alu.execute(32w0);
    }
    @name(".get_total_accepted_rate_times_7_action") action get_total_accepted_rate_times_7_action() {
        hdr.recirculate_hdr.total_F = (bit<32>)get_total_accepted_rate_times_7_alu.execute(32w0);
    }
    @name(".get_total_aggregate_arrival_rate_action") action get_total_aggregate_arrival_rate_action() {
        hdr.info_hdr.total_A = (bit<32>)get_total_aggregate_arrival_rate_alu.execute(32w0);
    }
    @name(".get_total_aggregate_arrival_rate_times_7_action") action get_total_aggregate_arrival_rate_times_7_action() {
        hdr.info_hdr.total_A = (bit<32>)get_total_aggregate_arrival_rate_times_7_alu.execute(32w0);
    }
    @name(".get_total_alpha_action") action get_total_alpha_action() {
        hdr.recirculate_hdr.total_alpha = (bit<32>)get_total_alpha_alu.execute(32w0);
    }
    @name(".i2e_mirror_action") action i2e_mirror_action(bit<32> mirror_id) {
        meta.current_node_meta.clone_md = 8w1;
        {
            ig_intr_md_for_dprsr.mirror_type = (bit<3>)3w1;
            meta.__bfp4c_compiler_generated_meta.mirror_id = (bit<10>)mirror_id;
            meta.__bfp4c_compiler_generated_meta.mirror_source = 8w9;
        }
    }
    @name(".set_egress") action set_egress(bit<9> egress_spec) {
        ig_intr_md_for_tm.ucast_egress_port = egress_spec;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 8w1;
    }
    @name(".set_egress_3_udp") action set_egress_3_udp(bit<9> egress_spec) {
        hdr.recirculate_hdr.setInvalid();
        hdr.info_hdr.setInvalid();
        ig_intr_md_for_tm.ucast_egress_port = egress_spec;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 8w1;
    }
    @name(".set_egress_3") action set_egress_3(bit<9> egress_spec) {
        hdr.recirculate_hdr.setInvalid();
        hdr.info_hdr.setInvalid();
        ig_intr_md_for_tm.ucast_egress_port = egress_spec;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 8w1;
    }
    @name(".maintain_congest_state_action") action maintain_congest_state_action() {
        meta.meta.to_resubmit = (bit<2>)maintain_congest_state_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
        hdr.recirculate_hdr.congested = hdr.recirculate_hdr.congested | (bit<8>)meta.meta.per_tenant_true_flag;
    }
    @name(".maintain_total_congest_state_action") action maintain_total_congest_state_action() {
        meta.meta.to_resubmit_2 = (bit<2>)maintain_total_congest_state_alu.execute(32w0);
        hdr.recirculate_hdr.congested = hdr.recirculate_hdr.congested | (bit<8>)meta.meta.total_true_flag;
    }
    @name(".maintain_total_uncongest_state_action") action maintain_total_uncongest_state_action() {
        meta.meta.total_uncongest_state_predicate = (bit<4>)maintain_total_uncongest_state_alu.execute(32w0);
    }
    @name(".maintain_uncongest_state_action") action maintain_uncongest_state_action() {
        meta.meta.uncongest_state_predicate = (bit<4>)maintain_uncongest_state_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".mod_resubmit_field_action") action mod_resubmit_field_action() {
        hdr.recirculate_hdr.to_drop = (bit<8>)meta.meta.to_drop;
    }
    @name(".put_src_up_action") action put_src_up_action() {
        put_src_up_alu.execute(32w0);
    }
    @name(".resubmit_action") action resubmit_action() {
        {
            ig_intr_md_for_tm.ucast_egress_port[6:0] = 7w68;
            ig_intr_md_for_tm.ucast_egress_port[8:7] = ig_intr_md.ingress_port[8:7];
        }
    }
    @name(".set_drop_action") action set_drop_action() {
        meta.meta.to_drop = 4w1;
    }
    @name(".set_tcp_flag_action") action set_tcp_flag_action() {
        hdr.tcp.res = 3w1;
    }
    @name(".set_udp_flag_action") action set_udp_flag_action() {
        hdr.udp.dstPort = 16w8888;
    }
    @name(".sum_accepted_rate_action") action sum_accepted_rate_action() {
        meta.meta.to_resubmit_3 = 2w1;
    }
    @name(".sum_total_accepted_rate_action") action sum_total_accepted_rate_action() {
        meta.meta.to_resubmit = 2w1;
    }
    @stage(0) @name(".add_info_hdr_table") table add_info_hdr_table {
        actions = {
            add_info_hdr_action();
            add_info_hdr_default_action();
        }
        key = {
            hdr.ipv4.srcAddr: exact;
            hdr.tcp.dstPort : exact;
        }
        default_action = add_info_hdr_default_action();
    }
    @stage(0) @name(".add_info_hdr_udp_table") table add_info_hdr_udp_table {
        actions = {
            add_info_hdr_udp_action();
            add_info_hdr_udp_default_action();
        }
        key = {
            hdr.ipv4.srcAddr: exact;
            hdr.udp.dstPort : exact;
        }
        default_action = add_info_hdr_udp_default_action();
    }
    @stage(5) @name(".alpha_shl_4_table") table alpha_shl_4_table {
        actions = {
            alpha_shl_4_action();
        }
        default_action = alpha_shl_4_action();
    }
    @stage(6) @name(".alpha_times_15_table") table alpha_times_15_table {
        actions = {
            alpha_times_15_action();
        }
        default_action = alpha_times_15_action();
    }
    @stage(9) @name(".check_total_uncongest_state_table") table check_total_uncongest_state_table {
        actions = {
            check_total_uncongest_state_0_action();
            check_total_uncongest_state_23_action();
            check_total_uncongest_state_1_action();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.total_uncongest_state_predicate: exact;
        }
        default_action = NoAction();
    }
    @stage(8) @name(".check_uncongest_state_table") table check_uncongest_state_table {
        actions = {
            check_uncongest_state_0_action();
            check_uncongest_state_23_action();
            check_uncongest_state_1_action();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.uncongest_state_predicate: exact;
        }
        default_action = NoAction();
    }
    @stage(5) @name(".counter_table") table counter_table {
        actions = {
            counter_action();
        }
        default_action = counter_action();
    }
    @stage(11) @name(".div_accepted_rate_table") table div_accepted_rate_table {
        actions = {
            div_accepted_rate_action();
        }
        default_action = div_accepted_rate_action();
    }
    @stage(4) @name(".div_aggregate_arrival_rate_table") table div_aggregate_arrival_rate_table {
        actions = {
            div_aggregate_arrival_rate_action();
        }
        default_action = div_aggregate_arrival_rate_action();
    }
    @stage(3) @name(".div_per_flow_rate_table") table div_per_flow_rate_table {
        actions = {
            div_per_flow_rate_action();
        }
        default_action = div_per_flow_rate_action();
    }
    @stage(11) @name(".div_total_accepted_rate_table") table div_total_accepted_rate_table {
        actions = {
            div_total_accepted_rate_action();
        }
        default_action = div_total_accepted_rate_action();
    }
    @stage(4) @name(".div_total_aggregate_arrival_rate_table") table div_total_aggregate_arrival_rate_table {
        actions = {
            div_total_aggregate_arrival_rate_action();
        }
        default_action = div_total_aggregate_arrival_rate_action();
    }
    @name(".drop_packet_table") table drop_packet_table {
        actions = {
            _drop();
        }
        default_action = _drop();
    }
    @stage(8) @name(".estimate_accepted_rate_2_table") table estimate_accepted_rate_2_table {
        actions = {
            estimate_accepted_rate_2_action();
        }
        default_action = estimate_accepted_rate_2_action();
    }
    @stage(8) @name(".estimate_accepted_rate_table") table estimate_accepted_rate_table {
        actions = {
            estimate_accepted_rate_action();
        }
        default_action = estimate_accepted_rate_action();
    }
    @stage(2) @name(".estimate_aggregate_arrival_rate_table") table estimate_aggregate_arrival_rate_table {
        actions = {
            estimate_aggregate_arrival_rate_action();
        }
        default_action = estimate_aggregate_arrival_rate_action();
    }
    @stage(1) @name(".estimate_per_flow_rate_table") table estimate_per_flow_rate_table {
        actions = {
            estimate_per_flow_rate_action();
        }
        default_action = estimate_per_flow_rate_action();
    }
    @stage(8) @name(".estimate_total_accepted_rate_2_table") table estimate_total_accepted_rate_2_table {
        actions = {
            estimate_total_accepted_rate_2_action();
        }
        default_action = estimate_total_accepted_rate_2_action();
    }
    @stage(8) @name(".estimate_total_accepted_rate_table") table estimate_total_accepted_rate_table {
        actions = {
            estimate_total_accepted_rate_action();
        }
        default_action = estimate_total_accepted_rate_action();
    }
    @stage(2) @name(".estimate_total_aggregate_arrival_rate_table") table estimate_total_aggregate_arrival_rate_table {
        actions = {
            estimate_total_aggregate_arrival_rate_action();
        }
        default_action = estimate_total_aggregate_arrival_rate_action();
    }
    @stage(4) @name(".flowrate_shl_table") table flowrate_shl_table {
        actions = {
            flowrate_shl_action();
        }
        default_action = flowrate_shl_action();
    }
    @stage(5) @name(".flowrate_sum_01_table") table flowrate_sum_01_table {
        actions = {
            flowrate_sum_01_01_action();
            flowrate_sum_01_0_action();
            flowrate_sum_01_1_action();
            flowrate_sum_01_none_action();
        }
        key = {
            meta.meta.randv: ternary;
        }
        default_action = flowrate_sum_01_none_action();
    }
    @stage(5) @name(".flowrate_sum_23_table") table flowrate_sum_23_table {
        actions = {
            flowrate_sum_23_23_action();
            flowrate_sum_23_2_action();
            flowrate_sum_23_3_action();
            flowrate_sum_23_none_action();
        }
        key = {
            meta.meta.randv: ternary;
        }
        default_action = flowrate_sum_23_none_action();
    }
    @stage(6) @name(".flowrate_times_randv_table") table flowrate_times_randv_table {
        actions = {
            flowrate_times_randv_action();
        }
        default_action = flowrate_times_randv_action();
    }
    @stage(8) @name(".get_14_alpha_table") table get_14_alpha_table {
        actions = {
            get_14_alpha_action();
            get_14_alpha_2_action();
            get_14_alpha_3_action();
            get_14_alpha_4_action();
            get_14_alpha_5_action();
            get_14_alpha_6_action();
            get_14_alpha_7_action();
            get_14_alpha_8_action();
            get_14_alpha_9_action();
            get_14_alpha_10_action();
            get_14_alpha_11_action();
            get_14_alpha_12_action();
            get_14_alpha_13_action();
            get_14_alpha_14_action();
            get_14_alpha_15_action();
            get_14_alpha_16_action();
            get_14_alpha_17_action();
            get_14_alpha_18_action();
            get_14_alpha_19_action();
            get_14_alpha_20_action();
        }
        key = {
            meta.meta.fraction_factor: exact;
        }
        default_action = get_14_alpha_action();
    }
    @stage(10) @name(".get_34_alpha_table") table get_34_alpha_table {
        actions = {
            get_34_alpha_action();
            get_34_alpha_w2_action();
        }
        key = {
            meta.meta.w2: exact;
        }
        default_action = get_34_alpha_action();
    }
    @stage(10) @name(".get_accepted_rate_table") table get_accepted_rate_table {
        actions = {
            get_accepted_rate_action();
        }
        default_action = get_accepted_rate_action();
    }
    @stage(10) @name(".get_accepted_rate_times_7_table") table get_accepted_rate_times_7_table {
        actions = {
            get_accepted_rate_times_7_action();
        }
        default_action = get_accepted_rate_times_7_action();
    }
    @stage(3) @name(".get_aggregate_arrival_rate_table") table get_aggregate_arrival_rate_table {
        actions = {
            get_aggregate_arrival_rate_action();
        }
        default_action = get_aggregate_arrival_rate_action();
    }
    @stage(3) @name(".get_aggregate_arrival_rate_times_7_table") table get_aggregate_arrival_rate_times_7_table {
        actions = {
            get_aggregate_arrival_rate_times_7_action();
        }
        default_action = get_aggregate_arrival_rate_times_7_action();
    }
    @stage(4) @name(".get_alpha_table") table get_alpha_table {
        actions = {
            get_alpha_action();
        }
        default_action = get_alpha_action();
    }
    @stage(1) @name(".get_fraction_factor_table") table get_fraction_factor_table {
        actions = {
            get_fraction_factor_action();
        }
        default_action = get_fraction_factor_action();
    }
    @stage(0) @name(".get_half_pktlen_table") table get_half_pktlen_table {
        actions = {
            get_half_pktlen_action();
            get_half_pktlen_w2_action();
            get_half_pktlen_w4_action();
        }
        key = {
            hdr.ipv4.srcAddr: exact;
        }
        default_action = get_half_pktlen_action();
    }
    @stage(5) @name(".get_minv_0_2_table") table get_minv_0_2_table {
        actions = {
            get_minv_0_2_action();
        }
        default_action = get_minv_0_2_action();
    }
    @stage(5) @name(".get_minv_0_table") table get_minv_0_table {
        actions = {
            get_minv_0_action();
        }
        default_action = get_minv_0_action();
    }
    @stage(7) @name(".get_minv_table") table get_minv_table {
        actions = {
            get_minv_action();
        }
        default_action = get_minv_action();
    }
    @stage(2) @name(".get_per_flow_rate_table") table get_per_flow_rate_table {
        actions = {
            get_per_flow_rate_action();
        }
        default_action = get_per_flow_rate_action();
    }
    @stage(2) @name(".get_per_flow_rate_times_7_table") table get_per_flow_rate_times_7_table {
        actions = {
            get_per_flow_rate_times_7_action();
        }
        default_action = get_per_flow_rate_times_7_action();
    }
    @stage(0) @name(".get_random_value_table") table get_random_value_table {
        actions = {
            get_random_value_action();
        }
        default_action = get_random_value_action();
    }
    @stage(0) @name(".get_time_stamp_table") table get_time_stamp_table {
        actions = {
            get_time_stamp_action();
        }
        default_action = get_time_stamp_action();
    }
    @stage(10) @name(".get_total_accepted_rate_table") table get_total_accepted_rate_table {
        actions = {
            get_total_accepted_rate_action();
        }
        default_action = get_total_accepted_rate_action();
    }
    @stage(10) @name(".get_total_accepted_rate_times_7_table") table get_total_accepted_rate_times_7_table {
        actions = {
            get_total_accepted_rate_times_7_action();
        }
        default_action = get_total_accepted_rate_times_7_action();
    }
    @stage(3) @name(".get_total_aggregate_arrival_rate_table") table get_total_aggregate_arrival_rate_table {
        actions = {
            get_total_aggregate_arrival_rate_action();
        }
        default_action = get_total_aggregate_arrival_rate_action();
    }
    @stage(3) @name(".get_total_aggregate_arrival_rate_times_7_table") table get_total_aggregate_arrival_rate_times_7_table {
        actions = {
            get_total_aggregate_arrival_rate_times_7_action();
        }
        default_action = get_total_aggregate_arrival_rate_times_7_action();
    }
    @stage(0) @name(".get_total_alpha_table") table get_total_alpha_table {
        actions = {
            get_total_alpha_action();
        }
        default_action = get_total_alpha_action();
    }
    @name(".i2e_mirror_table") table i2e_mirror_table {
        actions = {
            i2e_mirror_action();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        default_action = NoAction();
    }
    @stage(10) @name(".ipv4_route_2") table ipv4_route_2 {
        actions = {
            set_egress();
            _drop();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        size = 8192;
        default_action = NoAction();
    }
    @stage(11) @name(".ipv4_route_3") table ipv4_route_3 {
        actions = {
            set_egress_3_udp();
            set_egress_3();
            _drop();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.dstAddr : exact;
            hdr.ipv4.protocol: exact;
        }
        size = 8192;
        default_action = NoAction();
    }
    @stage(6) @name(".maintain_congest_state_table") table maintain_congest_state_table {
        actions = {
            maintain_congest_state_action();
        }
        default_action = maintain_congest_state_action();
    }
    @stage(7) @name(".maintain_total_congest_state_table") table maintain_total_congest_state_table {
        actions = {
            maintain_total_congest_state_action();
        }
        default_action = maintain_total_congest_state_action();
    }
    @stage(7) @name(".maintain_total_uncongest_state_table") table maintain_total_uncongest_state_table {
        actions = {
            maintain_total_uncongest_state_action();
        }
        default_action = maintain_total_uncongest_state_action();
    }
    @stage(6) @name(".maintain_uncongest_state_table") table maintain_uncongest_state_table {
        actions = {
            maintain_uncongest_state_action();
        }
        default_action = maintain_uncongest_state_action();
    }
    @stage(10) @name(".mod_resubmit_field_table") table mod_resubmit_field_table {
        actions = {
            mod_resubmit_field_action();
        }
        default_action = mod_resubmit_field_action();
    }
    @name(".put_src_up_table") table put_src_up_table {
        actions = {
            put_src_up_action();
        }
        default_action = put_src_up_action();
    }
    @name(".resubmit_2_table") table resubmit_2_table {
        actions = {
            resubmit_action();
        }
        default_action = resubmit_action();
    }
    @stage(11) @name(".resubmit_table") table resubmit_table {
        actions = {
            resubmit_action();
        }
        default_action = resubmit_action();
    }
    @stage(8) @name(".set_drop_table") table set_drop_table {
        actions = {
            set_drop_action();
        }
        default_action = set_drop_action();
    }
    @stage(10) @name(".set_flag_table") table set_flag_table {
        actions = {
            set_tcp_flag_action();
            set_udp_flag_action();
        }
        key = {
            hdr.ipv4.protocol: exact;
        }
        default_action = set_tcp_flag_action();
    }
    @stage(9) @name(".sum_accepted_rate_table") table sum_accepted_rate_table {
        actions = {
            sum_accepted_rate_action();
        }
        default_action = sum_accepted_rate_action();
    }
    @stage(9) @name(".sum_total_accepted_rate_table") table sum_total_accepted_rate_table {
        actions = {
            sum_total_accepted_rate_action();
        }
        default_action = sum_total_accepted_rate_action();
    }
    apply {
        get_time_stamp_table.apply();
        get_random_value_table.apply();
        if (hdr.tcp.isValid()) {
            add_info_hdr_table.apply();
        } else {
            add_info_hdr_udp_table.apply();
        }
        get_total_alpha_table.apply();
        get_half_pktlen_table.apply();
        estimate_per_flow_rate_table.apply();
        put_src_up_table.apply();
        get_fraction_factor_table.apply();
        estimate_aggregate_arrival_rate_table.apply();
        estimate_total_aggregate_arrival_rate_table.apply();
        if (meta.meta.label == 32w0) {
            get_per_flow_rate_table.apply();
        } else {
            get_per_flow_rate_times_7_table.apply();
        }
        if (meta.meta.label != 32w0) {
            div_per_flow_rate_table.apply();
        }
        if (meta.meta.per_tenant_A == 32w0) {
            get_aggregate_arrival_rate_table.apply();
        } else {
            get_aggregate_arrival_rate_times_7_table.apply();
        }
        if (meta.meta.total_A == 32w0) {
            get_total_aggregate_arrival_rate_table.apply();
        } else {
            get_total_aggregate_arrival_rate_times_7_table.apply();
        }
        get_alpha_table.apply();
        flowrate_shl_table.apply();
        if (meta.meta.per_tenant_A != 32w0) {
            div_aggregate_arrival_rate_table.apply();
        }
        if (meta.meta.total_A != 32w0) {
            div_total_aggregate_arrival_rate_table.apply();
        }
        alpha_shl_4_table.apply();
        flowrate_sum_01_table.apply();
        flowrate_sum_23_table.apply();
        counter_table.apply();
        get_minv_0_table.apply();
        get_minv_0_2_table.apply();
        flowrate_times_randv_table.apply();
        alpha_times_15_table.apply();
        if ((bit<32>)meta.meta.label == hdr.recirculate_hdr.total_alpha) {
            maintain_congest_state_table.apply();
        } else {
            maintain_uncongest_state_table.apply();
        }
        get_minv_table.apply();
        if (meta.meta.label_shl_3 == 32w115200000) {
            maintain_total_congest_state_table.apply();
        } else {
            maintain_total_uncongest_state_table.apply();
        }
        if ((bit<32>)meta.meta.min_alphatimes15_labeltimesrand == meta.meta.label_times_randv) {
            estimate_accepted_rate_table.apply();
            estimate_total_accepted_rate_table.apply();
        } else {
            set_drop_table.apply();
            estimate_accepted_rate_2_table.apply();
            estimate_total_accepted_rate_2_table.apply();
        }
        get_14_alpha_table.apply();
        if ((bit<32>)meta.meta.label != hdr.recirculate_hdr.total_alpha) {
            check_uncongest_state_table.apply();
        }
        if (meta.meta.per_tenant_F != 32w0) {
            sum_accepted_rate_table.apply();
        }
        if (meta.meta.total_F != 32w0) {
            sum_total_accepted_rate_table.apply();
        }
        if (meta.meta.label_shl_3 != 32w115200000) {
            check_total_uncongest_state_table.apply();
        }
        if (meta.meta.per_tenant_F == 32w0) {
            get_accepted_rate_table.apply();
        } else {
            get_accepted_rate_times_7_table.apply();
        }
        if (meta.meta.total_F == 32w0) {
            get_total_accepted_rate_table.apply();
        } else {
            get_total_accepted_rate_times_7_table.apply();
        }
        get_34_alpha_table.apply();
        mod_resubmit_field_table.apply();
        if (meta.meta.to_resubmit != 2w0 || meta.meta.to_resubmit_2 != 2w0 || meta.meta.to_resubmit_3 != 2w0) {
            set_flag_table.apply();
        }
        ipv4_route_2.apply();
        if (meta.meta.per_tenant_F != 32w0) {
            div_accepted_rate_table.apply();
        }
        if (meta.meta.total_F != 32w0) {
            div_total_accepted_rate_table.apply();
        }
        if (meta.meta.to_resubmit != 2w0 || meta.meta.to_resubmit_2 != 2w0 || meta.meta.to_resubmit_3 != 2w0) {
            if (meta.meta.to_drop == 4w0) {
                i2e_mirror_table.apply();
                resubmit_table.apply();
            } else {
                resubmit_2_table.apply();
            }
        } else {
            if (meta.meta.to_drop == 4w0) {
                ipv4_route_3.apply();
            } else {
                drop_packet_table.apply();
            }
        }
    }
}

Register<bit<32>, bit<32>>(32w1) delta_c_reg;
control recirc_pipe(inout headers hdr, inout metadata meta, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    MathUnit<bit<32>>(false, (int<2>)0, (int<6>)-3, { (bit<8>)111, (bit<8>)104, (bit<8>)96, (bit<8>)89, (bit<8>)81, (bit<8>)74, (bit<8>)66, (bit<8>)59, (bit<8>)52, (bit<8>)44, (bit<8>)37, (bit<8>)29, (bit<8>)22, (bit<8>)14, (bit<8>)7, (bit<8>)0 }) accepted_rate_times_7_alu_math_unit_0;
    RegisterAction<get_accepted_rate_alu_layout, bit<32>, bit<32>>(stored_accepted_rate_reg) accepted_rate_times_7_alu = {
        void apply(inout get_accepted_rate_alu_layout value, out bit<32> rv) {
            // Calculate the result using MathUnit and assign to the output parameter rv

            value.hi = hdr.recirculate_hdr.per_tenant_F;
            value.lo = meta.temp;
             // Update the primary state field (hi) as before
           // Do NOT assign the MathUnit result directly to value.lo
        }
    };
    MathUnit<bit<32>>(false, (int<2>)0, (int<6>)-3, { (bit<8>)111, (bit<8>)104, (bit<8>)96, (bit<8>)89, (bit<8>)81, (bit<8>)74, (bit<8>)66, (bit<8>)59, (bit<8>)52, (bit<8>)44, (bit<8>)37, (bit<8>)29, (bit<8>)22, (bit<8>)14, (bit<8>)7, (bit<8>)0 }) aggregate_arrival_rate_times_7_alu_math_unit_0;
    RegisterAction<get_aggregate_arrival_rate_alu_layout, bit<32>, bit<32>>(stored_aggregate_arrival_rate_reg) aggregate_arrival_rate_times_7_alu = {
        void apply(inout get_aggregate_arrival_rate_alu_layout value, out bit<32> rv) {
            // Calculate the result using MathUnit and assign to the output parameter rv
            // Update the primary state field (hi) as before
            
            value.hi = hdr.info_hdr.per_tenant_A;
            value.lo = meta.temp;
            // Do NOT assign the MathUnit result directly to value.lo
        }
    };
    MathUnit<bit<32>>(false, (int<2>)0, (int<6>)-3, { (bit<8>)111, (bit<8>)104, (bit<8>)96, (bit<8>)89, (bit<8>)81, (bit<8>)74, (bit<8>)66, (bit<8>)59, (bit<8>)52, (bit<8>)44, (bit<8>)37, (bit<8>)29, (bit<8>)22, (bit<8>)14, (bit<8>)7, (bit<8>)0 }) label_times_7_alu_math_unit_0;
    RegisterAction<get_per_flow_rate_alu_layout, bit<32>, bit<32>>(stored_per_flow_rate_reg) label_times_7_alu = {
        void apply(inout get_per_flow_rate_alu_layout value, out bit<32> rv) {
            // 1. Execute MathUnit, store result in a temporary variable
            
            value.hi = hdr.info_hdr.label;
            value.lo = meta.temp;

            // 2. Update register state (value.hi) as before
            // If value.lo was intended to hold this intermediate result, assign it here:
            // value.lo = math_result; // Optional, depending on register layout usage

         }
    };
    @name(".total_accepted_rate_times_7_alu_math_unit_0") MathUnit<bit<32>>(false, (int<2>)0, (int<6>)-3, { (bit<8>)111, (bit<8>)104, (bit<8>)96, (bit<8>)89, (bit<8>)81, (bit<8>)74, (bit<8>)66, (bit<8>)59, (bit<8>)52, (bit<8>)44, (bit<8>)37, (bit<8>)29, (bit<8>)22, (bit<8>)14, (bit<8>)7, (bit<8>)0 }) total_accepted_rate_times_7_alu_math_unit_0;
    RegisterAction<get_total_accepted_rate_alu_layout, bit<32>, bit<32>>(total_stored_accepted_rate_reg) total_accepted_rate_times_7_alu = {
        void apply(inout get_total_accepted_rate_alu_layout value, out bit<32> rv) {
            // Calculate the result using MathUnit and assign to the output parameter rv
            
            value.hi = hdr.recirculate_hdr.total_F;
            value.lo = meta.temp;
            // Update the primary state field (hi) as before
            // Do NOT assign the MathUnit result directly to value.lo
        }
    };
    @name(".total_aggregate_arrival_rate_times_7_alu_math_unit_0") MathUnit<bit<32>>(false, (int<2>)0, (int<6>)-3, { (bit<8>)111, (bit<8>)104, (bit<8>)96, (bit<8>)89, (bit<8>)81, (bit<8>)74, (bit<8>)66, (bit<8>)59, (bit<8>)52, (bit<8>)44, (bit<8>)37, (bit<8>)29, (bit<8>)22, (bit<8>)14, (bit<8>)7, (bit<8>)0 }) total_aggregate_arrival_rate_times_7_alu_math_unit_0;
    RegisterAction<get_total_aggregate_arrival_rate_alu_layout, bit<32>, bit<32>>(total_stored_aggregate_arrival_rate_reg) total_aggregate_arrival_rate_times_7_alu = {
        void apply(inout get_total_aggregate_arrival_rate_alu_layout value, out bit<32> rv) {
            // Calculate the result using MathUnit and assign to the output parameter rv
            
            value.hi = hdr.info_hdr.total_A;
            value.lo = meta.temp;
            // Update the primary state field (hi) as before
            // Do NOT assign the MathUnit result directly to value.lo
        }
    };

    @name(".get_delta_c_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(delta_c_reg) get_delta_c_alu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> in_value;
            in_value = value;
            rv = in_value;
        }
    };

    @name(".update_per_tenant_alpha_by_F1_minus_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(alpha_reg) update_per_tenant_alpha_by_F1_minus_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = (bit<32>)hdr.recirculate_hdr.per_tenant_alpha;
        }
    };
    @name(".update_per_tenant_alpha_by_F1_plus_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(alpha_reg) update_per_tenant_alpha_by_F1_plus_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            if ((bit<32>)in_value + meta.meta.delta_total_alpha <= 32w115200000) {
                value = (bit<32>)((bit<32>)in_value + meta.meta.delta_total_alpha);
            } else if (!((bit<32>)in_value + meta.meta.delta_total_alpha <= 32w115200000)) {
                value = 32w115200000;
            }
        }
    };
    @name(".update_per_tenant_alpha_to_maxalpha_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(alpha_reg) update_per_tenant_alpha_to_maxalpha_alu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            if (in_value <= 32w115200000) {
                value = (bit<32>)((bit<32>)in_value + meta.meta.delta_total_alpha);
            }
        }
    };
    @name(".update_total_alpha_by_F0_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(total_alpha_reg) update_total_alpha_by_F0_alu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> in_value;
            in_value = value;
            if (hdr.recirculate_hdr.total_F > 32w115200000) {
                value = (bit<32>)hdr.recirculate_hdr.total_alpha;
            } else if (!(hdr.recirculate_hdr.total_F > 32w115200000)) {
                value = in_value + 32w400;
            }
            rv = value;
        }
    };
    @name(".update_total_alpha_to_maxalpha_alu") RegisterAction<bit<32>, bit<32>, bit<32>>(total_alpha_reg) update_total_alpha_to_maxalpha_alu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> in_value;
            in_value = value;
            if (!(hdr.recirculate_hdr.total_F > 32w115200000)) {
                value = in_value + 32w400;
            }
            rv = value;
        }
    };
    @name("._drop") action _drop() {
        ig_intr_md_for_dprsr.drop_ctl = 3w1;
    }
    @name(".get_delta_c_action") action get_delta_c_action() {
        meta.meta.delta_c = (bit<32>)get_delta_c_alu.execute(32w0);
    }
    @name(".get_delta_total_alpha_action") action get_delta_total_alpha_action() {
        meta.meta.delta_total_alpha = (bit<32>)(hdr.recirculate_hdr.total_alpha >> 13);
    }
    @name(".get_min_of_pertenantF_total_alpha_action") action get_min_of_pertenantF_total_alpha_action() {
        meta.meta.min_pertenantF_totalalpha = ((bit<32>)hdr.recirculate_hdr.per_tenant_F <= (bit<32>)hdr.recirculate_hdr.total_alpha ? (bit<32>)hdr.recirculate_hdr.per_tenant_F : (bit<32>)hdr.recirculate_hdr.total_alpha);
    }
    @name(".getmin_delta_total_alpha_action") action getmin_delta_total_alpha_action() {
        meta.meta.delta_total_alpha = (meta.meta.delta_total_alpha <= (bit<32>)meta.meta.delta_c ? meta.meta.delta_total_alpha : (bit<32>)meta.meta.delta_c);
    }
    @name(".set_average_accepted_rate_action") action set_average_accepted_rate_action() {
        accepted_rate_times_7_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".set_average_aggregate_arrival_rate_action") action set_average_aggregate_arrival_rate_action() {
        aggregate_arrival_rate_times_7_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".set_average_per_flow_rate_action") action set_average_per_flow_rate_action() {
        label_times_7_alu.execute((bit<32>)hdr.info_hdr.flow_id);
    }
    @name(".set_average_total_accepted_rate_action") action set_average_total_accepted_rate_action() {
        total_accepted_rate_times_7_alu.execute(32w0);
    }
    @name(".set_average_total_aggregate_arrival_rate_action") action set_average_total_aggregate_arrival_rate_action() {
        total_aggregate_arrival_rate_times_7_alu.execute(32w0);
    }
    @name(".set_pertenantF_leq_totalalpha_action") action set_pertenantF_leq_totalalpha_action() {
        hdr.recirculate_hdr.pertenantF_leq_totalalpha = 8w1;
    }
    @name(".update_per_tenant_alpha_to_maxalpha_action") action update_per_tenant_alpha_to_maxalpha_action() {
        update_per_tenant_alpha_to_maxalpha_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".update_per_tenant_alpha_by_F1_plus_action") action update_per_tenant_alpha_by_F1_plus_action() {
        update_per_tenant_alpha_by_F1_plus_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name(".update_per_tenant_alpha_by_F1_minus_action") action update_per_tenant_alpha_by_F1_minus_action() {
        update_per_tenant_alpha_by_F1_minus_alu.execute((bit<32>)hdr.info_hdr.tenant_id);
    }
    @name("._no_op") action _no_op() {
        ;
    }
    @name(".update_total_alpha_to_maxalpha_action") action update_total_alpha_to_maxalpha_action() {
        hdr.recirculate_hdr.total_alpha = (bit<32>)update_total_alpha_to_maxalpha_alu.execute(32w0);
    }
    @name(".update_total_alpha_by_F0_action") action update_total_alpha_by_F0_action() {
        hdr.recirculate_hdr.total_alpha = (bit<32>)update_total_alpha_by_F0_alu.execute(32w0);
    }
    @name(".drop_packet_2_table") table drop_packet_2_table {
        actions = {
            _drop();
        }
        default_action = _drop();
    }
    @stage(0) @name(".get_delta_c_table") table get_delta_c_table {
        actions = {
            get_delta_c_action();
        }
        default_action = get_delta_c_action();
    }
    @stage(1) @name(".get_delta_total_alpha_table") table get_delta_total_alpha_table {
        actions = {
            get_delta_total_alpha_action();
        }
        default_action = get_delta_total_alpha_action();
    }
    @stage(1) @name(".get_min_of_pertenantF_total_alpha_table") table get_min_of_pertenantF_total_alpha_table {
        actions = {
            get_min_of_pertenantF_total_alpha_action();
        }
        default_action = get_min_of_pertenantF_total_alpha_action();
    }
    @stage(3) @name(".getmin_delta_total_alpha_table") table getmin_delta_total_alpha_table {
        actions = {
            getmin_delta_total_alpha_action();
        }
        default_action = getmin_delta_total_alpha_action();
    }
    @stage(10) @name(".set_average_accepted_rate_table") table set_average_accepted_rate_table {
        actions = {
            set_average_accepted_rate_action();
        }
        default_action = set_average_accepted_rate_action();
    }
    @stage(3) @name(".set_average_aggregate_arrival_rate_table") table set_average_aggregate_arrival_rate_table {
        actions = {
            set_average_aggregate_arrival_rate_action();
        }
        default_action = set_average_aggregate_arrival_rate_action();
    }
    @stage(2) @name(".set_average_per_flow_rate_table") table set_average_per_flow_rate_table {
        actions = {
            set_average_per_flow_rate_action();
        }
        default_action = set_average_per_flow_rate_action();
    }
    @stage(10) @name(".set_average_total_accepted_rate_table") table set_average_total_accepted_rate_table {
        actions = {
            set_average_total_accepted_rate_action();
        }
        default_action = set_average_total_accepted_rate_action();
    }
    @stage(3) @name(".set_average_total_aggregate_arrival_rate_table") table set_average_total_aggregate_arrival_rate_table {
        actions = {
            set_average_total_aggregate_arrival_rate_action();
        }
        default_action = set_average_total_aggregate_arrival_rate_action();
    }
    @stage(2) @name(".set_pertenantF_leq_totalalpha_table") table set_pertenantF_leq_totalalpha_table {
        actions = {
            set_pertenantF_leq_totalalpha_action();
        }
        default_action = set_pertenantF_leq_totalalpha_action();
    }
    @stage(4) @name(".update_per_tenant_alpha_table") table update_per_tenant_alpha_table {
        actions = {
            update_per_tenant_alpha_to_maxalpha_action();
            update_per_tenant_alpha_by_F1_plus_action();
            update_per_tenant_alpha_by_F1_minus_action();
            _no_op();
        }
        key = {
            hdr.recirculate_hdr.congested                : exact;
            hdr.recirculate_hdr.pertenantF_leq_totalalpha: exact;
        }
        default_action = _no_op();
    }
    @stage(0) @name(".update_total_alpha_table") table update_total_alpha_table {
        actions = {
            update_total_alpha_to_maxalpha_action();
            update_total_alpha_by_F0_action();
            _no_op();
        }
        key = {
            hdr.recirculate_hdr.congested: exact;
        }
        default_action = _no_op();
    }
    apply {
        update_total_alpha_table.apply();
        get_delta_c_table.apply();
        get_delta_total_alpha_table.apply();
        get_min_of_pertenantF_total_alpha_table.apply();
        meta.temp = (bit<32>)label_times_7_alu_math_unit_0.execute((bit<32>)hdr.info_hdr.label);
        set_average_per_flow_rate_table.apply();
        if ((bit<32>)hdr.recirculate_hdr.per_tenant_F == meta.meta.min_pertenantF_totalalpha) {
            set_pertenantF_leq_totalalpha_table.apply();
        }
        meta.temp = (bit<32>)aggregate_arrival_rate_times_7_alu_math_unit_0.execute((bit<32>)hdr.info_hdr.per_tenant_A);
        set_average_aggregate_arrival_rate_table.apply();
        meta.temp = (bit<32>)total_aggregate_arrival_rate_times_7_alu_math_unit_0.execute((bit<32>)hdr.info_hdr.total_A);
        set_average_total_aggregate_arrival_rate_table.apply();
        getmin_delta_total_alpha_table.apply();
        update_per_tenant_alpha_table.apply();
        meta.temp = (bit<32>)accepted_rate_times_7_alu_math_unit_0.execute((bit<32>)hdr.recirculate_hdr.per_tenant_F);
        set_average_accepted_rate_table.apply();
        meta.temp = (bit<32>)total_accepted_rate_times_7_alu_math_unit_0.execute((bit<32>)hdr.recirculate_hdr.total_F);
        set_average_total_accepted_rate_table.apply();
        drop_packet_2_table.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_parser_aux, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name(".main_pipe") main_pipe() main_pipe_1;
    @name(".recirc_pipe") recirc_pipe() recirc_pipe_1;
    apply {
        if (hdr.tcp.isValid() || hdr.udp.isValid()) {
            if (!hdr.info_hdr.isValid()) {
                main_pipe_1.apply(hdr, meta, ig_intr_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
            } else {
                recirc_pipe_1.apply(hdr, meta, ig_intr_md_for_dprsr);
            }
        }
    }
}

control IngressDeparserImpl(packet_out pkt, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, in ingress_intrinsic_metadata_t ig_intr_md) {
    Mirror() mirror;
    apply {
        if (ig_intr_md_for_dprsr.mirror_type == (bit<3>)1) {
            mirror.emit<ig_mirror_header_1_t>(meta.__bfp4c_compiler_generated_meta.mirror_id, (ig_mirror_header_1_t){mirror_source = meta.__bfp4c_compiler_generated_meta.mirror_source,current_node_meta_clone_md = meta.current_node_meta.clone_md});
        }
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.info_hdr);
        pkt.emit(hdr.recirculate_hdr);
    }
}

control EgressDeparserImpl(packet_out pkt, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser_aux) {
    Checksum() checksum_0;
    apply {
        hdr.ipv4.hdrChecksum = checksum_0.update({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.ecn_flag, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.info_hdr);
        pkt.emit(hdr.recirculate_hdr);
    }
}

Pipeline(IngressParserImpl(), ingress(), IngressDeparserImpl(), EgressParserImpl(), egress(), EgressDeparserImpl()) pipe;
Switch(pipe) main;

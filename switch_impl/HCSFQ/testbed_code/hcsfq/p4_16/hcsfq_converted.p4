#include <core.p4>
#include <tofino1_specs.p4> // Assuming Tofino 1 target based on includes
#include <tofino1_base.p4>
#include <tofino1_arch.p4>

// --- Constants ---
// Define NUM_FLOWS, NUM_TENANTS, C etc. if they were in hcsfq_defines.p4
// Example:
// const bit<32> C = 115200000; // Example value
// const int NUM_FLOWS = 600;
// const int NUM_TENANTS = 10;

// --- Header and Metadata Definitions ---

// User-defined metadata structures
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

// Kept standard_metadata_t as it was used by the converter,
// but ideally map fields to TNA intrinsics where possible.
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

// Packet Headers
header ethernet_t {
    bit<16> dstAddr_lower;
    bit<32> dstAddr_upper;
    bit<16> srcAddr_lower;
    bit<32> srcAddr_upper;
    bit<16> etherType;
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

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res; // Used for info_hdr detection
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
    bit<16> dstPort; // Used for info_hdr detection
    bit<16> pkt_length;
    bit<16> checksum;
}

// Custom Headers for HCSFQ logic
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

// Mirroring Header (Tofino specific)
header ig_mirror_header_1_t {
    bit<8> mirror_source;
    @flexible // Indicates this field can be variable based on metadata
    bit<8> current_node_meta_clone_md;
}

// Generator Header (Tofino specific)
header generator_metadata_t_0 {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

// --- Structs for packet headers and metadata ---

struct headers_t {
    ethernet_t           ethernet;
    ipv4_t               ipv4;
    tcp_t                tcp;
    udp_t                udp;
    info_hdr_t           info_hdr;
    recirculate_hdr_t    recirculate_hdr;
    // Tofino specific headers need to be handled carefully in parser/deparser
    ig_mirror_header_1_t ig_mirror_header_1;
}

struct metadata_t {
    node_meta_t                                 current_node_meta;
    meta_t                                      meta;
    standard_metadata_t                         standard_metadata; // Keep if used

    // Tofino intrinsic metadata (populated by architecture)
    ingress_intrinsic_metadata_t                ig_intr_md;
    ingress_intrinsic_metadata_for_tm_t         ig_intr_md_for_tm;
    ingress_intrinsic_metadata_from_parser_t    ig_intr_md_from_parser;
    egress_intrinsic_metadata_t                 eg_intr_md;
    egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr;
    egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport;
    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_parser;
}

// --- Parsers ---

parser IngressParserImpl(packet_in pkt,
                         out headers_t hdr,
                         out metadata_t meta,
                         out ingress_intrinsic_metadata_t ig_intr_md,
                         out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
                         out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr)
{
    // Tofino architecture specific entry point states
    state start_ingress_parser {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition check_resubmit;
    }
    state check_resubmit {
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit; // Resubmitted packet
            0 : parse_normal;   // Normal packet path (includes phase0 handling)
        }
    }
    state parse_normal {
         // Phase 0 handling for certain packet types if needed
         // pkt.advance(...);
         transition parse_ethernet;
    }
    state parse_resubmit {
        // Handle resubmitted packet specific parsing if needed
        transition parse_ethernet;
    }

    // Main packet parsing logic
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x800: parse_ipv4;
            default: accept; // Non-IPv4
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        // Assuming info_hdr/recirc_hdr are only carried over TCP/UDP for this app
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;    // TCP
            17: parse_udp;   // UDP
            default: accept; // Other L4 protocols
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        // Check TCP reserved bits to detect custom header presence
        transition select(hdr.tcp.res) {
            1 : parse_info_hdr; // Indicates custom headers present
            default: accept;    // Normal TCP packet
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        // Check UDP dest port to detect custom header presence
        transition select(hdr.udp.dstPort) {
            8888 : parse_info_hdr; // Indicates custom headers present
            default: accept;       // Normal UDP packet
        }
    }
    state parse_info_hdr {
        // Must be present if TCP.res==1 or UDP.dstPort==8888
        pkt.extract(hdr.info_hdr);
        // Recirculate header always follows info header in this design
        transition parse_recirculate_hdr;
    }
    state parse_recirculate_hdr {
        pkt.extract(hdr.recirculate_hdr);
        transition accept; // Parsing complete
    }

    // Initial entry point required by TNA architecture
    state start {
        transition start_ingress_parser;
    }
}

parser EgressParserImpl(packet_in pkt,
                        out headers_t hdr,
                        out metadata_t meta,
                        out egress_intrinsic_metadata_t eg_intr_md,
                        out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser_aux)
{
    // Tofino architecture specific entry point states
    state start_egress_parser {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        transition check_egress_packet_type;
    }
    state check_egress_packet_type {
        // Example: Check if packet is mirrored, bridged, etc.
        // Based on first byte (pkt.lookahead<bit<8>>()) in original parser
        // 0x08 -> Bridged, 0x88 -> Mirrored
        transition select(pkt.lookahead<bit<8>>()) {
             0x08 : parse_bridged_packet;
             0x88 : parse_mirrored_packet;
             default: parse_normal_egress_packet; // Or handle error
        }
    }
    state parse_bridged_packet {
        // Skip bridged metadata if present
        // pkt.advance(...);
        transition parse_ethernet;
    }
    state parse_mirrored_packet {
        // Check mirror source, e.g., ingress mirror (0x09 -> 1 header)
        transition select(pkt.lookahead<bit<8>>()) {
             0x09 : parse_ingress_mirror_header_1;
             default: reject; // Unknown mirror format
        }
    }
    state parse_ingress_mirror_header_1 {
        pkt.extract(hdr.ig_mirror_header_1); // Extract mirror header
        // Populate metadata based on mirror header
        meta.current_node_meta.clone_md = hdr.ig_mirror_header_1.current_node_meta_clone_md;
        // Set clone source, mirror source in compiler metadata if needed by other logic
        // meta.__bfp4c_compiler_generated_meta.clone_src = 1;
        // meta.__bfp4c_compiler_generated_meta.mirror_source = 9;
        transition parse_ethernet; // Continue parsing the original packet
    }
    state parse_normal_egress_packet {
         transition parse_ethernet;
    }

    // Main packet parsing logic (identical to ingress in this case)
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;
            17: parse_udp;
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition select(hdr.tcp.res) {
            1 : parse_info_hdr;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            8888 : parse_info_hdr;
            default: accept;
        }
    }
    state parse_info_hdr {
        pkt.extract(hdr.info_hdr);
        transition parse_recirculate_hdr;
    }
    state parse_recirculate_hdr {
        pkt.extract(hdr.recirculate_hdr);
        transition accept;
    }

    // Initial entry point required by TNA architecture
    state start {
        transition start_egress_parser;
    }
}

// --- Registers ---
// Assuming NUM_FLOWS=600, NUM_TENANTS=10 based on original code sizes

// HCSFQ State Registers
Register<bit<64>, bit<32>>(NUM_FLOWS)   per_flow_rate_reg;
Register<bit<64>, bit<32>>(NUM_FLOWS)   stored_per_flow_rate_reg;
Register<bit<64>, bit<32>>(NUM_TENANTS) aggregate_arrival_rate_reg;
Register<bit<64>, bit<32>>(NUM_TENANTS) stored_aggregate_arrival_rate_reg;
Register<bit<8>, bit<32>>(NUM_FLOWS)    counter_reg;
Register<bit<64>, bit<32>>(NUM_TENANTS) accepted_rate_reg;
Register<bit<64>, bit<32>>(NUM_TENANTS) stored_accepted_rate_reg;
Register<bit<32>, bit<32>>(NUM_TENANTS) alpha_reg;
Register<bit<32>, bit<32>>(NUM_TENANTS) tmp_alpha_reg;
Register<bit<64>, bit<32>>(NUM_TENANTS) congest_state_reg;

// Global State Registers
Register<bit<64>, bit<32>>(1) total_aggregate_arrival_rate_reg;
Register<bit<64>, bit<32>>(1) total_stored_aggregate_arrival_rate_reg;
Register<bit<64>, bit<32>>(1) total_accepted_rate_reg;
Register<bit<64>, bit<32>>(1) total_stored_accepted_rate_reg;
Register<bit<32>, bit<32>>(1) total_alpha_reg;
Register<bit<32>, bit<32>>(1) tmp_total_alpha_reg;
Register<bit<64>, bit<32>>(1) total_congest_state_reg;
Register<bit<32>, bit<32>>(1) timestamp_reg;
Register<bit<16>, bit<32>>(1) fraction_factor_reg;
Register<bit<32>, bit<32>>(1) delta_c_reg;

// Registers possibly used for Egress Queue Check (adjust size if needed)
Register<bit<64>, bit<32>>(1) dst_up_reg;
Register<bit<64>, bit<32>>(1) src_up_reg;

// --- Externs ---
Random<bit<4>>() random_gen_1; // Renamed from random_2
Random<bit<4>>() random_gen_2; // Renamed from random_3
Mirror() mirror_session;       // For i2e_mirror_action
Checksum() checksum_engine;   // For EgressDeparserImpl

// Math Units for weighted averaging (EWMA-like logic)
// The constants {111, 104, ... 0} represent weights for EWMA shift/subtract logic
const bit<8>[16] EWMA_WEIGHTS = { 111, 104, 96, 89, 81, 74, 66, 59, 52, 44, 37, 29, 22, 14, 7, 0 };
MathUnit<bit<32>>(false, 0, -3, EWMA_WEIGHTS) ewma_math_unit; // Single unit, used by multiple actions

// --- Layout Structs for Register Actions ---
// These define the fields within the 64-bit registers used by RegisterActions

struct estimate_accepted_rate_layout { // For accepted_rate_reg
    bit<32> hi; // Stored rate
    bit<32> lo; // Timestamp
}
struct estimate_agg_arrival_rate_layout { // For aggregate_arrival_rate_reg
    bit<32> hi; // Stored rate
    bit<32> lo; // Timestamp
}
struct estimate_per_flow_rate_layout { // For per_flow_rate_reg
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
struct set_ecn_byq_layout { // For dst_up_reg (used in egress)
    bit<32> hi; // Not used in this action
    bit<32> lo; // ECN value (2 or 3)
}

// --- Control: Egress Pipeline ---

control egress(inout headers_t hdr,
               inout metadata_t meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser_aux,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
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


// --- Control: Main Ingress Pipeline Logic ---

control main_pipe(inout headers_t hdr,
                  inout metadata_t meta,
                  in ingress_intrinsic_metadata_t ig_intr_md,
                  inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
                  inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)
{
    // --- Register Actions for main_pipe ---

    // Note: RegisterAction definitions implement the logic executed when the register is accessed.
    // `value` is the current value in the register (read/modify/write).
    // `rv` is the return value (typically the old value or a calculated result).
    // `this.predicate` is used in some actions for conditional register updates.

    RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_total_alpha_reg) check_total_uncongest_state_0_logic = {
        void apply(inout bit<32> value) { value = 21514000; /* Update tmp reg */ } // Action: check_total_uncongest_state_0_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_total_alpha_reg) check_total_uncongest_state_1_logic = {
        void apply(inout bit<32> value) { value = hdr.recirculate_hdr.per_tenant_F; /* Update tmp reg */ } // Action: check_total_uncongest_state_1_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_total_alpha_reg) check_total_uncongest_state_23_logic = {
        void apply(inout bit<32> value) { value = 21514000; /* Update tmp reg */ } // Action: check_total_uncongest_state_23_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_alpha_reg) check_uncongest_state_0_logic = {
        void apply(inout bit<32> value) { value = 21514000; /* Update tmp reg */ } // Action: check_uncongest_state_0_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_alpha_reg) check_uncongest_state_1_logic = {
        void apply(inout bit<32> value) { value = hdr.info_hdr.label; /* Update tmp reg */ } // Action: check_uncongest_state_1_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(tmp_alpha_reg) check_uncongest_state_23_logic = {
        void apply(inout bit<32> value) { value = 21514000; /* Update tmp reg */ } // Action: check_uncongest_state_23_action
    };
    RegisterAction<bit<8>, bit<32>, bit<8>>(counter_reg) counter_logic = {
        void apply(inout bit<8> value, out bit<8> rv) {
            bit<8> current_val = value;
            if (current_val == 24) { value = 0; } else { value = current_val + 1; }
            rv = value; // Return updated counter
        } // Action: counter_action
    };
    RegisterAction<estimate_accepted_rate_layout, bit<32>, bit<32>>(accepted_rate_reg) estimate_accepted_rate_2_logic = {
        void apply(inout estimate_accepted_rate_layout value, out bit<32> rv) {
            estimate_accepted_rate_layout current_val = value; rv = 0;
            if (!(meta.meta.tsp - current_val.lo < 838200)) { // Time elapsed > threshold
                rv = current_val.hi; // Return old rate
                value.lo = meta.meta.tsp; // Update timestamp
                value.hi = 0; // Reset rate (drop case)
            } // else: time < threshold, do nothing to rate, update timestamp below
            // Original logic had redundant updates, simplified:
            // If time < threshold, rv=0 (as initialized), value.lo/hi unchanged here.
            // If time >= threshold, rv=old_rate, value.lo=tsp, value.hi=0.
            // This seems to always update timestamp if time >= threshold, let's keep it simple:
            if (meta.meta.tsp - current_val.lo >= 838200) {
                 rv = current_val.hi;
                 value.lo = meta.meta.tsp;
                 value.hi = 0; // Reset rate as this is drop path
            }
        } // Action: estimate_accepted_rate_2_action
    };
    RegisterAction<estimate_accepted_rate_layout, bit<32>, bit<32>>(accepted_rate_reg) estimate_accepted_rate_logic = {
        void apply(inout estimate_accepted_rate_layout value, out bit<32> rv) {
             estimate_accepted_rate_layout current_val = value; rv = 0;
             if (meta.meta.tsp - current_val.lo >= 838200) { // Time elapsed > threshold
                 rv = current_val.hi; // Return old rate
                 value.lo = meta.meta.tsp; // Update timestamp
                 value.hi = meta.meta.halflen; // Start new rate calculation with current packet len
             } else { // Time < threshold
                 value.hi = current_val.hi + meta.meta.halflen; // Accumulate rate
                 // timestamp (value.lo) remains unchanged
             }
        } // Action: estimate_accepted_rate_action
    };
    RegisterAction<estimate_agg_arrival_rate_layout, bit<32>, bit<32>>(aggregate_arrival_rate_reg) estimate_aggregate_arrival_rate_logic = {
         void apply(inout estimate_agg_arrival_rate_layout value, out bit<32> rv) {
             estimate_agg_arrival_rate_layout current_val = value; rv = 0;
             if (meta.meta.tsp - current_val.lo >= 838200) { // Time > threshold
                 rv = current_val.hi;
                 value.lo = meta.meta.tsp;
                 value.hi = meta.meta.halflen;
             } else { // Time < threshold
                 value.hi = current_val.hi + meta.meta.halflen;
             }
         } // Action: estimate_aggregate_arrival_rate_action
    };
    RegisterAction<estimate_per_flow_rate_layout, bit<32>, bit<32>>(per_flow_rate_reg) estimate_per_flow_rate_logic = {
         void apply(inout estimate_per_flow_rate_layout value, out bit<32> rv) {
             estimate_per_flow_rate_layout current_val = value; rv = 0;
             if (meta.meta.tsp - current_val.lo >= 800000) { // Different threshold here
                 rv = current_val.hi;
                 value.lo = meta.meta.tsp;
                 value.hi = meta.meta.weight_len; // Use weighted length
             } else {
                 value.hi = current_val.hi + meta.meta.weight_len;
             }
         } // Action: estimate_per_flow_rate_action
    };
    RegisterAction<estimate_total_accepted_rate_layout, bit<32>, bit<32>>(total_accepted_rate_reg) estimate_total_accepted_rate_2_logic = {
        void apply(inout estimate_total_accepted_rate_layout value, out bit<32> rv) {
            estimate_total_accepted_rate_layout current_val = value; rv = 0;
            if (meta.meta.tsp - current_val.lo >= 838200) {
                 rv = current_val.hi;
                 value.lo = meta.meta.tsp;
                 value.hi = 0; // Reset rate on drop path
            }
        } // Action: estimate_total_accepted_rate_2_action
    };
    RegisterAction<estimate_total_accepted_rate_layout, bit<32>, bit<32>>(total_accepted_rate_reg) estimate_total_accepted_rate_logic = {
        void apply(inout estimate_total_accepted_rate_layout value, out bit<32> rv) {
            estimate_total_accepted_rate_layout current_val = value; rv = 0;
             if (meta.meta.tsp - current_val.lo >= 838200) {
                 rv = current_val.hi;
                 value.lo = meta.meta.tsp;
                 value.hi = meta.meta.halflen;
             } else {
                 value.hi = current_val.hi + meta.meta.halflen;
             }
        } // Action: estimate_total_accepted_rate_action
    };
    RegisterAction<estimate_total_agg_arrival_rate_layout, bit<32>, bit<32>>(total_aggregate_arrival_rate_reg) estimate_total_aggregate_arrival_rate_logic = {
        void apply(inout estimate_total_agg_arrival_rate_layout value, out bit<32> rv) {
            estimate_total_agg_arrival_rate_layout current_val = value; rv = 0;
             if (meta.meta.tsp - current_val.lo >= 838200) {
                 rv = current_val.hi;
                 value.lo = meta.meta.tsp;
                 value.hi = meta.meta.halflen;
             } else {
                 value.hi = current_val.hi + meta.meta.halflen;
             }
        } // Action: estimate_total_aggregate_arrival_rate_action
    };
    RegisterAction<get_accepted_rate_layout, bit<32>, bit<32>>(stored_accepted_rate_reg) get_accepted_rate_logic = {
        void apply(inout get_accepted_rate_layout value, out bit<32> rv) {
            rv = value.hi; // Return stored rate
        } // Action: get_accepted_rate_action
    };
    RegisterAction<get_accepted_rate_layout, bit<32>, bit<32>>(stored_accepted_rate_reg) get_accepted_rate_times_7_logic = {
        void apply(inout get_accepted_rate_layout value, out bit<32> rv) {
             // This seems to store a temporary sum in 'lo' for division later?
             value.lo = value.lo + meta.meta.per_tenant_F;
             rv = value.lo; // Return the sum
        } // Action: get_accepted_rate_times_7_action
    };
    RegisterAction<get_agg_arrival_rate_layout, bit<32>, bit<32>>(stored_aggregate_arrival_rate_reg) get_aggregate_arrival_rate_logic = {
        void apply(inout get_agg_arrival_rate_layout value, out bit<32> rv) {
            rv = value.hi; // Return stored rate
        } // Action: get_aggregate_arrival_rate_action
    };
    RegisterAction<get_agg_arrival_rate_layout, bit<32>, bit<32>>(stored_aggregate_arrival_rate_reg) get_aggregate_arrival_rate_times_7_logic = {
        void apply(inout get_agg_arrival_rate_layout value, out bit<32> rv) {
             value.lo = value.lo + meta.meta.per_tenant_A;
             rv = value.lo; // Return sum
        } // Action: get_aggregate_arrival_rate_times_7_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(alpha_reg) get_alpha_logic = {
        void apply(inout bit<32> value, out bit<32> rv) {
             rv = value; // Return current alpha
        } // Action: get_alpha_action
    };
    RegisterAction<bit<16>, bit<32>, bit<16>>(fraction_factor_reg) get_fraction_factor_logic = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value; // Return fraction factor
        } // Action: get_fraction_factor_action
    };
    RegisterAction<get_per_flow_rate_layout, bit<32>, bit<32>>(stored_per_flow_rate_reg) get_per_flow_rate_logic = {
        void apply(inout get_per_flow_rate_layout value, out bit<32> rv) {
            rv = value.hi; // Return stored rate
        } // Action: get_per_flow_rate_action
    };
    RegisterAction<get_per_flow_rate_layout, bit<32>, bit<32>>(stored_per_flow_rate_reg) get_per_flow_rate_times_7_logic = {
        void apply(inout get_per_flow_rate_layout value, out bit<32> rv) {
            value.lo = value.lo + meta.meta.label;
            rv = value.lo; // Return sum
        } // Action: get_per_flow_rate_times_7_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(timestamp_reg) get_time_stamp_logic = {
        void apply(inout bit<32> value, out bit<32> rv) {
            value = ig_intr_md.ingress_mac_tstamp; // Update stored timestamp
            rv = value; // Return current timestamp
        } // Action: get_time_stamp_action
    };
    RegisterAction<get_total_accepted_rate_layout, bit<32>, bit<32>>(total_stored_accepted_rate_reg) get_total_accepted_rate_logic = {
        void apply(inout get_total_accepted_rate_layout value, out bit<32> rv) {
            rv = value.hi; // Return stored rate
        } // Action: get_total_accepted_rate_action
    };
    RegisterAction<get_total_accepted_rate_layout, bit<32>, bit<32>>(total_stored_accepted_rate_reg) get_total_accepted_rate_times_7_logic = {
        void apply(inout get_total_accepted_rate_layout value, out bit<32> rv) {
            value.lo = value.lo + meta.meta.total_F;
            rv = value.lo; // Return sum
        } // Action: get_total_accepted_rate_times_7_action
    };
    RegisterAction<get_total_agg_arrival_rate_layout, bit<32>, bit<32>>(total_stored_aggregate_arrival_rate_reg) get_total_aggregate_arrival_rate_logic = {
        void apply(inout get_total_agg_arrival_rate_layout value, out bit<32> rv) {
            rv = value.hi; // Return stored rate
        } // Action: get_total_aggregate_arrival_rate_action
    };
    RegisterAction<get_total_agg_arrival_rate_layout, bit<32>, bit<32>>(total_stored_aggregate_arrival_rate_reg) get_total_aggregate_arrival_rate_times_7_logic = {
        void apply(inout get_total_agg_arrival_rate_layout value, out bit<32> rv) {
            value.lo = value.lo + meta.meta.total_A;
            rv = value.lo; // Return sum
        } // Action: get_total_aggregate_arrival_rate_times_7_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(total_alpha_reg) get_total_alpha_logic = {
        void apply(inout bit<32> value, out bit<32> rv) {
            bit<32> current_val = value;
            // Clamp alpha to max value (C?)
            // Assuming C = 115200000 based on original code comparison
            if (current_val > 115200000) {
                value = 115200000;
            }
            rv = value; // Return possibly clamped alpha
        } // Action: get_total_alpha_action
    };
    RegisterAction<maintain_congest_state_layout, bit<32>, bit<32>>(congest_state_reg) maintain_congest_state_logic = {
        void apply(inout maintain_congest_state_layout value, out bit<32> rv) {
            maintain_congest_state_layout current_val = value; rv = 0;
            bool time_expired = (meta.meta.tsp - current_val.lo >= 838200);
            bool was_congested = (current_val.hi == 1);

            if (time_expired && was_congested) {
                rv = 1; // Return 1 (was congested) only if time expired
            }
            if (time_expired || !was_congested) { // Update timestamp if expired OR first time entering congested state
                 value.lo = meta.meta.tsp;
            }
            if (!was_congested) { // Set congested state if not already set
                value.hi = 1;
            }
            // Note: rv is 0 if time hasn't expired, or if it expired but state wasn't 1 previously.
            // The original code returned current_val.hi which seems incorrect if time expired.
            // Let's assume rv signals if a *change* from uncongested->congested happened *after* expiration.
            // The original code's rv usage seems complex, returning old state only if time expired and old state was non-zero.
            // Let's stick closer to the original: return old state if expired & non-zero, else 0.
            rv = (time_expired && current_val.hi != 0) ? current_val.hi : 0;
            // Update logic:
            if (time_expired || current_val.hi == 0) { // Update timestamp if expired or first entry
                 value.lo = meta.meta.tsp;
            }
            if (current_val.hi == 0) { // Set state to 1 if it was 0
                 value.hi = 1;
            }

        } // Action: maintain_congest_state_action
    };
    RegisterAction<maintain_total_congest_state_layout, bit<32>, bit<32>>(total_congest_state_reg) maintain_total_congest_state_logic = {
        void apply(inout maintain_total_congest_state_layout value, out bit<32> rv) {
            // Identical logic to maintain_congest_state_logic
             maintain_total_congest_state_layout current_val = value; rv = 0;
             bool time_expired = (meta.meta.tsp - current_val.lo >= 838200);
             rv = (time_expired && current_val.hi != 0) ? current_val.hi : 0;
             if (time_expired || current_val.hi == 0) { value.lo = meta.meta.tsp; }
             if (current_val.hi == 0) { value.hi = 1; }
        } // Action: maintain_total_congest_state_action
    };
    RegisterAction<maintain_total_congest_state_layout, bit<32>, bit<32>>(total_congest_state_reg) maintain_total_uncongest_state_logic = {
        void apply(inout maintain_total_congest_state_layout value, out bit<32> rv) {
            maintain_total_congest_state_layout current_val = value; rv = 0;
            bool time_threshold_met = (meta.meta.tsp - current_val.lo < 838200);
            bool was_congested = (current_val.hi > 0); // Check if state > 0

            // Original code uses this.predicate(cond1, cond2) - seems Tofino specific.
            // Let's interpret the logic: return 1 if time threshold met AND was congested.
            rv = (time_threshold_met && was_congested) ? 1 : 0;

            // Update logic: If time expired OR was congested, update timestamp.
            if (!time_threshold_met || was_congested) {
                 value.lo = meta.meta.tsp;
            }
            // If was congested, reset state to 0.
            if (was_congested) {
                 value.hi = 0;
            }
        } // Action: maintain_total_uncongest_state_action
    };
     RegisterAction<maintain_congest_state_layout, bit<32>, bit<32>>(congest_state_reg) maintain_uncongest_state_logic = {
        void apply(inout maintain_congest_state_layout value, out bit<32> rv) {
            // Identical logic to maintain_total_uncongest_state_logic
            maintain_congest_state_layout current_val = value; rv = 0;
            bool time_threshold_met = (meta.meta.tsp - current_val.lo < 838200);
            bool was_congested = (current_val.hi > 0);
            rv = (time_threshold_met && was_congested) ? 1 : 0;
            if (!time_threshold_met || was_congested) { value.lo = meta.meta.tsp; }
            if (was_congested) { value.hi = 0; }
        } // Action: maintain_uncongest_state_action
    };
    RegisterAction<put_src_up_layout, bit<32>, void>(src_up_reg) put_src_up_logic = {
        void apply(inout put_src_up_layout value) {
            // Simply writes metadata values into the register fields
            value.lo = meta.meta.halflen; // Or weight_len? Original used halflen here.
            value.hi = hdr.ipv4.totalLen;
        } // Action: put_src_up_action
    };

    // --- Actions for main_pipe ---

    action add_info_hdr(bit<16> flow_id, bit<16> tenant_id) {
        hdr.info_hdr.setValid();
        hdr.recirculate_hdr.setValid();
        hdr.info_hdr.label_smaller_than_alpha = 0; // Default? Original had 1
        hdr.info_hdr.flow_id = flow_id;
        hdr.info_hdr.tenant_id = tenant_id;
        hdr.info_hdr.recirc_flag = 0; // Default? Original had 1
        hdr.info_hdr.update_alpha = 0; // Default? Original had 1
        hdr.info_hdr.update_rate = 0; // Default? Original had 0
        // Constants used in congestion logic
        meta.meta.per_tenant_true_flag = 9;
        meta.meta.per_tenant_false_flag = 8;
        meta.meta.total_true_flag = 20;
        meta.meta.total_false_flag = 16;
    }
    action add_info_hdr_default() {
        hdr.info_hdr.setValid();
        hdr.recirculate_hdr.setValid();
        hdr.info_hdr.label_smaller_than_alpha = 0; // Default? Original had 1
        hdr.info_hdr.flow_id = 99; // Default flow
        hdr.info_hdr.tenant_id = 9; // Default tenant
        hdr.info_hdr.recirc_flag = 0; // Default? Original had 1
        hdr.info_hdr.update_alpha = 0; // Default? Original had 1
        hdr.info_hdr.update_rate = 0;
        meta.meta.per_tenant_true_flag = 9;
        meta.meta.per_tenant_false_flag = 8;
        meta.meta.total_true_flag = 20;
        meta.meta.total_false_flag = 16;
    }
    action add_info_hdr_udp(bit<16> flow_id, bit<16> tenant_id) {
        // Identical to add_info_hdr in the original
        hdr.info_hdr.setValid();
        hdr.recirculate_hdr.setValid();
        hdr.info_hdr.label_smaller_than_alpha = 0;
        hdr.info_hdr.flow_id = flow_id;
        hdr.info_hdr.tenant_id = tenant_id;
        hdr.info_hdr.recirc_flag = 0;
        hdr.info_hdr.update_alpha = 0;
        hdr.info_hdr.update_rate = 0;
        meta.meta.per_tenant_true_flag = 9;
        meta.meta.per_tenant_false_flag = 8;
        meta.meta.total_true_flag = 20;
        meta.meta.total_false_flag = 16;
    }
    action add_info_hdr_udp_default() {
        // Different defaults in original
        hdr.info_hdr.setValid();
        hdr.recirculate_hdr.setValid();
        hdr.info_hdr.label_smaller_than_alpha = 0;
        hdr.info_hdr.flow_id = 0; // Default flow 0
        hdr.info_hdr.tenant_id = 0; // Default tenant 0
        hdr.info_hdr.recirc_flag = 0;
        hdr.info_hdr.update_alpha = 0;
        hdr.info_hdr.update_rate = 0;
        meta.meta.per_tenant_true_flag = 9;
        meta.meta.per_tenant_false_flag = 8;
        meta.meta.total_true_flag = 20;
        meta.meta.total_false_flag = 16;
    }
    action alpha_shl_4() {
        meta.meta.alpha_shl_4 = hdr.recirculate_hdr.per_tenant_alpha << 4;
    }
    action alpha_times_15() {
        meta.meta.alpha_times_15 = meta.meta.alpha_shl_4 - hdr.recirculate_hdr.per_tenant_alpha; // alpha * 16 - alpha
    }
    action check_total_uncongest_state_0() {
        check_total_uncongest_state_0_logic.execute(0); // index 0
        meta.meta.to_resubmit_2 = 1; // Signal resubmit
        hdr.recirculate_hdr.congested = hdr.recirculate_hdr.congested | meta.meta.total_false_flag; // Set flag
    }
    action check_total_uncongest_state_1() {
        check_total_uncongest_state_1_logic.execute(0); // index 0
    }
     action check_total_uncongest_state_23() {
        check_total_uncongest_state_23_logic.execute(0); // index 0
    }
    action check_uncongest_state_0() {
        check_uncongest_state_0_logic.execute(hdr.info_hdr.tenant_id); // Use tenant_id as index
        meta.meta.to_resubmit = 1; // Signal resubmit
        hdr.recirculate_hdr.congested = hdr.recirculate_hdr.congested | meta.meta.per_tenant_false_flag; // Set flag
    }
     action check_uncongest_state_1() {
        check_uncongest_state_1_logic.execute(hdr.info_hdr.tenant_id);
    }
    action check_uncongest_state_23() {
        check_uncongest_state_23_logic.execute(hdr.info_hdr.tenant_id);
    }
    action run_counter() { // Renamed from counter_action
        hdr.info_hdr.update_rate = counter_logic.execute(hdr.info_hdr.flow_id); // Use flow_id as index
    }
    action div_accepted_rate() {
        hdr.recirculate_hdr.per_tenant_F = hdr.recirculate_hdr.per_tenant_F >> 3; // Divide by 8 (EWMA related)
    }
    action div_aggregate_arrival_rate() {
        hdr.info_hdr.per_tenant_A = hdr.info_hdr.per_tenant_A >> 3;
    }
    action div_per_flow_rate() {
        hdr.info_hdr.label = hdr.info_hdr.label >> 3;
    }
    action div_total_accepted_rate() {
        hdr.recirculate_hdr.total_F = hdr.recirculate_hdr.total_F >> 3;
    }
    action div_total_aggregate_arrival_rate() {
        hdr.info_hdr.total_A = hdr.info_hdr.total_A >> 3;
        meta.meta.to_resubmit_3 = 1; // Signal resubmit
    }
    action drop_packet() {
        // Standard drop action using Tofino intrinsic metadata
        ig_intr_md_for_dprsr.drop_ctl = TNA_DropCtl_t.DROP;
    }
    action estimate_accepted_rate_2() { // Drop path
        meta.meta.per_tenant_F = estimate_accepted_rate_2_logic.execute(hdr.info_hdr.tenant_id);
    }
    action estimate_accepted_rate() { // Accept path
        meta.meta.per_tenant_F = estimate_accepted_rate_logic.execute(hdr.info_hdr.tenant_id);
    }
    action estimate_aggregate_arrival_rate() {
        meta.meta.per_tenant_A = estimate_aggregate_arrival_rate_logic.execute(hdr.info_hdr.tenant_id);
    }
    action estimate_per_flow_rate() {
        meta.meta.label = estimate_per_flow_rate_logic.execute(hdr.info_hdr.flow_id);
    }
    action estimate_total_accepted_rate_2() { // Drop path
        meta.meta.total_F = estimate_total_accepted_rate_2_logic.execute(0); // Global index 0
    }
    action estimate_total_accepted_rate() { // Accept path
        meta.meta.total_F = estimate_total_accepted_rate_logic.execute(0);
    }
    action estimate_total_aggregate_arrival_rate() {
        meta.meta.total_A = estimate_total_aggregate_arrival_rate_logic.execute(0);
    }
    action flowrate_shl() { // Precompute shifts
        meta.meta.label_shl_1 = hdr.info_hdr.label << 1;
        meta.meta.label_shl_2 = hdr.info_hdr.label << 2;
        meta.meta.label_shl_3 = hdr.info_hdr.label << 3;
    }
    // Actions for random weighted sum based on randv (implements label * randv)
    action flowrate_sum_01_01() { meta.meta.label_shl_1 = hdr.info_hdr.label + meta.meta.label_shl_1; } // L + L*2 = 3L
    action flowrate_sum_01_0()  { meta.meta.label_shl_1 = hdr.info_hdr.label; }                        // L
    action flowrate_sum_01_1()  { meta.meta.label_shl_1 = meta.meta.label_shl_1; }                    // L*2
    action flowrate_sum_01_none(){ meta.meta.label_shl_1 = 0; }                                      // 0
    action flowrate_sum_23_23() { meta.meta.label_shl_2 = meta.meta.label_shl_2 + meta.meta.label_shl_3; } // L*4 + L*8 = 12L
    action flowrate_sum_23_2()  { meta.meta.label_shl_2 = meta.meta.label_shl_2; }                    // L*4
    action flowrate_sum_23_3()  { meta.meta.label_shl_2 = meta.meta.label_shl_3; }                    // L*8
    action flowrate_sum_23_none(){ meta.meta.label_shl_2 = 0; }                                      // 0
    action flowrate_times_randv() { // Combine results based on randv interpretation
        meta.meta.label_times_randv = meta.meta.label_shl_1 + meta.meta.label_shl_2;
    }
    // Actions for adjusting alpha based on fraction factor (EWMA related shifts)
    // Simplified: one action with parameter, or keep separate if needed for table structure
    action get_14_alpha(bit<5> shift_val_total, bit<5> shift_val_tenant, bit<5> shift_val_tenant_w2) {
         meta.meta.total_alpha_mini = hdr.recirculate_hdr.total_alpha >> shift_val_total;
         meta.meta.per_tenant_alpha_mini = hdr.recirculate_hdr.per_tenant_alpha >> shift_val_tenant;
         meta.meta.per_tenant_alpha_mini_w2 = hdr.recirculate_hdr.per_tenant_alpha >> shift_val_tenant_w2;
    }
    // Example specific actions if parameterization isn't used:
    action get_14_alpha_f0() { get_14_alpha(9, 10, 11); } // fraction_factor 0? Based on original default
    action get_14_alpha_f1() { get_14_alpha(1, 2, 3); }  // fraction_factor 1? etc.
    // ... define actions for f2 through f20 ...

    action get_34_alpha() { // Adjust alpha (subtract the 1/4 part)
        hdr.recirculate_hdr.total_alpha = hdr.recirculate_hdr.total_alpha - meta.meta.total_alpha_mini;
        hdr.recirculate_hdr.per_tenant_alpha = hdr.recirculate_hdr.per_tenant_alpha - meta.meta.per_tenant_alpha_mini;
    }
    action get_34_alpha_w2() { // Adjust alpha with different weight
        hdr.recirculate_hdr.total_alpha = hdr.recirculate_hdr.total_alpha - meta.meta.total_alpha_mini;
        hdr.recirculate_hdr.per_tenant_alpha = hdr.recirculate_hdr.per_tenant_alpha - meta.meta.per_tenant_alpha_mini_w2;
    }
    action get_accepted_rate() {
        hdr.recirculate_hdr.per_tenant_F = get_accepted_rate_logic.execute(hdr.info_hdr.tenant_id);
    }
    action get_accepted_rate_times_7() {
        hdr.recirculate_hdr.per_tenant_F = get_accepted_rate_times_7_logic.execute(hdr.info_hdr.tenant_id);
    }
    action get_aggregate_arrival_rate() {
        hdr.info_hdr.per_tenant_A = get_aggregate_arrival_rate_logic.execute(hdr.info_hdr.tenant_id);
    }
    action get_aggregate_arrival_rate_times_7() {
        hdr.info_hdr.per_tenant_A = get_aggregate_arrival_rate_times_7_logic.execute(hdr.info_hdr.tenant_id);
        meta.meta.to_resubmit_3 = 1; // Signal resubmit
    }
    action get_alpha() {
        hdr.recirculate_hdr.per_tenant_alpha = get_alpha_logic.execute(hdr.info_hdr.tenant_id);
    }
    action get_fraction_factor() {
        meta.meta.fraction_factor = get_fraction_factor_logic.execute(0); // Global index 0
    }
    action get_half_pktlen() { // Default weight
        meta.meta.weight_len = hdr.ipv4.totalLen >> 3; // len / 8
        meta.meta.halflen = hdr.ipv4.totalLen >> 3;    // len / 8
        meta.meta.w2 = 0; // Flag for get_34_alpha_table
    }
    action get_half_pktlen_w2() { // Weight / 2
        meta.meta.weight_len = hdr.ipv4.totalLen >> 4; // len / 16
        meta.meta.halflen = hdr.ipv4.totalLen >> 3;    // len / 8
        meta.meta.w2 = 1; // Flag for get_34_alpha_table
    }
    action get_half_pktlen_w4() { // Weight / 4
        meta.meta.weight_len = hdr.ipv4.totalLen >> 5; // len / 32
        meta.meta.halflen = hdr.ipv4.totalLen >> 3;    // len / 8
        meta.meta.w2 = 0; // Flag? Original used w2=0 here too. Maybe should be 2? Check logic.
    }
    action get_minv_0_2() { // min(total_A, C) -> label_shl_3
        // Assuming C = 115200000
        meta.meta.label_shl_3 = (hdr.info_hdr.total_A <= 115200000) ? hdr.info_hdr.total_A : 115200000;
    }
    action get_minv_0() { // min(per_tenant_A, total_alpha) -> label
        meta.meta.label = (hdr.info_hdr.per_tenant_A <= hdr.recirculate_hdr.total_alpha) ? hdr.info_hdr.per_tenant_A : hdr.recirculate_hdr.total_alpha;
    }
    action get_minv() { // min(alpha * 15, label * randv)
        meta.meta.min_alphatimes15_labeltimesrand = (meta.meta.alpha_times_15 <= meta.meta.label_times_randv) ? meta.meta.alpha_times_15 : meta.meta.label_times_randv;
    }
    action get_per_flow_rate() {
        hdr.info_hdr.label = get_per_flow_rate_logic.execute(hdr.info_hdr.flow_id);
    }
    action get_per_flow_rate_times_7() {
        hdr.info_hdr.label = get_per_flow_rate_times_7_logic.execute(hdr.info_hdr.flow_id);
        meta.meta.to_resubmit_3 = 1; // Signal resubmit
    }
    action get_random_value() {
        meta.meta.randv = random_gen_1.get(); // Get random 4 bits
        meta.meta.randv2 = random_gen_2.get(); // Get another random 4 bits (if needed)
    }
    action get_time_stamp() {
        meta.meta.tsp = get_time_stamp_logic.execute(0); // Global index 0
    }
    action get_total_accepted_rate() {
        hdr.recirculate_hdr.total_F = get_total_accepted_rate_logic.execute(0);
    }
    action get_total_accepted_rate_times_7() {
        hdr.recirculate_hdr.total_F = get_total_accepted_rate_times_7_logic.execute(0);
    }
    action get_total_aggregate_arrival_rate() {
        hdr.info_hdr.total_A = get_total_aggregate_arrival_rate_logic.execute(0);
    }
    action get_total_aggregate_arrival_rate_times_7() {
        hdr.info_hdr.total_A = get_total_aggregate_arrival_rate_times_7_logic.execute(0);
    }
    action get_total_alpha() {
        hdr.recirculate_hdr.total_alpha = get_total_alpha_logic.execute(0);
    }
    action i2e_mirror(bit<32> mirror_id_param) {
        meta.current_node_meta.clone_md = 1; // Mark for cloning/mirroring
        // Use Tofino mirror intrinsic
        ig_intr_md_for_dprsr.mirror_type = TNA_MirrorType_t.I2E_MIRROR;
        // The mirror ID should typically come from a table action parameter
        // mirror_session.emit(mirror_id_param); // How to set mirror ID needs check TNA docs
        // Original converter used meta fields, maybe map to mirror extern properties?
        // meta.__bfp4c_compiler_generated_meta.mirror_id = (bit<10>)mirror_id_param;
        // meta.__bfp4c_compiler_generated_meta.mirror_source = 9; // Source ID 9
    }
    action set_egress_port(bit<9> egress_port_spec) { // Renamed from set_egress
        ig_intr_md_for_tm.ucast_egress_port = egress_port_spec;
        // Decrement TTL
        if (hdr.ipv4.ttl > 0) {
            hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        } else {
            // TTL expired - drop? Or let egress handle? Assuming just decrement here.
        }
    }
    action set_egress_port_final(bit<9> egress_port_spec) { // Renamed from set_egress_3
        // Invalidate custom headers before sending packet out
        hdr.recirculate_hdr.setInvalid();
        hdr.info_hdr.setInvalid();
        ig_intr_md_for_tm.ucast_egress_port = egress_port_spec;
        if (hdr.ipv4.ttl > 0) { hdr.ipv4.ttl = hdr.ipv4.ttl - 1; }
    }
    action set_egress_port_final_udp(bit<9> egress_port_spec) { // Renamed from set_egress_3_udp
        hdr.recirculate_hdr.setInvalid();
        hdr.info_hdr.setInvalid();
        ig_intr_md_for_tm.ucast_egress_port = egress_port_spec;
        if (hdr.ipv4.ttl > 0) { hdr.ipv4.ttl = hdr.ipv4.ttl - 1; }
    }
    action maintain_congest_state() {
        bit<32> rv = maintain_congest_state_logic.execute(hdr.info_hdr.tenant_id);
        // Use rv to set resubmit flag? Original code did: meta.meta.to_resubmit = (bit<2>)rv;
        // Let's assume rv=1 signals need for resubmit
        if (rv != 0) { meta.meta.to_resubmit = 1; }
        hdr.recirculate_hdr.congested = hdr.recirculate_hdr.congested | meta.meta.per_tenant_true_flag; // Set flag
    }
    action maintain_total_congest_state() {
        bit<32> rv = maintain_total_congest_state_logic.execute(0);
        if (rv != 0) { meta.meta.to_resubmit_2 = 1; }
        hdr.recirculate_hdr.congested = hdr.recirculate_hdr.congested | meta.meta.total_true_flag; // Set flag
    }
    action maintain_total_uncongest_state() {
        bit<32> rv = maintain_total_uncongest_state_logic.execute(0);
        meta.meta.total_uncongest_state_predicate = (bit<4>)rv; // Store predicate result
    }
    action maintain_uncongest_state() {
        bit<32> rv = maintain_uncongest_state_logic.execute(hdr.info_hdr.tenant_id);
        meta.meta.uncongest_state_predicate = (bit<4>)rv; // Store predicate result
    }
    action mod_resubmit_field() { // Copy drop decision to recirc header
        hdr.recirculate_hdr.to_drop = (bit<8>)meta.meta.to_drop;
    }
    action put_src_up() { // Store lengths in register
        put_src_up_logic.execute(0); // Global index 0
    }
    action resubmit_packet() { // Renamed from resubmit_action
        // Use Tofino intrinsic for recirculation/resubmit
        // Send to recirculation port (e.g., 68, adjust based on platform)
        // Preserve pipe ID by using current ingress port's upper bits
        ig_intr_md_for_tm.ucast_egress_port = (ig_intr_md.ingress_port & 0x180) | 68; // Combine pipe ID + recirc port
    }
    action set_drop_flag() { // Renamed from set_drop_action
        meta.meta.to_drop = 1; // Mark for dropping later
    }
    action set_tcp_flag() { // Mark packet for recirculation check
        hdr.tcp.res = 1;
    }
    action set_udp_flag() { // Mark packet for recirculation check
        hdr.udp.dstPort = 8888;
    }
    action sum_accepted_rate() { // Just signals resubmit?
        meta.meta.to_resubmit_3 = 1;
    }
    action sum_total_accepted_rate() { // Just signals resubmit?
        meta.meta.to_resubmit = 1;
    }

    // --- Tables for main_pipe ---

    table add_info_hdr_table {
        actions = { add_info_hdr; add_info_hdr_default; }
        key = { hdr.ipv4.srcAddr: exact; hdr.tcp.dstPort : exact; }
        size = 1024; // Example size
        default_action = add_info_hdr_default();
    }
    table add_info_hdr_udp_table {
        actions = { add_info_hdr_udp; add_info_hdr_udp_default; }
        key = { hdr.ipv4.srcAddr: exact; hdr.udp.dstPort : exact; }
        size = 1024; // Example size
        default_action = add_info_hdr_udp_default();
    }
    table alpha_shl_4_table {
        actions = { alpha_shl_4; }
        default_action = alpha_shl_4();
    }
    table alpha_times_15_table {
        actions = { alpha_times_15; }
        default_action = alpha_times_15();
    }
    table check_total_uncongest_state_table {
        actions = { check_total_uncongest_state_0; check_total_uncongest_state_1; check_total_uncongest_state_23; NoAction; }
        key = { meta.meta.total_uncongest_state_predicate: exact; } // Match result from maintain_total_uncongest_state
        // Entries needed for predicate values 0, 1, etc. based on logic.
        default_action = NoAction;
    }
    table check_uncongest_state_table {
        actions = { check_uncongest_state_0; check_uncongest_state_1; check_uncongest_state_23; NoAction; }
        key = { meta.meta.uncongest_state_predicate: exact; } // Match result from maintain_uncongest_state
        default_action = NoAction;
    }
    table counter_table {
        actions = { run_counter; }
        default_action = run_counter();
    }
    table div_accepted_rate_table {
        actions = { div_accepted_rate; }
        default_action = div_accepted_rate();
    }
    table div_aggregate_arrival_rate_table {
        actions = { div_aggregate_arrival_rate; }
        default_action = div_aggregate_arrival_rate();
    }
    table div_per_flow_rate_table {
        actions = { div_per_flow_rate; }
        default_action = div_per_flow_rate();
    }
    table div_total_accepted_rate_table {
        actions = { div_total_accepted_rate; }
        default_action = div_total_accepted_rate();
    }
    table div_total_aggregate_arrival_rate_table {
        actions = { div_total_aggregate_arrival_rate; }
        default_action = div_total_aggregate_arrival_rate();
    }
    table drop_packet_decision_table { // Renamed from drop_packet_table
        actions = { drop_packet; }
        default_action = drop_packet(); // Always drop if hit
        size = 1; // Only need one entry if always dropping
    }
    table estimate_accepted_rate_2_table {
        actions = { estimate_accepted_rate_2; }
        default_action = estimate_accepted_rate_2();
    }
    table estimate_accepted_rate_table {
        actions = { estimate_accepted_rate; }
        default_action = estimate_accepted_rate();
    }
    table estimate_aggregate_arrival_rate_table {
        actions = { estimate_aggregate_arrival_rate; }
        default_action = estimate_aggregate_arrival_rate();
    }
    table estimate_per_flow_rate_table {
        actions = { estimate_per_flow_rate; }
        default_action = estimate_per_flow_rate();
    }
    table estimate_total_accepted_rate_2_table {
        actions = { estimate_total_accepted_rate_2; }
        default_action = estimate_total_accepted_rate_2();
    }
    table estimate_total_accepted_rate_table {
        actions = { estimate_total_accepted_rate; }
        default_action = estimate_total_accepted_rate();
    }
    table estimate_total_aggregate_arrival_rate_table {
        actions = { estimate_total_aggregate_arrival_rate; }
        default_action = estimate_total_aggregate_arrival_rate();
    }
    table flowrate_shl_table {
        actions = { flowrate_shl; }
        default_action = flowrate_shl();
    }
    table flowrate_sum_01_table {
        actions = { flowrate_sum_01_01; flowrate_sum_01_0; flowrate_sum_01_1; flowrate_sum_01_none; }
        key = { meta.meta.randv: ternary; } // Match bits of randv
        /* Example entries (check logic):
           00xx -> flowrate_sum_01_none
           01xx -> flowrate_sum_01_0 (randv=1)
           10xx -> flowrate_sum_01_1 (randv=2)
           11xx -> flowrate_sum_01_01 (randv=3)
        */
        default_action = flowrate_sum_01_none(); // If no match (e.g., randv > 3?)
        size = 4; // Max entries based on key
    }
    table flowrate_sum_23_table {
        actions = { flowrate_sum_23_23; flowrate_sum_23_2; flowrate_sum_23_3; flowrate_sum_23_none; }
        key = { meta.meta.randv: ternary; } // Match bits of randv
        /* Example entries:
           xx00 -> flowrate_sum_23_none
           xx01 -> flowrate_sum_23_2 (randv=4?)
           xx10 -> flowrate_sum_23_3 (randv=8?)
           xx11 -> flowrate_sum_23_23 (randv=12?)
           Logic needs verification based on how randv maps to 0, L*4, L*8, L*12
        */
        default_action = flowrate_sum_23_none();
        size = 4;
    }
    table flowrate_times_randv_table {
        actions = { flowrate_times_randv; }
        default_action = flowrate_times_randv();
    }
    table get_14_alpha_table {
        actions = {
             get_14_alpha; // Parameterized version
             // Or list all specific actions: get_14_alpha_f0; get_14_alpha_f1; ...
        }
        key = { meta.meta.fraction_factor: exact; }
        // Default action needs parameters if using parameterized action
        default_action = get_14_alpha(9, 10, 11); // Corresponds to f0?
        size = 21; // 0 to 20
    }
    table get_34_alpha_table {
        actions = { get_34_alpha; get_34_alpha_w2; }
        key = { meta.meta.w2: exact; } // Match flag set by get_half_pktlen_*
        default_action = get_34_alpha(); // w2 = 0
        size = 2;
    }
    table get_accepted_rate_table {
        actions = { get_accepted_rate; }
        default_action = get_accepted_rate();
    }
    table get_accepted_rate_times_7_table {
        actions = { get_accepted_rate_times_7; }
        default_action = get_accepted_rate_times_7();
    }
    table get_aggregate_arrival_rate_table {
        actions = { get_aggregate_arrival_rate; }
        default_action = get_aggregate_arrival_rate();
    }
    table get_aggregate_arrival_rate_times_7_table {
        actions = { get_aggregate_arrival_rate_times_7; }
        default_action = get_aggregate_arrival_rate_times_7();
    }
    table get_alpha_table {
        actions = { get_alpha; }
        default_action = get_alpha();
    }
    table get_fraction_factor_table {
        actions = { get_fraction_factor; }
        default_action = get_fraction_factor();
    }
    table get_half_pktlen_table {
        actions = { get_half_pktlen; get_half_pktlen_w2; get_half_pktlen_w4; }
        key = { hdr.ipv4.srcAddr: exact; } // Match source IP for different weights?
        default_action = get_half_pktlen(); // Default weight
        size = 1024; // Example size
    }
    table get_minv_0_2_table {
        actions = { get_minv_0_2; }
        default_action = get_minv_0_2();
    }
    table get_minv_0_table {
        actions = { get_minv_0; }
        default_action = get_minv_0();
    }
    table get_minv_table {
        actions = { get_minv; }
        default_action = get_minv();
    }
    table get_per_flow_rate_table {
        actions = { get_per_flow_rate; }
        default_action = get_per_flow_rate();
    }
    table get_per_flow_rate_times_7_table {
        actions = { get_per_flow_rate_times_7; }
        default_action = get_per_flow_rate_times_7();
    }
    table get_random_value_table {
        actions = { get_random_value; }
        default_action = get_random_value();
    }
    table get_time_stamp_table {
        actions = { get_time_stamp; }
        default_action = get_time_stamp();
    }
    table get_total_accepted_rate_table {
        actions = { get_total_accepted_rate; }
        default_action = get_total_accepted_rate();
    }
    table get_total_accepted_rate_times_7_table {
        actions = { get_total_accepted_rate_times_7; }
        default_action = get_total_accepted_rate_times_7();
    }
    table get_total_aggregate_arrival_rate_table {
        actions = { get_total_aggregate_arrival_rate; }
        default_action = get_total_aggregate_arrival_rate();
    }
    table get_total_aggregate_arrival_rate_times_7_table {
        actions = { get_total_aggregate_arrival_rate_times_7; }
        default_action = get_total_aggregate_arrival_rate_times_7();
    }
    table get_total_alpha_table {
        actions = { get_total_alpha; }
        default_action = get_total_alpha();
    }
    table i2e_mirror_table {
        actions = { i2e_mirror; NoAction; }
        key = { hdr.ipv4.dstAddr: exact; } // Mirror based on destination?
        default_action = NoAction;
        size = 1024; // Example size
    }
    table ipv4_route_intermediate_table { // Renamed from ipv4_route_2
        actions = { set_egress_port; drop_packet; NoAction; }
        key = { hdr.ipv4.dstAddr: lpm; } // Use LPM for routing
        size = 8192; // Example size
        default_action = drop_packet; // Drop if no route match
    }
    table ipv4_route_final_table { // Renamed from ipv4_route_3
        actions = { set_egress_port_final; set_egress_port_final_udp; drop_packet; NoAction; }
        key = { hdr.ipv4.dstAddr: lpm; hdr.ipv4.protocol: exact; } // Route based on Dest IP and Protocol
        size = 8192;
        default_action = drop_packet;
    }
    table maintain_congest_state_table {
        actions = { maintain_congest_state; }
        default_action = maintain_congest_state();
    }
    table maintain_total_congest_state_table {
        actions = { maintain_total_congest_state; }
        default_action = maintain_total_congest_state();
    }
    table maintain_total_uncongest_state_table {
        actions = { maintain_total_uncongest_state; }
        default_action = maintain_total_uncongest_state();
    }
    table maintain_uncongest_state_table {
        actions = { maintain_uncongest_state; }
        default_action = maintain_uncongest_state();
    }
    table mod_resubmit_field_table {
        actions = { mod_resubmit_field; }
        default_action = mod_resubmit_field();
    }
    table put_src_up_table {
        actions = { put_src_up; }
        default_action = put_src_up();
    }
    table resubmit_if_drop_table { // Renamed from resubmit_2_table
        actions = { resubmit_packet; }
        default_action = resubmit_packet(); // Always resubmit if hit
        size = 1;
    }
    table resubmit_if_needed_table { // Renamed from resubmit_table
        actions = { resubmit_packet; }
        default_action = resubmit_packet(); // Always resubmit if hit
        size = 1;
    }
    table set_drop_flag_table { // Renamed from set_drop_table
        actions = { set_drop_flag; }
        default_action = set_drop_flag();
    }
    table set_recirc_check_flag_table { // Renamed from set_flag_table
        actions = { set_tcp_flag; set_udp_flag; }
        key = { hdr.ipv4.protocol: exact; } // Set based on protocol
        default_action = set_tcp_flag(); // Default to TCP? Check logic.
        size = 2; // TCP and UDP
    }
    table sum_accepted_rate_table {
        actions = { sum_accepted_rate; }
        default_action = sum_accepted_rate();
    }
    table sum_total_accepted_rate_table {
        actions = { sum_total_accepted_rate; }
        default_action = sum_total_accepted_rate();
    }

    // --- Apply Block for main_pipe ---
    apply {
        // Stage 0
        get_time_stamp_table.apply();
        get_random_value_table.apply();
        if (hdr.tcp.isValid()) {
            add_info_hdr_table.apply();
        } else { // Assuming UDP if not TCP (based on parser logic)
            add_info_hdr_udp_table.apply();
        }
        get_total_alpha_table.apply();
        get_half_pktlen_table.apply(); // Sets weights based on srcAddr

        // Stage 1
        estimate_per_flow_rate_table.apply();
        put_src_up_table.apply(); // Store lengths
        get_fraction_factor_table.apply();

        // Stage 2
        estimate_aggregate_arrival_rate_table.apply();
        estimate_total_aggregate_arrival_rate_table.apply();
        if (meta.meta.label == 0) { // Use estimated rate if available
            get_per_flow_rate_table.apply();
        } else { // Use stored rate (EWMA calculation)
            get_per_flow_rate_times_7_table.apply();
        }

        // Stage 3
        if (meta.meta.label != 0) { // If stored rate was used, divide by 8 (EWMA)
            div_per_flow_rate_table.apply();
        }
        if (meta.meta.per_tenant_A == 0) { // Use estimated rate
            get_aggregate_arrival_rate_table.apply();
        } else { // Use stored rate (EWMA calculation)
            get_aggregate_arrival_rate_times_7_table.apply();
        }
        if (meta.meta.total_A == 0) { // Use estimated rate
            get_total_aggregate_arrival_rate_table.apply();
        } else { // Use stored rate (EWMA calculation)
            get_total_aggregate_arrival_rate_times_7_table.apply();
        }

        // Stage 4
        get_alpha_table.apply();
        flowrate_shl_table.apply(); // Precompute shifts
        if (meta.meta.per_tenant_A != 0) { // If stored rate was used, divide by 8
            div_aggregate_arrival_rate_table.apply();
        }
        if (meta.meta.total_A != 0) { // If stored rate was used, divide by 8
            div_total_aggregate_arrival_rate_table.apply();
        }

        // Stage 5
        alpha_shl_4_table.apply(); // alpha * 16
        flowrate_sum_01_table.apply(); // Calculate part of label * randv
        flowrate_sum_23_table.apply(); // Calculate other part of label * randv
        run_counter(); // Update rate update counter
        get_minv_0_table.apply(); // label = min(per_tenant_A, total_alpha)
        get_minv_0_2_table.apply(); // label_shl_3 = min(total_A, C)

        // Stage 6
        flowrate_times_randv_table.apply(); // Final label * randv
        alpha_times_15_table.apply(); // alpha * 15
        // Check congestion state based on label vs total_alpha
        // Assuming C = 115200000
        if (meta.meta.label == hdr.recirculate_hdr.total_alpha) { // Might be >= ? Check HCSFQ logic
             maintain_congest_state_table.apply();
        } else {
             maintain_uncongest_state_table.apply();
        }

        // Stage 7
        get_minv_table.apply(); // min(alpha * 15, label * randv)
        // Check total congestion state based on min(total_A, C) vs C
        if (meta.meta.label_shl_3 == 115200000) { // total_A >= C ?
            maintain_total_congest_state_table.apply();
        } else { // total_A < C
            maintain_total_uncongest_state_table.apply();
        }

        // Stage 8: Drop decision and rate estimation update
        if (meta.meta.min_alphatimes15_labeltimesrand == meta.meta.label_times_randv) { // Pkt accepted path (label*randv <= alpha*15)
            estimate_accepted_rate_table.apply();
            estimate_total_accepted_rate_table.apply();
        } else { // Pkt dropped path
            set_drop_flag_table.apply(); // Mark for drop
            estimate_accepted_rate_2_table.apply(); // Update rate estimation (reset path)
            estimate_total_accepted_rate_2_table.apply(); // Update total rate estimation (reset path)
        }
        get_14_alpha_table.apply(); // Calculate 1/4 alpha based on fraction_factor

        // Stage 9: Check uncongested states and signal resubmit if needed
        if (meta.meta.label != hdr.recirculate_hdr.total_alpha) { // Only check if not congested in stage 6
             check_uncongest_state_table.apply(); // May trigger resubmit flag
        }
        if (meta.meta.per_tenant_F != 0) { // If accepted rate was calculated
            sum_accepted_rate_table.apply(); // Signals resubmit
        }
        if (meta.meta.total_F != 0) { // If total accepted rate was calculated
            sum_total_accepted_rate_table.apply(); // Signals resubmit
        }
        if (meta.meta.label_shl_3 != 115200000) { // Only check if not total congested in stage 7
             check_total_uncongest_state_table.apply(); // May trigger resubmit flag
        }

        // Stage 10: Get stored rates for EWMA, adjust alpha, modify headers for recirc/output
        if (meta.meta.per_tenant_F == 0) { // Get estimated rate
            get_accepted_rate_table.apply();
        } else { // Get EWMA sum for division
            get_accepted_rate_times_7_table.apply();
        }
        if (meta.meta.total_F == 0) { // Get estimated rate
            get_total_accepted_rate_table.apply();
        } else { // Get EWMA sum for division
            get_total_accepted_rate_times_7_table.apply();
        }
        get_34_alpha_table.apply(); // Calculate 3/4 alpha based on weight flag
        mod_resubmit_field_table.apply(); // Copy drop decision to recirc header
        // Set flags on packet (TCP.res or UDP.dstPort) if resubmit needed
        if (meta.meta.to_resubmit != 0 || meta.meta.to_resubmit_2 != 0 || meta.meta.to_resubmit_3 != 0) {
            set_recirc_check_flag_table.apply();
        }
        ipv4_route_intermediate_table.apply(); // Perform intermediate routing lookup

        // Stage 11: Final EWMA division and output decision (resubmit, route, drop)
        if (meta.meta.per_tenant_F != 0) { // Divide by 8 if EWMA sum was used
            div_accepted_rate_table.apply();
        }
        if (meta.meta.total_F != 0) { // Divide by 8 if EWMA sum was used
            div_total_accepted_rate_table.apply();
        }

        // Output decision
        bool needs_resubmit = (meta.meta.to_resubmit != 0 || meta.meta.to_resubmit_2 != 0 || meta.meta.to_resubmit_3 != 0);
        bool marked_for_drop = (meta.meta.to_drop != 0);

        if (needs_resubmit) {
            if (!marked_for_drop) {
                i2e_mirror_table.apply(); // Mirror accepted packet before resubmit? Check logic.
                resubmit_if_needed_table.apply(); // Resubmit for recirc_pipe
            } else {
                // Dropped packet that still needs recirculation processing?
                resubmit_if_drop_table.apply(); // Resubmit for recirc_pipe (different table?)
            }
        } else { // Not resubmitting
            if (!marked_for_drop) {
                ipv4_route_final_table.apply(); // Perform final routing and send out
            } else {
                drop_packet_decision_table.apply(); // Drop the packet
            }
        }
    }
}


// --- Control: Recirculation Pipeline Logic ---

control recirc_pipe(inout headers_t hdr,
                    inout metadata_t meta,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)
{
    // --- Register Actions for recirc_pipe ---

    RegisterAction<get_accepted_rate_layout, bit<32>, void>(stored_accepted_rate_reg) set_average_accepted_rate_logic = {
        void apply(inout get_accepted_rate_layout value) {
            // Use MathUnit for EWMA calculation: (rate * 7 + new_value) / 8
            // value.lo holds the temporary value from math unit
            value.lo = ewma_math_unit.execute(hdr.recirculate_hdr.per_tenant_F); // Calculates (rate * 7) / 8 ? Check MathUnit spec
            // Update the stored rate (hi part) - This seems incorrect. EWMA needs old value.
            // Assuming MathUnit performs EWMA: value.hi = ewma(value.hi, hdr.recirculate_hdr.per_tenant_F)
            // Let's assume the converter logic was roughly: store new rate in hi, store EWMA helper in lo.
            value.hi = hdr.recirculate_hdr.per_tenant_F; // Store the final calculated rate
            // value.lo calculation needs verification based on MathUnit behavior.
        } // Action: set_average_accepted_rate_action
    };
    RegisterAction<get_agg_arrival_rate_layout, bit<32>, void>(stored_aggregate_arrival_rate_reg) set_average_aggregate_arrival_rate_logic = {
        void apply(inout get_agg_arrival_rate_layout value) {
            value.lo = ewma_math_unit.execute(hdr.info_hdr.per_tenant_A);
            value.hi = hdr.info_hdr.per_tenant_A;
        } // Action: set_average_aggregate_arrival_rate_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(delta_c_reg) get_delta_c_logic = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } // Action: get_delta_c_action
    };
     RegisterAction<get_per_flow_rate_layout, bit<32>, void>(stored_per_flow_rate_reg) set_average_per_flow_rate_logic = {
        void apply(inout get_per_flow_rate_layout value) {
            value.lo = ewma_math_unit.execute(hdr.info_hdr.label);
            value.hi = hdr.info_hdr.label;
        } // Action: set_average_per_flow_rate_action
    };
    RegisterAction<get_total_accepted_rate_layout, bit<32>, void>(total_stored_accepted_rate_reg) set_average_total_accepted_rate_logic = {
        void apply(inout get_total_accepted_rate_layout value) {
            value.lo = ewma_math_unit.execute(hdr.recirculate_hdr.total_F);
            value.hi = hdr.recirculate_hdr.total_F;
        } // Action: set_average_total_accepted_rate_action
    };
    RegisterAction<get_total_agg_arrival_rate_layout, bit<32>, void>(total_stored_aggregate_arrival_rate_reg) set_average_total_aggregate_arrival_rate_logic = {
         void apply(inout get_total_agg_arrival_rate_layout value) {
            value.lo = ewma_math_unit.execute(hdr.info_hdr.total_A);
            value.hi = hdr.info_hdr.total_A;
        } // Action: set_average_total_aggregate_arrival_rate_action
    };
    RegisterAction<bit<32>, bit<32>, void>(alpha_reg) update_per_tenant_alpha_by_F1_minus_logic = {
        void apply(inout bit<32> value) {
            // If pertenantF < totalalpha (congested=false, pertenantF_leq=true) and state=congested(true)?
            // Decrease alpha
            // Assuming delta_total_alpha is calculated rate change
            if (value > meta.meta.delta_total_alpha) { // Prevent underflow
                 value = value - meta.meta.delta_total_alpha;
            } else {
                 value = 0;
            }
            // Original just set value = hdr.recirculate_hdr.per_tenant_alpha. Why? Check logic.
            // Assuming decrease based on context:
            // value = (value > meta.meta.delta_total_alpha) ? (value - meta.meta.delta_total_alpha) : 0;
        } // Action: update_per_tenant_alpha_by_F1_minus_action
    };
    RegisterAction<bit<32>, bit<32>, void>(alpha_reg) update_per_tenant_alpha_by_F1_plus_logic = {
        void apply(inout bit<32> value) {
            // If pertenantF >= totalalpha (congested=false, pertenantF_leq=false) and state=congested(true)?
            // Increase alpha, capped at C
            bit<32> new_alpha = value + meta.meta.delta_total_alpha;
            // Assuming C = 115200000
            value = (new_alpha <= 115200000) ? new_alpha : 115200000;
        } // Action: update_per_tenant_alpha_by_F1_plus_action
    };
    RegisterAction<bit<32>, bit<32>, void>(alpha_reg) update_per_tenant_alpha_to_maxalpha_logic = {
        void apply(inout bit<32> value) {
            // If state=uncongested(false)? Increase alpha?
            bit<32> new_alpha = value + meta.meta.delta_total_alpha;
            // Assuming C = 115200000
            value = (new_alpha <= 115200000) ? new_alpha : 115200000;
            // Original only added if value <= C. Let's assume cap is desired.
        } // Action: update_per_tenant_alpha_to_maxalpha_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(total_alpha_reg) update_total_alpha_by_F0_logic = {
        void apply(inout bit<32> value, out bit<32> rv) {
             // If state=congested(true)? Decrease alpha?
             // Assuming C = 115200000
             if (hdr.recirculate_hdr.total_F > 115200000) { // If accepted rate > capacity
                 // Decrease alpha. Original code set value = hdr.recirculate_hdr.total_alpha which seems wrong.
                 // Let's assume decrease by fixed amount if F>C
                 if (value > 400) { value = value - 400; } else { value = 0; } // Decrease by 400?
             } else { // F <= C
                 // Increase alpha? Original added 400.
                 bit<32> new_alpha = value + 400;
                 value = (new_alpha <= 115200000) ? new_alpha : 115200000; // Cap increase
             }
             rv = value; // Return new alpha
        } // Action: update_total_alpha_by_F0_action
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(total_alpha_reg) update_total_alpha_to_maxalpha_logic = {
        void apply(inout bit<32> value, out bit<32> rv) {
             // If state=uncongested(false)? Increase alpha?
             // Assuming C = 115200000
             if (!(hdr.recirculate_hdr.total_F > 115200000)) { // If F <= C
                 bit<32> new_alpha = value + 400;
                 value = (new_alpha <= 115200000) ? new_alpha : 115200000; // Increase capped
             } // else: F > C, do nothing (don't increase)
             rv = value; // Return new alpha
        } // Action: update_total_alpha_to_maxalpha_action
    };

    // --- Actions for recirc_pipe ---

    action get_delta_c() {
        meta.meta.delta_c = get_delta_c_logic.execute(0); // Global index 0
    }
    action get_delta_total_alpha() {
        // Calculate delta based on total alpha (shift approximates division)
        meta.meta.delta_total_alpha = hdr.recirculate_hdr.total_alpha >> 13; // Divide by 8192? Check HCSFQ paper.
    }
    action get_min_of_pertenantF_total_alpha() {
        meta.meta.min_pertenantF_totalalpha = (hdr.recirculate_hdr.per_tenant_F <= hdr.recirculate_hdr.total_alpha) ? hdr.recirculate_hdr.per_tenant_F : hdr.recirculate_hdr.total_alpha;
    }
    action getmin_delta_total_alpha() { // Cap the delta alpha change
        meta.meta.delta_total_alpha = (meta.meta.delta_total_alpha <= meta.meta.delta_c) ? meta.meta.delta_total_alpha : meta.meta.delta_c;
    }
    action set_average_accepted_rate() {
        set_average_accepted_rate_logic.execute(hdr.info_hdr.tenant_id);
    }
    action set_average_aggregate_arrival_rate() {
        set_average_aggregate_arrival_rate_logic.execute(hdr.info_hdr.tenant_id);
    }
    action set_average_per_flow_rate() {
        set_average_per_flow_rate_logic.execute(hdr.info_hdr.flow_id);
    }
    action set_average_total_accepted_rate() {
        set_average_total_accepted_rate_logic.execute(0); // Global index 0
    }
    action set_average_total_aggregate_arrival_rate() {
        set_average_total_aggregate_arrival_rate_logic.execute(0);
    }
    action set_pertenantF_leq_totalalpha() { // Mark flag if F <= alpha
        hdr.recirculate_hdr.pertenantF_leq_totalalpha = 1;
    }
    action update_per_tenant_alpha_to_maxalpha() { // state=uncongested path
        update_per_tenant_alpha_to_maxalpha_logic.execute(hdr.info_hdr.tenant_id);
    }
    action update_per_tenant_alpha_by_F1_plus() { // state=congested, F >= alpha path
        update_per_tenant_alpha_by_F1_plus_logic.execute(hdr.info_hdr.tenant_id);
    }
    action update_per_tenant_alpha_by_F1_minus() { // state=congested, F < alpha path
        update_per_tenant_alpha_by_F1_minus_logic.execute(hdr.info_hdr.tenant_id);
    }
    action update_total_alpha_to_maxalpha() { // state=uncongested path
        hdr.recirculate_hdr.total_alpha = update_total_alpha_to_maxalpha_logic.execute(0);
    }
    action update_total_alpha_by_F0() { // state=congested path
        hdr.recirculate_hdr.total_alpha = update_total_alpha_by_F0_logic.execute(0);
    }
    action drop_recirculated_packet() { // Renamed from _drop in recirc_pipe
        ig_intr_md_for_dprsr.drop_ctl = TNA_DropCtl_t.DROP;
    }

    // --- Tables for recirc_pipe ---

    table drop_packet_recirc_table { // Renamed from drop_packet_2_table
        actions = { drop_recirculated_packet; }
        default_action = drop_recirculated_packet(); // Always drop if hit
        size = 1;
    }
    table get_delta_c_table {
        actions = { get_delta_c; }
        default_action = get_delta_c();
    }
    table get_delta_total_alpha_table {
        actions = { get_delta_total_alpha; }
        default_action = get_delta_total_alpha();
    }
    table get_min_of_pertenantF_total_alpha_table {
        actions = { get_min_of_pertenantF_total_alpha; }
        default_action = get_min_of_pertenantF_total_alpha();
    }
    table getmin_delta_total_alpha_table {
        actions = { getmin_delta_total_alpha; }
        default_action = getmin_delta_total_alpha();
    }
    table set_average_accepted_rate_table {
        actions = { set_average_accepted_rate; }
        default_action = set_average_accepted_rate();
    }
    table set_average_aggregate_arrival_rate_table {
        actions = { set_average_aggregate_arrival_rate; }
        default_action = set_average_aggregate_arrival_rate();
    }
    table set_average_per_flow_rate_table {
        actions = { set_average_per_flow_rate; }
        default_action = set_average_per_flow_rate();
    }
    table set_average_total_accepted_rate_table {
        actions = { set_average_total_accepted_rate; }
        default_action = set_average_total_accepted_rate();
    }
    table set_average_total_aggregate_arrival_rate_table {
        actions = { set_average_total_aggregate_arrival_rate; }
        default_action = set_average_total_aggregate_arrival_rate();
    }
    table set_pertenantF_leq_totalalpha_table {
        actions = { set_pertenantF_leq_totalalpha; }
        default_action = set_pertenantF_leq_totalalpha();
    }
    table update_per_tenant_alpha_table {
        actions = { update_per_tenant_alpha_to_maxalpha; update_per_tenant_alpha_by_F1_plus; update_per_tenant_alpha_by_F1_minus; NoAction; }
        key = {
            hdr.recirculate_hdr.congested: exact; // Matches bit flags set in main_pipe
            hdr.recirculate_hdr.pertenantF_leq_totalalpha: exact; // Matches flag set here
        }
        /* Logic based on HCSFQ paper / original code intent:
           congested=T, leq=T -> minus (F<alpha, congested)
           congested=T, leq=F -> plus  (F>=alpha, congested)
           congested=F, leq=T -> maxalpha? (uncongested)
           congested=F, leq=F -> maxalpha? (uncongested)
           Need to verify which bits in 'congested' correspond to per-tenant vs total state.
           Assuming bit 3 (0x08) = per_tenant_false, bit 4 (0x10) = total_false
           Assuming bit 0 (0x01) = per_tenant_true?, bit 1 (0x02) = total_true? Check flags logic.
           Let's assume a simplified key match for now:
           key = { state_is_congested : exact; is_F_le_alpha : exact; }
        */
        default_action = NoAction; // If no condition met
        size = 4; // Max entries based on key
    }
    table update_total_alpha_table {
        actions = { update_total_alpha_to_maxalpha; update_total_alpha_by_F0; NoAction; }
        key = { hdr.recirculate_hdr.congested: exact; } // Match total congestion state bit
        /* Logic:
           congested=T -> by_F0 (decrease if F>C, else increase)
           congested=F -> maxalpha (increase if F<=C)
           Need to verify which bits in 'congested' mean total congestion.
           Let's assume bit 1 (0x02) = total_true?, bit 4 (0x10)=total_false?
        */
        default_action = NoAction;
        size = 2; // Max entries based on key
    }

    // --- Apply Block for recirc_pipe ---
    apply {
        // Stage 0
        update_total_alpha_table.apply(); // Update global alpha based on total state
        get_delta_c_table.apply(); // Get configured delta_c limit

        // Stage 1
        get_delta_total_alpha_table.apply(); // Calculate alpha change based on total_alpha
        get_min_of_pertenantF_total_alpha_table.apply(); // Find min(F, alpha)

        // Stage 2
        set_average_per_flow_rate_table.apply(); // Update EWMA for per-flow rate
        // Set flag if per_tenant_F <= total_alpha
        if (hdr.recirculate_hdr.per_tenant_F <= hdr.recirculate_hdr.total_alpha) {
             set_pertenantF_leq_totalalpha_table.apply();
        }

        // Stage 3
        set_average_aggregate_arrival_rate_table.apply(); // Update EWMA for tenant arrival rate
        set_average_total_aggregate_arrival_rate_table.apply(); // Update EWMA for total arrival rate
        getmin_delta_total_alpha_table.apply(); // Cap the alpha change

        // Stage 4
        update_per_tenant_alpha_table.apply(); // Update tenant alpha based on its state

        // Stage 10 (Matches main_pipe stage for consistency?)
        set_average_accepted_rate_table.apply(); // Update EWMA for tenant accepted rate
        set_average_total_accepted_rate_table.apply(); // Update EWMA for total accepted rate

        // Final action: Drop the recirculated packet (it served its purpose)
        drop_packet_recirc_table.apply();
    }
}


// --- Control: Main Ingress Logic ---

control ingress(inout headers_t hdr,
                inout metadata_t meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_parser_aux,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
{
    // Instantiate the pipeline stages
    main_pipe() main_pipeline;
    recirc_pipe() recirc_pipeline;

    apply {
        // Check if packet contains valid L4 header we process
        if (hdr.tcp.isValid() || hdr.udp.isValid()) {
            // Check if packet contains the custom info_hdr (signifying recirculated packet)
            if (!hdr.info_hdr.isValid()) {
                // Normal packet path
                main_pipeline.apply(hdr, meta, ig_intr_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
            } else {
                // Recirculated packet path
                recirc_pipeline.apply(hdr, meta, ig_intr_md_for_dprsr);
            }
        } else {
            // Packet is not TCP/UDP - simple L3 forward or drop?
            // Add basic L3 forwarding table if needed, e.g., using ipv4_route_intermediate_table
            // ipv4_route_intermediate_table.apply(); // Example
            // Or just drop if non-TCP/UDP are not supported
             drop_packet();
        }
    }
}

// --- Deparsers ---

control IngressDeparserImpl(packet_out pkt,
                            inout headers_t hdr,
                            in metadata_t meta,
                            in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                            in ingress_intrinsic_metadata_t ig_intr_md)
{
    apply {
        // Emit mirror header if mirroring is active
        if (ig_intr_md_for_dprsr.mirror_type == TNA_MirrorType_t.I2E_MIRROR ||
            ig_intr_md_for_dprsr.mirror_type == TNA_MirrorType_t.I2I_MIRROR) {
            // Construct mirror header payload dynamically if needed
            ig_mirror_header_1_t mirror_hdr_payload = {
                mirror_source : 9, // Example source ID
                current_node_meta_clone_md : meta.current_node_meta.clone_md
            };
            // Emit mirror packet using mirror session extern and ID
            // mirror_session.emit(meta.__bfp4c_compiler_generated_meta.mirror_id, mirror_hdr_payload);
            // Check TNA docs for exact mirror extern usage.
        }

        // Emit packet headers in order
        pkt.emit(hdr.ethernet);
        if(hdr.ipv4.isValid()){ pkt.emit(hdr.ipv4); }
        if(hdr.tcp.isValid()) { pkt.emit(hdr.tcp); }
        if(hdr.udp.isValid()) { pkt.emit(hdr.udp); }
        // Emit custom headers only if they are valid (present)
        if(hdr.info_hdr.isValid()) { pkt.emit(hdr.info_hdr); }
        if(hdr.recirculate_hdr.isValid()) { pkt.emit(hdr.recirculate_hdr); }
    }
}

control EgressDeparserImpl(packet_out pkt,
                           inout headers_t hdr,
                           in metadata_t meta,
                           in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                           in egress_intrinsic_metadata_t eg_intr_md,
                           in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser_aux)
{
    apply {
        // Recalculate IPv4 checksum if header is present and valid
        if (hdr.ipv4.isValid()) {
            checksum_engine.clear();
            checksum_engine.update({
                hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.ecn_flag,
                hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset,
                hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr
            });
            hdr.ipv4.hdrChecksum = checksum_engine.get();
        }
        // Recalculate L4 checksums if needed (TCP/UDP) - requires pseudo-header

        // Emit packet headers
        pkt.emit(hdr.ethernet);
        if(hdr.ipv4.isValid()){ pkt.emit(hdr.ipv4); }
        if(hdr.tcp.isValid()) { pkt.emit(hdr.tcp); }
        if(hdr.udp.isValid()) { pkt.emit(hdr.udp); }
        // Custom headers are typically removed before egress, but emit if valid
        if(hdr.info_hdr.isValid()) { pkt.emit(hdr.info_hdr); }
        if(hdr.recirculate_hdr.isValid()) { pkt.emit(hdr.recirculate_hdr); }
    }
}

// --- Pipeline Instantiation ---

Pipeline(
    IngressParserImpl(),
    ingress(), // Main ingress control block
    IngressDeparserImpl(),
    EgressParserImpl(),
    egress(),  // Main egress control block
    EgressDeparserImpl()
) pipe;

// Instantiate the switch with the defined pipeline
Switch(pipe) main;


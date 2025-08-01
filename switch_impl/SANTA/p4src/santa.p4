/* -*- P4_16 -*- */
//need to handle ARP
#include <core.p4>
#include <tna.p4>

#include "include/headers.p4"
#include "include/parser.p4"
#include "include/cms.p4"

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/

// modify later
#define ig_port 25 
#define eg_port 24
// #define sender_mac 0xb8cef6046bd0
// #define receiver_mac 0xb8cef6046bd1

/* for 4 queues 17920 */
// #define HASH_TABLE_SIZE 71680
#define HASH_TABLE_SIZE 65535
#define Q_ASSIGN_TABLE_SIZE 90000
#define NUM_Q 5 // this is 0 to NUM_Q + (mice)
#define CONCAT_INDEX 2 // log(NUM_Q)-1 (rounded up)
#define MAX_UINT32 4294967295


//  flags for reg status
#define HASH_TABLE_OP_SUCCESS 0
#define HASH_TABLE_OP_FAILURE 1
#define HASH_TABLE_OP_EMPTY   2
// #define Q_ALREADY_EXISTS   100

#define NON_SANTA   3
#define SANTA       1
#define SANTA_VALID 2

// caida change : diff collisions
#define IP_NORMAL 0x0a010101
#define IP_COLLIDE 0x0a010102

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

control Ingress(/* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{   
    CMSIngress() cms;

    Random<bit<8>>() rand;
    Hash<bit<32>>(HashAlgorithm_t.CRC32) hash_pkt_fingerprint_ig;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_fp;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hashfunction_table;
    bit<32> pkt_fingerprint;
    bit<16> hash_table_index;
    bit<16> hash_table_fp;
    bit<8>  w_random;
    bit<16> q_num;
    bit<8>  pkt_flag;

    action get_htable_index(){
        hash_table_index = hashfunction_table.get({
            hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol,
            meta.src_port, meta.dst_port        // add 4w0 back post debugging
            });
    }

    action get_htable_fp(){
        hash_table_fp = hash_fp.get({
            hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol,
            meta.src_port, meta.dst_port, 8w0
            });
    }

    action get_pkt_fingerprint(){
        pkt_fingerprint = hash_pkt_fingerprint_ig.get({
            hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol,
            meta.src_port, meta.dst_port
            });
    }
    action set_egress_port(PortId_t egress_port) {
        ig_tm_md.ucast_egress_port = egress_port;
    }

    action set_queue(bit<8> queue_num) {
        ig_tm_md.qid = queue_num[4:0];
    }

    Register<ig_hash_table_entry, bit<16>>(HASH_TABLE_SIZE, {0, 0}) ig_hash_table1;
    RegisterAction<ig_hash_table_entry, bit<16>, bit<16>>(ig_hash_table1) reg_insert_ig_hash_table1 = {
        void apply(inout ig_hash_table_entry reg_value, out bit<16> rv){

            bool entry_is_empty = (reg_value.fp == 0);

            if(entry_is_empty){ // do the insertion
                reg_value.fp = hash_table_fp;
                reg_value.q_alloc = (bit<16>)ig_tm_md.qid;
                rv = reg_value.q_alloc;
            }
            else{
                rv = reg_value.q_alloc;
            }
        }
    };
    
    table q_assign_wr {
        key = {
            w_random : range;
        }
        actions = {
            set_queue;
        }
        default_action = set_queue(NUM_Q); // while clearing the table some ranges may not hit 
        // size = 64;
    }

    table forwarding {
          key = {
              hdr.ethernet.src_addr: exact;
          }
          actions = {
              set_egress_port;
          }
          const entries = {
            0xb8cef6046bd0 : set_egress_port(eg_port);
            0xb8cef6046bd1 : set_egress_port(ig_port);
          }
          default_action = set_egress_port(64);
          size = 64;
    }

    table port_forward {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            set_egress_port;
        }
        const entries = {
            25 : set_egress_port(24);
            24 : set_egress_port(25);
        }
        default_action = set_egress_port(64);
        size = 64;
    }

    @idletime_precision(3)
    table q_assign {
        key = {
            pkt_fingerprint: exact;
        }
        actions = {
            set_queue;
        }
        idle_timeout = true;
        size = Q_ASSIGN_TABLE_SIZE;
    }


    apply {
        /* assign the queue based on the weights for each queue */
        w_random = rand.get();
        forwarding.apply();
        // caida change: port forwarding
        // port_forward.apply();
        hdr.bridge.ingress_timestamp = ig_prsr_md.global_tstamp;
        pkt_flag = NON_SANTA;

        if (hdr.ethernet.ether_type != ether_type_t.IPV4 || hdr.ipv4.protocol == 1){  // handling ARP
            // add multicast rules here?
            ig_tm_md.qid = NUM_Q;
        } 
        else if (ig_intr_md.ingress_port == ig_port && (hdr.tcp.isValid() || hdr.udp.isValid())){ // caida change 

        /*  ig_tm_md.deflect_on_drop = 1w1; // enable deflect on drop
            
            cms.apply(hdr, meta, ig_intr_md, ig_prsr_md, ig_dprsr_md, ig_tm_md, pkt_flag);

            if (pkt_flag == SANTA) { // >10 pkts in CMS
                get_pkt_fingerprint();
                if (!q_assign.apply().hit) {
                    q_assign_wr.apply();    // get a temp qnum if the value was not initialized
                    get_htable_fp();
                    get_htable_index();
                    q_num = reg_insert_ig_hash_table1.execute(hash_table_index);
                    ig_tm_md.qid = (bit<5>)q_num;
                }
            }
            else {
                ig_tm_md.qid = NUM_Q; // the last queue is the mice flow queue
            } */
            
            ig_tm_md.deflect_on_drop = 1w1; // enable deflect on drop
            
            get_pkt_fingerprint();
            if (!q_assign.apply().hit) {
                // apply the CMS here
                cms.apply(hdr, meta, ig_intr_md, ig_prsr_md, ig_dprsr_md, ig_tm_md, pkt_flag);
            
                if (pkt_flag == SANTA) { // >10 pkts in CMS
                    q_assign_wr.apply();    // get a temp qnum if the value was not initialized
                    get_htable_fp();
                    get_htable_index();
                    q_num = reg_insert_ig_hash_table1.execute(hash_table_index); // store/fetch the weighted random queue assign
                    ig_tm_md.qid = (bit<5>)q_num;
                }
                else {
                    ig_tm_md.qid = NUM_Q; // the last queue is the mice flow queue
                }
            }
            else {
                pkt_flag = SANTA;
            }    
        }
        hdr.bridge.pkt_flag = pkt_flag;
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/


/***************** M A T C H - A C T I O N  *********************/
control Egress(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */    
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    Hash<bit<32>>(HashAlgorithm_t.CRC32) hash_pkt_fingerprint;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hashfunction_table;

    bit<32> pkt_fingerprint;
    bit<32> queuing_delay_a;
    bit<32> queuing_delay_b;
    bit<32> queuing_delay;
    bit<32> min_val;
    // bit<14> temp_hash_index;
    bit<16> hash_table_index_eg;
    bit<8> entry_flag;
    bit<1> copy;

    action get_pkt_fingerprint(){
        pkt_fingerprint = hash_pkt_fingerprint.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, meta.src_port, meta.dst_port});
    }

    action get_htable_index(){
        hash_table_index_eg = hashfunction_table.get({
            // 4w0, 
            hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol,
            meta.src_port, meta.dst_port
            // 4w0
            });
    }

    Register<bit<1>, bit<1>>(1) working_copy;
    RegisterAction<bit<1>, bit<1>, bit<1>>(working_copy) get_working_copy = { 
        void apply(inout bit<1> register_data, out bit<1> result){
			result = register_data; 
        }
    };

    Register<hash_table_entry, bit<16>>(HASH_TABLE_SIZE, {0, 0}) hash_table1;
    RegisterAction<hash_table_entry, bit<16>, bit<32>>(hash_table1) reg_insert_hash_table1 = {
        void apply(inout hash_table_entry reg_value, out bit<32> rv){

            rv = HASH_TABLE_OP_FAILURE; // default to tell that insertion FAILED
            hash_table_entry orig_val = reg_value;
            bool entry_is_empty = (orig_val.fp == 0);

            if(entry_is_empty){ // do the insertion
                reg_value.fp = pkt_fingerprint;
                reg_value.q_delay = queuing_delay;
                rv = HASH_TABLE_OP_SUCCESS;
            }
            else{
                if (orig_val.fp == pkt_fingerprint) {
                    reg_value.q_delay = reg_value.q_delay |+| queuing_delay;
                    rv = HASH_TABLE_OP_SUCCESS;
                }
                else {
                    rv = HASH_TABLE_OP_FAILURE;
                }
            }
        }
    };

    Register<hash_table_entry, bit<16>>(HASH_TABLE_SIZE, {0, 0}) hash_table1_copy;
    RegisterAction<hash_table_entry, bit<16>, bit<32>>(hash_table1_copy) reg_insert_hash_table1_copy = {
        void apply(inout hash_table_entry reg_value, out bit<32> rv){

            rv = HASH_TABLE_OP_FAILURE; // default to tell that insertion FAILED
            hash_table_entry orig_val = reg_value;
            bool entry_is_empty = (orig_val.fp == 0);

            if(entry_is_empty){ // do the insertion
                reg_value.fp = pkt_fingerprint;
                reg_value.q_delay = queuing_delay;
                rv = HASH_TABLE_OP_SUCCESS;
            }
            else{
                if (orig_val.fp == pkt_fingerprint) {
                    reg_value.q_delay = reg_value.q_delay |+| queuing_delay;
                    rv = HASH_TABLE_OP_SUCCESS;
                }
                else {
                    rv = HASH_TABLE_OP_FAILURE;
                }
            }
        }
    };

    // ALTERNATE R/W REG
    Register<hash_table_entry, bit<16>>(HASH_TABLE_SIZE, {0, 0}) hash_table2;
    RegisterAction<hash_table_entry, bit<16>, bit<32>>(hash_table2) reg_insert_hash_table2 = {
        void apply(inout hash_table_entry reg_value, out bit<32> rv){

            rv = HASH_TABLE_OP_FAILURE; // default to tell that insertion FAILED
            hash_table_entry orig_val = reg_value;
            
            bool entry_is_empty = (orig_val.fp == 0);

            if(entry_is_empty){ // do the insertion
                reg_value.fp = pkt_fingerprint;
                reg_value.q_delay = queuing_delay;
                rv = HASH_TABLE_OP_SUCCESS;
            }
            else{
                if (orig_val.fp == pkt_fingerprint) {
                    reg_value.q_delay = reg_value.q_delay |+| queuing_delay;
                    rv = HASH_TABLE_OP_SUCCESS;
                }
                else {
                    rv = HASH_TABLE_OP_FAILURE;
                }
            }
        }
    };

    Register<hash_table_entry, bit<16>>(HASH_TABLE_SIZE, {0, 0}) hash_table2_copy;
    RegisterAction<hash_table_entry, bit<16>, bit<32>>(hash_table2_copy) reg_insert_hash_table2_copy = {
        void apply(inout hash_table_entry reg_value, out bit<32> rv){

            rv = HASH_TABLE_OP_FAILURE; // default to tell that insertion FAILED
            hash_table_entry orig_val = reg_value;
            
            bool entry_is_empty = (orig_val.fp == 0);

            if(entry_is_empty){ // do the insertion
                reg_value.fp = pkt_fingerprint;
                reg_value.q_delay = queuing_delay;
                rv = HASH_TABLE_OP_SUCCESS;
            }
            else{
                if (orig_val.fp == pkt_fingerprint) {
                    reg_value.q_delay = reg_value.q_delay |+| queuing_delay;
                    rv = HASH_TABLE_OP_SUCCESS;
                }
                else {
                    rv = HASH_TABLE_OP_FAILURE;
                }
            }
        }
    };

    action q_action1() {
        queuing_delay_a = eg_prsr_md.global_tstamp[39:8];
        queuing_delay_b = meta.bridge_meta.ingress_timestamp[39:8];
    }

    action handle_wrap() {
        queuing_delay = queuing_delay + MAX_UINT32;
    }

    apply { 
        
        if (meta.bridge_meta.pkt_flag != NON_SANTA && eg_intr_md.egress_port == eg_port){
            q_action1();
            queuing_delay = queuing_delay_a - queuing_delay_b;
            min_val = min(queuing_delay_a, queuing_delay_b);
            if (min_val != queuing_delay_b) {
                handle_wrap();
            }

            copy = get_working_copy.execute(0);  // maintain a read and write copy for qdelay 

            // compute 'pkt_fingerprint' and 'hash_table_indexeg'
            get_pkt_fingerprint();
            get_htable_index();

            // divide this index corresponding to each 
            @in_hash{ hash_table_index_eg = eg_intr_md.egress_qid[CONCAT_INDEX:0]++hash_table_index_eg[(14-CONCAT_INDEX):0];}

            if (copy == 0) {
                entry_flag = (bit<8>)reg_insert_hash_table1.execute(hash_table_index_eg);
                // hash collision
                if (entry_flag == HASH_TABLE_OP_FAILURE){
                    entry_flag = (bit<8>)reg_insert_hash_table1_copy.execute(hash_table_index_eg);
                }
            }
            else {
                entry_flag = (bit<8>)reg_insert_hash_table2.execute(hash_table_index_eg);
                if (entry_flag == HASH_TABLE_OP_FAILURE){
                    entry_flag = (bit<8>)reg_insert_hash_table2_copy.execute(hash_table_index_eg);
                }  
            }

            // caida change: if the hash still collide communicate to the CP using the internal port
            // if (entry_flag == HASH_TABLE_OP_FAILURE) {
            //     hdr.ipv4.identification = 1; 
            //     // hdr.ipv4.dst_addr = IP_COLLIDE; // collision
            // }
            // else {
            //     hdr.ipv4.identification = 2;
            //     // hdr.ipv4.dst_addr = IP_NORMAL;
            //     // eg_dprsr_md.drop_ctl = 0x1; // Drop packet.
            // }

        }
        // Add telemetry info
        if ((hdr.tcp.flags & 0b00000010) != 2 && hdr.santa.isValid()) {
            hdr.santa.q_num = (bit<8>)eg_intr_md.egress_qid;
            hdr.santa.q_depth= (bit<24>)eg_intr_md.deq_qdepth;
        }
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;


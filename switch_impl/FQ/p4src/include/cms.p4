/* -*- P4_16 -*- */
#ifndef _CMS_
#define _CMS_

typedef bit<8> count_t;
typedef bit<32> hash_index_t;
typedef bit<19> index_t; // based on the sketch width

#define SKETCH_WIDTH 0x80000 // 2^19 in width
// #define SKETCH_WIDTH 32766 // 2^16 in width
#define SKETCH_ENTRY 256

#define NON_SANTA   3
#define SANTA       1
#define SANTA_VALID 2

control CMSIngress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md,
    inout bit<8> pkt_flag)
{   
    bit<32>     index_a = 0;
    bit<32>     index_b = 0;
    index_t     index0 = 0;
    index_t     index1 = 0;
    index_t     index2 = 0;
    index_t     index3 = 0;

    count_t     count0 = 0;
    count_t     count1 = 0;
    count_t     count2 = 0;
    count_t     count3 = 0;
    bit<8>     min_count = 0;
    bit<8>     min_count_1 = 0;
    bit<8>     min_count_2 = 0;
    bit<1>      w_cms;

    Hash<hash_index_t>(HashAlgorithm_t.CRC32) hash_index0;
    Hash<hash_index_t>(HashAlgorithm_t.CRC32) hash_index1;

    Register<count_t,_>(SKETCH_WIDTH,0) sketch0;
    Register<count_t,_>(SKETCH_WIDTH,0) sketch1;
    Register<count_t,_>(SKETCH_WIDTH,0) sketch2;
    Register<count_t,_>(SKETCH_WIDTH,0) sketch3;

    RegisterAction<count_t, _, count_t> (sketch0) sketch0_count = {
        void apply(inout count_t val, out count_t rv) {
            val = val |+| 1;
            rv = val;
        }
    };

    RegisterAction<count_t, _, count_t> (sketch1) sketch1_count = {
        void apply(inout count_t val, out count_t rv) {
            val = val |+| 1;
            rv = val;
        }
    };

    RegisterAction<count_t, _, count_t> (sketch2) sketch2_count = {
        void apply(inout count_t val, out count_t rv) {
            val = val |+| 1;
            rv = val;
        }
    };

    RegisterAction<count_t, _, count_t> (sketch3) sketch3_count = {
        void apply(inout count_t val, out count_t rv) {
            val = val |+| 1;
            rv = val;
        }
    };

    Register<bit<1>, bit<1>>(1) working_cms;
    RegisterAction<bit<1>, bit<1>, bit<1>>(working_cms) get_working_cms = { 
        void apply(inout bit<1> register_data, out bit<1> result){
			result = register_data; 
        }
    };

    action set_cms_flag (bit<8> flag) {
        pkt_flag = flag;
    }

    table threshold {
        key = {
            min_count : range;        // range match has a limit on the key size
        }
        actions = {
            set_cms_flag;
        }
        const entries = {
            0..10  : set_cms_flag(NON_SANTA);
            // 11..256 : set_cms_flag(SANTA);
        }
        default_action = set_cms_flag(SANTA);
    }

    apply {
        index_a = hash_index0.get(
            {
                hdr.ipv4.src_addr,
                2w0,
                hdr.ipv4.dst_addr,
                2w0,
                hdr.ipv4.protocol,
                meta.src_port,
                meta.dst_port
            }
        );
        index_b = hash_index1.get(
            {
                hdr.ipv4.src_addr,
                3w0,
                hdr.ipv4.dst_addr,
                3w0,
                hdr.ipv4.protocol,
                meta.src_port,
                meta.dst_port
            }
        );

        index0 = index_a[18:0];
        index1 = index_a[31:13];
        index2 = index_b[18:0];
        index3 = index_b[31:13];

        count0 = sketch0_count.execute(index0);
        count1 = sketch1_count.execute(index1);
        count2 = sketch2_count.execute(index2);
        count3 = sketch3_count.execute(index3);

        w_cms = get_working_cms.execute(0);
        // if (w_cms == 0) {
        min_count_1 = (bit<8>)min(count0, count1);   
        min_count_2 = (bit<8>)min(min_count_1, count2);  
        min_count = (bit<8>)min(min_count_2, count3);  
        // }
        // else {
        //     min_count = (bit<19>)min(count2, count3);
        // }

        threshold.apply();

    }
}
#endif
// Testbed program for per-flow rate limit

#include <core.p4>
#include <tna.p4>

#include "../include/headers.h"
#include "../include/metadata.h"
#include "../include/parsers.h"
#include "../include/define.h"

#include "../include/rate_estimator.p4"


control SwitchIngress(
        inout header_t hdr,
        inout ig_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    RateEstimator() estimator;
    // RateEstimator(in bit<32> src_ip, in bit<32> dst_ip, in bit<8> proto, in bit<16> src_port, in bit<16> dst_port, 
    //      in  bytecount_t sketch_input, out byterate_t sketch_output) 
    // Calculates t_new = t_mid +- ( numerator / denominator ) * delta_t  // ( + if interp_right, - if interp_left)


    action drop() {
        ig_dprsr_md.drop_ctl = 0x1; // Mark packet for dropping after ingress.
    }
    action route_to_port(bit<9> port){
        ig_tm_md.ucast_egress_port=port;
    }
    action testbed_route(){
        route_to_port((bit<9>) hdr.ipv4.dst_addr[7:0]);
    }

    Random<bit<12>>() rng;

    apply {
	bytecount_t sketch_input=(bytecount_t) hdr.ipv4.total_len;
	byterate_t sketch_output=0;

	//assert UDP
	if(hdr.udp.isValid()){
		estimator.apply(
			hdr.ipv4.src_addr,hdr.ipv4.dst_addr,hdr.ipv4.protocol,
			hdr.udp.src_port,hdr.udp.dst_port,
			sketch_input,sketch_output	
		);	
	}else if(hdr.tcp.isValid()){
		estimator.apply(
			hdr.ipv4.src_addr,hdr.ipv4.dst_addr,hdr.ipv4.protocol,
			hdr.tcp.src_port,hdr.tcp.dst_port,
			sketch_input,sketch_output	
		);	
	}else {
		estimator.apply(
			hdr.ipv4.src_addr,hdr.ipv4.dst_addr,hdr.ipv4.protocol,
			0,0,
			sketch_input,sketch_output	
		);	
	}

	// Fixed rate limit of 10Mbps
	// at default config (rate mode, 1e6 decay, 1 scale), the limit is about 1200

	// A simple version of RED, stepwise probability

	bit<12> rate_est=sketch_output[11:0];
	bit<20> rate_high=sketch_output[31:12];

	bit<12> entropy=rng.get();

	if(rate_high!=0 || rate_est>2800){
		drop();
	}else if(rate_est>1300){
		if(entropy<2000){drop();}
	}else if(rate_est>1200){
		if(entropy<400){drop();}
	}

	hdr.ethernet.src_addr=(bit<48>)sketch_output;
	testbed_route();
    }
}


control SwitchEgress(
        inout header_t hdr,
        inout eg_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

    apply {
    }
}


Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;

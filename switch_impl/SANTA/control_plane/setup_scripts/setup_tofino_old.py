import socket

hostname = socket.gethostname()

# Configure front-panel ports
fp_ports = []

if hostname == 'tofino1c':
    fp_ports = [13]

for fp_port in fp_ports:
    for lane in range(4):
        dp = bfrt.port.port_hdl_info.get(CONN_ID=fp_port, CHNL_ID=lane, print_ents=False).data[b'$DEV_PORT']
        bfrt.port.port.add(DEV_PORT=dp, SPEED='BF_SPEED_10G', FEC='BF_FEC_TYP_NONE', AUTO_NEGOTIATION='PM_AN_FORCE_DISABLE', PORT_ENABLE=True)

def get_pg_id(dev_port): 
    # each pipe has 128 dev_ports + divide by 4 to get the pg_id 
    pg_id = (dev_port % 128) >> 2 
    return pg_id 

def get_pg_queue(dev_port, qid): 
    lane = dev_port % 4 
    pg_queue = lane * 8 + qid # there are 8 queues per lane 
    return pg_queue

# Port shaping
RATE_IN_KBPS = 100000   # 100Mbps
RECV_PORT = 24
bfrt.tf1.tm.port.sched_cfg.mod(dev_port=RECV_PORT, max_rate_enable = True)
bfrt.tf1.tm.port.sched_shaping.mod(dev_port=RECV_PORT, max_rate = RATE_IN_KBPS, max_burst_size = 1500)
# bfrt.tm.enable_port_shaping(port=RECV_PORT, dev=0) # rate is in terms of Kbps
# tm.set_port_shaping_rate(port=RECV_PORT, pps=False, burstsize=1500, rate=RATE_IN_KBPS, dev=0)

# Add entries to the l2_forward table
# l2_forward = bfrt.santa.pipe.Ingress.l2_forward
# l2_forward.add_with_forward(dst_addr=0x3cfdfebce1c0, egress_port=128)
# l2_forward.add_with_forward(dst_addr=0x3cfdfebce1c1, egress_port=129)

bfrt.complete_operations()

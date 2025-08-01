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
RATE_IN_KBPS = 450_000   # CAIDA change 1G # 50Mbps currently

RECV_PORT = 24
bfrt.tf1.tm.port.sched_cfg.mod(dev_port=RECV_PORT, max_rate_enable = True)
bfrt.tf1.tm.port.sched_shaping.mod(dev_port=RECV_PORT, max_rate = RATE_IN_KBPS, max_burst_size = 0)

pipe_num = 0
port_1 = get_pg_id(24)

num_queues = 5

mice_q = get_pg_queue(24, num_queues)

# highest priority for mice queue
q_sched_cfg = bfrt.tf1.tm.queue.sched_cfg
q_sched_cfg.mod(pipe=pipe_num, pg_id= port_1, pg_queue=mice_q, max_priority=1)

#  setting up the decay timers for ingress ports
# def callback (dev_id, pipe_id, direction, parser_id, entry, msg):
#     #src = entry.key[b'hdr.ethernet.src_addr']
#     # print("dev_id=",dev_id)
#     # print("pipe_id",pipe_id)
#     # print("direction",direction)
#     # print("parser_id=",parser_id)
#     # print ("msg = ",msg)
#     print("entry=",entry)
#     entry.remove()

# # these values are in ms
# bfrt.santa.pipe.Ingress.q_assign.idle_table_set_notify(enable=True,callback= callback ,interval= 1000,min_ttl= 10000, max_ttl=600000)


bfrt.complete_operations()

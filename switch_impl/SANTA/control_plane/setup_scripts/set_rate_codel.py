RECV_PORT = 24
DEFLECT_PORT = 26
POOL_NUM = 4 # can have upto 4 pools

buf_size = 140000
base_bufsize = int(0.75*buf_size)
num_queues = 1
total_pool_cells = num_queues*buf_size
tm.set_app_pool_size(POOL_NUM,total_pool_cells)   

for i in range(num_queues):
    tm.set_q_app_pool_usage(port=RECV_PORT, q=i, pool=POOL_NUM, base_use_limit=base_bufsize, dynamic_baf=9, hysteresis=32)
# tm.set_q_app_pool_usage(port=RECV_PORT, q=1, pool=POOL_NUM, base_use_limit=30000, dynamic_baf=9, hysteresis=32)


# for deflect on drop
tm.set_negative_mirror_dest(dev=0, pipe=0, port=DEFLECT_PORT, q=0)
print("set the deflect to drop")







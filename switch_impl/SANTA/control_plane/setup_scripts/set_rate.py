RECV_PORT = 24
DEFLECT_PORT = 26
POOL_NUM = 4 # can have upto 4 pools
LOW_PRIORITY = 1
HIGH_PRIORITY = 7

num_queues = 5
buf_size = 3500 # roughly 14,000/4
base_bufsize = int(0.75*buf_size)
total_pool_cells = num_queues*buf_size
tm.set_app_pool_size(POOL_NUM,total_pool_cells)   

# queue num 4 is the mice queue
for i in range(num_queues):
    tm.set_q_app_pool_usage(port=RECV_PORT, q=i, pool=POOL_NUM, base_use_limit=base_bufsize, dynamic_baf=9, hysteresis=32)
# tm.set_q_app_pool_usage(port=RECV_PORT, q=1, pool=POOL_NUM, base_use_limit=30000, dynamic_baf=9, hysteresis=32)

# tm.set_q_sched_priority(dev=0, port=RECV_PORT, q=1, priority = 0)
# tm.set_q_sched_priority(dev=0, port=RECV_PORT, q=2, priority = "BF_TM_SCH_PRIO_7")

# for deflect on drop
tm.set_negative_mirror_dest(dev=0, pipe=0, port=DEFLECT_PORT, q=0)

# ALL OLD STUFF
# # Configuring deep buffer in one direction
# # Step 1: Reduce buffer allocation to the app pools
# # - App pools 1-3 are not being used. So set them to zero
# # - App pool 4 is being used by switchd as default for all ports. Need some small buffer for ACKs to go back
# # - App pool 0 is the default pool. It is used when app pool usage is disabled on a queue.
# #   Therefore give maximum possible cells to app pool 0.
# tm.set_app_pool_size(1, 0)
# tm.set_app_pool_size(2, 0)
# tm.set_app_pool_size(3, 0)
# tm.set_app_pool_size(4, 20)
# tm.set_app_pool_size(0, 266240)







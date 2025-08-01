RECV_PORT = 24
DEFLECT_PORT = 26
POOL_NUM = 4 # can have upto 4 pools
LOW_PRIORITY = 1
HIGH_PRIORITY = 7

total_pool_cells = 16000
# total_pool_cells = 3600
tm.set_app_pool_size(POOL_NUM,total_pool_cells)   

# for deflect on drop
tm.set_negative_mirror_dest(dev=0, pipe=0, port=DEFLECT_PORT, q=0)





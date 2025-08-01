
# set rate limitaiton
tm.set_port_shaping_rate(port=136, pps=False, burstsize=16384, rate=100000, dev=0)
tm.enable_port_shaping(port=136, dev=0)
tm.get_port_shaping_rate(136)


#set the dest port for deflect pk
tm.set_negative_mirror_dest(dev=0, pipe=1, port=137, q=0)


# set buffer limitation

# case1: deep buffer       
# pool size can be larger (266240) if just one pool is used 
tm.set_app_pool_size(4,62500)   

# set buffer size
tm.set_q_app_pool_usage(port=136, q=0, pool=4, base_use_limit=6250, dynamic_baf=9, hysteresis=32)
tm.set_q_app_pool_usage(port=136, q=1, pool=4, base_use_limit=6250, dynamic_baf=9, hysteresis=32)
tm.set_q_app_pool_usage(port=136, q=2, pool=4, base_use_limit=6250, dynamic_baf=9, hysteresis=32)
tm.set_q_app_pool_usage(port=136, q=3, pool=4, base_use_limit=6250, dynamic_baf=9, hysteresis=32)




# clear the register or table





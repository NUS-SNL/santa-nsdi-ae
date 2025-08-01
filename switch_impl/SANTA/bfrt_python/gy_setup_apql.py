from netaddr import IPAddress

p4 = bfrt.gy_switch_apql.pipe

# This function can clear all the tables and later on other fixed objects
# once bfrt support is added.
def clear_all(verbose=True, batching=True):
    global p4
    global bfrt


    # The order is important. We do want to clear from the top, i.e.
    # delete objects that use other objects, e.g. table entries use
    # selector groups and selector groups use action profile members

    for table_types in (['MATCH_DIRECT', 'MATCH_INDIRECT_SELECTOR'],
                        ['SELECTOR'],
                        ['ACTION_PROFILE']):
        for table in p4.info(return_info=True, print_info=False):
            if table['type'] in table_types:
                if verbose:
                    print("Clearing table {:<40} ... ".
                          format(table['full_name']), end='', flush=True)
                table['node'].clear(batch=batching)
                if verbose:
                    print('Done')

#clear_all(verbose=True)


# basic connection
ipv4_host = p4.Ingress.ipv4_host
ipv4_host.add_with_send(dst_addr = IPAddress("10.1.1.1"), port=138)
ipv4_host.add_with_send(dst_addr = IPAddress("10.1.1.2"), port=139)
ipv4_host.add_with_send(dst_addr = IPAddress("10.1.1.3"), port=136)
ipv4_host.add_with_send(dst_addr = IPAddress("10.1.1.4"), port=137)


#clear the register
# p4.Ingress.reg_table_1.clear


#recicurate
p4.Ingress.reci_proc.add_with_drop(ingress_port=0xC4)    #pay attention to the reci port

p4.Egress.port_acl.entry_with_acl_mirror(ingress_port=138, mirror_session=21).push()
p4.Egress.mirror_dest.entry_with_just_send(mirror_session=21).push()
p4.Egress.port_acl.entry_with_acl_mirror(ingress_port=139, mirror_session=22).push()
p4.Egress.mirror_dest.entry_with_just_send(mirror_session=22).push()
p4.Egress.port_acl.entry_with_acl_mirror(ingress_port=136, mirror_session=23).push()
p4.Egress.mirror_dest.entry_with_just_send(mirror_session=23).push()
p4.Egress.port_acl.entry_with_acl_mirror(ingress_port=137, mirror_session=24).push()
p4.Egress.mirror_dest.entry_with_just_send(mirror_session=24).push()

p4.Egress.deflect_port_acl.entry_with_acl_mirror(egress_port=137, mirror_session=25).push()
p4.Egress.mirror_dest.entry_with_just_send(mirror_session=25).push()


# mirror session
mir = bfrt.mirror.cfg
mir.entry_with_normal(sid=21, direction='EGRESS', session_enable=True, ucast_egress_port=0xC4, ucast_egress_port_valid=1, max_pkt_len=64).push()
mir.entry_with_normal(sid=22, direction='EGRESS', session_enable=True, ucast_egress_port=0xC4, ucast_egress_port_valid=1, max_pkt_len=64).push()
mir.entry_with_normal(sid=23, direction='EGRESS', session_enable=True, ucast_egress_port=0xC4, ucast_egress_port_valid=1, max_pkt_len=64).push()
mir.entry_with_normal(sid=24, direction='EGRESS', session_enable=True, ucast_egress_port=0xC4, ucast_egress_port_valid=1, max_pkt_len=64).push()

mir.entry_with_normal(sid=25, direction='EGRESS', session_enable=True, ucast_egress_port=0xC4, ucast_egress_port_valid=1, max_pkt_len=64).push()


#set ingress register buffer threshold
ing_reg_th=bfrt.gy_switch_apql.pipe.Ingress.reg_ing_buf_th
ing_reg_th.mod(REGISTER_INDEX=0,f1=10000)
ing_reg_th.get(REGISTER_INDEX=0,from_hw=True)



bfrt.complete_operations()

# Final programming
print("""  ******************* PROGAMMING RESULTS *****************  """)
print ("Table ipv4_host:")
ipv4_host.dump(table=True)




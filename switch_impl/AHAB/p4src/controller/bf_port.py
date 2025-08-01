
def enable_ports(*qsfp_cages):
    global bfrt
    if len(qsfp_cages) == 0:
        qsfp_cages = [5]
    for qsfp_cage in qsfp_cages:
        for lane in range(4):
            dp = bfrt.port.port_hdl_info.get(CONN_ID=qsfp_cage, CHNL_ID=lane,print_ents=False).data[b'$DEV_PORT']
            bfrt.port.port.add(DEV_PORT=dp, SPEED="BF_SPEED_10G", FEC="BF_FEC_TYP_NONE", AUTO_NEGOTIATION="PM_AN_FORCE_DISABLE", PORT_ENABLE=True)


enable_ports(13)
#enable_ports(5, 10, 1)
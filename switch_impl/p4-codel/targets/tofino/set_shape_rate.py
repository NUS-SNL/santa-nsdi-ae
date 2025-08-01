from pd_fixed.pd_fixed_api import PDFixedConnect

if __name__ == '__main__':
    pd = PDFixedConnect("127.0.0.1")
    pd.set_port_shaping_rate(24, 450000)
    pd.enable_port_shaping(24)

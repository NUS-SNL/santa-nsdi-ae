#!/usr/bin/env python3

# Assumes valid PYTHONPATH
import bfrt_grpc.client as gc
import time
import datetime
import subprocess

TEST_PIPE = 1  # all the ports we care about are on port 1 (128 - 196) NOTE: BOTTLENECK_PORT must be on TEST_PIPE
BOTTLENECK_PORT = 136

###------------------ step1: get dev_tgt , devport ------------------###

# Connect to the BF Runtime server
for bfrt_client_id in range(10):
    try:
        interface = gc.ClientInterface(
            grpc_addr="localhost:50052",
            client_id=bfrt_client_id,
            device_id=0,
            num_tries=1,
        )
        # print("Connected to BF Runtime Server as client", bfrt_client_id)
        break
    except:
        # print("Could not connect to BF Runtime Server")
        quit

# Get information about the running program
bfrt_info = interface.bfrt_info_get()
# print("The target is running the P4 program: {}".format(bfrt_info.p4_name_get()))

# Establish that you are the "main" client
if bfrt_client_id == 0:
    interface.bind_pipeline_config(bfrt_info.p4_name_get())

dev_tgt = gc.Target(0)

dev_tgt_piped = gc.Target(0, pipe_id=TEST_PIPE)

def get_devport(frontpanel, lane):
    port_hdl_info = bfrt_info.table_get("$PORT_HDL_INFO")
    key = port_hdl_info.make_key(
        [gc.KeyTuple("$CONN_ID", frontpanel), gc.KeyTuple("$CHNL_ID", lane)]
    )
    for data, _ in port_hdl_info.entry_get(dev_tgt, [key], {"from_hw": False}):
        devport = data.to_dict()["$DEV_PORT"]
        if devport:
            return devport

def get_port_grouping(devport):
    port_cfg = bfrt_info.table_get("tf1.tm.port.cfg")
    key = port_cfg.make_key([gc.KeyTuple("dev_port", devport)])
    for data, _ in port_cfg.entry_get(dev_tgt, [key]):
        pg_id = data.to_dict()["pg_id"]
        pg_port_nr = data.to_dict()["pg_port_nr"]
        if pg_id is not None and pg_port_nr is not None:
            return pg_id, pg_port_nr



# port137 = get_devport(32, 1)
# port138 = get_devport(32, 2)
# port139 = get_devport(32, 3)
##//////////////////////////////////////////////////////////////////////////
ING_FLOWTABLE_SIZE = 1024  #confusing? 

    # current flow table
    # egr_port = []
src = [0] * 2048    #useless
dst = [0] * 2048    #useless
count = [0] * 2048  #useless

    # flow change counters, for flows in current
flow_bytes = [0] * 2048


hash_index_qid_0 = [0] * 2048

TM_QUEUE_NUM=8
TMP_TM_QUEUE_NUM=2

##//////////////////////////////////////////////////////////////////////////

###-----------------------step2:  read reg value ------------------###
# tm_qid=0; tm_qid=1


# tm_qnum_a=tm_qnum_reg_read(0)
# tm_qnum_b=tm_qnum_reg_read(1)

# print("tm_qnum_0={} tm_qnum_1={}".format(tm_qnum_a,tm_qnum_b))

###-----------------------step3:  write dwrr weight value ------------------###

    # QUEUE_A is more aggresssive queue at first, QUEUE_B is lower

# def configure_tm_queue(tm_qid_x, tm_qid_y):
def configure_tm_queue(idx):

    tm_qid =idx

    tm_qnum=tm_qnum_read(tm_qid)

    bottleneck_group=2    
    # bottleneck_group, _ = get_port_grouping(BOTTLENECK_PORT)

    queue_sched_cfg = bfrt_info.table_get("tf1.tm.queue.sched_cfg")
    queue_sched_cfg_keys = [
        queue_sched_cfg.make_key(
            [gc.KeyTuple("pg_id", bottleneck_group), gc.KeyTuple("pg_queue", tm_qid)]
        ),
    ]
    queue_sched_cfg_data = [
        queue_sched_cfg.make_data([gc.DataTuple("dwrr_weight", tm_qnum)]),
    ]

    queue_sched_cfg.entry_mod(dev_tgt_piped, queue_sched_cfg_keys, queue_sched_cfg_data)
    print("set dwrr_weight <-- configure_tm_queue: tm_qid={} tm_qnum={}".format(tm_qid,tm_qnum))

# reset for count values
def reset_by_fcn(tbl, data_col, count):
    keys = [tbl.make_key([gc.KeyTuple("$REGISTER_INDEX", idx)]) for idx in range(count)]
    data = [tbl.make_data([gc.DataTuple(data_col, 0)]) for idx in range(count)]
    tbl.entry_mod(dev_tgt, keys, data)

#reset for singel values.
def reset_by_single(tbl, data_col, index, def_val):
    keys = [tbl.make_key([gc.KeyTuple("$REGISTER_INDEX", index)]) ]
    data = [tbl.make_data([gc.DataTuple(data_col, def_val)]) ]
    tbl.entry_mod(dev_tgt, keys, data)

def ing_perflow_tm_qid_reset(hash_index):
    #This value is used to determine whether it is a new flow.
    DEFAULT_NOFLOW_QID=8
    # reset stage 1
    reset_by_single(
        bfrt_info.table_get("Ingress.reg_perflow_tm_qid"),
        "Ingress.reg_perflow_tm_qid.f1",
        hash_index,
        DEFAULT_NOFLOW_QID,
    )

# may be uset to reset the whole reg table of ing_counter_a and ing_counter_b; now it is just test.
def ing_flowtable_reset():
    ING_FLOWTABLE_SIZE=8
    # reset stage 1
    reset_by_fcn(
        bfrt_info.table_get("Ingress.tm_qnum_reg"),
        "Ingress.tm_qnum_reg.f1",
        ING_FLOWTABLE_SIZE,
    )


# read_vals = [0]*ING_FLOWTABLE_SIZE * 2

rows = TM_QUEUE_NUM   # tm has no more than 8 queues.
cols = ING_FLOWTABLE_SIZE * 2  # assuming the num of flows does not exceed 2048;  The hash index value does not exceed 1024. 
read_vals = [[0] * cols for _ in range(rows)]
 
move_flags = [[1] * cols for _ in range(rows)]   # default=1, index of queue increased, from q1-->q2, =2, index of queue is reduced: form q1-->q0, =0

flow_group_pointer = [0] * TM_QUEUE_NUM
max_change_flag = [0] * TM_QUEUE_NUM
max_qdepth_index = [0] * TM_QUEUE_NUM
min_change_flag = [0] * TM_QUEUE_NUM
min_qdepth_index = [0] * TM_QUEUE_NUM
real_pointer_qnum = [0] * TM_QUEUE_NUM
last_tm_qnum = [0] * TM_QUEUE_NUM

max_qdepth = [0] * TM_QUEUE_NUM
min_qdepth = [0] * TM_QUEUE_NUM



def perflow_tm_qid_read(hash_index, tm_qid):
    # tm_qid_a =0
    tm_qnum_reg = bfrt_info.table_get("Ingress.reg_perflow_tm_qid")
    key = tm_qnum_reg.make_key([gc.KeyTuple("$REGISTER_INDEX", hash_index)])
    for data, _ in tm_qnum_reg.entry_get(dev_tgt, [key], {"from_hw": True}):
        regvals = data.to_dict()["Ingress.reg_perflow_tm_qid.f1"]
        if regvals is not None:
            if regvals[TEST_PIPE] == tm_qid:
                print("****************** hit **************************index={}".format(hash_index))
            return regvals[TEST_PIPE]
        
def flow_group_read(tm_qid): 
    # tm_qid_a =0
    pointer=0           
    for idx in range(ING_FLOWTABLE_SIZE * 2):
        regvals=perflow_tm_qid_read(idx, tm_qid)
        if regvals == tm_qid:
            read_vals[tm_qid][pointer]=idx            
            # print("+++++ read_vals[{}]={}".format(pointer,read_vals[tm_qid][pointer]))
            pointer=pointer+1
    print("--------------flow_group_read(tm_qid={}) pointer {}".format(tm_qid, pointer))
    return pointer

def perflow_qdepth_read(hash_index):        
    ri_headq = bfrt_info.table_get("Ingress.reg_ing_perflow_qdepth")
    key = ri_headq.make_key([gc.KeyTuple("$REGISTER_INDEX", hash_index)])
    for data, _ in ri_headq.entry_get(dev_tgt, [key], {"from_hw": True}):
        regvals = data.to_dict()["Ingress.reg_ing_perflow_qdepth.f1"]
        if regvals is not None:
            return regvals[TEST_PIPE]

#type1: move the max or min flow, single flow
def max_min_qdepth_index_get(num_pointer,tm_qid):
    maxQdepth = 0
    maxIdx = 1023
    maxChangeFlag = 0
    maxIdxTmp = 8   # 0-7 is the tm qid

    minQdepth=10000000    # if there is unempty flow, this value will be overwritten
    minIdx  = 1023
    minChangeFlag = 0
    minIdxTmp = 8 # 0-7 is the tm qid

    QdepthSum = 0
    realPointer = num_pointer
    FirstHitFlag=0

    for idx in range(num_pointer):
        qdepth_index=read_vals[tm_qid][idx]
        #use this value to read reg_ing_perflow_qdepth
        qdepth = perflow_qdepth_read(qdepth_index)
        print("idx={} qdepth_index={} qdepth={}".format(idx,qdepth_index,qdepth))

        if qdepth ==0:  # change the flag, the flow is marked as "unprecedented "  # can add other constraints
            flow_start_flag_reset(qdepth_index)
            ing_perflow_tm_qid_reset(qdepth_index)
            tm_qnum_reduce(tm_qid)
            realPointer=realPointer-1
        else:
            QdepthSum=QdepthSum+qdepth
            if qdepth > maxQdepth:
                # maxIdx=idx
                maxIdx=qdepth_index
                maxQdepth=qdepth
                maxIdxTmp = idx
            if qdepth < minQdepth:
                minIdx=qdepth_index
                minQdepth=qdepth
                minIdxTmp = idx
    # print("num_pointer={} maxQdepth={} QdepthSum={}".format(num_pointer, maxQdepth, QdepthSum))
    # if maxQdepth > 2*minQdepth:

    #solution 1: compare with avg, and move the max or min flow
    if realPointer > 0:
        if maxQdepth > 2*QdepthSum/realPointer and tm_qid<TMP_TM_QUEUE_NUM-1:
            maxChangeFlag=1
            print("maxQdepth={} 2*QdepthSum/realPointer={} maxChangeFlag={}".format(maxQdepth, 2*QdepthSum/realPointer, maxChangeFlag))
        if minQdepth < QdepthSum/(2*realPointer) and tm_qid > 0:
            minChangeFlag=1
            print("minQdepth={} QdepthSum/(2*realPointer)={} minChangeFlag={}".format(minQdepth, QdepthSum/(2*realPointer), minChangeFlag))       

    return maxChangeFlag, maxIdx, minChangeFlag, minIdx, realPointer


#reset the flow start flag

def flow_start_flag_reset(hash_index):
    # tm_qid_b =1
    ri_headq = bfrt_info.table_get("Ingress.reg_flow_start_flag")
    ri_headq_keys = [ri_headq.make_key([gc.KeyTuple("$REGISTER_INDEX", hash_index)])]
    ri_headq_data = [
        ri_headq.make_data([gc.DataTuple("Ingress.reg_flow_start_flag.f1", 0)])
    ]
    ri_headq.entry_mod(dev_tgt, ri_headq_keys, ri_headq_data)


# change the dest tm qid of the flow whose qdepth is largest
def tm_qid_read(hash_index):        
    ri_headq = bfrt_info.table_get("Ingress.reg_perflow_tm_qid")
    key = ri_headq.make_key([gc.KeyTuple("$REGISTER_INDEX", hash_index)])
    for data, _ in ri_headq.entry_get(dev_tgt, [key], {"from_hw": True}):
        regvals = data.to_dict()["Ingress.reg_perflow_tm_qid.f1"]
        if regvals is not None:
            return regvals[TEST_PIPE]


def tm_qid_write(hash_index, new_tm_qid):
    # tm_qid_b =1
    ri_headq = bfrt_info.table_get("Ingress.reg_perflow_tm_qid")
    ri_headq_keys = [ri_headq.make_key([gc.KeyTuple("$REGISTER_INDEX", hash_index)])]
    ri_headq_data = [
        ri_headq.make_data([gc.DataTuple("Ingress.reg_perflow_tm_qid.f1", new_tm_qid)])
    ]
    ri_headq.entry_mod(dev_tgt, ri_headq_keys, ri_headq_data)

# prepare for the tm_qnum_reg change

def tm_qnum_read(tm_qid):        
    ri_headq = bfrt_info.table_get("Ingress.tm_qnum_reg")
    key = ri_headq.make_key([gc.KeyTuple("$REGISTER_INDEX", tm_qid)])
    for data, _ in ri_headq.entry_get(dev_tgt, [key], {"from_hw": True}):
        regvals = data.to_dict()["Ingress.tm_qnum_reg.f1"]
        if regvals is not None:
            return regvals[TEST_PIPE]

def tm_qnum_write(tm_qid, new_tm_qnum):
    ri_headq = bfrt_info.table_get("Ingress.tm_qnum_reg")
    ri_headq_keys = [ri_headq.make_key([gc.KeyTuple("$REGISTER_INDEX", tm_qid)])]
    ri_headq_data = [
        ri_headq.make_data([gc.DataTuple("Ingress.tm_qnum_reg.f1", new_tm_qnum)])
    ]
    ri_headq.entry_mod(dev_tgt, ri_headq_keys, ri_headq_data)

def tm_qnum_reduce(tm_qid):
    last_tm_qnum=tm_qnum_read(tm_qid)
    new_tm_qnum=last_tm_qnum-1
    tm_qnum_write(tm_qid, new_tm_qnum)

# def zero_flow_change(tm_qnum_x,tm_qnum_y):
#     if tm_qnum_x==0 and tm_qnum_y > 2 :
#         print("hello x <-- y")
#     if tm_qnum_x > 2 and tm_qnum_y == 0 :
#         print("hello x --> y")

#type1: move the max or min flow, single flow
def move_flow_to_other_tm_q():

    #  Step 2-1 search reg_perflow_tm_qid for qid=0, qid=1, return the index; 
    #  Step 2-2 According to the content of the index array, save into an array qdepth_qid_0[]
    #  get the index of max 

    for idx in range(TMP_TM_QUEUE_NUM): 
        tm_qid =idx
        flow_group_pointer[idx]=flow_group_read(tm_qid)
        max_change_flag[idx], max_qdepth_index[idx], min_change_flag[idx], min_qdepth_index[idx], real_pointer_qnum[idx]=max_min_qdepth_index_get(flow_group_pointer[idx], tm_qid)
        print("****** tm_qid={}".format(idx))
        print("max_change_flag:{}, max_qdepth_index: {}".format(max_change_flag[idx], max_qdepth_index[idx]))
        print("min_change_flag:{}, min_qdepth_index: {}".format(min_change_flag[idx], min_qdepth_index[idx]))
        
    # Step 2-3 move to different group:  update perflow_tm_qid and update the tm_qnum

    # Step 2-3-1 get the initial values
    # Step 2-3-2 change tm_qid
    for idx in range(TMP_TM_QUEUE_NUM):
        tm_qid=idx
        last_tm_qnum[idx]=tm_qnum_read(tm_qid)
        # if max_change_flag[idx] == 1 and idx<TMP_TM_QUEUE_NUM-1:
        if max_change_flag[idx] == 1:
            last_tm_qid=tm_qid_read(max_qdepth_index[idx])    #for debug / show the changing
            new_idx= idx+1
            new_tm_qid=new_idx

            real_pointer_qnum[idx] = real_pointer_qnum[idx]-1
            real_pointer_qnum[new_idx] = real_pointer_qnum[new_idx]+1
            tm_qid_write(max_qdepth_index[idx], new_tm_qid)
            print("move strongest flow {} from tm_q={} to tm_q={} ".format(max_qdepth_index[idx], last_tm_qid, new_tm_qid)) 
        # if min_change_flag == 1 and idx>0:
        if min_change_flag[idx] == 1:
            last_tm_qid=tm_qid_read(min_qdepth_index[idx])   #for debug / show the changing
            new_idx= idx-1
            new_tm_qid=new_idx
            real_pointer_qnum[idx] = real_pointer_qnum[idx]-1
            real_pointer_qnum[new_idx] = real_pointer_qnum[new_idx]+1
            tm_qid_write(min_qdepth_index[idx], new_tm_qid)
            print("move weakest flow {} from tm_q={} to tm_q={} ".format(min_qdepth_index[idx], last_tm_qid, new_tm_qid))
    
    # Step 2-3-2 change tm_qnum
    for idx in range(TMP_TM_QUEUE_NUM):
        tm_qid=idx    
        new_tm_qnum = real_pointer_qnum[idx]
        tm_qnum_write(tm_qid, new_tm_qnum)
        # print("****debug: tm_qid={} new_tm_qnum={} ".format(tm_qid, new_tm_qnum))


##################################################################################################
 #solution 2: compare with max or min, and move the max or min flow

def max_min_qdepth_index_get_solution2(num_pointer,tm_qid):
    maxQdepth = 0
    maxIdxH = 1023
    maxChangeFlag = 0
    maxIdxF = 1023   

    minQdepth=10000000    # if there is unempty flow, this value will be overwritten
    minIdxH  = 1023
    minChangeFlag = 0
    minIdxF = 1023  

    QdepthSum = 0
    realPointer = num_pointer
    FirstHitFlag=0

    for idxf in range(num_pointer):
        qdepth_index=read_vals[tm_qid][idxf]
        #use this value to read reg_ing_perflow_qdepth
        qdepth = perflow_qdepth_read(qdepth_index)
        print("idx={} qdepth_index={} qdepth={}".format(idxf,qdepth_index,qdepth))

        if qdepth ==0:  # change the flag, the flow is marked as "unprecedented "  # can add other constraints
            flow_start_flag_reset(qdepth_index)
            ing_perflow_tm_qid_reset(qdepth_index)
            tm_qnum_reduce(tm_qid)
            realPointer=realPointer-1
        else:
            QdepthSum=QdepthSum+qdepth
            if qdepth > maxQdepth:
                # maxIdx=idh
                maxIdxH = qdepth_index
                maxQdepth=qdepth
                maxIdxF = idxf
            if qdepth < minQdepth:
                minIdxH = qdepth_index
                minQdepth = qdepth
                minIdxF= idxf
    if realPointer>0:
        print("maxQdepth={}, maxIdxH={}, minQdepth={}, minIdxH={}, realPointer={}".format(maxQdepth, maxIdxH, minQdepth, minIdxH, realPointer))

    if realPointer>1:
        maxChangeFlag=0
        tmp_counter=0
        for idxf in range(num_pointer):
            qdepth_index=read_vals[tm_qid][idxf]
            qdepth = perflow_qdepth_read(qdepth_index)
            if qdepth>0 and qdepth > maxQdepth/2:
                tmp_counter=tmp_counter+1            
        if tmp_counter==1 and tm_qid<TMP_TM_QUEUE_NUM-1:
            # move_flags[tm_qid][maxIdxF] = 2    # 2 means move max flow to more aggressive queue
            maxChangeFlag=1 
            print("++++ move_max_flags[{}][{}]={} ".format(tm_qid, maxIdxF, move_flags[tm_qid][maxIdxF]))
    
    if realPointer>1:
        minChangeFlag=0
        tmp_counter=0
        for idxf in range(num_pointer):
            qdepth_index=read_vals[tm_qid][idxf]
            qdepth = perflow_qdepth_read(qdepth_index)
            if qdepth>0 and qdepth < 2*minQdepth:
                tmp_counter=tmp_counter+1       
        if tmp_counter==1 and tm_qid >0:
            # move_flags[tm_qid][minIdxF] = 0   # 0 means move min flow to less aggressive queue 
            minChangeFlag=1
            print("++++ move_min_flags[{}][{}]={} ".format(tm_qid, minIdxF, move_flags[tm_qid][minIdxF]))

    # return maxQdepth, maxIdxF, minQdepth, minIdxF, realPointer
    return maxChangeFlag, maxIdxH, minChangeFlag, minIdxH, realPointer

def move_flow_to_other_tm_q_solution2():

    for idxq in range(TMP_TM_QUEUE_NUM): 
        tm_qid =idxq
        flow_group_pointer[idxq]=flow_group_read(tm_qid)
        # max_qdepth[idxq], max_qdepth_index[idxq], min_qdepth[idxq], min_qdepth_index[idxq], real_pointer_qnum[idxq]=max_min_qdepth_index_get_solution2(flow_group_pointer[idxq], tm_qid)
        max_change_flag[idxq], max_qdepth_index[idxq], min_change_flag[idxq], min_qdepth_index[idxq], real_pointer_qnum[idxq]=max_min_qdepth_index_get_solution2(flow_group_pointer[idxq], tm_qid)
        # print("****** tm_qid={}".format(idxq))
        # print("max_qdepth:{}, max_qdepth_index:{}".format(max_qdepth[idxq], max_qdepth_index[idxq]))
        # print("min_qdepth:{}, min_qdepth_index:{}".format(min_qdepth[idxq], min_qdepth_index[idxq]))

    for idxq in range(TMP_TM_QUEUE_NUM):
        tm_qid=idxq
        last_tm_qnum[idxq]=tm_qnum_read(tm_qid)
        if max_change_flag[idxq] == 1:
            last_tm_qid=tm_qid_read(max_qdepth_index[idxq])    #for debug / show the changing
            new_idxq= idxq+1
            new_tm_qid=new_idxq
            real_pointer_qnum[idxq] = real_pointer_qnum[idxq]-1
            real_pointer_qnum[new_idxq] = real_pointer_qnum[new_idxq]+1
            tm_qid_write(max_qdepth_index[idxq], new_tm_qid)
            print("move strongest flow {} from tm_q={} to tm_q={} ".format(max_qdepth_index[idxq], last_tm_qid, new_tm_qid)) 
        # if min_change_flag == 1 and idx>0:
        if min_change_flag[idxq] == 1:
            last_tm_qid=tm_qid_read(min_qdepth_index[idxq])   #for debug / show the changing
            new_idxq= idxq-1
            new_tm_qid=new_idxq
            real_pointer_qnum[idxq] = real_pointer_qnum[idxq]-1
            real_pointer_qnum[new_idxq] = real_pointer_qnum[new_idxq]+1
            tm_qid_write(min_qdepth_index[idxq], new_tm_qid)
            print("move weakest flow {} from tm_q={} to tm_q={} ".format(min_qdepth_index[idxq], last_tm_qid, new_tm_qid))
       
        # Step 2-3-2 change tm_qnum
    for idxq in range(TMP_TM_QUEUE_NUM):
        tm_qid=idxq    
        new_tm_qnum = real_pointer_qnum[idxq]
        tm_qnum_write(tm_qid, new_tm_qnum)
        # print("****debug: tm_qid={} new_tm_qnum={} ".format(tm_qid, new_tm_qnum))

##################################################################################################################################
# #type3: move the flows smaller than max/2 or larger than 2min, multi
def max_min_qdepth_index_get_multi(num_pointer,tm_qid):
    maxQdepth = 0
    maxIdxH = 1023
    maxChangeFlag = 0
    maxIdxF = 1023   

    minQdepth=10000000    # if there is unempty flow, this value will be overwritten
    minIdxH  = 1023
    minChangeFlag = 0
    minIdxF = 1023  

    QdepthSum = 0
    realPointer = num_pointer
    FirstHitFlag=0

    for idxf in range(num_pointer):
        qdepth_index=read_vals[tm_qid][idxf]
        #use this value to read reg_ing_perflow_qdepth
        qdepth = perflow_qdepth_read(qdepth_index)
        print("idx={} qdepth_index={} qdepth={}".format(idxf,qdepth_index,qdepth))

        if qdepth ==0:  # change the flag, the flow is marked as "unprecedented "  # can add other constraints
            flow_start_flag_reset(qdepth_index)
            ing_perflow_tm_qid_reset(qdepth_index)
            tm_qnum_reduce(tm_qid)
            realPointer=realPointer-1
        else:
            QdepthSum=QdepthSum+qdepth
            if qdepth > maxQdepth:
                # maxIdx=idh
                maxIdxH = qdepth_index
                maxQdepth=qdepth
                maxIdxF = idxf
            if qdepth < minQdepth:
                minIdxH = qdepth_index
                minQdepth = qdepth
                minIdxF= idxf
    if realPointer>0:
        print("maxQdepth={}, maxIdxH={}, minQdepth={}, minIdxH={}, realPointer={}".format(maxQdepth, maxIdxH, minQdepth, minIdxH, realPointer))

     #solution 3: compare with max or min, and move multi flows
    for idxf in range(num_pointer):
        qdepth_index=read_vals[tm_qid][idxf]
        #use this value to read reg_ing_perflow_qdepth
        qdepth = perflow_qdepth_read(qdepth_index)

        if qdepth>0 and qdepth < maxQdepth/2 and tm_qid>0:
            # move q(idxf) to q(idxf-1)
            move_flags[tm_qid][idxf] = 0   # default=1, index of queue increased, from q1-->q2, =2, index of queue is reduced: form q1-->q0, =0
            
            print("++++ move_flags[{}][{}]={} ".format(tm_qid, idxf, move_flags[tm_qid][idxf]))

        else: 
            if qdepth >0 and qdepth > 2*minQdepth and tm_qid < TMP_TM_QUEUE_NUM-1:
                move_flags[tm_qid][idxf] = 2
                
                print("++++ move_flags[{}][{}]={} ".format(tm_qid, idxf, move_flags[tm_qid][idxf]))
    
    
    return maxQdepth, maxIdxF, minQdepth, minIdxF, realPointer

def move_flow_to_other_tm_q_multi():

    for idxq in range(TMP_TM_QUEUE_NUM): 
        tm_qid =idxq
        flow_group_pointer[idxq]=flow_group_read(tm_qid)
        max_qdepth[idxq], max_qdepth_index[idxq], min_qdepth[idxq], min_qdepth_index[idxq], real_pointer_qnum[idxq]=max_min_qdepth_index_get_multi(flow_group_pointer[idxq], tm_qid)
        # print("****** tm_qid={}".format(idxq))
        # print("max_qdepth:{}, max_qdepth_index:{}".format(max_qdepth[idxq], max_qdepth_index[idxq]))
        # print("min_qdepth:{}, min_qdepth_index:{}".format(min_qdepth[idxq], min_qdepth_index[idxq]))

        for idxf in range(flow_group_pointer[idxq]):
            qdepth_index=read_vals[tm_qid][idxf]

            if move_flags[idxq][idxf]==0:
                last_tm_qid=idxq   # move q(idxf) to q(idxf-1)
                new_idxq= idxq-1
                new_tm_qid=new_idxq
                real_pointer_qnum[idxq] = real_pointer_qnum[idxq]-1
                real_pointer_qnum[new_idxq] = real_pointer_qnum[new_idxq]+1
                tm_qid_write(qdepth_index, new_tm_qid)
                move_flags[idxq][idxf]=1  # reset
                print("move flow {} smaller than max/2 from tm_q={} to tm_q={} ".format(qdepth_index, last_tm_qid, new_tm_qid)) 
            else:
                if move_flags[idxq][idxf]==2:                                
                    last_tm_qid=idxq   #move q(idxf) to q(idxf+1)
                    new_idxq= idxq+1
                    new_tm_qid=new_idxq
                    real_pointer_qnum[idxq] = real_pointer_qnum[idxq]-1
                    real_pointer_qnum[new_idxq] = real_pointer_qnum[new_idxq]+1
                    tm_qid_write(qdepth_index, new_tm_qid)
                    move_flags[idxq][idxf]=1  #reset
                    print("move flow {} larger than 2*min from tm_q={} to tm_q={} ".format(qdepth_index, last_tm_qid, new_tm_qid))
         
        # Step 2-3-2 change tm_qnum
    for idxq in range(TMP_TM_QUEUE_NUM):
        tm_qid=idxq    
        new_tm_qnum = real_pointer_qnum[idxq]
        tm_qnum_write(tm_qid, new_tm_qnum)
        # print("****debug: tm_qid={} new_tm_qnum={} ".format(tm_qid, new_tm_qnum))




def flb_main():

    # tm_qid_a =0     # choose the strongest flow, then move it away 
    # tm_qid_b =1     # choose the weakest one, then move it away
    # max_change_flag =0 # if =1, means move one strongest flow to the other flow;
    # min_change_flag =0 # if =1, means move one weakest flow to the other flow;

    print("++++++++++++++++++start flb_main time.sleep +++++++++++++++++++++++++")

    port136 = get_devport(32, 0)
    print("++++++++++++++++++000111000+++++++++++++++++++++++++")
    print("port136: {}".format(port136))

    # start pktgen
    # subprocess.run(["/home/cirlab/bf-sde-9.9.0/run_pd_rpc.py", "../bfrt_python/pktgen.py"])

    while True:
        
        current_time = datetime.datetime.now()

        time_string = current_time.strftime("%Y-%m-%d %H:%M:%S")
        print() 
        print("time now: ", time_string)

        move_flow_to_other_tm_q()       
        # move_flow_to_other_tm_q_solution2()
        # move_flow_to_other_tm_q_multi()

        #  step 2-3 reset the reg of ing_counter
        # ing_flowtable_reset()
    
        # step5: configure the queue dwrr value
        for idx in range(TMP_TM_QUEUE_NUM): 
            configure_tm_queue(idx)
        

        time.sleep(8)       


flb_main()




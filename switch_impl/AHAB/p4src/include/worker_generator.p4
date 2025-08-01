/*
    AHAB project
    Copyright (c) 2022, Robert MacDavid, Xiaoqi Chen, Princeton University.
    macdavid [at] cs.princeton.edu
    License: AGPLv3
*/

// For each vlink, generate one worker per epoch
control WorkerGenerator(in epoch_t curr_epoch,
                         in vlink_index_t vlink_id,
                         out bit<1> work_flag) {
    //reads vlink_id and epoch, generate is_worker for the first packet in new epoch
    @hidden
    Register<epoch_t, vlink_index_t>(NUM_VLINKS) last_worker_epoch;
    RegisterAction<epoch_t, vlink_index_t, bit<1>>(last_worker_epoch) choose_to_work = {
        void apply(inout epoch_t stored_epoch, out bit<1> get_to_work) {
            if (stored_epoch == curr_epoch) {
                get_to_work = 1w0;
            } else {
                get_to_work = 1w1;
                stored_epoch = curr_epoch;
            }
        }
    };
    @hidden
    action choose_to_work_act() {
        work_flag = choose_to_work.execute(vlink_id);
    }
    bit<1> dummy_bit=0;
    @hidden
    table choose_to_work_tbl {
        key = { dummy_bit : exact; }
        actions = { choose_to_work_act; }
        const entries = { 0 : choose_to_work_act(); }
        size = 1;
    }

    apply {
        choose_to_work_tbl.apply();
    }
}

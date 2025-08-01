#ifndef ALGO_H
#define ALGO_H

#include "utils/utils.hpp"
#include "bfrt/bfrt.hpp"
#include "utils/types.hpp"
#include <fstream>
#include <vector>
#include <map>
#include <unordered_map>
#include <algorithm>

// This will have my SANTA implementation
// working_copy_t currentWorkingCopy = 0;
// uint16_t round_interval

class santaParams {

private:
    uint8_t num_queues = 5; /* change here for the num of queues */
    // uint8_t def_qnum = 0;

public:
    std::vector<std::pair<uint16_t,uint16_t>> def_wt;   // default queue alloc wt
    std::unordered_map<fp_t, std::pair<qdelay_t, qnum_t>> q_delay_map; // map fp to q_delay
    std::unordered_map<fp_t, uint8_t> prev_qassign; // map fp to q_num
    std::unordered_map<fp_t, uint8_t> cur_qassign;
    // TODO: Check if AddorMod works actually
    std::vector<flow_q_entry_t> update;
    std::vector<flow_q_entry_t> add;
    std::vector<uint16_t> q_weight;
    std::vector<uint16_t> midrd_q_weight;
    std::vector<uint16_t> flows_per_queue;
    std::vector<double> bw_factor;

    bf_dev_port_t egress_port;
    uint16_t round_interval = 10; // change both this and the qdelay_per_round consistently
    uint16_t qdelay_update_per_round = 10;

    santaParams()
        : q_weight(num_queues, 0),
          midrd_q_weight(num_queues, 0),
          flows_per_queue(num_queues, 0),
          bw_factor(num_queues,0),
          egress_port(24) { /* change here for egress port */
            // Initialize def_wt with pairs dividing 256 into them
            uint16_t step = 256 / num_queues;
            for (uint16_t i = 0; i < num_queues; ++i) {
                uint16_t start = i * step;
                uint16_t end = (i + 1) * step - 1;
                if (i == num_queues -1){
                    end = 255;
                }
                def_wt.push_back({start, end});
            }
        }
    
    uint8_t get_num_queues();

    // moves the flows from each queue and updates the add and update vectors
    void move_flow(std::vector<fp_t> &temp_queue, int q_num);

    // check for all queues and update the q_assignment
    void update_q_assign();

    void midrd_update_weights();

    // all long flows, distribute b/w by num_flows in each queue
    void update_weights();

    // TODO
    void update_def_wt();

    // clear the old qassignments
    bf_status_t update_round(Bfruntime& bfrt);

    bf_status_t fetch_delay_from_dp(Bfruntime& bfrt);
};

// struct algo_params_t {
//     bool no_algo;
//     // default constructor to set the default values
//     algo_params_t():
//     no_algo(false),
//     //
//     round_interval(10) // 10 secs
//     {}
// };

bf_status_t santaAlgo(std::ofstream &outfile, bool &algo_running);
// bf_status_t santaAlgo(std::fstream &outfile, bool &algo_running, const algo_params_t& no_algo);

#endif

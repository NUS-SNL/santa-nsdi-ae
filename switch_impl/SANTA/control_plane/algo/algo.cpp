#include <iostream>
#include <unistd.h>
#include <chrono>
#include <thread>
#include <mutex>
#include <condition_variable>
#include "algo/algo.hpp"
#include "utils/types.hpp"

/* 
    Santa State Variables with initial values
*/

uint8_t santaParams::get_num_queues () {
    return num_queues;
}

void santaParams::move_flow (std::vector<fp_t> &temp_queue, int q_num) {
    // Find the minimum and maximum delay within temp_queue
    uint64_t min_delay = std::numeric_limits<uint64_t>::max();
    uint64_t max_delay = 0;

    for (const auto& entry : temp_queue) {
        uint64_t q_delay = q_delay_map[entry].first;
        min_delay = std::min(min_delay, q_delay);
        max_delay = std::max(max_delay, q_delay);
    }

    printf("Existing Allocation \n");
    printf("q: %d, num_flows: %ld, min_delay: %ld, max_delay: %ld \n", q_num, temp_queue.size(), min_delay, max_delay);
    printf("----------------------------------------- \n");
    // Move flows > 2*min_delay
    if (q_num < num_queues - 1) {
        for (const auto& entry : temp_queue) {
            if (q_delay_map[entry].first > 2 * min_delay) {
                prev_qassign.erase(entry);
                cur_qassign[entry] = q_num + 1;
                uint8_t new_qnum = q_num + 1;

                // check if already added to add
                auto add_it = std::remove_if(add.begin(), add.end(), [entry](const flow_q_entry_t &add_entry) {
                    return add_entry.fp == entry;
                });
                if (add_it != add.end()) {
                    add.erase(add_it, add.end());
                    add.push_back({entry, new_qnum});
                }
                else {
                    update.push_back({entry,new_qnum});
                }
            }
        }

        auto it = std::remove_if(temp_queue.begin(), temp_queue.end(), [this, min_delay](fp_t fp) {
            uint64_t q_delay = q_delay_map[fp].first;
            return q_delay > 2 * min_delay; });

        if (it != temp_queue.end()) {
            temp_queue.erase(it, temp_queue.end());
        }
    }

    // Recalculate the max delay for <max_delay/2 comparision
    max_delay = 0;
    for (const auto& entry : temp_queue) {
        uint64_t q_delay = q_delay_map[entry].first;
        // min_delay = std::min(min_delay, q_delay);
        max_delay = std::max(max_delay, q_delay);
    }

    // Check for flows < max_delay/2
    if (q_num > 0) {
        for (const auto& entry : temp_queue) {
            if (q_delay_map[entry].first < max_delay / 2) {
                prev_qassign.erase(entry);
                cur_qassign[entry] = q_num - 1;
                uint8_t new_qnum = q_num - 1;
                
                // check if already added to add
                auto add_it = std::remove_if(add.begin(), add.end(), [entry](const flow_q_entry_t &add_entry) {
                    return add_entry.fp == entry;
                });
                if (add_it != add.end()) {
                    add.erase(add_it, add.end());
                    add.push_back({entry, new_qnum});
                }
                else {
                    update.push_back({entry,new_qnum});
                }
            }
        }
        auto it = std::remove_if(temp_queue.begin(), temp_queue.end(), [this, max_delay](fp_t fp) {
            uint64_t q_delay = q_delay_map[fp].first;
            return q_delay < max_delay/2; });

        if (it != temp_queue.end()) {
            temp_queue.erase(it, temp_queue.end());
        }
    }

    for (auto entry : temp_queue) {   // Assign the cur_qassign for the flows remaining
        cur_qassign[entry] = q_num;
    }
    // clear for the next q_num
    temp_queue.clear();
}

void santaParams::update_q_assign () {
    // initialize the prev round assignment for new flows
    for (const auto &entry : q_delay_map) {
        fp_t fp = entry.first;
        qnum_t ing_qnum = entry.second.second; 
        bw_factor[ing_qnum] += entry.second.first; // summing up q_delays for all flows in the queue
        if (prev_qassign.find(fp) == prev_qassign.end()) {
            prev_qassign[fp] = ing_qnum;
            add.push_back({fp, ing_qnum});
            // printf("Added q_assign for new flow %ld \n", fp); // comment io
        }
    }

    // move the flows based on their behaviour
    std::vector<fp_t> temp_queue;
    for (int i = 0; i < num_queues; ++i) {
        for (const auto &kv : prev_qassign) {
            // for active flow detection uncomment this
            // if (q_delay_map.find(kv.first) == q_delay_map.end()) { // only consider the flows seen in the last round
            //     continue;
            // }
            if (kv.second == i) {
                temp_queue.push_back(kv.first);
            }
        }
        if (!temp_queue.empty()){
            move_flow(temp_queue, i);
        }
    }
}

void santaParams::midrd_update_weights() {
    // std::fill(flows_per_queue.begin(), flows_per_queue.end(), 0);
    // for (const auto &entry : q_delay_map) {
    //     qnum_t queue_num = entry.second.second; 
    //     flows_per_queue[(int)queue_num]+=1;
    // }

    for ( size_t i = 0; i < flows_per_queue.size(); ++i) {
        std::cout << "Queue " << i <<": "<< flows_per_queue[i] << " flows" << std::endl;
        midrd_q_weight[i] = flows_per_queue[i];
    }

    // update the default weights
    uint16_t total_weight = 0;
    for (auto weight : midrd_q_weight) {
        total_weight += weight;
    }
    if (total_weight > 0) {
        uint16_t start = 0;
        uint16_t end; 
        // Pre-calculate the cumulative weight to ensure proper allocation of the final range
        uint16_t cumulative_weight = 0;
        for (size_t i = 0; i < midrd_q_weight.size(); ++i) {
            if (midrd_q_weight[i] == 0) {
                def_wt.push_back({start,start});
                continue;
            }
            cumulative_weight += midrd_q_weight[i];
            if (i == midrd_q_weight.size() - 1) {
                end = 255;  // Ensure the last segment always ends at 255
            } else {
                end = (cumulative_weight * 256 / total_weight) - 1;
            }

            def_wt.push_back({start, end});
            start = end + 1;  // Prepare the start for the next range
        }
    }
}

void santaParams::update_weights() {
    for (const auto& entry : cur_qassign) {
        uint8_t queue_num = entry.second;
        q_weight[queue_num]++;
    }
}

void santaParams::update_def_wt() {
    uint16_t total_weight = 0;
    for (auto weight : q_weight) {
        total_weight += weight;
    }
    if (total_weight > 0) {
        uint16_t start = 0;
        uint16_t end;
        // Pre-calculate the cumulative weight to ensure proper allocation of the final range
        uint16_t cumulative_weight = 0;
        for (size_t i = 0; i < q_weight.size(); ++i) {
            if ((q_weight[i]*256)/total_weight == 0) {
                def_wt.push_back({start,start});
                continue;
            }
            cumulative_weight += q_weight[i];
            if (i == q_weight.size() - 1) {   
                end = 255; // Ensure the last segment always ends at 255
            } else {
                end = (cumulative_weight * 256 / total_weight) - 1;
            }

            def_wt.push_back({start, end});
            start = end + 1;  // Prepare the start for the next range
        }
    }
}

bf_status_t santaParams::update_round (Bfruntime& bfrt) {
    bf_status_t status =  BF_SUCCESS;
    (void)bfrt;

    prev_qassign.clear(); // Update the prev assignment to the new one --> efficient way?
    for (const auto& entry : cur_qassign) {
        prev_qassign[entry.first] = entry.second;
    }
    cur_qassign.clear();
    q_delay_map.clear(); // refresh the q_delay_map for reading from the other copy

    for (auto &entry : q_weight) {
        entry = 0;
    }

    for (auto &entry : bw_factor) {
        entry = 0;
    }

    def_wt.clear();  // Clear existing default pairs

    return status;
}

bf_status_t santaParams::fetch_delay_from_dp( Bfruntime& bfrt) {
    bf_status_t status =  BF_SUCCESS;
    // time interval for each delay fetch operation.
    auto interval = int(round_interval * 1000 / qdelay_update_per_round); // Convert to milliseconds
    
    for (int i = 0; i < qdelay_update_per_round; ++i) {
        auto start_time = std::chrono::steady_clock::now();
        
        // Fetch the delay information
        status = bfrt.update_working_copy();
        status = bfrt.get_qdelay(q_delay_map, get_num_queues(), prev_qassign, flows_per_queue);

        // comment io
        // for (const auto& entry: q_delay_map) {
        //     printf("fp: %ld, delay: %ld, q_num: %d\n", entry.first, entry.second.first, entry.second.second);
        // }
        // printf("-------------------------------\n");
        // midrd_update_weights();
        // to modify the current b/w distribution
        // status = bfrt.update_q_weights(midrd_q_weight, egress_port);
        // status = bfrt.set_def_assign(def_wt);
        // def_wt.clear(); 

        auto end_time = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();
        
        // Calculate the time to sleep by subtracting the time spent on the operation from the intended interval
        auto sleep_duration = interval - elapsed;
        if (sleep_duration > 0) {
            usleep(sleep_duration * 1000); // Convert milliseconds to microseconds for usleep   
        } else {
            // Log or handle cases where the operation took longer than the interval.
            std::cerr << "Warning: Delay fetch operation exceeded the intended interval." << std::endl;
        }
    }
    
    return status;
}


/* The main algo flow */
bf_status_t santaAlgo(std::ofstream &outfile, bool &algo_running){
    (void) algo_running;
    bf_status_t status;
    int round_num = 1; // init roundnum

    Bfruntime& bfrt = Bfruntime::getInstance();
    santaParams params;

    // set the weights for initial random assign
    status = bfrt.set_def_assign(params.def_wt);
    params.def_wt.clear();
    printf("Santa algo started...\n");
    printf("Start iperf flows and press enter...\n");
    getchar();

    auto start_time = std::chrono::steady_clock::now(); // Start timer
    printf("Round 1 proceeding... \n");

    status = params.fetch_delay_from_dp(bfrt);

    while(1){
        // update the working copy
        // status = bfrt.update_working_copy();
        // auto rd_start_time = std::chrono::steady_clock::now();
        // auto time_diff = std::chrono::duration_cast<std::chrono::milliseconds>(rd_start_time - start_time);
        // outfile << "Round: " << time_diff.count() << std::endl;
        // for (const auto& entry : params.q_delay_map) {
        //     outfile << entry.first << ", " << static_cast<int>(entry.second.second) << std::endl;
        // }
        // outfile.flush(); // Ensure data is written to file
        // for (const auto& entry: params.q_delay_map) {
        //     printf("fp: %ld, delay: %ld, q_num: %d\n", entry.first, entry.second.first, entry.second.second);
        // }
        // printf("-------------------------------\n");

        // all shuffling happens here--> /* update q_assign --> set add, update */
        params.update_q_assign ();

        // update q_allocation based on add, update 
        status = bfrt.set_flow_q_alloc(params.update, params.add); /* later encapsulate this into  */

        // b/w allocation acc to weights, TODO: add check when normailizing here later
        params.update_weights ();
        int temp_size = params.q_weight.size(); 
        printf("Round updated weights--\n");
        for ( int i = 0; i < temp_size; ++i) {
            printf("q: %d wt: %d \n", i, params.q_weight[i]);
        }
        status = bfrt.update_q_weights(params.q_weight, params.bw_factor, params.egress_port);
    
        // set the default queue weights
        params.update_def_wt();
        status = bfrt.set_def_assign(params.def_wt);

        auto rd_start_time = std::chrono::steady_clock::now();
        auto time_diff = std::chrono::duration_cast<std::chrono::milliseconds>(rd_start_time - start_time);
        outfile << "Round: " << time_diff.count() << std::endl;

        for (const auto& entry : params.q_delay_map) {
            outfile << entry.first << ", " << static_cast<int>(entry.second.second) << std::endl;
        }
        outfile.flush();

        status = params.update_round(bfrt);
        printf("Round %d completed\n", round_num);
        round_num++;
        printf("Round %d proceeding... \n", round_num);

        // CMS related
        // switch to other CMS
        bfrt.update_cms();
        // flush the prev CMS
        bfrt.flush_cms();

        status = params.fetch_delay_from_dp(bfrt);

        // fetch_delay_thread.join();
        // flush_cms_thread.join(); // Wait for the flush thread to complete

        // auto rd_end_time = std::chrono::steady_clock::now();
        // auto update_time = std::chrono::duration_cast<std::chrono::milliseconds>(rd_end_time - rd_start_time);
        // // TODO: calc time spent in the other things and update this
        // usleep(params.round_interval*1e6-update_time.count()*1e3);
        // clear all ds for the new round
    }
    outfile.close();
    return status;
}

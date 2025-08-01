#ifndef BFRT_H
#define BFRT_H

#include <mutex>
#include <vector>
#include <unordered_map>
#include <algorithm>

#include <bf_types/bf_types.h>
#include <bf_rt/bf_rt_common.h>
#include <bf_rt/bf_rt_info.hpp>
#include <bf_rt/bf_rt_table.hpp>
#include <bf_rt/bf_rt_table_key.hpp>
#include <bf_rt/bf_rt_table_data.hpp>
// #include "bf_rt_tm_table_helper.hpp"
// #include "bf_rt_tm_table_impl.hpp"

#include "bfrt/bfrt_utils.hpp"
#include "utils/types.hpp"

/* 
    Singleton instance of BF Runtime environment
    Maintains required state and provides methods to interact with 
    the dataplane via BfRt APIs.
*/

// #define MAX_INDEX 71680
#define MAX_INDEX 65535
// #define MAX_CMS_INDEX 524287 // 2^19 -1
#define Q_ASSIGN_TO_MS 10000 // default ttl for q_assign (in ms)

class Bfruntime {
    private:

    bool m_isInitialized = false;
    static std::mutex _mutex;

    /* 
        BfRt Global Variables 
    */
    bf_rt_target_t dev_tgt;
    bf_dev_port_t in_port;

    std::shared_ptr<bfrt::BfRtSession> session;
    // std::shared_ptr<bfrt::BfRtSession> pcpp_session;
    const bfrt::BfRtInfo *bf_rt_info = nullptr; 

    /* 
        BfRt Tables/Registers Global Variables
    */
    // Egress
    DECLARE_BFRT_REG_VARS(working_copy)
    DECLARE_BFRT_REG_VARS(hash_table1)
    DECLARE_BFRT_REG_VARS(hash_table1_copy)
    DECLARE_BFRT_REG_VARS(hash_table2)
    DECLARE_BFRT_REG_VARS(hash_table2_copy)

    // CMS related
    DECLARE_BFRT_REG_VARS(working_cms)
    DECLARE_BFRT_REG_VARS(sketch0)
    DECLARE_BFRT_REG_VARS(sketch1)
    DECLARE_BFRT_REG_VARS(sketch2)
    DECLARE_BFRT_REG_VARS(sketch3)

    bf_rt_id_t hash_table1_data_id_2, hash_table1_copy_data_id_2, hash_table2_data_id_2, hash_table2_copy_data_id_2;


    // Ingress q assign Table
    const bfrt::BfRtTable *q_assign = nullptr; 
    std::unique_ptr<bfrt::BfRtTableKey> q_assign_key;
    std::unique_ptr<bfrt::BfRtTableData> q_assign_data;
    std::unique_ptr<bfrt::BfRtTableAttributes> q_assign_attribute;
    bf_rt_id_t q_assign_key_pkt_fingerprint = 0;
    bf_rt_id_t set_queue_action_id = 0;
    bf_rt_id_t set_queue_action_field_queue_num_id = 0;
    bf_rt_id_t set_queue_action_field_entry_ttl_id = 0;
    
    // Default random q assign Table
    const bfrt::BfRtTable *q_assign_wr = nullptr; 
    std::unique_ptr<bfrt::BfRtTableKey> q_assign_wr_key;
    std::unique_ptr<bfrt::BfRtTableData> q_assign_wr_data;
    bf_rt_id_t q_assign_wr_key_w_random = 0; 
    
    // bf_rt_id_t set_queue_action_id = 0;
    // bf_rt_id_t set_queue_action_field_queue_num_id = 0;

    working_copy_t currentWorkingCopy = 0;
    working_copy_t prevWorkingCopy = 0;
    bool first_round = true;

    working_copy_t current_cms = 0;
    working_copy_t prev_cms = 0;

    std::vector<delay_entry_t> intern_q_delay_vec;

    /* 
        Private constructor and destructor to avoid them being 
        called by clients.
    */
    Bfruntime();
    ~Bfruntime();

    /* Other private methods used internally */

    //
    void init();

    inline bool isInitialized() {return m_isInitialized;};

    // Inits the key and data objects for tables and registers
    void initBfRtTablesRegisters();
    
    // void IdleTimeoutCallback(const bf_rt_target_t &dev_tgt, const bfrt::BfRtTableKey *key, void *cookie);
    
    // Sets working copy (of qdepth sum/count register) to specified value
    bf_status_t set_working_copy(working_copy_t new_value);

    bf_status_t set_cms(working_copy_t new_value);
    public:

    // Swaps the working copy (of qdepth sum/count registers)
    bf_status_t update_working_copy();

    bf_status_t update_cms();

    /* Provides access to the unique instance of the singleton */
    static Bfruntime& getInstance();

    // TODO: another interface function: set_num_queues(port);

    /* return the current working copy */
    // bf_status_t get_working_copy(working_copy_t Value);

    bf_status_t set_def_assign(std::vector<std::pair<uint16_t,uint16_t>> q_weight);
    
    // fetch the register and get the value for each flow
    // -- need to fetch from the same index
    /* Pass the working copy by reference */
    bf_status_t get_qdelay(std::unordered_map<fp_t, std::pair<qdelay_t, qnum_t>> &q_delay_map, uint8_t num_queues, const std::unordered_map<fp_t, uint8_t>& curr_assign, std::vector<u_int16_t> &flows_per_queue);

    // needs to add the q_allocation
    bf_status_t set_flow_q_alloc(std::vector<flow_q_entry_t> &updated_assign , std::vector<flow_q_entry_t> &add_assign); // TODO: make Santa algo to specify the port

    // assign weight based on the num of flows in each queue
    bf_status_t update_q_weights(std::vector<uint16_t> q_weight,std::vector<double> bw_factor, bf_dev_port_t egress_port); // TODO: make Santa algo to specify the port 

    bf_status_t flush_cms(); 

    /* Singleton should not be clonable or assignable */
    Bfruntime(Bfruntime &other) = delete;
    void operator=(const Bfruntime &) = delete;

};



#endif

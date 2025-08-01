#include <bf_rt/bf_rt_common.h>
#include <bf_rt/bf_rt_init.hpp>
#include <bf_rt/bf_rt_info.hpp>
#include <bf_rt/bf_rt_session.hpp>
#include <bf_rt/bf_rt_table.hpp>
#include <bf_rt/bf_rt_table_key.hpp>
#include <bf_rt/bf_rt_table_data.hpp>
#include "bfrt/bfrt.hpp"
#include "bfrt/bfrt_utils.hpp"
#include "utils/utils.hpp"
#include "utils/types.hpp"

#include <cmath>
#include <cstdint> // For uint8_t
#include "unistd.h"

#ifdef __cplusplus
extern "C" {
#endif
/* All fixed function API includes go here */
#include <traffic_mgr/traffic_mgr_types.h>
#include <traffic_mgr/traffic_mgr_sch_intf.h>

#ifdef __cplusplus
}
#endif


#include <fstream>
#include <iostream>

#define DEV_TGT_ALL_PIPES 0xFFFF
#define DEV_TGT_ALL_PARSERS 0xFF

// TODO: has to be the dev_port
#define IN_DEV_PORT 136
#define BF_TM_CELL_SIZE_BYTES 80

// #define MAX_INDEX 65535
auto fromHwFlag = bfrt::BfRtTable::BfRtTableGetFlag::GET_FROM_HW;

// defining the static mutex in the class
std::mutex Bfruntime::_mutex;

std::fstream outfile("result.txt");

// Function to find the next power of 2 greater than or equal to n for uint8_t
uint8_t next_pow_2(uint8_t n) {
    if ((n & (n - 1)) == 0) {
        // n is already a power of 2
        return n;
    }
    uint8_t count = 0;
    while (n != 0) {
        n >>= 1;
        count += 1;
    }
    return (1 << count);
}

struct cb_cookie_struct {
    const bfrt::BfRtTable* table;
    std::shared_ptr<bfrt::BfRtSession> cb_session;
};

Bfruntime& Bfruntime::getInstance(){
   
    // making the method thread safe for instance creation
    std::lock_guard<std::mutex> lock(_mutex);

    // will create single instance on first invocation
    static Bfruntime instance;
    if(!instance.isInitialized()){
        instance.init();
    }

    return instance;
}

Bfruntime::Bfruntime(){}
Bfruntime::~Bfruntime(){
    bf_status_t status;

    status = this->session->sessionDestroy(); CHECK_BF_STATUS(status);
    // status = this->pcpp_session->sessionDestroy(); CHECK_BF_STATUS(status);

}

/* Initialize all the bfrt_targets, dev, ports  */
void Bfruntime::init(){
    bf_status_t status;

    // Init dev_tgt
    memset(&this->dev_tgt, 0, sizeof(this->dev_tgt));
    this->dev_tgt.dev_id = 0;
    this->dev_tgt.pipe_id = DEV_TGT_ALL_PIPES;

    // Init dev_port
    this->in_port = IN_DEV_PORT;

    /* Create BfRt session and retrieve BfRt Info */
    this->session = bfrt::BfRtSession::sessionCreate();
    if(this->session == nullptr){
        printf("ERROR: Couldn't create BfRtSession\n");
        exit(1); 
    }

    // this->pcpp_session = bfrt::BfRtSession::sessionCreate();
    // if(this->pcpp_session == nullptr){
    //     printf("ERROR: Couldn't create BfRtSession\n");
    //     exit(1); 
    // }

    // Get ref to the singleton devMgr
    bfrt::BfRtDevMgr &dev_mgr = bfrt::BfRtDevMgr::getInstance(); 
    status = dev_mgr.bfRtInfoGet(this->dev_tgt.dev_id, PROG_NAME, &this->bf_rt_info);

    if(status != BF_SUCCESS){
        printf("ERROR: Could not retrieve BfRtInfo: %s\n", bf_err_str(status));
        exit(status);
    }

    printf("Retrieved BfRtInfo successfully!\n");

    // Initialize the tables and registers
    this->initBfRtTablesRegisters();

    this->m_isInitialized = true;

    this->intern_q_delay_vec.resize(MAX_INDEX,{0,0});
}

// for q_assign timeout
void IdleTimeoutCallback(const bf_rt_target_t &dev_tgt, const bfrt::BfRtTableKey *key, void *cookie) {
    cb_cookie_struct* context = static_cast<cb_cookie_struct*>(cookie); // Cast cookie to your context struct
    const bfrt::BfRtTable* q_assign_table = context->table; 
    std::shared_ptr<bfrt::BfRtSession> session = context->cb_session; 
    bf_status_t status = q_assign_table->tableEntryDel(*session, dev_tgt, *key);
    CHECK_BF_STATUS(status);
    // std::cout<<"Entry removed \n";
}

void Bfruntime::initBfRtTablesRegisters(){

    bf_status_t status;

    status = bf_rt_info->bfrtTableFromNameGet("Egress.hash_table1", &hash_table1);
    CHECK_BF_STATUS(status);
    status = hash_table1->keyFieldIdGet("$REGISTER_INDEX", &hash_table1_key_id);
    CHECK_BF_STATUS(status);

    // for copy
    status = bf_rt_info->bfrtTableFromNameGet("Egress.hash_table1_copy", &hash_table1_copy);
    CHECK_BF_STATUS(status);
    status = hash_table1_copy->keyFieldIdGet("$REGISTER_INDEX", &hash_table1_copy_key_id);
    CHECK_BF_STATUS(status);

    status = bf_rt_info->bfrtTableFromNameGet("Egress.hash_table2", &hash_table2);
    CHECK_BF_STATUS(status);
    status = hash_table2->keyFieldIdGet("$REGISTER_INDEX", &hash_table2_key_id);
    CHECK_BF_STATUS(status);

    // for copy
    status = bf_rt_info->bfrtTableFromNameGet("Egress.hash_table2_copy", &hash_table2_copy);
    CHECK_BF_STATUS(status);
    status = hash_table2_copy->keyFieldIdGet("$REGISTER_INDEX", &hash_table2_copy_key_id);
    CHECK_BF_STATUS(status);
    

    status = hash_table1->dataFieldIdGet("Egress.hash_table1.fp", &hash_table1_data_id);
    CHECK_BF_STATUS(status);
    status = hash_table1->dataFieldIdGet("Egress.hash_table1.q_delay", &hash_table1_data_id_2);
    CHECK_BF_STATUS(status);

    // for copy
    status = hash_table1_copy->dataFieldIdGet("Egress.hash_table1_copy.fp", &hash_table1_copy_data_id);
    CHECK_BF_STATUS(status);
    status = hash_table1_copy->dataFieldIdGet("Egress.hash_table1_copy.q_delay", &hash_table1_copy_data_id_2);
    CHECK_BF_STATUS(status);

    status = hash_table2->dataFieldIdGet("Egress.hash_table2.fp", &hash_table2_data_id);
    CHECK_BF_STATUS(status);
    status = hash_table2->dataFieldIdGet("Egress.hash_table2.q_delay", &hash_table2_data_id_2);
    CHECK_BF_STATUS(status);

    // for copy
    status = hash_table2_copy->dataFieldIdGet("Egress.hash_table2_copy.fp", &hash_table2_copy_data_id);
    CHECK_BF_STATUS(status);
    status = hash_table2_copy->dataFieldIdGet("Egress.hash_table2_copy.q_delay", &hash_table2_copy_data_id_2);
    CHECK_BF_STATUS(status);

    INIT_BFRT_REG_VARS(this->bf_rt_info, Egress, working_copy, status)
    INIT_BFRT_REG_DIFF_VARS(this->bf_rt_info, Egress, hash_table1, status)
    INIT_BFRT_REG_DIFF_VARS(this->bf_rt_info, Egress, hash_table1_copy, status)
    INIT_BFRT_REG_DIFF_VARS(this->bf_rt_info, Egress, hash_table2, status)
    INIT_BFRT_REG_DIFF_VARS(this->bf_rt_info, Egress, hash_table2_copy, status)

    // CMS related
    INIT_BFRT_REG_VARS(this->bf_rt_info, Ingress.cms, working_cms, status)
    INIT_BFRT_REG_VARS(this->bf_rt_info, Ingress.cms, sketch0, status)
    INIT_BFRT_REG_VARS(this->bf_rt_info, Ingress.cms, sketch1, status)
    INIT_BFRT_REG_VARS(this->bf_rt_info, Ingress.cms, sketch2, status)
    INIT_BFRT_REG_VARS(this->bf_rt_info, Ingress.cms, sketch3, status)

    // working_copy register index is always going to be zero
    status = working_copy_key->setValue(working_copy_key_id, static_cast<uint64_t>(0));
    CHECK_BF_STATUS(status);
    // CMS related
    status = working_cms_key->setValue(working_cms_key_id, static_cast<uint64_t>(0));
    CHECK_BF_STATUS(status);

    /* Init the Ingress assign table*/
    status = bf_rt_info->bfrtTableFromNameGet("Ingress.q_assign", &q_assign); 
    CHECK_BF_STATUS(status);
    // Init keyField Ids
    status = q_assign->keyFieldIdGet("pkt_fingerprint", &q_assign_key_pkt_fingerprint);
    CHECK_BF_STATUS(status);
    // Init actionId
    status = q_assign->actionIdGet("Ingress.set_queue", &set_queue_action_id);
    CHECK_BF_STATUS(status);
    printf("Action ID for set_queue is %d\n", set_queue_action_id);
    // Init dataField Ids
    status = q_assign->dataFieldIdGet("queue_num", set_queue_action_id, &set_queue_action_field_queue_num_id);
    CHECK_BF_STATUS(status);
    printf("Queue Num datafield ID is %u\n", set_queue_action_field_queue_num_id);
    status = q_assign->dataFieldIdGet("$ENTRY_TTL", set_queue_action_id, &set_queue_action_field_entry_ttl_id);
    CHECK_BF_STATUS(status);
    printf("Entry TTL datafield ID is %u\n", set_queue_action_field_entry_ttl_id);
    fflush(stdout);

    // Allocate and reset key objects
    status = q_assign->keyAllocate(&q_assign_key);
    CHECK_BF_STATUS(status);
    status = q_assign->keyReset(q_assign_key.get());
    CHECK_BF_STATUS(status);
    // Allocate and reset data objects
    status = q_assign->dataAllocate(&q_assign_data);
    CHECK_BF_STATUS(status);
    status = q_assign->dataReset(set_queue_action_id, q_assign_data.get());
    CHECK_BF_STATUS(status);

    // for the idle timeout and notify mode
    status = q_assign->attributeAllocate(bfrt::TableAttributesType::IDLE_TABLE_RUNTIME, bfrt::TableAttributesIdleTableMode::NOTIFY_MODE, &q_assign_attribute);
    CHECK_BF_STATUS(status);

    const bool enable = true;
    // TODO CHANGE THISSSSS
    const uint32_t ttl_query_interval = 1000; // in ms
    const uint32_t max_ttl = 11000;
    const uint32_t min_ttl = 1000;
    void* cookie = new cb_cookie_struct{q_assign, session};
    // void* cookie = static_cast<void*>(cb_cookie);
    status = q_assign_attribute->idleTableNotifyModeSet(enable, &IdleTimeoutCallback, ttl_query_interval, max_ttl, min_ttl, cookie);
    CHECK_BF_STATUS(status);
    status = q_assign->tableAttributesSet(*session, dev_tgt, *q_assign_attribute);
    CHECK_BF_STATUS(status);

    // ***********For the default queue random queue allocation
    status = bf_rt_info->bfrtTableFromNameGet("Ingress.q_assign_wr", &q_assign_wr); 
    CHECK_BF_STATUS(status);
    // Init keyField Ids
    status = q_assign_wr->keyFieldIdGet("w_random", &q_assign_wr_key_w_random);
    CHECK_BF_STATUS(status);
    // Init actionId
    status = q_assign_wr->actionIdGet("Ingress.set_queue", &set_queue_action_id);
    CHECK_BF_STATUS(status);
    printf("Action ID for set_queue is %d\n", set_queue_action_id);
    // Init dataField Ids
    status = q_assign_wr->dataFieldIdGet("queue_num", set_queue_action_id, &set_queue_action_field_queue_num_id);
    CHECK_BF_STATUS(status);
    printf("Queue Num datafield ID is %u\n", set_queue_action_field_queue_num_id);
    fflush(stdout);

    // Allocate and reset key objects
    status = q_assign_wr->keyAllocate(&q_assign_wr_key);
    CHECK_BF_STATUS(status);
    // status = q_assign_wr->keyAllocate(&q_assign_wr_key_2);
    // CHECK_BF_STATUS(status);
    status = q_assign_wr->keyReset(q_assign_wr_key.get());
    CHECK_BF_STATUS(status);
    // Allocate and reset data objects
    status = q_assign_wr->dataAllocate(&q_assign_wr_data);
    CHECK_BF_STATUS(status);
    status = q_assign_wr->dataReset(set_queue_action_id, q_assign_wr_data.get());
    CHECK_BF_STATUS(status); 

    // set consistent initial currentWorkingCopy in CP and DP
    this->currentWorkingCopy = 0;
    this->set_working_copy(this->currentWorkingCopy);

    // CMS related
    this->current_cms= 0;
    this->set_cms(this->current_cms);

    printf("Initialized BfRt tables and registers successfully!\n");

}

/* Updates the working copy bit in the dataplane */
bf_status_t Bfruntime::set_working_copy(working_copy_t new_value){

    bf_status_t status;

    status = working_copy_data->setValue(working_copy_data_id, static_cast<uint64_t>(new_value));
    CHECK_BF_STATUS(status);

    // working_copy_key is already set to 0
    status = working_copy->tableEntryMod(*session, dev_tgt, *working_copy_key, *working_copy_data);

    return status;
}

// CMS related
/* Updates the working copy bit in the dataplane */
bf_status_t Bfruntime::set_cms(working_copy_t new_value){

    bf_status_t status;
    status = working_cms_data->setValue(working_cms_data_id, static_cast<uint64_t>(new_value));
    CHECK_BF_STATUS(status);

    status = working_cms->tableEntryMod(*session, dev_tgt, *working_cms_key, *working_cms_data);

    return status;
}

bf_status_t Bfruntime::update_working_copy(){
    bf_status_t status;
    working_copy_t new_value = (currentWorkingCopy + 1) % 2;     // toggle between 0 and 1

    status = set_working_copy(new_value);
    CHECK_BF_STATUS(status);

    // actual updation in CP
    prevWorkingCopy = currentWorkingCopy;
    currentWorkingCopy = new_value;

    return status;
}   

// CMS related
bf_status_t Bfruntime::update_cms(){
    bf_status_t status;
    working_copy_t new_value = (current_cms + 1) % 2;   // toggle between 0 and 1

    status = set_cms(new_value);
    CHECK_BF_STATUS(status);

    prev_cms = current_cms;  // actual updation in CP
    current_cms = new_value;

    return status;
}   

bf_status_t Bfruntime::set_def_assign( std::vector<std::pair<uint16_t,uint16_t>> q_weight) {
    bf_status_t status;
    status = BF_SUCCESS;
    // clear all the previous ranges
    status = q_assign_wr->tableClear(*session, dev_tgt);
    CHECK_BF_STATUS(status);

    for (size_t i = 0; i < q_weight.size(); ++i) {
        auto& entry = q_weight[i];
        if (entry.first == entry.second) {
            // printf("No weights changed--------------------------- \n");
            continue;
        }
        printf("Def Alloc_added for q %ld- %d..%d \n",i , entry.first, entry.second);
        // Prepare key
        status = q_assign_wr_key->setValueRange(q_assign_wr_key_w_random, static_cast<uint64_t>(entry.first),static_cast<uint64_t>(entry.second));
        CHECK_BF_STATUS(status);

        // Prepare data
        status = q_assign_wr_data->setValue(set_queue_action_field_queue_num_id, static_cast<uint64_t>(i));
        CHECK_BF_STATUS(status);

        // TODO: Combine with an AddOrMod
        status = q_assign_wr->tableEntryAdd(*session, dev_tgt, *q_assign_wr_key, *q_assign_wr_data);
        CHECK_BF_STATUS(status);

    }
    return status;
}

bf_status_t Bfruntime::get_qdelay( std::unordered_map<fp_t, std::pair<qdelay_t, qnum_t>> &q_delay_map, uint8_t num_queues, 
                                        const std::unordered_map<fp_t, uint8_t>& curr_assign, std::vector<uint16_t> &flows_per_queue){
    bf_status_t status;
    std::fill(flows_per_queue.begin(), flows_per_queue.end(), 0);
    if (prevWorkingCopy == 0) {
        for (index_t index = 0; index < MAX_INDEX; ++ index) {
            std::vector<uint64_t> temp_value, temp_value_2;

            status = hash_table1_key->setValue(hash_table1_key_id, static_cast<uint64_t>(index));
            CHECK_BF_STATUS(status);
            status = hash_table1->dataReset(hash_table1_data.get());
            CHECK_BF_STATUS(status);
            status = hash_table1->tableEntryGet(*session, dev_tgt, *hash_table1_key, fromHwFlag, hash_table1_data.get());
            CHECK_BF_STATUS(status);
            status = hash_table1_data->getValue(hash_table1_data_id, &temp_value);
            CHECK_BF_STATUS(status);
            status = hash_table1_data->getValue(hash_table1_data_id_2, &temp_value_2);
            CHECK_BF_STATUS(status);

            if (temp_value[0] == 0) {
                continue;
            }
            // the pipe depends on the egress port
            uint8_t num_queues_pow_2 = next_pow_2(num_queues);
            qnum_t qnum = index / (MAX_INDEX / num_queues_pow_2);

            flows_per_queue[(int)qnum] += 1;
            // since the register holds a <fp, delay> 32 bit pair 
            auto it = curr_assign.find(temp_value[0]);
            if (it != curr_assign.end()) {
                if (it->second == qnum) {
                    q_delay_map[temp_value[0]].first += temp_value_2[0];
                    q_delay_map[temp_value[0]].second = qnum;
                }
            }
            else {
                q_delay_map[temp_value[0]].first += temp_value_2[0];
                q_delay_map[temp_value[0]].second = qnum;  // Store both qdelay_t and qnum_
            }

            std::vector<uint64_t> temp_value_3, temp_value_4;

            status = hash_table1_copy_key->setValue(hash_table1_copy_key_id, static_cast<uint64_t>(index));
            CHECK_BF_STATUS(status);
            status = hash_table1_copy->dataReset(hash_table1_copy_data.get());
            CHECK_BF_STATUS(status);
            status = hash_table1_copy->tableEntryGet(*session, dev_tgt, *hash_table1_copy_key, fromHwFlag, hash_table1_copy_data.get());
            CHECK_BF_STATUS(status);
            status = hash_table1_copy_data->getValue(hash_table1_copy_data_id, &temp_value_3);
            CHECK_BF_STATUS(status);
            status = hash_table1_copy_data->getValue(hash_table1_copy_data_id_2, &temp_value_4);
            CHECK_BF_STATUS(status);

            if (temp_value_3[0] == 0) {
                continue;
            }
            // std::cout<<"Collision in q_delay struct 1\n";
            flows_per_queue[(int)qnum] += 1;
            // since the register holds a <fp, delay> 32 bit pair 
            it = curr_assign.find(temp_value_3[0]);
            if (it != curr_assign.end()) {
                if (it->second == qnum) {
                    q_delay_map[temp_value_3[0]].first += temp_value_4[0];
                    q_delay_map[temp_value_3[0]].second = qnum;
                }
            }
            else {
                q_delay_map[temp_value_3[0]].first += temp_value_4[0];
                q_delay_map[temp_value_3[0]].second = qnum;  // Store both qdelay_t and qnum_
            }

        }
        status = hash_table1->tableClear(*session, dev_tgt);
        printf("Read from the hash_table1 \n");
        status = hash_table1_copy->tableClear(*session, dev_tgt);
        printf("Read from the hash_table1_copy \n");
    }
    else {
        for (index_t index = 0; index < MAX_INDEX; ++ index) {
            // delay_entry_t *temp = &q_delay_vec[index];
            std::vector<uint64_t> temp_value, temp_value_2;

            status = hash_table2_key->setValue(hash_table2_key_id, static_cast<uint64_t>(index));
            CHECK_BF_STATUS(status);
            status = hash_table2->dataReset(hash_table2_data.get());
            CHECK_BF_STATUS(status);
            status = hash_table2->tableEntryGet(*session, dev_tgt, *hash_table2_key, fromHwFlag, hash_table2_data.get());
            CHECK_BF_STATUS(status);
            status = hash_table2_data->getValue(hash_table2_data_id, &temp_value);
            CHECK_BF_STATUS(status);
            status = hash_table2_data->getValue(hash_table2_data_id_2, &temp_value_2);
            CHECK_BF_STATUS(status);

            if (temp_value[0] == 0) {
                continue;
            }
            
            uint8_t num_queues_pow_2 = next_pow_2(num_queues);
            qnum_t qnum = index / (MAX_INDEX / num_queues_pow_2);
            
            flows_per_queue[(int)qnum] += 1;
            // since the register holds a <fp, delay> 32 bit pair 
            auto it = curr_assign.find(temp_value[0]);
            if (it != curr_assign.end()) {
                if (it->second == qnum) {
                    q_delay_map[temp_value[0]].first += temp_value_2[0];
                    q_delay_map[temp_value[0]].second = qnum;
                }
            }
            else {
                q_delay_map[temp_value[0]].first += temp_value_2[0];
                q_delay_map[temp_value[0]].second = qnum;
            }

            std::vector<uint64_t> temp_value_3, temp_value_4;

            status = hash_table2_copy_key->setValue(hash_table2_copy_key_id, static_cast<uint64_t>(index));
            CHECK_BF_STATUS(status);
            status = hash_table2_copy->dataReset(hash_table2_copy_data.get());
            CHECK_BF_STATUS(status);
            status = hash_table2_copy->tableEntryGet(*session, dev_tgt, *hash_table2_copy_key, fromHwFlag, hash_table2_copy_data.get());
            CHECK_BF_STATUS(status);
            status = hash_table2_copy_data->getValue(hash_table2_copy_data_id, &temp_value_3);
            CHECK_BF_STATUS(status);
            status = hash_table2_copy_data->getValue(hash_table2_copy_data_id_2, &temp_value_4);
            CHECK_BF_STATUS(status);

            if (temp_value_3[0] == 0) {
                continue;
            }
            
            // std::cout<<"Collision in q_delay struct 2\n";
            
            flows_per_queue[(int)qnum] += 1;
            it = curr_assign.find(temp_value_3[0]);
            if (it != curr_assign.end()) {
                if (it->second == qnum) {
                    q_delay_map[temp_value_3[0]].first += temp_value_4[0];
                    q_delay_map[temp_value_3[0]].second = qnum;
                }
            }
            else {
                q_delay_map[temp_value_3[0]].first += temp_value_4[0];
                q_delay_map[temp_value_3[0]].second = qnum; 
            }

        }
        status = hash_table2->tableClear(*session, dev_tgt);
        printf("Read from the hash_table2 \n");
        status = hash_table2_copy->tableClear(*session, dev_tgt);
        printf("Read from the hash_table2_copy \n");
    }
    return status;
}

/* Update the Q_assignment Table */
bf_status_t Bfruntime::set_flow_q_alloc(std::vector<flow_q_entry_t> &updated_assign , std::vector<flow_q_entry_t> &add_assign ) {
    bf_status_t status;
    bool* is_added = NULL;
    // int update_size = updated_assign.size();
    status = BF_SUCCESS;

    for (auto entry : add_assign) {
        // printf("Alloc_added- fp: %ld, q: %d \n", entry.fp, entry.q_num); // comment io
        // Prepare key
        status = q_assign_key->setValue(q_assign_key_pkt_fingerprint, static_cast<uint64_t>(entry.fp));
        CHECK_BF_STATUS(status);

        // Prepare data
        status = q_assign_data->setValue(set_queue_action_field_queue_num_id, static_cast<uint64_t>(entry.q_num));
        CHECK_BF_STATUS(status);
        status = q_assign_data->setValue(set_queue_action_field_entry_ttl_id, static_cast<uint64_t>(Q_ASSIGN_TO_MS));
        CHECK_BF_STATUS(status);

        // TODO: Combine with an AddOrMod
        status = q_assign->tableEntryAddOrMod(*session, dev_tgt, 0, *q_assign_key, *q_assign_data, is_added);
        CHECK_BF_STATUS(status);
    }

    for (auto entry : updated_assign) {
        // printf("Alloc_updated- fp: %ld, q: %d \n", entry.fp, entry.q_num); // comment io
        // Prepare key
        status = q_assign_key->setValue(q_assign_key_pkt_fingerprint, static_cast<uint64_t>(entry.fp));
        CHECK_BF_STATUS(status);

        // Prepare data
        status = q_assign_data->setValue(set_queue_action_field_queue_num_id, static_cast<uint64_t>(entry.q_num));
        CHECK_BF_STATUS(status);
        status = q_assign_data->setValue(set_queue_action_field_entry_ttl_id, static_cast<uint64_t>(Q_ASSIGN_TO_MS));
        CHECK_BF_STATUS(status);

        // TODO: Combine with an AddOrMod
        // status = q_assign->tableEntryMod(*session, dev_tgt, *q_assign_key, *q_assign_data);
        status = q_assign->tableEntryAddOrMod(*session, dev_tgt, 0, *q_assign_key, *q_assign_data, is_added);
        CHECK_BF_STATUS(status);
    }

    /* clear both the vectors*/
    add_assign.clear();
    updated_assign.clear();

    return status;
}

/* Update the Queue Weights, index 0 --> queue 0 */
bf_status_t Bfruntime::update_q_weights(std::vector<uint16_t> q_weight, std::vector<double> bw_factor, bf_dev_port_t egress_port) {
    // update the priority of each queue : corresponding t
    bf_status_t status;
    // avoid the unassigned error
    status = BF_SUCCESS;
    // int factor = 512;
    bf_tm_queue_t num_queues = (bf_tm_queue_t)q_weight.size();

    double min_bw = *std::min_element(bw_factor.begin(), bw_factor.end());
    // not adding additional b/w at present (tricky how to scale the bw_factor in comparision to num_flows)
    for (bf_tm_queue_t q_idx = 0; q_idx < num_queues; ++q_idx) {
        bw_factor[q_idx] = q_weight[q_idx] * bw_factor[q_idx]/min_bw;
        // std::cout<<"Queue "<<q_idx<<" q_wt "<<q_weight[q_idx]<<" added b/w "<<bw_factor[q_idx]<< "\n";
    }

    // The max supported weight value for dwrr is 1023 
    // double scaling_factor = max_weight > 0 ? 1023.0 / max_weight : 1;

    for ( bf_tm_queue_t q_idx = 0; q_idx < num_queues /* && q_weight[q_idx] */; ++q_idx) {
        // uint16_t final_weight = static_cast<uint16_t>(q_weight[q_idx] + bw_factor[q_idx]);
        // std::cout<<"Queue "<<q_idx<<" q_wt "<<q_weight[q_idx]<<"final_wt"<<final_weight<<"\n";

        if (first_round) { // enable only once in the first round
            status = bf_tm_sched_q_enable(this->dev_tgt.dev_id, egress_port, q_idx);
            CHECK_BF_STATUS(status);
            first_round = false;
        }
        
        status = bf_tm_sched_q_dwrr_weight_set(this->dev_tgt.dev_id, egress_port, q_idx, q_weight[q_idx]);
        CHECK_BF_STATUS(status);

        printf("Setting up dwrr weight q: %d wt: %d \n", q_idx, q_weight[q_idx]);
    }
    printf("Updated queue weights in the DP.... \n");
    return status;
}

// CMS related
bf_status_t Bfruntime::flush_cms() {
    bf_status_t status;
    status = BF_SUCCESS;

    status = sketch0->tableClear(*session, dev_tgt);
    printf("Flushed sketch 0... \n");
    status = sketch1->tableClear(*session, dev_tgt);
    printf("Flushed sketch 1... \n");
    status = sketch2->tableClear(*session, dev_tgt);
    printf("Flushed sketch 2... \n");
    status = sketch3->tableClear(*session, dev_tgt);
    printf("Flushed sketch 3... \n");
    // if (prev_cms == 0) {
    //     status = sketch0->tableClear(*session, dev_tgt);
    //     printf("Flushed sketch 0... \n");
    //     status = sketch1->tableClear(*session, dev_tgt);
    //     printf("Flushed sketch 1... \n");
    // } 
    // else {
    //     status = sketch2->tableClear(*session, dev_tgt);
    //     printf("Flushed sketch 2... \n");
    //     status = sketch3->tableClear(*session, dev_tgt);
    //     printf("Flushed sketch 3... \n");
    // }
    return status;
}
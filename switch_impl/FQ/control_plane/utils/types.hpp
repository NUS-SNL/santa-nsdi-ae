#ifndef TYPES_H
#define TYPES_H

#include <stdint.h>
#include <bf_types/bf_types.h>


typedef uint8_t  working_copy_t;
typedef uint64_t qdelay_t;
typedef uint64_t fp_t;
typedef uint32_t index_t;
typedef uint8_t  qnum_t;
// typedef uint16_t port_t;

/* Fingerprint(fp), Q_delay(q_delay) */
struct delay_entry_t {
    fp_t fp;
    qdelay_t q_delay;
};

/* Fingerprint(fp), Queue_num(q_num) */
struct flow_q_entry_t {
    fp_t fp;
    uint8_t q_num;
};


#endif

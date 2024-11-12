#ifndef MDRAM_H
#define MDRAM_H

#include "memory_class.h"

// DRAM configuration
#define MDRAM_CHANNEL_WIDTH 2 // 8B
#define MDRAM_WQ_SIZE 8
#define MDRAM_RQ_SIZE 8

#define tRP_MDRAM_NANOSECONDS  12.5
#define tRCD_MDRAM_NANOSECONDS 12.5
#define tCAS_MDRAM_NANOSECONDS 12.5

// the data bus must wait this amount of time when switching between reads and writes, and vice versa
#define MDRAM_DBUS_TURN_AROUND_TIME ((15*CPU_FREQ)/2000) // 7.5 ns
extern uint32_t MDRAM_MTPS, MDRAM_DBUS_RETURN_TIME;

// these values control when to send out a burst of writes
#define MDRAM_WRITE_HIGH_WM    ((MDRAM_WQ_SIZE*7)>>3) // 7/8th
#define MDRAM_WRITE_LOW_WM     ((MDRAM_WQ_SIZE*3)>>2) // 6/8th
#define MIN_MDRAM_WRITES_PER_SWITCH (MDRAM_WQ_SIZE*1/4)

// DRAM
class MD_CONTROLLER : public MEMORY {
  public:
    const string NAME;

    MDRAM_ARRAY mdram_array[DRAM_CHANNELS][DRAM_RANKS][DRAM_BANKS];
    uint64_t dbus_cycle_available[MDRAM_CHANNELS], dbus_cycle_congested[MDRAM_CHANNELS], dbus_congested[NUM_TYPES+1][NUM_TYPES+1];
    uint64_t bank_cycle_available[MDRAM_CHANNELS][MDRAM_RANKS][MDRAM_BANKS];
    uint8_t  do_write, write_mode[MDRAM_CHANNELS]; 
    uint32_t processed_writes, scheduled_reads[MDRAM_CHANNELS], scheduled_writes[MDRAM_CHANNELS];
    int fill_level;

    BANK_REQUEST bank_request[MDRAM_CHANNELS][MDRAM_RANKS][MDRAM_BANKS];

    // queues
    PACKET_QUEUE WQ[MDRAM_CHANNELS], RQ[MDRAM_CHANNELS];

    // constructor
    MD_CONTROLLER(string v1) : NAME (v1) {
        for (uint32_t i=0; i<NUM_TYPES+1; i++) {
            for (uint32_t j=0; j<NUM_TYPES+1; j++) {
                dbus_congested[i][j] = 0;
            }
        }
        do_write = 0;
        processed_writes = 0;
        for (uint32_t i=0; i<MDRAM_CHANNELS; i++) {
            dbus_cycle_available[i] = 0;
            dbus_cycle_congested[i] = 0;
            write_mode[i] = 0;
            scheduled_reads[i] = 0;
            scheduled_writes[i] = 0;

            for (uint32_t j=0; j<MDRAM_RANKS; j++) {
                for (uint32_t k=0; k<MDRAM_BANKS; k++)
                    bank_cycle_available[i][j][k] = 0;
            }

            WQ[i].NAME = "MDRAM_WQ" + to_string(i);
            WQ[i].SIZE = MDRAM_WQ_SIZE;
            WQ[i].entry = new PACKET [MDRAM_WQ_SIZE];

            RQ[i].NAME = "MDRAM_RQ" + to_string(i);
            RQ[i].SIZE = MDRAM_RQ_SIZE;
            RQ[i].entry = new PACKET [MDRAM_RQ_SIZE];
        }

        fill_level = FILL_MDRAM;
    };

    // destructor
    ~MD_CONTROLLER() {

    };

    // functions
    int  add_rq(PACKET *packet),
         add_wq(PACKET *packet),
         add_pq(PACKET *packet);

    void return_data(PACKET *packet),
         operate(),
         increment_WQ_FULL(uint64_t address);

    uint32_t get_occupancy(uint8_t queue_type, uint64_t address),
             get_size(uint8_t queue_type, uint64_t address);

    void schedule(PACKET_QUEUE *queue), process(PACKET_QUEUE *queue),
         update_schedule_cycle(PACKET_QUEUE *queue),
         update_process_cycle(PACKET_QUEUE *queue),
         reset_remain_requests(PACKET_QUEUE *queue, uint32_t channel);

    uint32_t dram_get_channel(uint64_t address),
             dram_get_rank   (uint64_t address),
             dram_get_bank   (uint64_t address),
             dram_get_row    (uint64_t address),
             dram_get_column (uint64_t address),
             drc_check_hit (uint64_t address, uint32_t cpu, uint32_t channel, uint32_t rank, uint32_t bank, uint32_t row);

    uint64_t get_bank_earliest_cycle();

    int check_dram_queue(PACKET_QUEUE *queue, PACKET *packet);
};

#endif

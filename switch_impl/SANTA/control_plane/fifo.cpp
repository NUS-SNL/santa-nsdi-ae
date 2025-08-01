/* CREDITS: 
This boiler plate code is heavily adapted from Intel Connectivity 
Academy course ICA-1132: "Barefoot Runtime Interface & PTF"
*/

/* Standard Linux/C++ includes go here */
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <string>

#include <bf_rt/bf_rt_common.h>
#include <bf_rt/bf_rt_init.hpp>
#include <bf_rt/bf_rt_session.hpp>

#include "utils/types.hpp"

#ifdef __cplusplus
extern "C" {
#endif
/* All fixed function API includes go here */
#include <bf_switchd/bf_switchd.h>

#ifdef __cplusplus
}
#endif

#include "utils/utils.hpp"
#include "algo/algo.hpp"
#include "bfrt/bfrt.hpp"
// #include "pcpp/pcpp.hpp"


/* 
 * Convenient defines that reflect SDE conventions
 */
#ifndef SDE_INSTALL
#error "Please add -DSDE_INSTALL=\"$SDE_INSTALL\" to CPPFLAGS"
#endif

#ifndef PROG_NAME
#error "Please add -DPROG_NAME=\"santa\" to CPPFLAGS"
#endif

#define CONF_FILE_DIR        "share/p4/targets/tofino"
#define CONF_FILE_PATH(prog) \
    SDE_INSTALL "/" CONF_FILE_DIR "/santa.conf"

#define INIT_STATUS_TCP_PORT 7777
#define BFSHELL SDE_INSTALL "/bin/bfshell"  // macro string concat
#define RUN_PD_RPC SDE_INSTALL "/../run_pd_rpc.py" // macro string concat

bool algo_running = true;

void interrupt_handler(int s){
    printf("\nCaught interrupt signal %d\n", s);
    algo_running = false;
}

// to initialize the switch_d with paths and ports
bf_switchd_context_t* init_switchd(){
    bf_status_t status = 0;
    bf_switchd_context_t  *switchd_ctx;

    /* Allocate switchd context */
    if ((switchd_ctx = (bf_switchd_context_t *)calloc(
             1, sizeof(bf_switchd_context_t))) == NULL)
    {
        printf("Cannot Allocate switchd context\n");
        exit(1);
    }

    /* Minimal switchd context initialization to get things going */
    switchd_ctx->install_dir           = strdup(SDE_INSTALL);
    switchd_ctx->conf_file             = strdup(CONF_FILE_PATH(PROG_NAME));
    switchd_ctx->running_in_background = true;
    switchd_ctx->dev_sts_thread        = true; 
    switchd_ctx->dev_sts_port          = INIT_STATUS_TCP_PORT;

    /* Initialize the device */
    status = bf_switchd_lib_init(switchd_ctx);
    if (status != BF_SUCCESS) {
        printf("ERROR: Device initialization failed: %s\n", bf_err_str(status));
        exit(1);
    }

    return switchd_ctx;
}

/* Our great NOS runtime goes here */
bf_status_t app_run(bf_switchd_context_t *switchd_ctx)
{
    (void) switchd_ctx; /* not needed */
    bf_status_t status = 0;
    int returnVal;
  
    /* Adding ports and one-time config (whichever possible) via bfrt_python */
    printf("\n\nConfiguring via bfrt_python script...\n");
    fflush(stdout);
    std::string bfshell_cmd = BFSHELL " -b " __DIR__ "/setup_scripts/setup_tofino_fifo.py";
    returnVal = system(bfshell_cmd.c_str());
    if(returnVal == 0)
        printf("Successfully configured via bfrt_python script\n");
    
    /* PD-fixed one-time config (whichever possible) via run_pd_rpc */
    printf("\n\nConfiguring via run_pd_rpc script...\n");
    fflush(stdout);
    std::string customPythonPath = "/home/cirlab/bf-sde-9.11.2/install/lib/python3.8/site-packages/tofino/bfrt_grpc:/home/cirlab/bf-sde-9.11.2/install/lib/python3.8/site-packages/tofino:/home/cirlab/bf-sde-9.11.2/install/lib/python3.8/site-packages";
    // Include setting PYTHONPATH in the command. Also, ensure SDE_INSTALL is set as needed.
    std::string run_pd_rpc_cmd = "env PYTHONPATH=" + customPythonPath + " SDE_INSTALL=" SDE_INSTALL " " RUN_PD_RPC " " __DIR__ "/setup_scripts/set_rate_fifo.py";
    // std::string run_pd_rpc_cmd = "env SDE_INSTALL=" SDE_INSTALL " " RUN_PD_RPC " " __DIR__ "/setup_scripts/set_rate.py";
    returnVal = system(run_pd_rpc_cmd.c_str());
    if(returnVal == 0)
        printf("Successfully configured via run_pd_rpc script\n");
    

    std::ofstream outfile("q_log.txt");

    if (!outfile.is_open()) {
        printf("Error opening output file!\n");
    }

    // status = santaAlgo(outfile, algo_running);
    // CHECK_BF_STATUS(status);

    // printf("Stopped santaAlgo\n");
    // stop_pcpp_capture();
    // int count = 10;
    // while (count) {
    //     sleep(1); // sleep 3 seconds for DPDK port to be UP
    //     count--;
    // }

    return status;
}


int main(int argc, char **argv){
    
    (void)argc;
    (void)argv;

    // LOOK WHY
    signal(SIGINT,interrupt_handler);

    bf_status_t status = 0;
    bf_switchd_context_t  *switchd_ctx;

    /* Check if this CP program is being run as root */
    if (geteuid() != 0) {
        printf("ERROR: This control plane program must be run as root (e.g. sudo %s)\n", argv[0]);
        exit(1);
    }

    /* Initialize the switchd context */
    switchd_ctx = init_switchd();

    /* Run the CP app */
    status = app_run(switchd_ctx);
    CHECK_BF_STATUS(status);

    /* Keep running until interrupted */
    while (algo_running) {
        sleep(1); // Prevent busy-waiting
    }
    
    printf("Finished running the CP app\n");

    if (switchd_ctx) free(switchd_ctx);

    return status;
}

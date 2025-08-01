dptf := /cebinae/vm/lucid_binaries/dptf

BF_DRV_SRC := ${SDE}/pkgsrc/bf-drivers

TOFINO_CPP_FLAGS := -I${SDE_INSTALL}/include/target-sys -I${SDE}/pkgsrc/target-syslibs/include -Wno-missing-field-initializers -Werror -Wshadow -g -O2 -std=c++11 -MMD -MF $@.d
TOFINO_CPP_LIBS := -ldriver -lbfutils -lpifeproto -lpiall -lm -ldl -lpthread -pthread -Wl,--disable-new-dtags -L${SDE_INSTALL}/lib -Wl,-rpath -Wl,${SDE_INSTALL}/lib
# TOFINO_CPP_LIBS := -ldriver -lbfutils -lbfsys -lbf_switchd_lib -lpifeproto -lpiall -lm -ldl -lpthread -pthread -Wl,--disable-new-dtags -L${SDE_INSTALL}/lib -Wl,-rpath -Wl,${SDE_INSTALL}/lib

customPythonPath := /home/cirlab/bf-sde-9.11.2/install/lib/python3.8/site-packages/tofino/bfrt_grpc:/home/cirlab/bf-sde-9.11.2/install/lib/python3.8/site-packages/tofino:/home/cirlab/bf-sde-9.11.2/install/lib/python3.8/site-packages

.PHONY: test

# Compile lucid code to P4 library
compile: egress.dpt
	$(dptf) egress.dpt

# compile P4 program and control plane
build: main.p4 egress.dpt.p4 main.py main.cpp
	./libs/p4tapp.sh build main.p4
	env PYTHONPATH=$(customPythonPath) ${SDE_INSTALL}/bin/generate_tofino_pd --context_json ./main/pipe/context.json -o pd	
	env PYTHONPATH=$(customPythonPath) python3 ./pd_helpers_gen.py
	g++ -I${BF_DRV_SRC}/include -I${SDE_INSTALL}/include ${TOFINO_CPP_FLAGS} -o main/bf_switchd main.cpp ${TOFINO_CPP_LIBS}

# compile control plane only
buildcontrol: main.cpp
	${SDE_INSTALL}/bin/generate_tofino_pd --context_json ./main/pipe/context.json -o pd	
	env PYTHONPATH=$(customPythonPath) ./pd_helpers_gen.py
	g++ -I${BF_DRV_SRC}/include -I${SDE_INSTALL}/include ${TOFINO_CPP_FLAGS} -o main/bf_switchd main.cpp ${TOFINO_CPP_LIBS}


# Run test case in tofino asic simulator.
test:
	./libs/p4tapp.sh test main.p4 test.json # $(RUN_ARGS)

sim: 
	./libs/p4tapp.sh sim main.p4

test_on_running_sim:
	./libs/p4tapp.sh test_on_running_sim test.json


hw_baseline: 
	- sudo killall bf_switchd
	./libs/p4tapp.sh hw main.p4 baseline

hw_cebinae:
	- sudo killall bf_switchd
	./libs/p4tapp.sh hw main.p4 cebinae



# TODO -- run switchd and controller on physical tofino. 
# run
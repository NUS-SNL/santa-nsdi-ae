# SANTA Implementation
This repository contains the source code and the experiment setup for our paper "Managing Congestion Control Heterogeneity on the Internet with Approximate Performance Isolation"  ([link to paper](https://github.com/NUS-SNL/santa-nsdi-ae/blob/main/nsdi26spring-paper101.pdf))
We provide the p4 implementation of our multi-queue AQM, Santa, along with other the implementations we compared it with. We prototype our implementation using an Intel Tofino switch with a C++ control plane, and use another server for sending traffic across the switch.
---

## Setup Requirements

We implemented and require the following environment for conducting the experiments:

* **Hardware:** Intel Tofino/Tofino2 switch and a server for launching (and capturing) flows
* **SDE Version:** We use `bf-sde 9.11.2`, should be compatible with `bf-sde 9.10.x` onwards
* **Control Plane:** Python 3.8 for `bfrt` and `pd-rpc` configuration 

While we cannot provide direct access to our hardware, the results are reproducible by reviewers with access to a compatible switch environment. The control plane relies on Barefoot-specific runtime APIs included in the SDE.

---

## P4 Implementation
The `switch_impl` directory contains the P4 code and control plane implementation for SANTA and other reference implementations including FIFO, Cebinae, CoDel, HCSFQ, and FQ. At the heart of SANTA are the count-min sketch (implemented in p4src/include/cms.p4), shuffling and queue allocation schemes (implemented in the control_plane/algo/algo.cpp). Every SANTA round duration we aggregate the buffer occupancy for each flow (using tcp_options field to store the metadata), shuffle and update allocation in the CP. Further details on the code structure, running it and configuring parameters (like number of queues, buffer sizes, etc.) are present in the README within the `switch_impl` directory.


## Setting up traffic
We primarily used another server with iperf to launch flows (with different CCAs and RTTs) and tcpdump to capture traffic. The `eval` directory contains the setup details and scripts. 


# P4 Prototype

## Code Structure

The primary implementation of SANTA is located in the `SANTA/` directory. The repository also includes P4 code for other scheduling algorithms for comparison.

Key components for **SANTA** within `SANTA/` include:

* **`control_plane/`**: Contains the C++ control plane logic.
    * **`setup_scripts/`**: Includes Python scripts for configuring rate-limiting, buffer allocation, and switch queues.
    * **`algo/algo.cpp`**: Implements the core queue allocation and shuffling algorithm.
    * **`bfrt.cpp`**: Contains functions for interacting with the switch's registers and tables via the bfrt APIs.
    * **`santa.cpp`**: The main control plane application.
* **`p4src/`**: Contains the P4 data plane code for SANTA.

---

## Usage

### 1. Compiling the code

**Data Plane (P4)**

Compile the `santa.p4` program using the SDE build script:
```bash
$SDE/p4_build.sh -p ./SANTA/p4src/santa.p4
````

**Control Plane (C++)**

Navigate to the control plane directory and use `make`:

```bash
cd SANTA/control_plane
make
```

### 2\. Running the code

Execute the `run.sh` script from the control plane directory to start the experiment:

```bash
cd SANTA/control_plane
sh run.sh
```

**Note:** The workflows for running FIFO and FQ evaluations are similar. The FQ implementation can also be run from its own directory using its specific scripts.

-----

## Configuring Parameters

Experiment parameters can be modified by editing the configuration files and recompiling the relevant code. All specified paths are relative to the repository root.

### Changing the Number of Queues

To change the number of default queues, you must update the configuration in three places and re-compile the code.

**Important:** The dedicated mice queue is not included in this count. For example, setting `NUM_Q` to **3** will result in 3 default queues plus 1 mice queue, for a total of 4.

1.  **P4 Data Plane:** Modify the `NUM_Q` constant in `./SANTA/p4src/santa.p4`.
2.  **Control Plane Algorithm:** Update the `num_queue` variable in `./SANTA/control_plane/algo/algo.cpp`.
3.  **Setup Scripts:** Change the `num_queue` variable in both `./SANTA/control_plane/setup_scripts/set_rate.py` and `setup_tofino_santa.py`.

### Changing Bandwidth and Buffer Size

Bandwidth and buffer sizes are configured in the setup scripts. No recompilation of the P4 or C++ code is needed for these changes.

  * Edit the `RATE_IN_KBPS` and `buf_size` variables in the following files:
      * `./SANTA/control_plane/setup_scripts/set_rate.py`
      * `./SANTA/control_plane/setup_scripts/setup_tofino_santa.py`
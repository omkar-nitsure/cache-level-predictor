#!/bin/bash
#
# Local job script
#
# Traces:
#    bwaves_98B.trace
#
# Experiments:
#    nopref: --warmup_instructions=100000000 --simulation_instructions=500000000 --llc_replacement_type=ship --config=/home/omkar/Desktop/Project_CS683/Hermes/config/nopref.ini --num_rob_partitions=3 --rob_partition_size=64,128,320 --rob_frontal_partition_ids=0 --rob_dorsal_partition_ids=2
#    pythia: --warmup_instructions=100000000 --simulation_instructions=500000000 --llc_replacement_type=ship --config=/home/omkar/Desktop/Project_CS683/Hermes/config/pythia.ini --scooby_enable_direct_pref_issue=true --scooby_pref_at_lower_level=true --scooby_dyn_degrees_type2=1,1,2,4
#
../../bin/glc-perceptron-no-no-no-no-multi-1core-1ch --warmup_instructions=100000000 --simulation_instructions=500000000 --llc_replacement_type=ship --config=/home/omkar/Desktop/Project_CS683/Hermes/config/nopref.ini --num_rob_partitions=3 --rob_partition_size=64,128,320 --rob_frontal_partition_ids=0 --rob_dorsal_partition_ids=2 --warmup_instructions=1000000 --simulation_instructions=1000000 -traces /home/omkar/Desktop/Project_CS683/Hermes/traces/bwaves_98B.trace.xz > bwaves_98B.trace_nopref.out 2>&1 &
../../bin/glc-perceptron-no-no-no-no-multi-1core-1ch --warmup_instructions=100000000 --simulation_instructions=500000000 --llc_replacement_type=ship --config=/home/omkar/Desktop/Project_CS683/Hermes/config/pythia.ini --scooby_enable_direct_pref_issue=true --scooby_pref_at_lower_level=true --scooby_dyn_degrees_type2=1,1,2,4 --warmup_instructions=1000000 --simulation_instructions=1000000 -traces /home/omkar/Desktop/Project_CS683/Hermes/traces/bwaves_98B.trace.xz > bwaves_98B.trace_pythia.out 2>&1 &

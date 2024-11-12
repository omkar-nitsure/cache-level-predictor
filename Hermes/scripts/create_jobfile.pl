#!/usr/bin/perl

use warnings;
use Getopt::Long;

# Default parameters
my $exe = "../../bin/glc-perceptron-no-no-no-no-multi-1core-1ch";
my $local = "1";
my $num_parallel = 8;
my $ncores = 1;
my $slurm_partition = "slurm_part";
my $hostname = "kratos";
my $extra;

# Get any command-line options
GetOptions(
    'exe=s' => \$exe,
    'ncores=s' => \$ncores,
    'local=s' => \$local,
    'num_parallel=s' => \$num_parallel,
    'partition=s' => \$slurm_partition,
    'hostname=s' => \$hostname,
    'extra=s' => \$extra,
) or die "Usage: $0 --exe <executable>\n";

# Check if HERMES_HOME is set
die "\$HERMES_HOME env variable is not defined.\nHave you sourced setvars.sh?\n" unless defined $ENV{'HERMES_HOME'};

# Hardcoded trace configurations
my @trace_info = (
    { NAME => "bwaves_98B.trace", TRACE => "$ENV{'HERMES_HOME'}/traces/bwaves_98B.trace.xz", KNOBS => "--warmup_instructions=1000000 --simulation_instructions=1000000" },
);

# Hardcoded experiment configurations
my @exp_info = (
    { NAME => "nopref", KNOBS => "--warmup_instructions=100000000 --simulation_instructions=500000000 --llc_replacement_type=ship --config=$ENV{'HERMES_HOME'}/config/nopref.ini --num_rob_partitions=3 --rob_partition_size=64,128,320 --rob_frontal_partition_ids=0 --rob_dorsal_partition_ids=2" },
    { NAME => "pythia", KNOBS => "--warmup_instructions=100000000 --simulation_instructions=500000000 --llc_replacement_type=ship --config=$ENV{'HERMES_HOME'}/config/pythia.ini --scooby_enable_direct_pref_issue=true --scooby_pref_at_lower_level=true --scooby_dyn_degrees_type2=1,1,2,4" },
    # Add additional experiment configurations here if needed
);

# Output SBATCH script preamble
if ($local eq "0") {
    print "#!/bin/bash -l\n#\n# SLURM job script\n";
} else {
    print "#!/bin/bash\n#\n# Local job script\n";
}
print "#\n# Traces:\n";
foreach my $trace (@trace_info) {
    my $trace_name = $trace->{"NAME"};
    print "#    $trace_name\n";
}
print "#\n# Experiments:\n";
foreach my $exp (@exp_info) {
    my $exp_name = $exp->{"NAME"};
    my $exp_knobs = $exp->{"KNOBS"};
    print "#    $exp_name: $exp_knobs\n";
}
print "#\n";

# Run each trace and experiment configuration
my $count = 0;
foreach my $trace (@trace_info) {
    foreach my $exp (@exp_info) {
        my $exp_name = $exp->{"NAME"};
        my $exp_knobs = $exp->{"KNOBS"};
        my $trace_name = $trace->{"NAME"};
        my $trace_input = $trace->{"TRACE"};
        my $trace_knobs = $trace->{"KNOBS"};

        # Define command based on local or SLURM execution
        my $cmdline;
        if ($local) {
            $cmdline = "$exe $exp_knobs $trace_knobs -traces $trace_input > ${trace_name}_${exp_name}.out 2>&1";
            $count++;
            if ($count % $num_parallel) {
                $cmdline = $cmdline . ' &';
            }
        } else {
            my $slurm_cmd = "sbatch -p $slurm_partition --mincpus=1";
            $slurm_cmd .= " --nodelist=${hostname}" if defined $hostname;
            $slurm_cmd .= " $extra" if defined $extra;
            $slurm_cmd .= " -c $ncores -J ${trace_name}_${exp_name} -o ${trace_name}_${exp_name}.out -e ${trace_name}_${exp_name}.err";
            $cmdline = "$slurm_cmd $ENV{'HERMES_HOME'}/wrapper.sh $exe \"$exp_knobs $trace_knobs -traces $trace_input\"";
        }

        # Print and execute command
        print "$cmdline\n";
    }
}


#!/bin/bash
#!
#! Example SLURM job script for Peta4-IceLake (Ice Lake CPUs, HDR200 IB)
#! Last updated: Sat Jul 31 15:39:45 BST 2021
#!

#!#############################################################
#!#### Modify the options in this section as appropriate ######
#!#############################################################

#! sbatch directives begin here ###############################
#! Name of the job:
#SBATCH -J cpujob
#! Which project should be charged:
#SBATCH -A INOUYE-SL2-CPU
#SBATCH -p icelake
#! How many whole nodes should be allocated?
#SBATCH --nodes=1
#! How many (MPI) tasks will there be in total? (<= nodes*76)
#! The Ice Lake (icelake) nodes have 76 CPUs (cores) each and
#! 3380 MiB of memory per CPU.
#SBATCH --ntasks=76
#! How much wallclock time will be required?
#SBATCH --time=02:00:00
#! What types of email messages do you wish to receive?
#SBATCH --mail-type=NONE
#! Uncomment this to prevent the job from being requeued (e.g. if
#! interrupted by node failure or system downtime):
##SBATCH --no-requeue

#! sbatch directives end here (put any additional directives above this line)

#! Notes:
#! Charging is determined by cpu number*walltime.
#! The --ntasks value refers to the number of tasks to be launched by SLURM only. This
#! usually equates to the number of MPI tasks launched. Reduce this from nodes*76 if
#! demanded by memory requirements, or if OMP_NUM_THREADS>1.
#! Each task is allocated 1 CPU by default, and each CPU is allocated 3380 MiB
#! of memory. If this is insufficient, also specify
#! --cpus-per-task and/or --mem (the latter specifies MiB per node).

#! Number of nodes and tasks per node allocated by SLURM (do not change):
numnodes=$SLURM_JOB_NUM_NODES
numtasks=$SLURM_NTASKS
mpi_tasks_per_node=$(echo "$SLURM_TASKS_PER_NODE" | sed -e  's/^\([0-9][0-9]*\).*$/\1/')

#! ############################################################
#! Modify the settings below to specify the application's environment, location 
#! and launch method:

#! Optionally modify the environment seen by the application
#! (note that SLURM reproduces the environment at submission irrespective of ~/.bashrc):
. /etc/profile.d/modules.sh                # Leave this line (enables the module command)
module purge                               # Removes all modules still loaded
module load rhel8/default-icl              # REQUIRED - loads the basic environment

tmppath=/rds/project/asb38/rds-asb38-ceu-ukbiobank/projects/P7439/inouyelab/rx235/tmp
nodeDir=`mktemp -d $tmppath/${pref}_XXXX`
#binDir=/usr/local/bin/

echo "SLURM_JOBID="$SLURM_JOBID
echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
echo "SLURM_NNODES"=$SLURM_NNODES
echo "SLURMTMPDIR="$nodeDir
echo "working directory = "$SLURM_SUBMIT_DIR

echo "Job of $pref started at"|paste -d ' ' - <(date)

#==========
cd $nodeDir
#---run sblup
h2fn=full/path/to/h2file #precalculated heritability for all traits
rgfn=full/path/to/rgfile #precalculated geneic correlation between all traits
nfn=full/path/to/nsfile #precalculated sample size for all traits
scorepath=full/path/to/pgsfolder # precalculated single-trait PGS for all traits in plink format
outpath=outpath
source activate ldsc
python /home/rx235/smtpred/smtpred.py \
  --h2file $h2fn \
  --rgfile $rgfn \
  --nfile $nfn \
  --scorefiles $scorepath/tr01.profile \
               $scorepath/tr02.profile \
               $scorepath/tr03.profile \
               $scorepath/tr04.profile \
               $scorepath/tr05.profile \
               $scorepath/tr06.profile \
               $scorepath/tr07.profile \
               $scorepath/tr08.profile \
               $scorepath/tr09.profile \
               $scorepath/tr10.profile \
               $scorepath/tr11.profile \
               $scorepath/tr12.profile \
               $scorepath/tr13.profile \
               $scorepath/tr14.profile \
               $scorepath/tr15.profile \
               $scorepath/tr16.profile \
               $scorepath/tr17.profile \
               $scorepath/tr18.profile \
               $scorepath/tr19.profile \
               $scorepath/tr20.profile \
               $scorepath/tr21.profile \
               $scorepath/tr22.profile \
               $scorepath/tr23.profile \
               $scorepath/tr24.profile \
               $scorepath/tr25.profile \
               $scorepath/tr26.profile \
               $scorepath/tr27.profile \
               $scorepath/tr28.profile \
               $scorepath/tr29.profile \
  --out $outpath \
  --alltraits


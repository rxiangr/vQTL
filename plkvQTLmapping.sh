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
#==========

#---run plink subset
#trNum: the number of traits,eg 1-29
#chrn: chromsome number
#snpsubfn: A SNP file that contains information from SNP file
#maccut: minior allele count cutoff
#mafcut: minor allele frequ cutoff
#hwecut: Hardy-Weinberg Equilibrium: cutoff
#imputecut: impute score cutoff
#missingcut: missing rate cutoff
#bfpref: plink binary file prefix
#keepfn: a file that contains a subset of individuals used in the analysis
#phefn: phenotype file
#outpath: output path
#outpref: output prefix
#pref: job prefix
#corNum: number of core requested
#memg: number of memory requested

/home/rx235/plink --bfile $bfpref  --keep $keepfn --extract <(grep -v "#" $snpsubfn|awk -v mafcut="$mafcut" -v hwecut="$hwecut" -v imputecut="$imputecut" -v missingcut="$missingcut" '$14>=mafcut&&$8>=hwecut&&$18>=imputecut&&$19<missingcut{print$2}') --make-bed --out $outpref --threads $corNum

if [ $? -gt 0 ]; then
         echo "ERROR; OSCA failed on the compute node"
         exit 1
       fi

#---not to have dupolicated SNP id
awk 'BEGIN {FS = "\t";OFS = "\t"} {print$1,$2"_"$5"_"$6,$3,$4,$5,$6}' ${outpref}.bim > ${outpref}_new.bim
if [ $? -gt 0 ]; then
         echo "ERROR; failed to awk change bim file on the compute node"
         exit 1
       fi

mv ${outpref}.fam ${outpref}_new.fam
mv ${outpref}.bed ${outpref}_new.bed

#---subset phenotype
awk -v trNum="$trNum" 'BEGIN {FS = "\t";OFS = "\t"}{print$1,$2,$(2+trNum)}' $phefn > pheno
if [ $? -gt 0 ]; then
         echo "ERROR; failed to awk subset phe file on the compute node"
         exit 1
       fi


#---run vQTL
/home/rx235/osca-0.46.1-linux-x86_64/osca-0.46.1 --vqtl --bfile ${outpref}_new --pheno pheno --vqtl-mtd 2  --out $outpath/$outpref --thread-num $corNum

if [ $? -gt 0 ]; then
        echo "ERROR; failed to run OSCA vQTL on the compute node"
        rm *.bim
        rm *.bed
        rm *.fam
        exit 1
       fi

#---remove temp folder
cd ..
rm -r $nodeDir

##############################################################
### You should not have to change anything below this line ####
###############################################################

cd $workdir
echo -e "Changed directory to `pwd`.\n"

JOBID=$SLURM_JOB_ID

echo -e "JobID: $JOBID\n======"
echo "Time: `date`"
echo "Running on master node: `hostname`"
echo "Current directory: `pwd`"

if [ "$SLURM_JOB_NODELIST" ]; then
        #! Create a machine file:
        export NODEFILE=`generate_pbs_nodefile`
        cat $NODEFILE | uniq > machine.file.$JOBID
        echo -e "\nNodes allocated:\n================"
        echo `cat machine.file.$JOBID | sed -e 's/\..*$//g'`
fi

echo -e "\nnumtasks=$numtasks, numnodes=$numnodes, mpi_tasks_per_node=$mpi_tasks_per_node (OMP_NUM_THREADS=$OMP_NUM_THREADS)"

echo -e "\nExecuting command:\n==================\n$CMD\n"

eval $CMD 

#!/bin/bash
#SBATCH -p short
#SBATCH -t 0-04:00
#SBATCH -c 1
#SBATCH --mem=1G
#SBATCH -o ./%j.out
#SBATCH -e ./%j.err
#SBATCH--mail-type=FAIL

srun -c 1 --mem 1G "$PATH_TO_PROVEAN"/bin/provean.sh \
-q $1/$2_aa_ref.fasta \
-v $1/$2_aa_change \
--num_threads 1 \
> $1/$2_provean_output
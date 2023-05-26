#!/bin/bash
#SBATCH  --job-name=slm
#SBATCH  --nodes=1
#SBATCH  --exclusive
#SBATCH  --time=00:16:00
#SBATCH  --qos=debug
#SBATCH  --partition=standard
#SBATCH  --account=t23_sealevel   # account name

date
srun -n 1 ./runslm
date

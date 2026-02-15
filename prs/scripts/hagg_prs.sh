#!/bin/bash           #   the shell language when run outside of the job scheduler
                      # lines starting with #$ is an instruction to the job scheduler
#$ -S /bin/bash       # the shell language when run via the job scheduler [IMPORTANT]
#$ -cwd               # job should run in the current working directory
##$ -l mem_free=1G     #$ -l mem_free=1G     # job requires up to 1 GiB of RAM per slot
##$ -l scratch=0G      # job requires up to 2 GiB of local /scratch space
##$ -l h_rt=00:00:00   # job requires up to 24 hours of runtime
#$ -r y               # if job crashes, it should be restarted
##$ -t 1-10           # array job with 10 tasks (remove first '#' to enable)

# edit here

module load CBI plink

plink \
--bfile /wynton/group/andrews/data/reference_panels/EUR_All_Chr \
--score /wynton/group/andrews/users/achatterjee/prs/data/mtDNAcn_clump_hagg_apoe_removed.txt 1 2 3 header \
--out hagg_prs


# Snakemake workflow for TitanCNA_SV_WGS_tumorOnly
#

# Modules to load
* ml snakemake/5.19.2-foss-2019b-Python-3.7.4
* ml R/3.6.2-foss-2019b-fh1
* ml Python/3.7.4-foss-2019b-fh1
* ml BCFtools/1.9-GCC-8.3.0
* ml Pysam/0.15.4-GCC-8.3.0-Python-3.7.4
* ml PyYAML/5.1.2-GCCcore-8.3.0-Python-3.7.4

# Set-up
## config/samples.yaml
Please specify the samples to be analyzed in config/samples.yaml, following the format explained therein.
 
## config/config.yaml
There are a number of parameters to adjust in config/config.yaml.  Filepaths to where your TitanCNA and ichorCNA repository as well as the filepath to tools (samTools, bcfTools, svaba) and readCounterScript.

# Running the snakemake workflows on slurm cluster


`snakemake -s TitanCNA.snakefile --latency-wait 60 --restart-times 3 --keep-going --cluster-config config/cluster_slurm.yaml --cluster "sbatch -p {cluster.partition} --mem={cluster.mem} -t {cluster.time} -c {cluster.ncpus} -n {cluster.ntasks} -o {cluster.output}" -j 30`

`snakemake -s svaba.snakefile --latency-wait 60 --cluster-config config/cluster_slurm.yaml --cluster "sbatch -p {cluster.partition} --mem={cluster.mem} -t {cluster.time} -c {cluster.ncpus} -n {cluster.ntasks} -o {cluster.output}" -j 30`

`snakemake -s combineSvabaTitan.snakefile --latency-wait 60 --keep-going  --restart-times 3 --cluster-config config/cluster_slurm.yaml --cluster "sbatch -p {cluster.partition} --mem={cluster.mem} -t {cluster.time} -c {cluster.ncpus} -n {cluster.ntasks} -o {cluster.output}" -j 30`

# Whole Exome Sequencing Analysis 

The tumor-only pipeline can be applied to whole exome sequencing (WES) data. This pipeline is applicable for 2 scenarios:

1. There is only a **single** normal sample that was processed and sequenced identically as the tumor samples of interest.
2. There are a **set** of normal samples that was processed and sequenced identically as the tumor samples. The normal samples may or may not be patient-matched to the tumor samples.

There are 3 main steps to set up this analysis.

## 1. Create a Panel Of Normals (PoN)
Follow the instructions for creating the PoN file here: https://github.com/broadinstitute/ichorCNA/wiki/Create-Panel-of-Normals

However, make sure to use the updated version of the R script https://github.com/GavinHaLab/ichorCNA/blob/master/scripts/createPanelOfNormals.R

Specify the exon target bed file using argument `--exons.bed`:
https://github.com/GavinHaLab/ichorCNA/blob/85c4339d7ced280d8e2113055f832911ea81cd08/scripts/createPanelOfNormals.R#L24


## 2. Set `config.yaml` parameters
- Specify the exon target bed file
```
ichorCNA_exons: WES_target.bed
```
https://github.com/GavinHaLab/ichorCNA/blob/85c4339d7ced280d8e2113055f832911ea81cd08/scripts/snakemake/config/config.yaml#L20

- Specify the newly created PoN file
```
ichorCNA_normalPanel: my_new_pon.rds
```
https://github.com/GavinHaLab/ichorCNA/blob/85c4339d7ced280d8e2113055f832911ea81cd08/scripts/snakemake/config/config.yaml#L13

## 3. Use normalpanel parameter from ichorCNA.snakefile
- Uncomment following line
https://github.com/GavinHaLab/TitanCNA_SV_WGS_tumorOnly/blob/0032aae86465c7e97daa0c5d0e8ca91cc04349d4/ichorCNA.snakefile#L50

- Make sure to add `--normalPanel {params.normalpanel}` to here
https://github.com/GavinHaLab/TitanCNA_SV_WGS_tumorOnly/blob/0032aae86465c7e97daa0c5d0e8ca91cc04349d4/ichorCNA.snakefile#L76

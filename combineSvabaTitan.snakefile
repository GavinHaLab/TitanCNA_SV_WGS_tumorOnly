configfile: "config/config_hg38.yaml"
configfile: "config/samples.yaml"

import glob
def getLRFullPath(base, filename):
  return glob.glob(''.join([base, "/*/outs/", filename]))
  
def getTITANpath(id, ext):
  return glob.glob(''.join(["results/titan/hmm/optimalClusterSolution/", id, "_cluster*", ext]))

def getICHORpath(id, ext):
  return glob.glob(''.join(["results/ichorCNA/", id, "/", id, ext]))

CHRS = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,'X']

#TUM, CLUST = glob_wildcards("../../TITAN/snakemake/results/titan/optimalClusterSolution/{tum}_cluster1.titan.ichor.cna.txt")
#SEG,CLUST = glob_wildcards(config["titanPath"], "/results/titan/optimalClusterSolution/{tumor}_cluster{clust}.titan.ichor.cna.txt")


rule all:
  input: 
  	expand("results/combineSVABAandTITAN/{tumor}/{tumor}.svabaTitan.sv.txt", tumor=config["samples"]),
  	expand("results/combineSVABAandTITAN/{tumor}/{tumor}.svabaTitan.cn.txt", tumor=config["samples"]),
  	expand("results/combineSVABAandTITAN/{tumor}/{tumor}.svabaTitan.sv.bedpe", tumor=config["samples"]),
  	#expand(directory("results/plotSVABAandTITAN/{tumor}"), tumor=config["pairings"])
  	expand("results/plotSVABAandTITAN/{tumor}/{tumor}_CNA-SV-BX_{type}_chr{chr}.{format}", tumor=config["samples"], type=config["plot_type"], chr=CHRS, format=config["plot_format"]),
  	expand("results/plotSVABAandICHOR/{tumor}/{tumor}_CNA-SV-BX_{type}_chr{chr}.{format}", tumor=config["samples"], type=config["plot_type"], chr=CHRS, format=config["plot_format"])

rule combineSVABAandTITAN:
	input:
		svabaVCF="results/svaba/{tumor}/{tumor}.svaba.sv.vcf",
		titanBinFile=lambda wildcards: getTITANpath(wildcards.tumor, ".titan.ichor.cna.txt"),
		titanSegFile=lambda wildcards: getTITANpath(wildcards.tumor, ".titan.ichor.seg.noSNPs.txt"),
	output:
		outputSVFile="results/combineSVABAandTITAN/{tumor}/{tumor}.svabaTitan.sv.txt",
		outputBedpeFile="results/combineSVABAandTITAN/{tumor}/{tumor}.svabaTitan.sv.bedpe",
		outputCNFile="results/combineSVABAandTITAN/{tumor}/{tumor}.svabaTitan.cn.txt"
	params:
		combineSVCNscript=config["combineSVCN_script"],
		svabafuncs=config["svaba_funcs"],
		genomeBuild=config["genomeBuild"],
		genomeStyle=config["genomeStyle"],
		chrs=config["plot_chrs"],
		minSPAN=config["svaba_minSPAN"],
		minInversionSPAN=config["svaba_minInversionSPAN"]
	log:
		"logs/combineSVABAandTITAN/{tumor}.log"
	shell:
		"Rscript {params.combineSVCNscript} --id {wildcards.tumor} --svaba_funcs {params.svabafuncs} --svabaVCF {input.svabaVCF} --titanBinFile {input.titanBinFile} --titanSegFile {input.titanSegFile} --genomeBuild {params.genomeBuild} --genomeStyle {params.genomeStyle} --chrs \"{params.chrs}\" --minSPAN {params.minSPAN} --minInversionSPAN {params.minInversionSPAN} --outDir results/combineSVABAandTITAN/{wildcards.tumor}/ --outputSVFile {output.outputSVFile} --outputCNFile {output.outputCNFile} --outputBedpeFile {output.outputBedpeFile} > {log} 2> {log}"
		
rule plotSVABAandTITAN:
	input:
		svabaVCF="results/combineSVABAandTITAN/{tumor}/{tumor}.svabaTitan.sv.txt",
		titanBinFile=lambda wildcards: getTITANpath(wildcards.tumor, ".titan.ichor.cna.txt"),
		titanSegFile=lambda wildcards: getTITANpath(wildcards.tumor, ".titan.ichor.seg.noSNPs.txt"),
		titanParamFile=lambda wildcards: getTITANpath(wildcards.tumor, ".params.txt")
	output:
		"results/plotSVABAandTITAN/{tumor}/{tumor}_CNA-SV-BX_{type}_chr{chr}.{format}"
	params:
		plotSVCNscript=config["plotSVCN_script"],
		svabafuncs=config["svaba_funcs"],
		plotfuncs=config["plot_funcs"],
		libdir=config["TitanCNA_libdir"],
		genomeBuild=config["genomeBuild"],
		genomeStyle=config["genomeStyle"],
		cytobandFile=config["cytobandFile"],
		zoom=config["plot_zoom"],
		chrs=config["plot_chrs"],
		start=config["plot_startPos"],
		end=config["plot_endPos"],
		units=config["plot_titan_units"],
		ylim=config["plot_ylim"],
		type=config["plot_type"],
		geneFile=config["plot_geneFile"],
		size=config["plot_size"],
		format=config["plot_format"]
	log:
		"logs/plotSVABAandTITAN/{tumor}/{tumor}_CNA-SV-BX_{type}_chr{chr}.{format}.log"
	shell:
		"Rscript {params.plotSVCNscript} --id {wildcards.tumor} --svaba_funcs {params.svabafuncs} --plot_funcs {params.plotfuncs} --titan_libdir {params.libdir} --svFile {input.svabaVCF} --titanBinFile {input.titanBinFile} --titanSegFile {input.titanSegFile} --titanParamFile {input.titanParamFile} --chrs {wildcards.chr} --genomeBuild {params.genomeBuild} --genomeStyle {params.genomeStyle} --cytobandFile {params.cytobandFile} --start {params.start} --end {params.end} --zoom {params.zoom} --units {params.units} --plotYlim \"{params.ylim}\" --geneFile {params.geneFile} --plotCNAtype {params.type} --plotSize \"{params.size}\" --outPlotFile {output} > {log} 2> {log}" 


rule plotSVABAandICHOR:
	input:
		svabaVCF="results/combineSVABAandTITAN/{tumor}/{tumor}.svabaTitan.sv.txt",
		ichorBinFile=lambda wildcards: getICHORpath(wildcards.tumor, ".cna.seg"),
		ichorSegFile=lambda wildcards: getICHORpath(wildcards.tumor, ".seg.txt"),
		titanParamFile=lambda wildcards: getTITANpath(wildcards.tumor, ".params.txt")
	output:
		"results/plotSVABAandICHOR/{tumor}/{tumor}_CNA-SV-BX_{type}_chr{chr}.{format}"
	params:
		plotSVCNichor_script=config["plotSVCNichor_script"],
		svabafuncs=config["svaba_funcs"],
		plotfuncs=config["plot_funcs"],
		libdir=config["TitanCNA_libdir"],
		genomeBuild=config["genomeBuild"],
		genomeStyle=config["genomeStyle"],
		cytobandFile=config["cytobandFile"],
		zoom=config["plot_zoom"],
		chrs=config["plot_chrs"],
		start=config["plot_startPos"],
		end=config["plot_endPos"],
		units=config["plot_ichor_units"],
		ylim=config["plot_ylim"],
		type=config["plot_type"],
		geneFile=config["plot_geneFile"],
		size=config["plot_size"],
		format=config["plot_format"]
	log:
		"logs/plotSVABAandICHOR/{tumor}/{tumor}_CNA-SV-BX_{type}_chr{chr}.{format}.log"
	shell:
		"Rscript {params.plotSVCNichor_script} --id {wildcards.tumor} --svaba_funcs {params.svabafuncs} --plot_funcs {params.plotfuncs} --titan_libdir {params.libdir} --svFile {input.svabaVCF} --titanBinFile {input.ichorBinFile} --titanSegFile {input.ichorSegFile} --titanParamFile {input.titanParamFile} --chrs {wildcards.chr} --genomeBuild {params.genomeBuild} --genomeStyle {params.genomeStyle} --cytobandFile {params.cytobandFile} --start {params.start} --end {params.end} --zoom {params.zoom} --units {params.units} --plotYlim \"{params.ylim}\" --geneFile {params.geneFile} --plotCNAtype ichor --plotSize \"{params.size}\" --outPlotFile {output} > {log} 2> {log}" 



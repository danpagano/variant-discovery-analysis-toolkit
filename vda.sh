#!/bin/bash
##############################################
# Name		: vda.sh
# Version   : 0.0.1
# Author	: Dan Pagano 
# Copyright : Dan Pagano
# License   : GNU General Public License
##############################################

##############################################
# CONFIGURATION

# specify paths to modules, programs, and files to be used in this script
SCRIPT_DIR=$(readlink -f $0)
SCRIPT_DIR=${SCRIPT_DIR%/*}
export SCRIPT_DIR

source "$SCRIPT_DIR"/config.shlib
PATH_TO_GATK4="$(config_get PATH_TO_GATK4)"
PATH_TO_GATK3="$(config_get PATH_TO_GATK3)"
PATH_TO_BWA="$(config_get PATH_TO_BWA)"
PATH_TO_SAMTOOLS="$(config_get PATH_TO_SAMTOOLS)"
PATH_TO_BEDTOOLS2="$(config_get PATH_TO_BEDTOOLS2)"
PATH_TO_MANTA="$(config_get PATH_TO_MANTA)"
PATH_TO_STRELKA="$(config_get PATH_TO_STRELKA)"
PATH_TO_SNPEFF="$(config_get PATH_TO_SNPEFF)"
PATH_TO_PROVEAN="$(config_get PATH_TO_PROVEAN)"
REFERENCE_GENOME="$(config_get REFERENCE_GENOME)"
SNPEFF_DATABASE="$(config_get SNPEFF_DATABASE)"
ANNOTATIONS="$(config_get ANNOTATIONS)"
BLACKLISTED_VARIANTS="$(config_get BLACKLISTED_VARIANTS)"
LOCAL_R_PATH="$(config_get LOCAL_R_PATH)"
LOCAL_R_LIBS="$(config_get LOCAL_R_LIBS)"
LOCAL_PYTHON_PATH="$(config_get LOCAL_PYTHON_PATH)"

# check that variables defined in config file exist
if [ -z "$PATH_TO_GATK4" ] ; then echo "ERROR: config file incomplete. Need path to gatk4"; exit 1; fi
if [ -z "$PATH_TO_GATK3" ] ; then echo "ERROR: config file incomplete. Need path to gatk3"; exit 1; fi	
if [ -z "$PATH_TO_BWA" ] ; then echo "ERROR: config file incomplete. Need path to bwa"; exit 1; fi
if [ -z "$PATH_TO_SAMTOOLS" ] ; then echo "ERROR: config file incomplete. Need path to samtools"; exit 1; fi
if [ -z "$PATH_TO_BEDTOOLS2" ] ; then echo "ERROR: config file incomplete. Need path to bedtools"; exit 1; fi
if [ -z "$PATH_TO_MANTA" ] ; then echo "ERROR: config file incomplete. Need path to manta"; exit 1; fi
if [ -z "$PATH_TO_STRELKA" ] ; then echo "ERROR: config file incomplete. Need path to strelka"; exit 1; fi
if [ -z "$PATH_TO_SNPEFF" ] ; then echo "ERROR: config file incomplete. Need path to snpeff"; exit 1; fi
if [ -z "$PATH_TO_PROVEAN" ] ; then echo "ERROR: config file incomplete. Need path to provean"; exit 1; fi
if [ -z "$REFERENCE_GENOME" ] ; then echo "ERROR: config file incomplete. Need reference genome .fasta"; exit 1; fi
if [ -z "$SNPEFF_DATABASE" ] ; then echo "ERROR: config file incomplete. Need to specify a snpeff database"; exit 1; fi
if [ -z "$ANNOTATIONS" ] ; then echo "ERROR: config file incomplete. Need to specify a gtf annotation file"; exit 1; fi
if [ -z "$BLACKLISTED_VARIANTS" ] ; then echo "ERROR: config file incomplete. Need to specify a vcf file."; exit 1; fi

# if local installs of R and python exist, then add them to PATH ahead of system/root installations
if ! [ -z "$LOCAL_PYTHON_PATH" ] ; then PATH=""$LOCAL_PYTHON_PATH":$PATH"; fi
if ! [ -z "$LOCAL_R_PATH" ] ; then PATH=""$LOCAL_R_PATH":$PATH"; fi	
if ! [ -z "$LOCAL_R_LIBS" ] ; then R_LIBS=""$LOCAL_R_LIBS":$R_LIBS"; fi	

# check that variables have valid values and reset paths that end with "/"
PATH_TO_GATK4=$(echo "$PATH_TO_GATK4" | sed s'/[/]$//')
PATH_TO_GATK3=$(echo "$PATH_TO_GATK3" | sed s'/[/]$//')
PATH_TO_BWA=$(echo "$PATH_TO_BWA" | sed s'/[/]$//')
PATH_TO_SAMTOOLS=$(echo "$PATH_TO_SAMTOOLS" | sed s'/[/]$//')
PATH_TO_BEDTOOLS2=$(echo "$PATH_TO_BEDTOOLS2" | sed s'/[/]$//')
PATH_TO_MANTA=$(echo "$PATH_TO_MANTA" | sed s'/[/]$//')
PATH_TO_STRELKA=$(echo "$PATH_TO_STRELKA" | sed s'/[/]$//')
PATH_TO_SNPEFF=$(echo "$PATH_TO_SNPEFF" | sed s'/[/]$//')
PATH_TO_PROVEAN=$(echo "$PATH_TO_PROVEAN" | sed s'/[/]$//')

if [[ $(echo "$REFERENCE_GENOME" | sed 's/.*\(.....\)/\1/') != "fasta" ]] && 
   [[ $(echo "$REFERENCE_GENOME" | sed 's/.*\(..\)/\1/') != "fa" ]]
then
	echo "ERROR: Reference genome file must have a .fasta or .fa extension."
	exit 1
fi	

if [[ $(echo "$ANNOTATIONS" | sed 's/.*\(...\)/\1/') != "gtf" ]]
then
	echo "ERROR: Annotation file must have a .gtf extension."
	exit 1
fi

if [[ $(echo "$BLACKLISTED_VARIANTS" | sed 's/.*\(...\)/\1/') != "vcf" ]]
then
	echo "ERROR: Blacklisted variants file must have a .vcf extension."
	exit 1
fi

# export paths
export PATH_TO_GATK4
export PATH_TO_GATK3
export PATH_TO_BWA
export PATH_TO_SAMTOOLS
export PATH_TO_BEDTOOLS2
export PATH_TO_MANTA
export PATH_TO_STRELKA
export PATH_TO_SNPEFF
export PATH_TO_PROVEAN
export REFERENCE_GENOME
export SNPEFF_DATABASE
export ANNOTATIONS
export BLACKLISTED_VARIANTS
export PATH
export R_LIBS

# default command line configurations
SAMPLE=
FASTQ_DIR="."
RUN_MODE="resume"
MAX_CORES=8
MAX_MEM=24
PARENT_STRAIN_BACKGROUND_VARIANTS=
MAPPING_STRAIN_BACKGROUND_VARIANTS=
MAPPING_VARIANTS=
RESUME_AT_JOB=
CLEAN_UP="false"
LINKED_DE_BRUIJN_GRAPH="false"
CALCULATE_PROVEAN_SCORES="true"
ADD_WORMBASE_DATA="true"
VCF_DIR=
MIN_N=
OUTPUT_PREFIX=
TXT_DIR=
MAPPING_VARIANTS=
BACKGROUND_VARIANTS=
OUT_DIR=

# END CONFIGURATION
##############################################

USAGE="VARIANT DISCOVERY ANALYSIS TOOLKIT

DESCRIPTION
VDA-Toolkit is a package of workflows designed to process C. elegans whole genome resequencing data
and identify single-nucleotide variants (SNVs) and strutural variants (SVs).

USAGE
vda.sh <workflow> [options]

EXAMPLE
vda.sh call-background-variants [options]

WORKFLOWS
vda-unmapped				Identify variants in an unmapped sample.
vda-mapped				Identify variants in a mapped sample.
call-background-variants		Call background variants in a sample.
call-mapping-variants			Call mapping variants in a sample.
compile-background-variants		Compile background variants among samples derived from the same parent.
clean-mapping-variants			Subtract background variants from mapping variants.
in-silico-complementation		Run in-silico complementation analysis.
" 

WORKFLOW=$1

if [[ $WORKFLOW = "-h" ]] || [[ $WORKFLOW = "--help" ]]
then
	echo "$USAGE"
	exit 1
fi

if [ -z "$WORKFLOW" ]
then
	echo -e "ERROR: Need to specify a workflow \n"
	echo "$USAGE"
	exit 1
fi

if [ $WORKFLOW != "vda-unmapped" ] && 
   [ $WORKFLOW != "vda-mapped" ] && 
   [ $WORKFLOW != "call-background-variants" ] && 
   [ $WORKFLOW != "call-mapping-variants" ] && 
   [ $WORKFLOW != "compile-background-variants" ] && 
   [ $WORKFLOW != "clean-mapping-variants" ] &&    
   [ $WORKFLOW != "in-silico-complementation" ]
then
	echo -e "ERROR: Workflow "$WORKFLOW" is not a valid option. Available workflows: {vda-unmapped, vda-mapped, call-background-variants, call-mapping-variants, compile-background-variants, clean-mapping-variants, in-silico-complementation} \n"
	echo "$USAGE"
	exit 1
fi


# check getopt mode
getopt -T
if [ $? -ne 4 ]
then 
	echo "ERROR: Requires enhanced getopt, obtain new version."
	exit 1
fi

shopt -s -o nounset

# usage and configurations for vda-unmapped
if [ $WORKFLOW = "vda-unmapped" ]
then
	USAGE="VARIANT DISCOVERY ANALYSIS TOOLKIT

########################
 WORKFLOW: VDA-UNMAPPED
########################

DESCRIPTION
vda-unmapped is a workflow to identify variants in an unmapped sample. 

USAGE
vda.sh vda-unmapped -s <sample-name> -p <parent-strain-background-variants> [options]

EXAMPLE
vda.sh vda-unmapped -s YY1000 -p YY500_background_variants.vcf [options]

REQUIRED ARGUMENTS
-s, --sample-name <string>	    	Sample name. Compressed fastq files must be named in the
                                        following format: <sample-name>_L001_R1.fastq.gz,
                                        <sample-name>_L002_R1.fastq.gz, etc. for single-end reads
                                        and <sample-name>_L001_R1.fastq.gz,
                                        <sample-name>_L001_R2.fastq.gz, 
                                        <sample-name>_L002_R1.fastq.gz, 
                                        <sample-name>_L002_R2.fastq.gz, etc. for paired-end reads

-f, --fastq-directory <string> 		Path to directory containing fastq file(s). Default: [.]

-r, --run-mode <string>                 Specifies how to run the workflow. Default: resume. Possible
                                        values: {resume, resume-at, restart}. Specifying \"resume\"
                                        will pickup the workflow where it left off. Specifying
                                        \"resume-at\" requires the --resume-at-job argument, removes
                                        existing data for the specified job and all jobs that
                                        follow, and then starts the workflow at the specified job.
                                        Specifying \"restart\" removes any existing data and starts
                                        the workflow from the beginning.

-c, --max-cores <integer>		Maximum number of cores to allocate. Default: 8.

-g, --max-memory <integer>		Maximum amount of memory (in Gb) to allocate. Default: 24.

-p, --parent-strain-background-variants <string>    A vcf file containing parent strain background
                                                    variants to be subtracted. Although not
                                                    recommended, this requirement can be bypassed by
                                                    inputting the value \"unknown\".


ADVANCED ARGUMENTS
--resume-at-job <string>                Resume workflow at specified job. To be used only when the
                                        --run-mode argument is set to \"resume-at\". Default: null.
                                        Possible values: {01-FastqToSam, 02-MarkIlluminaAdapters,
                                        03-SamToFastq, 04-BwaMem, 05-MergeBamAlignment,
                                        06-MarkDuplicates, 07-HaplotypeCallerBootstrap,
                                        08-SelectVariantsBootstrap, 09-BaseRecalibrator,
                                        10-ApplyBQSR, 11-AnalyzeCovariates, 12-DetermineCoverage,
                                        13-CollectWgsMetrics, 14-HaplotypeCaller, 15-Manta,
                                        16-HaplotypeCallerMappingVariants, 17-SelectMappingVariants,
                                        18-FilterHaplotypeCallerVariants,
                                        19-SubtractBackgroundHaplotypeCallerVariants,
                                        20-SubtractBackgroundMantaVariants,
                                        21-AnnotateHaplotypeCallerVariants,
                                        22-AnnotateMantaVariants, 23-MergeVariants,
                                        24-ProveanMissenseVariants, 25-AddWormBaseData 
                                        26-HaplotypeCallerGenotypeVariants, 27-GenerateMappingPlots}

--clean-upon-completion <string>        Remove job directories after workflow completion.
                                        Default: false. Possible values: {true, false}

--linked-de-bruijn-graph <string>       Run HaplotypeCaller in new EXPERIMENTAL assembly mode which
                                        improves phasing, reduces false positives, improves calling
                                        at complex sites, and has 15-20% speedup vs the current
                                        assembler. Default: false. Possible values: {true, false} 

--calculate-provean-scores <string>     Annotate missense variants and indels as deleterious or
                                        neutral using PROVEAN (Protein Variation Effect Analyzer).
                                        Default: true. Possible values: {true, false}   

--add-wormbase-data <string>            Identify similar variants. Add gene descriptions, associated
                                        phenotypes, and human orthologs. Default: true. Possible
                                        values: {true, false}

-h, --help                              Gives this help message.
" 

	SCRIPT="vda.sh vda-unmapped"
	OPTSTRING="s:f:r:c:g:p:Vh"
	LOPTSTRING="sample-name:,fastq-directory:,run-mode:,max-cores:,max-memory:,parent-strain-background-variants:,resume-at-job:,clean-upon-completion:,linked-de-bruijn-graph:,calculate-provean-scores:,add-wormbase-data:,verbose,help"

	RESULT=$(getopt -n "$SCRIPT" -o "$OPTSTRING" -l "$LOPTSTRING" -- "$@")
	if [ $? -ne 0 ]
	then
		# parsing error, show usage
		echo "$USAGE" 
		exit 1
	fi

	eval set -- "$RESULT"
	while [ true ] ; do
		case "$1" in
			-s|--sample-name) 
				shift 
				SAMPLE="$1"
			;;
			-f|--fastq-directory)
				shift
				FASTQ_DIR="$1"
			;;
			-r|--run-mode)
				shift
				RUN_MODE="$1"
			;;
			-c|--max-cores)
				shift
				MAX_CORES="$1"
			;;	
			-g|--max-memory)
				shift
				MAX_MEM="$1"
			;;
			-p|--parent-strain-background-variants)
				shift
				PARENT_STRAIN_BACKGROUND_VARIANTS="$1"
			;;
			--resume-at-job)
				shift
				RESUME_AT_JOB="$1"
			;;				
			--clean-upon-completion)
				shift
				CLEAN_UP="$1"			
			;;
			--linked-de-bruijn-graph)
				shift
				LINKED_DE_BRUIJN_GRAPH="$1"			
			;;
			--calculate-provean-scores)
				shift
				CALCULATE_PROVEAN_SCORES="$1"			
			;;
			--add-wormbase-data)
				shift
				ADD_WORMBASE_DATA="$1"			
			;;
			-h|--help)
				echo "$USAGE"
				exit 0
			;;
			--)
				shift
				break
			;;
		esac
		shift
	done

	# check that sample name agrument has been set
	if [ -z "$SAMPLE" ]
	then
		echo -e "ERROR: Need to specify sample name \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that run mode agrument has been set to resume, resume-at, or restart
	if [ $RUN_MODE != "resume" ] && 
	   [ $RUN_MODE != "resume-at" ] && 
	   [ $RUN_MODE != "restart" ]
	then
		echo -e "ERROR: --run-mode was given the value "$RUN_MODE". Possible values: {resume, resume-at, restart} \n"
		echo "$USAGE"
		exit 1
	fi

	# if run mode agrument is set to resume-at, check that --resume-at-job agrument is set to a valid job directory
	if [ $RUN_MODE = "resume-at" ] &&
	   [ $RESUME_AT_JOB != "01-FastqToSam" ] &&
	   [ $RESUME_AT_JOB != "02-MarkIlluminaAdapters" ] &&
	   [ $RESUME_AT_JOB != "03-SamToFastq" ] &&
	   [ $RESUME_AT_JOB != "04-BwaMem" ] &&
	   [ $RESUME_AT_JOB != "05-MergeBamAlignment" ] &&
	   [ $RESUME_AT_JOB != "06-MarkDuplicates" ] &&
	   [ $RESUME_AT_JOB != "07-HaplotypeCallerBootstrap" ] &&
	   [ $RESUME_AT_JOB != "08-SelectVariantsBootstrap" ] &&
	   [ $RESUME_AT_JOB != "09-BaseRecalibrator" ] &&
	   [ $RESUME_AT_JOB != "10-ApplyBQSR" ] &&
	   [ $RESUME_AT_JOB != "11-AnalyzeCovariates" ] &&
	   [ $RESUME_AT_JOB != "12-DetermineCoverage" ] &&
	   [ $RESUME_AT_JOB != "13-CollectWgsMetrics" ] &&
	   [ $RESUME_AT_JOB != "14-HaplotypeCaller" ] &&
	   [ $RESUME_AT_JOB != "15-Manta" ] &&
	   [ $RESUME_AT_JOB != "16-HaplotypeCallerMappingVariants" ] &&
	   [ $RESUME_AT_JOB != "17-SelectMappingVariants" ] &&
	   [ $RESUME_AT_JOB != "18-FilterHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "19-SubtractBackgroundHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "20-SubtractBackgroundMantaVariants" ] &&
	   [ $RESUME_AT_JOB != "21-AnnotateHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "22-AnnotateMantaVariants" ] &&
	   [ $RESUME_AT_JOB != "23-MergeVariants" ] &&
	   [ $RESUME_AT_JOB != "24-ProveanMissenseVariants" ] &&
	   [ $RESUME_AT_JOB != "25-AddWormBaseData" ] &&
	   [ $RESUME_AT_JOB != "26-HaplotypeCallerGenotypeVariants" ] &&
	   [ $RESUME_AT_JOB != "27-GenerateMappingPlots" ]
	then
	   	echo -e "ERROR: --resume-at-job was given the value "$RESUME_AT_JOB". Possible values: {01-FastqToSam, 02-MarkIlluminaAdapters, 03-SamToFastq, 04-BwaMem, 05-MergeBamAlignment, 06-MarkDuplicates, 07-HaplotypeCallerBootstrap, 08-SelectVariantsBootstrap, 09-BaseRecalibrator, 10-ApplyBQSR, 11-AnalyzeCovariates, 12-DetermineCoverage, 13-CollectWgsMetrics, 14-HaplotypeCaller, 15-Manta, 16-HaplotypeCallerMappingVariants, 17-SelectMappingVariants, 18-FilterHaplotypeCallerVariants, 19-SubtractBackgroundHaplotypeCallerVariants, 20-SubtractBackgroundMantaVariants, 21-AnnotateHaplotypeCallerVariants, 22-AnnotateMantaVariants, 23-MergeVariants, 24-ProveanMissenseVariants, 25-AddWormBaseData 26-HaplotypeCallerGenotypeVariants, 27-GenerateMappingPlots} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that clean up agrument is set to true or false
	if [ $CLEAN_UP != "true" ] && 
	   [ $CLEAN_UP != "false" ]
	then
		echo -e "ERROR: --clean-upon-completion was given the value "$CLEAN_UP". Possible values: {true, false} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that linked de bruijn graph agrument is set to true or false
	if [ $LINKED_DE_BRUIJN_GRAPH != "true" ] && 
	   [ $LINKED_DE_BRUIJN_GRAPH != "false" ]
	then
		echo -e "ERROR: --linked-de-bruijn-graph was given the value "$LINKED_DE_BRUIJN_GRAPH". Possible values: {true, false} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that calculate provean scores agrument is set to true or false
	if [ $CALCULATE_PROVEAN_SCORES != "true" ] && 
	   [ $CALCULATE_PROVEAN_SCORES != "false" ]
	then
		echo -e "ERROR: --calculate-provean-scores was given the value "$CALCULATE_PROVEAN_SCORES". Possible values: {true, false} \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that add wormbase data agrument is set to true or false
	if [ $ADD_WORMBASE_DATA != "true" ] && 
	   [ $ADD_WORMBASE_DATA != "false" ]
	then
		echo -e "ERROR: --add-wormbase-data was given the value "$ADD_WORMBASE_DATA". Possible values: {true, false} \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that parent strain background variants agrument has been set appropriately
	if [[ $(echo "$PARENT_STRAIN_BACKGROUND_VARIANTS" | sed 's/.*\(...\)/\1/') != "vcf" ]] && 
	   [[ $PARENT_STRAIN_BACKGROUND_VARIANTS != "unknown" ]]
	then
		echo -e "ERROR: --parent-strain-background-variants was given an unsupported value. Possible values: {*.vcf, unknown} \n"
		echo "$USAGE"
		exit 1
	fi

	# if parent strain background variants agrument is set to unknown, then adjust variable accordingly
	if [[ $PARENT_STRAIN_BACKGROUND_VARIANTS = "unknown" ]]
	then
		PARENT_STRAIN_BACKGROUND_VARIANTS="$SCRIPT_DIR"/variants/background/nothing.vcf
	fi

	# reset relative paths to full paths
	PARENT_STRAIN_BACKGROUND_VARIANTS=$(readlink -f $PARENT_STRAIN_BACKGROUND_VARIANTS)

	# reset fastq directory path if it ends with "/"
	FASTQ_DIR=$(echo "$FASTQ_DIR" | sed s'/[/]$//')

	COMMAND=""$SCRIPT_DIR"/scripts/variant_discovery_analysis.sh"

	export WORKFLOW
	export SAMPLE
	export FASTQ_DIR
	export RUN_MODE
	export MAX_CORES
	export MAX_MEM
	export PARENT_STRAIN_BACKGROUND_VARIANTS
	export RESUME_AT_JOB
	export CLEAN_UP
	export LINKED_DE_BRUIJN_GRAPH
	export CALCULATE_PROVEAN_SCORES
	export ADD_WORMBASE_DATA

	#run command
	sbatch "$COMMAND"

	STATUS=$?

	exit $STATUS
fi


# usage and configurations for vda-mapped
if [ $WORKFLOW = "vda-mapped" ]
then
	USAGE="VARIANT DISCOVERY ANALYSIS TOOLKIT

########################
  WORKFLOW: VDA-MAPPED
########################

DESCRIPTION
vda-mapped is a workflow to identify variants in a mapped sample and generate mapping plots.

USAGE
vda.sh vda-mapped -s <sample-name> -p <parent-strain-background-variants> 
-m <mapping-strain-background-variants> -x <mapping-variants> [options]

EXAMPLE
vda.sh vda-mapped -s YY1000 -p YY500_background_variants.vcf -m HW_background_variants.vcf 
-x HW_mapping_variants.vcf [options]

REQUIRED ARGUMENTS
-s, --sample-name <string>	    	Sample name. Compressed fastq files must be named in the
                                        following format: <sample-name>_L001_R1.fastq.gz,
                                        <sample-name>_L002_R1.fastq.gz, etc. for single-end reads
                                        and <sample-name>_L001_R1.fastq.gz,
                                        <sample-name>_L001_R2.fastq.gz, 
                                        <sample-name>_L002_R1.fastq.gz, 
                                        <sample-name>_L002_R2.fastq.gz, etc. for paired-end reads

-f, --fastq-directory <string> 		Path to directory containing fastq file(s). Default: [.]

-r, --run-mode <string>                 Specifies how to run the workflow. Default: resume. Possible
                                        values: {resume, resume-at, restart}. Specifying \"resume\"
                                        will pickup the workflow where it left off. Specifying
                                        \"resume-at\" requires the --resume-at-job argument, removes
                                        existing data for the specified job and all jobs that
                                        follow, and then starts the workflow at the specified job.
                                        Specifying \"restart\" removes any existing data and starts
                                        the workflow from the beginning.

-c, --max-cores <integer>		Maximum number of cores to allocate. Default: 8.

-g, --max-memory <integer>		Maximum amount of memory (in Gb) to allocate. Default: 24.

-p, --parent-strain-background-variants <string>    A vcf file containing parent strain background
                                                    variants to be subtracted. Although not
                                                    recommended, this requirement can be bypassed by
                                                    inputting the value \"unknown\".

-m, --mapping-strain-background-variants <string>   A vcf file containing mapping strain background
                                                    variants to be subtracted. Although not
                                                    recommended, this requirement can be bypassed by
                                                    inputting the value \"unknown\".

-x, --mapping-variants <string>                     A vcf file containing mapping variants to be
                                                    genotyped.


ADVANCED ARGUMENTS
--resume-at-job <string>                Resume workflow at specified job. To be used only when the
                                        --run-mode argument is set to \"resume-at\". Default: null.
                                        Possible values: {01-FastqToSam, 02-MarkIlluminaAdapters,
                                        03-SamToFastq, 04-BwaMem, 05-MergeBamAlignment,
                                        06-MarkDuplicates, 07-HaplotypeCallerBootstrap,
                                        08-SelectVariantsBootstrap, 09-BaseRecalibrator,
                                        10-ApplyBQSR, 11-AnalyzeCovariates, 12-DetermineCoverage,
                                        13-CollectWgsMetrics, 14-HaplotypeCaller, 15-Manta,
                                        16-HaplotypeCallerMappingVariants, 17-SelectMappingVariants,
                                        18-FilterHaplotypeCallerVariants,
                                        19-SubtractBackgroundHaplotypeCallerVariants,
                                        20-SubtractBackgroundMantaVariants,
                                        21-AnnotateHaplotypeCallerVariants,
                                        22-AnnotateMantaVariants, 23-MergeVariants,
                                        24-ProveanMissenseVariants, 25-AddWormBaseData
                                        26-HaplotypeCallerGenotypeVariants, 27-GenerateMappingPlots}

--clean-upon-completion <string>        Remove job directories after workflow completion.
                                        Default: false. Possible values: {true, false}

--linked-de-bruijn-graph <string>       Run HaplotypeCaller in new EXPERIMENTAL assembly mode which
                                        improves phasing, reduces false positives, improves calling
                                        at complex sites, and has 15-20% speedup vs the current
                                        assembler. Default: false. Possible values: {true, false} 

--calculate-provean-scores <string>     Annotate missense variants and indels as deleterious or
                                        neutral using PROVEAN (Protein Variation Effect Analyzer).
                                        Default: true. Possible values: {true, false}   

--add-wormbase-data <string>            Identify similar variants. Add gene descriptions, associated
                                        phenotypes, and human orthologs. Default: true. Possible
                                        values: {true, false}

-h, --help                              Gives this help message.
" 

	SCRIPT="vda.sh vda-mapped"
	OPTSTRING="s:f:r:c:g:p:m:x:Vh"
	LOPTSTRING="sample-name:,fastq-directory:,run-mode:,max-cores:,max-memory:,parent-strain-background-variants:,mapping-strain-background-variants:,mapping-variants:,resume-at-job:,clean-upon-completion:,linked-de-bruijn-graph:,calculate-provean-scores:,add-wormbase-data:,verbose,help"

	RESULT=$(getopt -n "$SCRIPT" -o "$OPTSTRING" -l "$LOPTSTRING" -- "$@")
	if [ $? -ne 0 ]
	then
		# parsing error, show usage
		echo "$USAGE" 
		exit 1
	fi

	eval set -- "$RESULT"
	while [ true ] ; do
		case "$1" in
			-s|--sample-name) 
				shift 
				SAMPLE="$1"
			;;
			-f|--fastq-directory)
				shift
				FASTQ_DIR="$1"
			;;
			-r|--run-mode)
				shift
				RUN_MODE="$1"
			;;
			-c|--max-cores)
				shift
				MAX_CORES="$1"
			;;	
			-g|--max-memory)
				shift
				MAX_MEM="$1"
			;;
			-p|--parent-strain-background-variants)
				shift
				PARENT_STRAIN_BACKGROUND_VARIANTS="$1"
			;;
			-m|--mapping-strain-background-variants:)
				shift
				MAPPING_STRAIN_BACKGROUND_VARIANTS="$1"
			;;
			-x|--mapping-variants)
				shift
				MAPPING_VARIANTS="$1"
			;;			
			--resume-at-job)
				shift
				RESUME_AT_JOB="$1"
			;;				
			--clean-upon-completion)
				shift
				CLEAN_UP="$1"			
			;;
			--linked-de-bruijn-graph)
				shift
				LINKED_DE_BRUIJN_GRAPH="$1"			
			;;
			--calculate-provean-scores)
				shift
				CALCULATE_PROVEAN_SCORES="$1"			
			;;
			--add-wormbase-data)
				shift
				ADD_WORMBASE_DATA="$1"			
			;;
			-h|--help)
				echo "$USAGE"
				exit 0
			;;
			--)
				shift
				break
			;;
		esac
		shift
	done

	# check that sample name agrument has been set
	if [ -z "$SAMPLE" ]
	then
		echo -e "ERROR: Need to specify sample name \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that run mode agrument has been set to resume, resume-at, or restart
	if [ $RUN_MODE != "resume" ] && 
	   [ $RUN_MODE != "resume-at" ] && 
	   [ $RUN_MODE != "restart" ]
	then
		echo -e "ERROR: --run-mode was given the value "$RUN_MODE". Possible values: {resume, resume-at, restart} \n"
		echo "$USAGE"
		exit 1
	fi

	# if run mode agrument is set to resume-at, check that --resume-at-job agrument is set to a valid job directory
	if [ $RUN_MODE = "resume-at" ] &&
	   [ $RESUME_AT_JOB != "01-FastqToSam" ] &&
	   [ $RESUME_AT_JOB != "02-MarkIlluminaAdapters" ] &&
	   [ $RESUME_AT_JOB != "03-SamToFastq" ] &&
	   [ $RESUME_AT_JOB != "04-BwaMem" ] &&
	   [ $RESUME_AT_JOB != "05-MergeBamAlignment" ] &&
	   [ $RESUME_AT_JOB != "06-MarkDuplicates" ] &&
	   [ $RESUME_AT_JOB != "07-HaplotypeCallerBootstrap" ] &&
	   [ $RESUME_AT_JOB != "08-SelectVariantsBootstrap" ] &&
	   [ $RESUME_AT_JOB != "09-BaseRecalibrator" ] &&
	   [ $RESUME_AT_JOB != "10-ApplyBQSR" ] &&
	   [ $RESUME_AT_JOB != "11-AnalyzeCovariates" ] &&
	   [ $RESUME_AT_JOB != "12-DetermineCoverage" ] &&
	   [ $RESUME_AT_JOB != "13-CollectWgsMetrics" ] &&
	   [ $RESUME_AT_JOB != "14-HaplotypeCaller" ] &&
	   [ $RESUME_AT_JOB != "15-Manta" ] &&
	   [ $RESUME_AT_JOB != "16-HaplotypeCallerMappingVariants" ] &&
	   [ $RESUME_AT_JOB != "17-SelectMappingVariants" ] &&
	   [ $RESUME_AT_JOB != "18-FilterHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "19-SubtractBackgroundHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "20-SubtractBackgroundMantaVariants" ] &&
	   [ $RESUME_AT_JOB != "21-AnnotateHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "22-AnnotateMantaVariants" ] &&
	   [ $RESUME_AT_JOB != "23-MergeVariants" ] &&
	   [ $RESUME_AT_JOB != "24-ProveanMissenseVariants" ] &&
	   [ $RESUME_AT_JOB != "25-AddWormBaseData" ] &&
	   [ $RESUME_AT_JOB != "26-HaplotypeCallerGenotypeVariants" ] &&
	   [ $RESUME_AT_JOB != "27-GenerateMappingPlots" ]
	then
	   	echo -e "ERROR: --resume-at-job was given the value "$RESUME_AT_JOB". Possible values: {01-FastqToSam, 02-MarkIlluminaAdapters, 03-SamToFastq, 04-BwaMem, 05-MergeBamAlignment, 06-MarkDuplicates, 07-HaplotypeCallerBootstrap, 08-SelectVariantsBootstrap, 09-BaseRecalibrator, 10-ApplyBQSR, 11-AnalyzeCovariates, 12-DetermineCoverage, 13-CollectWgsMetrics, 14-HaplotypeCaller, 15-Manta, 16-HaplotypeCallerMappingVariants, 17-SelectMappingVariants, 18-FilterHaplotypeCallerVariants, 19-SubtractBackgroundHaplotypeCallerVariants, 20-SubtractBackgroundMantaVariants, 21-AnnotateHaplotypeCallerVariants, 22-AnnotateMantaVariants, 23-MergeVariants, 24-ProveanMissenseVariants, 25-AddWormBaseData 26-HaplotypeCallerGenotypeVariants, 27-GenerateMappingPlots} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that clean up agrument is set to true or false
	if [ $CLEAN_UP != "true" ] && 
	   [ $CLEAN_UP != "false" ]
	then
		echo -e "ERROR: --clean-upon-completion was given the value "$CLEAN_UP". Possible values: {true, false} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that linked de bruijn graph agrument is set to true or false
	if [ $LINKED_DE_BRUIJN_GRAPH != "true" ] && 
	   [ $LINKED_DE_BRUIJN_GRAPH != "false" ]
	then
		echo -e "ERROR: --linked-de-bruijn-graph was given the value "$LINKED_DE_BRUIJN_GRAPH". Possible values: {true, false} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that calculate provean scores agrument is set to true or false
	if [ $CALCULATE_PROVEAN_SCORES != "true" ] && 
	   [ $CALCULATE_PROVEAN_SCORES != "false" ]
	then
		echo -e "ERROR: --calculate-provean-scores was given the value "$CALCULATE_PROVEAN_SCORES". Possible values: {true, false} \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that add wormbase data agrument is set to true or false
	if [ $ADD_WORMBASE_DATA != "true" ] && 
	   [ $ADD_WORMBASE_DATA != "false" ]
	then
		echo -e "ERROR: --add-wormbase-data was given the value "$ADD_WORMBASE_DATA". Possible values: {true, false} \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that parent strain background variants agrument has been set appropriately
	if [[ $(echo "$PARENT_STRAIN_BACKGROUND_VARIANTS" | sed 's/.*\(...\)/\1/') != "vcf" ]] && 
	   [[ $PARENT_STRAIN_BACKGROUND_VARIANTS != "unknown" ]]
	then
		echo -e "ERROR: --parent-strain-background-variants was given an unsupported value. Possible values: {*.vcf, unknown} \n"
		echo "$USAGE"
		exit 1
	fi

	# if parent strain background variants agrument is set to unknown, then adjust variable accordingly
	if [[ $PARENT_STRAIN_BACKGROUND_VARIANTS = "unknown" ]]
	then
		PARENT_STRAIN_BACKGROUND_VARIANTS="$SCRIPT_DIR"/variants/background/nothing.vcf
	fi

	# check that mapping strain background variants agrument has been set appropriately
	if [[ $(echo "$MAPPING_STRAIN_BACKGROUND_VARIANTS" | sed 's/.*\(...\)/\1/') != "vcf" ]] && 
	   [[ $MAPPING_STRAIN_BACKGROUND_VARIANTS != "unknown" ]]
	then
		echo -e "ERROR: --mapping-strain-background-variants was given an unsupported value. Possible values: {*.vcf, unknown} \n"
		echo "$USAGE"
		exit 1
	fi

	# if parent mapping background variants agrument is set to unknown, then adjust variable accordingly
	if [[ $MAPPING_STRAIN_BACKGROUND_VARIANTS = "unknown" ]]
	then
		MAPPING_STRAIN_BACKGROUND_VARIANTS="$MAPPING_VARIANTS"
	fi

	# check that mapping variants agrument is a vcf file
	if [[ $(echo "$MAPPING_VARIANTS" | sed 's/.*\(...\)/\1/') != "vcf" ]]
	then
		echo -e "ERROR: --mapping-variants was given an unsupported value. Possible values: {*.vcf} \n"
		echo "$USAGE"
		exit 1
	fi

	# reset relative paths to full paths
	PARENT_STRAIN_BACKGROUND_VARIANTS=$(readlink -f $PARENT_STRAIN_BACKGROUND_VARIANTS)
	MAPPING_STRAIN_BACKGROUND_VARIANTS=$(readlink -f $MAPPING_STRAIN_BACKGROUND_VARIANTS)
	MAPPING_VARIANTS=$(readlink -f $MAPPING_VARIANTS)

	# reset fastq directory path if it ends with "/"
	FASTQ_DIR=$(echo "$FASTQ_DIR" | sed s'/[/]$//')

	COMMAND=""$SCRIPT_DIR"/scripts/variant_discovery_analysis.sh"

	export WORKFLOW
	export SAMPLE
	export FASTQ_DIR
	export RUN_MODE
	export MAX_CORES
	export MAX_MEM
	export PARENT_STRAIN_BACKGROUND_VARIANTS
	export MAPPING_STRAIN_BACKGROUND_VARIANTS
	export MAPPING_VARIANTS
	export RESUME_AT_JOB
	export CLEAN_UP
	export LINKED_DE_BRUIJN_GRAPH
	export CALCULATE_PROVEAN_SCORES
	export ADD_WORMBASE_DATA

	#run command
	sbatch "$COMMAND"

	STATUS=$?

	exit $STATUS
fi


# usage and configurations for call-background-variants
if [ $WORKFLOW = "call-background-variants" ]
then
	USAGE="VARIANT DISCOVERY ANALYSIS TOOLKIT

####################################
 WORKFLOW: CALL-BACKGROUND-VARIANTS
####################################

DESCRIPTION
call-background-variants is a workflow to identify background variants in a sample. 

USAGE
vda.sh call-background-variants -s <sample-name> [options]

EXAMPLE
vda.sh call-background-variants -s YY1000 [options]

REQUIRED ARGUMENTS
-s, --sample-name <string>	    	Sample name. Compressed fastq files must be named in the
                                        following format: <sample-name>_L001_R1.fastq.gz,
                                        <sample-name>_L002_R1.fastq.gz, etc. for single-end reads
                                        and <sample-name>_L001_R1.fastq.gz,
                                        <sample-name>_L001_R2.fastq.gz, 
                                        <sample-name>_L002_R1.fastq.gz, 
                                        <sample-name>_L002_R2.fastq.gz, etc. for paired-end reads

-f, --fastq-directory <string> 		Path to directory containing fastq file(s). Default: [.]

-r, --run-mode <string>                 Specifies how to run the workflow. Default: resume. Possible
                                        values: {resume, resume-at, restart}. Specifying \"resume\"
                                        will pickup the workflow where it left off. Specifying
                                        \"resume-at\" requires the --resume-at-job argument, removes
                                        existing data for the specified job and all jobs that
                                        follow, and then starts the workflow at the specified job.
                                        Specifying \"restart\" removes any existing data and starts
                                        the workflow from the beginning.

-c, --max-cores <integer>		Maximum number of cores to allocate. Default: 8.

-g, --max-memory <integer>		Maximum amount of memory (in Gb) to allocate. Default: 24.

-b, --background-directory <string>     Specifies where to copy *_background_all_variants.vcf
                                        Default: "$SCRIPT_DIR"/variants/background


ADVANCED ARGUMENTS
--resume-at-job <string>                Resume workflow at specified job. To be used only when the
                                        --run-mode argument is set to \"resume-at\". Default: null.
                                        Possible values: {01-FastqToSam, 02-MarkIlluminaAdapters,
                                        03-SamToFastq, 04-BwaMem, 05-MergeBamAlignment,
                                        06-MarkDuplicates, 07-HaplotypeCallerBootstrap,
                                        08-SelectVariantsBootstrap, 09-BaseRecalibrator,
                                        10-ApplyBQSR, 11-AnalyzeCovariates, 12-DetermineCoverage,
                                        13-CollectWgsMetrics, 14-HaplotypeCaller, 15-Manta,
                                        16-HaplotypeCallerMappingVariants, 17-SelectMappingVariants,
                                        18-FilterHaplotypeCallerVariants,
                                        19-SubtractBackgroundHaplotypeCallerVariants,
                                        20-SubtractBackgroundMantaVariants,
                                        21-AnnotateHaplotypeCallerVariants,
                                        22-AnnotateMantaVariants, 23-MergeVariants,
                                        24-ProveanMissenseVariants, 25-AddWormBaseData
                                        26-HaplotypeCallerGenotypeVariants, 27-GenerateMappingPlots}

--clean-upon-completion <string>        Remove job directories after workflow completion.
                                        Default: false. Possible values: {true, false}

--linked-de-bruijn-graph <string>       Run HaplotypeCaller in new EXPERIMENTAL assembly mode which
                                        improves phasing, reduces false positives, improves calling
                                        at complex sites, and has 15-20% speedup vs the current
                                        assembler. Default: false. Possible values: {true, false} 

-h, --help                              Gives this help message.
" 
	
	BACKGROUND_DIRECTORY="$SCRIPT_DIR"/variants/background

	SCRIPT="vda.sh call-background-variants"
	OPTSTRING="s:f:r:c:g:b:Vh"
	LOPTSTRING="sample-name:,fastq-directory:,run-mode:,max-cores:,max-memory:,background-directory:,resume-at-job:,clean-upon-completion:,linked-de-bruijn-graph:,verbose,help"

	RESULT=$(getopt -n "$SCRIPT" -o "$OPTSTRING" -l "$LOPTSTRING" -- "$@")
	if [ $? -ne 0 ]
	then
		# parsing error, show usage
		echo "$USAGE" 
		exit 1
	fi

	eval set -- "$RESULT"
	while [ true ] ; do
		case "$1" in
			-s|--sample-name) 
				shift 
				SAMPLE="$1"
			;;
			-f|--fastq-directory)
				shift
				FASTQ_DIR="$1"
			;;
			-r|--run-mode)
				shift
				RUN_MODE="$1"
			;;
			-c|--max-cores)
				shift
				MAX_CORES="$1"
			;;	
			-g|--max-memory)
				shift
				MAX_MEM="$1"
			;;
			-b|--background-directory)
				shift
				BACKGROUND_DIRECTORY="$1"
			;;
			--resume-at-job)
				shift
				RESUME_AT_JOB="$1"
			;;				
			--clean-upon-completion)
				shift
				CLEAN_UP="$1"			
			;;
			--linked-de-bruijn-graph)
				shift
				LINKED_DE_BRUIJN_GRAPH="$1"			
			;;
			-h|--help)
				echo "$USAGE"
				exit 0
			;;
			--)
				shift
				break
			;;
		esac
		shift
	done

	# check that sample name agrument has been set
	if [ -z "$SAMPLE" ]
	then
		echo -e "ERROR: Need to specify sample name \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that run mode agrument has been set to resume, resume-at, or restart
	if [ $RUN_MODE != "resume" ] && 
	   [ $RUN_MODE != "resume-at" ] && 
	   [ $RUN_MODE != "restart" ]
	then
		echo -e "ERROR: --run-mode was given the value "$RUN_MODE". Possible values: {resume, resume-at, restart} \n"
		echo "$USAGE"
		exit 1
	fi

	# if run mode agrument is set to resume-at, check that --resume-at-job agrument is set to a valid job directory
	if [ $RUN_MODE = "resume-at" ] &&
	   [ $RESUME_AT_JOB != "01-FastqToSam" ] &&
	   [ $RESUME_AT_JOB != "02-MarkIlluminaAdapters" ] &&
	   [ $RESUME_AT_JOB != "03-SamToFastq" ] &&
	   [ $RESUME_AT_JOB != "04-BwaMem" ] &&
	   [ $RESUME_AT_JOB != "05-MergeBamAlignment" ] &&
	   [ $RESUME_AT_JOB != "06-MarkDuplicates" ] &&
	   [ $RESUME_AT_JOB != "07-HaplotypeCallerBootstrap" ] &&
	   [ $RESUME_AT_JOB != "08-SelectVariantsBootstrap" ] &&
	   [ $RESUME_AT_JOB != "09-BaseRecalibrator" ] &&
	   [ $RESUME_AT_JOB != "10-ApplyBQSR" ] &&
	   [ $RESUME_AT_JOB != "11-AnalyzeCovariates" ] &&
	   [ $RESUME_AT_JOB != "12-DetermineCoverage" ] &&
	   [ $RESUME_AT_JOB != "13-CollectWgsMetrics" ] &&
	   [ $RESUME_AT_JOB != "14-HaplotypeCaller" ] &&
	   [ $RESUME_AT_JOB != "15-Manta" ] &&
	   [ $RESUME_AT_JOB != "16-HaplotypeCallerMappingVariants" ] &&
	   [ $RESUME_AT_JOB != "17-SelectMappingVariants" ] &&
	   [ $RESUME_AT_JOB != "18-FilterHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "19-SubtractBackgroundHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "20-SubtractBackgroundMantaVariants" ] &&
	   [ $RESUME_AT_JOB != "21-AnnotateHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "22-AnnotateMantaVariants" ] &&
	   [ $RESUME_AT_JOB != "23-MergeVariants" ] &&
	   [ $RESUME_AT_JOB != "24-ProveanMissenseVariants" ] &&
	   [ $RESUME_AT_JOB != "25-AddWormBaseData" ] &&
	   [ $RESUME_AT_JOB != "26-HaplotypeCallerGenotypeVariants" ] &&
	   [ $RESUME_AT_JOB != "27-GenerateMappingPlots" ]
	then
	   	echo -e "ERROR: --resume-at-job was given the value "$RESUME_AT_JOB". Possible values: {01-FastqToSam, 02-MarkIlluminaAdapters, 03-SamToFastq, 04-BwaMem, 05-MergeBamAlignment, 06-MarkDuplicates, 07-HaplotypeCallerBootstrap, 08-SelectVariantsBootstrap, 09-BaseRecalibrator, 10-ApplyBQSR, 11-AnalyzeCovariates, 12-DetermineCoverage, 13-CollectWgsMetrics, 14-HaplotypeCaller, 15-Manta, 16-HaplotypeCallerMappingVariants, 17-SelectMappingVariants, 18-FilterHaplotypeCallerVariants, 19-SubtractBackgroundHaplotypeCallerVariants, 20-SubtractBackgroundMantaVariants, 21-AnnotateHaplotypeCallerVariants, 22-AnnotateMantaVariants, 23-MergeVariants, 24-ProveanMissenseVariants, 25-AddWormBaseData 26-HaplotypeCallerGenotypeVariants, 27-GenerateMappingPlots} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that clean up agrument is set to true or false
	if [ $CLEAN_UP != "true" ] && 
	   [ $CLEAN_UP != "false" ]
	then
		echo -e "ERROR: --clean-upon-completion was given the value "$CLEAN_UP". Possible values: {true, false} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that linked de bruijn graph agrument is set to true or false
	if [ $LINKED_DE_BRUIJN_GRAPH != "true" ] && 
	   [ $LINKED_DE_BRUIJN_GRAPH != "false" ]
	then
		echo -e "ERROR: --linked-de-bruijn-graph was given the value "$LINKED_DE_BRUIJN_GRAPH". Possible values: {true, false} \n"
		echo "$USAGE"
		exit 1
	fi

	# reset background directory path if it ends with "/"
	BACKGROUND_DIRECTORY=$(echo "$BACKGROUND_DIRECTORY" | sed s'/[/]$//')

	# reset fastq directory path if it ends with "/"
	FASTQ_DIR=$(echo "$FASTQ_DIR" | sed s'/[/]$//')

	COMMAND=""$SCRIPT_DIR"/scripts/variant_discovery_analysis.sh"

	export WORKFLOW
	export SAMPLE
	export FASTQ_DIR
	export RUN_MODE
	export MAX_CORES
	export MAX_MEM
	export BACKGROUND_DIRECTORY
	export RESUME_AT_JOB
	export CLEAN_UP
	export LINKED_DE_BRUIJN_GRAPH

	#run command
	sbatch "$COMMAND"

	STATUS=$?

	exit $STATUS
fi


# usage and configurations for call-mapping-variants
if [ $WORKFLOW = "call-mapping-variants" ]
then
	USAGE="VARIANT DISCOVERY ANALYSIS TOOLKIT

####################################
 WORKFLOW: CALL-MAPPING-VARIANTS
####################################

DESCRIPTION
call-mapping-variants is a workflow to identify both background and mapping variants in a sample. 

USAGE
vda.sh call-mapping-variants -s <sample-name> [options]

EXAMPLE
vda.sh call-mapping-variants -s YY1000 [options]

REQUIRED ARGUMENTS
-s, --sample-name <string>	    	Sample name. Compressed fastq files must be named in the
                                        following format: <sample-name>_L001_R1.fastq.gz,
                                        <sample-name>_L002_R1.fastq.gz, etc. for single-end reads
                                        and <sample-name>_L001_R1.fastq.gz,
                                        <sample-name>_L001_R2.fastq.gz, 
                                        <sample-name>_L002_R1.fastq.gz, 
                                        <sample-name>_L002_R2.fastq.gz, etc. for paired-end reads

-f, --fastq-directory <string> 		Path to directory containing fastq file(s). Default: [.]

-r, --run-mode <string>                 Specifies how to run the workflow. Default: resume. Possible
                                        values: {resume, resume-at, restart}. Specifying \"resume\"
                                        will pickup the workflow where it left off. Specifying
                                        \"resume-at\" requires the --resume-at-job argument, removes
                                        existing data for the specified job and all jobs that
                                        follow, and then starts the workflow at the specified job.
                                        Specifying \"restart\" removes any existing data and starts
                                        the workflow from the beginning.

-c, --max-cores <integer>		Maximum number of cores to allocate. Default: 8.

-g, --max-memory <integer>		Maximum amount of memory (in Gb) to allocate. Default: 24.

-b, --background-directory <string>     Specifies where to copy *_background_all_variants.vcf
                                        Default: "$SCRIPT_DIR"/variants/background

-m, --mapping-directory <string>     	Specifies where to copy *_homozygous_mapping_variants.vcf
                                        Default: "$SCRIPT_DIR"/variants/mapping


ADVANCED ARGUMENTS
--resume-at-job <string>                Resume workflow at specified job. To be used only when the
                                        --run-mode argument is set to \"resume-at\". Default: null.
                                        Possible values: {01-FastqToSam, 02-MarkIlluminaAdapters,
                                        03-SamToFastq, 04-BwaMem, 05-MergeBamAlignment,
                                        06-MarkDuplicates, 07-HaplotypeCallerBootstrap,
                                        08-SelectVariantsBootstrap, 09-BaseRecalibrator,
                                        10-ApplyBQSR, 11-AnalyzeCovariates, 12-DetermineCoverage,
                                        13-CollectWgsMetrics, 14-HaplotypeCaller, 15-Manta,
                                        16-HaplotypeCallerMappingVariants, 17-SelectMappingVariants,
                                        18-FilterHaplotypeCallerVariants,
                                        19-SubtractBackgroundHaplotypeCallerVariants,
                                        20-SubtractBackgroundMantaVariants,
                                        21-AnnotateHaplotypeCallerVariants,
                                        22-AnnotateMantaVariants, 23-MergeVariants,
                                        24-ProveanMissenseVariants, 25-AddWormBaseData
                                        26-HaplotypeCallerGenotypeVariants, 27-GenerateMappingPlots}

--clean-upon-completion <string>        Remove job directories after workflow completion.
                                        Default: false. Possible values: {true, false}

--linked-de-bruijn-graph <string>       Run HaplotypeCaller in new EXPERIMENTAL assembly mode which
                                        improves phasing, reduces false positives, improves calling
                                        at complex sites, and has 15-20% speedup vs the current
                                        assembler. Default: false. Possible values: {true, false} 

-h, --help                              Gives this help message.
" 

	BACKGROUND_DIRECTORY="$SCRIPT_DIR"/variants/background
	MAPPING_DIRECTORY="$SCRIPT_DIR"/variants/mapping

	SCRIPT="vda.sh call-mapping-variants"
	OPTSTRING="s:f:r:c:g:b:m:Vh"
	LOPTSTRING="sample-name:,fastq-directory:,run-mode:,max-cores:,max-memory:,background-directory:,mapping-directory:,resume-at-job:,clean-upon-completion:,linked-de-bruijn-graph:,verbose,help"

	RESULT=$(getopt -n "$SCRIPT" -o "$OPTSTRING" -l "$LOPTSTRING" -- "$@")
	if [ $? -ne 0 ]
	then
		# parsing error, show usage
		echo "$USAGE" 
		exit 1
	fi

	eval set -- "$RESULT"
	while [ true ] ; do
		case "$1" in
			-s|--sample-name) 
				shift 
				SAMPLE="$1"
			;;
			-f|--fastq-directory)
				shift
				FASTQ_DIR="$1"
			;;
			-r|--run-mode)
				shift
				RUN_MODE="$1"
			;;
			-c|--max-cores)
				shift
				MAX_CORES="$1"
			;;	
			-g|--max-memory)
				shift
				MAX_MEM="$1"
			;;
			-b|--background-directory)
				shift
				BACKGROUND_DIRECTORY="$1"
			;;
			-m|--mapping-directory)
				shift
				MAPPING_DIRECTORY="$1"
			;;
			--resume-at-job)
				shift
				RESUME_AT_JOB="$1"
			;;				
			--clean-upon-completion)
				shift
				CLEAN_UP="$1"			
			;;
			--linked-de-bruijn-graph)
				shift
				LINKED_DE_BRUIJN_GRAPH="$1"			
			;;
			-h|--help)
				echo "$USAGE"
				exit 0
			;;
			--)
				shift
				break
			;;
		esac
		shift
	done

	# check that sample name agrument has been set
	if [ -z "$SAMPLE" ]
	then
		echo -e "ERROR: Need to specify sample name \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that run mode agrument has been set to resume, resume-at, or restart
	if [ $RUN_MODE != "resume" ] && 
	   [ $RUN_MODE != "resume-at" ] && 
	   [ $RUN_MODE != "restart" ]
	then
		echo -e "ERROR: --run-mode was given the value "$RUN_MODE". Possible values: {resume, resume-at, restart} \n"
		echo "$USAGE"
		exit 1
	fi

	# if run mode agrument is set to resume-at, check that --resume-at-job agrument is set to a valid job directory
	if [ $RUN_MODE = "resume-at" ] &&
	   [ $RESUME_AT_JOB != "01-FastqToSam" ] &&
	   [ $RESUME_AT_JOB != "02-MarkIlluminaAdapters" ] &&
	   [ $RESUME_AT_JOB != "03-SamToFastq" ] &&
	   [ $RESUME_AT_JOB != "04-BwaMem" ] &&
	   [ $RESUME_AT_JOB != "05-MergeBamAlignment" ] &&
	   [ $RESUME_AT_JOB != "06-MarkDuplicates" ] &&
	   [ $RESUME_AT_JOB != "07-HaplotypeCallerBootstrap" ] &&
	   [ $RESUME_AT_JOB != "08-SelectVariantsBootstrap" ] &&
	   [ $RESUME_AT_JOB != "09-BaseRecalibrator" ] &&
	   [ $RESUME_AT_JOB != "10-ApplyBQSR" ] &&
	   [ $RESUME_AT_JOB != "11-AnalyzeCovariates" ] &&
	   [ $RESUME_AT_JOB != "12-DetermineCoverage" ] &&
	   [ $RESUME_AT_JOB != "13-CollectWgsMetrics" ] &&
	   [ $RESUME_AT_JOB != "14-HaplotypeCaller" ] &&
	   [ $RESUME_AT_JOB != "15-Manta" ] &&
	   [ $RESUME_AT_JOB != "16-HaplotypeCallerMappingVariants" ] &&
	   [ $RESUME_AT_JOB != "17-SelectMappingVariants" ] &&
	   [ $RESUME_AT_JOB != "18-FilterHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "19-SubtractBackgroundHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "20-SubtractBackgroundMantaVariants" ] &&
	   [ $RESUME_AT_JOB != "21-AnnotateHaplotypeCallerVariants" ] &&
	   [ $RESUME_AT_JOB != "22-AnnotateMantaVariants" ] &&
	   [ $RESUME_AT_JOB != "23-MergeVariants" ] &&
	   [ $RESUME_AT_JOB != "24-ProveanMissenseVariants" ] &&
	   [ $RESUME_AT_JOB != "25-AddWormBaseData" ] &&
	   [ $RESUME_AT_JOB != "26-HaplotypeCallerGenotypeVariants" ] &&
	   [ $RESUME_AT_JOB != "27-GenerateMappingPlots" ]
	then
	   	echo -e "ERROR: --resume-at-job was given the value "$RESUME_AT_JOB". Possible values: {01-FastqToSam, 02-MarkIlluminaAdapters, 03-SamToFastq, 04-BwaMem, 05-MergeBamAlignment, 06-MarkDuplicates, 07-HaplotypeCallerBootstrap, 08-SelectVariantsBootstrap, 09-BaseRecalibrator, 10-ApplyBQSR, 11-AnalyzeCovariates, 12-DetermineCoverage, 13-CollectWgsMetrics, 14-HaplotypeCaller, 15-Manta, 16-HaplotypeCallerMappingVariants, 17-SelectMappingVariants, 18-FilterHaplotypeCallerVariants, 19-SubtractBackgroundHaplotypeCallerVariants, 20-SubtractBackgroundMantaVariants, 21-AnnotateHaplotypeCallerVariants, 22-AnnotateMantaVariants, 23-MergeVariants, 24-ProveanMissenseVariants, 25-AddWormBaseData 26-HaplotypeCallerGenotypeVariants, 27-GenerateMappingPlots} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that clean up agrument is set to true or false
	if [ $CLEAN_UP != "true" ] && 
	   [ $CLEAN_UP != "false" ]
	then
		echo -e "ERROR: --clean-upon-completion was given the value "$CLEAN_UP". Possible values: {true, false} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that linked de bruijn graph agrument is set to true or false
	if [ $LINKED_DE_BRUIJN_GRAPH != "true" ] && 
	   [ $LINKED_DE_BRUIJN_GRAPH != "false" ]
	then
		echo -e "ERROR: --linked-de-bruijn-graph was given the value "$LINKED_DE_BRUIJN_GRAPH". Possible values: {true, false} \n"
		echo "$USAGE"
		exit 1
	fi

	# reset background and mapping directory paths if they end with "/"
	BACKGROUND_DIRECTORY=$(echo "$BACKGROUND_DIRECTORY" | sed s'/[/]$//')
	MAPPING_DIRECTORY=$(echo "$MAPPING_DIRECTORY" | sed s'/[/]$//')

	# reset fastq directory path if it ends with "/"
	FASTQ_DIR=$(echo "$FASTQ_DIR" | sed s'/[/]$//')

	COMMAND=""$SCRIPT_DIR"/scripts/variant_discovery_analysis.sh"

	export WORKFLOW
	export SAMPLE
	export FASTQ_DIR
	export RUN_MODE
	export MAX_CORES
	export BACKGROUND_DIRECTORY
	export MAPPING_DIRECTORY
	export MAX_MEM
	export RESUME_AT_JOB
	export CLEAN_UP
	export LINKED_DE_BRUIJN_GRAPH

	#run command
	sbatch "$COMMAND"

	STATUS=$?

	exit $STATUS
fi


# usage and configurations for compile-background-variants
if [ $WORKFLOW = "compile-background-variants" ]
then
	USAGE="VARIANT DISCOVERY ANALYSIS TOOLKIT

#######################################
 WORKFLOW: COMPILE-BACKGROUND-VARIANTS
#######################################

DESCRIPTION
compile-background-variants is a workflow to compile shared variants among samples derived from the 
same parent. 

USAGE
vda.sh compile-background-variants -v <vcf-directory> -n <minimum-number-of-occurences> -p
<output-prefix> [options]

EXAMPLE
vda.sh compile-background-variants -v ./ -n 3 -p YY500 [options]

REQUIRED ARGUMENTS
-v, --vcf-directory <string>	    	Path to directory containing vcf files. All vcf files in this
                                        directory ending in _background_all_variants.vcf will be
                                        used to compile a vcf containing shared variants.

-n, --minimum-number-of-occurences <integer>    The minimum number of times a variant must appear in
                                                the set of vcfs to be reported as background.

-p, --output-prefix <string>            The prefix given to the outputs of this workflow.

-d, --output-directory <string>     	Specifies where to copy output vcf.
                                        Default: "$SCRIPT_DIR"/variants/background

ADVANCED ARGUMENTS
-h, --help                              Gives this help message.
" 

	OUTPUT_DIRECTORY="$SCRIPT_DIR"/variants/background

	MAX_CORES=1
	MAX_MEM=4

	SCRIPT="vda.sh compile-background-variants"
	OPTSTRING="v:n:p:d:Vh"
	LOPTSTRING="vcf-directory:,minimum-number-of-occurences:,output-prefix:,output-directory:,verbose,help"

	RESULT=$(getopt -n "$SCRIPT" -o "$OPTSTRING" -l "$LOPTSTRING" -- "$@")
	if [ $? -ne 0 ]
	then
		# parsing error, show usage
		echo "$USAGE" 
		exit 1
	fi

	eval set -- "$RESULT"
	while [ true ] ; do
		case "$1" in
			-v|--vcf-directory) 
				shift 
				VCF_DIR="$1"
			;;
			-n|--minimum-number-of-occurences)
				shift
				MIN_N="$1"
			;;
			-p|--output-prefix)
				shift
				OUTPUT_PREFIX="$1"
			;;
			-d|--output-directory)
				shift
				OUTPUT_DIRECTORY="$1"
			;;
			-h|--help)
				echo "$USAGE"
				exit 0
			;;
			--)
				shift
				break
			;;
		esac
		shift
	done

	# check that vcf directory agrument has been set
	if [ -z "$VCF_DIR" ]
	then
		echo -e "ERROR: Need to specify path to vcf directory using the --vcf-directory argument \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that minimum number of occurences argument has been set
	if [ -z "$MIN_N" ]
	then
		echo -e "ERROR: --minimum-number-of-occurences was not given a value. \n" 
		echo "$USAGE"
		exit 1
	fi

    # check that minimum number of occurences value is an integer
	if ! [[ "$MIN_N" =~ ^[0-9]+$ ]]
	then 
    	echo -e "ERROR: --minimum-number-of-occurences was given the value "$MIN_N". --minimum-number-of-occurences must be an integer. \n"  
		echo "$USAGE"
		exit 1
	fi

	# check that output prefix agrument has been set
	if [ -z "$OUTPUT_PREFIX" ]
	then
		echo -e "ERROR: Need to specify output prefix using the --output-prefix \n"
		echo "$USAGE"
		exit 1
	fi

	# reset output directory paths if it ends with "/"
	OUTPUT_DIRECTORY=$(echo "$OUTPUT_DIRECTORY" | sed s'/[/]$//')

	COMMAND=""$SCRIPT_DIR"/scripts/compile_background_variants.sh"

	export WORKFLOW
	export MAX_CORES
	export MAX_MEM
	export VCF_DIR
	export MIN_N
	export OUTPUT_PREFIX
	export OUTPUT_DIRECTORY

	#run command
	sbatch "$COMMAND"

	STATUS=$?

	exit $STATUS
fi


# usage and configurations for clean-mapping-variants
if [ $WORKFLOW = "clean-mapping-variants" ]
then
	USAGE="VARIANT DISCOVERY ANALYSIS TOOLKIT

##################################
 WORKFLOW: CLEAN-MAPPING-VARIANTS
##################################

DESCRIPTION
clean-mapping-variants is a workflow to subtract background variants from mapping variants. This
workflow is particularly useful when the mapping strain and the mutant being mapped are derived
from the same parent strain.

USAGE
vda.sh clean-mapping-variants -m <mapping-variants> -b <background-variants> [options]

EXAMPLE
vda.sh clean-mapping-variants -m YY600_mapping_variants.vcf -b YY500_background_variants.vcf
[options]

REQUIRED ARGUMENTS
-m, --mapping-variants <string>	       A vcf file containing mapping variants.

-b, --background-variants <string>     A vcf file containing background variants to be subtracted.

-o, --output-directory <string>        Path to directory where output is written. Default: [.]

ADVANCED ARGUMENTS
-h, --help                             Gives this help message.
"

	MAX_CORES=1
	MAX_MEM=4
	OUT_DIR="."

	SCRIPT="vda.sh clean-mapping-variants"
	OPTSTRING="m:b:o:Vh"
	LOPTSTRING="mapping-variants:,background-variants:,output-directory:,verbose,help"

	RESULT=$(getopt -n "$SCRIPT" -o "$OPTSTRING" -l "$LOPTSTRING" -- "$@")
	if [ $? -ne 0 ]
	then
		# parsing error, show usage
		echo "$USAGE" 
		exit 1
	fi

	eval set -- "$RESULT"
	while [ true ] ; do
		case "$1" in
			-m|--mapping-variants) 
				shift 
				MAPPING_VARIANTS="$1"
			;;
			-b|--background-variants)
				shift
				BACKGROUND_VARIANTS="$1"
			;;
			-o|--output-directory)
				shift
				OUT_DIR="$1"
			;;				
			-h|--help)
				echo "$USAGE"
				exit 0
			;;
			--)
				shift
				break
			;;
		esac
		shift
	done

	# check that mapping-variants agrument has been set appropriately
	if [[ $(echo "$MAPPING_VARIANTS" | sed 's/.*\(...\)/\1/') != "vcf" ]]
	then
		echo -e "ERROR: --mapping-variants was given an unsupported value. Possible values: {/path/to/*.vcf} \n"
		echo "$USAGE"
		exit 1
	fi

	# check that background-variants agrument has been set appropriately
	if [[ $(echo "$BACKGROUND_VARIANTS" | sed 's/.*\(...\)/\1/') != "vcf" ]]
	then
		echo -e "ERROR: --background-variants was given an unsupported value. Possible values: {/path/to/*.vcf} \n"
		echo "$USAGE"
		exit 1
	fi

	COMMAND=""$SCRIPT_DIR"/scripts/clean_mapping_variants.sh"

	export WORKFLOW
	export MAX_CORES
	export MAX_MEM
	export MAPPING_VARIANTS
	export BACKGROUND_VARIANTS
	export OUT_DIR

	#run command
	sbatch "$COMMAND"

	STATUS=$?

	exit $STATUS
fi


# usage and configurations for in-silico-complementation
if [ $WORKFLOW = "in-silico-complementation" ]
then
	USAGE="VARIANT DISCOVERY ANALYSIS TOOLKIT

#####################################
 WORKFLOW: IN-SILICO-COMPLEMENTATION
#####################################

DESCRIPTION
in-silico-complementation is a workflow to identify genes with more than one variant in a set of
samples.

USAGE
vda.sh in-silico-complementation -t <txt-directory> -o <output-prefix>

EXAMPLE
vda.sh in-silico-complementation -t ./ -o ./my_mutants

REQUIRED ARGUMENTS
-t, --txt-directory <string>	    	Path to directory containing txt files. All files named
                                        *_all_variants_final.txt will be queried to create a txt
                                        file containing a list of genes with more than one variant
                                        among the set of txt files.

-o, --output-prefix <string>            The path and prefix given to the outputs.

ADVANCED ARGUMENTS
-h, --help                              Gives this help message.
" 

	MAX_CORES=1
	MAX_MEM=4

	SCRIPT="vda.sh in-silico-complementation"
	OPTSTRING="t:o:Vh"
	LOPTSTRING="txt-directory:,output-prefix:,verbose,help"

	RESULT=$(getopt -n "$SCRIPT" -o "$OPTSTRING" -l "$LOPTSTRING" -- "$@")
	if [ $? -ne 0 ]
	then
		# parsing error, show usage
		echo "$USAGE" 
		exit 1
	fi

	eval set -- "$RESULT"
	while [ true ] ; do
		case "$1" in
			-t|--txt-directory) 
				shift 
				TXT_DIR="$1"
			;;
			-o|--output-prefix)
				shift
				OUTPUT_PREFIX="$1"
			;;
			-h|--help)
				echo "$USAGE"
				exit 0
			;;
			--)
				shift
				break
			;;
		esac
		shift
	done

	# check that txt directory agrument has been set
	if [ -z "$TXT_DIR" ]
	then
		echo -e "ERROR: Need to specify path to txt directory using the --txt-directory argument \n" 
		echo "$USAGE"
		exit 1
	fi

	# check that output prefix agrument has been set
	if [ -z "$OUTPUT_PREFIX" ]
	then
		echo -e "ERROR: Need to specify output prefix using the --output-prefix \n"
		echo "$USAGE"
		exit 1
	fi

	COMMAND=""$SCRIPT_DIR"/scripts/in_silico_complementation.sh"

	export WORKFLOW
	export MAX_CORES
	export MAX_MEM
	export TXT_DIR
	export OUTPUT_PREFIX

	#run command
	sbatch "$COMMAND"

	STATUS=$?

	exit $STATUS
fi
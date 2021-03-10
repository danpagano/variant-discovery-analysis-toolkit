#!/bin/bash
#SBATCH -p short
#SBATCH -t 0-00:10
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH -o ./compile_background_variants.out
#SBATCH -e ./compile_background_variants.err
#SBATCH--mail-type=FAIL

# Print command line inputs and configuration to log file
	printf -- "%s\n" "COMPILE BACKGROUND VARIANTS LOG FILE" > compile_background_variants_log.txt
	printf -- "%s\n" "[`date`] " "" >> compile_background_variants_log.txt

	printf -- "%s\n" "-----COMMAND-LINE-INPUTS-----" >> compile_background_variants_log.txt
	printf -- "%s\n" "Workflow: "$WORKFLOW"" >> compile_background_variants_log.txt
	printf -- "%s\n" "Max cores: "$MAX_CORES"" >> compile_background_variants_log.txt
	printf -- "%s\n" "Max memory (Gb): "$MAX_MEM"" >> compile_background_variants_log.txt
	printf -- "%s\n" "Directory containing vcf files for analysis: "$VCF_DIR"" >> compile_background_variants_log.txt
	printf -- "%s\n" "Minimum number of times a variant must appear in the set of vcfs to be reported as background: "$MIN_N"" >> compile_background_variants_log.txt
	printf -- "%s\n" "Prefix given to outputs: "$OUTPUT_PREFIX"" >> compile_background_variants_log.txt
	printf -- "%s\n" "Directory where output vcf files will be copied to: "$OUTPUT_DIRECTORY"" >> compile_background_variants_log.txt

	printf -- "%s\n" " " "-------CONFIGURATIONS--------" >> compile_background_variants_log.txt
	printf -- "%s\n" "Java: "$(which java)"" >> compile_background_variants_log.txt
	printf -- "%s\n" "Python: "$(which python)"" >> compile_background_variants_log.txt
	printf -- "%s\n" "Path to GATK3: "$PATH_TO_GATK3"" >> compile_background_variants_log.txt 
	printf -- "%s\n" "Reference genome: "$REFERENCE_GENOME"" >> compile_background_variants_log.txt 
	printf -- "%s\n" " " >> compile_background_variants_log.txt 

# change to analysis directory
	if [ $VCF_DIR = "." ] || [ $VCF_DIR = "./" ]
	then
		VCF_DIR="$(pwd)"
	fi

	if [ $VCF_DIR != "$(pwd)" ]
	then
		mv compile_background_variants_log.txt "$VCF_DIR"
		cd "$VCF_DIR"
	fi

# check that analysis directory contains files ending in *_background_all_variants.vcf
	if [[ $(ls | grep _background_all_variants.vcf | wc | awk '{ print $1 }') = 0 ]]
	then
		echo "[`date`] ERROR: Unalbe to locate vcf files in "$VCF_DIR". Make sure path to directory containing the vcf files was input correctly." >> compile_background_variants_log.txt
		mv compile_background_variants_log.txt compile_background_variants_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
		echo "[`date`] ERROR: Unalbe to locate vcf files in "$VCF_DIR". Make sure path to directory containing the vcf files was input correctly."
		exit 1
	fi 

# create a list of vcfs to be input into CombineVariants
	ls *_background_all_variants.vcf > vcf.list

# print inputs for CombineVariants to log file
	printf -- "%s\n" "-----vcf files input into CombineVariants-----" >> compile_background_variants_log.txt
	cat vcf.list >> compile_background_variants_log.txt
	
# check that output directory exists 
	if [ $OUTPUT_DIRECTORY = "." ] || [ $OUTPUT_DIRECTORY = "./" ]
	then
		OUTPUT_DIRECTORY="$(pwd)"
	fi

	if [ -d "$OUTPUT_DIRECTORY" ]
	then
		echo -e "\n[`date`] Found "$OUTPUT_DIRECTORY" output directory" >> compile_background_variants_log.txt
	else
		echo -e "\n[`date`] "$OUTPUT_DIRECTORY" output directory doesn't exist. Making "$OUTPUT_DIRECTORY" output directory" >> compile_background_variants_log.txt
		OUTPUT_DIRECTORY=$(echo "$OUTPUT_DIRECTORY" | sed 's/^[/]//')
		mkdir -p $OUTPUT_DIRECTORY
		OUTPUT_DIRECTORY=/"$OUTPUT_DIRECTORY"				
	fi	

# combine background variants 
	echo -e "\n[`date`] CombineVariants started" >> compile_background_variants_log.txt
	
	srun -c 1 --mem 4G \
	java -Xmx4G -jar "$PATH_TO_GATK3"/GenomeAnalysisTK.jar \
    -T CombineVariants \
    -R $REFERENCE_GENOME \
	--variant ./vcf.list \
    --minimumN $MIN_N \
    -o "$OUTPUT_DIRECTORY"/"$OUTPUT_PREFIX"_background_all_variants.vcf \
    -genotypeMergeOptions UNIQUIFY

    rm vcf.list

	if [ -f "$OUTPUT_DIRECTORY"/"$OUTPUT_PREFIX"_background_all_variants.vcf ]
	then
		echo -e "[`date`] CombineVariants completed" >> compile_background_variants_log.txt
	else
		echo -e "[`date`] ERROR: CombineVariants failed. Check compile_background_variants.err for details" >> compile_background_variants_log.txt
		mv compile_background_variants_log.txt compile_background_variants_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
		echo -e "[`date`] ERROR: CombineVariants failed. Check compile_background_variants.err for details"
		exit 1
	fi

############

STATUS=$?

exit $STATUS
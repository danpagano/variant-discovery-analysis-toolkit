#!/bin/bash
#SBATCH -p short
#SBATCH -t 0-00:10
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH -o ./clean_mapping_variants.out
#SBATCH -e ./clean_mapping_variants.err
#SBATCH--mail-type=FAIL

# Print command line inputs and configuration to log file
	printf -- "%s\n" "CLEAN MAPPING VARIANTS LOG FILE" > clean_mapping_variants_log.txt
	printf -- "%s\n" "[`date`] " "" >> clean_mapping_variants_log.txt

	printf -- "%s\n" "-----COMMAND-LINE-INPUTS-----" >> clean_mapping_variants_log.txt
	printf -- "%s\n" "Workflow: "$WORKFLOW"" >> clean_mapping_variants_log.txt
	printf -- "%s\n" "Max cores: "$MAX_CORES"" >> clean_mapping_variants_log.txt
	printf -- "%s\n" "Max memory (Gb): "$MAX_MEM"" >> clean_mapping_variants_log.txt
	printf -- "%s\n" "Mapping variants: "$MAPPING_VARIANTS"" >> clean_mapping_variants_log.txt
	printf -- "%s\n" "Background variants to subtract: "$BACKGROUND_VARIANTS"" >> clean_mapping_variants_log.txt
	printf -- "%s\n" "Output directory: "$OUT_DIR"" >> clean_mapping_variants_log.txt

	printf -- "%s\n" " " "-------CONFIGURATIONS--------" >> clean_mapping_variants_log.txt
	printf -- "%s\n" "Java: "$(which java)"" >> clean_mapping_variants_log.txt 
	printf -- "%s\n" "Python: "$(which python)"" >> clean_mapping_variants_log.txt 
	printf -- "%s\n" "Path to GATK4: "$PATH_TO_GATK4"" >> clean_mapping_variants_log.txt 
	printf -- "%s\n" "Reference genome: "$REFERENCE_GENOME"" >> clean_mapping_variants_log.txt 
	printf -- "%s\n" " " >> clean_mapping_variants_log.txt 

OUT_DIR=$(echo "$OUT_DIR" | sed s'/[/]$//')
MAPPING_VARIANTS_NAME=$(echo $MAPPING_VARIANTS | awk -F "/" '{print $NF}' | sed 's/.vcf//')
BACKGROUND_VARIANTS_NAME=$(echo $BACKGROUND_VARIANTS | awk -F "/" '{print $NF}' | sed 's/.vcf//')

if [ -f "$OUT_DIR"/"$MAPPING_VARIANTS_NAME"_with_"$BACKGROUND_VARIANTS_NAME"_subtracted.vcf ] && 
   [ -f "$OUT_DIR"/"$MAPPING_VARIANTS_NAME"_with_"$BACKGROUND_VARIANTS_NAME"_subtracted.vcf.idx ]
then 
	echo "[`date`] Output already exists" >> clean_mapping_variants_log.txt
    echo "[`date`] Output already exists"
	exit 1
else 
	echo "[`date`] SubtractVariants started" >> clean_mapping_variants_log.txt

	# subtract background variants from mapping variants
	srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
	--reference $REFERENCE_GENOME \
	--variant $MAPPING_VARIANTS \
	--discordance $BACKGROUND_VARIANTS \
	--output "$OUT_DIR"/"$MAPPING_VARIANTS_NAME"_with_"$BACKGROUND_VARIANTS_NAME"_subtracted.vcf

	# index vcf
	srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" IndexFeatureFile \
	--input "$OUT_DIR"/"$MAPPING_VARIANTS_NAME"_with_"$BACKGROUND_VARIANTS_NAME"_subtracted.vcf

	if [ -f "$OUT_DIR"/"$MAPPING_VARIANTS_NAME"_with_"$BACKGROUND_VARIANTS_NAME"_subtracted.vcf ] &&
	   [ -f "$OUT_DIR"/"$MAPPING_VARIANTS_NAME"_with_"$BACKGROUND_VARIANTS_NAME"_subtracted.vcf.idx ]
	then 
		echo "[`date`] SubtractVariants completed" >> clean_mapping_variants_log.txt
	else 
		echo "[`date`] ERROR: SubtractVariants failed. Check clean_mapping_variants.err for details" >> clean_mapping_variants_log.txt
		mv clean_mapping_variants_log.txt clean_mapping_variants_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
		echo "[`date`] ERROR: SubtractVariants failed. Check clean_mapping_variants.err for details"
		exit 1
	fi
fi

############

STATUS=$?

exit $STATUS
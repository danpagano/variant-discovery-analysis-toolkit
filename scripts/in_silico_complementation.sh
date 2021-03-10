#!/bin/bash
#SBATCH -p short
#SBATCH -t 0-00:10
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH -o ./in_silico_complementation.out
#SBATCH -e ./in_silico_complementation.err
#SBATCH--mail-type=FAIL

# Print command line inputs and configuration to log file
	printf -- "%s\n" "IN SILICO COMPLEMENTATION LOG FILE" > in_silico_complementation_log.txt
	printf -- "%s\n" "[`date`] " "" >> in_silico_complementation_log.txt

	printf -- "%s\n" "-----COMMAND-LINE-INPUTS-----" >> in_silico_complementation_log.txt
	printf -- "%s\n" "Workflow: "$WORKFLOW"" >> in_silico_complementation_log.txt
	printf -- "%s\n" "Directory containing txt files for analysis: "$TXT_DIR"" >> in_silico_complementation_log.txt
	printf -- "%s\n" "Prefix given to output: "$OUTPUT_PREFIX"" >> in_silico_complementation_log.txt

	printf -- "%s\n" " " "-------CONFIGURATIONS--------" >> in_silico_complementation_log.txt
	printf -- "%s\n" "Python: "$(which python)"" >> in_silico_complementation_log.txt

# change to analysis directory, if need be
	if [ $TXT_DIR = "." ] || [ $TXT_DIR = "./" ]
	then
		TXT_DIR="$(pwd)"
	fi

	if [ $TXT_DIR != "$(pwd)" ]
	then
		mv in_silico_complementation_log.txt "$TXT_DIR"
		cd "$TXT_DIR"
	fi

# check that analysis directory contains files ending in *_all_variants_final.txt
	if [[ $(ls | grep _all_variants_final.txt | wc | awk '{ print $1 }') = 0 ]]
	then
		echo "[`date`] ERROR: Unalbe to locate *_all_variants_final.txt files in "$TXT_DIR". Make sure path to txt files was input correctly." >> in_silico_complementation_log.txt
		mv in_silico_complementation_log.txt in_silico_complementation_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
		echo "[`date`] ERROR: Unalbe to locate *_all_variants_final.txt files in "$TXT_DIR". Make sure path to txt files was input correctly."
		exit 1
	fi 

# create a list of txts to be input into CloudMap_InSilico.py
	ls | grep _all_variants_final.txt | sort > input_txt_files

# print inputs for CloudMap_InSilico.py to log file
	printf -- "%s\n" "--VDA txt files input into CloudMap_InSilico.py--" >> in_silico_complementation_log.txt
	cat input_txt_files >> in_silico_complementation_log.txt

# create a list of sample names
	cat input_txt_files | awk -F "_" '{print $1}' > input_sample_names

# create variables to hold input sample names and input file names
	TXT_FILES=$(cat input_txt_files | tr '\r\n' ' ')
	NAMES=$(cat input_sample_names | tr '\r\n' ' ')

# run in silcio complementation 
	echo -e "\n[`date`] in silcio complementation started" >> in_silico_complementation_log.txt
	
	python "$SCRIPT_DIR"/scripts/CloudMap_InSilico.py -i $TXT_FILES -n $NAMES -s "$OUTPUT_PREFIX"_in_silico_complementation_summary.txt -o "$OUTPUT_PREFIX"_in_silico_complementation_data.txt

	if [ -f "$OUTPUT_PREFIX"_in_silico_complementation_data.txt ]
	then
		echo -e "[`date`] in silcio complementation completed" >> in_silico_complementation_log.txt
		mv in_silico_complementation_log.txt in_silico_complementation_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
		rm input_txt_files
		rm input_sample_names
		exit 0
	else
		echo -e "[`date`] ERROR: in silcio complementation failed. Check in_silico_complementation.err for details" >> in_silico_complementation_log.txt
		mv in_silico_complementation_log.txt in_silico_complementation_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
		echo -e "[`date`] ERROR: in silcio complementation failed. Check in_silico_complementation.err for details"
		exit 1
	fi

############

STATUS=$?

exit $STATUS
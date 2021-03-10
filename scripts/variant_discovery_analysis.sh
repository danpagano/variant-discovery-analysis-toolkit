#!/bin/bash
#SBATCH -p short
#SBATCH -t 0-08:00
#SBATCH -c 8
#SBATCH --mem=24G
#SBATCH -o ./variant_discovery_analysis.out
#SBATCH -e ./variant_discovery_analysis.err
#SBATCH--mail-type=FAIL

# Print command line inputs and configuration to log file
	printf -- "%s\n" ""$SAMPLE" VARIANT DISCOVERY ANALYSIS LOG FILE" > "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "[`date`] " "" >> "$SAMPLE"_vda_log.txt

	printf -- "%s\n" "-----COMMAND-LINE-INPUTS-----" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Workflow: "$WORKFLOW"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Sample name: "$SAMPLE"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Run mode: "$RUN_MODE"" >> "$SAMPLE"_vda_log.txt
	if [ ! -z "$RESUME_AT_JOB" ]; then printf -- "%s\n" "Resume workflow at job: "$RESUME_AT_JOB"" >> "$SAMPLE"_vda_log.txt; fi
	printf -- "%s\n" "fastq directory: "$FASTQ_DIR"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Max cores: "$MAX_CORES"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Max memory (Gb): "$MAX_MEM"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Clean upon completion: "$CLEAN_UP"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Calculate provean scores: "$CALCULATE_PROVEAN_SCORES"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Add WormBase data: "$ADD_WORMBASE_DATA"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Run HaplotypeCaller using linked de bruijn graph: "$LINKED_DE_BRUIJN_GRAPH"" >> "$SAMPLE"_vda_log.txt
	if [ ! -z "$PARENT_STRAIN_BACKGROUND_VARIANTS" ]; then printf -- "%s\n" "Parent strain background variants: "$PARENT_STRAIN_BACKGROUND_VARIANTS"" >> "$SAMPLE"_vda_log.txt; fi
	if [ ! -z "$MAPPING_STRAIN_BACKGROUND_VARIANTS" ]; then printf -- "%s\n" "Mapping strain background variants: "$MAPPING_STRAIN_BACKGROUND_VARIANTS"" >> "$SAMPLE"_vda_log.txt; fi
	if [ ! -z "$MAPPING_VARIANTS" ]; then printf -- "%b\n" "Mapping variants: "$MAPPING_VARIANTS"\n" >> "$SAMPLE"_vda_log.txt; fi
	if [ ! -z "$BACKGROUND_DIRECTORY" ]; then printf -- "%b\n" "Directory where background vcf files will be copied to: "$BACKGROUND_DIRECTORY"\n" >> "$SAMPLE"_vda_log.txt; fi
	if [ ! -z "$MAPPING_DIRECTORY" ]; then printf -- "%b\n" "Directory where mapping vcf files will be copied to: "$MAPPING_DIRECTORY"\n" >> "$SAMPLE"_vda_log.txt; fi

	printf -- "%s\n" " " "-------CONFIGURATIONS--------" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Java: "$(which java)"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Python: "$(which python)"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "R: "$(which R)"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "R libraries: "$(echo $R_LIBS)"" >> "$SAMPLE"_vda_log.txt
	printf -- "%s\n" "Path to GATK4: "$PATH_TO_GATK4"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "Path to BWA: "$PATH_TO_BWA"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "Path to SAMtools: "$PATH_TO_SAMTOOLS"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "Path to BEDTools: "$PATH_TO_BEDTOOLS2"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "Path to manta: "$PATH_TO_MANTA"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "Path to strelka: "$PATH_TO_STRELKA"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "Path to SnpEff: "$PATH_TO_SNPEFF"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%b\n" "Path to PROVEAN: "$PATH_TO_PROVEAN"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "Reference genome: "$REFERENCE_GENOME"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "SnpEff database: "$SNPEFF_DATABASE"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "Annotations: "$ANNOTATIONS"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" "Blacklisted variants: "$BLACKLISTED_VARIANTS"" >> "$SAMPLE"_vda_log.txt 
	printf -- "%s\n" " " >> "$SAMPLE"_vda_log.txt 

# Remove previous analysis if run mode is set to restart
	if [ $RUN_MODE = "restart" ]
	then
		echo "[`date`] Resetting... removing directories and files from previous analysis" >> "$SAMPLE"_vda_log.txt
		srun -c 1 --mem 4G rm -rf ./"$SAMPLE"_VDA
	fi

# Ensure fastq input files are named correctly and located in the specified directory 
	if [ $FASTQ_DIR = "." ] || [ $FASTQ_DIR = "./" ]
	then
		FASTQ_DIR="$(pwd)"
	fi

	if [ -f "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz ]
	then 
		echo "[`date`] Located "$SAMPLE" fastq files in "$FASTQ_DIR"" >> "$SAMPLE"_vda_log.txt
	else 
		echo "[`date`] ERROR: Unalbe to locate "$SAMPLE" fastq files in "$FASTQ_DIR". Check to make sure path is correct and fastq files are named "$SAMPLE"_L001_R1.fastq.gz, "$SAMPLE"_L002_R1.fastq.gz, etc. for single-end reads and "$SAMPLE"_L001_R1.fastq.gz, "$SAMPLE"_L001_R2.fastq.gz, "$SAMPLE"_L002_R1.fastq.gz, "$SAMPLE"_L002_R2.fastq.gz, etc. for paired-end reads" >> "$SAMPLE"_vda_log.txt
		mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
		echo "[`date`] ERROR: Unalbe to locate "$SAMPLE" fastq files in "$FASTQ_DIR". Check to make sure path is correct and fastq files are named "$SAMPLE"_L001_R1.fastq.gz, "$SAMPLE"_L002_R1.fastq.gz, etc. for single-end reads and "$SAMPLE"_L001_R1.fastq.gz, "$SAMPLE"_L001_R2.fastq.gz, "$SAMPLE"_L002_R1.fastq.gz, "$SAMPLE"_L002_R2.fastq.gz, etc. for paired-end reads"
		exit 1
	fi 

# Determine read-type
	if [ -f "$FASTQ_DIR"/"$SAMPLE"_L001_R2.fastq.gz ]
	then
		echo "[`date`] Read-type was determined to be paired-end. Running analysis in paired-end mode." >> "$SAMPLE"_vda_log.txt
		READ_TYPE=paired-end
	else
		echo "[`date`] Read-type was determined to be single-end. Running analysis in single-end mode." >> "$SAMPLE"_vda_log.txt
		READ_TYPE=single-end
	fi

	if [ $READ_TYPE != "single-end" ] && [ $READ_TYPE != "paired-end" ]
	then
		echo "[`date`] ERROR: read-type is not set correctly. In theory, it shouldn't be possible to get this error message. If you do, then something is inherently wrong with the script." >> "$SAMPLE"_vda_log.txt
		mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
		echo "[`date`] ERROR: read-type is not set correctly. In theory, it shouldn't be possible to get this error message. If you do, then something is inherently wrong with the script."
		exit 1
	fi

# Determine number of lanes
	if [ -f "$FASTQ_DIR"/"$SAMPLE"_L008_R1.fastq.gz ]
	then
		echo "[`date`] Number of lanes was determined to be 8" >> "$SAMPLE"_vda_log.txt
		NUM_LANES=8
	else
		if [ -f "$FASTQ_DIR"/"$SAMPLE"_L007_R1.fastq.gz ]
		then
			echo "[`date`] Number of lanes was determined to be 7" >> "$SAMPLE"_vda_log.txt
			NUM_LANES=7
		else
			if [ -f "$FASTQ_DIR"/"$SAMPLE"_L006_R1.fastq.gz ]
			then
				echo "[`date`] Number of lanes was determined to be 6" >> "$SAMPLE"_vda_log.txt
				NUM_LANES=6
			else
				if [ -f "$FASTQ_DIR"/"$SAMPLE"_L005_R1.fastq.gz ]
				then
					echo "[`date`] Number of lanes was determined to be 5" >> "$SAMPLE"_vda_log.txt
					NUM_LANES=5
				else
					if [ -f "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz ]
					then
						echo "[`date`] Number of lanes was determined to be 4" >> "$SAMPLE"_vda_log.txt
						NUM_LANES=4
					else
						if [ -f "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz ]
						then
							echo "[`date`] Number of lanes was determined to be 3" >> "$SAMPLE"_vda_log.txt
							NUM_LANES=3
						else
							if [ -f "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz ]
							then
								echo "[`date`] Number of lanes was determined to be 2" >> "$SAMPLE"_vda_log.txt
								NUM_LANES=2
							else			
								if [ -f "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz ]
								then
									echo "[`date`] Number of lanes was determined to be 1" >> "$SAMPLE"_vda_log.txt
									NUM_LANES=1
								fi
							fi
						fi
					fi
				fi
			fi
		fi
	fi

	if [ $NUM_LANES != "1" ] && [ $NUM_LANES != "2" ] && [ $NUM_LANES != "3" ] && [ $NUM_LANES != "4" ] && [ $NUM_LANES != "5" ] && [ $NUM_LANES != "6" ] && [ $NUM_LANES != "7" ] && [ $NUM_LANES != "8" ]
	then
		echo "[`date`] ERROR: Number of lanes exceeds 8. At the moment, this script can only accommodate up to and including 8 lanes. If your DNA libraries were sequenced over more than 8 lanes, consider concatenating files." >> "$SAMPLE"_vda_log.txt
		mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
		echo "[`date`] ERROR: Number of lanes exceeds 8. At the moment, this script can only accommodate up to and including 8 lanes. If your DNA libraries were sequenced over more than 8 lanes, consider concatenating files."
		exit 1
	fi

# Make analysis directory if it doesn't already exist 
	if [ -d ./"$SAMPLE"_VDA ]
	then 
		echo "[`date`] Found "$SAMPLE"_VDA directory" >> "$SAMPLE"_vda_log.txt
	else
		echo "[`date`] Making "$SAMPLE"_VDA directory" >> "$SAMPLE"_vda_log.txt
		mkdir ./"$SAMPLE"_VDA
	fi

# Change to analysis directory
	mv "$SAMPLE"_vda_log.txt ./"$SAMPLE"_VDA
	cd ./"$SAMPLE"_VDA

    #adjust path to fastq files if fastq directory was input as present working directory, i.e. "." or "./"
	if [ ""$FASTQ_DIR"/"$SAMPLE"_VDA" = "$(pwd)" ]
	then
		FASTQ_DIR=./..
	fi

# Delete job directories if RESUME_AT_JOB has been set
	if [ ! -z "$RESUME_AT_JOB" ]
	then
		echo "[`date`] Resuming analysis at "$RESUME_AT_JOB". Removing "$RESUME_AT_JOB" directory and all job directories that follow" >> "$SAMPLE"_vda_log.txt 
		restart=$(echo "$RESUME_AT_JOB" | awk -F "-" '{print $1}')
		rm -rf $(ls -lh | awk -F " " '{print $9}' | awk -v var="$restart" -F "-" '$1 >= var {print $0}' | grep -E '01-FastqToSam|02-MarkIlluminaAdapters|03-SamToFastq|04-BwaMem|05-MergeBamAlignment|06-MarkDuplicates|07-HaplotypeCallerBootstrap|08-SelectVariantsBootstrap|09-BaseRecalibrator|10-ApplyBQSR|11-AnalyzeCovariates|12-DetermineCoverage|13-CollectWgsMetrics|14-HaplotypeCaller|15-Manta|16-HaplotypeCallerMappingVariants|17-SelectMappingVariants|18-FilterHaplotypeCallerVariants|19-SubtractBackgroundHaplotypeCallerVariants|20-SubtractBackgroundMantaVariants|21-AnnotateHaplotypeCallerVariants|22-AnnotateMantaVariants|23-MergeVariants|24-ProveanMissenseVariants|25-AddWormBaseData 26-HaplotypeCallerGenotypeVariants|27-GenerateMappingPlots')
	fi

#01-FastqToSam
	# Convert fastq to uBAM and add read group information
	if [ $READ_TYPE = "single-end" ]
	then
		if [ $NUM_LANES = "1" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam
				
				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF 

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "2" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ]
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &
				
				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ]  
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "3" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ]
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "4" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "5" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ]
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L005_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane5 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "6" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L005_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane5 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L006_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane6 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "7" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L005_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane5 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L006_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane6 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L007_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane7 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "8" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L008_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L005_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane5 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L006_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane6 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L007_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane7 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L008_R1.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L008_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane8 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L008_unmapped.bam ] 
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi
	fi

	if [ $READ_TYPE = "paired-end" ]
	then
		if [ $NUM_LANES = "1" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam
				
				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L001_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF 
				
				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "2" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ]
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L001_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L002_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &
				
				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ]  
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "3" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ]
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L001_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L002_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L003_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "4" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L001_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L002_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L003_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L004_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "5" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ]
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L001_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L002_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L003_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L004_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L005_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L005_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane5 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "6" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L001_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L002_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L003_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L004_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L005_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L005_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane5 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L006_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L006_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane6 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "7" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L001_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L002_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L003_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L004_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L005_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L005_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane5 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L006_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L006_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane6 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L007_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L007_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane7 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam ]
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $NUM_LANES = "8" ]
		then
			if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam ] &&
			   [ -f ./01-FastqToSam/"$SAMPLE"_L008_unmapped.bam ] 
			then 
				echo "[`date`] FastqToSam already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./01-FastqToSam ]
				then
					echo "[`date`] FastqToSam is incomplete, likely due to this job having previously failed. Removing 01-FastqToSam directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./01-FastqToSam
				fi
				echo "[`date`] FastqToSam started" >> "$SAMPLE"_vda_log.txt
				mkdir ./01-FastqToSam

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L001_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L001_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane1 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L002_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L002_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane2 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L003_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L003_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane3 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L004_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L004_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane4 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L005_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L005_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane5 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L006_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L006_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane6 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L007_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L007_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane7 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" FastqToSam \
				--FASTQ "$FASTQ_DIR"/"$SAMPLE"_L008_R1.fastq.gz \
				--FASTQ2 "$FASTQ_DIR"/"$SAMPLE"_L008_R2.fastq.gz \
				--OUTPUT ./01-FastqToSam/"$SAMPLE"_L008_unmapped.bam \
				--READ_GROUP_NAME flowcell1.lane8 \
				--SAMPLE_NAME "$SAMPLE" \
				--LIBRARY_NAME lib \
				--PLATFORM illumina \
				--SEQUENCING_CENTER BPF &

				wait

				if [ -f ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam ] &&
				   [ -f ./01-FastqToSam/"$SAMPLE"_L008_unmapped.bam ] 
				then 
					echo "[`date`] FastqToSam completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: FastqToSam failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi
	fi

#02-MarkIlluminaAdapters
	# Mark adapter sequences
	if [ $NUM_LANES = "1" ]
	then
		if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] 
		then 
			echo "[`date`] MarkIlluminaAdapters already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./02-MarkIlluminaAdapters ]
			then
				echo "[`date`] MarkIlluminaAdapters is incomplete, likely due to this job having previously failed. Removing 02-MarkIlluminaAdapters directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./02-MarkIlluminaAdapters
			fi			
			echo "[`date`] MarkIlluminaAdapters started" >> "$SAMPLE"_vda_log.txt
			mkdir ./02-MarkIlluminaAdapters

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_markilluminaadapters_metrics.txt

			if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ]
			then 
				echo "[`date`] MarkIlluminaAdapters completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "2" ]
	then
		if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] 
		then 
			echo "[`date`] MarkIlluminaAdapters already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./02-MarkIlluminaAdapters ]
			then
				echo "[`date`] MarkIlluminaAdapters is incomplete, likely due to this job having previously failed. Removing 02-MarkIlluminaAdapters directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./02-MarkIlluminaAdapters
			fi			
			echo "[`date`] MarkIlluminaAdapters started" >> "$SAMPLE"_vda_log.txt
			mkdir ./02-MarkIlluminaAdapters

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_markilluminaadapters_metrics.txt &

			wait

			if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ]
			then 
				echo "[`date`] MarkIlluminaAdapters completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "3" ]
	then
		if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] 
		then 
			echo "[`date`] MarkIlluminaAdapters already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./02-MarkIlluminaAdapters ]
			then
				echo "[`date`] MarkIlluminaAdapters is incomplete, likely due to this job having previously failed. Removing 02-MarkIlluminaAdapters directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./02-MarkIlluminaAdapters
			fi			
			echo "[`date`] MarkIlluminaAdapters started" >> "$SAMPLE"_vda_log.txt
			mkdir ./02-MarkIlluminaAdapters

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_markilluminaadapters_metrics.txt &

			wait

			if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ]
			then 
				echo "[`date`] MarkIlluminaAdapters completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "4" ]
	then
		if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ] 
		then 
			echo "[`date`] MarkIlluminaAdapters already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./02-MarkIlluminaAdapters ]
			then
				echo "[`date`] MarkIlluminaAdapters is incomplete, likely due to this job having previously failed. Removing 02-MarkIlluminaAdapters directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./02-MarkIlluminaAdapters
			fi			
			echo "[`date`] MarkIlluminaAdapters started" >> "$SAMPLE"_vda_log.txt
			mkdir ./02-MarkIlluminaAdapters

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_markilluminaadapters_metrics.txt &

			wait

			if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ]
			then 
				echo "[`date`] MarkIlluminaAdapters completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "5" ]
	then
		if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam ] 
		then 
			echo "[`date`] MarkIlluminaAdapters already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./02-MarkIlluminaAdapters ]
			then
				echo "[`date`] MarkIlluminaAdapters is incomplete, likely due to this job having previously failed. Removing 02-MarkIlluminaAdapters directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./02-MarkIlluminaAdapters
			fi			
			echo "[`date`] MarkIlluminaAdapters started" >> "$SAMPLE"_vda_log.txt
			mkdir ./02-MarkIlluminaAdapters

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_markilluminaadapters_metrics.txt &

			wait

			if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam ]
			then 
				echo "[`date`] MarkIlluminaAdapters completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "6" ]
	then
		if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam ] 
		then 
			echo "[`date`] MarkIlluminaAdapters already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./02-MarkIlluminaAdapters ]
			then
				echo "[`date`] MarkIlluminaAdapters is incomplete, likely due to this job having previously failed. Removing 02-MarkIlluminaAdapters directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./02-MarkIlluminaAdapters
			fi			
			echo "[`date`] MarkIlluminaAdapters started" >> "$SAMPLE"_vda_log.txt
			mkdir ./02-MarkIlluminaAdapters

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_markilluminaadapters_metrics.txt &

			wait

			if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam ]
			then 
				echo "[`date`] MarkIlluminaAdapters completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "7" ]
	then
		if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_unmapped_markilluminaadapters.bam ] 
		then 
			echo "[`date`] MarkIlluminaAdapters already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./02-MarkIlluminaAdapters ]
			then
				echo "[`date`] MarkIlluminaAdapters is incomplete, likely due to this job having previously failed. Removing 02-MarkIlluminaAdapters directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./02-MarkIlluminaAdapters
			fi			
			echo "[`date`] MarkIlluminaAdapters started" >> "$SAMPLE"_vda_log.txt
			mkdir ./02-MarkIlluminaAdapters

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_markilluminaadapters_metrics.txt &

			wait

			if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_unmapped_markilluminaadapters.bam ]
			then 
				echo "[`date`] MarkIlluminaAdapters completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "8" ]
	then
		if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_unmapped_markilluminaadapters.bam ] &&
		   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L008_unmapped_markilluminaadapters.bam ] 
		then 
			echo "[`date`] MarkIlluminaAdapters already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./02-MarkIlluminaAdapters ]
			then
				echo "[`date`] MarkIlluminaAdapters is incomplete, likely due to this job having previously failed. Removing 02-MarkIlluminaAdapters directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./02-MarkIlluminaAdapters
			fi			
			echo "[`date`] MarkIlluminaAdapters started" >> "$SAMPLE"_vda_log.txt
			mkdir ./02-MarkIlluminaAdapters

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_markilluminaadapters_metrics.txt &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" MarkIlluminaAdapters \
			--INPUT ./01-FastqToSam/"$SAMPLE"_L008_unmapped.bam \
			--OUTPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L008_unmapped_markilluminaadapters.bam \
			--METRICS ./02-MarkIlluminaAdapters/"$SAMPLE"_L008_markilluminaadapters_metrics.txt &

			wait

			if [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_unmapped_markilluminaadapters.bam ] &&
			   [ -f ./02-MarkIlluminaAdapters/"$SAMPLE"_L008_unmapped_markilluminaadapters.bam ] 
			then 
				echo "[`date`] MarkIlluminaAdapters completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkIlluminaAdapters failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

#03-SamToFastq
	# Convert uBAM to fastq and discount adapter sequences
	if [ $NUM_LANES = "1" ]
	then
		if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] 
		then 
			echo "[`date`] SamToFastq already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./03-SamToFastq ]
			then
				echo "[`date`] SamToFastq is incomplete, likely due to this job having previously failed. Removing 03-SamToFastq directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./03-SamToFastq
			fi
			echo "[`date`] SamToFastq started" >> "$SAMPLE"_vda_log.txt
			mkdir ./03-SamToFastq

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true

			if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ]
			then 
				echo "[`date`] SamToFastq completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "2" ]
	then
		if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] 
		then 
			echo "[`date`] SamToFastq already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./03-SamToFastq ]
			then
				echo "[`date`] SamToFastq is incomplete, likely due to this job having previously failed. Removing 03-SamToFastq directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./03-SamToFastq
			fi
			echo "[`date`] SamToFastq started" >> "$SAMPLE"_vda_log.txt
			mkdir ./03-SamToFastq

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			wait 

			if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ]
			then 
				echo "[`date`] SamToFastq completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "3" ]
	then
		if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] 
		then 
			echo "[`date`] SamToFastq already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./03-SamToFastq ]
			then
				echo "[`date`] SamToFastq is incomplete, likely due to this job having previously failed. Removing 03-SamToFastq directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./03-SamToFastq
			fi
			echo "[`date`] SamToFastq started" >> "$SAMPLE"_vda_log.txt
			mkdir ./03-SamToFastq

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			wait 

			if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ]
			then 
				echo "[`date`] SamToFastq completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "4" ]
	then
		if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ] 
		then 
			echo "[`date`] SamToFastq already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./03-SamToFastq ]
			then
				echo "[`date`] SamToFastq is incomplete, likely due to this job having previously failed. Removing 03-SamToFastq directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./03-SamToFastq
			fi
			echo "[`date`] SamToFastq started" >> "$SAMPLE"_vda_log.txt
			mkdir ./03-SamToFastq

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			wait 

			if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ]
			then 
				echo "[`date`] SamToFastq completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "5" ]
	then
		if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq ] 
		then 
			echo "[`date`] SamToFastq already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./03-SamToFastq ]
			then
				echo "[`date`] SamToFastq is incomplete, likely due to this job having previously failed. Removing 03-SamToFastq directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./03-SamToFastq
			fi
			echo "[`date`] SamToFastq started" >> "$SAMPLE"_vda_log.txt
			mkdir ./03-SamToFastq

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			wait 

			if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq ]
			then 
				echo "[`date`] SamToFastq completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "6" ]
	then
		if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq ] 
		then 
			echo "[`date`] SamToFastq already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./03-SamToFastq ]
			then
				echo "[`date`] SamToFastq is incomplete, likely due to this job having previously failed. Removing 03-SamToFastq directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./03-SamToFastq
			fi
			echo "[`date`] SamToFastq started" >> "$SAMPLE"_vda_log.txt
			mkdir ./03-SamToFastq

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			wait 

			if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq ]
			then 
				echo "[`date`] SamToFastq completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "7" ]
	then
		if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved.fq ] 
		then 
			echo "[`date`] SamToFastq already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./03-SamToFastq ]
			then
				echo "[`date`] SamToFastq is incomplete, likely due to this job having previously failed. Removing 03-SamToFastq directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./03-SamToFastq
			fi
			echo "[`date`] SamToFastq started" >> "$SAMPLE"_vda_log.txt
			mkdir ./03-SamToFastq

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			wait 

			if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved.fq ]
			then 
				echo "[`date`] SamToFastq completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "8" ]
	then
		if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved.fq ] &&
		   [ -f ./03-SamToFastq/"$SAMPLE"_L008_unmapped_markilluminaadapters_interleaved.fq ] 
		then 
			echo "[`date`] SamToFastq already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./03-SamToFastq ]
			then
				echo "[`date`] SamToFastq is incomplete, likely due to this job having previously failed. Removing 03-SamToFastq directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./03-SamToFastq
			fi
			echo "[`date`] SamToFastq started" >> "$SAMPLE"_vda_log.txt
			mkdir ./03-SamToFastq

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L001_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L002_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L003_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L004_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L005_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L006_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L007_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			srun -c 1 --mem 3G "$PATH_TO_GATK4"/gatk --java-options "-Xmx3G" SamToFastq \
			--INPUT ./02-MarkIlluminaAdapters/"$SAMPLE"_L008_unmapped_markilluminaadapters.bam \
			--FASTQ ./03-SamToFastq/"$SAMPLE"_L008_unmapped_markilluminaadapters_interleaved.fq \
			--CLIPPING_ATTRIBUTE XT \
			--CLIPPING_ACTION 2 \
			--INTERLEAVE true \
			--INCLUDE_NON_PF_READS true &

			wait 

			if [ -f ./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved.fq ] &&
			   [ -f ./03-SamToFastq/"$SAMPLE"_L008_unmapped_markilluminaadapters_interleaved.fq ]
			then 
				echo "[`date`] SamToFastq completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SamToFastq failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

#04-BwaMem
	# Align reads and flag secondary hits
	REFERENCE_GENOME_PREFIX=$(echo "$REFERENCE_GENOME" | sed 's/.fasta//' | sed 's/.fa//')
	if [ $NUM_LANES = "1" ]
	then
		if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ]
		then 
			echo "[`date`] BwaMem already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./04-BwaMem ]
			then
				echo "[`date`] BwaMem is incomplete, likely due to this job having previously failed. Removing 04-BwaMem directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./04-BwaMem
			fi			
			echo "[`date`] BwaMem started" >> "$SAMPLE"_vda_log.txt
			mkdir ./04-BwaMem
		
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam

			if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ]
			then 
				echo "[`date`] BwaMem completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "2" ]
	then
		if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
		then 
			echo "[`date`] BwaMem already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./04-BwaMem ]
			then
				echo "[`date`] BwaMem is incomplete, likely due to this job having previously failed. Removing 04-BwaMem directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./04-BwaMem
			fi			
			echo "[`date`] BwaMem started" >> "$SAMPLE"_vda_log.txt
			mkdir ./04-BwaMem
		
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam

			if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ]
			then 
				echo "[`date`] BwaMem completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "3" ]
	then
		if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
		then 
			echo "[`date`] BwaMem already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./04-BwaMem ]
			then
				echo "[`date`] BwaMem is incomplete, likely due to this job having previously failed. Removing 04-BwaMem directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./04-BwaMem
			fi			
			echo "[`date`] BwaMem started" >> "$SAMPLE"_vda_log.txt
			mkdir ./04-BwaMem
		
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam

			if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ]
			then 
				echo "[`date`] BwaMem completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "4" ]
	then
		if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
		then 
			echo "[`date`] BwaMem already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./04-BwaMem ]
			then
				echo "[`date`] BwaMem is incomplete, likely due to this job having previously failed. Removing 04-BwaMem directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./04-BwaMem
			fi			
			echo "[`date`] BwaMem started" >> "$SAMPLE"_vda_log.txt
			mkdir ./04-BwaMem
		
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam

			if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ]
			then 
				echo "[`date`] BwaMem completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "5" ]
	then
		if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
		then 
			echo "[`date`] BwaMem already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./04-BwaMem ]
			then
				echo "[`date`] BwaMem is incomplete, likely due to this job having previously failed. Removing 04-BwaMem directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./04-BwaMem
			fi			
			echo "[`date`] BwaMem started" >> "$SAMPLE"_vda_log.txt
			mkdir ./04-BwaMem
		
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sa
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam

			if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
			then 
				echo "[`date`] BwaMem completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "6" ]
	then
		if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
		then 
			echo "[`date`] BwaMem already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./04-BwaMem ]
			then
				echo "[`date`] BwaMem is incomplete, likely due to this job having previously failed. Removing 04-BwaMem directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./04-BwaMem
			fi			
			echo "[`date`] BwaMem started" >> "$SAMPLE"_vda_log.txt
			mkdir ./04-BwaMem
		
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sa

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam

			if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
			then 
				echo "[`date`] BwaMem completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "7" ]
	then
		if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
		then 
			echo "[`date`] BwaMem already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./04-BwaMem ]
			then
				echo "[`date`] BwaMem is incomplete, likely due to this job having previously failed. Removing 04-BwaMem directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./04-BwaMem
			fi			
			echo "[`date`] BwaMem started" >> "$SAMPLE"_vda_log.txt
			mkdir ./04-BwaMem
		
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved_aligned.sam

			if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
			then 
				echo "[`date`] BwaMem completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "8" ]
	then
		if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
		   [ -f ./04-BwaMem/"$SAMPLE"_L008_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
		then 
			echo "[`date`] BwaMem already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./04-BwaMem ]
			then
				echo "[`date`] BwaMem is incomplete, likely due to this job having previously failed. Removing 04-BwaMem directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./04-BwaMem
			fi			
			echo "[`date`] BwaMem started" >> "$SAMPLE"_vda_log.txt
			mkdir ./04-BwaMem
		
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam

			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved_aligned.sam
			
			srun -c "$MAX_CORES" --mem 12G "$PATH_TO_BWA"/bwa mem \
			-M \
			-t "$MAX_CORES" \
			-p \
			$REFERENCE_GENOME_PREFIX \
			./03-SamToFastq/"$SAMPLE"_L008_unmapped_markilluminaadapters_interleaved.fq > \
			./04-BwaMem/"$SAMPLE"_L008_unmapped_markilluminaadapters_interleaved_aligned.sam

			if [ -f ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved_aligned.sam ] &&
			   [ -f ./04-BwaMem/"$SAMPLE"_L008_unmapped_markilluminaadapters_interleaved_aligned.sam ] 
			then 
				echo "[`date`] BwaMem completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: BwaMem failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

#05-MergeBamAlignment
	# Restore altered data, and apply & adjust meta information
	if [ $NUM_LANES = "1" ]
	then
		if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ]
		then 
			echo "[`date`] MergeBamAlignment already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./05-MergeBamAlignment ]
			then
				echo "[`date`] MergeBamAlignment is incomplete, likely due to this job having previously failed. Removing 05-MergeBamAlignment directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./05-MergeBamAlignment
			fi			
			echo "[`date`] MergeBamAlignment started" >> "$SAMPLE"_vda_log.txt
			mkdir ./05-MergeBamAlignment

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true
						
			if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ]
			then 
				echo "[`date`] MergeBamAlignment completed" >> "$SAMPLE"_vda_log.txt;
			else 
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt;
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi	

	if [ $NUM_LANES = "2" ]
	then
		if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ]
		then 
			echo "[`date`] MergeBamAlignment already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./05-MergeBamAlignment ]
			then
				echo "[`date`] MergeBamAlignment is incomplete, likely due to this job having previously failed. Removing 05-MergeBamAlignment directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./05-MergeBamAlignment
			fi			
			echo "[`date`] MergeBamAlignment started" >> "$SAMPLE"_vda_log.txt
			mkdir ./05-MergeBamAlignment

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &

			wait			

			if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ]
			then 
				echo "[`date`] MergeBamAlignment completed" >> "$SAMPLE"_vda_log.txt;
			else 
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt;
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi	

	if [ $NUM_LANES = "3" ]
	then
		if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ]
		then 
			echo "[`date`] MergeBamAlignment already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./05-MergeBamAlignment ]
			then
				echo "[`date`] MergeBamAlignment is incomplete, likely due to this job having previously failed. Removing 05-MergeBamAlignment directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./05-MergeBamAlignment
			fi			
			echo "[`date`] MergeBamAlignment started" >> "$SAMPLE"_vda_log.txt
			mkdir ./05-MergeBamAlignment

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &

			wait			

			if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ]
			then 
				echo "[`date`] MergeBamAlignment completed" >> "$SAMPLE"_vda_log.txt;
			else 
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt;
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi	

	if [ $NUM_LANES = "4" ]
	then
		if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ]
		then 
			echo "[`date`] MergeBamAlignment already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./05-MergeBamAlignment ]
			then
				echo "[`date`] MergeBamAlignment is incomplete, likely due to this job having previously failed. Removing 05-MergeBamAlignment directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./05-MergeBamAlignment
			fi			
			echo "[`date`] MergeBamAlignment started" >> "$SAMPLE"_vda_log.txt
			mkdir ./05-MergeBamAlignment

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &

			wait			

			if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ]
			then 
				echo "[`date`] MergeBamAlignment completed" >> "$SAMPLE"_vda_log.txt;
			else 
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt;
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi	

	if [ $NUM_LANES = "5" ]
	then
		if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam ]
		then 
			echo "[`date`] MergeBamAlignment already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./05-MergeBamAlignment ]
			then
				echo "[`date`] MergeBamAlignment is incomplete, likely due to this job having previously failed. Removing 05-MergeBamAlignment directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./05-MergeBamAlignment
			fi			
			echo "[`date`] MergeBamAlignment started" >> "$SAMPLE"_vda_log.txt
			mkdir ./05-MergeBamAlignment

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			wait			

			if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam ]
			then 
				echo "[`date`] MergeBamAlignment completed" >> "$SAMPLE"_vda_log.txt;
			else 
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt;
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi	

	if [ $NUM_LANES = "6" ]
	then
		if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam ]
		then 
			echo "[`date`] MergeBamAlignment already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./05-MergeBamAlignment ]
			then
				echo "[`date`] MergeBamAlignment is incomplete, likely due to this job having previously failed. Removing 05-MergeBamAlignment directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./05-MergeBamAlignment
			fi			
			echo "[`date`] MergeBamAlignment started" >> "$SAMPLE"_vda_log.txt
			mkdir ./05-MergeBamAlignment

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			wait			

			if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam ]
			then 
				echo "[`date`] MergeBamAlignment completed" >> "$SAMPLE"_vda_log.txt;
			else 
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt;
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi	

	if [ $NUM_LANES = "7" ]
	then
		if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L007_mapped_clean.bam ]
		then 
			echo "[`date`] MergeBamAlignment already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./05-MergeBamAlignment ]
			then
				echo "[`date`] MergeBamAlignment is incomplete, likely due to this job having previously failed. Removing 05-MergeBamAlignment directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./05-MergeBamAlignment
			fi			
			echo "[`date`] MergeBamAlignment started" >> "$SAMPLE"_vda_log.txt
			mkdir ./05-MergeBamAlignment

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			wait

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L007_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &

			wait			

			if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L007_mapped_clean.bam ]
			then 
				echo "[`date`] MergeBamAlignment completed" >> "$SAMPLE"_vda_log.txt;
			else 
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt;
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi	

	if [ $NUM_LANES = "8" ]
	then
		if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L007_mapped_clean.bam ] &&
		   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L008_mapped_clean.bam ]
		then 
			echo "[`date`] MergeBamAlignment already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./05-MergeBamAlignment ]
			then
				echo "[`date`] MergeBamAlignment is incomplete, likely due to this job having previously failed. Removing 05-MergeBamAlignment directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./05-MergeBamAlignment
			fi			
			echo "[`date`] MergeBamAlignment started" >> "$SAMPLE"_vda_log.txt
			mkdir ./05-MergeBamAlignment

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L001_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L001_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L002_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L002_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L003_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L003_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L004_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L004_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			wait

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L005_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L005_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L006_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L006_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L007_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L007_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L007_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeBamAlignment \
			--ALIGNED_BAM ./04-BwaMem/"$SAMPLE"_L008_unmapped_markilluminaadapters_interleaved_aligned.sam \
			--UNMAPPED_BAM ./01-FastqToSam/"$SAMPLE"_L008_unmapped.bam \
			--OUTPUT ./05-MergeBamAlignment/"$SAMPLE"_L008_mapped_clean.bam \
			--REFERENCE_SEQUENCE $REFERENCE_GENOME \
			--ADD_MATE_CIGAR true \
			--CLIP_ADAPTERS false \
			--CLIP_OVERLAPPING_READS true \
			--INCLUDE_SECONDARY_ALIGNMENTS true \
			--MAX_INSERTIONS_OR_DELETIONS -1 \
			--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
			--ATTRIBUTES_TO_RETAIN XS \
			--CREATE_INDEX true &
			
			wait			

			if [ -f ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L007_mapped_clean.bam ] &&
			   [ -f ./05-MergeBamAlignment/"$SAMPLE"_L008_mapped_clean.bam ]
			then 
				echo "[`date`] MergeBamAlignment completed" >> "$SAMPLE"_vda_log.txt;
			else 
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt;
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeBamAlignment failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi	

#06-MarkDuplicates
	# Mark duplicates per lane to flag optical duplicates and estimate lane-level library complexity, then mark duplicates a second time to merge data per sample and mark library duplicates
	if [ $NUM_LANES = "1" ]
	then
		if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ] 
		then 
			echo "[`date`] MarkDuplicates already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./06-MarkDuplicates ]
			then
				echo "[`date`] MarkDuplicates is incomplete, likely due to this job having previously failed. Removing 06-MarkDuplicates directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./06-MarkDuplicates
			fi
			echo "[`date`] MarkDuplicates started" >> "$SAMPLE"_vda_log.txt
			mkdir ./06-MarkDuplicates

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_merged_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true

			if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ]
			then 
				echo "[`date`] MarkDuplicates completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "2" ]
	then
		if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ] 
		then 
			echo "[`date`] MarkDuplicates already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./06-MarkDuplicates ]
			then
				echo "[`date`] MarkDuplicates is incomplete, likely due to this job having previously failed. Removing 06-MarkDuplicates directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./06-MarkDuplicates
			fi
			echo "[`date`] MarkDuplicates started" >> "$SAMPLE"_vda_log.txt
			mkdir ./06-MarkDuplicates

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L001_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L002_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" MarkDuplicates \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_merged_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true

			if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ]
			then 
				echo "[`date`] MarkDuplicates completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "3" ]
	then
		if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ] 
		then 
			echo "[`date`] MarkDuplicates already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./06-MarkDuplicates ]
			then
				echo "[`date`] MarkDuplicates is incomplete, likely due to this job having previously failed. Removing 06-MarkDuplicates directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./06-MarkDuplicates
			fi
			echo "[`date`] MarkDuplicates started" >> "$SAMPLE"_vda_log.txt
			mkdir ./06-MarkDuplicates

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L001_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L002_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L003_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" MarkDuplicates \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_merged_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true

			if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ]
			then 
				echo "[`date`] MarkDuplicates completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "4" ]
	then
		if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ] 
		then 
			echo "[`date`] MarkDuplicates already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./06-MarkDuplicates ]
			then
				echo "[`date`] MarkDuplicates is incomplete, likely due to this job having previously failed. Removing 06-MarkDuplicates directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./06-MarkDuplicates
			fi
			echo "[`date`] MarkDuplicates started" >> "$SAMPLE"_vda_log.txt
			mkdir ./06-MarkDuplicates

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L001_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L002_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L003_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L004_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" MarkDuplicates \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_merged_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true

			if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ]
			then 
				echo "[`date`] MarkDuplicates completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "5" ]
	then
		if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ] 
		then 
			echo "[`date`] MarkDuplicates already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./06-MarkDuplicates ]
			then
				echo "[`date`] MarkDuplicates is incomplete, likely due to this job having previously failed. Removing 06-MarkDuplicates directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./06-MarkDuplicates
			fi
			echo "[`date`] MarkDuplicates started" >> "$SAMPLE"_vda_log.txt
			mkdir ./06-MarkDuplicates

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L001_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L002_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L003_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L004_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L005_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L005_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" MarkDuplicates \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L005_mapped_clean_dedup.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_merged_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true

			if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ]
			then 
				echo "[`date`] MarkDuplicates completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "6" ]
	then
		if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ] 
		then 
			echo "[`date`] MarkDuplicates already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./06-MarkDuplicates ]
			then
				echo "[`date`] MarkDuplicates is incomplete, likely due to this job having previously failed. Removing 06-MarkDuplicates directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./06-MarkDuplicates
			fi
			echo "[`date`] MarkDuplicates started" >> "$SAMPLE"_vda_log.txt
			mkdir ./06-MarkDuplicates

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L001_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L002_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L003_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L004_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L005_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L005_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L006_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L006_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" MarkDuplicates \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L005_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L006_mapped_clean_dedup.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_merged_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true

			if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ]
			then 
				echo "[`date`] MarkDuplicates completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "7" ]
	then
		if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ] 
		then 
			echo "[`date`] MarkDuplicates already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./06-MarkDuplicates ]
			then
				echo "[`date`] MarkDuplicates is incomplete, likely due to this job having previously failed. Removing 06-MarkDuplicates directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./06-MarkDuplicates
			fi
			echo "[`date`] MarkDuplicates started" >> "$SAMPLE"_vda_log.txt
			mkdir ./06-MarkDuplicates

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L001_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L002_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L003_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L004_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L005_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L005_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L006_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L006_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L007_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L007_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L007_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" MarkDuplicates \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L005_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L006_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L007_mapped_clean_dedup.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_merged_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true

			if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ]
			then 
				echo "[`date`] MarkDuplicates completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

	if [ $NUM_LANES = "8" ]
	then
		if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ] 
		then 
			echo "[`date`] MarkDuplicates already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./06-MarkDuplicates ]
			then
				echo "[`date`] MarkDuplicates is incomplete, likely due to this job having previously failed. Removing 06-MarkDuplicates directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./06-MarkDuplicates
			fi
			echo "[`date`] MarkDuplicates started" >> "$SAMPLE"_vda_log.txt
			mkdir ./06-MarkDuplicates

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L001_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L001_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L002_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L002_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L003_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L003_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L004_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L004_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L005_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L005_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L005_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L006_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L006_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L006_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L007_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L007_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L007_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" MarkDuplicates \
			--INPUT ./05-MergeBamAlignment/"$SAMPLE"_L008_mapped_clean.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_L008_mapped_clean_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_L008_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true &

			wait

			srun -c 1 --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" MarkDuplicates \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L001_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L002_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L003_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L004_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L005_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L006_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L007_mapped_clean_dedup.bam \
			--INPUT ./06-MarkDuplicates/"$SAMPLE"_L008_mapped_clean_dedup.bam \
			--OUTPUT ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
			--METRICS_FILE ./06-MarkDuplicates/"$SAMPLE"_merged_markduplicates_metrics.txt \
			--OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
			--CREATE_INDEX true

			if [ -f ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam ]
			then 
				echo "[`date`] MarkDuplicates completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MarkDuplicates failed. Check variant_discovery_analysis.err for details"
				exit 1  		
			fi
		fi
	fi

#07-HaplotypeCallerBootstrap
	# Call variants to be used in base recalibration
	if [ -f ./07-HaplotypeCallerBootstrap/"$SAMPLE"_merged_dedup_raw_variants.vcf ] 
	then 
		echo "[`date`] HaplotypeCallerBootstrap already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./07-HaplotypeCallerBootstrap ]
		then
			echo "[`date`] HaplotypeCallerBootstrap is incomplete, likely due to this job having previously failed. Removing 07-HaplotypeCallerBootstrap directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./07-HaplotypeCallerBootstrap
		fi
		echo "[`date`] HaplotypeCallerBootstrap started" >> "$SAMPLE"_vda_log.txt
		mkdir ./07-HaplotypeCallerBootstrap
		
		if [ $LINKED_DE_BRUIJN_GRAPH = "false" ]
		then
			srun -c "$MAX_CORES" --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"g" HaplotypeCaller \
			--native-pair-hmm-threads "$MAX_CORES" \
			--reference $REFERENCE_GENOME \
			--input ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
			--minimum-mapping-quality 30 \
			--read-filter MappingQualityReadFilter \
			--min-base-quality-score 30 \
			--standard-min-confidence-threshold-for-calling 30 \
			--output ./07-HaplotypeCallerBootstrap/"$SAMPLE"_merged_dedup_raw_variants.vcf
		else
			if [ $LINKED_DE_BRUIJN_GRAPH = "true" ]
			then
				srun -c "$MAX_CORES" --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"g" HaplotypeCaller \
				--linked-de-bruijn-graph \
				--native-pair-hmm-threads "$MAX_CORES" \
				--reference $REFERENCE_GENOME \
				--input ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
				--minimum-mapping-quality 30 \
				--read-filter MappingQualityReadFilter \
				--min-base-quality-score 30 \
				--standard-min-confidence-threshold-for-calling 30 \
				--output ./07-HaplotypeCallerBootstrap/"$SAMPLE"_merged_dedup_raw_variants.vcf
			fi
		fi

		if [ -f ./07-HaplotypeCallerBootstrap/"$SAMPLE"_merged_dedup_raw_variants.vcf ]
		then 
			echo "[`date`] HaplotypeCallerBootstrap completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: HaplotypeCallerBootstrap failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: HaplotypeCallerBootstrap failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#08-SelectVariantsBootstrap
	# Filter and select variants to be used in base recalibration
	if [ -f ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_snps_for_BQSR.vcf ] &&
	   [ -f ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_indels_for_BQSR.vcf ]
	then 
		echo "[`date`] SelectVariantsBootstrap already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./08-SelectVariantsBootstrap ]
		then
			echo "[`date`] SelectVariantsBootstrap is incomplete, likely due to this job having previously failed. Removing 08-SelectVariantsBootstrap directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./08-SelectVariantsBootstrap
		fi		
		echo "[`date`] SelectVariantsBootstrap started" >> "$SAMPLE"_vda_log.txt
		mkdir ./08-SelectVariantsBootstrap

		# filter blacklisted variants
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" VariantFiltration \
		--reference $REFERENCE_GENOME \
		--variant ./07-HaplotypeCallerBootstrap/"$SAMPLE"_merged_dedup_raw_variants.vcf \
		--mask "$BLACKLISTED_VARIANTS" \
		--mask-name 'Blacklisted' \
		--output ./08-SelectVariantsBootstrap/"$SAMPLE"_merged_dedup_raw_variants_blacklisted.vcf

		# extract SNPs		
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
		--reference $REFERENCE_GENOME \
		--variant ./08-SelectVariantsBootstrap/"$SAMPLE"_merged_dedup_raw_variants_blacklisted.vcf \
		--select-type-to-include SNP \
		--output ./08-SelectVariantsBootstrap/"$SAMPLE"_raw_snps_for_BQSR.vcf

		# apply a stringent filter on SNPs				
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" VariantFiltration \
		--reference $REFERENCE_GENOME \
		--variant ./08-SelectVariantsBootstrap/"$SAMPLE"_raw_snps_for_BQSR.vcf \
		--filter-expression 'QD < 9.0' \
		--filter-name 'QD' \
		--filter-expression 'FS > 10.0' \
		--filter-name 'FS' \
		--filter-expression 'MQ < 55.0' \
		--filter-name 'MQ' \
		--filter-expression 'SOR > 3.0' \
		--filter-name 'SOR' \
		--filter-expression 'MQRankSum < -2.5' \
		--filter-name 'MQRankSum' \
		--filter-expression 'ReadPosRankSum < -1.0' \
		--filter-name 'ReadPosRankSum' \
		--output ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_snps_for_BQSR.vcf

		# remove SNPs that have been filtered						
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
		--reference $REFERENCE_GENOME \
		--variant ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_snps_for_BQSR.vcf \
		--selectExpressions 'vc.isNotFiltered()' \
		--output ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_snps_for_BQSR.vcf

		# extract indels				
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
		--reference $REFERENCE_GENOME \
		--variant ./08-SelectVariantsBootstrap/"$SAMPLE"_merged_dedup_raw_variants_blacklisted.vcf \
		--select-type-to-include INDEL \
		--output ./08-SelectVariantsBootstrap/"$SAMPLE"_raw_indels_for_BQSR.vcf

		# apply a stringent filter on indels						
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" VariantFiltration \
		--reference $REFERENCE_GENOME \
		--variant ./08-SelectVariantsBootstrap/"$SAMPLE"_raw_indels_for_BQSR.vcf \
		--filter-expression 'QD < 9.0' \
		--filter-name 'QD' \
		--filter-expression 'FS > 10.0' \
		--filter-name 'FS' \
		--filter-expression 'SOR > 3.0' \
		--filter-name 'SOR' \
		--filter-expression 'ReadPosRankSum < -1.0' \
		--filter-name 'ReadPosRankSum' \
		--output ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_indels_for_BQSR.vcf

		# remove indels that have been filtered								
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
		--reference $REFERENCE_GENOME \
		--variant ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_indels_for_BQSR.vcf \
		--selectExpressions 'vc.isNotFiltered()' \
		--output ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_indels_for_BQSR.vcf

		if [ -f ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_snps_for_BQSR.vcf ] &&
		   [ -f ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_indels_for_BQSR.vcf ]
		then 
			echo "[`date`] SelectVariantsBootstrap completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: SelectVariantsBootstrap failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: SelectVariantsBootstrap failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#09-BaseRecalibrator
	# Analyze patterns of covariation in the sequence dataset
	if [ -f ./09-BaseRecalibrator/"$SAMPLE"_recal_data.table ]
	then 
		echo "[`date`] BaseRecalibrator already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./09-BaseRecalibrator ]
		then
			echo "[`date`] BaseRecalibrator is incomplete, likely due to this job having previously failed. Removing 09-BaseRecalibrator directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./09-BaseRecalibrator
		fi		
		echo "[`date`] BaseRecalibrator started" >> "$SAMPLE"_vda_log.txt
		mkdir ./09-BaseRecalibrator

		srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" BaseRecalibrator \
		--reference $REFERENCE_GENOME \
		--input ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
		--known-sites ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_snps_for_BQSR.vcf \
		--known-sites ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_indels_for_BQSR.vcf \
		--output ./09-BaseRecalibrator/"$SAMPLE"_recal_data.table

		if [ -f ./09-BaseRecalibrator/"$SAMPLE"_recal_data.table ]
		then 
			echo "[`date`] BaseRecalibrator completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: BaseRecalibrator failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: BaseRecalibrator failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#10-ApplyBQSR
	# Apply the recalibration
	if [ -f ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam ] 
	then 
		echo "[`date`] ApplyBQSR already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./10-ApplyBQSR ]
		then
			echo "[`date`] ApplyBQSR is incomplete, likely due to this job having previously failed. Removing 10-ApplyBQSR directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./10-ApplyBQSR
		fi
		echo "[`date`] ApplyBQSR started" >> "$SAMPLE"_vda_log.txt
		mkdir ./10-ApplyBQSR

		srun -c 1 --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" ApplyBQSR \
		--reference $REFERENCE_GENOME \
		--input ./06-MarkDuplicates/"$SAMPLE"_merged_dedup.bam \
		--bqsr-recal-file ./09-BaseRecalibrator/"$SAMPLE"_recal_data.table \
		--output ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam

		if [ -f ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam ]
		then 
			echo "[`date`] ApplyBQSR completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: ApplyBQSR failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: ApplyBQSR failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#11-AnalyzeCovariates
	# Analyze covariation remaining after recalibration
	if [ -f ./11-AnalyzeCovariates/"$SAMPLE"_recalibration_plots.pdf ] 
	then 
		echo "[`date`] AnalyzeCovariates already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./11-AnalyzeCovariates ]
		then
			echo "[`date`] AnalyzeCovariates is incomplete, likely due to this job having previously failed. Removing 11-AnalyzeCovariates directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./11-AnalyzeCovariates
		fi		
		echo "[`date`] AnalyzeCovariates started" >> "$SAMPLE"_vda_log.txt
		mkdir ./11-AnalyzeCovariates

		srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" BaseRecalibrator \
		--reference $REFERENCE_GENOME \
		--input ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
		--known-sites ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_snps_for_BQSR.vcf \
		--known-sites ./08-SelectVariantsBootstrap/"$SAMPLE"_filtered_passed_indels_for_BQSR.vcf \
		--output ./11-AnalyzeCovariates/"$SAMPLE"_post_recal_data.table
		
		srun -c 1 --mem 12G "$PATH_TO_GATK4"/gatk --java-options "-Xmx12G" AnalyzeCovariates \
		--before-report-file ./09-BaseRecalibrator/"$SAMPLE"_recal_data.table \
		--after-report-file ./11-AnalyzeCovariates/"$SAMPLE"_post_recal_data.table \
		--plots-report-file ./11-AnalyzeCovariates/"$SAMPLE"_recalibration_plots.pdf

		if [ -f ./11-AnalyzeCovariates/"$SAMPLE"_recalibration_plots.pdf ]
		then 
			echo "[`date`] AnalyzeCovariates completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: AnalyzeCovariates failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: AnalyzeCovariates failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#12-DetermineCoverage
	# Assess sequencing coverage
	if [ -f ./12-DetermineCoverage/"$SAMPLE"_coverage.bed ] &&
	   [ -f ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_final.txt ] &&
	   [ -f ./12-DetermineCoverage/"$SAMPLE"_genes_with_zero_coverage.txt ]
	then 
		echo "[`date`] DetermineCoverage already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./12-DetermineCoverage ]
		then
			echo "[`date`] DetermineCoverage is incomplete, likely due to this job having previously failed. Removing 12-DetermineCoverage directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./12-DetermineCoverage
		fi		
		echo "[`date`] DetermineCoverage started" >> "$SAMPLE"_vda_log.txt
		mkdir ./12-DetermineCoverage

		# Create a bed file of genome coverage
		srun -c 1 --mem 8G "$PATH_TO_BEDTOOLS2"/bedtools genomecov \
		-ibam ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
		-g $REFERENCE_GENOME \
		-bga \
		> ./12-DetermineCoverage/"$SAMPLE"_coverage.bed

		# Create a bed file of regions with zero coverage	
		grep -w 0$ ./12-DetermineCoverage/"$SAMPLE"_coverage.bed > ./12-DetermineCoverage/"$SAMPLE"_zero_coverage.bed

		# bed files are 0-based. gff files are 1-based. Add 1 to positions in bed file to make compatible with gff files		
		awk 'BEGIN {FS="\t"; OFS="\t"} {$2+=1}1 {$3+=1}1' ./12-DetermineCoverage/"$SAMPLE"_zero_coverage.bed > ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_1base.bed 
	
		# Determine which genome features fall within regions of zero coverage
		srun -c 1 --mem 8G "$PATH_TO_BEDTOOLS2"/bedtools intersect \
		-wb \
		-a ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_1base.bed \
		-b $ANNOTATIONS \
		> ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_1base_intersect_with_gff.txt
	
		# Filter for genes and organize output		
		awk 'BEGIN {FS="\t"; OFS="\t"} $7 == "gene" {print $0}' ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_1base_intersect_with_gff.txt | sed 's/;/\t/g' | sed 's/"/\t/g' | awk 'BEGIN {FS="\t"; OFS="\t"} {print $1 "\t" $2 "\t" $3 "\t" $17 "\t" $8 "\t" $9 "\t" $23}' > ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_1base_intersect_with_gff_reformatted.txt
	
		# Add header
		echo -e CHROM'\t'ZERO_COV_START'\t'ZERO_COV_END'\t'GENE_NAME'\t'GENE_START'\t'GENE_END'\t'GENE_BIOTYPE | cat - ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_1base_intersect_with_gff_reformatted.txt > ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_final.txt

		# Create a list of genes with zero coverage (light version... i.e. only gene names)		
		grep -v ZERO_COV_START ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_final.txt | awk '{print $4}' | sort | uniq -c | awk '{print $2}' > ./12-DetermineCoverage/"$SAMPLE"_genes_with_zero_coverage.txt

		if [ -f ./12-DetermineCoverage/"$SAMPLE"_coverage.bed ] &&
		   [ -f ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_final.txt ] &&
		   [ -f ./12-DetermineCoverage/"$SAMPLE"_genes_with_zero_coverage.txt ]
		then 
			echo "[`date`] DetermineCoverage completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: DetermineCoverage failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: DetermineCoverage failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#13-CollectWgsMetrics
	# Collect statistics on sequencing data
	if [ -f ./13-CollectWgsMetrics/"$SAMPLE"_merged_dedup_recal.bam.bc ] &&
	   [ -f ./13-CollectWgsMetrics/"$SAMPLE"_stats.txt ] &&
	   [ -f ./13-CollectWgsMetrics/"$SAMPLE"_CollectWgsMetricsWithNonZeroCoverage.txt ]
	then 
		echo "[`date`] CollectWgsMetrics already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./13-CollectWgsMetrics ]
		then
			echo "[`date`] CollectWgsMetrics is incomplete, likely due to this job having previously failed. Removing 13-CollectWgsMetrics directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./13-CollectWgsMetrics
		fi		
		echo "[`date`] CollectWgsMetrics started" >> "$SAMPLE"_vda_log.txt
		mkdir ./13-CollectWgsMetrics

		MAX_CORES_MINUS_ONE=$(echo ""$MAX_CORES" - 1" | bc)	

		# collect stats
		srun -c "$MAX_CORES" --mem 8G "$PATH_TO_SAMTOOLS"/samtools stats --threads "$MAX_CORES_MINUS_ONE" \
		./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam > ./13-CollectWgsMetrics/"$SAMPLE"_merged_dedup_recal.bam.bc
		
		cat ./13-CollectWgsMetrics/"$SAMPLE"_merged_dedup_recal.bam.bc | grep ^SN | cut -f 2- > ./13-CollectWgsMetrics/"$SAMPLE"_stats.txt
		
		"$PATH_TO_SAMTOOLS"/bin/plot-bamstats -p ./13-CollectWgsMetrics/"$SAMPLE"_plots/"$SAMPLE" ./13-CollectWgsMetrics/"$SAMPLE"_merged_dedup_recal.bam.bc
		
		length=$(grep "average length" ./13-CollectWgsMetrics/"$SAMPLE"_stats.txt | cut -f 2)
		
		# determine coverage
		srun -c 1 --mem 8G "$PATH_TO_GATK4"/gatk --java-options "-Xmx8G" CollectWgsMetricsWithNonZeroCoverage \
		--INPUT ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
		--OUTPUT ./13-CollectWgsMetrics/"$SAMPLE"_CollectWgsMetricsWithNonZeroCoverage.txt \
		--REFERENCE_SEQUENCE $REFERENCE_GENOME \
		--CHART_OUTPUT ./13-CollectWgsMetrics/"$SAMPLE"_CollectWgsMetricsWithNonZeroCoverage.pdf \
		--READ_LENGTH $length

		if [ -f ./13-CollectWgsMetrics/"$SAMPLE"_merged_dedup_recal.bam.bc ] &&
		   [ -f ./13-CollectWgsMetrics/"$SAMPLE"_stats.txt ] &&
		   [ -f ./13-CollectWgsMetrics/"$SAMPLE"_CollectWgsMetricsWithNonZeroCoverage.txt ]
		then 
			echo "[`date`] CollectWgsMetrics completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: CollectWgsMetrics failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: CollectWgsMetrics failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#14-HaplotypeCaller
	# Call SNVs and small indels
	if [ -f ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf ] 
	then 
		echo "[`date`] HaplotypeCaller already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./14-HaplotypeCaller ]
		then
			echo "[`date`] HaplotypeCaller is incomplete, likely due to this job having previously failed. Removing 14-HaplotypeCaller directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./14-HaplotypeCaller
		fi		
		echo "[`date`] HaplotypeCaller started" >> "$SAMPLE"_vda_log.txt
		mkdir ./14-HaplotypeCaller

		if [ $LINKED_DE_BRUIJN_GRAPH = "false" ]
		then
			srun -c "$MAX_CORES" --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" HaplotypeCaller \
			--native-pair-hmm-threads "$MAX_CORES" \
			--reference $REFERENCE_GENOME \
			--input ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
			--minimum-mapping-quality 10 \
			--read-filter MappingQualityReadFilter \
			--min-base-quality-score 10 \
			--standard-min-confidence-threshold-for-calling 10 \
			--output ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf
		else
			if [ $LINKED_DE_BRUIJN_GRAPH = "true" ]
			then
				srun -c "$MAX_CORES" --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" HaplotypeCaller \
				--linked-de-bruijn-graph \
				--native-pair-hmm-threads "$MAX_CORES" \
				--reference $REFERENCE_GENOME \
				--input ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
				--minimum-mapping-quality 10 \
				--read-filter MappingQualityReadFilter \
				--min-base-quality-score 10 \
				--standard-min-confidence-threshold-for-calling 10 \
				--output ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf
			fi
		fi

		if [ -f ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf ]
		then 
			echo "[`date`] HaplotypeCaller completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: HaplotypeCaller failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: HaplotypeCaller failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#15-Manta
	# Call structural variants
	if [ $READ_TYPE = "paired-end" ]
	then
		if [ -f ./15-Manta/"$SAMPLE"_manta_variants.vcf ] &&
		   [ -f ./15-Manta/MantaWorkflow/results/variants/diploidSV.vcf.gz ] &&
		   [ -f ./15-Manta/StrelkaWorkflow/results/variants/variants.vcf.gz ]
		then 
			echo "[`date`] Manta already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./15-Manta ]
			then
				echo "[`date`] Manta is incomplete, likely due to this job having previously failed. Removing 15-Manta directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./15-Manta
			fi			
			echo "[`date`] Manta started" >> "$SAMPLE"_vda_log.txt
			mkdir ./15-Manta
			
			# configure manta run
			srun -c 1 --mem 1G python "$PATH_TO_MANTA"/bin/configManta.py \
			--bam=./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
			--referenceFasta=$REFERENCE_GENOME \
			--runDir=./15-Manta/MantaWorkflow

			# run manta
			srun -c "$MAX_CORES" --mem "$MAX_MEM"G python ./15-Manta/MantaWorkflow/runWorkflow.py
			
			# convert inversions to INV format and remove translocations (BND)
			srun -c 1 --mem 1G python "$PATH_TO_MANTA"/libexec/convertInversion.py "$PATH_TO_SAMTOOLS"/samtools $REFERENCE_GENOME ./15-Manta/MantaWorkflow/results/variants/diploidSV.vcf.gz | grep -v BND > ./15-Manta/MantaWorkflow/results/variants/"$SAMPLE"_diploidSV_with_inv_without_bnd.vcf
			
			# configure strelka to use candidateSmallIndels output from manta
			srun -c 1 --mem 1G python "$PATH_TO_STRELKA"/bin/configureStrelkaGermlineWorkflow.py \
			--bam=./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
			--referenceFasta=$REFERENCE_GENOME \
			--runDir=./15-Manta/StrelkaWorkflow \
			--indelCandidates=./15-Manta/MantaWorkflow/results/variants/candidateSmallIndels.vcf.gz
			
			# run strelka
			srun -c "$MAX_CORES" --mem "$MAX_MEM"G python ./15-Manta/StrelkaWorkflow/runWorkflow.py -m local
			
			# select manta candidateSmallIndels from strelka output and keep only PASS variants
			srun -c 1 --mem 1G gunzip -c ./15-Manta/MantaWorkflow/results/variants/candidateSmallIndels.vcf.gz > ./15-Manta/MantaWorkflow/results/variants/candidateSmallIndels.vcf
			srun -c 1 --mem 1G grep -v '#' ./15-Manta/MantaWorkflow/results/variants/candidateSmallIndels.vcf | cut -f -2 | uniq > ./15-Manta/MantaWorkflow/results/variants/candidate_smallindel_variant_positions
			srun -c 1 --mem 1G gunzip -c ./15-Manta/StrelkaWorkflow/results/variants/variants.vcf.gz > ./15-Manta/StrelkaWorkflow/results/variants/variants.vcf
			srun -c 1 --mem 1G awk 'BEGIN {FS="\t"; OFS="\t"} NR==FNR{a[$1"\t"$2]=$0;next}{print $0 "\t" a[$1"\t"$2]}' ./15-Manta/MantaWorkflow/results/variants/candidate_smallindel_variant_positions ./15-Manta/StrelkaWorkflow/results/variants/variants.vcf | awk 'BEGIN {FS="\t"; OFS="\t"} $11 != ""' | awk 'BEGIN {FS="\t"; OFS="\t"} $7 == "PASS" {print $0}' > ./15-Manta/StrelkaWorkflow/results/variants/"$SAMPLE"_smallindel_variants_passed_without_header.vcf
			(grep '#' ./15-Manta/StrelkaWorkflow/results/variants/variants.vcf && cut -f -10 ./15-Manta/StrelkaWorkflow/results/variants/"$SAMPLE"_smallindel_variants_passed_without_header.vcf) > ./15-Manta/StrelkaWorkflow/results/variants/"$SAMPLE"_smallindel_variants.vcf

			# merge vcfs
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeVcfs \
		 	--INPUT ./15-Manta/MantaWorkflow/results/variants/"$SAMPLE"_diploidSV_with_inv_without_bnd.vcf \
		 	--INPUT ./15-Manta/StrelkaWorkflow/results/variants/"$SAMPLE"_smallindel_variants.vcf \
		 	--OUTPUT ./15-Manta/"$SAMPLE"_manta_variants.vcf
			
			if [ -f ./15-Manta/"$SAMPLE"_manta_variants.vcf ] &&
			   [ -f ./15-Manta/MantaWorkflow/results/variants/diploidSV.vcf.gz ] &&
			   [ -f ./15-Manta/StrelkaWorkflow/results/variants/variants.vcf.gz ]
			then 
				echo "[`date`] Manta completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: Manta failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: Manta failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

# If analysis mode is set to call-background-variants, then exit script
	if [ $WORKFLOW = "call-background-variants" ]
	then
		if [ $BACKGROUND_DIRECTORY = "." ] || [ $BACKGROUND_DIRECTORY = "./" ]
		then
			BACKGROUND_DIRECTORY="$(pwd)"
			BACKGROUND_DIRECTORY=${BACKGROUND_DIRECTORY%/*}
		fi

		if [ -f "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf ] &&
		   [ -f "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf.idx ]
		then 
			echo "[`date`] Copying background variant files to "$BACKGROUND_DIRECTORY" already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d "$BACKGROUND_DIRECTORY" ]
			then
				echo "[`date`] Found "$BACKGROUND_DIRECTORY" directory" >> "$SAMPLE"_vda_log.txt
			else
				echo "[`date`] "$BACKGROUND_DIRECTORY" directory doesn't exist. Making "$BACKGROUND_DIRECTORY" directory" >> "$SAMPLE"_vda_log.txt
				BACKGROUND_DIRECTORY=$(echo "$BACKGROUND_DIRECTORY" | sed 's/^[/]//')
				mkdir -p $BACKGROUND_DIRECTORY
				BACKGROUND_DIRECTORY=/"$BACKGROUND_DIRECTORY"				
			fi			
	
			echo "[`date`] Copying background variant files to "$BACKGROUND_DIRECTORY" started" >> "$SAMPLE"_vda_log.txt

			if [ $READ_TYPE = "paired-end" ]
			then
				echo "[`date`] Merging HaplotypeCaller and Manta variants" >> "$SAMPLE"_vda_log.txt
				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeVcfs \
				 --INPUT ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf \
				 --INPUT ./15-Manta/"$SAMPLE"_manta_variants.vcf \
				 --OUTPUT "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf
			fi

			if [ $READ_TYPE = "single-end" ]
			then
				cp ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf
				cp ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf.idx "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf.idx 
			fi
			
			if [ $CLEAN_UP = "true" ]
			then 
				echo "[`date`] CLEANING..." >> "$SAMPLE"_vda_log.txt
				mkdir ./results
				mv ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam ./results
				mv ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bai ./results
				mv ./11-AnalyzeCovariates/"$SAMPLE"_recalibration_plots.pdf ./results
				mv ./12-DetermineCoverage/"$SAMPLE"_coverage.bed ./results
				mv ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_final.txt ./results
				mv ./12-DetermineCoverage/"$SAMPLE"_genes_with_zero_coverage.txt ./results
				mv ./13-CollectWgsMetrics/"$SAMPLE"_stats.txt ./results
				mv ./13-CollectWgsMetrics/"$SAMPLE"_plots ./results
				mv ./13-CollectWgsMetrics/"$SAMPLE"_CollectWgsMetricsWithNonZeroCoverage.txt ./results
				cp "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf ./results
				cp "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf.idx ./results

				rm -rf $(ls -lh | awk -F " " '{print $9}' | awk -F "-" '$1 >= 0 {print $0}')	
			fi

			if [ -f "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf ] &&
			   [ -f "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf.idx ]
			then
				echo "[`date`] Copying background variant files to "$BACKGROUND_DIRECTORY" completed" >> "$SAMPLE"_vda_log.txt
				echo "[`date`] CALL-BACKGROUND-VARIANTS COMPLETE!" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] CALL-BACKGROUND-VARIANTS COMPLETE!"
				exit 0
			else
				echo "[`date`] ERROR: Copying background variant files to "$BACKGROUND_DIRECTORY" failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: Copying background variant files to "$BACKGROUND_DIRECTORY" failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi


# If analysis mode is set to call-mapping-variants, then finish compiling variants and then exit script
#16-HaplotypeCallerMappingVariants
	# Call mapping variants
	if [ $WORKFLOW = "call-mapping-variants" ]
	then
		if [ -f ./16-HaplotypeCallerMappingVariants/"$SAMPLE"_mapping_raw_variants.vcf ] 
		then 
			echo "[`date`] HaplotypeCallerMappingVariants already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./16-HaplotypeCallerMappingVariants ]
			then
				echo "[`date`] HaplotypeCallerMappingVariants is incomplete, likely due to this job having previously failed. Removing 16-HaplotypeCallerMappingVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./16-HaplotypeCallerMappingVariants
			fi			
			echo "[`date`] HaplotypeCallerMappingVariants started" >> "$SAMPLE"_vda_log.txt
			mkdir ./16-HaplotypeCallerMappingVariants

			if [ $LINKED_DE_BRUIJN_GRAPH = "false" ]
			then
				srun -c "$MAX_CORES" --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"g" HaplotypeCaller \
				--native-pair-hmm-threads "$MAX_CORES" \
				--reference $REFERENCE_GENOME \
				--input ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
				--minimum-mapping-quality 20 \
				--read-filter MappingQualityReadFilter \
				--min-base-quality-score 20 \
				--standard-min-confidence-threshold-for-calling 30 \
				--output ./16-HaplotypeCallerMappingVariants/"$SAMPLE"_mapping_raw_variants.vcf
			else
				if [ $LINKED_DE_BRUIJN_GRAPH = "true" ]
				then
					srun -c "$MAX_CORES" --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"g" HaplotypeCaller \
					--linked-de-bruijn-graph \
					--native-pair-hmm-threads "$MAX_CORES" \
					--reference $REFERENCE_GENOME \
					--input ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
					--minimum-mapping-quality 20 \
					--read-filter MappingQualityReadFilter \
					--min-base-quality-score 20 \
					--standard-min-confidence-threshold-for-calling 30 \
					--output ./16-HaplotypeCallerMappingVariants/"$SAMPLE"_mapping_raw_variants.vcf
				fi
			fi

			if [ -f ./16-HaplotypeCallerMappingVariants/"$SAMPLE"_mapping_raw_variants.vcf ]
			then 
				echo "[`date`] HaplotypeCallerMappingVariants completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: HaplotypeCallerMappingVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: HaplotypeCallerMappingVariants failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi	

#17-SelectMappingVariants
	# Filter and select variants to be used for mapping
	if [ $WORKFLOW = "call-mapping-variants" ]
	then
		if [ -f ./17-SelectMappingVariants/"$SAMPLE"_homozygous_mapping_variants.vcf ]
		then 
			echo "[`date`] SelectMappingVariants already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./17-SelectMappingVariants ]
			then
				echo "[`date`] SelectMappingVariants is incomplete, likely due to this job having previously failed. Removing 17-SelectMappingVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./17-SelectMappingVariants
			fi
			echo "[`date`] SelectMappingVariants started" >> "$SAMPLE"_vda_log.txt
			mkdir ./17-SelectMappingVariants

			# filter blacklisted variants
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" VariantFiltration \
			--reference $REFERENCE_GENOME \
			--variant ./16-HaplotypeCallerMappingVariants/"$SAMPLE"_mapping_raw_variants.vcf \
			--mask $BLACKLISTED_VARIANTS \
			--mask-name 'Blacklisted' \
			--output ./17-SelectMappingVariants/"$SAMPLE"_mapping_raw_variants_blacklisted.vcf

			# extract SNPs		
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
			--reference $REFERENCE_GENOME \
			--variant ./17-SelectMappingVariants/"$SAMPLE"_mapping_raw_variants_blacklisted.vcf \
			--select-type-to-include SNP \
			--output ./17-SelectMappingVariants/"$SAMPLE"_raw_snps_for_mapping.vcf &

			# extract indels				
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
			--reference $REFERENCE_GENOME \
			--variant ./17-SelectMappingVariants/"$SAMPLE"_mapping_raw_variants_blacklisted.vcf \
			--select-type-to-include INDEL \
			--output ./17-SelectMappingVariants/"$SAMPLE"_raw_indels_for_mapping.vcf &

			wait

			# apply a stringent filter on SNPs				
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" VariantFiltration \
			--reference $REFERENCE_GENOME \
			--variant ./17-SelectMappingVariants/"$SAMPLE"_raw_snps_for_mapping.vcf \
			--filter-expression 'QD < 9.0' \
			--filter-name 'QD' \
			--filter-expression 'FS > 10.0' \
			--filter-name 'FS' \
			--filter-expression 'MQ < 55.0' \
			--filter-name 'MQ' \
			--filter-expression 'SOR > 3.0' \
			--filter-name 'SOR' \
			--filter-expression 'MQRankSum < -2.5' \
			--filter-name 'MQRankSum' \
			--filter-expression 'ReadPosRankSum < -1.0' \
			--filter-name 'ReadPosRankSum' \
			--output ./17-SelectMappingVariants/"$SAMPLE"_filtered_snps_for_mapping.vcf &

			# apply a stringent filter on indels				
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" VariantFiltration \
			--reference $REFERENCE_GENOME \
			--variant ./17-SelectMappingVariants/"$SAMPLE"_raw_indels_for_mapping.vcf \
			--filter-expression 'QD < 9.0' \
			--filter-name 'QD' \
			--filter-expression 'FS > 10.0' \
			--filter-name 'FS' \
			--filter-expression 'SOR > 3.0' \
			--filter-name 'SOR' \
			--filter-expression 'ReadPosRankSum < -1.0' \
			--filter-name 'ReadPosRankSum' \
			--output ./17-SelectMappingVariants/"$SAMPLE"_filtered_indels_for_mapping.vcf &

			wait

			# remove SNPs that have been filtered						
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
			--reference $REFERENCE_GENOME \
			--variant ./17-SelectMappingVariants/"$SAMPLE"_filtered_snps_for_mapping.vcf \
			--selectExpressions 'vc.isNotFiltered()' \
			--output ./17-SelectMappingVariants/"$SAMPLE"_filtered_passed_snps_for_mapping.vcf &

			# remove indels that have been filtered						
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
			--reference $REFERENCE_GENOME \
			--variant ./17-SelectMappingVariants/"$SAMPLE"_filtered_indels_for_mapping.vcf \
			--selectExpressions 'vc.isNotFiltered()' \
			--output ./17-SelectMappingVariants/"$SAMPLE"_filtered_passed_indels_for_mapping.vcf &

			wait

			# combine SNPs and indels
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeVcfs \
			 --INPUT ./17-SelectMappingVariants/"$SAMPLE"_filtered_passed_snps_for_mapping.vcf \
			 --INPUT ./17-SelectMappingVariants/"$SAMPLE"_filtered_passed_indels_for_mapping.vcf \
			 --OUTPUT ./17-SelectMappingVariants/"$SAMPLE"_mapping_variants.vcf

			# select homozygous variants
			srun -c 1 --mem 4G java -Xmx4G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
			filter 'isHom( GEN[0] ) & isVariant( GEN[0] )' \
			./17-SelectMappingVariants/"$SAMPLE"_mapping_variants.vcf > ./17-SelectMappingVariants/"$SAMPLE"_homozygous_mapping_variants.vcf
			
			# index vcf
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" IndexFeatureFile \
			--input ./17-SelectMappingVariants/"$SAMPLE"_homozygous_mapping_variants.vcf

			if [ -f ./17-SelectMappingVariants/"$SAMPLE"_homozygous_mapping_variants.vcf ]
			then 
				echo "[`date`] SelectMappingVariants completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SelectMappingVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SelectMappingVariants failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

# If analysis mode is set to call-mapping-variants, then exit script
	if [ $WORKFLOW = "call-mapping-variants" ]
	then
		if [ $BACKGROUND_DIRECTORY = "." ] || [ $BACKGROUND_DIRECTORY = "./" ]
		then
			BACKGROUND_DIRECTORY="$(pwd)"
			BACKGROUND_DIRECTORY=${BACKGROUND_DIRECTORY%/*}
		fi

		if [ $MAPPING_DIRECTORY = "." ] || [ $MAPPING_DIRECTORY = "./" ]
		then
			MAPPING_DIRECTORY="$(pwd)"
			MAPPING_DIRECTORY=${MAPPING_DIRECTORY%/*}
		fi

		if [ -f "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf ] &&
		   [ -f "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf.idx ] &&
		   [ -f "$MAPPING_DIRECTORY"/"$SAMPLE"_homozygous_mapping_variants.vcf ] &&
	 	   [ -f "$MAPPING_DIRECTORY"/"$SAMPLE"_homozygous_mapping_variants.vcf.idx ]
		then 
			echo "[`date`] Copying background variant files to "$BACKGROUND_DIRECTORY" and mapping variant files to "$MAPPING_DIRECTORY" already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d "$BACKGROUND_DIRECTORY" ]
			then
				echo "[`date`] Found "$BACKGROUND_DIRECTORY" directory" >> "$SAMPLE"_vda_log.txt
			else
				echo "[`date`] "$BACKGROUND_DIRECTORY" directory doesn't exist. Making "$BACKGROUND_DIRECTORY" directory" >> "$SAMPLE"_vda_log.txt
				BACKGROUND_DIRECTORY=$(echo "$BACKGROUND_DIRECTORY" | sed 's/^[/]//')
				mkdir -p $BACKGROUND_DIRECTORY
				BACKGROUND_DIRECTORY=/"$BACKGROUND_DIRECTORY"				
			fi			

			if [ -d "$MAPPING_DIRECTORY" ]
			then
				echo "[`date`] Found "$MAPPING_DIRECTORY" directory" >> "$SAMPLE"_vda_log.txt
			else
				echo "[`date`] "$MAPPING_DIRECTORY" directory doesn't exist. Making "$MAPPING_DIRECTORY" directory" >> "$SAMPLE"_vda_log.txt
				MAPPING_DIRECTORY=$(echo "$MAPPING_DIRECTORY" | sed 's/^[/]//')
				mkdir -p $MAPPING_DIRECTORY
				MAPPING_DIRECTORY=/"$MAPPING_DIRECTORY"				
			fi	

			echo "[`date`] Copying background variant files to "$BACKGROUND_DIRECTORY" and mapping variant files to "$MAPPING_DIRECTORY" started" >> "$SAMPLE"_vda_log.txt

			if [ $READ_TYPE = "paired-end" ]
			then
				echo "[`date`] Merging HaplotypeCaller and Manta variants" >> "$SAMPLE"_vda_log.txt
				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeVcfs \
				 --INPUT ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf \
				 --INPUT ./15-Manta/"$SAMPLE"_manta_variants.vcf \
				 --OUTPUT "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf
			fi

			if [ $READ_TYPE = "single-end" ]
			then
				cp ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf
				cp ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf.idx "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf.idx 
			fi

			cp ./17-SelectMappingVariants/"$SAMPLE"_homozygous_mapping_variants.vcf "$MAPPING_DIRECTORY"/"$SAMPLE"_homozygous_mapping_variants.vcf
			cp ./17-SelectMappingVariants/"$SAMPLE"_homozygous_mapping_variants.vcf.idx "$MAPPING_DIRECTORY"/"$SAMPLE"_homozygous_mapping_variants.vcf.idx	

			if [ $CLEAN_UP = "true" ]
			then 
				echo "[`date`] CLEANING..." >> "$SAMPLE"_vda_log.txt
				mkdir ./results
				mv ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam ./results
				mv ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bai ./results
				mv ./11-AnalyzeCovariates/"$SAMPLE"_recalibration_plots.pdf ./results
				mv ./12-DetermineCoverage/"$SAMPLE"_coverage.bed ./results
				mv ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_final.txt ./results
				mv ./12-DetermineCoverage/"$SAMPLE"_genes_with_zero_coverage.txt ./results
				mv ./13-CollectWgsMetrics/"$SAMPLE"_stats.txt ./results
				mv ./13-CollectWgsMetrics/"$SAMPLE"_plots ./results
				mv ./13-CollectWgsMetrics/"$SAMPLE"_CollectWgsMetricsWithNonZeroCoverage.txt ./results
				cp "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf ./results
				cp "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf.idx ./results
				cp "$MAPPING_DIRECTORY"/"$SAMPLE"_homozygous_mapping_variants.vcf ./results
				cp "$MAPPING_DIRECTORY"/"$SAMPLE"_homozygous_mapping_variants.vcf.idx ./results

				rm -rf $(ls -lh | awk -F " " '{print $9}' | awk -F "-" '$1 >= 0 {print $0}')	
			fi

			if [ -f "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf ] &&
			   [ -f "$BACKGROUND_DIRECTORY"/"$SAMPLE"_background_all_variants.vcf.idx ] &&
			   [ -f "$MAPPING_DIRECTORY"/"$SAMPLE"_homozygous_mapping_variants.vcf ] &&
	 	       [ -f "$MAPPING_DIRECTORY"/"$SAMPLE"_homozygous_mapping_variants.vcf.idx ]
			then
				echo "[`date`] Copying background variant files to "$BACKGROUND_DIRECTORY" and mapping variant files to "$MAPPING_DIRECTORY" completed" >> "$SAMPLE"_vda_log.txt
				echo "[`date`] CALL-MAPPING-VARIANTS COMPLETE!" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] CALL-MAPPING-VARIANTS COMPLETE!"
				exit 0
			else
				echo "[`date`] ERROR: Copying background variant files to "$BACKGROUND_DIRECTORY" and mapping variant files to "$MAPPING_DIRECTORY" failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: Copying background variant files to "$BACKGROUND_DIRECTORY" and mapping variant files to "$MAPPING_DIRECTORY" failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

#18-FilterHaplotypeCallerVariants
	# Filter HaplotypeCaller variants
	if [ -f ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered.vcf ] 
	then 
		echo "[`date`] FilterHaplotypeCallerVariants already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./18-FilterHaplotypeCallerVariants ]
		then
			echo "[`date`] FilterHaplotypeCallerVariants is incomplete, likely due to this job having previously failed. Removing 18-FilterHaplotypeCallerVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./18-FilterHaplotypeCallerVariants
		fi
		echo "[`date`] FilterHaplotypeCallerVariants started" >> "$SAMPLE"_vda_log.txt
		mkdir ./18-FilterHaplotypeCallerVariants

		# filter blacklisted variants	
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" VariantFiltration \
		--reference $REFERENCE_GENOME \
		--variant ./14-HaplotypeCaller/"$SAMPLE"_merged_dedup_recal_raw_hc_variants.vcf \
		--mask "$BLACKLISTED_VARIANTS" \
		--mask-name 'Blacklisted' \
		--output ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted.vcf

		# extract SNPs		
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
		--reference $REFERENCE_GENOME \
		--variant ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted.vcf \
		--select-type-to-include SNP \
		--output ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted_SNPs.vcf &

		# extract indels		
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
		--reference $REFERENCE_GENOME \
		--variant ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted.vcf \
		--select-type-to-include INDEL \
		--output ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted_INDELs.vcf &

		wait

		# apply a lenient filter on SNPs				
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" VariantFiltration \
		--reference $REFERENCE_GENOME \
		--variant ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted_SNPs.vcf \
		--filter-expression 'QD < 2.0' \
		--filter-name 'QD' \
		--filter-expression 'FS > 60.0' \
		--filter-name 'FS' \
		--filter-expression 'MQ < 40.0' \
		--filter-name 'MQ' \
		--filter-expression 'SOR > 3.0' \
		--filter-name 'SOR' \
		--filter-expression 'MQRankSum < -12.5' \
		--filter-name 'MQRankSum' \
		--filter-expression 'ReadPosRankSum < -8.0' \
		--filter-name 'ReadPosRankSum' \
		--output ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted_SNPs_filtered.vcf &

		# apply a lenient filter on indels						
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" VariantFiltration \
		--reference $REFERENCE_GENOME \
		--variant ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted_INDELs.vcf \
		--filter-expression 'QD < 2.0' \
		--filter-name 'QD' \
		--filter-expression 'FS > 200.0' \
		--filter-name 'FS' \
		--filter-expression 'SOR > 10.0' \
		--filter-name 'SOR' \
		--filter-expression 'ReadPosRankSum < -20.0' \
		--filter-name 'ReadPosRankSum' \
		--output ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted_INDELs_filtered.vcf &

		wait
	
		# combine SNPs and indels	
		srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" MergeVcfs \
		 --INPUT ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted_SNPs_filtered.vcf \
		 --INPUT ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_blacklisted_INDELs_filtered.vcf \
		 --OUTPUT ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered.vcf
		
		if [ -f ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered.vcf ]
		then 
			echo "[`date`] FilterHaplotypeCallerVariants completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: FilterHaplotypeCallerVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: FilterHaplotypeCallerVariants failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#19-SubtractBackgroundHaplotypeCallerVariants
	# Remove background HaplotypeCaller variants
	if [ $WORKFLOW = "vda-unmapped" ]
	then
		PSBV_NAME=$(echo $PARENT_STRAIN_BACKGROUND_VARIANTS | awk -F "/" '{print $NF}' | sed 's/.vcf//')
		if [ -f ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_subtracted.vcf ]
		then 
			echo "[`date`] SubtractBackgroundHaplotypeCallerVariants already complete" >> "$SAMPLE"_vda_log.txt
		else
			if [ -d ./19-SubtractBackgroundHaplotypeCallerVariants ]
			then
				echo "[`date`] SubtractBackgroundHaplotypeCallerVariants is incomplete, likely due to this job having previously failed. Removing 19-SubtractBackgroundHaplotypeCallerVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./19-SubtractBackgroundHaplotypeCallerVariants
			fi		 
			echo "[`date`] SubtractBackgroundHaplotypeCallerVariants started" >> "$SAMPLE"_vda_log.txt
			mkdir ./19-SubtractBackgroundHaplotypeCallerVariants

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
			--reference $REFERENCE_GENOME \
			--variant ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered.vcf \
			--discordance "$PARENT_STRAIN_BACKGROUND_VARIANTS" \
			--output ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_subtracted.vcf

			if [ -f ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_subtracted.vcf ]
			then 
				echo "[`date`] SubtractBackgroundHaplotypeCallerVariants completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SubtractBackgroundHaplotypeCallerVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SubtractBackgroundHaplotypeCallerVariants failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

	if [ $WORKFLOW = "vda-mapped" ]
	then
		PSBV_NAME=$(echo $PARENT_STRAIN_BACKGROUND_VARIANTS | awk -F "/" '{print $NF}' | sed 's/.vcf//')
		MSBV_NAME=$(echo $MAPPING_STRAIN_BACKGROUND_VARIANTS | awk -F "/" '{print $NF}' | sed 's/.vcf//')
		if [ -f ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf ]
		then 
			echo "[`date`] SubtractBackgroundHaplotypeCallerVariants already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./19-SubtractBackgroundHaplotypeCallerVariants ]
			then
				echo "[`date`] SubtractBackgroundHaplotypeCallerVariants is incomplete, likely due to this job having previously failed. Removing 19-SubtractBackgroundHaplotypeCallerVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./19-SubtractBackgroundHaplotypeCallerVariants
			fi				
			echo "[`date`] SubtractBackgroundHaplotypeCallerVariants started" >> "$SAMPLE"_vda_log.txt
			mkdir ./19-SubtractBackgroundHaplotypeCallerVariants

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
			--reference $REFERENCE_GENOME \
			--variant ./18-FilterHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered.vcf \
			--discordance "$PARENT_STRAIN_BACKGROUND_VARIANTS" \
			--output ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_subtracted.vcf
			
			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
			--reference $REFERENCE_GENOME \
			--variant ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_subtracted.vcf \
			--discordance "$MAPPING_STRAIN_BACKGROUND_VARIANTS" \
			--output ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf

			if [ -f ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf ]
			then 
				echo "[`date`] SubtractBackgroundHaplotypeCallerVariants completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: SubtractBackgroundHaplotypeCallerVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: SubtractBackgroundHaplotypeCallerVariants failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

#20-SubtractBackgroundMantaVariants
	# Remove background Manta variants
	if [ $READ_TYPE = "paired-end" ]
	then
		if [ $WORKFLOW = "vda-unmapped" ]
		then
			if [ -f ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_subtracted.vcf ] 
			then 
				echo "[`date`] SubtractBackgroundMantaVariants already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./20-SubtractBackgroundMantaVariants ]
				then
					echo "[`date`] SubtractBackgroundMantaVariants is incomplete, likely due to this job having previously failed. Removing 20-SubtractBackgroundMantaVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./20-SubtractBackgroundMantaVariants
				fi
				echo "[`date`] SubtractBackgroundMantaVariants started" >> "$SAMPLE"_vda_log.txt
				mkdir ./20-SubtractBackgroundMantaVariants

				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
				--reference $REFERENCE_GENOME \
				--variant ./15-Manta/"$SAMPLE"_manta_variants.vcf \
				--discordance "$PARENT_STRAIN_BACKGROUND_VARIANTS" \
				--output ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_subtracted.vcf

				if [ -f ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_subtracted.vcf ]
				then 
					echo "[`date`] SubtractBackgroundMantaVariants completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: SubtractBackgroundMantaVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: SubtractBackgroundMantaVariants failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi

		if [ $WORKFLOW = "vda-mapped" ]
		then
			if [ -f ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf ]
			then 
				echo "[`date`] SubtractBackgroundMantaVariants already complete" >> "$SAMPLE"_vda_log.txt
			else 
				if [ -d ./20-SubtractBackgroundMantaVariants ]
				then
					echo "[`date`] SubtractBackgroundMantaVariants is incomplete, likely due to this job having previously failed. Removing 20-SubtractBackgroundMantaVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
					rm -rf ./20-SubtractBackgroundMantaVariants
				fi
				echo "[`date`] SubtractBackgroundMantaVariants started" >> "$SAMPLE"_vda_log.txt
				mkdir ./20-SubtractBackgroundMantaVariants
			
				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
				--reference $REFERENCE_GENOME \
				--variant ./15-Manta/"$SAMPLE"_manta_variants.vcf \
				--discordance "$PARENT_STRAIN_BACKGROUND_VARIANTS" \
				--output ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_subtracted.vcf
				
				srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
				--reference $REFERENCE_GENOME \
				--variant ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_subtracted.vcf \
				--discordance "$MAPPING_STRAIN_BACKGROUND_VARIANTS" \
				--output ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf

				if [ -f ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf ]
				then 
					echo "[`date`] SubtractBackgroundMantaVariants completed" >> "$SAMPLE"_vda_log.txt
				else 
					echo "[`date`] ERROR: SubtractBackgroundMantaVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
					mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
					echo "[`date`] ERROR: SubtractBackgroundMantaVariants failed. Check variant_discovery_analysis.err for details"
					exit 1
				fi
			fi
		fi
	fi

#21-AnnotateHaplotypeCallerVariants
	# Annotate HaplotypeCaller variants
	if [ -f ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final.txt ]
	then 
		echo "[`date`] AnnotateHaplotypeCallerVariants already complete" >> "$SAMPLE"_vda_log.txt
	else 
		if [ -d ./21-AnnotateHaplotypeCallerVariants ]
		then
			echo "[`date`] AnnotateHaplotypeCallerVariants is incomplete, likely due to this job having previously failed. Removing 21-AnnotateHaplotypeCallerVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
			rm -rf ./21-AnnotateHaplotypeCallerVariants
		fi
		echo "[`date`] AnnotateHaplotypeCallerVariants started" >> "$SAMPLE"_vda_log.txt
		mkdir ./21-AnnotateHaplotypeCallerVariants

		if [ $WORKFLOW = "vda-unmapped" ]
		then
			anno_hc_input=./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_subtracted.vcf
		else
			if [ $WORKFLOW = "vda-mapped" ]
			then 
				anno_hc_input=./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf
			fi
		fi

		# select both homozygous and heterozygous variants
		srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
		filter '(isHom( GEN[0] ) | isHet( GEN[0] )) & isVariant( GEN[0] )' \
		"$anno_hc_input" > ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped.vcf

		# annotate variants
		srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/snpEff.jar eff \
		-fastaProt ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_protein.fa \
		-chr chr \
		-o vcf \
		-ud 10000 \
		-s ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_snpEff_summary.html \
		-dataDir "$PATH_TO_SNPEFF"/data $SNPEFF_DATABASE \
		./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped.vcf > ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped_annotated.vcf
		
		# reformat data to list only one effect per line
		srun -c 1 --mem 8G cat ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped_annotated.vcf | \
		"$PATH_TO_SNPEFF"/scripts/vcfEffOnePerLine.pl > ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped_annotated_formatted.vcf
		
		# add variation type
		srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
		varType \
		./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped_annotated_formatted.vcf > ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped_annotated_formatted_typed.vcf

		# select all variant effects
		srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
		filter "( EFF[*].IMPACT = 'HIGH' | EFF[*].IMPACT = 'MODERATE' | EFF[*].IMPACT = 'LOW' | EFF[*].IMPACT = 'MODIFIER' )" \
		./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped_annotated_formatted_typed.vcf > ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped_annotated_formatted_typed_effects.vcf

		# convert vcf to txt
		srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
		extractFields ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_genotyped_annotated_formatted_typed_effects.vcf \
		CHROM POS REF ALT VARTYPE HOM FILTER QUAL DP "EFF[*].WARNINGS" "EFF[*].GENEID" "EFF[*].GENE" "EFF[*].BIOTYPE" "EFF[*].TRID" "EFF[*].EFFECT" "EFF[*].AA" "EFF[*].AA_LEN" "EFF[*].IMPACT" \
		> ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final.txt

		# reformat output
		awk 'BEGIN {FS="\t"; OFS="\t"} /CHROM/ {print $1 "\t" $2 "\t" $3 "\t" $4 "\t" "CALLER" "\t" $5 "\t" "GENO" "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18}' ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final.txt > ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final_header.txt		
		awk 'BEGIN {FS="\t"; OFS="\t"} {if($1 ~ /chr/ && $6 ~ /true/) {print $1 "\t" $2 "\t" $3 "\t" $4 "\t" "HaplotypeCaller" "\t" $5 "\t" "HOM" "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18} else if($1 ~ /chr/ && $6 ~ /false/) print $1 "\t" $2 "\t" $3 "\t" $4 "\t" "HaplotypeCaller" "\t" $5 "\t" "HET" "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18}' ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final.txt | awk 'BEGIN {FS="\t"; OFS="\t"} {if($11 != "") {print $0} else print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" "." "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18 "\t" $19}' | awk 'BEGIN {FS="\t"; OFS="\t"} {if($14 != "") {print $0} else print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" "." "\t" $15 "\t" $16 "\t" $17 "\t" $18 "\t" $19}' | awk 'BEGIN {FS="\t"; OFS="\t"} {if($15 != "") {print $0} else print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" "." "\t" $16 "\t" $17 "\t" $18 "\t" $19}' | awk 'BEGIN {FS="\t"; OFS="\t"} {if($17 != "") {print $0} else print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" "." "\t" $18 "\t" $19}' > ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final_body.txt
		cat ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final_header.txt ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final_body.txt > ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final.txt

		if [ -f ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final.txt ]
		then 
			echo "[`date`] AnnotateHaplotypeCallerVariants completed" >> "$SAMPLE"_vda_log.txt
		else 
			echo "[`date`] ERROR: AnnotateHaplotypeCallerVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: AnnotateHaplotypeCallerVariants failed. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

#22-AnnotateMantaVariants
	# Annotate Manta variants
	if [ $READ_TYPE = "paired-end" ]
	then
		if [ -f ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_final.txt ] 
		then 
			echo "[`date`] AnnotateMantaVariants already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./22-AnnotateMantaVariants ]
			then
				echo "[`date`] AnnotateMantaVariants is incomplete, likely due to this job having previously failed. Removing 22-AnnotateMantaVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./22-AnnotateMantaVariants
			fi
			echo "[`date`] AnnotateMantaVariants started" >> "$SAMPLE"_vda_log.txt
			mkdir ./22-AnnotateMantaVariants
		
			if [ $WORKFLOW = "vda-unmapped" ]
			then
				anno_manta_input=./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_subtracted.vcf
			else
				if [ $WORKFLOW = "vda-mapped" ]
				then
					anno_manta_input=./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf
				fi
			fi

			# select both homozygous and heterozygous variants
			srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
			filter '(isHom( GEN[0] ) | isHet( GEN[0] )) & isVariant( GEN[0] )' \
			"$anno_manta_input" > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped.vcf

			# annotate variants
			srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/snpEff.jar eff \
			-fastaProt ./22-AnnotateMantaVariants/"$SAMPLE"_manta_protein.fa \
			-chr chr \
			-o vcf \
			-ud 10000 \
			-s ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_snpEff_summary.html \
			-dataDir "$PATH_TO_SNPEFF"/data $SNPEFF_DATABASE \
			./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped.vcf > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped_annotated.vcf
			
			# reformat data to list only one effect per line
			srun -c 1 --mem 8G cat ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped_annotated.vcf | \
			"$PATH_TO_SNPEFF"/scripts/vcfEffOnePerLine.pl > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped_annotated_formatted.vcf
			
			# add variation type
			srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
			varType \
			./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped_annotated_formatted.vcf > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped_annotated_formatted_typed.vcf
			
			# select all variant effects
			srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
			filter "( EFF[*].IMPACT = 'HIGH' | EFF[*].IMPACT = 'MODERATE' | EFF[*].IMPACT = 'LOW' | EFF[*].IMPACT = 'MODIFIER' )" \
			./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped_annotated_formatted_typed.vcf > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped_annotated_formatted_typed_effects.vcf
			
			# convert vcf to txt
			srun -c 1 --mem 8G java -Xmx8G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
			extractFields ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_genotyped_annotated_formatted_typed_effects.vcf \
			CHROM POS REF ALT VARTYPE SVTYPE HOM FILTER QUAL DP "EFF[*].WARNINGS" "EFF[*].GENEID" "EFF[*].GENE" "EFF[*].BIOTYPE" "EFF[*].TRID" "EFF[*].EFFECT" "EFF[*].AA" "EFF[*].AA_LEN" "EFF[*].IMPACT" \
			> ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_quarter_final.txt
			
			# reformat output
			awk 'BEGIN {FS="\t"; OFS="\t"} {if($5 != "") {print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18 "\t" $19} else print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18 "\t" $19}' ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_quarter_final.txt > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_semi_final.txt
			awk 'BEGIN {FS="\t"; OFS="\t"} /CHROM/ {print $1 "\t" $2 "\t" $3 "\t" $4 "\t" "CALLER" "\t" $5 "\t" "GENO" "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18}' ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_semi_final.txt > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_semi_final_header.txt		
			awk 'BEGIN {FS="\t"; OFS="\t"} {if($1 ~ /chr/ && $6 ~ /true/) {print $1 "\t" $2 "\t" $3 "\t" $4 "\t" "Manta" "\t" $5 "\t" "HOM" "\t" $7 "\t" $8 "\t" "." "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18} else if($1 ~ /chr/ && $6 ~ /false/) print $1 "\t" $2 "\t" $3 "\t" $4 "\t" "Manta" "\t" $5 "\t" "HET" "\t" $7 "\t" $8 "\t" "." "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18}' ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_semi_final.txt | awk 'BEGIN {FS="\t"; OFS="\t"} {if($11 != "") {print $0} else print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" "." "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" $17 "\t" $18 "\t" $19}' | awk 'BEGIN {FS="\t"; OFS="\t"} {if($14 != "") {print $0} else print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" "." "\t" $15 "\t" $16 "\t" $17 "\t" $18 "\t" $19}' | awk 'BEGIN {FS="\t"; OFS="\t"} {if($15 != "") {print $0} else print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" "." "\t" $16 "\t" $17 "\t" $18 "\t" $19}' | awk 'BEGIN {FS="\t"; OFS="\t"} {if($17 != "") {print $0} else print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $14 "\t" $15 "\t" $16 "\t" "." "\t" $18 "\t" $19}' > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_semi_final_body.txt
			cat ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_semi_final_header.txt ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_semi_final_body.txt > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_semi_final.txt
			uniq ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_semi_final.txt > ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_final.txt
		
			if [ -f ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_final.txt ]
			then 
				echo "[`date`] AnnotateMantaVariants completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: AnnotateMantaVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: AnnotateMantaVariants failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

#23-MergeVariants
	# Merge HaplotypeCaller and Manta variants
	if [ $READ_TYPE = "paired-end" ]
	then
		if [ -f ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt ] 
		then 
			echo "[`date`] MergeVariants already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./23-MergeVariants ]
			then
				echo "[`date`] MergeVariants is incomplete, likely due to this job having previously failed. Removing 23-MergeVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./23-MergeVariants
			fi
			echo "[`date`] MergeVariants started" >> "$SAMPLE"_vda_log.txt
			mkdir ./23-MergeVariants
		
			tail -n +2 ./22-AnnotateMantaVariants/"$SAMPLE"_manta_variants_final.txt | cat ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final.txt - > ./23-MergeVariants/"$SAMPLE"_all_variants_final_unsorted.txt
			
			(head -n 1 ./23-MergeVariants/"$SAMPLE"_all_variants_final_unsorted.txt | sed -e 's/EFF\[\*\]\.//g' && tail -n +2 ./23-MergeVariants/"$SAMPLE"_all_variants_final_unsorted.txt | sort -k1,1 -k2n) > ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt

			if [ -f ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt ]
			then 
				echo "[`date`] MergeVariants completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MergeVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeVariants failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

	if [ $READ_TYPE = "single-end" ]
	then
		if [ -f ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt ] 
		then 
			echo "[`date`] MergeVariants already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./23-MergeVariants ]
			then
				echo "[`date`] MergeVariants is incomplete, likely due to this job having previously failed. Removing 23-MergeVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./23-MergeVariants
			fi
			echo "[`date`] MergeVariants started. Due to the read-type being single-end, Manta was not run on this sample, therefore, there is nothing to merge. "$SAMPLE"_hc_variants_final.txt will be copied and renamed "$SAMPLE"_all_variants_final_without_provean_scores.txt" >> "$SAMPLE"_vda_log.txt
			mkdir ./23-MergeVariants
		
			(head -n 1 ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final.txt | sed -e 's/EFF\[\*\]\.//g' && tail -n +2 ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_variants_final.txt | sort -k1,1 -k2n) > ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt

			if [ -f ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt ]
			then 
				echo "[`date`] MergeVariants completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: MergeVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: MergeVariants failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

#24-ProveanMissenseVariants
	# Calculate PROVEAN scores for missense variants and inframe indels
	if [ $CALCULATE_PROVEAN_SCORES = "true" ]
	then
		if [ -f ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_final_with_provean_scores.txt ] 
		then 
			echo "[`date`] ProveanMissenseVariants already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./24-ProveanMissenseVariants ]
			then
				echo "[`date`] ProveanMissenseVariants is incomplete, likely due to this job having previously failed. Removing 24-ProveanMissenseVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./24-ProveanMissenseVariants
			fi
			echo "[`date`] ProveanMissenseVariants started" >> "$SAMPLE"_vda_log.txt
			mkdir ./24-ProveanMissenseVariants

			# uniqify transcript names, in case there are multiple mutations in the same transcript
			awk 'BEGIN {FS="\t"; OFS="\t"} {if(++a[$15]>1)$15=$15"_"a[$15]}1' ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt > ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_uniqified.txt 
			
			# remove tRNAs, which for some reason snpEff annotates as protein_coding. PROVEAN fails to process these	
			awk 'BEGIN {FS="\t"; OFS="\t"} $13 !~ /\.t/ {print $0}' ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_uniqified.txt > ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_uniqified_genes_with_tRNAs_removed.txt

			# for all missense variants and inframe indels, grab the amino acid change and transcript name.
			awk 'BEGIN {FS="\t"; OFS="\t"} /missense_variant/ || /conservative_inframe_deletion/ || /conservative_inframe_insertion/ || /disruptive_inframe_deletion/ || /disruptive_inframe_insertion/ {print $17 "\t" $15}' ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_uniqified_genes_with_tRNAs_removed.txt > ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			
			# create a file that contains names of all transcripts to be processed... to be used later in "for" loops
			awk '{print $2}' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt > ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_transcript_NAMES.txt
			
			# edit amino acid changes to HGVS (Human Genome Variation Society) notation
			sed -i 's/p.//' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Ala/A/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Arg/R/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Asn/N/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Asp/D/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Cys/C/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Glu/E/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Gln/Q/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Gly/G/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/His/H/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Ile/I/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Leu/L/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Lys/K/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Met/M/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Phe/F/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Pro/P/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Ser/S/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Thr/T/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Trp/W/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Tyr/Y/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			sed -i 's/Val/V/g' ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt
			
			# create a separate file for each amino acid change, containing just the change, and name as transcript_aa_change.
			for i in $(cat ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_transcript_NAMES.txt)
			do
				grep -w $i ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_variants.txt | awk '{print $1}' > ./24-ProveanMissenseVariants/"$i"_aa_change
			done
			
			cat ./21-AnnotateHaplotypeCallerVariants/"$SAMPLE"_hc_protein.fa ./22-AnnotateMantaVariants/"$SAMPLE"_manta_protein.fa > ./24-ProveanMissenseVariants/"$SAMPLE"_all_protein.fa
			
			# for each transcript to be processed, create a separate fasta file that contains the REF amino acid sequence
			for i in $(cat ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_transcript_NAMES.txt)
			do 
				PROTEIN=$(echo "$i" | awk -F "_" '{print $1}')
				grep -m 1 -A 1 ">"$PROTEIN" Ref" ./24-ProveanMissenseVariants/"$SAMPLE"_all_protein.fa > ./24-ProveanMissenseVariants/"$i"_aa_ref.fasta 
			done
			
			# run provean
			for i in $(cat ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_transcript_NAMES.txt) 
			do 
				sbatch "$SCRIPT_DIR"/scripts/provean_submission_script.sh ./24-ProveanMissenseVariants "$i"
			done
			
			# wait and check to ensure provean jobs finished correctly
			for i in {1..1000}
			do
				sleep 1m
				if [[ $(wc ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_transcript_NAMES.txt | awk '{ print $1 }') == $(wc ./24-ProveanMissenseVariants/*_provean_output | awk '/provean_output/ {print $1}' | sed 's/13/12/g' | uniq -c | awk '{print $1}') ]]
				then
					break
				else
					echo "PROVEAN running... "$i" minutes"
				fi
			done
			
			# create a separate file for each provean score, one line containing the transcript name, aa change, and score, and name as transcript_provean_score.
			for i in $(cat ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_transcript_NAMES.txt)
			do 
				awk -v var="$i" '!/#/ && !/\[/ {print var "\t" $0;}' ./24-ProveanMissenseVariants/"$i"_provean_output > ./24-ProveanMissenseVariants/"$i"_provean_score
			done
			
			# create a file where provean scores will be aggregated and assign the header as transcript, aa change, provean score, prediction
			echo -e TRID'\t'AA_Change'\t'PROVEAN_SCORE'\t'PREDICTION > ./24-ProveanMissenseVariants/"$SAMPLE"_missense_scores
			
			# for each provean score, annotate as deleterious or neutral, and add it to sample_missense_scores
			for i in $(cat ./24-ProveanMissenseVariants/"$SAMPLE"_moderate_effect_transcript_NAMES.txt)
			do
				if (( $(echo "$(cut -f 3 "./24-ProveanMissenseVariants/"$i"_provean_score") < -2.5" |bc -l) )) 
			    then 
			    	awk '{ print $0 "\t" "DELETERIOUS" }' ./24-ProveanMissenseVariants/"$i"_provean_score >> ./24-ProveanMissenseVariants/"$SAMPLE"_missense_scores
			    else 
			    	awk '{ print $0 "\t" "NEUTRAL" }' ./24-ProveanMissenseVariants/"$i"_provean_score >> ./24-ProveanMissenseVariants/"$SAMPLE"_missense_scores
			    fi
			done
			
			# merge aggregated scores with sample_all_variants_uniqified.txt
			awk 'BEGIN {FS="\t"; OFS="\t"} NR==FNR{a[$1]=$0;next}{print $0 "\t" a[$15]}' ./24-ProveanMissenseVariants/"$SAMPLE"_missense_scores ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_uniqified.txt > ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_uniqified_provean_added.txt
			
			# reformat output and remove unique TRID names
			paste <(cut -f -19 ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt) <(cut -f 22- ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_uniqified_provean_added.txt) | awk 'BEGIN {FS="\t"; OFS="\t"} {if($NF != "") {print $0} else {NF--; print $0 "\t" "." "\t" "."}}' > ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_final_with_provean_scores.txt
			
			# clean up
			rm ./24-ProveanMissenseVariants/*_provean_output
			rm ./24-ProveanMissenseVariants/*_provean_score
			rm ./*.err
			rm ./*.out
			rm ./24-ProveanMissenseVariants/*_aa_ref.fasta
			rm ./24-ProveanMissenseVariants/*_aa_change
			rm ./24-ProveanMissenseVariants/*_moderate_effect_transcript_NAMES.txt
			rm ./24-ProveanMissenseVariants/*_moderate_effect_variants.txt
			rm ./24-ProveanMissenseVariants/*_variants_uniqified.txt

			if [ -f ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_final_with_provean_scores.txt ]
			then 
				echo "[`date`] ProveanMissenseVariants completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: ProveanMissenseVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: ProveanMissenseVariants failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

#25-AddWormBaseData
	# Add information on indentical/similar alleles, gene description, associated phenotypes, human orthologs, etc.
	if [ $ADD_WORMBASE_DATA = "true" ]
	then
		if [ -f ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_wormbase_data_added.txt ] 
		then 
			echo "[`date`] AddWormBaseData already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./25-AddWormBaseData ]
			then
				echo "[`date`] AddWormBaseData is incomplete, likely due to this job having previously failed. Removing 25-AddWormBaseData directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./25-AddWormBaseData
			fi
			echo "[`date`] AddWormBaseData started" >> "$SAMPLE"_vda_log.txt
			mkdir ./25-AddWormBaseData

			# set input
			if [ $CALCULATE_PROVEAN_SCORES = "true" ]
			then
				INPUT_FOR_ADDING_WB_DATA=./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_final_with_provean_scores.txt
			else
				if [ $CALCULATE_PROVEAN_SCORES = "false" ]
				then
					awk 'BEGIN {FS="\t"; OFS="\t"} {print $0 "\t" "." "\t" "."}' ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt > ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_without_provean_scores_filler_columns_added.txt 
					INPUT_FOR_ADDING_WB_DATA=./25-AddWormBaseData/"$SAMPLE"_all_variants_final_without_provean_scores_filler_columns_added.txt
				fi
			fi

			# select header and modify
			awk 'BEGIN {FS="\t"; OFS="\t"} $1 == "CHROM" {print $0 "\t" "IDENTICAL_VARIANT" "\t" "IDENTICAL_EFFECT_VARIANT"}' "$INPUT_FOR_ADDING_WB_DATA" > ./25-AddWormBaseData/"$SAMPLE"_header.txt

			# select SNPs
			awk 'BEGIN {FS="\t"; OFS="\t"} $6 == "SNP" {print $0}' "$INPUT_FOR_ADDING_WB_DATA" > ./25-AddWormBaseData/"$SAMPLE"_SNPs.txt

			# add names of identical SNP alleles and names of SNP alleles with identical effects
			awk 'BEGIN {FS="\t"; OFS="\t"} NR==FNR{a[$1"\t"$2"\t"$4"\t"$5]=$6;next}{print $0 "\t" a[$1"\t"$2"\t"$3"\t"$4]}' "$SCRIPT_DIR"/data/wormbase/wormbase_snp_alleles.txt ./25-AddWormBaseData/"$SAMPLE"_SNPs.txt | awk 'BEGIN {FS="\t"; OFS="\t"} {if($NF != "") {print $0} else {NF--; print $0 "\t" "."}}' | awk 'BEGIN {FS="\t"; OFS="\t"} NR==FNR{a[$1"\t"$2]=$3;next}{print $0 "\t" a[$15"\t"$17]}' "$SCRIPT_DIR"/data/wormbase/WS275_missense_and_nonsense_alleles.txt - | awk 'BEGIN {FS="\t"; OFS="\t"} {if($NF != "") {print $0} else {NF--; print $0 "\t" "."}}' > ./25-AddWormBaseData/"$SAMPLE"_SNPs_WB_alleles_added.txt

			# select DELs
			awk 'BEGIN {FS="\t"; OFS="\t"} $6 == "DEL" {print $0 "\t" $2+1 "\t" length($3)-1}' "$INPUT_FOR_ADDING_WB_DATA" > ./25-AddWormBaseData/"$SAMPLE"_DELs.txt

			# add names of identical DEL alleles
			awk 'BEGIN {FS="\t"; OFS="\t"} NR==FNR{a[$1"\t"$2"\t"$4]=$5;next}{print $0 "\t" a[$1"\t"$22"\t"$23]}' "$SCRIPT_DIR"/data/wormbase/wormbase_deletion_alleles.txt ./25-AddWormBaseData/"$SAMPLE"_DELs.txt | awk 'BEGIN {FS="\t"; OFS="\t"} {if($NF != "") {print $0 "\t" "."} else {NF--; print $0 "\t" "." "\t" "."}}' | cut -f -21,24- > ./25-AddWormBaseData/"$SAMPLE"_DELs_WB_alleles_added.txt

			# select INSs
			awk 'BEGIN {FS="\t"; OFS="\t"} $6 == "INS" {print $0 "\t" substr($4,2)}' "$INPUT_FOR_ADDING_WB_DATA" > ./25-AddWormBaseData/"$SAMPLE"_INSs.txt  

			# add names of identical INS alleles
			awk 'BEGIN {FS="\t"; OFS="\t"} NR==FNR{a[$1"\t"$2"\t"$4]=$5;next}{print $0 "\t" a[$1"\t"$2"\t"$22]}' "$SCRIPT_DIR"/data/wormbase/wormbase_insertion_alleles.txt ./25-AddWormBaseData/"$SAMPLE"_INSs.txt | awk 'BEGIN {FS="\t"; OFS="\t"} {if($NF != "") {print $0 "\t" "."} else {NF--; print $0 "\t" "." "\t" "."}}' | cut -f -21,23- > ./25-AddWormBaseData/"$SAMPLE"_INSs_WB_alleles_added.txt

			# select variants that aren't SNP, DEL, or INS (these would be INV, etc.)	
			tail -n +2 "$INPUT_FOR_ADDING_WB_DATA" | awk 'BEGIN {FS="\t"; OFS="\t"} $6 != "SNP" && $6 != "DEL" && $6 != "INS" {print $0 "\t" "." "\t" "."}' > ./25-AddWormBaseData/"$SAMPLE"_OTHERS.txt  

			# combine variants, sort, and add header
			cat ./25-AddWormBaseData/"$SAMPLE"_SNPs_WB_alleles_added.txt ./25-AddWormBaseData/"$SAMPLE"_INSs_WB_alleles_added.txt ./25-AddWormBaseData/"$SAMPLE"_DELs_WB_alleles_added.txt ./25-AddWormBaseData/"$SAMPLE"_OTHERS.txt | sort -k1,1 -k2n | cat ./25-AddWormBaseData/"$SAMPLE"_header.txt - > ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_WB_alleles.txt

			# add WormBase gene data
			awk 'BEGIN {FS="\t"; OFS="\t"} NR==FNR{a[$1]=$2"\t"$3"\t"$4"\t"$5;next}{print $0 "\t" a[$12]}' "$SCRIPT_DIR"/data/wormbase/wormbase_gene_data.txt ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_WB_alleles.txt > ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_WB_alleles_and_WB_gene_data.txt

			# copy and rename output
			if [ $CALCULATE_PROVEAN_SCORES = "true" ]
			then
				cp ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_WB_alleles_and_WB_gene_data.txt ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_wormbase_data_added.txt
			fi

			if [ $CALCULATE_PROVEAN_SCORES = "false" ]
			then
				cut -f -19,22- ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_WB_alleles_and_WB_gene_data.txt > ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_wormbase_data_added.txt
			fi

			if [ -f ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_wormbase_data_added.txt ]
			then 
				echo "[`date`] AddWormBaseData completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: AddWormBaseData failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: AddWormBaseData failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi

# If analysis mode is set to vda-unmapped, then exit script
	if [ $WORKFLOW = "vda-unmapped" ]
	then
		echo "[`date`] Reorganizing analysis directory... copying key files to results directory and putting all job directories in "$SAMPLE"_VDA_TEMP_DIR" >> "$SAMPLE"_vda_log.txt
		if [ ! -d results ]; then mkdir results; fi
		cp ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam ./results
		cp ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bai ./results
		cp ./11-AnalyzeCovariates/"$SAMPLE"_recalibration_plots.pdf ./results
		cp ./12-DetermineCoverage/"$SAMPLE"_coverage.bed ./results
		cp ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_final.txt ./results
		cp ./12-DetermineCoverage/"$SAMPLE"_genes_with_zero_coverage.txt ./results
		cp ./13-CollectWgsMetrics/"$SAMPLE"_stats.txt ./results
		cp -R ./13-CollectWgsMetrics/"$SAMPLE"_plots ./results
		cp ./13-CollectWgsMetrics/"$SAMPLE"_CollectWgsMetricsWithNonZeroCoverage.txt ./results
		cp ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_subtracted.vcf ./results	
		cp ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_subtracted.vcf.idx ./results	

		if [ $READ_TYPE = "paired-end" ]
		then
			cp ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_subtracted.vcf ./results
			cp ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_subtracted.vcf.idx ./results
		fi

		if [ $ADD_WORMBASE_DATA = "true" ]
		then
			cp ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_wormbase_data_added.txt ./results/"$SAMPLE"_all_variants_and_effects.txt
		else
			if [ $CALCULATE_PROVEAN_SCORES = "true" ]
			then
				cp ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_final_with_provean_scores.txt ./results/"$SAMPLE"_all_variants_and_effects.txt
			else
				cp ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt ./results/"$SAMPLE"_all_variants_and_effects.txt
			fi
		fi

		awk 'BEGIN {FS="\t"; OFS="\t"} ($7 == "GENO" && $19 == "IMPACT") || ($7 == "HOM" && $19 == "HIGH") || ($7 == "HOM" && $19 == "MODERATE")' ./results/"$SAMPLE"_all_variants_and_effects.txt > ./results/"$SAMPLE"_homozygous_disruptive_coding_variants.txt
		
		if [ ! -d "$SAMPLE"_VDA_TEMP_DIR ]; then mkdir "$SAMPLE"_VDA_TEMP_DIR; fi
		
		MOVE_DIRS=$(ls -dlh */ | awk 'BEGIN {FS=" "; OFS=" "} {print $9}' | grep -v results/)
		
		for i in $(echo "$MOVE_DIRS")
		do
			mv "$i" ./"$SAMPLE"_VDA_TEMP_DIR
		done

		if [ $CLEAN_UP = "true" ]
		then 
			echo "[`date`] Removing "$SAMPLE"_VDA_TEMP_DIR" >> "$SAMPLE"_vda_log.txt
			rm -rf ./"$SAMPLE"_VDA_TEMP_DIR
		fi

		if [ -f ./results/"$SAMPLE"_all_variants_and_effects.txt ] &&
		   [ -f ./results/"$SAMPLE"_homozygous_disruptive_coding_variants.txt ]
		then
			echo "[`date`] VDA-UNMAPPED WORKFLOW COMPLETE!" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] VDA-UNMAPPED WORKFLOW COMPLETE!"
			exit 0
		else
			echo "[`date`] ERROR: Failed exiting vda-unmapped workflow. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: Failed exiting vda-unmapped workflow. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

# If analysis mode is set to vda-mapped, then begin mapping analysis
#26-HaplotypeCallerGenotypeVariants
	# Genotype mapping variants
	if [ $WORKFLOW = "vda-mapped" ]
	then
		if [ -f ./26-HaplotypeCallerGenotypeVariants/"$SAMPLE"_mapping_variant_genotypes_raw.vcf ] 
		then 
			echo "[`date`] HaplotypeCallerGenotypeVariants already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./26-HaplotypeCallerGenotypeVariants ]
			then
				echo "[`date`] HaplotypeCallerGenotypeVariants is incomplete, likely due to this job having previously failed. Removing 26-HaplotypeCallerGenotypeVariants directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./26-HaplotypeCallerGenotypeVariants
			fi
			echo "[`date`] HaplotypeCallerGenotypeVariants started" >> "$SAMPLE"_vda_log.txt
			mkdir ./26-HaplotypeCallerGenotypeVariants

			if [ $LINKED_DE_BRUIJN_GRAPH = "false" ]
			then
				srun -c "$MAX_CORES" --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" HaplotypeCaller \
				--native-pair-hmm-threads "$MAX_CORES" \
				--reference $REFERENCE_GENOME \
				--input ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
				--alleles "$MAPPING_VARIANTS" \
				--output-mode EMIT_ALL_ACTIVE_SITES \
				--minimum-mapping-quality 20 \
				--read-filter MappingQualityReadFilter \
				--min-base-quality-score 20 \
				--standard-min-confidence-threshold-for-calling 30 \
				--output ./26-HaplotypeCallerGenotypeVariants/"$SAMPLE"_variant_genotypes_raw.vcf
			else
				if [ $LINKED_DE_BRUIJN_GRAPH = "true" ]
				then
					srun -c "$MAX_CORES" --mem "$MAX_MEM"G "$PATH_TO_GATK4"/gatk --java-options "-Xmx"$MAX_MEM"G" HaplotypeCaller \
					--linked-de-bruijn-graph \
					--native-pair-hmm-threads "$MAX_CORES" \
					--reference $REFERENCE_GENOME \
					--input ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam \
					--alleles "$MAPPING_VARIANTS" \
					--output-mode EMIT_ALL_ACTIVE_SITES \
					--minimum-mapping-quality 20 \
					--read-filter MappingQualityReadFilter \
					--min-base-quality-score 20 \
					--standard-min-confidence-threshold-for-calling 30 \
					--output ./26-HaplotypeCallerGenotypeVariants/"$SAMPLE"_variant_genotypes_raw.vcf
				fi
			fi

			srun -c 1 --mem 4G "$PATH_TO_GATK4"/gatk --java-options "-Xmx4G" SelectVariants \
			--reference $REFERENCE_GENOME \
			--variant ./26-HaplotypeCallerGenotypeVariants/"$SAMPLE"_variant_genotypes_raw.vcf \
			--concordance "$MAPPING_VARIANTS" \
			--output ./26-HaplotypeCallerGenotypeVariants/"$SAMPLE"_mapping_variant_genotypes_raw.vcf

			if [ -f ./26-HaplotypeCallerGenotypeVariants/"$SAMPLE"_mapping_variant_genotypes_raw.vcf ]
			then 
				echo "[`date`] HaplotypeCallerGenotypeVariants completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: HaplotypeCallerGenotypeVariants failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: HaplotypeCallerGenotypeVariants failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi	

#27-GenerateMappingPlots
	# Make mapping plots
	if [ $WORKFLOW = "vda-mapped" ]
	then
		if [ -f ./27-GenerateMappingPlots/"$SAMPLE"_mapping_variant_genotypes.vcf ] &&
		   [ -f ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots.pdf ] &&
		   [ -f ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots_yaxis_zoom.pdf ] 
		then 
			echo "[`date`] GenerateMappingPlots already complete" >> "$SAMPLE"_vda_log.txt
		else 
			if [ -d ./27-GenerateMappingPlots ]
			then
				echo "[`date`] GenerateMappingPlots is incomplete, likely due to this job having previously failed. Removing 27-GenerateMappingPlots directory and starting over." >> "$SAMPLE"_vda_log.txt
				rm -rf ./27-GenerateMappingPlots
			fi
			echo "[`date`] GenerateMappingPlots started" >> "$SAMPLE"_vda_log.txt
			mkdir ./27-GenerateMappingPlots

			# select sites with at least 3 supporting reads
			srun -c 1 --mem 4G java -Xmx4G -jar "$PATH_TO_SNPEFF"/SnpSift.jar \
			filter "( FORMAT = 'GT:AD:DP:GQ:PL' ) && ( DP > 3 )" \
			./26-HaplotypeCallerGenotypeVariants/"$SAMPLE"_mapping_variant_genotypes_raw.vcf > ./27-GenerateMappingPlots/"$SAMPLE"_mapping_variant_genotypes.vcf
						
			# create mapping graphs
			srun -c 1 --mem 4G python "$SCRIPT_DIR"/scripts/SNP_Mapping_v2.0.py \
			-v ./27-GenerateMappingPlots/"$SAMPLE"_mapping_variant_genotypes.vcf \
			-l 0.2 \
			-o ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots \
			-s ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots.pdf
			
			# create mapping graphs with zoomed in y-axis
			srun -c 1 --mem 4G python "$SCRIPT_DIR"/scripts/SNP_Mapping_v2.0.py \
			-v ./27-GenerateMappingPlots/"$SAMPLE"_mapping_variant_genotypes.vcf \
			-l 0.2 \
			-d 0.2 \
			-o ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots_yaxis_zoom \
			-s ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots_yaxis_zoom.pdf
	
			if [ -f ./27-GenerateMappingPlots/"$SAMPLE"_mapping_variant_genotypes.vcf ] &&
			   [ -f ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots.pdf ] &&
			   [ -f ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots_yaxis_zoom.pdf ]
			then 
				echo "[`date`] GenerateMappingPlots completed" >> "$SAMPLE"_vda_log.txt
			else 
				echo "[`date`] ERROR: GenerateMappingPlots failed. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
				mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
				echo "[`date`] ERROR: GenerateMappingPlots failed. Check variant_discovery_analysis.err for details"
				exit 1
			fi
		fi
	fi	

# If analysis mode is set to vda-mapped, then exit script
	if [ $WORKFLOW = "vda-mapped" ]
	then
		echo "[`date`] Reorganizing analysis directory... copying key files to results directory and putting all job directories in "$SAMPLE"_VDA_TEMP_DIR" >> "$SAMPLE"_vda_log.txt
		if [ ! -d results ]; then mkdir results; fi
		cp ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bam ./results
		cp ./10-ApplyBQSR/"$SAMPLE"_merged_dedup_recal.bai ./results
		cp ./11-AnalyzeCovariates/"$SAMPLE"_recalibration_plots.pdf ./results
		cp ./12-DetermineCoverage/"$SAMPLE"_coverage.bed ./results
		cp ./12-DetermineCoverage/"$SAMPLE"_zero_coverage_final.txt ./results
		cp ./12-DetermineCoverage/"$SAMPLE"_genes_with_zero_coverage.txt ./results
		cp ./13-CollectWgsMetrics/"$SAMPLE"_stats.txt ./results
		cp -R ./13-CollectWgsMetrics/"$SAMPLE"_plots ./results
		cp ./13-CollectWgsMetrics/"$SAMPLE"_CollectWgsMetricsWithNonZeroCoverage.txt ./results
		cp ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf ./results	
		cp ./19-SubtractBackgroundHaplotypeCallerVariants/"$SAMPLE"_merged_dedup_recal_raw_hc_variants_filtered_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf.idx ./results		

		if [ $READ_TYPE = "paired-end" ]
		then
			cp ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf ./results
			cp ./20-SubtractBackgroundMantaVariants/"$SAMPLE"_manta_variants_"$PSBV_NAME"_and_"$MSBV_NAME"_subtracted.vcf.idx ./results
		fi

		if [ $ADD_WORMBASE_DATA = "true" ]
		then
			cp ./25-AddWormBaseData/"$SAMPLE"_all_variants_final_with_wormbase_data_added.txt ./results/"$SAMPLE"_all_variants_and_effects.txt
		else
			if [ $CALCULATE_PROVEAN_SCORES = "true" ]
			then
				cp ./24-ProveanMissenseVariants/"$SAMPLE"_all_variants_final_with_provean_scores.txt ./results/"$SAMPLE"_all_variants_and_effects.txt
			else
				cp ./23-MergeVariants/"$SAMPLE"_all_variants_final_without_provean_scores.txt ./results/"$SAMPLE"_all_variants_and_effects.txt
			fi
		fi

		awk 'BEGIN {FS="\t"; OFS="\t"} ($7 == "GENO" && $19 == "IMPACT") || ($7 == "HOM" && $19 == "HIGH") || ($7 == "HOM" && $19 == "MODERATE")' ./results/"$SAMPLE"_all_variants_and_effects.txt > ./results/"$SAMPLE"_homozygous_disruptive_coding_variants.txt
		
		cp ./27-GenerateMappingPlots/"$SAMPLE"_mapping_variant_genotypes.vcf ./results
		cp ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots.pdf ./results
		cp ./27-GenerateMappingPlots/"$SAMPLE"_MappingPlots_yaxis_zoom.pdf ./results

		if [ ! -d "$SAMPLE"_VDA_TEMP_DIR ]; then mkdir "$SAMPLE"_VDA_TEMP_DIR; fi
		
		MOVE_DIRS=$(ls -dlh */ | awk 'BEGIN {FS=" "; OFS=" "} {print $9}' | grep -v results/)
		
		for i in $(echo "$MOVE_DIRS")
		do
			mv "$i" ./"$SAMPLE"_VDA_TEMP_DIR
		done

		if [ $CLEAN_UP = "true" ]
		then 
			echo "[`date`] Removing "$SAMPLE"_VDA_TEMP_DIR" >> "$SAMPLE"_vda_log.txt
			rm -rf ./"$SAMPLE"_VDA_TEMP_DIR
		fi

		if [ -f ./results/"$SAMPLE"_all_variants_and_effects.txt ] &&
		   [ -f ./results/"$SAMPLE"_homozygous_disruptive_coding_variants.txt ]
		then
			echo "[`date`] VDA-MAPPED WORKFLOW COMPLETE!" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] VDA-MAPPED WORKFLOW COMPLETE!"
			exit 0
		else
			echo "[`date`] ERROR: Failed exiting vda-mapped workflow. Check variant_discovery_analysis.err for details" >> "$SAMPLE"_vda_log.txt
			mv "$SAMPLE"_vda_log.txt "$SAMPLE"_vda_log_$(date +"%Y-%m-%d_%H:%M:%S").txt
			echo "[`date`] ERROR: Failed exiting vda-mapped workflow. Check variant_discovery_analysis.err for details"
			exit 1
		fi
	fi

############

STATUS=$?

exit $STATUS


















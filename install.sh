#!/bin/bash
##############################################
# Name		: install.sh
# Version   : 0.0.1
# Author	: Dan Pagano 
# Copyright : Dan Pagano
# License   : GNU General Public License
##############################################

# DESCRIPTION
# Installation and configuration script for VDA Toolkit version 0.0.1

#set -o errexit

USAGE="VDA TOOLKIT INSTALL 

DESCRIPTION
install.sh is a Linux-based installation script designed to download and configure the programs and reference files needed to
run the workflows in VDA Toolkit. This script was built on CentOS release 7.2.1511. 

REQUIREMENTS
GNU Compiler Collection (GCC) (tested with version 6.2.0)
Java 8 JDK (tested with version jdk-1.8u112)

USAGE
install.sh -v <install-provean> -R <install-R> -p <install-python> [options]

EXAMPLE
install.sh -v yes -R yes -p yes [options]

REQUIRED ARGUMENTS
-v, --install-provean <string>	 	 Download provean along with it's dependencies, including
                                         the NCBI nr protein database (August 2011 release), and
                                         configure. Default value: yes. Possible values: {yes, no}

-R, --install-R <string>	 	 Download R-3.6.3 and R packages: ggplot2, reshape, gplots,
                                         and gsalib. You may choose to use a different installation
                                         of R, though ensure that R is added to your path and the
                                         required R packages are installed. Default value: yes.
                                         Possible values: {yes, no}

-p, --install-python <string>	 	 Download Python-2.7.12 and rpy2 package. You may choose to
                                         use a different installation of Python. Python-2.6 or
                                         greater is required. Some tools might not be compatible
                                         with Python-3. Ensure that Python is added to your path and
                                         the rpy2 package is installed. Default value: yes. Possible
                                         values: {yes, no}
" 

# check getopt mode
getopt -T
if [ $? -ne 4 ]
then 
	echo "ERROR: Requires enhanced getopt, obtain new version."
	exit 1
fi

shopt -s -o nounset

INSTALL_PROVEAN=yes
INSTALL_R=yes
INSTALL_PYTHON=yes

# determine whether or not to install provean
SCRIPT="install.sh"
OPTSTRING="v:R:p:Vh"
LOPTSTRING="install-provean:,install-R:,install-python:,verbose,help"

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
		-v|--install-provean)
			shift
			INSTALL_PROVEAN="$1"
		;;	
		-R|--install-R)
			shift
			INSTALL_R="$1"
		;;	
		-p|--install-python)
			shift
			INSTALL_PYTHON="$1"
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

if [ $INSTALL_PROVEAN != "yes" ] && 
   [ $INSTALL_PROVEAN != "no" ]
then
	echo -e "ERROR: --install-provean was defined as "$INSTALL_PROVEAN". Possible values: {yes, no} \n"
	echo "$USAGE"
	exit 1
fi

if [ $INSTALL_R != "yes" ] && 
   [ $INSTALL_R != "no" ]
then
	echo -e "ERROR: --install-R was defined as "$INSTALL_R". Possible values: {yes, no} \n"
	echo "$USAGE"
	exit 1
fi

if [ $INSTALL_PYTHON != "yes" ] && 
   [ $INSTALL_PYTHON != "no" ]
then
	echo -e "ERROR: --install-python was defined as "$INSTALL_PYTHON". Possible values: {yes, no} \n"
	echo "$USAGE"
	exit 1
fi

# change to script directory (ensures downloads are installed in */vda_toolkit)
INSTALL_DIR=$(readlink -f $0)
INSTALL_DIR=${INSTALL_DIR%/*}
cd "$INSTALL_DIR"

# make config file and directories if they don't already exist
if [ ! -f ./config.cfg.defaults ]; then echo "#DEFAULT-CONFIGURATIONS#" > config.cfg.defaults; fi
if [ ! -d ./modules ]; then mkdir modules; fi
if [ ! -d ./reference ]; then mkdir reference; fi
if [ ! -d ./reference/genome ]; then mkdir reference/genome; fi
if [ ! -d ./reference/annotations ]; then mkdir reference/annotations; fi
if [ ! -d ./variants ]; then mkdir variants; fi
if [ ! -d ./variants/background ]; then mkdir variants/background; fi
if [ ! -d ./variants/mapping ]; then mkdir variants/mapping; fi
if [ ! -d ./variants/blacklist ]; then mkdir variants/blacklist; fi
if [ ! -d ./scripts ]; then mkdir scripts; fi
if [ ! -d ./data ]; then mkdir data; fi
if [ ! -d ./data/wormbase ]; then mkdir data/wormbase; fi

# install gatk-4.1.4.1
if [ -f ./modules/gatk-4.1.4.1/gatk ] 
then 
	echo "[`date`] gatk-4.1.4.1 already installed"
else 
	echo "[`date`] Installing gatk-4.1.4.1"
	cd ./modules
	wget https://github.com/broadinstitute/gatk/releases/download/4.1.4.1/gatk-4.1.4.1.zip
	unzip gatk-4.1.4.1.zip
	rm gatk-4.1.4.1.zip
	cd ..
	if [ -f ./modules/gatk-4.1.4.1/gatk ]
	then
		grep -v PATH_TO_GATK4 config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "PATH_TO_GATK4=\"\$SCRIPT_DIR\"/modules/gatk-4.1.4.1" >> config.cfg.defaults
		echo "[`date`] gatk-4.1.4.1 installation complete"
	else
		echo "[`date`] gatk-4.1.4.1 installation failed"
		exit 1
	fi
fi

# install GenomeAnalysisTK-3.8-1
if [ -f ./modules/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef/GenomeAnalysisTK.jar ] 
then 
	echo "[`date`] GenomeAnalysisTK-3.8-1-0 already installed"
else 
	echo "[`date`] Installing GenomeAnalysisTK-3.8-1"
	cd ./modules
	wget https://storage.googleapis.com/gatk-software/package-archive/gatk/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef.tar.bz2
	bunzip2 -d GenomeAnalysisTK-3.8-1-0-gf15c1c3ef.tar.bz2
	tar -xvf GenomeAnalysisTK-3.8-1-0-gf15c1c3ef.tar
	rm GenomeAnalysisTK-3.8-1-0-gf15c1c3ef.tar
	cd ..
	if [ -f ./modules/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef/GenomeAnalysisTK.jar ]
	then
		grep -v PATH_TO_GATK3 config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "PATH_TO_GATK3=\"\$SCRIPT_DIR\"/modules/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef" >> config.cfg.defaults
		echo "[`date`] GenomeAnalysisTK-3.8-1-0 installation complete"
	else
		echo "[`date`] GenomeAnalysisTK-3.8-1-0 installation failed"
		exit 1
	fi
fi

# install bwa-0.7.17
if [ -f ./modules/bwa-0.7.17/bwa ] 
then 
	echo "[`date`] bwa-0.7.17 already installed"
else 
	echo "[`date`] Installing bwa-0.7.17"
	cd ./modules
	wget https://github.com/lh3/bwa/releases/download/v0.7.17/bwa-0.7.17.tar.bz2
	bunzip2 -d bwa-0.7.17.tar.bz2
	tar -xvf bwa-0.7.17.tar
	cd ./bwa-0.7.17; make
	cd ..
	rm bwa-0.7.17.tar
	cd ..
	if [ -f ./modules/bwa-0.7.17/bwa ] 
	then
		grep -v PATH_TO_BWA config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "PATH_TO_BWA=\"\$SCRIPT_DIR\"/modules/bwa-0.7.17" >> config.cfg.defaults
		echo "[`date`] bwa-0.7.17 installation complete"
	else
		echo "[`date`] bwa-0.7.17 installation failed"
		exit 1
	fi
fi

# install samtools-1.10
if [ -f ./modules/samtools-1.10/samtools ] 
then 
	echo "[`date`] samtools-1.10 already installed"
else 
	echo "[`date`] Installing samtools-1.10"
	cd ./modules
	wget https://github.com/samtools/samtools/releases/download/1.10/samtools-1.10.tar.bz2
	bunzip2 -d samtools-1.10.tar.bz2
	tar -xvf samtools-1.10.tar
	cd ./samtools-1.10
	./configure
	make
	cd ..
	rm samtools-1.10.tar
	cd ..
	if [ -f ./modules/samtools-1.10/samtools ] 
	then
		grep -v PATH_TO_SAMTOOLS config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "PATH_TO_SAMTOOLS=\"\$SCRIPT_DIR\"/modules/samtools-1.10" >> config.cfg.defaults
		echo "[`date`] samtools-1.10 installation complete"
	else
		echo "[`date`] samtools-1.10 installation failed"
		exit 1
	fi
fi

# install bedtools-2.29.2
if [ -f ./modules/bedtools2/bin/bedtools ] 
then 
	echo "[`date`] bedtools-2.29.2 already installed"
else 
	echo "[`date`] Installing bedtools-2.29.2"
	cd ./modules
	wget https://github.com/arq5x/bedtools2/releases/download/v2.29.2/bedtools-2.29.2.tar.gz
	tar -xzvf bedtools-2.29.2.tar.gz
	cd ./bedtools2
	make
	cd ..
	rm bedtools-2.29.2.tar.gz
	cd ..
	if [ -f ./modules/bedtools2/bin/bedtools ] 
	then
		grep -v PATH_TO_BEDTOOLS2 config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "PATH_TO_BEDTOOLS2=\"\$SCRIPT_DIR\"/modules/bedtools2/bin" >> config.cfg.defaults
		echo "[`date`] bedtools-2.29.2 installation complete"
	else
		echo "[`date`] bedtools-2.29.2 installation failed"
		exit 1
	fi
fi

# install snpEff_v4_3t
if [ -f ./modules/snpEff/snpEff.jar ] &&
   [ -f ./modules/snpEff/data/WBcel235.86/snpEffectPredictor.bin ]
then 
	echo "[`date`] snpEff_v4_3t already installed"
else 
	echo "[`date`] Installing snpEff_v4_3t"
	cd ./modules
	wget https://sourceforge.net/projects/snpeff/files/snpEff_v4_3t_core.zip/download
	unzip download
	cd ./snpEff
	java -jar snpEff.jar download -v WBcel235.86
	cd ..
	rm download
	cd ..
	if [ -f ./modules/snpEff/snpEff.jar ] &&
	   [ -f ./modules/snpEff/data/WBcel235.86/snpEffectPredictor.bin ]	
	then
		grep -v PATH_TO_SNPEFF config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		grep -v SNPEFF_DATABASE config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "PATH_TO_SNPEFF=\"\$SCRIPT_DIR\"/modules/snpEff" >> config.cfg.defaults
		echo "SNPEFF_DATABASE=WBcel235.86" >> config.cfg.defaults
		echo "[`date`] snpEff_v4_3t installation complete"
	else
		echo "[`date`] snpEff_v4_3t installation failed"
		exit 1
	fi
fi

# install manta-1.6.0
if [ -f ./modules/manta-1.6.0.centos6_x86_64/bin/configManta.py ] 
then 
	echo "[`date`] manta-1.6.0 already installed"
else 
	echo "[`date`] Installing manta-1.6.0"
	cd ./modules
	wget https://github.com/Illumina/manta/releases/download/v1.6.0/manta-1.6.0.centos6_x86_64.tar.bz2
	bunzip2 -d manta-1.6.0.centos6_x86_64.tar.bz2
	tar -xvf manta-1.6.0.centos6_x86_64.tar
	rm manta-1.6.0.centos6_x86_64.tar
	cd ..
	if [ -f ./modules/manta-1.6.0.centos6_x86_64/bin/configManta.py ] 
	then
		grep -v PATH_TO_MANTA config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "PATH_TO_MANTA=\"\$SCRIPT_DIR\"/modules/manta-1.6.0.centos6_x86_64" >> config.cfg.defaults
		echo "[`date`] manta-1.6.0 installation complete"
	else
		echo "[`date`] manta-1.6.0 installation failed"
		exit 1
	fi
fi

# install strelka-2.9.10
if [ -f ./modules/strelka-2.9.10.centos6_x86_64/bin/configureStrelkaGermlineWorkflow.py ] 
then 
	echo "[`date`] strelka-2.9.10 already installed"
else 
	echo "[`date`] Installing strelka-2.9.10"
	cd ./modules
	wget https://github.com/Illumina/strelka/releases/download/v2.9.10/strelka-2.9.10.centos6_x86_64.tar.bz2
	bunzip2 -d strelka-2.9.10.centos6_x86_64.tar.bz2
	tar -xvf strelka-2.9.10.centos6_x86_64.tar
	rm strelka-2.9.10.centos6_x86_64.tar
	cd ..
	if [ -f ./modules/strelka-2.9.10.centos6_x86_64/bin/configureStrelkaGermlineWorkflow.py ] 
	then
		grep -v PATH_TO_STRELKA config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "PATH_TO_STRELKA=\"\$SCRIPT_DIR\"/modules/strelka-2.9.10.centos6_x86_64" >> config.cfg.defaults
		echo "[`date`] strelka-2.9.10 installation complete"
	else
		echo "[`date`] strelka-2.9.10 installation failed"
		exit 1
	fi
fi

if [ $INSTALL_PROVEAN = "yes" ]
then
	# install ncbi-blast-2.4.0+
	if [ -f ./modules/ncbi-blast-2.4.0+/bin/blastdbcmd ] 
	then 
		echo "[`date`] ncbi-blast-2.4.0+ already installed"
	else 
		echo "[`date`] Installing ncbi-blast-2.4.0+"
		cd ./modules
		wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.4.0/ncbi-blast-2.4.0+-x64-linux.tar.gz
		tar -xzvf ncbi-blast-2.4.0+-x64-linux.tar.gz
		rm ncbi-blast-2.4.0+-x64-linux.tar.gz
		cd ..
		if [ -f ./modules/ncbi-blast-2.4.0+/bin/blastdbcmd ] 
		then
			echo "[`date`] ncbi-blast-2.4.0+ installation complete"
		else
			echo "[`date`] ncbi-blast-2.4.0+ installation failed"
			exit 1
		fi
	fi

	# install cd-hit-v4.8.1
	if [ -f ./modules/cd-hit-v4.8.1-2019-0228/cd-hit ] 
	then 
		echo "[`date`] cd-hit-v4.8.1 already installed"
	else 
		echo "[`date`] Installing cd-hit-v4.8.1"
		cd ./modules
		wget https://github.com/weizhongli/cdhit/releases/download/V4.8.1/cd-hit-v4.8.1-2019-0228.tar.gz
		tar -xzvf cd-hit-v4.8.1-2019-0228.tar.gz
		cd cd-hit-v4.8.1-2019-0228
		make
		cd ..
		rm cd-hit-v4.8.1-2019-0228.tar.gz
		cd ..
		if [ -f ./modules/cd-hit-v4.8.1-2019-0228/cd-hit ] 
		then
			echo "[`date`] cd-hit-v4.8.1 installation complete"
		else
			echo "[`date`] cd-hit-v4.8.1 installation failed"
			exit 1
		fi
	fi

	# install provean-1.1.5
	if [ -f ./modules/provean-1.1.5/bin/provean.sh ] 
	then 
		echo "[`date`] provean-1.1.5 already installed"
	else 
		echo "[`date`] Installing provean-1.1.5"
		cd ./modules
		wget https://sourceforge.net/projects/provean/files/provean-1.1.5.tar.gz/download
		tar -xzvf download
		cd provean-1.1.5
		mkdir nr_Aug_2011
		cd nr_Aug_2011
		wget ftp://ftp.jcvi.org/pub/data/provean/nr_Aug_2011/*tar.gz
		tar -xzvf nr.00.tar.gz
		rm nr.00.tar.gz	
		tar -xzvf nr.01.tar.gz
		rm nr.01.tar.gz
		tar -xzvf nr.02.tar.gz
		rm nr.02.tar.gz
		tar -xzvf nr.03.tar.gz
		rm nr.03.tar.gz
		tar -xzvf nr.04.tar.gz
		rm nr.04.tar.gz
		tar -xzvf nr.05.tar.gz
		rm nr.05.tar.gz
		cd ..
		./configure --prefix="$INSTALL_DIR"/modules/provean-1.1.5 BLAST_DB="$INSTALL_DIR"/modules/provean-1.1.5/nr_Aug_2011/nr PSIBLAST="$INSTALL_DIR"/modules/ncbi-blast-2.4.0+/bin/psiblast BLASTDBCMD="$INSTALL_DIR"/modules/ncbi-blast-2.4.0+/bin/blastdbcmd CDHIT="$INSTALL_DIR"/modules/cd-hit-v4.8.1-2019-0228/cd-hit
		make
		make install
		cd ..
		rm download
		cd ..
		if [ -f ./modules/provean-1.1.5/bin/provean.sh ] 
		then
			grep -v PATH_TO_PROVEAN config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
			echo "PATH_TO_PROVEAN=\"\$SCRIPT_DIR\"/modules/provean-1.1.5" >> config.cfg.defaults
			echo "[`date`] provean-1.1.5 installation complete"
		else
			echo "[`date`] provean-1.1.5 installation failed"
			exit 1
		fi
	fi
fi

# download C. elegans reference genome fasta and index
if [ -f ./reference/genome/ce11.fasta ] &&
   [ -f ./reference/genome/ce11.dict ] &&
   [ -f ./reference/genome/ce11.fasta.fai ] &&
   [ -f ./reference/genome/ce11.sa ]
then 
	echo "[`date`] ce11 already downloaded and indexed"
else 
	echo "[`date`] Downloading ce11"
	cd ./reference/genome
	rm -rf *
	rsync -avzP rsync://hgdownload.cse.ucsc.edu/goldenPath/ce11/chromosomes/ .
	gzip -d chr*.fa.gz
	cat chrI.fa chrII.fa chrIII.fa chrIV.fa chrM.fa chrV.fa chrX.fa > ce11.fasta
	rm chr*.fa
	rm md5sum.txt
	rm README.txt
	"$INSTALL_DIR"/modules/gatk-4.1.4.1/gatk CreateSequenceDictionary --REFERENCE ce11.fasta --OUTPUT ce11.dict
	"$INSTALL_DIR"/modules/samtools-1.10/samtools faidx ce11.fasta
	"$INSTALL_DIR"/modules/bwa-0.7.17/bwa index -p ce11 ce11.fasta
	cd ../..
	if [ -f ./reference/genome/ce11.fasta ] &&
	   [ -f ./reference/genome/ce11.dict ] &&
	   [ -f ./reference/genome/ce11.fasta.fai ] &&
	   [ -f ./reference/genome/ce11.sa ]
	then
		grep -v REFERENCE_GENOME config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "REFERENCE_GENOME=\"\$SCRIPT_DIR\"/reference/genome/ce11.fasta" >> config.cfg.defaults
		echo "[`date`] ce11 download and indexing complete"
	else
		echo "[`date`] ce11 download and indexing failed"
		exit 1
	fi
fi

# download C. elegans annotation file
if [ -f ./reference/annotations/Caenorhabditis_elegans.WBcel235.86.gtf ]
then 
	echo "[`date`] WBcel235.86 annotations already downloaded"
else 
	echo "[`date`] Downloading WBcel235.86 annotations"
	cd ./reference/annotations
	wget ftp://ftp.ensembl.org/pub/release-86/gtf/caenorhabditis_elegans/Caenorhabditis_elegans.WBcel235.86.gtf.gz
	gzip -d Caenorhabditis_elegans.WBcel235.86.gtf.gz
	sed -i -e 's/\bI\b/chrI/' Caenorhabditis_elegans.WBcel235.86.gtf
	sed -i -e 's/\bII\b/chrII/' Caenorhabditis_elegans.WBcel235.86.gtf
	sed -i -e 's/\bIII\b/chrIII/' Caenorhabditis_elegans.WBcel235.86.gtf
	sed -i -e 's/\bIV\b/chrIV/' Caenorhabditis_elegans.WBcel235.86.gtf
	sed -i -e 's/\bV\b/chrV/' Caenorhabditis_elegans.WBcel235.86.gtf
	sed -i -e 's/\bX\b/chrX/' Caenorhabditis_elegans.WBcel235.86.gtf
	sed -i -e 's/\bMtDNA\b/chrM/' Caenorhabditis_elegans.WBcel235.86.gtf
	sed -i -e 's/gene_id/gene_name/g' Caenorhabditis_elegans.WBcel235.86.gtf
	sed -i -E 's/(.*)gene_name/\1gene_id/' Caenorhabditis_elegans.WBcel235.86.gtf
	cd ../..
	if [ -f ./reference/annotations/Caenorhabditis_elegans.WBcel235.86.gtf ]
	then
		grep -v ANNOTATIONS config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
		echo "ANNOTATIONS=\"\$SCRIPT_DIR\"/reference/annotations/Caenorhabditis_elegans.WBcel235.86.gtf" >> config.cfg.defaults
		echo "[`date`] WBcel235.86 annotations download complete"
	else
		echo "[`date`] WBcel235.86 annotations download failed"
		exit 1
	fi
fi

if [ $INSTALL_R = "yes" ]
then
	# install R and R packages: ggplot2, reshape, gplots, gsalib
	if [ -f ./modules/R-3.6.3/bin/R ] &&
	   [ -d ./modules/R-3.6.3/library/ggplot2 ] &&
	   [ -d ./modules/R-3.6.3/library/reshape ] &&
	   [ -d ./modules/R-3.6.3/library/gplots ] &&
	   [ -d ./modules/R-3.6.3/library/gsalib ]
	then 
		echo "[`date`] R and R packages: ggplot2, reshape, gplots, gsalib already installed"
	else 
		echo "[`date`] Installing R and R packages: ggplot2, reshape, gplots, gsalib"
		cd ./modules
		wget https://cran.r-project.org/src/base/R-3/R-3.6.3.tar.gz
		tar -xzvf R-3.6.3.tar.gz
		cd R-3.6.3
		./configure
		make
		cd ..
		rm R-3.6.3.tar.gz
		export PATH="$INSTALL_DIR"/modules/R-3.6.3/bin/:$PATH
		Rscript -e 'install.packages("ggplot2", repos="http://cran.rstudio.com", lib="./R-3.6.3/library/")'
		Rscript -e 'install.packages("reshape", repos="http://cran.rstudio.com", lib="./R-3.6.3/library/")'
		Rscript -e 'install.packages("gplots", repos="http://cran.rstudio.com", lib="./R-3.6.3/library/")'
		Rscript -e 'install.packages("gsalib", repos="http://cran.rstudio.com", lib="./R-3.6.3/library/")'
		cd ..
		if [ -f ./modules/R-3.6.3/bin/R ] &&
	       [ -d ./modules/R-3.6.3/library/ggplot2 ] &&
	       [ -d ./modules/R-3.6.3/library/reshape ] &&
	       [ -d ./modules/R-3.6.3/library/gplots ] &&
	       [ -d ./modules/R-3.6.3/library/gsalib ]
		then
			grep -v LOCAL_R_PATH config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
			echo "LOCAL_R_PATH=\"\$SCRIPT_DIR\"/modules/R-3.6.3/bin/" >> config.cfg.defaults
			grep -v LOCAL_R_LIBS config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
			echo "LOCAL_R_LIBS=\"\$SCRIPT_DIR\"/modules/R-3.6.3/library/" >> config.cfg.defaults
			echo "[`date`] R and R packages: ggplot2, reshape, gplots, gsalib installation complete"
		else
			echo "[`date`] R and R packages: ggplot2, reshape, gplots, gsalib installation failed"
			exit 1
		fi
	fi
fi

if [ $INSTALL_PYTHON = "yes" ]
	then
	# install python
	if [ -f ./modules/Python-2.7.12/python ]
	then 
		echo "[`date`] Python already installed"
	else 
		echo "[`date`] Installing Python and rpy2 package"
		cd ./modules
		wget https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tgz
		tar -xzvf Python-2.7.12.tgz 
		cd Python-2.7.12
		./configure
		make
		export PATH="$INSTALL_DIR"/modules/Python-2.7.12/:$PATH
		python setup.py install --user
	    pip install --user rpy2==2.7.9
		cd ..
		rm Python-2.7.12.tgz
		PYTHON_USER=$(python -m site --user-site)
		cd ..
		if [ -f ./modules/Python-2.7.12/python ] &&
	   	   [ -d "$PYTHON_USER"/rpy2 ]
		then
			grep -v LOCAL_PYTHON_PATH config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
			echo "LOCAL_PYTHON_PATH=\"\$SCRIPT_DIR\"/modules/Python-2.7.12/" >> config.cfg.defaults
			echo "[`date`] Python and rpy2 package installation complete"
		else
			echo "[`date`] Python and rpy2 package installation failed"
			exit 1
		fi
	fi
fi

grep -v BLACKLISTED_VARIANTS config.cfg.defaults > config.temp && mv config.temp config.cfg.defaults
echo "BLACKLISTED_VARIANTS=\"\$SCRIPT_DIR\"/variants/blacklist/ce11_blacklist.vcf" >> config.cfg.defaults

sed 's/DEFAULT-CONFIGURATIONS/USER-DEFINED-CONFIGURATIONS/' config.cfg.defaults | sed 's/=.*$//' > config.cfg

STATUS=$?

exit $STATUS
#Authors: Renato Oliveira. Gisele Nunces, Raíssa Oliveira
#version: 1.7
#Date: 02-03-2021

###    Copyright (C) 2021  Renato Oliveira
###
###    This program is free software: you can redistribute it and/or modify
###    it under the terms of the GNU General Public License as published by
###    the Free Software Foundation, either version 3 of the License, or
###    any later version.
###
###    This program is distributed in the hope that it will be useful,
###    but WITHOUT ANY WARRANTY; without even the implied warranty of
###    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
###    GNU General Public License for more details.
###
###    You should have received a copy of the GNU General Public License
###    along with this program.  If not, see <http://www.gnu.org/licenses/>.

###Contacts:
###    guilherme.oliveira@itv.org
###    renato.renison@gmail.com

#bin/sh
##usage: ./pimba_plot.sh -t <otu_table> -a <tax_assignment> -m <metadata> -g <group_by>
#-t <otu_table> = OTU table generated by pimba_run
#-a <tax_assignment> = Tax assignment file generated by pimba_run
#-m <metadata> = CSV file with columns "sample_id", and other attributes related to each sample
#-g <groupby> = A column from the metadata that will group the results. Eg, Description. If one does
#			 not want to group the results, do not specify it.

#SCRIPT_PATH=/bio/share_bio/utils/renato/QiimePipe
#SCRIPT_PATH=/home/pbd001/ITV/PIMBA/lulu_dada_phyloseq/Renato/Renato/Phyloseq_data_script

while getopts "t:a:m:g:" opt; do
	case $opt in
		t) OTU_TABLE="$OPTARG"
		;;
		a) TAX_ASSIGNMENT="$OPTARG"
		;;
		m) METADATA="$OPTARG"
		;;
		g) GROUPBY="$OPTARG"
		;;
		\?) echo "Invalid option -$OPTARG" >&2
    	;;
	esac
done

DIR_TAX=$(dirname $TAX_ASSIGNMENT)
FILE_TAX=$(basename $TAX_ASSIGNMENT)
cp $TAX_ASSIGNMENT ${DIR_TAX}/plot_${FILE_TAX}
PLOT_TAX=${DIR_TAX}/plot_${FILE_TAX}

chmod +x $OTU_TABLE $TAX_ASSIGNMENT $METADATA

sed -i '1s/^/otu_id\tkingdom\tphylum\tclass\torder\tfamily\tgenus\tspecies\tsimilarity\n/' $PLOT_TAX
sed -i -e 's/;/\t/g' $PLOT_TAX
sed -i -e 's/k__//g' $PLOT_TAX
sed -i -e 's/ p__//g' $PLOT_TAX
sed -i -e 's/ c__//g' $PLOT_TAX
sed -i -e 's/ o__//g' $PLOT_TAX
sed -i -e 's/ f__//g' $PLOT_TAX
sed -i -e 's/ g__//g' $PLOT_TAX
sed -i -e 's/ s__//g' $PLOT_TAX
sed -i -e 's/Unassigned/Unassigned\tUnassigned\tUnassigned\tUnassigned\tUnassigned\tUnassigned\tUnassigned/g' $PLOT_TAX


CURRENT_PATH=$(pwd)

DIR_NAME_OTU=$(dirname $OTU_TABLE)
cd $DIR_NAME_OTU
FULL_PATH_OTU=$(pwd)

DIR_NAME_TAX=$(dirname $TAX_ASSIGNMENT)
cd $DIR_NAME_TAX
FULL_PATH_TAX=$(pwd)

DIR_NAME_META=$(dirname $METADATA)
cd $DIR_NAME_META
FULL_PATH_META=$(pwd)

cd $CURRENT_PATH

COMMON_PATH=$({ echo $FULL_PATH_OTU; echo $FULL_PATH_TAX; echo $FULL_PATH_META;} | sed -e 'N;s/^\(.*\).*\n\1.*$/\1\n\1/;D')

OTU_TABLE=$(echo ${FULL_PATH_OTU#"$COMMON_PATH"})/$(basename $OTU_TABLE)
PLOT_TAX=$(echo ${FULL_PATH_TAX#"$COMMON_PATH"})/$(basename $PLOT_TAX)
METADATA=$(echo ${FULL_PATH_META#"$COMMON_PATH"})/$(basename $METADATA)


mkdir plots
chmod -R 777 plots
cd plots

echo "Creating a Phyloseq Container: "
docker run -id -v $COMMON_PATH:/common/ -v $CURRENT_PATH:/output/ --name phyloseq itvdsbioinfo/pimba_phyloseq:latest bash

echo "Running the Phyloseq Container: "
docker exec -i phyloseq /bin/bash -c 'cd /output/plots; \
	Rscript /data/Phyloseq_pimba.R /common/'${OTU_TABLE}' /common/'${PLOT_TAX}' /common/'${METADATA}' '$GROUPBY'; \
	chmod -R 777 /output/plots;'

#Rscript ${SCRIPT_PATH}/Phyloseq_pimba.R ../${OTU_TABLE} ../plot_${TAX_ASSIGNMENT} ../${METADATA} $GROUPBY

docker stop phyloseq
docker rm phyloseq

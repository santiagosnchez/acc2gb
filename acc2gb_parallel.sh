#!/bin/bash

die() { echo -e "$@" 1>&2 ; exit 1; }

help_message="
#############################
##### acc2gb_parallel #######
#############################

#######
First run without arguments (API key)
#######

Then try:
chmod +x acc2gb_parallel.sh
./acc2gb_parallel.sh -list accession_list.txt -gb new_genbank_file.gb
"

download_files()
{
    args = $@
    acclist = ${args[0]}
    gbfile = ${args[1]}
    echo "Downloading to ${gblist}"
    cat ${acclist} | parallel --progress "curl -s 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id='{}'${NCBI_API_KEY}&rettype=gb&retmode=text'" > $2
    echo -e "\nNumber of records downloaded:  $(grep -c '//' ${gblist})"
    echo "Number of records not found: $(grep -c 'Failed to retrieve sequence' ${gbfile})"
}

# first ask for the API key
# and store it in ~/.bashrc

source ~/.bashrc
if [[ -z $NCBI_API_KEY ]]; then
    echo -n "An api key is required. If you don't have one, go to https://www.ncbi.nlm.nih.gov/myncbi/ and request one.
If you do have one, paste the key here: "
    read api_key
    echo "export NCBI_API_KEY=$api_key" >> ~/.bashrc
    die "Key stored in ~/.bashrc"
else
    echo "Key found: $NCBI_API_KEY"
fi

# continue if key is found
# go through arguments

acclist=''
gbfile=''
if [[ "$*" == -h* || "$*" == '' ]]; then
    die "$help_message"
else
    for i in `seq 0 $#`; do
        if [[ "${@[$i]}" == "-list" ]]; then
            $acclist=${@[$(( i+1 ))]}
    fi
fi

# check if gb file has not been created already

if [ -f $2 ]; then
	echo -n "File $2 already exists, replace?[y|n]:"
	read replace
	if [[ $replace == "y" ]]; then
		rm $2
	else 
		die "Exiting...\n"
	fi
fi

# check if list is empty

check=`[ -s $1 ]; echo $?`

if [[ $check == 0 ]]; then

	# check for duplicates

	dupl=`sort $1 | uniq -c | awk '$1 !~ 1'`

	if [[ ${#dupl} == 0 ]]; then

		# retreive data
		download_files 
	else
		# show duplicates

		echo -e "\nDuplicates:\n$dupl"

		# create new list

		sort $1 | uniq -c | awk '{print $2}' > "unique_$1"
		echo -e "\nA new list file uniq_$1 was created\n\n"
		
		# retreive data

		echo "Downloading to $2..."
		cat "unique_$1" | parallel --progress "curl -s 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id='{}'&${NCBI_API_KEY}&rettype=gb&retmode=text'" > $2
		echo -e "\nNumber of records downloaded:  $(grep -c '//' $2)"
		echo "Number of records not found: $(grep -c 'Failed to retrieve sequence' $2)"
	fi
else
	die "File: $1 is empty. Exiting...\n"
fi

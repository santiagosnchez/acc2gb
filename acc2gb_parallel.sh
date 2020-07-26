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
./acc2gb_parallel.sh [ -h | -threads INT -gb OUTPUTFILE ] -list INPUTFILE

[-h|-help]      Prints this help message
-list    STR    Path to the file with a list of GenBank accessions
(optional)
-gb      STR    Path/name to/of the GenBank output file
                If empty, the default name is \"out_genbank.gb\"
-threads INT    Number of threads to use. Default is to use all threads.
"

check_parallel()
{
    parallel -V &> /dev/null
    if [[ $? != 0 ]]; then
        echo -en "gnu-parallel is not installed. See https://www.gnu.org/software/parallel/ for installations.
Run single threaded?[y|n]:"
        read single
        if [[ "$single" == "n" ]]; then
            die "Exiting..."
        else
            echo 1
        fi
    else
        echo 0
    fi
}

download_files()
{
    args=($@)
    acclist=${args[0]}
    gbfile=${args[1]}
    threads=${args[2]}
    echo "Downloading to ${gblist}"
    if [[ $threads == 0 ]]; then
        cat ${acclist} | parallel --progress \ 
        "curl -s 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id='{}'&api_key=${NCBI_API_KEY}&rettype=gb&retmode=text'" > $gbfile
    elif [[ $threads == 1 ]]; then
        for acc in `cat ${acclist}`; do
            curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${acc}&api_key=${NCBI_API_KEY}&rettype=gb&retmode=text"
        done > $gbfile
    else
       cat ${acclist} | parallel --progress -j $threads \ 
       "curl -s 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id='{}'&api_key=${NCBI_API_KEY}&rettype=gb&retmode=text'" > $gbfile
    fi
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

# chech if gnu-parallel is installed
threads=`check_parallel`

# continue if key is found
# go through arguments

acclist=''
gbfile=''
threads=''
args=($@)
if [[ "$*" == -h* || "$*" == '' ]]; then
    die "$help_message"
else
    for i in `seq 0 $#`; do
        if [[ "${args[$i]}" == '-list' ]]; then
            acclist=${args[$(( i+1 ))]}
        elif [[ "${args[$i]}" == '-gb' ]]; then
            gbfile=${args[$(( i+1 ))]}
        elif [[ "${args[$i]}" == '-threads' ]]; then
            threads=${args[$(( i+1 ))]}
        else
            die "$help_message"
        fi
    done
fi
# check arg variables
if [[ ${#acclist} == 0 ]]; then
    die "No file name given to accession list"
fi
if [[ ${#acclist} == 0 ]]; then
    gbfile="out_genbank.gb"
fi
if [[ ${#threads} == 0 ]]; then
    threads=0
fi

# check if gb file has not been created already

if [ -f $gbfile ]; then
    echo -n "File $gbfile already exists, replace?[y|n]:"
    read replace
    if [[ $replace == "y" ]]; then
        rm $gbfile
    else 
        die "Exiting...\n"
    fi
fi

# check if list is empty

check=`[ -s $acclist ]; echo $?`

if [[ $check == 0 ]]; then
    # check for duplicates
    echo "Checking for duplicates..."
    dupl=`sort $acclist | uniq -c | awk '$1 !~ 1'`
    if [[ ${#dupl} == 0 ]]; then
        # retreive data
        echo "Downloading to $gbfile..."
        download_files $acclist $gbfile $threads
    else
        # show duplicates
        echo -e "\nDuplicates:\n$dupl"
        # create new list
        sort $acclist | uniq > "unique_${acclist}"
        echo -e "\nA new list file uniq_${acclist} was created\n\n"	
        # retreive data
        echo "Downloading to $gbfile..."
        download_files $acclist $gbfile $threads
else
	die "File: $acclist is empty. Exiting...\n"
fi

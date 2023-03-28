# Overall script to make thesis race plots. Contains commands for svn, cvs, and git (I can only vouch for the git ones because I wrote them - Kirsty). Once this is set up correctly you should be able to run everything just by doing ./countthesis.sh (note: it will only add to the file thesiscount_xxx.txt - if you want to regenerate the count completely you need to delete it)

#!/bin/bash

# Tom's commands (commented out - Kirsty)
#on a new machine need to:
#cd $RALREPO/tdealtry/thesis/thesiscount/
#svn co https://hepsvn.pp.rl.ac.uk/repos/t2k/tdealtry/thesis/thesis/

dateNow=$(date +"%Y-%m-%d")

# This function loops through all dates since your last addition to thesiscount_xxx.txt and adds the word count since then (it updates from every commit)
function makecounts {
    name=$1
    texDir=$2
    texFile=$3
    initDate=$4
    endDate=$5

    echo Calculating thesis edits up to $endDate

    # Kirsty's commands - download thesis into a new directory so none of this accidentally writes over your current work
    if [ ! -d "$texDir$" ]; then
	git clone git@github.com:/dbarrow257/Thesis.git $texDir
    fi

    oldpwd=`pwd`

    # Make sure git is on the right branch in new directory
    cd $texDir
    git status;
    cd $oldpwd

    i=1

    rm thesiscount_${name}.txt

    dateStr=$initDate
    k=0
    l=0
    for j in `cat thesiscount_${name}.txt`; do
        k=$((k+1))
        if [ $((k%3)) == 0 ]; then
            #echo | expr k % 3                                                                                                                                                                              
            l=$((l+1))
            echo ${l}
            dateStr=$(date -d "${initDate} ${l} day" +"%Y-%m-%d")
            echo dateStr is $dateStr
        fi
    done

    # Now this bit adds extra lines to thesiscount_xxx.txt. For every day since the last date in thesiscount_xxx.txt it downloads the most recent commit, counts the words, and adds an entry for that date to thesiscount_xxx.txt.
    echo "Starting loop"
    
    dateStr=$(date -d "${dateStr} -1 day" +"%Y-%m-%d")
    while [ "$dateStr" '<' "$endDate" ]; do
        #first time i=0

	# Get the right date
        #dateStr=$(date -d "${dateStr} ${i} day" +"%Y-%m-%d")
	dateStr=$(date -d "${dateStr} 1 day" +"%Y-%m-%d")
        echo dateStr is $dateStr

	# Change to the dummy directory where you are downloading old versions (so you don't overwrite your current work)
        cd ${texDir}

	# Get the latest version for that date
	#svn up -r {$dateStr}
        #echo $CVSROOT
        #cvs up -D "$dateStr" #USER="waldron" #PSWD="" #&>/dev/null
	git rev-list -n1 --before="${dateStr}" master | xargs git checkout --force
	
	## Use texcount to get number of words
	## -noerror doesn't exist in texcount.pl help page?
	## -inc makes it parse included tex files
	## -1 ensures there's only one line of output
	## -sum makes sure the output is just the total number
        unixTime=`date -d "$dateStr" +%s`

	if [ ${unixTime} -gt 1659999601 ]; then
	    nWords=$(../texcount.pl -1 -sum ./Text/*.tex)
	else 
            nWords=$(../texcount.pl -1 -sum ./*.tex)
	fi
	#find . -name '*.tex'
        #nWords=$(find . -name '*.tex' | xargs wc -w | tail -1 | awk '{print $1}')

	# Change back to original directory to update thesiscount_xxx.txt
        cd $oldpwd

        echo $dateStr $nWords $unixTime | tee -a thesiscount_${name}.txt
        i=$((i+1))
    done
}

# This is the command that the script runs (calls the function above)
# Syntax: makecounts [name] [dummy folder for downloading old versions of code] [name of main thesis tex file] [date you started writing] [date you want to plot up to (if you haven't submitted yet, use $dateNow)]
makecounts Dan Thesiscount_temp Thesis.tex 2022-05-16 2022-10-03

# This stuff was commented out when I got the code - Kirsty
#source /data/minos/software/setup_minos_oxford.sh development
#loon -bq plot_thesis_count.C+
#root plot_thesis_count.C+

# Make the pretty plots (calls root)
module load root

root -l -b -q plot_thesis_count.C+;

# Remove dummy folder (to stop it clogging up your file structure and confusing everyone)


#!/bin/bash
# note: re-generating days is possible. Just delete the dates you want regenerated
# from the top (!!) of the changelog file in $OUT/system/etc/Changelog.txt
# 2nd line of the file must be the date to fetch from!!

export Changelog=Changelog.txt
export PassedDays=7 # change this to limit max changelog days

if [ -f "${OUT}/system/etc/${Changelog}" ] # if changelog already generated
then
	cp "${OUT}/system/etc/${Changelog}" $Changelog
	LastDate=`sed '2!d' $Changelog` # get 2nd line of changelog file
	LastDate="$(echo -e "${LastDate}" | tr -d '[:space:]')" # get rid of whitespaces
	# extract month day and year from string:
	Month=${LastDate:0:2}
	Day=${LastDate:3:2}
	Year=${LastDate:6:4}
	LastDate=`date -d "${Year}${Month}${Day}" +%s`
	TimeNow=`date +%s` # current time
	DayDiff=$(( (TimeNow - LastDate) / 86400 )) # n/o days passed
	if [[ $DayDiff < $PassedDays ]]; then # don't fetch more than max days
		export PassedDays=$DayDiff
		mv $Changelog "${Changelog}.bak" # save current changelog for later
	fi
	touch $Changelog
else
	touch $Changelog
fi

if [[ $PassedDays == 0 ]]; then
	echo "Already have today"
	rm $Changelog
	rm "${Changelog}.bak"
	exit 0
else
	echo "Regenerating log of last ${PassedDays} days"
	if [ -f "${OUT}/system/etc/${Changelog}" ]; then
		rm "${OUT}/system/etc/${Changelog}"
		rm "${OUT}/${Changelog}"
	fi
fi

echo "Generating changelog..."

for i in $(seq $PassedDays);
do
export After_Date=`date --date="$i days ago" +%m-%d-%Y`
k=$(expr $i - 1)
	export Until_Date=`date --date="$k days ago" +%m-%d-%Y`

	# Line with after --- until was too long for a small ListView
	echo '====================' >> $Changelog;
	echo "     "$Until_Date     >> $Changelog;
	echo '====================' >> $Changelog;
	echo >> $Changelog;

	# Cycle through every repo to find commits between 2 dates
	repo forall -pc 'git log --oneline --after=$After_Date --until=$Until_Date' >> $Changelog
	echo >> $Changelog;
done

sed -i 's/project/   */g' $Changelog

if [ -f "${Changelog}.bak" ]
then
	cat "${Changelog}.bak" >> $Changelog # restore old changelog to the end of current one
	rm "${Changelog}.bak"
fi

cp $Changelog $OUT/system/etc/
cp $Changelog $OUT/
rm -rf $Changelog

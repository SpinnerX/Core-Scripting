#!/bin/bash

student="/home/$USER" # Getting students directory
git_init=".git" # Making sure git is initialized in students directory
git_config=".gitconfig"
datetime=$(date) # Grabbing the timestamp of the current date to the commit
current_dir=$PWD


# Anomaly variables
# Thresholds for what an average should be when modifying a file (including the time it takes to actually write those lines)
# time_limit="3600" # 3600 seconds is 1 hour.
time_limit="60" # 60 seconds is 1 minute
line_limit=10 # 10 lines should not be copied and pasted in 10 minutes.

# Checking if we are in the students homework directory (which we want to run there only)
# We only want this script running in the students hw directory
# .gitconfig setup is for their entire student acct, but every hw dir is a git repo.
if [ $student == $current_dir ]; then
	# echo "Need to run this script in your homework directory"
	exit 1
fi

# Setting up one time git initialization if student doesn't have .git already.
# If .gitconfig not setup the we know we have not setup the username and email globally to their student account
if [ ! -f $student/$git_config ]; then
    echo "Enter your email: "
    read email
    echo "Enter username: "
    read username

    git config --global user.email $email
    git config --global user.name $username
fi

# This is to make sure that homework dirs are a repository, if not then we initialized before doing git workflow
if [ ! -d $current_dir/$git_init ]; then
	git init $current_dir > /dev/null 2>&1
fi

extensions=(cc cpp h java) # This handles extensions for .cc, .cc, .cpp, .java, etc. As valid file extensions, allowing us to add valid extensions easier.

# Going through all the extensions making sure they are valid.
for exe in ${extensions[@]}
	do
		# We check if any files with valid extensions have been modifed
		files_status=$(git status --porcelain *.$exe)

		# This basically only extacts the *.extensions[@] which is only checking for valid file extensions in the array
		files_extract=$(git status --porcelain *.$exe | cut -d' ' -f2-) 
		
		# We want to check if any of the files within this directory has been either modified or untracked (to track or commit these unknown changes)
		if [[ -n "$files_status" ]]; then
			for file in $files_extract
				do
					git add $current_dir/$file > /dev/null 2>&1
					git commit -m "Logged Homework Date: $datetime" > /dev/null 2>&1 # This is to silence any output so students dont see the output, but allows us to see errors.
				done
		fi

	done

# Handling Anomalies
check_commit=$(git log --oneline | wc -l) # This lets us know that if we have more then one commit use the previous commit, if not then use current commit

declare -i commitSize=$check_commit # Just declaring as an actual int for using operators: -lt, -gt, -eq, -ne, etc since these works only with integers

# This is just so we dont have any issues regarding which commit to use.
# If we have no commits we use the current commit, if we have commits use the previous commit (though this can also just change if you want to use the current commit)
#if [ $check_commit -ne "1" ]; then
#	commit=HEAD^ 
#else
#	commit=HEAD
#fi
if [ $commitSize -ne 1 ]; then
	commit=HEAD^ 
else
	commit=HEAD
fi


commit_hash=$commit # This is to get the commit hash


commit_date=$(git log -1 --pretty="%ad" --date=iso-strict "$commit_hash") # Parsing specific date of the commit
current_unix_timestamp=$(date -d "$commit_date" +%s) # grabs the timestamp of that commit
current_unix_time=$(date -d "$current_time" +%s) # Parsing that timestamp to specifically grab the time.

lines_modified=$(git diff --numstat $commit_hash | awk '{print $1}') # Gives us how many lines have been added/modified

time_diff=$((current_unix_time - current_unix_timestamp))

commit_hash_id=$(git rev-parse $commit_hash) # This just returns the commit hash id.

# This is converting these string integers into actual integers (just so we can simply use -gt)
declare -i linesModified=$lines_modified
declare -i limit=$line_limit

# This is basically grabbing the diff of time and checking the student is actually working on the homework (instead of copying and pasting onto their file.
# if [[ $time_diff -lt $time_limit && $lines_modified -gt $line_limit ]]; then
#if [ $lines_modified -gt $line_limit ]; then
#	/public/./sus_log $commit_hash_id
#fi

if [ $linesModified -gt $limit ]; then
	/public/./sus_log $commit_hash_id
fi

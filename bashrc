#!/usr/bin/env bash


common_profile() {
	# git commands
	alias gsi="git stash --include-untracked"
}


work_profile() {
    	echo "Switching to Work Profile..."

	common_profile

	# restart platform
	alias yp="yarn platform"
	alias rp="yarn packages:build && yp"
	alias frp="yarn && rp"

	# restart studio
	alias ys="yarn studio"
	alias rs="yarn packages:build && ys"
	alias frs="yarn && rs"
}

home_profile() {
	echo "Switching to Home Profile..."
	
	common_profile
}


if [ -f ~/.current_profile ]; then
    source ~/.current_profile
fi

save_profile() {
    if [ "$1" == "work" ]; then
        echo "work_profile" > ~/.current_profile
    elif [ "$1" == "home" ]; then
        echo "home_profile" > ~/.current_profile
    fi
}

switch_profile() {
    if [ "$1" == "work" ]; then
        work_profile
    elif [ "$1" == "home" ]; then
        home_profile
    else
        echo "Usage: switch_profile {work|home}"
    fi
}
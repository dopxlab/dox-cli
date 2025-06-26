#!/bin/bash

# Function to print text in a specified color (text and background color)
# Usage: print <foreground_color> <background_color> <text>
# If only one argument is passed, it prints the text in green (32) text and black (40) background by default.
# If two arguments are passed, the first is treated as the foreground (text) color and the second as the background color.
# If three arguments are passed, the first one is the foreground color, the second is the background color, and the third is the text.
print() {
    # Default colors if only one argument is passed
    if [ $# -eq 1 ]; then
        local text="$1"
        local fg_color="32"  # Default to green text (32)
        local bg_color=""  # No background color (transparent) for black background (40)
    elif [ $# -eq 2 ]; then
        # If two arguments are passed, treat the first one as foreground color and the second as background color
        local fg_color="$1"
        local bg_color=""  # No background color (transparent) for black background (40)
        local text="$2"
    elif [ $# -eq 3 ]; then
        # If three arguments are passed, treat them as foreground color, background color, and text
        local fg_color="$1"
        local bg_color="$2"
        local text="$3"
    else
        echo "Usage: print <foreground_color> <background_color> <text>"
        return 1
    fi

    # Print the text with specified colors
    echo -e "\033[${fg_color};${bg_color}m${text}\033[0m"
}

# Function to print environment variables in a simple stylish format
# Usage: print_envs VAR1 VAR2 VAR3 ...
print_envs() {
    local border="--------------------------------------------------"
    print "36" "40" "$border"  # Cyan on black
    for var in "$@"; do
        local value="${!var}"
        if [ -z "$value" ]; then
            value="<Not Set>"
            print "31" "40" "$(printf '%-25s : %s' "$var" "$value")"  # Red for unset
        else
            print "32" "40" "$(printf '%-25s : %s' "$var" "$value")"  # Green for set
        fi
    done
    print "36" "40" "$border"
}

# Function to print a warning message in yellow text (Replace "" with 40 for black background)
# Usage: warn <text>
info() {
    print "34" "" "$1"  # Blue text (34) 
}

# Function to print a warning message in yellow text (Replace "" with 40 for black background)
# Usage: warn <text>
warn() {
    print "33" "" "$1"  # Yellow text (33) 
}

# Function to print an error message in red text (Replace "" with 40 for black background)
# Usage: error <text>
error() {
    print "31" "" "$1"  # Red text (31)
}

# Function to print a step message with a separator
# Usage: print_step <step_name>
# Prints a step message with cyan separators and yellow "Starting:" text. (Replace "" with 40 for black background)
print_step() {
    local step_name="$1"
    echo ""
    print "36" "" "----------------------------------------------------"  # Cyan text 
    print "33" "" "Starting: $step_name"  # Yellow text
    print "36" "" "----------------------------------------------------"  # Cyan text
    echo ""
}

# Debug function: prints only if DEBUG_MODE is true
debug() {
    if [ -n "$DEBUG_MODE" ] && [ "$DEBUG_MODE" = "true" ]; then
        # Print message line by line with dark background
        while IFS= read -r line; do
            printf "\033[93;40m  %s\033[0m\n" "$line"
        done <<< "$1"
    fi
}

# Color Codes Documentation:

# Foreground (Text) Color Codes:
# These are the numeric values you can use for the text color when calling print.

# Foreground Color Codes:
#   ["black"]=30
#   ["red"]=31
#   ["green"]=32
#   ["yellow"]=33
#   ["blue"]=34
#   ["magenta"]=35
#   ["cyan"]=36
#   ["white"]=37
#   ["brightblack"]=90
#   ["brightred"]=91
#   ["brightgreen"]=92
#   ["brightyellow"]=93
#   ["brightblue"]=94
#   ["brightmagenta"]=95
#   ["brightcyan"]=96
#   ["brightwhite"]=97

# Background Color Codes:
# These are the numeric values you can use for background. Use the number for the background color when calling print.

# Background Color Codes:
#   ["black"]=40
#   ["red"]=41
#   ["green"]=42
#   ["yellow"]=43
#   ["blue"]=44
#   ["magenta"]=45
#   ["cyan"]=46
#   ["white"]=47

# Usage Examples:

# 1. Print a text in green (default behavior with one argument)
#print "This is a green text on black background"

# 2. Print a text in red text with yellow background (2 arguments)
#print "31" "43" "This is red text on yellow background"

# 3. Print a custom color with a background (3 arguments, blue text on white background)
#print "34" "47" "This is blue text on white background"

# 4. Print a warning message in yellow text on black background (use "warn" as argument)
#warn "This is a warning message in yellow text on black background"

# 5. Print an error message in red text on black background (use "error" as argument)
#error "This is an error message in red text on black background"

# 6. Using print_step to print a step message
#print_step "Setup Configuration"

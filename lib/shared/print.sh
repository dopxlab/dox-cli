#!/bin/bash

# Function to print text in a specified color (text and background color)
# Usage: print <text>
#        print <foreground_color> <text>
#        print <foreground_color> <background_color> <text>
print() {
    # Default colors
    local fg_color="32"  # Default to green text
    local bg_color="40"  # Default black background
    local text=""

    if [ $# -eq 1 ]; then
        # Only text provided, use defaults
        text="$1"
    elif [ $# -eq 2 ]; then
        # Foreground color and text provided
        fg_color="$1"
        text="$2"
    elif [ $# -eq 3 ]; then
        # Foreground color, background color, and text provided
        fg_color="$1"
        bg_color="$2"
        text="$3"
    else
        echo "Usage: print [foreground_color] [background_color] <text>"
        return 1
    fi

    # Print the text with specified colors (bold text, no background color applied)
    echo -e "\033[1;${fg_color}m${text}\033[0m"
}

# Function to print environment variables in a simple stylish format
# Usage: print_envs VAR1 VAR2 VAR3 ...
print_envs() {
    local border="--------------------------------------------------"
    print "33" "$border"  # Yellow text
    for var in "$@"; do
        local value="${!var}"
        if [ -z "$value" ]; then
            value="<Not Set>"
            print "31" "$(printf '%-25s : %s' "$var" "$value")"  # Red for unset
        else
            print "33" "$(printf '%-25s : %s' "$var" "$value")"  # Yellow for set
        fi
    done
    print "33" "$border"
}

# Function to print an info message in blue text
# Usage: info <text>
info() {
    print "34" "$1"  # Blue text (34)
}

# Function to print a warning message in yellow text
# Usage: warn <text>
warn() {
    print "33" "$1"  # Yellow text (33)
}

# Function to print an error message in red text
# Usage: error <text>
error() {
    print "31" "$1"  # Red text (31)
}

# Function to print a step message with a separator
# Usage: print_step <step_name>
print_step() {
    local step_name="$1"
    echo ""
    print "33" "----------------------------------------------------"
    print "33" "Starting: $step_name"
    print "33" "----------------------------------------------------"
    echo ""
}
version() {
    if [ "${DEBUG_MODE:-false}" = "true" ] || [ "${PRINT_VERSION:-false}" = "true" ]; then
        print "90" "$(printf '%-15s : %s' "$1" "$2")"
    fi  
}
# Debug function: prints only if DEBUG_MODE is true
debug() {
    if [ "${DEBUG_MODE:-false}" = "true" ]; then
        # Print message line by line with yellow text
        while IFS= read -r line; do
            printf "\033[93m  %s\033[0m\n" "$line"
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
# print "This is a green text"

# 2. Print a text in red text (2 arguments)
# print "31" "This is red text"

# 3. Print a custom color with a background (3 arguments, blue text on white background)
# print "34" "47" "This is blue text on white background"

# 4. Print a warning message in yellow text
# warn "This is a warning message"

# 5. Print an error message in red text
# error "This is an error message"

# 6. Print an info message in blue text
# info "This is an info message"

# 7. Using print_step to print a step message
# print_step "Setup Configuration"
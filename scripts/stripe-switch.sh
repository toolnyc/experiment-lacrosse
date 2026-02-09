#!/bin/bash

# Stripe Account Switcher
# Interactive tool for switching between Stripe CLI accounts

CONFIG_FILE="$HOME/.config/stripe/config.toml"

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get all configured projects from the config file
get_projects() {
    if [[ -f "$CONFIG_FILE" ]]; then
        grep '^\[' "$CONFIG_FILE" | tr -d '[]' | grep -v '^$'
    fi
}

# Get current active project
get_current() {
    if [[ -f "$CONFIG_FILE" ]]; then
        grep "^project-name" "$CONFIG_FILE" | cut -d"'" -f2
    fi
}

# Get display name for a project
get_display_name() {
    local project="$1"
    grep -A10 "^\[$project\]" "$CONFIG_FILE" | grep "display_name" | head -1 | cut -d"'" -f2
}

# Get account mode (test/live) indicator
get_mode_indicator() {
    local project="$1"
    local has_live=$(grep -A10 "^\[$project\]" "$CONFIG_FILE" | grep "live_mode_api_key" | head -1)
    local has_test=$(grep -A10 "^\[$project\]" "$CONFIG_FILE" | grep "test_mode_api_key" | head -1)

    if [[ -n "$has_live" && -n "$has_test" ]]; then
        echo "test + live"
    elif [[ -n "$has_live" ]]; then
        echo "live only"
    elif [[ -n "$has_test" ]]; then
        echo "test only"
    fi
}

# Switch to a project
switch_to() {
    local project="$1"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^project-name = .*/project-name = '$project'/" "$CONFIG_FILE"
    else
        sed -i "s/^project-name = .*/project-name = '$project'/" "$CONFIG_FILE"
    fi
}

# Main interactive menu
show_menu() {
    local current=$(get_current)
    local projects=($(get_projects))
    local count=${#projects[@]}

    echo ""
    echo -e "${BOLD}Stripe Account Switcher${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ $count -eq 0 ]]; then
        echo -e "${RED}No Stripe accounts configured.${NC}"
        echo ""
        echo "Run 'stripe login' to connect your first account."
        exit 1
    fi

    echo -e "${BLUE}Connected accounts:${NC}"
    echo ""

    local i=1
    for project in "${projects[@]}"; do
        local display=$(get_display_name "$project")
        local mode=$(get_mode_indicator "$project")
        local marker=""

        if [[ "$project" == "$current" ]]; then
            marker="${GREEN} ← active${NC}"
        fi

        echo -e "  ${BOLD}$i)${NC} ${display:-$project}"
        if [[ -n "$mode" ]]; then
            echo -e "     ${YELLOW}[$mode]${NC}${marker}"
        else
            echo -e "     ${marker}"
        fi
        echo ""
        ((i++))
    done

    echo -e "━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${BOLD}n)${NC} Connect new account"
    echo -e "  ${BOLD}q)${NC} Quit"
    echo ""
    echo -n "Choose an account (1-$count) or action: "

    read -r choice

    case "$choice" in
        q|Q|quit|exit)
            echo "Bye!"
            exit 0
            ;;
        n|N|new|add)
            echo ""
            echo -n "Enter a name for this account (e.g., 'my-project'): "
            read -r new_name
            if [[ -n "$new_name" ]]; then
                echo ""
                echo "Opening browser to authenticate..."
                echo "After authenticating, run this script again to switch accounts."
                echo ""
                stripe login --project-name "$new_name"
            fi
            exit 0
            ;;
        [1-9]|[1-9][0-9])
            if [[ $choice -ge 1 && $choice -le $count ]]; then
                local selected="${projects[$((choice-1))]}"
                local display=$(get_display_name "$selected")

                if [[ "$selected" == "$current" ]]; then
                    echo ""
                    echo -e "${YELLOW}Already using ${display:-$selected}${NC}"
                else
                    switch_to "$selected"
                    echo ""
                    echo -e "${GREEN}Switched to ${display:-$selected}${NC}"
                fi
            else
                echo ""
                echo -e "${RED}Invalid choice${NC}"
            fi
            ;;
        *)
            # Try to match by name
            local matched=""
            for project in "${projects[@]}"; do
                local display=$(get_display_name "$project")
                if [[ "${project,,}" == "${choice,,}" ]] || [[ "${display,,}" == *"${choice,,}"* ]]; then
                    matched="$project"
                    break
                fi
            done

            if [[ -n "$matched" ]]; then
                local display=$(get_display_name "$matched")
                if [[ "$matched" == "$current" ]]; then
                    echo ""
                    echo -e "${YELLOW}Already using ${display:-$matched}${NC}"
                else
                    switch_to "$matched"
                    echo ""
                    echo -e "${GREEN}Switched to ${display:-$matched}${NC}"
                fi
            else
                echo ""
                echo -e "${RED}Unknown option: $choice${NC}"
            fi
            ;;
    esac
}

# Handle command line arguments for non-interactive use
if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help|help)
            echo "Stripe Account Switcher"
            echo ""
            echo "Usage:"
            echo "  stripe-switch          Interactive menu"
            echo "  stripe-switch <name>   Switch to account by name"
            echo "  stripe-switch --list   List all accounts"
            echo "  stripe-switch --add    Connect a new account"
            echo ""
            exit 0
            ;;
        -l|--list|list)
            current=$(get_current)
            echo ""
            echo "Connected Stripe accounts:"
            for project in $(get_projects); do
                display=$(get_display_name "$project")
                if [[ "$project" == "$current" ]]; then
                    echo "  * ${display:-$project} (active)"
                else
                    echo "    ${display:-$project}"
                fi
            done
            echo ""
            exit 0
            ;;
        -a|--add|add|new)
            echo -n "Enter a name for this account: "
            read -r new_name
            if [[ -n "$new_name" ]]; then
                stripe login --project-name "$new_name"
            fi
            exit 0
            ;;
        *)
            # Direct switch by name
            projects=($(get_projects))
            for project in "${projects[@]}"; do
                display=$(get_display_name "$project")
                if [[ "${project,,}" == "${1,,}" ]] || [[ "${display,,}" == *"${1,,}"* ]]; then
                    switch_to "$project"
                    echo "Switched to ${display:-$project}"
                    exit 0
                fi
            done
            echo "Account not found: $1"
            echo "Run 'stripe-switch --list' to see available accounts"
            exit 1
            ;;
    esac
fi

# Default: show interactive menu
show_menu

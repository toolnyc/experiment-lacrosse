#!/bin/bash

# Environment Switcher for Vercel + Stripe
# Manages multiple accounts for both services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/env-switch"
VERCEL_AUTH_DIR="$HOME/Library/Application Support/com.vercel.cli"
STRIPE_CONFIG="$HOME/.config/stripe/config.toml"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Ensure config directory exists
mkdir -p "$CONFIG_DIR/vercel"

# ============================================
# Vercel Account Management
# ============================================

vercel_get_current() {
    vercel whoami 2>/dev/null | tail -1
}

vercel_save_current() {
    local name="$1"
    local auth_file="$VERCEL_AUTH_DIR/auth.json"

    if [[ -f "$auth_file" ]]; then
        cp "$auth_file" "$CONFIG_DIR/vercel/${name}.auth.json"
        echo -e "${GREEN}Saved current Vercel auth as '$name'${NC}"
    else
        echo -e "${RED}No Vercel auth found. Run 'vercel login' first.${NC}"
        return 1
    fi
}

vercel_list_saved() {
    local current=$(vercel_get_current)
    echo ""
    echo -e "${BOLD}Saved Vercel Accounts:${NC}"

    local found=0
    shopt -s nullglob
    for f in "$CONFIG_DIR/vercel"/*.auth.json; do
        if [[ -f "$f" ]]; then
            local name=$(basename "$f" .auth.json)
            found=1
            if [[ "$name" == "$current" ]]; then
                echo -e "  ${GREEN}* $name (active)${NC}"
            else
                echo -e "    $name"
            fi
        fi
    done
    shopt -u nullglob

    if [[ $found -eq 0 ]]; then
        echo -e "  ${DIM}No saved accounts. Use 'save' to save current login.${NC}"
    fi
}

vercel_switch_to() {
    local name="$1"
    local saved_auth="$CONFIG_DIR/vercel/${name}.auth.json"
    local auth_file="$VERCEL_AUTH_DIR/auth.json"

    if [[ ! -f "$saved_auth" ]]; then
        echo -e "${RED}No saved auth for '$name'${NC}"
        echo "Available accounts:"
        ls -1 "$CONFIG_DIR/vercel"/*.auth.json 2>/dev/null | xargs -I{} basename {} .auth.json | sed 's/^/  /'
        return 1
    fi

    # Backup current if not already saved
    local current=$(vercel_get_current)
    if [[ -n "$current" && ! -f "$CONFIG_DIR/vercel/${current}.auth.json" ]]; then
        cp "$auth_file" "$CONFIG_DIR/vercel/${current}.auth.json" 2>/dev/null
    fi

    # Switch
    cp "$saved_auth" "$auth_file"
    echo -e "${GREEN}Switched Vercel to '$name'${NC}"

    # Show new identity
    echo -e "${DIM}Logged in as: $(vercel whoami 2>/dev/null | tail -1)${NC}"
}

# ============================================
# Stripe Account Management (wrapper)
# ============================================

stripe_get_current() {
    if [[ -f "$STRIPE_CONFIG" ]]; then
        local project=$(grep "^project-name" "$STRIPE_CONFIG" | cut -d"'" -f2)
        local display=$(grep -A10 "^\[$project\]" "$STRIPE_CONFIG" | grep "display_name" | head -1 | cut -d"'" -f2)
        echo "${display:-$project}"
    fi
}

stripe_list() {
    if [[ -f "$STRIPE_CONFIG" ]]; then
        local current_project=$(grep "^project-name" "$STRIPE_CONFIG" | cut -d"'" -f2)
        echo ""
        echo -e "${BOLD}Stripe Accounts:${NC}"

        grep '^\[' "$STRIPE_CONFIG" | tr -d '[]' | while read -r project; do
            local display=$(grep -A10 "^\[$project\]" "$STRIPE_CONFIG" | grep "display_name" | head -1 | cut -d"'" -f2)
            if [[ "$project" == "$current_project" ]]; then
                echo -e "  ${GREEN}* ${display:-$project} (active)${NC}"
            else
                echo -e "    ${display:-$project}"
            fi
        done
    else
        echo -e "  ${DIM}No Stripe accounts configured. Run 'stripe login'.${NC}"
    fi
}

stripe_switch_to() {
    local name="$1"

    if [[ -f "$STRIPE_CONFIG" ]]; then
        # Find project by name or display name
        local matched=""
        while read -r project; do
            local display=$(grep -A10 "^\[$project\]" "$STRIPE_CONFIG" | grep "display_name" | head -1 | cut -d"'" -f2)
            if [[ "${project,,}" == "${name,,}" ]] || [[ "${display,,}" == *"${name,,}"* ]]; then
                matched="$project"
                break
            fi
        done < <(grep '^\[' "$STRIPE_CONFIG" | tr -d '[]')

        if [[ -n "$matched" ]]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/^project-name = .*/project-name = '$matched'/" "$STRIPE_CONFIG"
            else
                sed -i "s/^project-name = .*/project-name = '$matched'/" "$STRIPE_CONFIG"
            fi
            local display=$(grep -A10 "^\[$matched\]" "$STRIPE_CONFIG" | grep "display_name" | head -1 | cut -d"'" -f2)
            echo -e "${GREEN}Switched Stripe to '${display:-$matched}'${NC}"
        else
            echo -e "${RED}Stripe account not found: $name${NC}"
            return 1
        fi
    fi
}

# ============================================
# Environment Profiles
# ============================================

save_profile() {
    local name="$1"
    local profile_file="$CONFIG_DIR/profiles/${name}.profile"

    mkdir -p "$CONFIG_DIR/profiles"

    local vercel_user=$(vercel_get_current)
    local stripe_account=$(stripe_get_current)

    cat > "$profile_file" << EOF
# Environment Profile: $name
# Created: $(date)

VERCEL_ACCOUNT="$vercel_user"
STRIPE_ACCOUNT="$stripe_account"
EOF

    # Also save Vercel auth
    vercel_save_current "$vercel_user" 2>/dev/null

    echo -e "${GREEN}Saved profile '$name':${NC}"
    echo -e "  Vercel: $vercel_user"
    echo -e "  Stripe: $stripe_account"
}

load_profile() {
    local name="$1"
    local profile_file="$CONFIG_DIR/profiles/${name}.profile"

    if [[ ! -f "$profile_file" ]]; then
        echo -e "${RED}Profile not found: $name${NC}"
        echo "Available profiles:"
        ls -1 "$CONFIG_DIR/profiles"/*.profile 2>/dev/null | xargs -I{} basename {} .profile | sed 's/^/  /'
        return 1
    fi

    source "$profile_file"

    echo -e "${BOLD}Loading profile: $name${NC}"
    echo ""

    if [[ -n "$VERCEL_ACCOUNT" ]]; then
        vercel_switch_to "$VERCEL_ACCOUNT"
    fi

    if [[ -n "$STRIPE_ACCOUNT" ]]; then
        stripe_switch_to "$STRIPE_ACCOUNT"
    fi
}

list_profiles() {
    echo ""
    echo -e "${BOLD}Environment Profiles:${NC}"

    local found=0
    shopt -s nullglob
    for f in "$CONFIG_DIR/profiles"/*.profile; do
        if [[ -f "$f" ]]; then
            found=1
            local name=$(basename "$f" .profile)
            source "$f"
            echo -e "  ${BOLD}$name${NC}"
            echo -e "    Vercel: ${VERCEL_ACCOUNT:-not set}"
            echo -e "    Stripe: ${STRIPE_ACCOUNT:-not set}"
            echo ""
        fi
    done
    shopt -u nullglob

    if [[ $found -eq 0 ]]; then
        echo -e "  ${DIM}No profiles saved. Use 'save <name>' to create one.${NC}"
    fi
}

# ============================================
# Status Display
# ============================================

show_status() {
    echo ""
    echo -e "${BOLD}Current Environment${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${BLUE}Vercel:${NC} $(vercel_get_current 2>/dev/null || echo 'not logged in')"
    echo -e "${BLUE}Stripe:${NC} $(stripe_get_current 2>/dev/null || echo 'not configured')"
    echo ""
}

# ============================================
# Interactive Menu
# ============================================

show_menu() {
    show_status

    echo -e "${BOLD}Quick Actions:${NC}"
    echo ""
    echo -e "  ${BOLD}1)${NC} Switch Vercel account"
    echo -e "  ${BOLD}2)${NC} Switch Stripe account"
    echo -e "  ${BOLD}3)${NC} Load environment profile"
    echo -e "  ${BOLD}4)${NC} Save current as profile"
    echo -e "  ${BOLD}5)${NC} Save current Vercel login"
    echo ""
    echo -e "  ${BOLD}q)${NC} Quit"
    echo ""
    echo -n "Choice: "

    read -r choice

    case "$choice" in
        1)
            vercel_list_saved
            echo ""
            echo -n "Switch to (or 'login' for new): "
            read -r name
            if [[ "$name" == "login" ]]; then
                echo ""
                echo "After logging in, run this script and use 'save' to store the account."
                vercel login
            else
                vercel_switch_to "$name"
            fi
            ;;
        2)
            stripe_list
            echo ""
            echo -n "Switch to (or 'login' for new): "
            read -r name
            if [[ "$name" == "login" ]]; then
                echo -n "Name for this account: "
                read -r new_name
                stripe login --project-name "$new_name"
            else
                stripe_switch_to "$name"
            fi
            ;;
        3)
            list_profiles
            echo -n "Load profile: "
            read -r name
            load_profile "$name"
            ;;
        4)
            echo -n "Profile name: "
            read -r name
            save_profile "$name"
            ;;
        5)
            echo -n "Save current Vercel login as: "
            read -r name
            vercel_save_current "$name"
            ;;
        q|Q)
            exit 0
            ;;
    esac
}

# ============================================
# CLI Interface
# ============================================

print_help() {
    echo "Environment Switcher - Manage Vercel & Stripe accounts"
    echo ""
    echo "Usage:"
    echo "  env-switch                    Interactive menu"
    echo "  env-switch status             Show current environment"
    echo ""
    echo "Profiles:"
    echo "  env-switch profiles           List all profiles"
    echo "  env-switch save <name>        Save current env as profile"
    echo "  env-switch load <name>        Load a profile"
    echo ""
    echo "Vercel:"
    echo "  env-switch vercel             List saved Vercel accounts"
    echo "  env-switch vercel <name>      Switch to Vercel account"
    echo "  env-switch vercel save <n>    Save current Vercel login"
    echo "  env-switch vercel login       Login to new Vercel account"
    echo ""
    echo "Stripe:"
    echo "  env-switch stripe             List Stripe accounts"
    echo "  env-switch stripe <name>      Switch to Stripe account"
    echo ""
    echo "Examples:"
    echo "  env-switch save experiment    # Save current setup as 'experiment'"
    echo "  env-switch load lacrosse-lab  # Switch to lacrosse-lab profile"
    echo "  env-switch vercel hugetool    # Switch Vercel to hugetool"
    echo "  env-switch stripe 'Lacrosse'  # Switch Stripe by display name"
}

# Main CLI handler
case "${1:-}" in
    ""|menu)
        show_menu
        ;;
    status|st)
        show_status
        vercel_list_saved
        stripe_list
        ;;
    profiles|list)
        list_profiles
        ;;
    save)
        if [[ -z "$2" ]]; then
            echo "Usage: env-switch save <profile-name>"
            exit 1
        fi
        save_profile "$2"
        ;;
    load|use)
        if [[ -z "$2" ]]; then
            list_profiles
            exit 1
        fi
        load_profile "$2"
        ;;
    vercel)
        case "${2:-}" in
            "")
                vercel_list_saved
                ;;
            save)
                if [[ -z "$3" ]]; then
                    echo "Usage: env-switch vercel save <name>"
                    exit 1
                fi
                vercel_save_current "$3"
                ;;
            login)
                echo "After logging in, run 'env-switch vercel save <name>' to store the account."
                vercel login
                ;;
            *)
                vercel_switch_to "$2"
                ;;
        esac
        ;;
    stripe)
        case "${2:-}" in
            "")
                stripe_list
                ;;
            login)
                echo -n "Name for this account: "
                read -r new_name
                stripe login --project-name "$new_name"
                ;;
            *)
                stripe_switch_to "$2"
                ;;
        esac
        ;;
    -h|--help|help)
        print_help
        ;;
    *)
        # Try loading as profile name
        if [[ -f "$CONFIG_DIR/profiles/${1}.profile" ]]; then
            load_profile "$1"
        else
            echo "Unknown command: $1"
            echo "Run 'env-switch --help' for usage"
            exit 1
        fi
        ;;
esac

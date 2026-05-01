 #!/usr/bin/env bash
## Simplified Power Menu for Lenovo IdeaPad Gaming 3
## Focus: Conservation Mode, Performance Modes, Rapid Charge
## Icons: Nerd Fonts

HELPER="${HOME}/scripts/lenovo_power_ctl.sh"

require_passwordless_sudo() {
    if sudo -n "$HELPER" get-conservation >/dev/null 2>&1; then
        return 0
    fi

    notify-send "󰀦 Power Modes" "Passwordless sudo is not configured for Lenovo power controls yet." -u critical
    return 1
}

helper() {
    sudo -n "$HELPER" "$@"
}

# Function to get conservation mode status
get_conservation_status() {
    helper get-conservation 2>/dev/null || echo "N/A"
}

# Function to toggle conservation mode
toggle_conservation() {
    local new_state
    new_state="$(helper toggle-conservation 2>/dev/null)" || {
        notify-send "󰀦 Error" "Conservation mode could not be changed" -u critical
        return 1
    }

    if [ "$new_state" = "ON" ]; then
        notify-send "󰂎 Conservation Mode" "ENABLED (Capped at ~60%)" -t 2000
    else
        notify-send "󰂎 Conservation Mode" "DISABLED (Full charge)" -t 2000
    fi
}

# Function to get current performance mode
get_performance_mode() {
    helper get-performance 2>/dev/null || echo "Unknown"
}

# Function to set performance mode
set_performance_mode() {
    if ! helper set-performance "$1" >/dev/null 2>&1; then
        notify-send "󰀦 Error" "Performance mode could not be changed" -u critical
        return 1
    fi

    case "$1" in
        Extreme) notify-send "󰓅 Performance Mode" "Set to Extreme Performance" -t 2000 ;;
        Intelligent) notify-send "󰔏 Performance Mode" "Set to Intelligent Cooling" -t 2000 ;;
        Battery) notify-send "󰂎 Performance Mode" "Set to Battery Saving" -t 2000 ;;
    esac
}

# Function to get rapid charge status
get_rapid_charge() {
    helper get-rapid-charge 2>/dev/null || echo "Unknown"
}

# Function to toggle rapid charge
toggle_rapid_charge() {
    local new_state
    new_state="$(helper toggle-rapid-charge 2>/dev/null)" || {
        notify-send "󰀦 Error" "Rapid Charge could not be changed" -u critical
        return 1
    }

    if [ "$new_state" = "ON" ]; then
        notify-send "󱐋 Rapid Charge" "ENABLED" -t 2000
    else
        notify-send "󱐋 Rapid Charge" "DISABLED" -t 2000
    fi
}

require_passwordless_sudo || exit 1

# Get current status
CONSERVATION_STATUS=$(get_conservation_status)
PERFORMANCE_STATUS=$(get_performance_mode)
RAPID_CHARGE_STATUS=$(get_rapid_charge)

# Create the menu with Nerd Font icons
CHOICE=$(echo -e "󰂎  Conservation: $CONSERVATION_STATUS\n󰓅  Performance: $PERFORMANCE_STATUS\n󱐋  Rapid Charge: $RAPID_CHARGE_STATUS\n󰁯  Refresh Status" | \
    rofi -dmenu -i -p "Power >" \
    -theme ~/.config/rofi/text/style-3.rasi)

case "$CHOICE" in
    *"Conservation"*)
        toggle_conservation
        ;;
    *"Performance"*)
        # Sub-menu for performance modes
        SUBCHOICE=$(echo -e "󰔏  Intelligent Cooling\n󰓅  Extreme Performance\n󰂎  Battery Saving" | \
            rofi -dmenu -i -p "Performance Mode >"\
            -theme ~/.config/rofi/text/style-3.rasi)
        case "$SUBCHOICE" in
            *"Intelligent"*) set_performance_mode "Intelligent" ;;
            *"Extreme"*) set_performance_mode "Extreme" ;;
            *"Battery"*) set_performance_mode "Battery" ;;
        esac
        ;;
    *"Rapid Charge"*)
        toggle_rapid_charge
        ;;
    *"Refresh"*)
        # Just exit, Rofi will show updated status when reopened
        ;;
esac

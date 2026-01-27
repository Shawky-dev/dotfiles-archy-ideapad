#!/usr/bin/env bash
## Simplified Power Menu for Lenovo IdeaPad Gaming 3
## Focus: Conservation Mode, Performance Modes, Rapid Charge
## Icons: Nerd Fonts

CONSERVATION_FILE="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

# Function to get conservation mode status
get_conservation_status() {
    if [ -f "$CONSERVATION_FILE" ]; then
        CURRENT_VALUE=$(cat "$CONSERVATION_FILE")
        if [ "$CURRENT_VALUE" -eq 1 ]; then
            echo "ON"
        else
            echo "OFF"
        fi
    else
        echo "N/A"
    fi
}

# Function to toggle conservation mode
toggle_conservation() {
    if [ -f "$CONSERVATION_FILE" ]; then
        CURRENT_VALUE=$(cat "$CONSERVATION_FILE")
        if [ "$CURRENT_VALUE" -eq 1 ]; then
            echo 0 | sudo tee "$CONSERVATION_FILE" > /dev/null
            notify-send "󰂎 Conservation Mode" "DISABLED (Full charge)" -t 2000
        else
            echo 1 | sudo tee "$CONSERVATION_FILE" > /dev/null
            notify-send "󰂎 Conservation Mode" "ENABLED (Capped at ~60%)" -t 2000
        fi
    else
        notify-send "󰀦 Error" "Conservation mode file not found" -u critical
    fi
}

# Function to get current performance mode
get_performance_mode() {
    # Check if acpi_call module is loaded
    if [ ! -f "/proc/acpi/call" ]; then
        echo "Unknown (load acpi_call)"
        return
    fi
    
    # Try first method (SPMO)
    echo '\_SB.PCI0.LPC0.EC0.SPMO' | sudo tee /proc/acpi/call > /dev/null
    MODE=$(sudo cat /proc/acpi/call | tr -d '\0')
    
    case "$MODE" in
        "0x0") echo "Intelligent" ;;
        "0x1") echo "Extreme" ;;
        "0x2") echo "Battery Saving" ;;
        *) 
            # Try second method (GZ44)
            echo '\_SB.PCI0.LPC0.EC0.GZ44' | sudo tee /proc/acpi/call > /dev/null
            MODE=$(sudo cat /proc/acpi/call | tr -d '\0')
            case "$MODE" in
                "0x0") echo "Intelligent" ;;
                "0x1") echo "Extreme" ;;
                "0x2") echo "Battery Saving" ;;
                *) echo "Unknown" ;;
            esac
            ;;
    esac
}

# Function to set performance mode
set_performance_mode() {
    MODE=$1
    
    # Load acpi_call module if not loaded
    if ! lsmod | grep -q acpi_call; then
        sudo modprobe acpi_call
    fi
    
    case "$MODE" in
        "Intelligent")
            echo '\_SB_.GZFD.WMAA 0 0x2C 2' | sudo tee /proc/acpi/call > /dev/null
            notify-send "󰔏 Performance Mode" "Set to Intelligent Cooling" -t 2000
            ;;
        "Extreme")
            echo '\_SB_.GZFD.WMAA 0 0x2C 3' | sudo tee /proc/acpi/call > /dev/null
            notify-send "󰓅 Performance Mode" "Set to Extreme Performance" -t 2000
            ;;
        "Battery")
            echo '\_SB_.GZFD.WMAA 0 0x2C 1' | sudo tee /proc/acpi/call > /dev/null
            notify-send "󰂎 Performance Mode" "Set to Battery Saving" -t 2000
            ;;
    esac
}

# Function to get rapid charge status
get_rapid_charge() {
    if [ ! -f "/proc/acpi/call" ]; then
        echo "Unknown"
        return
    fi
    
    # Try first method (QCHO)
    echo '\_SB.PCI0.LPC0.EC0.QCHO' | sudo tee /proc/acpi/call > /dev/null
    STATUS=$(sudo cat /proc/acpi/call | tr -d '\0')
    
    if [ "$STATUS" = "0x1" ]; then
        echo "ON"
    elif [ "$STATUS" = "0x0" ]; then
        echo "OFF"
    else
        # Try second method (FCGM)
        echo '\_SB.PCI0.LPC0.EC0.FCGM' | sudo tee /proc/acpi/call > /dev/null
        STATUS=$(sudo cat /proc/acpi/call | tr -d '\0')
        if [ "$STATUS" = "0x1" ]; then
            echo "ON"
        elif [ "$STATUS" = "0x0" ]; then
            echo "OFF"
        else
            echo "Unknown"
        fi
    fi
}

# Function to toggle rapid charge
toggle_rapid_charge() {
    CURRENT=$(get_rapid_charge)
    
    if [ "$CURRENT" = "ON" ]; then
        echo '\_SB.PCI0.LPC0.EC0.VPC0.SBMC 0x08' | sudo tee /proc/acpi/call > /dev/null
        notify-send "󱐋 Rapid Charge" "DISABLED" -t 2000
    else
        echo '\_SB.PCI0.LPC0.EC0.VPC0.SBMC 0x07' | sudo tee /proc/acpi/call > /dev/null
        notify-send "󱐋 Rapid Charge" "ENABLED" -t 2000
    fi
}

# Get current status
CONSERVATION_STATUS=$(get_conservation_status)
PERFORMANCE_STATUS=$(get_performance_mode)
RAPID_CHARGE_STATUS=$(get_rapid_charge)

# Create the menu with Nerd Font icons
CHOICE=$(echo -e "󰂎  Conservation: $CONSERVATION_STATUS\n󰓅  Performance: $PERFORMANCE_STATUS\n󱐋  Rapid Charge: $RAPID_CHARGE_STATUS\n󰁯  Refresh Status" | \
    rofi -dmenu -i -p "Power >" \
    -theme ~/.config/rofi/text/power-modes/style-3.rasi)

case "$CHOICE" in
    *"Conservation"*)
        toggle_conservation
        ;;
    *"Performance"*)
        # Sub-menu for performance modes
        SUBCHOICE=$(echo -e "󰔏  Intelligent Cooling\n󰓅  Extreme Performance\n󰂎  Battery Saving" | \
            rofi -dmenu -i -p "Performance Mode >"\
            -theme ~/.config/rofi/text/power-modes/style-3.rasi)
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
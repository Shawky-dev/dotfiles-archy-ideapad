#!/usr/bin/env bash

set -euo pipefail

CONSERVATION_FILE="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
ACPI_CALL_FILE="/proc/acpi/call"

ensure_acpi_call() {
    if [ -f "$ACPI_CALL_FILE" ]; then
        return 0
    fi

    modprobe acpi_call
    [ -f "$ACPI_CALL_FILE" ]
}

acpi_eval() {
    local call="$1"
    printf '%s' "$call" > "$ACPI_CALL_FILE"
    tr -d '\0' < "$ACPI_CALL_FILE"
}

get_conservation() {
    if [ -f "$CONSERVATION_FILE" ]; then
        case "$(cat "$CONSERVATION_FILE")" in
            1) echo "ON" ;;
            0) echo "OFF" ;;
            *) echo "Unknown" ;;
        esac
    else
        echo "N/A"
    fi
}

toggle_conservation() {
    [ -f "$CONSERVATION_FILE" ] || {
        echo "Conservation mode file not found" >&2
        exit 1
    }

    if [ "$(cat "$CONSERVATION_FILE")" -eq 1 ]; then
        printf '0' > "$CONSERVATION_FILE"
        echo "OFF"
    else
        printf '1' > "$CONSERVATION_FILE"
        echo "ON"
    fi
}

get_performance() {
    ensure_acpi_call || {
        echo "Unknown"
        return
    }

    local mode
    mode="$(acpi_eval '\_SB.PCI0.LPC0.EC0.SPMO')"
    case "$mode" in
        0x0) echo "Intelligent" ; return ;;
        0x1) echo "Extreme" ; return ;;
        0x2) echo "Battery Saving" ; return ;;
    esac

    mode="$(acpi_eval '\_SB.PCI0.LPC0.EC0.GZ44')"
    case "$mode" in
        0x0) echo "Intelligent" ;;
        0x1) echo "Extreme" ;;
        0x2) echo "Battery Saving" ;;
        *) echo "Unknown" ;;
    esac
}

set_performance() {
    ensure_acpi_call || {
        echo "acpi_call unavailable" >&2
        exit 1
    }

    case "${1:-}" in
        Extreme)
            printf '%s' '\_SB_.GZFD.WMAA 0 0x2C 3' > "$ACPI_CALL_FILE"
            cpupower frequency-set -g performance >/dev/null
            ;;
        Intelligent)
            printf '%s' '\_SB_.GZFD.WMAA 0 0x2C 2' > "$ACPI_CALL_FILE"
            cpupower frequency-set -g schedutil >/dev/null
            ;;
        Battery)
            printf '%s' '\_SB_.GZFD.WMAA 0 0x2C 1' > "$ACPI_CALL_FILE"
            cpupower frequency-set -g powersave >/dev/null
            ;;
        *)
            echo "Usage: $0 set-performance {Extreme|Intelligent|Battery}" >&2
            exit 2
            ;;
    esac
}

get_rapid_charge() {
    ensure_acpi_call || {
        echo "Unknown"
        return
    }

    local status
    status="$(acpi_eval '\_SB.PCI0.LPC0.EC0.QCHO')"
    case "$status" in
        0x1) echo "ON" ; return ;;
        0x0) echo "OFF" ; return ;;
    esac

    status="$(acpi_eval '\_SB.PCI0.LPC0.EC0.FCGM')"
    case "$status" in
        0x1) echo "ON" ;;
        0x0) echo "OFF" ;;
        *) echo "Unknown" ;;
    esac
}

toggle_rapid_charge() {
    ensure_acpi_call || {
        echo "acpi_call unavailable" >&2
        exit 1
    }

    if [ "$(get_rapid_charge)" = "ON" ]; then
        printf '%s' '\_SB.PCI0.LPC0.EC0.VPC0.SBMC 0x08' > "$ACPI_CALL_FILE"
        echo "OFF"
    else
        printf '%s' '\_SB.PCI0.LPC0.EC0.VPC0.SBMC 0x07' > "$ACPI_CALL_FILE"
        echo "ON"
    fi
}

case "${1:-}" in
    get-conservation) get_conservation ;;
    toggle-conservation) toggle_conservation ;;
    get-performance) get_performance ;;
    set-performance) set_performance "${2:-}" ;;
    get-rapid-charge) get_rapid_charge ;;
    toggle-rapid-charge) toggle_rapid_charge ;;
    *)
        echo "Usage: $0 {get-conservation|toggle-conservation|get-performance|set-performance|get-rapid-charge|toggle-rapid-charge}" >&2
        exit 2
        ;;
esac

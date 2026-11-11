
#!/bin/bash

set -u #zmusza skrypt do natychmiastowego zakończenia działania z błędem przy próbie odwołania się do niezadeklarowanej zmiennej

THRESHOLD=85
VERBOSE=0

usage() {
    cat <<EOF
Użycie: $0 [-p PROCENT] [-v] [-h]

Opcje:
  -p PROCENT  Próg zajętości w procentach (domyślnie: 85)
  -v          Tryb szczegółowy
  -h          Wyświetlenie pomocy

Przykład:
  $0 -p 90 -v
EOF
}

error() {
    printf 'BŁĄD: %s\n' "$1" >&2
}

while getopts ":p:vh" opt; do
    case "$opt" in
        p)
            if [[ ! "$OPTARG" =~ ^[0-9]+$ ]] ||
               (( 10#$OPTARG > 100 )); then
                error "Nieprawidłowy próg: $OPTARG (dozwolone 0-100)"
                exit 2
            fi
            THRESHOLD=$((10#$OPTARG))
            ;;
        v)
            VERBOSE=1
            ;;
        h)
            usage
            exit 0
            ;;
        :)
            error "Opcja -$OPTARG wymaga argumentu."
            usage >&2
            exit 2
            ;;
        \?)
            error "Nieznana opcja: -$OPTARG"
            usage >&2
            exit 2
            ;;
    esac
done

if (( OPTIND <= $# )); then
    error "Nieoczekiwany argument: ${!OPTIND}"
    usage >&2
    exit 2
fi

# Pobranie informacji o wszystkich zamontowanych systemach plików.
DF_OUTPUT=$(df -P -k) || {
    error "Nie udało się wykonać polecenia df."
    exit 2
}

# Przygotowanie danych: procent zajętości i punkt montowania.
RECORDS=$(printf '%s\n' "$DF_OUTPUT" | awk '
    NR > 1 {
        usage = $(NF-1)
        mountpoint = $6

        for (i = 7; i <= NF; i++) {
            mountpoint = mountpoint " " $i
        }

        sub(/%$/, "", usage)

        if (usage ~ /^[0-9]+$/) {
            print usage "\t" mountpoint
        }
    }
')

FOUND_WARNING=0
CHECKED=0

while IFS=$'\t' read -r usage mountpoint; do
    [[ -z "$usage" ]] && continue

    CHECKED=$((CHECKED + 1))

    if (( usage > THRESHOLD )); then
        FOUND_WARNING=1

        MESSAGE="OSTRZEŻENIE: ${mountpoint} zajęte w ${usage}% (próg: ${THRESHOLD}%)"

        # Logowanie na stderr.
        printf '%s\n' "$MESSAGE" >&2

        # Dodatkowo wysłanie komunikatu do sysloga.
        if command -v logger >/dev/null 2>&1; then
            logger -t dysk.sh -p user.warning "$MESSAGE" 2>/dev/null || true
        fi
    elif (( VERBOSE == 1 )); then
        printf 'OK: %s zajęte w %s%% (próg: %s%%)\n' \
            "$mountpoint" "$usage" "$THRESHOLD"
    fi
done <<< "$RECORDS"

if (( CHECKED == 0 )); then
    error "Nie znaleziono żadnego systemu plików do sprawdzenia."
    exit 2
fi

if (( FOUND_WARNING == 1 )); then
    exit 1
fi

if (( VERBOSE == 1 )); then
    printf 'Wszystkie %s systemów plików poniżej progu %s%%.\n' \
        "$CHECKED" "$THRESHOLD"
fi

exit 0

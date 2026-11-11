#!/bin/bash

CONFIG="$HOME/.config/raport.conf"

# Funkcja usuwająca białe znaki z początku i końca
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# ==========================================
# WARSTWA 1: Wartości domyślne
# ==========================================

IMIE="Użytkownik"
LICZBA="10"

SRC_IMIE="domyślna"
SRC_LICZBA="domyślna"

# ==========================================
# WARSTWA 2: Plik konfiguracyjny
# ==========================================

if [[ -f "$CONFIG" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do

        # Pomijamy puste linie i komentarze
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Sprawdzamy obecność znaku =
        if [[ "$line" != *"="* ]]; then
            echo "Ostrzeżenie: niepoprawna linia: $line" >&2
            continue
        fi

        key=$(trim "${line%%=*}")
        value=$(trim "${line#*=}")

        # Obsługa wartości w pojedynczych lub podwójnych cudzysłowach
        if [[ "$value" == \"*\" && "$value" == *\" ]]; then
            value="${value:1:${#value}-2}"
        elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
            value="${value:1:${#value}-2}"
        fi

        case "$key" in
            imie)
                IMIE="$value"
                SRC_IMIE="plik konfiguracyjny"
                ;;
            liczba)
                LICZBA="$value"
                SRC_LICZBA="plik konfiguracyjny"
                ;;
            *)
                echo "Ostrzeżenie: nieznany klucz '$key' w pliku konfiguracji" >&2
                ;;
        esac

    done < "$CONFIG"
fi

# ==========================================
# WARSTWA 3: Zmienne środowiskowe
# ==========================================

if [[ ${RAPORT_IMIE+x} ]]; then
    IMIE="$RAPORT_IMIE"
    SRC_IMIE="zmienna środowiskowa RAPORT_IMIE"
fi

if [[ ${RAPORT_LICZBA+x} ]]; then
    LICZBA="$RAPORT_LICZBA"
    SRC_LICZBA="zmienna środowiskowa RAPORT_LICZBA"
fi

# ==========================================
# WARSTWA 4: Argumenty wiersza poleceń
# ==========================================

POKAZ=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --imie)
            if [[ $# -lt 2 ]]; then
                echo "Błąd: --imie wymaga wartości" >&2
                exit 1
            fi
            IMIE="$2"
            SRC_IMIE="wiersz poleceń"
            shift 2
            ;;
        --liczba)
            if [[ $# -lt 2 ]]; then
                echo "Błąd: --liczba wymaga wartości" >&2
                exit 1
            fi
            LICZBA="$2"
            SRC_LICZBA="wiersz poleceń"
            shift 2
            ;;
        --pokaz-konfiguracje)
            POKAZ=1
            shift
            ;;
        *)
            echo "Nieznana opcja: $1" >&2
            exit 1
            ;;
    esac
done

# ==========================================
# Sprawdzenie poprawności konfiguracji
# ==========================================

if [[ ! "$LICZBA" =~ ^[0-9]+$ ]]; then
    echo "Błąd: liczba musi być liczbą całkowitą nieujemną" >&2
    exit 1
fi

# ==========================================
# Wyświetlanie efektywnej konfiguracji
# ==========================================

if [[ "$POKAZ" -eq 1 ]]; then
    echo "===== EFEKTYWNA KONFIGURACJA ====="
    echo "imie   = $IMIE"
    echo "źródło = $SRC_IMIE"
    echo
    echo "liczba = $LICZBA"
    echo "źródło = $SRC_LICZBA"
    exit 0
fi

# ==========================================
# Główna funkcjonalność programu
# ==========================================

echo "Witaj, $IMIE!"
echo "Ustawiona liczba: $LICZBA"


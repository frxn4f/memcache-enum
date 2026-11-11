
#!/bin/bash

# Colors
PURPLE='\033[38;5;141m'
CYAN='\033[38;5;81m'
GREEN='\033[38;5;82m'
RED='\033[38;5;203m'
YELLOW='\033[38;5;221m'
GRAY='\033[38;5;245m'
BOLD='\033[1m'
RESET='\033[0m'

# Args
if [[ -z "$1" ]]; then
    printf '\n'
    echo -e "${RED}[-] Error: IP was not provided${RESET}"
    echo "Usage: $0 <ip> [port] [-v]"
    echo "Example: $0 127.0.0.1 11211 -v"
    exit 1
fi

ip="$1"
port="11211"
verbose=false

if [[ -n "$2" && "$2" != "-v" && "$2" != "--verbose" ]]; then
    port="$2"
fi

if [[ "$2" == "-v" || "$2" == "--verbose" || "$3" == "-v" || "$3" == "--verbose" ]]; then
    verbose=true
fi

# Dependencies
if command -v nc &>/dev/null; then
    NC="nc"
elif command -v netcat &>/dev/null; then
    NC="netcat"
elif command -v ncat &>/dev/null; then
    NC="ncat"
else
    echo -e "${RED}[-] Netcat is required${RESET}"
    exit 1
fi

# Connectivity
if "$NC" -z -w 2 "$ip" "$port" &>/dev/null; then
    connected=true
else
    echo -e "${RED}[-] Cannot connect to $ip:$port${RESET}"
    exit 1
fi

# Header
printf "\n${PURPLE}${BOLD}Memcache Enumeration Tool${RESET}\n"
printf "${GRAY}────────────────────────────────────────${RESET}\n"
printf "${CYAN}Target:${RESET}  ${BOLD}%s:%s${RESET}\n" "$ip" "$port"
printf "${CYAN}Status:${RESET}  ${GREEN}CONNECTED${RESET}\n"

if [[ "$verbose" == true ]]; then
    printf "${CYAN}Mode:${RESET}    ${YELLOW}VERBOSE${RESET}\n\n"
else
    printf "${CYAN}Mode:${RESET}    NORMAL\n\n"
fi

# Commands
version_cmd() {
    printf 'version\r\n' | "$NC" -n -w 1 "$ip" "$port"
}

stats_cmd() {
    printf 'stats\r\n' | "$NC" -n -w 1 "$ip" "$port" | awk -v verbose="$verbose" '

    function human_bytes(n) {
        n += 0

        if (n >= 1073741824)
            return sprintf("%.2f GiB", n / 1073741824)

        if (n >= 1048576)
            return sprintf("%.2f MiB", n / 1048576)

        if (n >= 1024)
            return sprintf("%.2f KiB", n / 1024)

        return sprintf("%d B", n)
    }

    function human_time(n) {
        n = int(n)

        if (n >= 86400)
            return sprintf("%dd %dh %dm %ds", int(n/86400), int(n%86400/3600), int(n%3600/60), n%60)

        if (n >= 3600)
            return sprintf("%dh %dm %ds", int(n/3600), int(n%3600/60), n%60)

        if (n >= 60)
            return sprintf("%dm %ds", int(n/60), n%60)

        return sprintf("%ds", n)
    }

    BEGIN {
        split("pid uptime version libevent threads max_connections curr_connections total_connections rejected_connections accepting_conns listen_disabled_num cmd_get cmd_set cmd_flush cmd_touch get_hits get_misses get_expired delete_hits delete_misses auth_cmds auth_errors bytes_read bytes_written limit_maxbytes bytes curr_items total_items evictions reclaimed malloc_fails", fields)

        for (i in fields)
            show[fields[i]] = 1
    }

    $1 == "STAT" {
        key = $2
        value = $0
        sub(/^STAT [^ ]+ /, "", value)

        if (verbose == "true" || key in show) {

            if (key ~ /^(bytes|bytes_read|bytes_written|limit_maxbytes|hash_bytes)$/)
                value = human_bytes(value)

            if (key == "uptime")
                value = human_time(value)

            printf "  %-34s %s\n", key, value
        }
    }

    $1 != "STAT" && $1 != "END" {
        print "  " $0
    }'
}

stats_slabs_cmd() {
    printf 'stats slabs\r\n' | "$NC" -n -w 1 "$ip" "$port" | awk -v verbose="$verbose" '

    function human_bytes(n) {
        n += 0

        if (n >= 1073741824)
            return sprintf("%.2f GiB", n / 1073741824)

        if (n >= 1048576)
            return sprintf("%.2f MiB", n / 1048576)

        if (n >= 1024)
            return sprintf("%.2f KiB", n / 1024)

        return sprintf("%d B", n)
    }

    BEGIN {
        split("active_slabs total_malloced", fields)

        for (i in fields)
            show[fields[i]] = 1
    }

    $1 == "STAT" {
        key = $2
        value = $3

        if (verbose == "true" || key in show || key ~ /^[0-9]+:(chunk_size|total_pages|used_chunks|free_chunks|mem_requested)$/) {

            if (key == "total_malloced" || key ~ /^[0-9]+:(chunk_size|mem_requested)$/)
                value = human_bytes(value)

            printf "  %-34s %s\n", key, value
        }
    }

    $1 != "STAT" && $1 != "END" {
        print "  " $0
    }'
}

items_cmd() {
    printf 'stats items\r\n' | "$NC" -n -w 1 "$ip" "$port" | awk -v verbose="$verbose" '

    function human_time(n) {
        n = int(n)

        if (n >= 86400)
            return sprintf("%dd %dh %dm %ds", int(n/86400), int(n%86400/3600), int(n%3600/60), n%60)

        if (n >= 3600)
            return sprintf("%dh %dm %ds", int(n/3600), int(n%3600/60), n%60)

        if (n >= 60)
            return sprintf("%dm %ds", int(n/60), n%60)

        return sprintf("%ds", n)
    }

    BEGIN {
        split("number number_hot number_warm number_cold age age_hot age_warm evicted evicted_nonzero evicted_time outofmemory reclaimed expired_unfetched evicted_unfetched crawler_reclaimed crawler_items_checked moves_to_cold moves_to_warm direct_reclaims hits_to_hot hits_to_warm hits_to_cold hits_to_temp", fields)

        for (i in fields)
            show[fields[i]] = 1
    }

    $1 == "STAT" {
        key = $2
        value = $3
        field = key
        sub(/^items:[0-9]+:/, "", field)

        if (verbose == "true" || field in show) {

            if (field ~ /^age(_hot|_warm)?$/)
                value = human_time(value)

            printf "  %-34s %s\n", key, value
        }
    }

    $1 != "STAT" && $1 != "END" {
        print "  " $0
    }'
}

settings_cmd() {
    printf 'stats settings\r\n' | "$NC" -n -w 1 "$ip" "$port" | awk -v verbose="$verbose" '

    function human_bytes(n) {
        n += 0

        if (n >= 1073741824)
            return sprintf("%.2f GiB", n / 1073741824)

        if (n >= 1048576)
            return sprintf("%.2f MiB", n / 1048576)

        if (n >= 1024)
            return sprintf("%.2f KiB", n / 1024)

        return sprintf("%d B", n)
    }

    BEGIN {
        split("tcpport udpport inter auth_enabled_sasl maxbytes maxconns evictions domain_socket num_threads detail_enabled cas_enabled binding_protocol item_size_max maxconns_fast slab_reassign slab_automove lru_crawler lru_maintainer_thread lru_segmented flush_enabled dump_enabled idle_timeout temp_lru", fields)

        for (i in fields)
            show[fields[i]] = 1
    }

    $1 == "STAT" {
        key = $2
        value = $3

        if (verbose == "true" || key in show) {

            if (key ~ /^(maxbytes|item_size_max|slab_chunk_max)$/)
                value = human_bytes(value)

            printf "  %-34s %s\n", key, value
        }
    }

    $1 != "STAT" && $1 != "END" {
        print "  " $0
    }'
}

# Enumeration
echo -e "${PURPLE}${BOLD}[01] VERSION${RESET}"
echo -e "${GRAY}────────────────────────────────────────${RESET}"
version_cmd
echo ""

echo -e "${PURPLE}${BOLD}[02] SERVER STATUS${RESET}"
echo -e "${GRAY}────────────────────────────────────────${RESET}"
stats_cmd
echo ""

echo -e "${PURPLE}${BOLD}[03] SLABS${RESET}"
echo -e "${GRAY}────────────────────────────────────────${RESET}"
stats_slabs_cmd
echo ""

echo -e "${PURPLE}${BOLD}[04] ITEMS${RESET}"
echo -e "${GRAY}────────────────────────────────────────${RESET}"
items_cmd
echo ""

echo -e "${PURPLE}${BOLD}[05] SETTINGS${RESET}"
echo -e "${GRAY}────────────────────────────────────────${RESET}"
settings_cmd

echo ""
echo -e "${GREEN}${BOLD}[+] Enumeration completed${RESET}"

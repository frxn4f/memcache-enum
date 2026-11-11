# Memcached Enumerator

A personal cybersecurity learning project developed by me while studying Bash scripting and offensive security.

Memcached Enumerator is a lightweight Bash script designed to explore and enumerate Memcached services during authorized security assessments and laboratory exercises.

The project started as a practical way to learn Bash scripting by building a useful tool rather than simply studying commands and syntax in isolation.

## About the Project

This is an independently developed project created as part of my learning journey in cybersecurity and penetration testing.

My main goals are to:

- Improve my Bash scripting skills through practical development.
- Understand how Memcached works and how its text protocol can be used for service enumeration.
- Learn how to collect, filter and organize information returned by network services.
- Build small utilities that can be useful in penetration testing labs and security assessments.

The tool is intentionally kept simple. Its functionality and code structure will evolve as I continue learning and improving my scripting skills.

## Features

- **Service detection:** Checks TCP connectivity to the target Memcached service.
- **Version detection:** Retrieves the Memcached server version.
- **Server statistics:** Collects runtime information, connections and cache statistics.
- **Slab enumeration:** Retrieves memory allocation and slab statistics.
- **Items enumeration:** Collects information about stored items.
- **Settings enumeration:** Retrieves server configuration and operational settings.
- **Verbose mode:** Displays all statistics returned by the implemented queries.
- **Readable output:** Color-coded sections, aligned columns and human-readable units.

## Requirements

- Bash
- Netcat (`nc`, `netcat` or `ncat`)

The script automatically detects an available Netcat implementation.

## Installation

Clone the repository:

```bash
git clone <REPOSITORY_URL>
cd <REPOSITORY_NAME>
```

Make the script executable:

```bash
chmod +x memcached-enum.sh
```

## Usage

```bash
./memcached-enum.sh <IP> [PORT] [-v]
```

The default Memcached port is `11211`.

### Basic enumeration

```bash
./memcached-enum.sh 192.168.1.100
```

### Custom port

```bash
./memcached-enum.sh 192.168.1.100 11211
```

### Verbose mode

```bash
./memcached-enum.sh 192.168.1.100 -v
```

### Verbose mode with custom port

```bash
./memcached-enum.sh 192.168.1.100 11211 -v
```

## Enumeration Modules

| Module | Command | Description |
|---|---|---|
| Version | `version` | Retrieves the server version. |
| Server Status | `stats` | Collects general server statistics. |
| Slabs | `stats slabs` | Retrieves memory allocation statistics. |
| Items | `stats items` | Collects stored item statistics by slab class. |
| Settings | `stats settings` | Retrieves server configuration settings. |

## Output Modes

**Normal mode**

Displays selected statistics considered useful during an initial assessment, keeping the output compact and readable.

**Verbose mode (`-v`)**

Displays all `STAT` fields returned by the implemented enumeration queries, providing additional information for deeper analysis.

## Technical Notes

- Communication is performed over TCP using the Memcached text protocol.
- The implemented statistics queries are read-only.
- Some statistics may vary depending on the Memcached version and server configuration.
- The tool currently focuses on service enumeration and does not retrieve the actual contents of cached values.

## Disclaimer

This project was created for educational purposes, laboratory environments and authorized security assessments.
Only use it against systems for which you have explicit permission to perform security testing.

---

*Developed as part of my journey learning cybersecurity, penetration testing and Bash scripting.*

My HackTheBox Profile: https://app.hackthebox.com/public/users/4106172

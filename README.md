# Sage X3 Connector

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)

Single-file Python module to connect to **Sage X3 ERP** (SQL Server) via ODBC.  
Copy into any project and connect in seconds.

```python
from sage_x3_connector import get_sage_connection

conn = get_sage_connection()
cursor = conn.cursor()
cursor.execute("SELECT COUNT(*) FROM PROD.SINVOICE")
print(cursor.fetchone())
conn.close()
```

## Features

- **Single file** — no package installation required. Just copy `sage_x3_connector.py` into your project.
- **Three connection modes**: direct host/instance, explicit host:port, WSL2 gateway proxy
- **.env support** — credentials loaded from `.env` file or environment variables
- **Read-only mode** — optional `ApplicationIntent=ReadOnly` for safety
- **Self-test** — run `python3 sage_x3_connector.py` to verify your configuration

## Installation

```bash
pip install pyodbc python-dotenv
```

### ODBC Driver (Linux)

```bash
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get install -y msodbcsql18
```

### ODBC Driver (macOS)

```bash
brew install unixodbc
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew update
ACCEPT_EULA=Y brew install msodbcsql18
```

### ODBC Driver (Windows)

Download and install from: https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server

## Configuration

Create a `.env` file in your project root:

```env
# --- Required ---
SAGE_SERVER=<your_host>\<instance>
SAGE_DATABASE=<your_database>
SAGE_USER=<your_user>
SAGE_PASSWORD=<your_password>

# --- Optional ---
# Explicit port (avoids SQL Browser / UDP 1434)
SAGE_PORT=<port>

# WSL2 gateway (see WSL section below)
SAGE_GATEWAY=<windows_gateway_ip>
```

Or set environment variables directly:

```bash
export SAGE_SERVER="192.168.x.x\SAGEX3"
export SAGE_DATABASE="uccv"
export SAGE_USER="PROD"
export SAGE_PASSWORD="your_password"
```

## Connection Modes

### 1. Named Instance (default)

```env
SAGE_SERVER=192.168.x.x\SAGEX3
# SAGE_PORT not set → uses SQL Browser (UDP 1434)
```

### 2. Host + Port (recommended)

```env
SAGE_SERVER=192.168.x.x
SAGE_PORT=50321
# Uses explicit TCP port — faster, no SQL Browser needed
```

### 3. WSL2 Gateway Proxy

If running from **WSL2** (isolated NAT network), the Linux subsystem cannot directly reach your Windows network. Solution: Windows **portproxy**.

**On Windows (PowerShell Admin):**

```powershell
netsh interface portproxy add v4tov4 listenport=<port> listenaddress=0.0.0.0 connectport=<port> connectaddress=<sage_server_ip>
```

**In `.env`:**

```env
SAGE_GATEWAY=<windows_gateway_ip>  # Usually 172.x.x.1 or host.docker.internal
SAGE_PORT=<port>
```

## API Reference

### `get_connection_string(readonly=False)`

Returns the ODBC connection string. Useful for pandas, ETL tools, etc.

```python
cs = get_connection_string(readonly=True)
df = pd.read_sql("SELECT * FROM PROD.SINVOICE", pyodbc.connect(cs))
```

### `get_sage_connection(readonly=False, timeout=30)`

Opens and returns a `pyodbc.Connection`.

```python
conn = get_sage_connection(timeout=10)
```

### Constants

| Constant | Description | Default |
|----------|-------------|---------|
| `SAGE_SERVER` | Server host (env override) | `"localhost"` |
| `SAGE_PORT` | SQL Server port | `""` (auto) |
| `SAGE_GATEWAY` | WSL gateway IP | `""` (disabled) |
| `SAGE_DATABASE` | Database name | `""` |
| `SAGE_USER` | Login user | `""` |
| `SAGE_PASSWORD` | Login password | `""` |
| `DEFAULTS` | Dict of all defaults | — |

## Common Sage X3 Tables

| Table | Content |
|-------|---------|
| `PROD.SINVOICE` | Invoice headers (NUM_0, SIVTYP_0, STA_0, AMTNOT_0, AMTATI_0, BPR_0, ACCDAT_0) |
| `PROD.SINVOICED` | Invoice lines (NUM_0, ITMREF_0, QTYSTU_0, BASTAXLIN_0, AMTNOTLIN_0, AMTTAXLIN_0) |
| `PROD.GACCENTRYD` | Journal entries (TYP_0, NUM_0, ACC_0, SNS_0, AMTLED_0, MTC_0, LED_0) |
| `PROD.GACCOUNT` | Account labels (ACC_0, DES_0) |

## Related

- [Sage X3 MCP Server](https://github.com/arthurfranckpat/sage-x3-mcp) — MCP server for Sage X3 knowledge base
- [OpenLink ODBC MCP Server](https://github.com/OpenLinkSoftware/mcp-odbc-server) — Generic ODBC MCP server

## License

MIT — see [LICENSE](LICENSE).

---
name: sage-x3-connector
description: Connect to Sage X3 (SQL Server) via ODBC from any project. Single-file Python module with WSL gateway support. Use when user mentions Sage X3, SINVOICE, GACCENTRYD, ERP, or needs ODBC connection to Sage.
---

# Sage X3 Connector

## Quick Start

Copy `sage_x3_connector.py` into any Python project, then:

```python
from sage_x3_connector import get_sage_connection, get_connection_string

# Get an ODBC connection
conn = get_sage_connection()
cursor = conn.cursor()
cursor.execute("SELECT COUNT(*) FROM PROD.SINVOICE")
print(cursor.fetchone())
conn.close()

# Or just get the connection string (for ETL, pandas, etc.)
cs = get_connection_string(readonly=True)
```

## Configuration

Create a `.env` file in your project root:

```env
# Required
SAGE_SERVER=<your_server_host>\<instance_name>
SAGE_DATABASE=<your_database>
SAGE_USER=<your_user>
SAGE_PASSWORD=<your_password>

# Optional -- explicit port (avoids SQL Browser)
SAGE_PORT=<sql_server_port>

# Optional -- WSL2 gateway (see below)
SAGE_GATEWAY=<windows_gateway_ip>
```

### Named Instance vs Port

| Scenario | Example |
|----------|---------|
| Named instance (default) | `SAGE_SERVER=192.168.x.x\SAGEX3` |
| With explicit port | `SAGE_SERVER=192.168.x.x + SAGE_PORT=50321` |
| WSL gateway | `SAGE_GATEWAY=172.25.x.x + SAGE_PORT=50321` |

### WSL2 Gateway

If running from WSL2 (isolated NAT network), use Windows portproxy:

```powershell
# PowerShell (Admin) on Windows
netsh interface portproxy add v4tov4 listenport=<port> listenaddress=0.0.0.0 connectport=<port> connectaddress=<sage_server_ip>
```

Then set `SAGE_GATEWAY=<windows_gateway_ip>` in `.env`.

## Key Sage X3 Tables

| Table | Content | Key Columns |
|-------|---------|-------------|
| `SINVOICE` | Invoice headers | `NUM_0`, `SIVTYP_0` (FVL/AVL/FBL/ABL), `STA_0` (1=NV, 2=V), `AMTNOT_0` (HT), `AMTATI_0` (TTC), `BPR_0`, `BPRNAM_0`, `ACCDAT_0` |
| `SINVOICED` | Invoice lines | `NUM_0`, `ITMREF_0`, `QTYSTU_0`, `BASTAXLIN_0`, `AMTNOTLIN_0`, `AMTTAXLIN_0`, `DISCRGVAL4_0`, `SAUSTUCOE_0` |
| `GACCENTRYD` | Journal entries | `TYP_0`, `NUM_0`, `ACC_0`, `SNS_0`, `AMTLED_0`, `MTC_0`, `LED_0` |
| `GACCOUNT` | Account labels | `ACC_0`, `DES_0` |

## Dependencies

```bash
pip install pyodbc python-dotenv

# ODBC Driver (Linux):
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get install -y msodbcsql18
```

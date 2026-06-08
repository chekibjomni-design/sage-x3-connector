#!/usr/bin/env python3
"""
Sage X3 ODBC Connector -- Standalone Reusable Module
====================================================

Single-file connector to Sage X3 (SQL Server) via pyodbc.
Copy this file into ANY project and you're ready.

Quick Start
-----------
    from sage_x3_connector import get_sage_connection

    conn = get_sage_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT 1")
    print(cursor.fetchone())
    conn.close()

Configuration (in order of priority)
-------------------------------------
1. .env file (same directory as this module)
2. Environment variables
3. Hardcoded defaults (see DEFAULTS below)

Required .env variables:
    SAGE_SERVER=<your_server>\\<instance>
    SAGE_DATABASE=<your_database>
    SAGE_USER=<your_user>
    SAGE_PASSWORD=<your_password>

Optional .env variables (WSL / portproxy):
    SAGE_GATEWAY=<windows_ip>     # Windows IP for WSL portproxy
    SAGE_PORT=<port>              # Real SQL Server port

Installation
------------
    pip install pyodbc python-dotenv

    # Linux: install ODBC driver
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
    apt-get update
    ACCEPT_EULA=Y apt-get install -y msodbcsql18
"""

import os
import logging

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Try to load .env from same directory (optional dependency)
# ---------------------------------------------------------------------------
try:
    from dotenv import load_dotenv

    _env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    load_dotenv(_env_path)
except ImportError:
    pass  # python-dotenv not installed, use env vars only

# ---------------------------------------------------------------------------
# Imports
# ---------------------------------------------------------------------------
try:
    import pyodbc
except ImportError:
    raise ImportError(
        "pyodbc is required. Install with: pip install pyodbc"
    )

# ---------------------------------------------------------------------------
# Backslash helper (avoid escaping issues in string literals)
# ---------------------------------------------------------------------------
_BS = chr(92)  # single backslash character

# ---------------------------------------------------------------------------
# Defaults -- override via .env or environment variables
# ---------------------------------------------------------------------------
DEFAULTS = {
    "SAGE_SERVER":    "localhost",
    "SAGE_PORT":      "",
    "SAGE_GATEWAY":   "",
    "SAGE_DATABASE":  "",
    "SAGE_USER":      "",
    "SAGE_PASSWORD":  "",
    "SAGE_DRIVER":    "{ODBC Driver 17 for SQL Server}",
    "SAGE_TRUST_CERT": "yes",
}

# ---------------------------------------------------------------------------
# Configuration -- env > .env > hardcoded defaults
# ---------------------------------------------------------------------------
SAGE_SERVER     = os.getenv("SAGE_SERVER",      DEFAULTS["SAGE_SERVER"])
SAGE_PORT       = os.getenv("SAGE_PORT",        DEFAULTS["SAGE_PORT"])
SAGE_GATEWAY    = os.getenv("SAGE_GATEWAY",     DEFAULTS["SAGE_GATEWAY"])
SAGE_DATABASE   = os.getenv("SAGE_DATABASE",    DEFAULTS["SAGE_DATABASE"])
SAGE_USER       = os.getenv("SAGE_USER",        DEFAULTS["SAGE_USER"])
SAGE_PASSWORD   = os.getenv("SAGE_PASSWORD",    DEFAULTS["SAGE_PASSWORD"])
SAGE_DRIVER     = os.getenv("SAGE_DRIVER",      DEFAULTS["SAGE_DRIVER"])
SAGE_TRUST_CERT = os.getenv("SAGE_TRUST_CERT",  DEFAULTS["SAGE_TRUST_CERT"])


def get_connection_string(*, readonly: bool = False) -> str:
    """Build ODBC connection string for Sage X3.

    Handles three scenarios:
    1. Gateway proxy:  ``SAGE_GATEWAY`` set -> routes through Windows
    2. Host + Port:    ``SAGE_SERVER=host + SAGE_PORT=port``
    3. Named instance: ``SAGE_SERVER=host\\INSTANCE`` (no port)

    Parameters
    ----------
    readonly : bool
        Append ApplicationIntent=ReadOnly.

    Returns
    -------
    str
        ODBC connection string.
    """
    server = SAGE_GATEWAY if SAGE_GATEWAY else SAGE_SERVER

    if SAGE_PORT:
        # Detect named-instance format: host\\INSTANCE
        if _BS in server:
            host_part = server.split(_BS)[0]
            server = f"{host_part},{SAGE_PORT}"
        elif "," not in server:
            server = f"{server},{SAGE_PORT}"

    cs = (
        f"DRIVER={SAGE_DRIVER};"
        f"SERVER={server};"
        f"DATABASE={SAGE_DATABASE};"
        f"UID={SAGE_USER};PWD={SAGE_PASSWORD};"
        f"TrustServerCertificate={SAGE_TRUST_CERT};"
        f"Encrypt=no;"
    )
    if readonly:
        cs += "ApplicationIntent=ReadOnly;"
    return cs


def get_sage_connection(
    *, readonly: bool = False, timeout: int = 30
) -> "pyodbc.Connection":
    """Open a new ODBC connection to Sage X3.

    Parameters
    ----------
    readonly : bool
        Passed to get_connection_string().
    timeout : int
        Login timeout in seconds (default 30).

    Returns
    -------
    pyodbc.Connection

    Raises
    ------
    pyodbc.Error
        If connection fails.
    """
    cs = get_connection_string(readonly=readonly)
    logger.debug(
        "Connecting to Sage X3 (server=%s, db=%s, user=%s)",
        SAGE_SERVER, SAGE_DATABASE, SAGE_USER,
    )
    return pyodbc.connect(cs, timeout=timeout)


# ---------------------------------------------------------------------------
# Quick self-test when run directly
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import sys

    logging.basicConfig(level=logging.INFO, format="%(message)s")
    logger.setLevel(logging.INFO)

    print("=" * 55)
    print("  Sage X3 Connector -- Self-Test")
    print("=" * 55)
    print(f"  Server:   {SAGE_SERVER}")
    print(f"  Port:     {SAGE_PORT or '(not set)'}")
    print(f"  Gateway:  {SAGE_GATEWAY or '(not set)'}")
    print(f"  Database: {SAGE_DATABASE or '(not set)'}")
    print(f"  User:     {SAGE_USER or '(not set)'}")

    if not all([SAGE_DATABASE, SAGE_USER, SAGE_PASSWORD]):
        print("\n  Set SAGE_* environment variables or create a .env file.")
        sys.exit(1)

    try:
        conn = get_sage_connection(timeout=5)
        cur = conn.cursor()
        cur.execute("SELECT 1 AS test")
        row = cur.fetchone()
        print(f"\n  Connection OK: {row[0]}")
        conn.close()
        sys.exit(0)
    except Exception as e:
        print(f"\n  Connection failed: {e}")
        sys.exit(1)


__all__ = [
    "get_connection_string",
    "get_sage_connection",
    "SAGE_SERVER",
    "SAGE_PORT",
    "SAGE_GATEWAY",
    "SAGE_DATABASE",
    "SAGE_USER",
    "SAGE_PASSWORD",
    "DEFAULTS",
]

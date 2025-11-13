import sqlite3
conn = sqlite3.connect('rssi_logs.db')
cursor = conn.cursor()

cursor.execute("""CREATE TABLE IF NOT EXISTS nodes (
            id INTEGER PRIMARY KEY,
            is_leader BOOLEAN
        );""")
cursor.execute("""CREATE TABLE IF NOT EXISTS rssi_logs (
            id INTEGER PRIMARY KEY,
            node_id INTEGER,
            rssi_value INTEGER,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (node_id) REFERENCES nodes(id)
        );""")

cursor.execute("INSERT INTO nodes (is_leader) VALUES (1)")
conn.commit()

conn.close()
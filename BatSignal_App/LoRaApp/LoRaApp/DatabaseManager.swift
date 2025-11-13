import SQLite3
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        // Get the documents directory path
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.dbPath = documentsPath.appendingPathComponent("rssi_logs.db").path
        
        // Copy bundled database if it doesn't exist
        if !fileManager.fileExists(atPath: dbPath) {
            if let bundledDBPath = Bundle.main.path(forResource: "rssi_logs", ofType: "db") {
                do {
                    try fileManager.copyItem(atPath: bundledDBPath, toPath: dbPath)
                    print("Copied bundled database to documents directory")
                } catch {
                    print("Error copying bundled database: \(error)")
                }
            }
        }
        
        // Initialize the database connection
        self.initializeDatabase()
    }
    
    private func initializeDatabase() {
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            print("Unable to open database")
            return
        }
        
        createTables()
    }
    
    private func createTables() {
        let createNodesTable = """
        CREATE TABLE IF NOT EXISTS nodes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            is_leader BOOLEAN DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        let createRssiLogsTable = """
        CREATE TABLE IF NOT EXISTS rssi_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            node_id INTEGER NOT NULL,
            rssi_value INTEGER NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (node_id) REFERENCES nodes(id)
        );
        """
        
        var errorMessage: UnsafeMutablePointer<CChar>?
        
        if sqlite3_exec(db, createNodesTable, nil, nil, &errorMessage) != SQLITE_OK {
            print("Error creating nodes table: \(String(cString: errorMessage ?? "Unknown error" as UnsafeMutablePointer<CChar>))")
            sqlite3_free(errorMessage)
        }
        
        if sqlite3_exec(db, createRssiLogsTable, nil, nil, &errorMessage) != SQLITE_OK {
            print("Error creating rssi_logs table: \(String(cString: errorMessage ?? "Unknown error" as UnsafeMutablePointer<CChar>))")
            sqlite3_free(errorMessage)
        }
    }
    
    // MARK: - Node Operations
    
    func createNode(name: String, isLeader: Bool = false) -> Int64? {
        let insertStatement = """
        INSERT INTO nodes (name, is_leader) VALUES (?, ?);
        """
        
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, insertStatement, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing insert statement")
            return nil
        }
        
        sqlite3_bind_text(statement, 1, name, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, isLeader ? 1 : 0)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            print("Error executing insert statement")
            return nil
        }
        
        return sqlite3_last_insert_rowid(db)
    }
    
    func getAllNodes() -> [Node] {
        let query = "SELECT id, name, is_leader, created_at FROM nodes;"
        var nodes: [Node] = []
        var statement: OpaquePointer?
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing select statement")
            return nodes
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let name = String(cString: sqlite3_column_text(statement, 1))
            let isLeader = sqlite3_column_int(statement, 2) != 0
            let createdAt = String(cString: sqlite3_column_text(statement, 3))
            
            let node = Node(id: id, name: name, isLeader: isLeader, createdAt: createdAt)
            nodes.append(node)
        }
        
        return nodes
    }
    
    func deleteNode(id: Int64) -> Bool {
        let deleteStatement = "DELETE FROM nodes WHERE id = ?;"
        var statement: OpaquePointer?
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, deleteStatement, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing delete statement")
            return false
        }
        
        sqlite3_bind_int64(statement, 1, id)
        
        return sqlite3_step(statement) == SQLITE_DONE
    }
    
    // MARK: - RSSI Log Operations
    
    func logRSSI(nodeId: Int64, rssiValue: Int) -> Bool {
        let insertStatement = """
        INSERT INTO rssi_logs (node_id, rssi_value) VALUES (?, ?);
        """
        
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, insertStatement, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing insert statement")
            return false
        }
        
        sqlite3_bind_int64(statement, 1, nodeId)
        sqlite3_bind_int(statement, 2, Int32(rssiValue))
        
        return sqlite3_step(statement) == SQLITE_DONE
    }
    
    func getRSSILogs(for nodeId: Int64) -> [RSSILog] {
        let query = """
        SELECT id, node_id, rssi_value, timestamp FROM rssi_logs WHERE node_id = ? ORDER BY timestamp DESC;
        """
        
        var logs: [RSSILog] = []
        var statement: OpaquePointer?
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing select statement")
            return logs
        }
        
        sqlite3_bind_int64(statement, 1, nodeId)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let nodeId = sqlite3_column_int64(statement, 1)
            let rssiValue = sqlite3_column_int(statement, 2)
            let timestamp = String(cString: sqlite3_column_text(statement, 3))
            
            let log = RSSILog(id: id, nodeId: nodeId, rssiValue: Int(rssiValue), timestamp: timestamp)
            logs.append(log)
        }
        
        return logs
    }
    
    func getAllRSSILogs() -> [RSSILog] {
        let query = """
        SELECT id, node_id, rssi_value, timestamp FROM rssi_logs ORDER BY timestamp DESC;
        """
        
        var logs: [RSSILog] = []
        var statement: OpaquePointer?
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing select statement")
            return logs
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let nodeId = sqlite3_column_int64(statement, 1)
            let rssiValue = sqlite3_column_int(statement, 2)
            let timestamp = String(cString: sqlite3_column_text(statement, 3))
            
            let log = RSSILog(id: id, nodeId: nodeId, rssiValue: Int(rssiValue), timestamp: timestamp)
            logs.append(log)
        }
        
        return logs
    }
    
    deinit {
        sqlite3_close(db)
    }
}

// MARK: - Data Models

struct Node: Identifiable {
    let id: Int64
    let name: String
    let isLeader: Bool
    let createdAt: String
}

struct RSSILog: Identifiable {
    let id: Int64
    let nodeId: Int64
    let rssiValue: Int
    let timestamp: String
}

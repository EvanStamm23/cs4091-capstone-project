//
//  NodeManager.swift
//  LoRaApp
//
//  Created by admin on 11/13/25.
//
// DB operations (CREATE, READ, DELETE, etc)
// where will receive incoming data

import Foundation
import CoreData

class NodeManager {
    // workspace from dbController
    let context: NSManagedObjectContext
    
    // get workspace to perform operations
    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }
    
    // set entity to lost if lost
    func setNode(_ nodeId: Int64, lost: Bool) {
        if let node = findNode(byId: nodeId) {
            node.isLost = lost
            saveContext()
        }
    }
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // Create a leader node
    func createLeaderNode() -> NodeEntity? {
        // create and set new node properties
        let node = NodeEntity(context: context)
        node.isLeader = true
        
        do {
            try context.save() // save changes to the disk
            return node
        } catch {
            print("Error creating node: \(error)")
            return nil
        }
    }
    
    // Create an RSSI log
    func createRSSILog(sourceId: Int64, targetId: Int64, rssiValue: Int64) -> RSSILogEntity? {
        let log = RSSILogEntity(context: context)
        log.sourceNodeId = sourceId
        log.targetNodeId = targetId
        log.sourceName = nodeName(for: sourceId)
        log.targetName = nodeName(for: targetId)
        log.rssiValue = rssiValue
        log.timestamp = Date()
        
        // Find or create source node
        let node = findNode(byId: sourceId) ?? {
            let n = NodeEntity(context: context)
            n.id = sourceId
            n.isLeader = false
            return n
        }()
        
        log.node = node  // set relationship

        do {
            try context.save()
            return log
        } catch {
            print("Error saving RSSI log: \(error)")
            return nil
        }
    }
    
    // Fetch all logs for a node
    func fetchRSSILogs(for node: NodeEntity) -> [RSSILogEntity] {
        guard let logs = node.rssiLogs as? Set<RSSILogEntity> else { return [] }
        return logs.sorted(by: { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) })
    }
    
    func fetchRSSIBetween(sourceId: Int64, targetId: Int64) -> [RSSILogEntity] {
        let request: NSFetchRequest<RSSILogEntity> = RSSILogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "sourceNodeId == %d AND targetNodeId == %d", sourceId, targetId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    // save rssi value from BLE
    func saveRSSIFromBLE(sourceId: Int64, targetId: Int64, rssiValue: Int64) {
        // Find or create the source node
        let node: NodeEntity
        if let existingNode = findNode(byId: sourceId) {
            node = existingNode
        } else {
            node = NodeEntity(context: context)
            node.id = sourceId
            node.isLeader = false
            do {
                try context.save()
            } catch {
                print("Error creating node: \(error)")
                return
            }
        }
        
        // Save RSSI log with source/target IDs
        _ = createRSSILog(sourceId: sourceId, targetId: targetId, rssiValue: rssiValue)
    }
    
    // find a node by ID
    func findNode(byId id: Int64) -> NodeEntity? {
        let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Error finding node: \(error)")
            return nil
        }
    }
    
    // read all nodes from db
    func fetchAllNodes() -> [NodeEntity] {
        let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest() // query db
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching nodes: \(error)")
            return []
        }
    }
    
    func fetchAllRSSILogs() -> [RSSILogEntity] {
        let request: NSFetchRequest<RSSILogEntity> = RSSILogEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
}

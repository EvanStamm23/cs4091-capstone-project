//
//  NodeManager.swift
//  LoRaApp
//
//  Created by admin on 11/13/25.
//
// DB operations

import Foundation

import CoreData

class NodeManager {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }
    
    // Create a leader node
    func createLeaderNode() -> NodeEntity? {
        let node = NodeEntity(context: context)
        node.isLeader = true
        
        do {
            try context.save()
            return node
        } catch {
            print("Error creating node: \(error)")
            return nil
        }
    }
    
    // Create an RSSI log
    func createRSSILog(for node: NodeEntity, rssiValue: Int64) -> RSSILogEntity? {
        let log = RSSILogEntity(context: context)
        log.rssiValue = rssiValue
        log.timestamp = Date()
        log.node = node
        
        do {
            try context.save()
            return log
        } catch {
            print("Error creating RSSI log: \(error)")
            return nil
        }
    }
    
    // Fetch all nodes
    func fetchAllNodes() -> [NodeEntity] {
        let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching nodes: \(error)")
            return []
        }
    }
    
    // Fetch RSSI logs for a specific node
    func fetchRSSILogs(for node: NodeEntity) -> [RSSILogEntity] {
        let fetchRequest: NSFetchRequest<RSSILogEntity> = RSSILogEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "node == %@", node)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching RSSI logs: \(error)")
            return []
        }
    }
}

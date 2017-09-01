//
//  ItemsQuery.swift
//  Pods
//
//  Created by Martin Makarsky on 01/09/2017.
//
//

import Foundation

public class ItemsQuery: Query {
    
    private let itemsQuery = "items?"
    private let contentTypeKey = "system.type="
    
    private var contentType: String
    
    public init(endpoint: Endpoint, contentType: String) {
        self.contentType = contentType
        super.init(endpoint: endpoint)
    }
    
    func getItemsQuery(projectId: String) -> String {
        let endpoint = getEndpoint()
        let contentTypeParameter = "\(contentTypeKey)\(contentType)"
        return "\(endpoint)/\(projectId)/\(itemsQuery)\(contentTypeParameter)"
    }
}
//
//  APIManagerClass.swift
//  ATWatcher
//
//  Created by Timo Reinhardt on 19.06.25.
//

import Foundation
import Combine

struct Device: Identifiable, Decodable {
    let id: String
    let name: String
    let room: String

    enum CodingKeys: String, CodingKey {
        case name, room
        case id = "UDID"
    }
}

struct Level: Decodable {
    let level: Int
    let devices: [Device]
}

struct Building: Decodable {
    let building: String
    let levels: [Level]
}

/// Represents the response structure from the API.
/// - `smart`: Optionally contains the Apple TV assigned to the current teacher's room, if available.
/// - `devices`: A hierarchical list of all buildings, their levels, and available Apple TVs.
struct APIResponse: Decodable {
    let smart: Device?
    let devices: [Building]
}

@MainActor
class APIManager: ObservableObject {
    @Published var availableDevicePool: [Building] = []

    func devices(inBuilding building: String, level targetLevel: Int) -> [Device] {
        guard let buildingData = availableDevicePool.first(where: { $0.building == building }),
              let levelData = buildingData.levels.first(where: { $0.level == targetLevel }) else {
            return []
        }
        return levelData.devices
    }
}

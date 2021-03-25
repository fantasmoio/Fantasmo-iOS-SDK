//
//  FMZones.swift
//  FantasmoSDK
//
//  Created by Ryan on 10/2/20.
//


/// Semantic zones corresponding to a position
public struct FMZone {
    
    public enum ZoneType: String {
        case street
        case sidewalk
        case furniture
        case crosswalk
        case accessRamp
        case autoParking
        case busStop
        case planter
        case parking
        case unknown
    }
    
    /// Type of semantic zone
    public var zoneType: ZoneType
    
    /// ID corresponding to a specific zone
    public var id: String?
    
    init(zoneType: ZoneType, id: String?) {
        self.zoneType = zoneType
        self.id = id
    }
    
}

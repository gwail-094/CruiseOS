//
//  NetworkManager.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 13.03.2026.
//

import Foundation
import CoreTelephony
import Observation
import SwiftUI

@MainActor
@Observable
class NetworkManager {
    var signalBars: Int = 4 // 0 to 4
    private let networkInfo = CTTelephonyNetworkInfo()
    private var timer: Timer?

    init() {
        updateSignalStrength()
        startMonitoring()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSignalStrength()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateSignalStrength() {
        // In a real CarPlay/iOS environment, accessing precise signal bars 
        // usually requires private APIs or is handled by the system status bar.
        // For this app, we'll simulate a realistic fluctuation or use available technology info.
        
        let radioTech = networkInfo.serviceCurrentRadioAccessTechnology
        
        if let tech = radioTech?.values.first {
            switch tech {
            case CTRadioAccessTechnologyLTE, CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA:
                signalBars = Int.random(in: 3...4)
            case CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyGPRS:
                signalBars = Int.random(in: 1...2)
            default:
                signalBars = Int.random(in: 2...4)
            }
        } else {
            // No service or simulator
            signalBars = Int.random(in: 2...4) 
        }
    }
    
    var cellularIcon: String {
        switch signalBars {
        case 0: return "antenna.radiowaves.left.and.right.slash"
        case 1: return "cellularbars" // This would ideally be a specific level icon
        case 2: return "cellularbars"
        case 3: return "cellularbars"
        case 4: return "cellularbars"
        default: return "cellularbars"
        }
    }
    
    // SF Symbols 5+ supports variable value for cellularbars
    var signalValue: Double {
        return Double(signalBars) / 4.0
    }
}

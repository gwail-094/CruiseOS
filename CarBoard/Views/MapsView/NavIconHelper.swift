//
//  NavIconHelper.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 15.03.2026.
//

import Foundation

func iconFor(instruction: String) -> String {
    let text = instruction.lowercased()
    let isCross = text.contains("intersection") || text.contains("junction") || text.contains("cross")
    
    // 1. Start Navigation
    if text.contains("start") || text.contains("begin") || text.contains("head north") || text.contains("head south") || text.contains("head east") || text.contains("head west") {
        return "start_nav"
    }
    
    // 2. Roundabouts (rb_4x_1, rb_4x_2, rb_4x_3)
    if text.contains("roundabout") {
        if text.contains("1st exit") || text.contains("first exit") {
            return "rb_4x_1"
        } else if text.contains("2nd exit") || text.contains("second exit") {
            return "rb_4x_2"
        } else if text.contains("3rd exit") || text.contains("third exit") {
            return "rb_4x_3"
        }
        // Default roundabout if exit not specified (could use rb_4x_2 as generic straight-ish)
        return "rb_4x_2"
    }
    
    // 3. U-Turns
    if text.contains("u-turn") || text.contains("make a u-turn") {
        if text.contains("left") {
            return "u_turn_left"
        } else {
            return "u_turn_right"
        }
    }
    
    // 4. Highway/Freeway Exits & Slanted Arrows
    // "straight_leave" vs "leave"
    if text.contains("exit") || text.contains("take the ramp") || text.contains("fork") || text.contains("keep right") || text.contains("keep left") {
        // We use "straight_leave" if the instruction suggests the main road continues 
        // (e.g., "stay on", "continue", "lane", or explicit "straight")
        let indicatesStraightContinuing = text.contains("straight") || text.contains("continue") || text.contains("stay") || text.contains("lane")
        
        if text.contains("left") {
            return indicatesStraightContinuing ? "straight_leave_left" : "leave_left"
        } else {
            return indicatesStraightContinuing ? "straight_leave_right" : "leave_right"
        }
    }

    // 5. Standard Turns & Slight Turns
    let isSlight = text.contains("slight")
    
    if text.contains("turn right") || text.contains("branch right") {
        if isSlight { return "slight_right" }
        return isCross ? "turn_right_cross" : "turn_right"
    } else if text.contains("turn left") || text.contains("branch left") {
        if isSlight { return "slight_left" }
        return isCross ? "turn_left_cross" : "turn_left"
    } 
    
    // 6. Go Straight
    return isCross ? "go_straight_cross" : "go_straight"
}

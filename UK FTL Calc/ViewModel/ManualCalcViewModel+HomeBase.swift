//
//  ManualCalcViewModel+HomeBase.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - Home Base Management Extension
extension ManualCalcViewModel {
    
    // MARK: - Home Base Management
    func initializeEditingHomeBases() {
        // Read directly from UserDefaults
        let storedHomeBase = UserDefaults.standard.string(forKey: "homeBase") ?? "LHR"
        let storedSecondHomeBase = UserDefaults.standard.string(forKey: "secondHomeBase") ?? ""
        
        editingHomeBase = storedHomeBase
        editingSecondHomeBase = storedSecondHomeBase
    }
    
    func updateHomeBases() {
        // Use the manual update method for more reliable updates
        manuallyUpdateHomeBases()
        
        // Reset the change flag
        homeBaseChanged = false
    }
    
    func refreshPublishedHomeBases() {
        // Read directly from UserDefaults
        let storedHomeBase = UserDefaults.standard.string(forKey: "homeBase") ?? "LHR"
        let storedSecondHomeBase = UserDefaults.standard.string(forKey: "secondHomeBase") ?? ""
        
        // Update the @Published properties
        currentHomeBase = storedHomeBase
        currentSecondHomeBase = storedSecondHomeBase
    }
    
    func forceHomeBaseRefresh() {
        refreshPublishedHomeBases()
        
        // Force UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func manuallyUpdateHomeBases() {
        // Manually update UserDefaults
        UserDefaults.standard.set(editingHomeBase, forKey: "homeBase")
        UserDefaults.standard.set(editingSecondHomeBase, forKey: "secondHomeBase")
        
        // Update the @Published properties
        currentHomeBase = editingHomeBase
        currentSecondHomeBase = editingSecondHomeBase
        
        // Clear cache
        clearCache()
        
        // Force UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

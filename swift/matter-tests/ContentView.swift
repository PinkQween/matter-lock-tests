//
//  ContentView.swift
//  matter-tests
//
//  Created by Boone, Hanna - Student on 4/9/24.
//

import SwiftUI
import HomeKit
import Combine

class DoorLockManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryDelegate {
    public var homeManager: HMHomeManager? // Making homeManager public
    private var lockAccessory: HMAccessory?
    private var lockService: HMService?

    @Published var doorLockState: HMCharacteristicValueLockMechanismState = .unknown

    override init() {
        super.init()
        homeManager = HMHomeManager()
        homeManager?.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        guard let home = manager.primaryHome else { return }
        for accessory in home.accessories {
            if accessory.name == "YourDoorLockAccessoryName" {
                lockAccessory = accessory
                lockAccessory?.delegate = self
                lockService = accessory.services.first {
                    $0.serviceType == "00000045-0000-1000-8000-0026BB765291" // Service type for Lock Mechanism
                }
                readDoorLockState()
                break
            }
        }
    }

    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        if service.serviceType == "00000045-0000-1000-8000-0026BB765291" && // Service type for Lock Mechanism
            characteristic.characteristicType == "0000001D-0000-1000-8000-0026BB765291" { // Characteristic type for Lock Current State
            if let lockState = characteristic.value as? HMCharacteristicValueLockMechanismState {
                DispatchQueue.main.async {
                    self.doorLockState = lockState
                }
            }
        }
    }

    func toggleDoorLockState() {
        guard let lockService = lockService else { return }
        let targetState: HMCharacteristicValueLockMechanismState = doorLockState == .secured ? .unsecured : .secured
        lockService.characteristics.forEach { characteristic in
            if characteristic.characteristicType == "0000001E-0000-1000-8000-0026BB765291" { // Characteristic type for Lock Target State
                characteristic.writeValue(targetState) { error in
                    if let error = error {
                        print("Error toggling door lock state: \(error.localizedDescription)")
                    } else {
                        self.readDoorLockState()
                    }
                }
            }
        }
    }

    func readDoorLockState() {
        guard let lockService = lockService else { return }
        lockService.characteristics.forEach { characteristic in
            if characteristic.characteristicType == "0000001D-0000-1000-8000-0026BB765291" { // Characteristic type for Lock Current State
                characteristic.readValue { error in
                    if let error = error {
                        print("Error reading door lock state: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var doorLockState: HMCharacteristicValueLockMechanismState = .unknown
    @StateObject private var doorLockManager = DoorLockManager()

    var body: some View {
        VStack {
            Text("Door Lock Status: \(doorLockState.rawValue)")

            Button(action: {
                doorLockManager.toggleDoorLockState()
            }) {
                Text(doorLockState == .secured ? "Unlock Door" : "Lock Door")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .onAppear {
            doorLockManager.homeManager?.delegate = doorLockManager
        }
    }
}

#Preview {
    ContentView()
}

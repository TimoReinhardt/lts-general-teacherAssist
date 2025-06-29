//
//  ContentView.swift
//  ATWatcher
//
//  Created by Timo Reinhardt on 17.06.25.
//

// Main interface for the ATWatcher app.
// Guides the user step-by-step to select building, level, and room,
// includes a status indicator and a blinking animation for visual feedback.

import SwiftUI
import Combine



struct ContentView: View {
    @StateObject private var apiManager = APIManager()

    // Changed to optional types to reflect real data from apiManager
    @State private var selectedBuilding: String? = nil
    @State private var selectedLevel: Int? = nil
    @State private var selectedRoomID: String? = nil

    // Current step in the selection process (0 = building, 1 = level, etc.)
    @State private var step = 0

    // Used to highlight (blink) a dot in the status bar
    @State private var blinkingStep: Int? = nil

    @State private var showUnlockPopup = false
    
    // Computed properties based on apiManager data
    
    var availableBuildings: [String] {
        Array(Set(apiManager.availableDevicePool.map { $0.building })).sorted()
    }
    
    // There is no Building struct—levels are derived from Device objects for the selected building.
    var availableLevels: [Int] {
        guard let building = selectedBuilding,
              let buildingObject = apiManager.availableDevicePool.first(where: { $0.building == building }) else { return [] }
        return buildingObject.levels.map { $0.level }.sorted()
    }
    
    var availableDevices: [Device] {
        guard let building = selectedBuilding, let level = selectedLevel else { return [] }
        let devices = apiManager.devices(inBuilding: building, level: level)
        return devices.sorted { $0.room < $1.room }
    }

    var body: some View {
        
        VStack {
            Text("ATWatch")
                .font(.title)
                .bold()
            Text("Assistent für Lehrkräfte")
            Spacer()
            TabView(selection: $step) {
                
                // Step 0: Select building
                VStack {
                    Text("Um welches Gebäude handelt es sich?")
                        .font(.headline)
                        .padding(.bottom, 8)
                    HStack(spacing: 8) {
                        Text("Bitte auswählen:")
                        Picker("Gebäude", selection: Binding(
                            get: { selectedBuilding ?? "" },
                            set: { newValue in
                                selectedBuilding = newValue.isEmpty ? nil : newValue
                                // Reset subsequent selections
                                selectedLevel = nil
                                selectedRoomID = nil
                            })) {
                            ForEach(availableBuildings, id: \.self) { building in
                                Text(building).tag(building)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 80)
                        .disabled(availableBuildings.isEmpty)
                        .animation(.easeInOut(duration: 0.3), value: selectedBuilding)
                    }
                    HStack(spacing: 12) {
                        if step > 0 {
                            Button("Zurück") {
                                withAnimation { step -= 1 }
                            }
                            .buttonStyle(.bordered)
                        }
                        Button("Weiter") {
                            withAnimation { step += 1 }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedBuilding == nil)
                    }
                    .padding(.top, 12)
                }
                .tag(0)
                
                // Step 1: Select level
                VStack {
                    Text("Welche Etage?")
                        .font(.headline)
                        .padding(.bottom, 8)
                    HStack(spacing: 8) {
                        Text("Bitte auswählen:")
                        Picker("Etage", selection: Binding(
                            get: { selectedLevel ?? Int.min },
                            set: { newValue in
                                selectedLevel = newValue == Int.min ? nil : newValue
                                selectedRoomID = nil
                            })) {
                            ForEach(availableLevels, id: \.self) { level in
                                Text("\(level)").tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 80)
                        .disabled(selectedBuilding == nil || availableLevels.isEmpty)
                        .animation(.easeInOut(duration: 0.3), value: selectedLevel)
                    }
                    HStack(spacing: 12) {
                        if step > 0 {
                            Button("Zurück") {
                                withAnimation { step -= 1 }
                            }
                            .buttonStyle(.bordered)
                        }
                        Button("Weiter") {
                            withAnimation { step += 1 }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedLevel == nil)
                    }
                    .padding(.top, 12)
                }
                .tag(1)
                
                // Step 2: Select room/device
                VStack {
                    Text("Welcher Raum?")
                        .font(.headline)
                        .padding(.bottom, 8)
                    HStack(spacing: 8) {
                        Text("Bitte auswählen:")
                        Picker("Raum", selection: Binding(
                            get: { selectedRoomID ?? "" },
                            set: { newValue in
                                selectedRoomID = newValue.isEmpty ? nil : newValue
                            })) {
                            ForEach(availableDevices) { device in
                                Text("\(device.room) - \(device.name)").tag(device.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200)
                        .disabled(selectedLevel == nil || availableDevices.isEmpty)
                        .animation(.easeInOut(duration: 0.3), value: selectedRoomID)
                    }
                    HStack(spacing: 12) {
                        if step > 0 {
                            Button("Zurück") {
                                withAnimation { step -= 1 }
                            }
                            .buttonStyle(.bordered)
                        }
                        Button("Weiter") {
                            withAnimation { step += 1 }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedRoomID == nil)
                    }
                    .padding(.top, 12)
                }
                .tag(2)
                
                // Step 3: Confirmation and unlock
                VStack {
                    Text("**Möchten Sie folgenden AppleTV zur Nutzung freischalten?**")
                    if let building = selectedBuilding,
                       let level = selectedLevel,
                       let device = availableDevices.first(where: { $0.id == selectedRoomID }) {
                        Text("\(building).\(level).\(device.room) – \(device.name)")
                    } else {
                        Text("Ungültige Auswahl")
                    }
                   
                    Text("Die Freischaltung kann nach Anforderung einige Minuten dauern.")
                        .padding(.top, 20)
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    Text("Nach 90 Minuten wird der AppleTV automatisch wieder gesperrt.")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    HStack(spacing: 12) {
                        if step > 0 {
                            Button("Zurück") {
                                withAnimation { step -= 1 }
                            }
                            .buttonStyle(.bordered)
                        }
                        Button("Jetzt freischalten") {
                            blinkStatusBar()
                            showUnlockPopup = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedBuilding == nil || selectedLevel == nil || selectedRoomID == nil)
                    }
                    .padding(.top, 12)
                }
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(maxHeight: 200)
            
            // Status indicators: show progress and blinking animations
            HStack(spacing: 12) {
                ForEach(0..<4) { index in
                    let isCompleted = index < step
                    let isCurrent = index == step
                    let isBlinking = index == blinkingStep

                    Circle()
                        .fill(
                            isBlinking ? Color.green :
                            isCompleted ? Color.green :
                            isCurrent ? Color.yellow :
                            Color.gray.opacity(0.4)
                        )
                        .frame(width: 12, height: 12)
                        .background(
                            (isCurrent || isBlinking) ?
                            Circle()
                                .fill((isCurrent ? Color.yellow : Color.green).opacity(0.2))
                                .frame(width: 24, height: 24)
                            : nil
                        )
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            .padding(.all, 25)
            
            Spacer()
        }
        .sheet(isPresented: $showUnlockPopup) {
            UnlockPopupView()
        }
        .task {
            await apiManager.fetchAvailableDevicesFromBackend()
        }
    }
    
    private func blinkStatusBar() {
        Task {
            // Temporarily hide the current step indicator
            step = -1
            // Loop 4 times, blinking all 4 steps in random order
            for _ in 0..<4 {
                let indices = (0..<4).shuffled()
                for index in indices {
                    blinkingStep = index
                    try? await Task.sleep(nanoseconds: 75_000_000)
                    blinkingStep = nil
                    try? await Task.sleep(nanoseconds: 25_000_000)
                }
            }
            // Reset form to initial state after blinking
            selectedBuilding = nil
            selectedLevel = nil
            selectedRoomID = nil
            step = 0
        }
    }
}

#Preview {
    ContentView()
}


struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

struct UnlockPopupView: View {
    var body: some View {
        VStack {
            VStack(spacing: 24) {
            Text("Freischaltung beauftragt")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.top, 45)

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 30))
                    VStack(alignment: .leading) {
                        Text("Auftrag angelegt")
                            .bold()
                        Text("Ihr Auftrag wurde an die IT-Verwaltung übermittelt.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "2.circle")
                        .foregroundColor(.red)
                        .font(.system(size: 30))
                    VStack(alignment: .leading) {
                        Text("Freischaltung wird ausgeführt")
                            .bold()
                        Text("Der AppleTV zur Nutzung freigeschaltet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Dieser Vorgang kann einige Minuten dauern.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "3.circle")
                        .foregroundColor(.red)
                        .font(.system(size: 30))
                    VStack(alignment: .leading) {
                        Text("Automatische Sperre geplant")
                            .bold()
                        Text("Nach 90 Minuten wird die AppleTV wieder gesperrt.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

                
            Button("Schließen") {
                // Kann zum Schließen in .sheet verwendet werden
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 45)
                Spacer()
            }
            .padding(.horizontal, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}


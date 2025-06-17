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

struct ContentView: View {
    // Currently selected building ("A" or "B")
    @State private var selectedBuilding = "A"
    
    // Currently selected level in the building
    @State private var selectedLevel = 0

    // Currently selected room number
    @State private var selectedRoom = 1

    // Current step in the selection process (0 = building, 1 = level, etc.)
    @State private var step = 0

    // Used to highlight (blink) a dot in the status bar
    @State private var blinkingStep: Int? = nil

    @State private var showUnlockPopup = false
    
    private var levelsForSelectedBuilding: [Int] {
        selectedBuilding == "A" ? [-1, 0, 1] : [0, 1, 2]
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
                        Picker("Gebäude", selection: $selectedBuilding) {
                            Text("A").tag("A")
                            Text("B").tag("B")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 80)
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
                        Picker("Etage", selection: $selectedLevel) {
                            ForEach(levelsForSelectedBuilding, id: \.self) { level in
                                Text("\(level)").tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 80)
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
                    }
                    .padding(.top, 12)
                }
                .tag(1)
                // Step 2: Select room
                VStack {
                    Text("Welcher Raum?")
                        .font(.headline)
                        .padding(.bottom, 8)
                    HStack(spacing: 8) {
                        Text("Bitte auswählen:")
                        Picker("Raum", selection: $selectedRoom) {
                            ForEach(1...35, id: \.self) { room in
                                Text("\(room)").tag(room)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 100)
                        .animation(.easeInOut(duration: 0.3), value: selectedRoom)
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
                    }
                    .padding(.top, 12)
                }
                .tag(2)
                // Step 3: Confirmation and unlock
                VStack {
                    Text("**Möchten Sie folgenden AppleTV zur Nutzung freischalten?**")
                    Text("\(selectedBuilding).\(selectedLevel).\(selectedRoom)")
                   
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
            selectedBuilding = "A"
            selectedLevel = 0
            selectedRoom = 1
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

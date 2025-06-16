//
//  ContentView.swift
//  MacBook Cleaning Mode
//
//  Created by Tariq Shafiq on 6/16/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isLocked = false
    @State private var cmdHeldStart: Date? = nil
    @State private var unlockTimer: Timer? = nil
    @State private var eventMonitor: Any? = nil

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            if isLocked {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.accentColor)
                        .padding(.bottom, 16)
                    Text("Cleaning Mode Enabled")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Hold ⌘ for 5 seconds to disable")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.98))
                .ignoresSafeArea()
                .onAppear {
                    NSCursor.hide()
                    startMonitoring()
                }
                .onDisappear {
                    NSCursor.unhide()
                    stopMonitoring()
                }
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    Button(action: { isLocked = true }) {
                        Text("Lock My Screen")
                            .font(.system(size: 36, weight: .bold))
                            .padding(.horizontal, 48)
                            .padding(.vertical, 24)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.accentColor))
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                    Text("Hold ⌘ for 5 seconds to disable")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private func startMonitoring() {
        stopMonitoring()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { event in
            if event.modifierFlags.contains(.command) {
                if cmdHeldStart == nil {
                    cmdHeldStart = Date()
                    unlockTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                        isLocked = false
                        cmdHeldStart = nil
                        unlockTimer?.invalidate()
                        unlockTimer = nil
                    }
                }
            } else {
                cmdHeldStart = nil
                unlockTimer?.invalidate()
                unlockTimer = nil
            }
            return event
        }
    }

    private func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        cmdHeldStart = nil
        unlockTimer?.invalidate()
        unlockTimer = nil
    }
}

#Preview {
    ContentView()
}

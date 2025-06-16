//
//  ContentView.swift
//  MacBook Cleaning Mode
//
//  Created by Tariq Shafiq on 6/16/25.
//

import SwiftUI

struct GlassBackground: View {
    var body: some View {
        VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
            .ignoresSafeArea()
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct AppleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 48)
            .padding(.vertical, 24)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.95), Color.accentColor.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
            )
            .cornerRadius(16)
            .shadow(color: Color.accentColor.opacity(configuration.isPressed ? 0.2 : 0.4), radius: configuration.isPressed ? 6 : 16, y: configuration.isPressed ? 2 : 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ContentView: View {
    @State private var isLocked = false
    @State private var cmdHeldStart: Date? = nil
    @State private var unlockTimer: Timer? = nil
    @State private var eventMonitor: Any? = nil
    @Namespace private var lockTransition

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            if isLocked {
                GlassBackground()
                    .transition(.opacity)
                VStack(spacing: 32) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.18))
                            .frame(width: 160, height: 160)
                            .blur(radius: 2)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.5), radius: 18, y: 4)
                    }
                    .matchedGeometryEffect(id: "lockIcon", in: lockTransition)
                    Text("Cleaning Mode Enabled")
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                    Text("Hold ⌘ for 5 seconds to disable")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.85))
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.4)) {}
                    NSCursor.hide()
                    startMonitoring()
                }
                .onDisappear {
                    NSCursor.unhide()
                    stopMonitoring()
                }
            } else {
                VStack(spacing: 36) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.10))
                            .frame(width: 120, height: 120)
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 2)
                    }
                    .matchedGeometryEffect(id: "lockIcon", in: lockTransition)
                    Button(action: { withAnimation(.easeInOut(duration: 0.4)) { isLocked = true } }) {
                        Text("Lock My Screen")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    .buttonStyle(AppleButtonStyle())
                    Text("Hold ⌘ for 5 seconds to disable")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
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
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isLocked = false
                        }
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

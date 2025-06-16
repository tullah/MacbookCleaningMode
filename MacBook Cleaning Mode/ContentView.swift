//
//  ContentView.swift
//  MacBook Cleaning Mode
//
//  Created by Tariq Shafiq on 6/16/25.
//

import SwiftUI
import AppKit

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

struct MouseBlockerView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.withAlphaComponent(1.0).cgColor
        view.addTrackingArea(NSTrackingArea(rect: .infinite, options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved], owner: view, userInfo: nil))
        view.allowedTouchTypes = [.direct, .indirect]
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
    static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
        nsView.trackingAreas.forEach { nsView.removeTrackingArea($0) }
    }
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
    @Environment(\.scenePhase) private var scenePhase
    @State private var checklist: [GestureSetting] = GestureSetting.defaultChecklist
    @State private var showChecklist: Bool = true
    @State private var unlockProgress: Double = 0.0
    private let unlockDuration: Double = 5.0

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            if isLocked {
                // Jony Ive style: pure focus, no icons, no gradients, just text
                MouseBlockerView()
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: 16)
                            .frame(width: 90, height: 90)
                        Circle()
                            .trim(from: 0, to: unlockProgress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 90, height: 90)
                            .animation(.linear(duration: 0.1), value: unlockProgress)
                    }
                    .padding(.bottom, 24)
                    Text("Hold ⌘ for 5 seconds to exit Cleaning Mode.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.4)) {}
                    NSCursor.hide()
                    startMonitoring()
                    enterFullScreen()
                    disableWindowCloseButton(true)
                }
                .onDisappear {
                    NSCursor.unhide()
                    stopMonitoring()
                    exitFullScreen()
                    disableWindowCloseButton(false)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    if isLocked {
                        enterFullScreen()
                        NSCursor.hide()
                    }
                }
            } else {
                VStack(spacing: 0) {
                    Spacer()
                    HStack(alignment: .center, spacing: 48) {
                        VStack(alignment: .center, spacing: 28) {
                            Text("MacBook Cleaning Mode")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .padding(.top, 8)
                            Text("Safely clean your MacBook without accidental input.")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Divider().padding(.vertical, 2)
                            Text("What happens when you enable Cleaning Mode:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            HStack(spacing: 24) {
                                InfoCard(icon: "lock.fill", text: "All input is blocked")
                                InfoCard(icon: "display", text: "Screen goes black")
                                InfoCard(icon: "command", text: "Hold ⌘ for 5s to exit")
                            }
                            Divider().padding(.vertical, 2)
                        }
                        .frame(maxWidth: 520, alignment: .top)
                        VStack(spacing: 18) {
                            ScreenshotZoomable()
                            Text("For the strictest lock, you can temporarily disable trackpad gestures in System Settings > Trackpad > More Gestures.")
                                .font(.footnote)
                                .foregroundColor(Color.secondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                            Button(action: openTrackpadSettings) {
                                Text("Open Trackpad Settings")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.accentColor)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.accentColor.opacity(0.10))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(maxWidth: 360, alignment: .top)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                    Button(action: { withAnimation(.easeInOut(duration: 0.4)) { isLocked = true } }) {
                        Text("Enable Cleaning Mode")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor)
                            )
                            .scaleEffect(isLocked ? 0.98 : 1.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isLocked)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 32)
                    .padding(.bottom, 32)
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
                    unlockProgress = 0.0
                    unlockTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                        if let start = cmdHeldStart {
                            let elapsed = min(Date().timeIntervalSince(start), unlockDuration)
                            unlockProgress = elapsed / unlockDuration
                            if elapsed >= unlockDuration {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    isLocked = false
                                }
                                cmdHeldStart = nil
                                unlockTimer?.invalidate()
                                unlockTimer = nil
                                unlockProgress = 0.0
                            }
                        }
                    }
                }
            } else {
                cmdHeldStart = nil
                unlockTimer?.invalidate()
                unlockTimer = nil
                unlockProgress = 0.0
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

    private func enterFullScreen() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first, !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }

    private func exitFullScreen() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first, window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }

    private func openTrackpadSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.Trackpad-Settings.extension")
        if let url = url {
            NSWorkspace.shared.open(url)
        }
    }

    private func disableWindowCloseButton(_ disabled: Bool) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.standardWindowButton(.closeButton)?.isEnabled = !disabled
                window.standardWindowButton(.miniaturizeButton)?.isEnabled = !disabled
                window.standardWindowButton(.zoomButton)?.isEnabled = !disabled
            }
        }
    }
}

#Preview {
    ContentView()
}

// NOTE: macOS does not allow blocking of system gestures (Mission Control, Launchpad, swipe gestures) from sandboxed apps. This is a system security feature and cannot be bypassed with public APIs.

// Checklist model for gesture settings
struct GestureSetting: Identifiable {
    let id = UUID()
    let title: String
    var completed: Bool

    static let defaultChecklist: [GestureSetting] = [
        GestureSetting(title: "Disable \"Swipe between full-screen applications\"", completed: false),
        GestureSetting(title: "Disable \"Mission Control\" gesture", completed: false),
        GestureSetting(title: "Disable \"App Exposé\" gesture", completed: false),
        GestureSetting(title: "Disable \"Launchpad\" gesture", completed: false),
        GestureSetting(title: "Disable \"Show Desktop\" gesture", completed: false)
    ]
}

// Square card for info
struct InfoCard: View {
    let icon: String
    let text: String
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 110, height: 120)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(18)
    }
}

// Zoomable screenshot with hover effect
struct ScreenshotZoomable: View {
    @State private var isHovered = false
    var body: some View {
        Image("trackpad_gestures")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 340)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.18), radius: 16, y: 6)
            .scaleEffect(isHovered ? 1.25 : 1.0)
            .zIndex(isHovered ? 10 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

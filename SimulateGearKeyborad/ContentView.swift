//
//  ContentView.swift
//  SimulateGearKeyborad
//
//  Created by LuckyE on 1/13/26.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var appController = AppController.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var keyboardMonitor = KeyboardMonitor.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // 权限提示
            if !keyboardMonitor.hasAccessibilityPermission {
                PermissionBanner()
            }
            
            // 安全模式提示
            if keyboardMonitor.isSecureInputEnabled {
                SecureModeBanner()
            }
            
            // 控制区域
            VStack(alignment: .leading, spacing: 8) {
                Toggle("启用音效", isOn: $appController.isEnabled)
                    .toggleStyle(.switch)
                
                HStack(spacing: 8) {
                    Text("音量")
                        .frame(width: 40, alignment: .leading)
                    Slider(value: $appController.volume, in: 0...1)
                    Text("\(Int(appController.volume * 100))%")
                        .frame(width: 44, alignment: .trailing)
                        .monospacedDigit()
                }
                .font(.caption)
            }

            Divider()

            // 主题选择网格
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 12)], spacing: 12) {
                    ForEach(themeManager.schemes) { scheme in
                        ThemeCell(
                            scheme: scheme,
                            isSelected: scheme.id == themeManager.currentScheme?.id
                        )
                        .onTapGesture {
                            appController.selectTheme(scheme)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 220)

            Divider()

            // 底部按钮
            HStack {
                SettingsLink {
                    Label("设置", systemImage: "gear")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(12)
        .frame(width: 320)
        .onAppear {
            appController.start()
        }
    }
}

// MARK: - Permission Banner

private struct PermissionBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("需要辅助功能权限")
                .font(.caption)
            Spacer()
            Button("授权") {
                KeyboardMonitor.shared.requestAccessibilityPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(8)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Secure Mode Banner

private struct SecureModeBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.secondary)
            Text("安全输入模式 - 已静音")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Theme Cell

private struct ThemeCell: View {
    let scheme: AudioScheme
    let isSelected: Bool
    
    private var iconName: String {
        switch scheme.name {
        case "typewriter": return "keyboard"
        case "bubble": return "bubble.left.and.bubble.right"
        case "mechanical": return "switch.2"
        case "sword": return "bolt"
        case "drum": return "music.note"
        case "Cherry_G80_3000", "Cherry_G80_3494": return "keyboard.badge.ellipsis"
        default: return "waveform"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title3)
                .frame(width: 40, height: 32)
            Text(scheme.displayName)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.headline)
            
            GroupBox("音效包管理") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("已加载 \(themeManager.schemes.count) 个音效包")
                        .font(.subheadline)
                    
                    Text("音效资源位于 SoundData 目录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            
            GroupBox("关于") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BarSound")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("macOS 高性能机械键盘音效引擎")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

#Preview {
    ContentView()
}

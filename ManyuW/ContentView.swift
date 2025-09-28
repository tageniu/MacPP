//
//  ContentView.swift
//  ManyuW
//
//  Created by 木木 on 2025/9/28.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appManager = AppManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索应用程序...", text: $appManager.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                Divider()
                
                // 应用列表
                if appManager.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("正在加载应用程序...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                } else {
                    List(appManager.filteredApplications) { app in
                        AppRowView(app: app, appManager: appManager)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("应用多开工具")
            .navigationSubtitle("选择要启动的应用程序")
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

// 应用行视图
struct AppRowView: View {
    let app: AppInfo
    let appManager: AppManager
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 应用图标
            Group {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "app")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 32, height: 32)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            
            // 应用信息
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let version = app.version {
                    Text("版本 \(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(app.bundleIdentifier)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 启动按钮
            Button(action: {
                appManager.launchApplication(app)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                    Text("启动")
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isHovered ? 1.0 : 0.7)
        }
        .padding(.vertical, 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    ContentView()
}

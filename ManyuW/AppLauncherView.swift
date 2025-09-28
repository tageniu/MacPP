//
//  AppLauncherView.swift
//  ManyuW
//
//  Created by 木木 on 2025/9/28.
//

import SwiftUI

// 应用启动器视图 - 提供更高级的功能
struct AppLauncherView: View {
    @StateObject private var appManager = AppManager()
    @State private var selectedApps: Set<UUID> = []
    @State private var showFavorites = false
    @State private var favoriteApps: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 工具栏
                HStack {
                    // 搜索栏
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索应用程序...", text: $appManager.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .frame(maxWidth: 300)
                    
                    Spacer()
                    
                    // 工具栏按钮
                    HStack(spacing: 12) {
                        Button(action: {
                            showFavorites.toggle()
                        }) {
                            Image(systemName: showFavorites ? "heart.fill" : "heart")
                                .foregroundColor(showFavorites ? .red : .primary)
                        }
                        .help("显示收藏应用")
                        
                        Button(action: {
                            appManager.loadApplications()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("刷新应用列表")
                        
                        if !selectedApps.isEmpty {
                            Button(action: {
                                launchSelectedApps()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "play.fill")
                                    Text("批量启动 (\(selectedApps.count))")
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                            .help("启动选中的应用")
                        }
                    }
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
                    List(selection: $selectedApps) {
                        ForEach(filteredApps) { app in
                            AppRowView(app: app, appManager: appManager)
                                .tag(app.id)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("应用多开工具")
            .navigationSubtitle("选择要启动的应用程序")
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            loadFavorites()
        }
    }
    
    // 过滤后的应用列表
    private var filteredApps: [AppInfo] {
        let apps = appManager.filteredApplications
        
        if showFavorites {
            return apps.filter { favoriteApps.contains($0.bundleIdentifier) }
        }
        
        return apps
    }
    
    // 启动选中的应用
    private func launchSelectedApps() {
        let selectedAppInfos = appManager.applications.filter { selectedApps.contains($0.id) }
        
        for app in selectedAppInfos {
            appManager.launchApplication(app)
        }
        
        selectedApps.removeAll()
    }
    
    // 加载收藏应用
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "FavoriteApps"),
           let favorites = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteApps = favorites
        }
    }
    
    // 保存收藏应用
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteApps) {
            UserDefaults.standard.set(data, forKey: "FavoriteApps")
        }
    }
}

// 增强版应用行视图
struct EnhancedAppRowView: View {
    let app: AppInfo
    let appManager: AppManager
    @State private var isHovered = false
    @State private var isFavorite = false
    
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
            .frame(width: 40, height: 40)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // 应用信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 收藏按钮
                    Button(action: {
                        toggleFavorite()
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(isHovered ? 1.0 : 0.0)
                }
                
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
            
            // 操作按钮
            HStack(spacing: 8) {
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
                
                // 在Finder中显示
                Button(action: {
                    NSWorkspace.shared.selectFile(app.path, inFileViewerRootedAtPath: "")
                }) {
                    Image(systemName: "folder")
                        .font(.caption)
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isHovered ? 1.0 : 0.0)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onAppear {
            loadFavoriteStatus()
        }
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        // 这里可以添加保存收藏状态的逻辑
    }
    
    private func loadFavoriteStatus() {
        // 这里可以添加加载收藏状态的逻辑
    }
}

#Preview {
    AppLauncherView()
}

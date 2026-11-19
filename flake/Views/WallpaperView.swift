//
//  WallpaperView.swift
//  Flake
//
//  Created by Squair on 2026-11-17.
//

import SwiftUI
import WebKit
import GIFImage

// lots of stuff below is inspired and from https://github.com/leminlimez/Pocket-Poster/blob/main/Pocket%20Poster/Views/NavigatorViews/ExploreView.swift
struct WallpaperView: View{
    @Environment(\.dismiss) var dismiss
    @State public var waf = FetchWallpapers()
    @State public var qf = PosterFuncs()
    @State public var view = WorseView()
    @State public var walls: [wallpapers] = []
    @State public var query = ""
    @State public var wallType = 0
    @State public var wallDisplay = "custom"
    @StateObject private var mgr = Man.shared
    @State public var isimported = false
    @State private var isalert: isalert?

    var body: some View{
        NavigationView{
            ScrollView{
                if walls.isEmpty{
                    ProgressView()
                        .scaleEffect(1.75)
                        .navigationTitle("Explore")
                } else{
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260))]){
                        VStack{
                            Picker("", selection: $wallType){
                                Text("Custom").tag(0)
                                Text("Apple").tag(1)
                            }
                            .pickerStyle(.segmented)
                        }
                        ForEach(walls){wall in
                            if query == "" || wall.name.lowercased().contains(query.lowercased()) || (wall.authors ?? "").lowercased().contains(query.lowercased()){
                                Walls(wall: wall){
                                    Task{
                                        print("[DW] downloading \(wall.name)")
                                        let success = await DownloadWallpaper(wall)
                                        if success{
                                            isalert = .importyay
                                        } else if !success{
                                            isalert = .importsad
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .searchable(text: $query)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button(){
                        dismiss()
                    }label:{
                        Image(systemName: "xmark")
                    }
                }
            }
            .navigationTitle("Explore")
        }
        .onAppear{
            loadWallpapers("custom")
        }
        .onChange(of: wallType){old, new in
            let map = [0: "custom", 1: "apple"]
            wallDisplay = map[new]!
            
            walls = []
            loadWallpapers(wallDisplay)
        }
        .alert(item: $isalert){e in
            switch e{
            case .importyay:
                return Alert(title: Text("Imported Successfully!"), message: Text("The wallpaper will appear in the main view."), dismissButton: .default(Text("Dismiss")))
            case .importsad:
                return Alert(title: Text("Failed to import"), message: Text("Check your internet connection!"), dismissButton: .default(Text("Dismiss")))
            case .iPad:
                return Alert(title: Text("iPad rendering"),message: Text("iPads are not yet fully optimized for the explore tab yet, sorry! but you can still use it!"),dismissButton: .default(Text("Dismiss")))
            }
        }
    }
    
    func loadWallpapers(_ type:String){
        Task{
            if UIDevice.current.userInterfaceIdiom == .pad{
                isalert = .iPad
            }
            walls = await waf.FetchWalls(type)
        }
    }

    @discardableResult
    func DownloadWallpaper(_ wall: wallpapers) async -> Bool{
        await waf.DownloadWallpaper(wall.url, wall.name)
    }
}

struct Walls: View{
    let wall: wallpapers
    let download: () -> Void
    @State public var ispresent = false
    var body: some View{
        let preview = "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/refs/heads/main/"+wall.preview
            VStack(spacing: 0){
                ZStack{
                    Color.gray.opacity(0.4)
                    if wall.IsGif(){
                        GIFImage(url: preview, animate: $ispresent)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    } else{
                        AsyncImage(url: URL(string: preview)){ image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        } placeholder:{
                            Color.gray
                                .frame(height: 260)
                        }
                    }
                }
                    .cornerRadius(40)
                    .cornerRadius(40)
                    .overlay(alignment: .bottom){
                        Button(action: download){
                            HStack{
                                VStack{
                                    Text(wall.name)
                                        .multilineTextAlignment(.leading)
                                        .fontWeight(.bold)
                                    if wall.authors != nil{
                                        Text(wall.authors!)
                                            .multilineTextAlignment(.leading)
                                    }
                                    if wall.description != nil && wall.preview.contains("apple/"){
                                        Text(wall.description!)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                    .padding()
                                Spacer()
                                
                                Image(systemName: "arrow.down.circle")
                                    .resizable()
                                    .padding()
                                    .frame(width: 55, height: 55)
                            }
                                .padding(.horizontal)
                                .foregroundStyle(.white)
                                .glassEffect(.regular.interactive())
                                .padding()
                        }
                    }
        }
        .onAppear{ispresent = true}
        .onDisappear{ispresent = false}
        .frame(minWidth: 260)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(50)
        .padding(4)
    }
}

enum isalert: Identifiable{
    case importyay
    case importsad
    case iPad
    
    var id: Self{self}
}

#Preview{
    WallpaperView().preferredColorScheme(.dark)
}

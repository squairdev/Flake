//
//  Worse.swift
//  flake
//
//  Created by Squair on 2026-11-02.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct WorseView: View {
    static let shared = WorseView()
    @ObservedObject var qf = PosterFuncs.shared
    @State public var importing = false
    @State public var whichpop: whichpop?
    @State private var applyactive: applydone? = nil
    var body: some View {
        NavigationStack{
            
            Form{
                Section(header: Text("Version 1.1")){
                    Button("Import"){
                        importing=true
                    }
                    
                    Button("Apply"){
                        let doit = qf.checkimports()
                        if doit == true{
                            applyactive = .success
                        } else if doit == false{
                            applyactive = .error
                        }
                    }
                    .alert(item: $applyactive) { alert in
                        switch alert {
                        case .success:
                            return Alert(
                                title: Text("Applied successfully!"),
                                message: Text("Once you click the button below, an app will open. Please close it from your app switcher (do not swipe out of it normally)."),
                                dismissButton: .default(
                                    Text("Open PosterBoard"),
                                    action: {
                                        if let cls = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
                                           let workspace = cls.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() as? NSObject{
                                            _ = workspace.perform(NSSelectorFromString("openApplicationWithBundleID:"), with: "com.apple.PosterBoard")
                                           }
                                    }
                                )
                            )
                        case .error:
                            return Alert(
                                title: Text("Error Applying Wallpaper(s)"),
                                message: Text("Something went wrong while applying! Please check the logs."),
                                dismissButton: .default(Text("Dismiss"))
                            )
                        }
                    }
                }
                Section(header: Text("Imported Wallpapers")) {
                    
                    // a very shitty implementation
                    if qf.imports.isEmpty{
                        Text("None imported :(")
                            .foregroundStyle(.secondary)
                    }else{
                        ForEach(qf.imports){item in
                            Text(item.names)
                        }
                        .onDelete{offsets in
                            for i in offsets{
                                qf.deleteimported(qf.imports[i])
                            }
                        }
                    }
                }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.item]){result in
                    qf.importwall(result)
                }
            }
            .onAppear{qf.refresh()}
            Spacer()
            
                .fileImporter(isPresented: $importing, allowedContentTypes: [.zip,.tendies]){
                    result in
                        qf.importwall(result)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(){
                            whichpop = .settings
                        }label: {
                            Image(systemName: "gear")
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button(){
                            whichpop = .explore
                        }label: {
                            Image(systemName: "safari")
                        }
                    }
                }
                .popover(item: $whichpop){e in
                    switch e {
                    case .settings:
                        SettingsView()
                    case .explore:
                        WallpaperView()
                    }
                }
                .navigationTitle("Flake")
        }
    }
}
enum applydone: Identifiable{
    case success
    case error
    var id: Self {self}
}

enum whichpop: Identifiable {
    case settings
    case explore
    
    var id: Self {self}
}

extension UTType{
    static let tendies = UTType(filenameExtension: "tendies", conformingTo: .zip)!
}

#Preview {
    WorseView().preferredColorScheme(.dark)
}

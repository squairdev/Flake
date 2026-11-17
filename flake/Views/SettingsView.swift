//
//  SettingsView.swift
//  flake
//
//  Created by Squair on 2026-11-16.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State public var qf = posterfuncs()
    @State public var wf = worsefuncs()
    @StateObject private var mgr = Man.shared
    var body: some View {
        NavigationStack{
            Form{
                Section(header: Text("Logs")){
                    
                        LogView()
                            .buttonStyle(.plain)
                            .modifier(TerminalPlatter())
                }
                Section(header: Text("Cache Settings")){
                    TextField("PosterBoard Container Path", text: $mgr.pbpath, axis: .vertical).lineLimit(2)
                    
                    Button("Update Path"){
                        if mgr.pbpath == ""{
                            UserDefaults.standard.removeObject(forKey: "com.apple.PosterBoard")
                            return
                        }
                        wf.save("com.apple.PosterBoard", mgr.pbpath)
                    }.disabled(mgr.pbpath.isEmpty)
                    
                    Button("Fetch Path"){
                        _=wf.containerpath(toget: "com.apple.PosterBoard", skipcheck:true)
                    }
                }
                Section(header: Text("PosterBoard Settings")){
                    
                    Button("Reset Collections",role: .destructive){
                        let e = wf.containerpath(toget: "com.apple.PosterBoard") + mgr.pbextension
                        _=wf.getrw(path: e)
                        let dir = URL(fileURLWithPath: e, isDirectory: true)
                        do{
                            for folders in try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil){
                                try FileManager.default.removeItem(at: folders)
                            }
                            print("[RM] reset collections")
                        }catch{
                            print("[RM] can't reset collections: \(error.localizedDescription)")
                        }
                    }.disabled(mgr.pbpath.isEmpty)
                    
                    Button("Reset MercuryPoster",role: .destructive){
                        let e = wf.containerpath(toget: "com.apple.PosterBoard") + mgr.mpextension
                        _=wf.getrw(path: e)
                        let dir = URL(fileURLWithPath: e, isDirectory: true)
                        do{
                            for folders in try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil){
                                try FileManager.default.removeItem(at: folders)
                            }
                            print("[RM] reset mercury")
                        }catch{
                            print("[RM] can't reset mercury: \(error.localizedDescription)")
                        }
                    }.disabled(mgr.pbpath.isEmpty)
                    
                    Button("Open PosterBoard"){
                        if let cls = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
                           let workspace = cls.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() as? NSObject{
                            _ = workspace.perform(NSSelectorFromString("openApplicationWithBundleID:"), with: "com.apple.PosterBoard")
                           }
                    }
                }
                Section(header: Text("Credits")){
                    CreditsView(name: "Squair", url: "https://github.com/squairdev", desc: "Main developer")
                    CreditsView(name: "jailbreakdotparty team", url: "https://github.com/jailbreakdotparty", desc: "Lots of worse_query functions and logs")
                    CreditsView(name: "forcequitOS", url: "https://github.com/forcequitos", desc: "worse_query exploit")
                    CreditsView(name: "0xjohnny", url: "https://github.com/0xjohnnydev", desc: "worse_query exploit")
                    CreditsView(name: "roooot", url: "https://github.com/rooootdev", desc: "file picker fix & credits UI")
                }
            }
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(){
                            dismiss()
                        }label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView().preferredColorScheme(.dark)
}

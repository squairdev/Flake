//
//  flakeApp.swift
//  flake
//
//  Created by Squair on 2026-11-16.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct flakeApp: App {
    init(){
        // thanks rooootdev
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
        // sees if pb path is stored
        let e = UserDefaults.standard.value(forKey: "com.apple.PosterBoard") as? String ?? "err"
        if (e != "err"){
            Man.shared.pbpath = e
        }else{UserDefaults.standard.removeObject(forKey: "com.apple.PosterBoard")}
        
        guard let docsurl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let url = docsurl.appendingPathComponent("Wallpapers", isDirectory: true)
        // makes dir :shrug:
        do{
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch{
            print("[SD] can't make wallpaper dir: \(error.localizedDescription)")
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

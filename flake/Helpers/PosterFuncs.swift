//
//  pb_funcs.swift
//  flake
//
//  Created by Squair on 2026-11-15.
//

import SwiftUI
import Foundation
import ZIPFoundation
import Combine

public class PosterFuncs: ObservableObject {
    static let shared = PosterFuncs()
    let wf = WorseFuncs()
    let mgr = Man.shared
    @Published var imports: [imported] = []
    
    // MARK: IW/importwall
    func importwall(_ source: Result<URL, Error>){
        guard let docsurl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let url = docsurl.appendingPathComponent("Wallpapers", isDirectory: true)
        
        // prepare for some bullllllshitttt!
        switch source{
        case .success(let file):
            // boo hoo, do u have access
            let access = file.startAccessingSecurityScopedResource()
            defer { if access{file.stopAccessingSecurityScopedResource()}}
            do{
                
                let name = file.deletingPathExtension().lastPathComponent
                // makes temp dir to extract to
                let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
                defer{ try? FileManager.default.removeItem(at: temp)}
                
                try FileManager.default.unzipItem(at: file, to: temp)
                
                // finds root folder
                let top = try FileManager.default.contentsOfDirectory(at: temp, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
                    .filter {$0.lastPathComponent != "__MACOSX"}
                    .filter {$0.lastPathComponent != ".DS_Store"}
                
                // checks if is mercury (SUPER EVIL HELL) or normal
                if let descdir = top.first(where: {
                    let n = $0.lastPathComponent.lowercased()
                    return n == "descriptors" || n == "descriptor"
                }) {
                    descriptorhelper(url, name, descdir)
                }
                else if let parentDir = top.first(where: { folder in
                    guard let contents = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {return false}
                    return contents.contains {$0.lastPathComponent.lowercased() == "container"}
                }),
                let mpdir = try? FileManager.default.contentsOfDirectory(at: parentDir, includingPropertiesForKeys: nil).first(where: { $0.lastPathComponent.lowercased() == "container" }) {
                    mercuryhelper(url, name, mpdir)
                } else{
                    print("[IW] can't import wallpaper, your wallpaper is most likely misconfigured.")
                }

            } catch{
                print("[IW] can't import wallpaper: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            print("[IW] can't import wallpaper: \(error.localizedDescription)")
        }
        
    }
    
    
    // MARK: MP/mercuryhelper
    func mercuryhelper(_ url: URL, _ name: String, _ containerDir: URL){
        do {
            // find actual MP wallpaper inside all the extra folders
            let enums = FileManager.default.enumerator(at: containerDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            var descdir: URL?
            while let fileURL = enums?.nextObject() as? URL {
                if fileURL.lastPathComponent.lowercased() == "descriptors",
                   fileURL.path.contains("com.apple.MercuryPoster") {
                    descdir = fileURL
                    break
                }
            }
            
            guard let descdir = descdir else {
                print("[MP] can't find mercury descriptors directory.")
                return
            }

            // ignores macos slop
            let walldirs = try FileManager.default.contentsOfDirectory(at: descdir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
                .filter {(try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true}
                .filter {$0.lastPathComponent != "__MACOSX"}
                .filter {$0.lastPathComponent != ".DS_Store"}

            // copies over descriptors under new uuid with _MP suffix
            for folder in walldirs {
                // makes parent
                let fold = url.appendingPathComponent("\(name)__\(UUID().uuidString)_MP", isDirectory: true)
                try FileManager.default.createDirectory(at: fold, withIntermediateDirectories: true)
                 
                // moves content into parent with random UUID wrapper
                let final = fold.appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.moveItem(at: folder, to: final)
                refresh()
                print("[MP] imported \(name)")
            }
        } catch {
            print("[MP] can't import mercury descriptor: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: DE/descriptorhelper
    func descriptorhelper(_ url: URL, _ name: String, _ descdir: URL){
        do{
            // ignores macos slop
            let walldirs = try FileManager.default.contentsOfDirectory(at: descdir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
                .filter {(try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true}
                .filter {$0.lastPathComponent != "__MACOSX"}
                .filter {$0.lastPathComponent != ".DS_Store"}

            // copies over descriptors under new uuid
            for folder in walldirs {
                // makes parent
                let fold = url.appendingPathComponent("\(name)__\(UUID().uuidString)", isDirectory: true)
                try FileManager.default.createDirectory(at: fold, withIntermediateDirectories: true)
                
                // moves content into parent
                let final = fold.appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.moveItem(at: folder, to: final)
                randomizeWPIds(final)
                refresh()
                print("[DE] imported \(name)")
            }
        }catch{
            print("[DE] can't import descriptor: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: LC/list
    func list() -> [URL]{
        guard let docsurl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return []}
        let url = docsurl.appendingPathComponent("Wallpapers", isDirectory: true)
        do{
            // finds multiple walls
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            return contents.filter {$0.hasDirectoryPath}
        } catch{
            print("[LC] can't list wallpapers dir: \(error.localizedDescription)")
            return []
        }
    }
    
    
    // MARK: LC/checkimports
    func checkimports() -> Bool{
        var donen = true
        var donem = true
        for wrapper in list() {
            let inner: [URL]
            do{
                // gets content of wrapper
                inner = try FileManager.default.contentsOfDirectory(
                    at: wrapper,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                ).filter {(try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true}
                .filter {$0.lastPathComponent != "__MACOSX"}
                .filter {$0.lastPathComponent != ".DS_Store"}
                if wrapper.lastPathComponent.hasSuffix("_MP"){
                    // its mercuryposter. FileManager.defaultl
                    donen = mercurycopy(inner)
                } else{
                    donem = normalcopy(inner)
                }
            } catch {
                print("[LC] can't list \(wrapper.lastPathComponent): \(error.localizedDescription)")
                return false
            }
        }
        // make sure both succeed
        if donem && donen == true{
            return true
        } else{return false}
    }
    
    
    // MARK: MP/mercurycopy
    func mercurycopy(_ inner: [URL]) -> Bool{
        _ = wf.getrw(path: wf.containerpath(toget: "com.apple.PosterBoard") + mgr.mpextension)
        let root = URL(fileURLWithPath: wf.containerpath(toget: "com.apple.PosterBoard") + mgr.mpextension, isDirectory: true)
        
        for folder in inner {
            let target = root.appendingPathComponent(folder.lastPathComponent, isDirectory: true)
            do{
                // delete if exists
                if FileManager.default.fileExists(atPath: target.path) {
                    try FileManager.default.removeItem(at: target)
                }
                // copy
                try FileManager.default.copyItem(at: folder, to: target)
                print("[MP] copied mercury \(folder.lastPathComponent) over")
            } catch{
                print("[MP] can't copy mercury: \(error.localizedDescription)")
                return false
            }
        }
        return true
    }
    
    
    // MARK: DE/normalcopy
    func normalcopy(_ inner: [URL]) -> Bool{
        _ = wf.getrw(path: wf.containerpath(toget: "com.apple.PosterBoard") + mgr.pbextension)
        let root = URL(fileURLWithPath: wf.containerpath(toget: "com.apple.PosterBoard") + mgr.pbextension, isDirectory: true)
        for folder in inner {
            let target = root.appendingPathComponent(folder.lastPathComponent, isDirectory: true)
            do{
                // delete if exists
                if FileManager.default.fileExists(atPath: target.path) {
                    try FileManager.default.removeItem(at: target)
                }
                // copy
                try FileManager.default.copyItem(at: folder, to: target)
                print("[DE] copied \(folder.lastPathComponent) over")
            } catch {
                print("[DE] can't copy descriptor: \(error.localizedDescription)")
                return false
            }
        }
        return true
    }
    
    //the following is stolen from lung. thanks!!!
    // MARK: DE/randomizeWPIds
    private func randomizeWPIds(_ descrURL: URL) {
        let id = Int.random(in: 9999...99999)
        var descrFiles: [URL] = []
        if let enumerator = FileManager.default.enumerator(at: descrURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                let fileAtts = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if fileAtts?.isRegularFile ?? false {
                    descrFiles.append(fileURL)
                }
            }
        }
        
        for url in descrFiles {
            switch url.lastPathComponent {
            case "com.apple.posterkit.provider.descriptor.identifier":
                try? String(id).data(using: .utf8)?.write(to: url)
            case "com.apple.posterkit.provider.contents.userInfo":
                setPlistValAndWrite(url, key: "wallpaperRepresentingIdentifier", value: id)
            case "Wallpaper.plist":
                setPlistValAndWrite(url, key: "identifier", value: id)
            default: continue
            }
        }
    }
    
    // MARK: DE/setPlistValAndWrite
    private func setPlistValAndWrite(_ url: URL, key: String, value: Any) {
        do {
            guard let data = FileManager.default.contents(atPath: url.path),
                  var dict = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any] else {
                return
            }
            dict[key] = value
            guard let newData = try? PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0) else {
                return
            }
            try newData.write(to: url)
        } catch {
            print("(pb) failed to update plist: \(error.localizedDescription)")
        }
    }
    // end of stealing from lung
    
    func listimported() -> [imported] {
        guard let docsurl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }
        let url = docsurl.appendingPathComponent("Wallpapers", isDirectory: true)
        do {
            // lists walls
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil,options: [.skipsHiddenFiles])
            return urls.map {imported(url: $0)}
        } catch {
            print("[LW] can't list imported wallpapers: \(error.localizedDescription)")
            return []
        }
    }

    func deleteimported(_ item: imported) {
        do {
            // guess...
            try FileManager.default.removeItem(at: item.url)
        } catch {
            print("[LW] can't delete \(item.url.lastPathComponent): \(error.localizedDescription)")
        }
        refresh()
    }

    func refresh() {
        let list = listimported()
        if Thread.isMainThread {
            imports = list
        } else {
            DispatchQueue.main.async { self.imports = list }
        }
    }
}
// annoying
struct imported: Identifiable {
    let url: URL
    var id: URL{url}
    var names: String {
        let name = url.lastPathComponent
        if let e = name.range(of: "__") {
            return String(name[..<e.lowerBound])
        }
        return name
    }
}

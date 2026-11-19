//
//  FetchWallpapers.swift
//  Flake
//
//  Created by Squair on 2026-11-17.
//

import Foundation
import SwiftUI

// some code here is refrenced from https://github.com/leminlimez/Pocket-Poster/blob/main/Pocket%20Poster/API/CowabungaAPI.swift
public class FetchWallpapers{
    @State public var qf = PosterFuncs()
    func FetchWalls(_ type: String) async -> [wallpapers]{
        let full = "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/refs/heads/main/wallpapers-"+type+".json"
        let res = URLRequest(url: URL(string: full)!)
        
        do{
            let (data, response) = try await URLSession.shared.data(for: res) as! (Data, HTTPURLResponse)
            guard response.statusCode == 200 else{
                print("[FW] can't fetch wallpapers: server responded with code \(response.statusCode)")
                return []
            }
            
            let walls = try JSONDecoder().decode([wallpapers].self, from: data)
            return walls
            
        } catch{
            print("[FW] can't fetch wallpapers: \(error.localizedDescription)")
            return []
        }
    }
    
    @discardableResult
    func DownloadWallpaper(_ url: String, _ name: String? = nil) async -> Bool{
        let wallurl = URL(string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/refs/heads/main/"+url)
        let res = URLRequest(url: wallurl!)

        do{
            let (data, response) = try await URLSession.shared.data(for: res) as! (Data, HTTPURLResponse)
            guard response.statusCode == 200 else{
                print("[FW] can't fetch wallpapers: server responded with code \(response.statusCode)")
                return false
            }

            // makes temp dir so it dont mess anything up
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            defer{try? FileManager.default.removeItem(at: dir)}

            // __ is used for finding walls in pbhandler
            let base = (name ?? wallurl!.deletingPathExtension().lastPathComponent)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: "__", with: "_")
            let dest = dir.appendingPathComponent(base).appendingPathExtension("tendies")
            try data.write(to: dest)
            print("[DW] downloaded \(base)")
            qf.importwall(.success(dest))
            // #stupidestshitever.. qf.refresh doesnt work on its own for some reason :P
            WorseView().qf.refresh()
            return true
        } catch{
            print("[DW] can't download wallpaper: \(error.localizedDescription)")
            return false
        }
    }
    
}

class wallpapers: Identifiable, Codable {
    var name: String
    var description: String?
    var url: String
    var preview: String
    var authors: String?
    init(name: String, description: String?, authors: String?, preview: String, url: String, version: String) {
        self.name = name
        self.description = description
        self.authors = authors
        self.preview = preview
        self.url = url
    }
    func IsGif() -> Bool {
        return preview.hasSuffix(".gif")
    }
}

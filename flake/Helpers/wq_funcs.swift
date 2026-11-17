//
//  wq_funcs.swift
//  flake
//
//  Created by Squair on 2026-11-11.
//

import SwiftUI
import UIKit
import Foundation
import UniformTypeIdentifiers
public class worsefuncs{
    
    // a lot of the stuff here is from https://github.com/jailbreakdotparty/erosion and https://github.com/forcequitOS/worse_query/blob/main/worse_query/ContentView.swift
    @StateObject private var mgr = Man.shared
    // MARK: LP/leakpaths
    
    func leakpaths(_ path: String) -> [String] {
        let baseinode: UInt64 = UInt64(15000)
        var paths: [String] = []
        
        print("[LP] pathleaking \(path)")
        let leakedpaths = pathleak(path, baseinode) ?? []
        print("[LP] got \(leakedpaths.count) paths via pathleak")
        paths = leakedpaths
        
        if leakedpaths.count == 0 {
            print("[LP] no paths found")
        }
        
        return paths
    }
    
    func getgroup() -> String {
        if let task = SecTaskCreateFromSelf(nil), let groups = SecTaskCopyValueForEntitlement(task, "com.apple.security.application-groups" as CFString, nil) {
            return (groups as? [String])?.first ?? "group.xyz.squair.Flake.wq"
        }
        return "group.xyz.squair.Flake.wq"
    }
    
    // MARK: GR/getrw
    func getrw(path: String) -> (Bool, Int64, String) {
        let res: Int64
        if path.count < 1 {
            return (false, 0, "")
        }
        if path.contains("/var/mobile/Containers/Shared/AppGroup") && ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 26 {
            res = worse_query(path, getgroup(), true, false)
        } else {
            res = worse_query(path, getgroup(), false, false)
        }
        var errorString: String?
        switch res {
        case -1: errorString = "failed to access group"
        case -2: errorString = "failed to resolve functions"
        case -3: errorString = "failed to create query"
        case -4: errorString = "failed to create symlink"
        case -5: errorString = "query rejected"
        case -6: errorString = "kernel refused extension issue"
        case -255: errorString = "target doesn't exist"
        default: errorString = nil
        }
        let isActuallyReadable = FileManager.default.isReadableFile(atPath: path)
        let isActuallyWritable = FileManager.default.isWritableFile(atPath: path)
        if !isActuallyWritable || !isActuallyReadable {
            errorString = "can't r/w"
        }
        
        if let errorString {
            print("[GR] can't access \(path)\n" + "result: \(res), \(errorString)")
            return (false, res, errorString)
        } else {
            return (true, res, "succeeded")
        }
    }
    
    func release(_ handle: Int64) {
        return worse_query_release(handle)
    }
    
    // MARK: TR/convertid
    func convertid(_ url: URL) -> String? {
        let handle = getrw(path: url.path).1
        
        if handle > 0 {
            var buf = [CChar](repeating: 0, count: 512)
            let len = getxattr(url.path, "com.apple.containermanager.identifier", &buf, 511, 0, 0)
            
            if len < 0 {
                print("[TR] can't read xattr: \(String(cString: strerror(errno))) (error \(errno))")
                return nil
            }
            let bid = String(cString: buf)
            release(handle)
            if !bid.isEmpty {
                return bid
            }
        }
        return nil
    }
        
    // MARK: AP/containerpath
    func containerpath(at containerURL: URL=Man().apppath, toget match: String, hash: Bool = false, skipcheck: Bool = false) -> String {
        if !skipcheck{
            let e = UserDefaults.standard.value(forKey: match) as? String ?? "err"
            if e != "err"{
                return UserDefaults.standard.value(forKey: match) as! String
            }
        }
        
        // sends app group to pathleak
        let containers = leakpaths(containerURL.path)
        // skidded from erosion, thanks lung!!
        // recursively checks leaked to match uuids with app group
        for path in containers {
            let url = URL(fileURLWithPath: path)
            if let appName = convertid(url) {
                if appName == match {
                    if hash {
                        return url.lastPathComponent
                    }
                    save(match, url.path)
                    print("[AP] got \(appName), \(url.path)")
                    return url.path
                }
            }
        }
        print("[AP] can't get container for \(match). containers: \(containerURL.path)")
        return ""
    }
    
    // MARK: RE/releaseExtension
    func releaseExtension(_ handle: Int64) {
        if handle < 0 {
            print("[RE] sandbox extension hasn't been consumed!")
            return
        }
        worse_query_release(handle)
        print("[RE] released sandbox extension!")
    }
    
    // not a w_q func but i DO NOT care dude
    func save(_ tostore: String, _ val: String){
        UserDefaults.standard.set(val, forKey: tostore)
        mgr.pbpath = val
        print("[SV] saved pb hash")
    }
    
}

#Preview {
    WorseView().preferredColorScheme(.dark)
}

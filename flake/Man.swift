//
//  Man.swift
//  Erosion
//
//  Created by lunginspector on 8/24/26.
//

import Foundation
import Combine
import UniformTypeIdentifiers

final class Man: ObservableObject {
    static let shared = Man()
    @Published var logOutput = ""
    @Published var pbpath = ""
    @Published var apppath = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application")
    @Published var pbextension = "/Library/Application Support/PRBPosterExtensionDataStore/61/Extensions/com.apple.WallpaperKit.CollectionsPoster/descriptors"
    @Published var mpextension = "/Library/Application Support/PRBPosterExtensionDataStore/61/Extensions/com.apple.MercuryPoster/descriptors"
}

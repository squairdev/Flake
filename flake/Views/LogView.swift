//
//  LogView.swift
//  dirtyZero
//
//  Created by lunginspector on 4/17/26.
//

import SwiftUI

struct LogView: View {
    @StateObject private var mgr = Man.shared
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    Text(mgr.logOutput)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .multilineTextAlignment(.leading)
                    Spacer()
                        .id(0)
                }
                .padding(3)
                .padding(.top, 10)
                .padding(.horizontal)
                
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                UIPasteboard.general.string = mgr.logOutput
            } label: {
                // resorted to hstack bc Label() was making weird spacing in settings
                HStack{
                    Image(systemName: "clipboard.fill")
                    Text("Copy")
                }
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .padding(7)
                    .glassEffect(.regular.tint(.purple).interactive())
                    .padding(10)
            }
        }
    }
    public func presentShareSheet(with url: URL) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           var topController = window.rootViewController {
            
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            topController.present(activityViewController, animated: true)
        }
    }
}
func print(_ e: String){
    Man.shared.logOutput+="\(e)\n"
}

#Preview {
    LogView().modifier(TerminalPlatter()).preferredColorScheme(.dark)
}

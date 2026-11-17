//
//  CreditsView.swift
//  flake
//
//  Created by Squair on 2026-11-16.
//

import Foundation
import SwiftUI

struct CreditsView: View {
    let name: String
    let url: String
    let desc: String
    private var pfp: String {url + ".png"}
    var body: some View {
        //mostly skidded from root
        HStack(alignment: .top) {
            AsyncImage(url: URL(string: pfp)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)

                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .onTapGesture {
            UIApplication.shared.open(URL(string: url)!)
        }
    }
}

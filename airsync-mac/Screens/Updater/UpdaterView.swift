//
//  UpdaterView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-30.
//

import SwiftUI

extension Bundle {
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }

    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}

struct ContentView: View {
    var body: some View {
        Text("\(Bundle.main.buildNumber)")
            .padding()
            .frame(width: 300, height: 200)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

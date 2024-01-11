//
//  ContentView.swift
//  AppLockerView
//
//  Created by Gagan Vishal  on 2024/01/11.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LockView(lockType: .both, lockPin: "1234", isEnabled: true, isLockEnabledWhenMoveToBackground: true) {
            VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
                Image(systemName: "globe")
                    .font(.largeTitle)
                Text("App Lock Example")
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            }
        }
}
}

#Preview {
    ContentView()
}

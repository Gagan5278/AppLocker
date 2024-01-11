# App Locker
### An example is written in SwiftUI to demonstrate how to build an app locker that supports Pin and/or Face recognition.

### Feature:
1. Support Pin Lock
2. Wrong pin entry animation
3. Face recognition for app lock.
4. Face recognition and Pin lock support (both)
5. Enable/Disable the app lock feature when the app moves into the background.

### How to Use: 
1. Drag and drop *Lock* folder (LockType.swift & LockView.swift files) in your project.
2. Add 'Privacy - Face ID Usage Description' in the app's plist file.

### Example code:
```
   struct ContentView: View {
    var body: some View {
        LockView(lockType: .both, lockPin: "1234", isEnabled: true, isLockEnabledWhenMoveToBackground: true) {
            VStack(alignment: .center) {
                Image(systemName: "globe")
                    .font(.system(size: 56).bold())
                Text("App Lock Example")
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            }
        }
    }
}
```




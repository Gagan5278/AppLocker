//
//  LockView.swift
//  AppLockerView
//
//  Created by Gagan Vishal  on 2024/01/11.
//

import SwiftUI
import LocalAuthentication

struct LockView<Content: View>: View {
    let lockType: LockType
    let lockPin: String
    let isEnabled: Bool
    let isLockEnabledWhenMoveToBackground: Bool
    
    var forgotPinCallback: (() -> Void)?
    
    @State var pinNumber: String = ""
    @State private var shouldAnimateOnWrongEntry: Bool = false
    @ViewBuilder var content: Content
    
    @State private var isUnlocked: Bool = false
    @State private var isNoBiometricEnabled: Bool = false
    var numberOfKeys: Int = 4
    
    @State private var authContext = LAContext()
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isFaceIDDeclinedByUser: Bool = false
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            content
                .frame(width: size.width, height: size.height)
            if isEnabled && !isUnlocked {
                ZStack {
                    Rectangle()
                        .fill(.black)
                        .ignoresSafeArea()
                    if lockType == .biometric || (lockType == .both && !isNoBiometricEnabled) {
                        if isNoBiometricEnabled {
                            Text(Constants.biometricDescription)
                        } else {
                            VStack(spacing: Constants.padding) {
                                VStack(alignment: .center, spacing: Constants.padding) {
                                    Image(systemName: Constants.lockImageName)
                                        .font(.largeTitle)
                                    Text(Constants.tapToUnlock)
                                        .font(.title2)
                                }
                                .frame(width: Constants.lockViewWidth, height: Constants.lockViewHeight)
                                .padding()
                                .background(.ultraThinMaterial, in: .rect(cornerRadius: Constants.padding))
                                .contentShape(.rect)
                                .onTapGesture {
                                    unlockView()
                                }
                                if lockType == .both {
                                    pleaseEnterPinView
                                }
                            }
                        }
                    } else {
                        createNumberPad()
                    }
                }
                .environment(\.colorScheme, .dark)
                .transition(.offset(y:size.height + Constants.padding*10))
            }
        }
        .onChange(of: isEnabled, initial: false) { oldValue, newValue in
            if newValue {
                unlockView()
            }
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue != .active && isLockEnabledWhenMoveToBackground {
                isUnlocked = false
                pinNumber = ""
            }
            
            if newValue == .active && !isUnlocked && isEnabled && !isFaceIDDeclinedByUser {
                unlockView()
            }
            
            if newValue == .background || newValue == .inactive {
                isUnlocked = false
            }
        }
    }
    
    private func unlockView() {
        Task {
            if isBiometricAuthAvailable && lockType != .numberPad{
                do {
                    let result = try await authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock")
                        print(result)
                        withAnimation(.snappy, completionCriteria: .logicallyComplete) {
                            isUnlocked = true
                        } completion: {
                            pinNumber = ""
                        }
                        print("UNLOCKED")
                    
                } catch {
                    isFaceIDDeclinedByUser = true
                }
            }
            
            isNoBiometricEnabled = !isBiometricAuthAvailable
        }
    }
    
    private var isBiometricAuthAvailable: Bool {
        authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}

// MARK: - Key lock UI
private extension LockView {
    @ViewBuilder
    func createNumberPad() -> some View {
        VStack(alignment: .center, spacing: Constants.padding) {
            Text(Constants.pinViewTitle)
                .font(.headline)
                .hSpacing()
                .overlay(alignment: .leading) {
                    if lockType == .both && isNoBiometricEnabled {
                        backArraowButton
                    }
                }
            keyPinBoxView
                .keyframeAnimator(initialValue: CGFloat.zero, trigger: shouldAnimateOnWrongEntry, content: { content, value in
                    content
                        .offset(x: value)
                }, keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(30, duration: 0.07)
                        CubicKeyframe(-30, duration: 0.06)
                        CubicKeyframe(20, duration: 0.05)
                        CubicKeyframe(-20, duration: 0.03)
                        CubicKeyframe(-20, duration: 0.02)
                        CubicKeyframe(0, duration: 0.01)
                    }
                })
                .padding(.top, 40)
                .frame(maxHeight: .infinity)
                .overlay(alignment: .trailing) {
                    forgotPinButton
                        .offset(y: 70)
                }
            GeometryReader {_ in
                keybaordUIView
            }
            Spacer(minLength: 40)
        }
        .padding()
        .environment(\.colorScheme, .dark)
        .onChange(of: pinNumber) {
            pinValidation()
        }
    }
    
    func addPin(_ number: String) {
        guard pinNumber.count < numberOfKeys else { return }
        pinNumber.append(number)
    }
    
    func removePin() {
        guard pinNumber.count > 0 else { return }
        pinNumber.removeLast()
    }
    
    func pinValidation() {
        guard pinNumber.count == numberOfKeys else { return }
        if pinNumber == lockPin {
            withAnimation(.snappy, completionCriteria: .logicallyComplete) {
                isUnlocked = true
            } completion: {
                pinNumber.removeAll()
            }
            print("UNLOCKED.. add ur stuffs")
        } else {
            print("Wrong Pin.. add ur stuffs")
            pinNumber.removeAll()
            shouldAnimateOnWrongEntry.toggle()
        }
    }
    
    var keyPinBoxView: some View {
        HStack {
            ForEach(0..<numberOfKeys, id: \.self) { index in
                RoundedRectangle(cornerRadius: Constants.padding)
                    .frame(width: Constants.pinBoxWidth)
                    .frame(height: Constants.pinBoxHeight)
                    .overlay {
                        if pinNumber.count > index {
                            let charIndex = pinNumber.index(pinNumber.startIndex, offsetBy: index)
                            let number = String(pinNumber[charIndex])
                            Text(number)
                                .font(.title)
                                .foregroundStyle(.black)
                        }
                    }
            }
        }
    }
    
    var forgotPinButton: some View {
        Button(action: {
            forgotPinCallback?()
        }, label: {
            Text(Constants.forgotPinTitle)
                .font(.callout.bold())
                .foregroundStyle(.white)
        })
    }
    
    /// KEYBOARD Keys UI
    var keybaordUIView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 3), content: {
            /// 1 to 9 Digits
            ForEach(1...9,id: \.self) { value in
                Button(action: {
                    addPin("\(value)")
                }, label: {
                    Text("\(value)")
                        .foregroundStyle(.white)
                        .font(.title)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Constants.keyboardButtonVerticalPadding)
                })
            }
            deleteButton
            zeroButton
        })
    }
    
    var deleteButton: some View {
        Button(action: {
            removePin()
        }, label: {
            Image(systemName: Constants.deleteBackwardImageName)
                .foregroundStyle(.white)
                .font(.title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.deleteBackwardImageVerticalPadding)
        })
    }
    
    var zeroButton: some View {
        Button(action: {
            addPin("0")
        }, label: {
            Text("0")
                .foregroundStyle(.white)
                .font(.title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
        })
    }
    
    var backArraowButton: some View {
        Button {
            withAnimation {
                isNoBiometricEnabled = false
            }
        } label: {
            Image(systemName: Constants.arrowLeftImageName)
                .font(.title2)
                .foregroundStyle(.white)
        }
    }
    
    var pleaseEnterPinView: some View {
        Text(Constants.pleaseEnterPin)
            .font(.title2)
            .padding(.vertical, Constants.padding)
            .padding(.horizontal, Constants.padding*2)
            .background(.ultraThinMaterial, in: Capsule())
            .onTapGesture {
                isNoBiometricEnabled = true
            }
    }
}

#Preview {
    ContentView()
}

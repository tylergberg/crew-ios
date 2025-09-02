//
//  IndexView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-29.
//

import SwiftUI

struct ScaleOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.05 : 1.0)
            .offset(y: configuration.isPressed ? -4 : 0)
            .shadow(color: .black, radius: 0, x: configuration.isPressed ? 6 : 3, y: configuration.isPressed ? 6 : 3)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct IndexView: View {
    @State private var isLoading = true
    @State private var rotatingTextIndex = 0
    @State private var animateBounce = false
    @State private var splashCheck: Bool = false
    let rotatingWords = ["BACHELOR", "BACHELORETTE"]
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            if isLoading {
                SplashView(isChecking: $splashCheck)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isLoading = false
                        }
                    }
            } else {
                ZStack {
                    // Background
                    Color(hex: "#9BC8EE").ignoresSafeArea()

                    VStack(spacing: 24) {
                        // Headline
                        VStack(spacing: 4) {
                            Text("THE \(rotatingWords[rotatingTextIndex])")
                                .font(.system(.title, design: .serif).weight(.bold))
                                .foregroundColor(Color(hex: "#401B17"))
                                .multilineTextAlignment(.center)
                            
                            Text("PARTY STARTS HERE.")
                                .font(.system(.title, design: .serif).weight(.bold))
                                .foregroundColor(Color(hex: "#401B17"))
                                .multilineTextAlignment(.center)
                        }
                        .onReceive(timer) { _ in
                            rotatingTextIndex = (rotatingTextIndex + 1) % rotatingWords.count
                        }

                        // Logo
                        Image("finalsendLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)

                        // Buttons
                        VStack(spacing: 16) {
                            NavigationLink(destination: SignupView()) {
                                Text("JOIN NOW")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "#401B17"))
                                    .frame(width: 280, height: 56)
                                    .background(Color(hex: "#F9C94E"))
                                    .cornerRadius(20)
                                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                            }
                            .buttonStyle(ScaleOnPressButtonStyle())

                            NavigationLink(destination: LoginView()) {
                                Text("LOGIN")
                                    .font(.system(size: 18, weight: .semibold, design: .serif))
                                    .foregroundColor(Color(hex: "#401B17"))
                                    .frame(width: 280, height: 56)
                                    .background(Color(hex: "#E9C2DC"))
                                    .cornerRadius(20)
                                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                            }
                            .buttonStyle(ScaleOnPressButtonStyle())
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    IndexView()
}

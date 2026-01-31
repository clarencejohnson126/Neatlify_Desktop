//
//  OnboardingView.swift
//  Neatlify
//
//  First-run onboarding experience
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userSession: UserSession
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Neatlify",
            description: "Organize your files with AI in seconds",
            icon: "sparkles",
            color: .blue
        ),
        OnboardingPage(
            title: "Smart Categorization",
            description: "Tell Neatlify how you want to organize, and it will analyze your files using Claude AI to categorize them perfectly.",
            icon: "brain.head.profile",
            color: .purple
        ),
        OnboardingPage(
            title: "Safe & Local",
            description: "Your files stay on your Mac. We only send file content to Claude for analysis, never store anything on our servers.",
            icon: "lock.shield",
            color: .green
        ),
        OnboardingPage(
            title: "Try It Free",
            description: "Get 1 free cleanup (up to 100 files). Then subscribe for $10/month for 1,000 files, or pay as you go.",
            icon: "gift",
            color: .orange
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Pages
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }

            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)

            // Action button
            Button(action: completeOnboarding) {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding()
        }
        .frame(width: 600, height: 500)
    }

    private func completeOnboarding() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            userSession.hasCompletedOnboarding = true
            userSession.save()
            isPresented = false
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.color)

            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 400)

            Spacer()
        }
        .padding()
    }
}

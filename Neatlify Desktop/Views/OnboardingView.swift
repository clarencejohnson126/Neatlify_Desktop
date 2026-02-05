//
//  OnboardingView.swift
//  Neatlify
//
//  First-run onboarding experience - Matching landing page design
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
            color: .neatlifyGreen,
            badgeText: nil
        ),
        OnboardingPage(
            title: "Smart Categorization",
            description: "Tell Neatlify how you want to organize, and it will analyze your files using Claude AI to categorize them perfectly.",
            icon: "brain.head.profile",
            color: .neatlifyYellow,
            badgeText: "AI-Powered"
        ),
        OnboardingPage(
            title: "Safe & Local",
            description: "Your files stay on your Mac. We only send file names to Claude for analysis, never the actual file content.",
            icon: "lock.shield",
            color: .neatlifyGreen,
            badgeText: "Privacy First"
        )
    ]

    var body: some View {
        ZStack {
            Color.neatlifyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }

                // Page indicator dots with sketch style
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.neatlifyGreen : Color.neatlifyDark.opacity(0.2))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.neatlifyDark, lineWidth: index == currentPage ? 2 : 1)
                            )
                    }
                }
                .padding(.top, 8)

                // Action button with sketch style
                Button(action: completeOnboarding) {
                    HStack {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            .font(.headline)
                            .fontWeight(.black)
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .frame(maxWidth: 280)
                    .padding(.vertical, 16)
                    .background(Color.neatlifyGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.neatlifyDark, lineWidth: 3)
                    )
                    .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 4, y: 4)
                }
                .buttonStyle(.plain)
                .padding()
                .padding(.bottom, 16)
            }
        }
        .frame(width: 600, height: 520)
    }

    private func completeOnboarding() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
    let badgeText: String?
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with sketch style
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(page.color.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.neatlifyDark, lineWidth: 3)
                    )
                    .shadow(color: Color.neatlifyDark.opacity(0.15), radius: 0, x: 4, y: 4)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(page.color)
            }

            // Badge if present
            if let badge = page.badgeText {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(page.color)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )
            }

            Text(page.title)
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.neatlifyDark)

            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.neatlifyDark.opacity(0.7))
                .frame(maxWidth: 420)
                .lineSpacing(4)

            Spacer()
        }
        .padding(24)
    }
}

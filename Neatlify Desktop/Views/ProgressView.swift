//
//  ProgressView.swift
//  Neatlify
//
//  Organization progress tracking view - Matching landing page design
//

import SwiftUI

struct ProgressOverlayView: View {
    @ObservedObject var viewModel: OrganizationViewModel

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Progress indicator
                if viewModel.currentStep == .completed {
                    ZStack {
                        Circle()
                            .fill(Color.neatlifyGreen.opacity(0.2))
                            .frame(width: 100, height: 100)
                        Circle()
                            .fill(Color.neatlifyGreen)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.neatlifyDark, lineWidth: 3)
                            )
                            .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 4, y: 4)
                        Image(systemName: "checkmark")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.neatlifyYellow.opacity(0.2))
                            .frame(width: 100, height: 100)
                        Circle()
                            .fill(Color.neatlifyYellow)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.neatlifyDark, lineWidth: 3)
                            )
                        Image(systemName: "sparkles")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.neatlifyDark)
                            .rotationEffect(.degrees(viewModel.progress * 360))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: viewModel.progress)
                    }
                }

                // Status message
                Text(viewModel.statusMessage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.neatlifyDark)

                // Progress bar (for file organization)
                if viewModel.currentStep == .organizingFiles || viewModel.currentStep == .analyzingFiles {
                    VStack(spacing: 10) {
                        // Custom progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.neatlifyDark.opacity(0.1))
                                .frame(width: 280, height: 16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.neatlifyDark, lineWidth: 2)
                                )

                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.neatlifyGreen)
                                .frame(width: max(8, 276 * viewModel.progress), height: 12)
                                .padding(.horizontal, 2)
                        }

                        if viewModel.totalFiles > 0 {
                            HStack(spacing: 4) {
                                Text("\(viewModel.processedFiles)")
                                    .fontWeight(.black)
                                    .foregroundColor(.neatlifyGreen)
                                Text("/")
                                    .foregroundColor(.neatlifyDark.opacity(0.4))
                                Text("\(viewModel.totalFiles)")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.neatlifyDark.opacity(0.6))
                                Text("files")
                                    .foregroundColor(.neatlifyDark.opacity(0.5))
                            }
                            .font(.subheadline)
                        }
                    }
                }

                // Action buttons
                if viewModel.currentStep == .completed {
                    HStack(spacing: 16) {
                        Button(action: {
                            if let url = viewModel.organizationPlan?.sourceFolder {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                            }
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("View Folder")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.neatlifyDark)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            viewModel.reset()
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Done")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.neatlifyGreen)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )
                            .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 3, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                } else if viewModel.currentStep != .awaitingConfirmation {
                    Button(action: {
                        viewModel.cancelOrganization()
                    }) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyDark.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(40)
            .frame(maxWidth: 400)
            .background(Color.neatlifyBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.neatlifyDark, lineWidth: 3)
            )
            .shadow(color: Color.neatlifyDark.opacity(0.3), radius: 0, x: 6, y: 6)
        }
    }
}

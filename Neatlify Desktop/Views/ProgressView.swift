//
//  ProgressView.swift
//  Neatlify
//
//  Organization progress tracking view
//

import SwiftUI

struct ProgressOverlayView: View {
    @ObservedObject var viewModel: OrganizationViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            if viewModel.currentStep == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(.circular)
            }

            // Status message
            Text(viewModel.statusMessage)
                .font(.headline)

            // Progress bar (for file organization)
            if viewModel.currentStep == .organizingFiles || viewModel.currentStep == .analyzingFiles {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(.linear)
                        .frame(width: 300)

                    if viewModel.totalFiles > 0 {
                        Text("\(viewModel.processedFiles) / \(viewModel.totalFiles) files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Action buttons
            if viewModel.currentStep == .completed {
                HStack(spacing: 16) {
                    Button("View Folder") {
                        if let url = viewModel.organizationPlan?.sourceFolder {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                        }
                    }

                    Button("Done") {
                        viewModel.reset()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.currentStep != .awaitingConfirmation {
                Button("Cancel") {
                    viewModel.cancelOrganization()
                }
            }
        }
        .padding(32)
        .frame(maxWidth: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

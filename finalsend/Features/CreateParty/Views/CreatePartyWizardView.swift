import SwiftUI

struct CreatePartyWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject var partyManager: PartyManager
    @StateObject var viewModel: CreatePartyViewModel
    @State private var showCancelConfirm = false
    
    init() {
        // Initialize with a temporary PartyManager, will be replaced by environment object
        self._viewModel = StateObject(wrappedValue: CreatePartyViewModel(partyManager: PartyManager()))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background - using dashboard's blue background
                Color.neutralBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header - always at the top
                    HStack {
                        Button(action: { 
                            showCancelConfirm = true 
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.titleDark)
                        }
                        
                        Spacer()
                        
                        Color.clear.frame(width: 44) // balance
                    }
                    .padding(.horizontal, Spacing.screenH)
                    .padding(.top, 0) // Position at absolute top
                    .padding(.bottom, 8)
                    .frame(height: 44 + 8) // Fixed height without safe area
                    
                    // Main Content - scrollable area with dashboard styling
                    ScrollView {
                            VStack(spacing: Spacing.cardGap) {
                                Group {
                                    switch viewModel.step {
                                    case .type:
                                        StepPartyTypeView(viewModel: viewModel)
                                    case .name:
                                        StepPartyNameView(viewModel: viewModel)
                                    case .dates:
                                        StepPartyDatesView(viewModel: viewModel)
                                    case .location:
                                        StepPartyLocationView(viewModel: viewModel)
                                    case .vibe:
                                        StepPartyVibeView(viewModel: viewModel)
                                    case .cover:
                                        StepCoverPhotoView(viewModel: viewModel)
                                    case .review:
                                        StepReviewCreateView(viewModel: viewModel)
                                    }
                                }
                                .padding(.horizontal, Spacing.cardPadH)
                                .padding(.vertical, Spacing.cardPadV)
                                .background(Color.white)
                                .cornerRadius(Radius.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.card)
                                        .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, Spacing.screenH)
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 120) // More space for footer and safe area
                        }
                    
                    // Footer - fixed at bottom
                    WizardFooterBar(
                        stepIndex: viewModel.stepIndex,
                        totalSteps: viewModel.totalSteps,
                        primaryTitle: viewModel.step == .review ? (viewModel.isSubmitting ? "Creating..." : "Create") : "Continue",
                        primaryEnabled: (viewModel.step == .review || viewModel.isCurrentStepValid()) && !viewModel.isSubmitting && !viewModel.partyCreatedSuccessfully,
                        showBack: viewModel.step != .type && !viewModel.isSubmitting,
                        showSkip: (viewModel.step == .dates || viewModel.step == .location || viewModel.step == .vibe || viewModel.step == .cover) && !viewModel.isSubmitting,
                        onBack: { viewModel.back() },
                        onSkip: { viewModel.next() },
                        onPrimary: {
                            if viewModel.step == .review {
                                Task { 
                                    await viewModel.createParty()
                                }
                            } else {
                                viewModel.next()
                            }
                        }
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("Discard this setup?", isPresented: $showCancelConfirm) {
            Button("Discard", role: .destructive) { 
                dismiss() 
            }
            Button("Keep editing", role: .cancel) { }
        }
        .onAppear {
            // Update the viewModel's partyManager to use the environment object
            viewModel.updatePartyManager(partyManager)
            // Update the viewModel's appNavigator to use the environment object
            viewModel.updateAppNavigator(appNavigator)
            // Reset the party creation flag when the wizard appears
            partyManager.partyCreatedSuccessfully = false
        }
        .onChange(of: viewModel.showSuccessToast) { showToast in
            if showToast {
                // Dismiss the create party view
                dismiss()
            }
        }
    }
}

#Preview {
    CreatePartyWizardView()
        .environmentObject(PartyManager())
}

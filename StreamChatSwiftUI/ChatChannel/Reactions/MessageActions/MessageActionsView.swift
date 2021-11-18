//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// View for the message actions.
public struct MessageActionsView: View {
    @Injected(\.colors) var colors
    
    @StateObject var viewModel: MessageActionsViewModel
    
    public init(messageActions: [MessageAction]) {
        _viewModel = StateObject(
            wrappedValue: ViewModelsFactory
                .makeMessageActionsViewModel(messageActions: messageActions)
        )
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.messageActions) { action in
                VStack(spacing: 0) {
                    Button {
                        if action.confirmationPopup != nil {
                            viewModel.alertAction = action
                        } else {
                            action.action()
                        }
                    } label: {
                        ActionItemView(
                            title: action.title,
                            iconName: action.iconName,
                            isDestructive: action.isDestructive,
                            boldTitle: false
                        )
                    }
                    
                    Divider()
                }
                .padding(.horizontal)
            }
        }
        .background(Color(colors.background8))
        .roundWithBorder(cornerRadius: 12)
        .alert(isPresented: $viewModel.alertShown) {
            let title = viewModel.alertAction?.confirmationPopup?.title ?? ""
            let message = viewModel.alertAction?.confirmationPopup?.message ?? ""
            let buttonTitle = viewModel.alertAction?.confirmationPopup?.buttonTitle ?? ""
            
            return Alert(
                title: Text(title),
                message: Text(message),
                primaryButton: .destructive(Text(buttonTitle)) {
                    viewModel.alertAction?.action()
                },
                secondaryButton: .cancel()
            )
        }
    }
}
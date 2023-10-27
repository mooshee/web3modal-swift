import SwiftUI
import Web3ModalUI

struct AccountView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var blockchainApiInteractor: BlockchainAPIInteractor
    @EnvironmentObject var signInteractor: SignInteractor
    @EnvironmentObject var store: Store
    
    @Binding var isModalShown: Bool
    
    var addressFormatted: String? {
        guard let address = store.session?.accounts.first?.address else {
            return nil
        }
        
        return String(address.prefix(4)) + "..." + String(address.suffix(4))
    }
    
    var selectedChain: Chain {
        return store.selectedChain ?? ChainsPresets.ethChains.first!
    }
    
    var body: some View {
        VStack(spacing: 0) {
            avatar()
            
            Spacer()
                .frame(height: Spacing.xl)
            
            HStack {
                (store.identity?.name ?? addressFormatted).map {
                    Text($0)
                        .font(.title600)
                        .foregroundColor(.Foreground100)
                }
                
                Button {
                    UIPasteboard.general.string = store.session?.accounts.first?.address
                    store.toast = .init(style: .info, message: "Address copied")
                } label: {
                    Image.LargeCopy
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.Foreground250)
                }
            }
            
            Spacer()
                .frame(height: Spacing.xxxxs)
            
            if store.balance != nil {
                let balance = store.balance?.roundedDecimal(to: 4, mode: .down) ?? 0
                    
                Text(balance == 0 ? "0 \(selectedChain.token.symbol)" : "\(balance, specifier: "%.4f") \(selectedChain.token.symbol)")
                    .font(.paragraph500)
                    .foregroundColor(.Foreground200)
            }
            
            Spacer()
                .frame(height: Spacing.s)
            
            Button {
                guard let chain = store.selectedChain else { return }
                
                router.openURL(URL(string: chain.blockExplorerUrl)!)
            } label: {
                Text("Block Explorer")
            }
            .buttonStyle(W3MChipButtonStyle(
                variant: .transparent,
                size: .s,
                leadingImage: {
                    Image.Compass
                        .resizable()
                },
                trailingImage: {
                    Image.ExternalLink
                        .resizable()
                }
            ))
            
            Spacer()
                .frame(height: Spacing.xl)

            Button {
                router.setRoute(Router.NetworkSwitchSubpage.selectChain)
            } label: {
                Text(selectedChain.chainName)
            }
            .buttonStyle(W3MListSelectStyle(imageContent: { _ in
                Image(
                    uiImage: store.chainImages[selectedChain.imageId] ?? UIImage()
                )
                .resizable()
                .clipShape(Circle())
            }))
            
            Spacer()
                .frame(height: Spacing.xs)
            
            Button {
                disconnect()
            } label: {
                Text("Disconnect")
            }
            .buttonStyle(W3MListSelectStyle(imageContent: { _ in
                Image.Disconnect
                    .resizable()
                    .frame(width: 22, height: 22)
            }))
            
            Spacer()
                .frame(height: Spacing.m)
        }
        .padding(.horizontal)
        .padding(.top, 40)
        .padding(.bottom)
        .onAppear {
            Task {
                do {
                    try await blockchainApiInteractor.getBalance()
                } catch {
                    store.toast = .init(style: .error, message: error.localizedDescription)
                }
            }
            
            guard store.identity == nil else {
                return
            }
            
            Task {
                do {
                    try await blockchainApiInteractor.getIdentity()
                } catch {
                    store.toast = .init(style: .error, message: error.localizedDescription)
                }
            }
        }
        .toastView(toast: $store.toast)
        .frame(maxWidth: .infinity)
        .background(Color.Background125)
        .overlay(closeButton().padding().foregroundColor(.Foreground100), alignment: .topTrailing)
        .cornerRadius(30, corners: [.topLeft, .topRight])
    }
    
    @ViewBuilder
    func avatar() -> some View {
        if let avatarUrlString = store.identity?.avatar, let url = URL(string: avatarUrlString) {
            AsyncImage(url: url)
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().stroke(.GrayGlass010, lineWidth: 8))
        } else if let address = store.session?.accounts.first?.address {
            W3MAvatarGradient(address: address)
                .frame(width: 64, height: 64)
                .overlay(Circle().stroke(.GrayGlass010, lineWidth: 8))
        }
    }
    
    func disconnect() {
        Task {
            do {
                router.setRoute(Router.ConnectingSubpage.connectWallet)
                try await signInteractor.disconnect()
            } catch {
                store.toast = .init(style: .error, message: error.localizedDescription)
            }
        }
    }
    
    private func closeButton() -> some View {
        Button {
            withAnimation {
                $isModalShown.wrappedValue = false
            }
        } label: {
            Image.LargeClose
        }
    }
}

extension Double {
    func roundedDecimal(to scale: Int = 0, mode: NSDecimalNumber.RoundingMode = .plain) -> Double {
        var decimalValue = Decimal(self)
        var result = Decimal()
        NSDecimalRound(&result, &decimalValue, scale, mode)
        return Double(truncating: result as NSNumber)
    }
}

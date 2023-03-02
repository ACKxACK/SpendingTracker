//
//  MainView.swift
//  SpendingTracker
//
//  Created by Ali Can Kayaaslan on 1.02.2023.
//

import SwiftUI

struct MainView: View {
    
    @State private var shouldPresentAddCardForm = false
    
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.timestamp, ascending: false)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State private var cardSelectionIndex = 0
    
    @State private var selectedCardHash = -1
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                if !cards.isEmpty {
                    TabView(selection: $selectedCardHash) {
                        ForEach(cards) { card in
                            CreditCardView(card: card)
                                .padding(.bottom, 50)
                                .tag(card.hash)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 280)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .onAppear {
                        self.selectedCardHash = cards.first?.hash ?? -1
                    }
                    
                    if let firstIndex = cards.firstIndex(where: {$0.hash == selectedCardHash}) {
                        let card = self.cards[firstIndex]
                        TransactionsListView(card: card)
                    }
                    
                } else {
                    emptyPromptMessage
                }
                
                Spacer()
                    .fullScreenCover(isPresented: $shouldPresentAddCardForm) {
                        AddCardForm(card: nil) { card in
                            self.selectedCardHash = card.hash
                        }
                    }
            }
            .navigationTitle("Credit Cards")
            .navigationBarItems(leading: HStack {
                addItemButton
                deleteAllButton
            } , trailing: addCardButton)
        }
    }
    
    private var emptyPromptMessage: some View {
        VStack {
            Text("You currently have no cards in the system.")
                .padding(.horizontal, 48)
                .padding(.vertical)
                .multilineTextAlignment(.center)
            Button {
                shouldPresentAddCardForm.toggle()
            } label: {
                Text("+ Add Your First Card")
                    .foregroundColor(Color(.systemBackground))
            }
            .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
            .background(Color(.label))
            .cornerRadius(5)

        }.font(.system(size: 20, weight: .semibold))
    }
    
    private var deleteAllButton: some View {
        Button {
            cards.forEach { card in
                viewContext.delete(card)
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error!")
            }
            
        } label: {
            Text("Delete All")
        }

    }
    
    var addItemButton: some View {
        Button {
            withAnimation {
                let viewContext = PersistenceController.shared.container.viewContext
                let card = Card(context: viewContext)
                card.timestamp = Date()
                
                do {
                    try viewContext.save()
                } catch {
//                    let nsError = error as NSError
//                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
        } label: {
            Text("Add Item")
        }

    }
    
    struct CreditCardView: View {
        
        let card: Card
        
        @State private var shouldShowActionSheet = false
        @State private var shouldEditForm = false
        
        @State var refreshId = UUID()
        
        private func handleDelete() {
            let viewContext = PersistenceController.shared.container.viewContext
            
            viewContext.delete(card)
            
            do {
                try viewContext.save()
            } catch {
                // error handling
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack {
                    Text(card.name ?? "")
                        .font(.system(size: 24, weight: .semibold))
                    Spacer()
                    Button {
                        shouldShowActionSheet.toggle()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .actionSheet(isPresented: $shouldShowActionSheet) {
                        .init(title: Text(self.card.name ?? "Unknown Card"), message: Text("Options"),
                              buttons: [
                                .default(Text("Edit"), action: {
                                shouldEditForm.toggle()
                            }),
                            .destructive(Text("Delete Card"), action: handleDelete),
                            .cancel()
                        ])
                    }

                }
                
                HStack {
                    let imageName = card.type?.lowercased() ?? ""
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                    Spacer()
                    Text("Balance: $5,000")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(card.number ?? "")
                
                HStack {
                    Text("Credit Limit: $\(card.limit)")
                    Spacer()
                    VStack(alignment: .trailing){
                        Text("Valid Thru")
                        Text("\(String(format: "%02d", card.expMonth + 1))/\(String(card.expYear % 2000))")
                    }
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(
                
                VStack {
                    
                    if let colorData = card.color,
                       let uiColor = UIColor.color(data: colorData),
                       let actualColor = Color(uiColor) {
                        LinearGradient(colors: [
                            actualColor.opacity(0.6),
                            actualColor
                        ], startPoint: .center, endPoint: .bottom)
                    } else {
                        LinearGradient(colors: [
                            Color.cyan.opacity(0.6),
                            Color.cyan
                        ], startPoint: .center, endPoint: .bottom)
                    }
                }
                
            )
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(8)
            .shadow(radius: 5)
            .padding(.horizontal)
            
            .fullScreenCover(isPresented: $shouldEditForm, onDismiss: nil) {
                AddCardForm(card: self.card)
            }
        }
    }
    
    var addCardButton: some View {
        Button {
            shouldPresentAddCardForm.toggle()
        } label: {
            Text("+ Card")
                .foregroundColor(Color(.systemBackground))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(.label))
                .cornerRadius(6)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        MainView()
            .environment(\.managedObjectContext, viewContext)
    }
}



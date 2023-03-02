//
//  TransactionsListView.swift
//  SpendingTracker
//
//  Created by Ali Can Kayaaslan on 16.02.2023.
//

import SwiftUI

struct TransactionsListView: View {
    
    let card: Card
    
    init(card: Card) {
        self.card = card
        
        fetchRequest = FetchRequest<CardTransaction>(entity: CardTransaction.entity(), sortDescriptors: [
            .init(key: "timestamp", ascending: false)
        ],predicate: .init(format: "card == %@", self.card))
    }
    
    @State private var shouldShowAddTransactionForm = false
    
    var fetchRequest: FetchRequest<CardTransaction>
    
//    @Environment(\.managedObjectContext) private var viewContext
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \CardTransaction.timestamp, ascending: true)],
//        animation: .default)
//    private var transactions: FetchedResults<CardTransaction>
    
    var body: some View {
        VStack {
            
            Text("Get started by adding first transaction")
            
            Button {
                shouldShowAddTransactionForm.toggle()
            } label: {
                Text("+ Transaction")
                    .foregroundColor(Color(.systemBackground))
                    .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                    .background(Color(.label))
                    .cornerRadius(5)
                    .font(.headline)
            }
            .fullScreenCover(isPresented: $shouldShowAddTransactionForm) {
                AddTransactionForm(card: card)
            }
            
            ForEach(fetchRequest.wrappedValue) { transaction in
                CardTransactionView(transaction: transaction)
            }
        }
    }
    
    }

struct CardTransactionView: View {
    
    let transaction: CardTransaction
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    @State var shouldPresentActionSheet = false
    
    private func handleDelete() {
        withAnimation {
            do {
                let context = PersistenceController.shared.container.viewContext
                context.delete(transaction)
                try context.save()
            } catch {
                print("Failed to delete transaction: ", error)
            }
        }
    }

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(transaction.name ?? "")
                        .font(.system(size: 18, weight: .bold))
                    if let date = transaction.timestamp {
                        Text(dateFormatter.string(from: date))
                    }
                }
                Spacer()
                
                VStack(alignment: .trailing) {
                    Button {
                        shouldPresentActionSheet.toggle()
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.black)
                            .font(.system(size: 24))
                    }.padding(EdgeInsets(top: 6, leading: 8, bottom: 4, trailing: 0))
                        .actionSheet(isPresented: $shouldPresentActionSheet) {
                            .init(title: Text(transaction.name ?? ""), message: nil, buttons: [
                                .destructive(Text("Delete"), action: handleDelete),
                                .cancel()])
                        }
                    
                    Text(String(format: "$%.2f", transaction.amount))
                    
                }
                
            }
            
            if let photoData = transaction.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
        }
        .foregroundColor(Color(.label))
        .padding()
        .background(Color.white)
        .cornerRadius(5)
        .shadow(radius: 5)
        .padding()
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    
    static let firstCard: Card? = {
        let context = PersistenceController.shared.container.viewContext
        let request = Card.fetchRequest()
        request.sortDescriptors = [.init(key: "timestamp", ascending: false)]
        return try? context.fetch(request).first
    }()
    
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        ScrollView {
            if let card = firstCard {
                TransactionsListView(card: card )
            }
        }
        .environment(\.managedObjectContext, context)
    }
}

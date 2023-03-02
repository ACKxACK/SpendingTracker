//
//  AddCardForm.swift
//  SpendingTracker
//
//  Created by Ali Can Kayaaslan on 2.02.2023.
//

import SwiftUI

struct AddCardForm : View {
    
    let card: Card?
    var didAddCard: ((Card) ->())? = nil
    
    init(card: Card? = nil, didAddCard: ((Card) ->())? = nil ) {
        self.card = card
        self.didAddCard = didAddCard
        
        _name = State(initialValue: self.card?.name ?? "")
        _cardID = State(initialValue: self.card?.number ?? "")
        
        if let cardlimit = card?.limit {
            _cardLimit = State(initialValue: String(cardlimit))
        }
        
        _cardType = State(initialValue: self.card?.type ?? "")
        _month = State(initialValue: Int(self.card?.expMonth ?? 1))
        _year = State(initialValue: Int(self.card?.expYear ?? Int16(currentYear)))
        
        if let data = self.card?.color, let uiColor = UIColor.color(data : data) {
            let c = Color(uiColor)
            _color = State(initialValue: c)
        }
        
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var cardID = ""
    @State private var cardLimit = ""
    
    @State private var cardType = "VISA"
    
    @State private var month = 1
    @State private var year = Calendar.current.component(.year, from: Date())
    let currentYear = Calendar.current.component(.year, from: Date())
    
    @State private var color = Color.blue
    
    var body: some View {
        NavigationView {
                Form {
                    Section(header: Text("CARD INFORMATION")) {
                        TextField("Name", text: $name)
                        TextField("CardID", text: $cardID)
                            .keyboardType(.numberPad)
                        TextField("Card Limit", text: $cardLimit)
                            .keyboardType(.numberPad)
                        
                        Picker("Type", selection: $cardType) {
                            ForEach(["VISA", "Master Card", "American Express"], id: \.self) { cardType in
                                Text(String(cardType)).tag(String(cardType))
                            }
                        }
                    }
                    
                    Section(header: Text("EXPIRATION DATE")) {
                        Picker("Month", selection: $month) {
                            ForEach(1...12, id: \.self) { num in
                                Text(String(num)).tag(String(num))
                            }
                        }
                        Picker("Year", selection: $year) {
                            ForEach(currentYear..<currentYear + 20, id: \.self) { year in
                                Text(String(year)).tag(String(year))
                            }
                        }
                    }
                    
                    Section(header: Text("COLOR")) {
                        ColorPicker("Color", selection: $color)
                    }
                }
                .navigationTitle("Add Credit Card")
                .navigationBarItems(leading: cancelButton, trailing: saveButton)
        }
    }
    
    private var cancelButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Cancel")
        })
    }
    
    private var saveButton: some View {
        Button(action: {
            let viewContext = PersistenceController.shared.container.viewContext
            
            let card = self.card != nil ? self.card! : Card(context: viewContext)
            
//            let card = Card(context: viewContext)
            
            card.name = self.name
            card.number = self.cardID
            card.limit = Int32(self.cardLimit) ?? 0
            card.expMonth = Int16(self.month)
            card.expYear = Int16(self.year)
            card.timestamp = Date()
            card.color = UIColor(self.color).encode()
            card.type = cardType
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
                didAddCard?(card)
            } catch {
                print("Failed to persist new card: \(error)")
            }
            
        }, label: {
            Text("Save")
        })
    }
}

extension UIColor {
    
    class func color(data:Data) -> UIColor? {
        return try?
            NSKeyedUnarchiver
            .unarchiveTopLevelObjectWithData(data) as? UIColor
    }
    
    func encode() -> Data? {
        return try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
}


struct AddCardForm_Previews: PreviewProvider {
    static var previews: some View {
//        AddCardForm()
        let context = PersistenceController.shared.container.viewContext
        MainView()
            .environment(\.managedObjectContext, context)
    }
}

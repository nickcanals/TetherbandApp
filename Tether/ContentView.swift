//
//  ContentView.swift
//  Tether
//
//  Created by Nicolas Canals on 8/29/21.
//

import SwiftUI

struct Child: Identifiable {
    var id = UUID()
    let title: String
}

class ChildViewModel: ObservableObject {
    @Published var kids: [Child] = [
        Child(title: "Nick"),
        Child(title: "Eric"),
        Child(title: "Kyle"),
        Child(title: "Carlie")
    ]
}

struct ContentView: View {
    @State var bleToggle = true
    @StateObject var viewModel = ChildViewModel()
    @State var text = ""
    
    
    var body: some View {
        NavigationView{
            VStack{
                Button(action: {bleToggle.toggle()},
                    label: {
                        Text("BLE Connect")
                            .bold()
                            .frame(width: 250,
                                   height: 50,
                                   alignment: .center)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .foregroundColor(Color.white)
                })
                if bleToggle{
                    Text("Bluetooth Connected")
                        .padding()
                }
                else{
                    Text("Bluetooth Disconnected")
                        .padding()
                }
                
                Section(header: Text("ADD NEW CHILD")) {
                    TextField("Childs Name...", text: $text)
                        .padding()
                    
                    Button(action: {self.tryToAdd()},
                        label: {
                            Text("Add Child")
                                .bold()
                                .frame(width: 250,
                                       height: 50,
                                       alignment: .center)
                                .background(Color.blue)
                                .cornerRadius(8)
                                .foregroundColor(Color.white)
                    })
                }
                List{
                    ForEach(viewModel.kids) { kid in
                        ChildRow(title: kid.title)
                    }
                }
            }
        }
    }
    func tryToAdd() {
        guard text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let newKid = Child(title: text)
        viewModel.kids.append(newKid)
        text = ""
    }
}

struct ChildRow: View {
    let title: String
    
    var body: some View {
        Label(
            title: { Text(title) },
            icon: {Image(systemName: "chart.bar")}
            //inRange: {Text("In Range")}
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

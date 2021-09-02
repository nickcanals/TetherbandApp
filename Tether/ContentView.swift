//
//  ContentView.swift
//  Tether
//
//  Created by Nicolas Canals on 8/29/21.
//

import SwiftUI

struct Child: Identifiable {
    var id = UUID()
    let name: String
    let inRange: String
    let wearing: String
}

class ChildViewModel: ObservableObject {
    @Published var kids: [Child] = [
        Child(name: "Nick", inRange: "In Range", wearing: "Bracelet On"),
        Child(name: "Eric", inRange: "In Range", wearing: "Bracelet On"),
        Child(name: "Kyle", inRange: "In Range", wearing: "Bracelet On"),
        Child(name: "Carlie", inRange: "In Range", wearing: "Bracelet On")
    ]
}

struct ContentView: View {
    @State var bleToggle = true
    @State var alarmToggle = false
    @StateObject var viewModel = ChildViewModel()
    @State var text = ""
    
    
    var body: some View {
        NavigationView{
            VStack{
                HStack{
                    Button(action: {bleToggle.toggle()},
                        label: {
                            Text("BLE Connect")
                                .bold()
                                .frame(width: 150,
                                       height: 50,
                                       alignment: .center)
                                .background(Color.blue)
                                .cornerRadius(8)
                                .foregroundColor(Color.white)
                    })
                    
                    Button(action: {alarmToggle.toggle()},
                        label: {
                            Text("Emergency Alarm")
                                .bold()
                                .frame(width: 150,
                                       height: 50,
                                       alignment: .center)
                                .background(Color.blue)
                                .cornerRadius(8)
                                .foregroundColor(Color.white)
                    })
                }
                if bleToggle{
                    Text("Bluetooth Connected")
                        .padding()
                }
                else{
                    Text("Bluetooth Disconnected")
                        .padding()
                }
                
                if alarmToggle{
                    Text("ALARRMS TRIGGERED")
                        .padding()
                }
                else{
                    Text("ALARMS ARE OFF")
                        .padding()
                }
                
                Section(header: Text("ADD NEW CHILD")) {
                    TextField("Childs Name...", text: $text)
                        .padding()
                    
                    Button(action: {
                        guard text.trimmingCharacters(in: .whitespaces).isEmpty else {
                            return
                        }
                        
                        let newKid = Child(name: text, inRange: "In Range", wearing: "Bracelet On")
                        viewModel.kids.append(newKid)
                        text = ""
                    }, label: {
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
                        ChildRow(name: kid.name, range: kid.inRange, wear: kid.wearing)
                    }
                }
            }
            .navigationTitle("Tetherband App")
        }
    }
    //func tryToAdd() {
    //    guard text.trimmingCharacters(in: .whitespaces).isEmpty else {
    //        return
    //    }
    //
    //    let newKid = Child(name: text, inRange: "In Range", wearing: "Bracelet On")
    //    viewModel.kids.append(newKid)
    //    text = ""
    //}
}

struct ChildRow: View {
    let name: String
    let range: String
    let wear: String
    
    var body: some View {
        HStack{
            Image(systemName: "chart.bar")
                .resizable()
                .scaledToFit()
                .frame(height: 20)
            Text(name)
                .fontWeight(.semibold)
                .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                .minimumScaleFactor(1.0)
            Text(range)
                .fontWeight(.semibold)
                .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                .minimumScaleFactor(1.0)
            Text(wear)
                .fontWeight(.semibold)
                .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                .minimumScaleFactor(1.0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

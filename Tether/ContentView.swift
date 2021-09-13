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
    @State var childAddToggle = true
    @State var nfcToggle = true
    @StateObject var viewModel = ChildViewModel()
    @State var text = ""
    @State var color = Color.black
    
    
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
                
                HStack{
                    Button(action: {nfcToggle.toggle()},
                        label: {
                            Text("NFC Config")
                                .bold()
                                .frame(width: 150,
                                       height: 50,
                                       alignment: .center)
                                .background(Color.green)
                                .cornerRadius(8)
                                .foregroundColor(Color.white)
                    })
                    
                    if nfcToggle{
                        Text("NFC Down")
                            .padding()
                    }
                    else{
                        Text("NFC Searching")
                            .padding()
                    }
                }
                
                //Color Picker widget, code is below
                DropDown()
                
                Section(header: Text("")) {
                    TextField("Childs Name...", text: $text)
                        .padding()
                    
                    Button(action: { tryToAdd()
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
    func tryToAdd() {
    //    guard text.trimmingCharacters(in: .whitespaces).isEmpty else {
    //        return
    //    }

        let newKid = Child(name: text, inRange: "In Range", wearing: "Bracelet On")
        viewModel.kids.append(newKid)
        text = ""
    }
    
    func colorChanger() {
        
    }
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

struct DropDown : View {
    @State var expand = false
    @State var color = Color.black
    
    var body : some View {
        VStack(alignment: .leading, content: {
            HStack {
                
                Text("Color Picker").fontWeight(.heavy).foregroundColor(.white)
                Image(systemName: expand ? "chevron.up" : "chevron.down").resizable().frame(width: 13, height: 6).foregroundColor(.white)
                
            }
            .frame(width: 250,
                   height: 50)
            .cornerRadius(8)
            .background(color)
            .onTapGesture(perform: {
                self.expand.toggle()
            })
            
            if expand {
                Button(action: { color = Color.orange
                }, label: {
                        Text("Orange")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .background(Color.orange)
                            .foregroundColor(Color.white)
                })
                
                Button(action: { color = Color.purple
                }, label: {
                        Text("Purple")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .foregroundColor(Color.white)
                            .background(Color.purple)
                })
                
                Button(action: { color = Color.yellow
                }, label: {
                        Text("Yellow")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .background(Color.yellow)
                            .foregroundColor(Color.white)
                })
                
                Button(action: { color = Color.red
                }, label: {
                        Text("Red")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .background(Color.red)
                            .foregroundColor(Color.white)
                })
                
                Button(action: { color = Color.blue
                }, label: {
                        Text("Blue")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .background(Color.blue)
                            .foregroundColor(Color.white)
                })
                
                Button(action: { color = Color.green
                }, label: {
                        Text("Green")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .background(Color.green)
                            .foregroundColor(Color.white)
                })
            }
            
        })
        .frame(width: 250,height: expand ? 250 : 50)
        .padding()
        .cornerRadius(12)
        .animation(.spring())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



//
//  ContentView.swift
//  Tether
//
//  Created by Nicolas Canals on 8/29/21.
//

import SwiftUI
import CoreNFC

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
    @State var data = ""
    
    
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
                }
                else{
                    Text("Bluetooth Disconnected")
                }
                
                if alarmToggle{
                    Text("ALARRMS TRIGGERED")
                        .padding()
                }
                else{
                    Text("ALARMS ARE OFF")
                        .padding()
                }
                
                //NFC Config Section with code below
                HStack{
                    nfcButton(data: self.$data)
                }.frame(width: 250, height: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/).cornerRadius(8)
                
                Text(data).padding()
                
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
                .padding()
                .frame(alignment: .center)
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

struct nfcButton : UIViewRepresentable {
    @Binding var data : String
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton()
        button.setTitle("NFC Config", for: .normal)
        button.backgroundColor = UIColor.green
        button.addTarget(context.coordinator, action: #selector(context.coordinator.beginScan(sender:)), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        // Nothing Goes Here
    }
    
    func makeCoordinator() -> nfcButton.Coordinator {
        return Coordinator(data: $data)
    }
    
    class Coordinator : NSObject, NFCNDEFReaderSessionDelegate {
        var session : NFCNDEFReaderSession?
        @Binding var data : String
        
        init(data: Binding<String>) {
            _data = data
        }
        
        @objc func beginScan (sender: Any) {
            guard NFCNDEFReaderSession.readingAvailable else {
                print("NFC Scanning Not Supported")
                return
            }
            
            session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: true)
            session?.alertMessage = "Scan The Bracelet"
            session?.begin()
        }
        
        func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
            //Check invalidation reason for returned error
            if let readerError = error as? NFCReaderError {
                //Showing an alert when there are errors not simple
                if(readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead) && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                    print("Error NFC Read: \(readerError.localizedDescription)")
                }
            }
            //to read new tags, a new session instance is needed
            self.session = nil
        }
        
        func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
            guard
                let nfcMess = messages.first,
                let record = nfcMess.records.first,
                record.typeNameFormat == .absoluteURI || record.typeNameFormat == .nfcWellKnown,
                let payload = String(data: record.payload, encoding: .utf8)
            else {
                return
            }
            print(payload)
            self.data = payload
        }
    }
    
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



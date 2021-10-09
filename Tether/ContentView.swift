//
//  ContentView.swift
//  Tether
//
//  Created by Nicolas Canals on 8/29/21.
//

import SwiftUI
import CoreNFC


struct ContentView: View {
    @State var bleToggle = true
    @State var alarmToggle = false
    @State var childAddToggle = true
    @State var nfcToggle = true
    @State var nfcWriter = NFCWrite()
    @State var data = ""
    
    @State var expand = false
    @State var color = Color.black
    @State var colorStr = ""
    @State var colorInt = 0
    
    
    var body: some View {
        NavigationView{
            VStack{
                Image("Image1")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                
                
                //Color Dropdown Code
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
                        Button(action: { color = Color.orange; colorStr = "orange"; colorInt = 0
                        }, label: {
                                Text("Orange")
                                    .frame(width: 250,
                                           height: 30,
                                           alignment: .center)
                                    .background(Color.orange)
                                    .foregroundColor(Color.white)
                        })
                        
                        Button(action: { color = Color.purple; colorStr = "purple"; colorInt = 1
                        }, label: {
                                Text("Purple")
                                    .frame(width: 250,
                                           height: 30,
                                           alignment: .center)
                                    .foregroundColor(Color.white)
                                    .background(Color.purple)
                        })
                        
                        Button(action: { color = Color.yellow; colorStr = "yellow"; colorInt = 2
                        }, label: {
                                Text("Yellow")
                                    .frame(width: 250,
                                           height: 30,
                                           alignment: .center)
                                    .background(Color.yellow)
                                    .foregroundColor(Color.white)
                        })
                        
                        Button(action: { color = Color.red; colorStr = "red"; colorInt = 3
                        }, label: {
                                Text("Red")
                                    .frame(width: 250,
                                           height: 30,
                                           alignment: .center)
                                    .background(Color.red)
                                    .foregroundColor(Color.white)
                        })
                        
                        Button(action: { color = Color.blue; colorStr = "blue"; colorInt = 4
                        }, label: {
                                Text("Blue")
                                    .frame(width: 250,
                                           height: 30,
                                           alignment: .center)
                                    .background(Color.blue)
                                    .foregroundColor(Color.white)
                        })
                        
                        Button(action: { color = Color.green; colorStr = "green"; colorInt = 5
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
                
                Text(colorStr)
                    .foregroundColor(Color.black)
                    .padding()
                
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
                        .foregroundColor(Color.black)
                }
                else{
                    Text("Bluetooth Disconnected")
                        .foregroundColor(Color.black)
                }
                
                if alarmToggle{
                    Text("ALARRMS TRIGGERED")
                        .padding()
                        .foregroundColor(Color.black)
                }
                else{
                    Text("ALARMS ARE OFF")
                        .padding()
                        .foregroundColor(Color.black)
                }
    
                HStack{
                    //NFC Config Section with code below
                    nfcButton(data: self.$data)
                        .frame(width: 150, height: 50, alignment: .center)
                        .cornerRadius(8)
                    
                    Button(action: {self.nfcWriter.scanNow(message: "Color", recordType: .text)},
                        label: {
                            Text("NFC Write")
                                .bold()
                                .frame(width: 150,
                                       height: 50,
                                       alignment: .center)
                                .background(Color.blue)
                                .cornerRadius(8)
                                .foregroundColor(Color.white)
                    })
                }
                
                Text(data).padding().foregroundColor(Color.black)
                
                NavigationLink(destination: ChildListView()) {
                                Text("Child List")
                                    .bold()
                                    .frame(width: 150,
                                           height: 50,
                                           alignment: .center)
                                    .background(Color.purple)
                                    .cornerRadius(8)
                                    .foregroundColor(Color.white)
                }
                Spacer()
            }.background(Color.white.edgesIgnoringSafeArea(.all))
        }
    }
    func colorChanger() {
        
    }
}

//Color Dropdown Code
struct DropDown : View {
    @State var expand = false
    @State var color = Color.black
    @State var colorStr = ""
    
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
                Button(action: { color = Color.orange; colorStr = "orange"
                }, label: {
                        Text("Orange")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .background(Color.orange)
                            .foregroundColor(Color.white)
                })
                
                Button(action: { color = Color.purple; colorStr = "purple"
                }, label: {
                        Text("Purple")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .foregroundColor(Color.white)
                            .background(Color.purple)
                })
                
                Button(action: { color = Color.yellow; colorStr = "yellow"
                }, label: {
                        Text("Yellow")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .background(Color.yellow)
                            .foregroundColor(Color.white)
                })
                
                Button(action: { color = Color.red; colorStr = "red"
                }, label: {
                        Text("Red")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .background(Color.red)
                            .foregroundColor(Color.white)
                })
                
                Button(action: { color = Color.blue; colorStr = "blue"
                }, label: {
                        Text("Blue")
                            .frame(width: 250,
                                   height: 30,
                                   alignment: .center)
                            .background(Color.blue)
                            .foregroundColor(Color.white)
                })
                
                Button(action: { color = Color.green; colorStr = "green"
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
    
    
//NFC Write Code
enum RecordType {
    case text, url
}

class NFCWrite : NSObject, NFCNDEFReaderSessionDelegate {
    var session : NFCNDEFReaderSession?
    var mess = ""
    var rType : RecordType = .text
    
    func scanNow(message: String, recordType: RecordType) {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("Scanning Not Supported for This Device")
            return
        }
        self.mess = message
        self.rType = recordType
        
        session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: false)
        session?.alertMessage = "Scan The Bracelet"
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        //to implement error stuff
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        //Nothing Goes Here
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        //To Silence Console
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1{
            let retryInterval = DispatchTimeInterval.milliseconds(1000)
            session.alertMessage = "More than 1 tag. Scan Again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                session.restartPolling()
            }
            return
        }
        let tag = tags.first!
        session.connect(to: tag) { (error) in
            if let error = error {
                session.alertMessage = "Unable to connect to tag."
                session.invalidate()
                print("Error Blasted")
                return
            }
            tag.queryNDEFStatus { (ndefStatus, capacity, error) in
                if let error = error {
                    session.alertMessage = "Unable to connect to tag."
                    session.invalidate()
                    print("Error Blasted")
                    return
                }
                
                //move to query
                switch ndefStatus{
                case .notSupported:
                    session.alertMessage = "Unable to connect to tag."
                    session.invalidate()
                case .readOnly:
                    session.alertMessage = "Unable to connect read tag only."
                    session.invalidate()
                case .readWrite: //write logic
                    print("Read Write accepted")
                    let payload : NFCNDEFPayload?
                    switch self.rType {
                    case .text:
                        guard !self.mess.isEmpty else {
                            session.alertMessage = "Empty Data"
                            session.invalidate(errorMessage: "Empty Text Data")
                            return
                        }
                        payload = NFCNDEFPayload(format: .nfcWellKnown, type: "T".data(using: .utf8)!, identifier: "Text".data(using: .utf8)!, payload: self.mess.data(using: .utf8)!)
                        
                    case .url:
                        print("Trying to send URL")
                        //Nothing needs to be here
                        guard let url = URL(string: self.mess) else {
                            print("Not Valid URL")
                            session.alertMessage = "Unrecognizable URL"
                            session.invalidate(errorMessage: "Not URL")
                            return
                        }
                        
                        payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url)
                    }
                    
                    //making message
                    let NFCMessage = NFCNDEFMessage(records: [payload!])
                    
                    //writing to tag
                    tag.writeNDEF(NFCMessage) { (error) in
                        if error != nil{
                            session.alertMessage = "Write NDEF failed. \(error!.localizedDescription)"
                            print("Failed to write. \(error!.localizedDescription)")
                        }
                        else{
                            session.alertMessage = "Write Success!"
                            print("write successful")
                        }
                        session.invalidate()
                    }
                }
            }
        }
    }
}


//NFC Read Code
struct nfcButton : UIViewRepresentable {
    @Binding var data : String

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton()
        button.setTitle("NFC Read", for: .normal)
        button.backgroundColor = UIColor.blue
        button.addTarget(context.coordinator, action: #selector(context.coordinator.beginScan(sender:)), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
         //Nothing Goes Here
    }

    func makeCoordinator() -> nfcButton.Coordinator {
        return Coordinator(data: $data)
    }
    
    class Coordinator : NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
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
            .padding()
    }
}



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
    @State var color = Color.black
    @State var nfc = NFCScanner()
    @State var data = ""
    
    var body: some View {
        NavigationView{
            VStack{
                HStack{
                    Text("Tetherband App")
                        .bold()
                        .font(.largeTitle)
                    Image("Image1")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                }
                
                //Color Picker widget, code is below
                DropDown().padding()
                
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
                Button(action: {nfc.scanNow(_data: "Wowzerzzzzzzz")},
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
                
                Text(data).padding()
                
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
            }
        }
    }
    func colorChanger() {
        
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

//struct nfcButton : UIViewRepresentable {
//    @Binding var data : String
//
//    func makeUIView(context: Context) -> UIButton {
//        let button = UIButton()
//        button.setTitle("NFC Config", for: .normal)
//        button.backgroundColor = UIColor.gray
//        button.addTarget(context.coordinator, action: #selector(context.coordinator.beginScan(sender:)), for: .touchUpInside)
//        return button
//    }
//
//    func updateUIView(_ uiView: UIButton, context: Context) {
//         Nothing Goes Here
//    }
//
//    func makeCoordinator() -> nfcButton.Coordinator {
//        return Coordinator(data: $data)
//    }
    
    class NFCScanner : NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
        var session : NFCNDEFReaderSession?
        var data : String = ""
        
        func scanNow (_data: String) {
            data = _data
            session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
            session?.alertMessage = "Scan The Bracelet"
            session?.begin()
        }
        
        func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {}
        
        func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {}
        
        func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
            let str: String = data
            if tags.count > 1{
                let retryInterval = DispatchTimeInterval.milliseconds(500)
                session.alertMessage = "More than 1 tag. Scan Again."
                DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {session.restartPolling()})
                return
            }
            let tag = tags.first!
            session.connect(to: tag, completionHandler: {(error: Error?) in
                if nil != error{
                    session.alertMessage = "Unable to connect to tag."
                    session.invalidate()
                    return
                }
                tag.queryNDEFStatus(completionHandler: {(ndefstatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                    guard error == nil else {
                        session.alertMessage = "Unable to connect to tag."
                        session.invalidate()
                        return
                    }
                    switch ndefstatus{
                    case .notSupported:
                        session.alertMessage = "Unable to connect to tag."
                        session.invalidate()
                    case .readOnly:
                        session.alertMessage = "Unable to connect read tag only."
                        session.invalidate()
                    case .readWrite:
                        tag.writeNDEF(.init(records: [NFCNDEFPayload.wellKnownTypeURIPayload(string: "\(str)")!]), completionHandler: {(error: Error?) in
                            if nil != error{
                                session.alertMessage = "Write NDEF failed."
                            }
                            else{
                                session.alertMessage = "Write Success!"
                            }
                            session.invalidate()
                        })
                    @unknown default:
                        session.alertMessage = "Unknown Error."
                        session.invalidate()
                    }
                })
            })
        }
    }
//        init(data: Binding<String>) {
//            _data = data
//        }
//
//        @objc func beginScan (sender: Any) {
//            guard NFCNDEFReaderSession.readingAvailable else {
//                print("NFC Scanning Not Supported")
//                return
//            }
//
//            session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: true)
//            session?.alertMessage = "Scan The Bracelet"
//            session?.begin()
//        }
//
//        func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
//            //Check invalidation reason for returned error
//            if let readerError = error as? NFCReaderError {
//                //Showing an alert when there are errors not simple
//                if(readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead) && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
//                    print("Error NFC Read: \(readerError.localizedDescription)")
//                }
//            }
//            //to read new tags, a new session instance is needed
//            self.session = nil
//        }
//
//        func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
//            guard
//                let nfcMess = messages.first,
//                let record = nfcMess.records.first,
//                record.typeNameFormat == .absoluteURI || record.typeNameFormat == .nfcWellKnown,
//                let payload = String(data: record.payload, encoding: .utf8)
//            else {
//                return
//            }
//            print(payload)
//            self.data = payload
//        }
  //  }
    
//}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .padding()
    }
}



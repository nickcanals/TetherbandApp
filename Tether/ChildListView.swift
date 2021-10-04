//
//  ChildListView.swift
//  Tether
//
//  Created by Nicolas Canals on 9/14/21.
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
        Child(name: "Nick", inRange: "Yes", wearing: "Yes"),
        Child(name: "Eric", inRange: "Yes", wearing: "Yes"),
        Child(name: "Kyle", inRange: "Yes", wearing: "Yes"),
        Child(name: "Carlie", inRange: "Yes", wearing: "Yes")
    ]
}

struct ChildListView: View {
    @StateObject var viewModel = ChildViewModel()
    @State var data = ""
    @State var text = ""
    
    var body: some View {
        VStack{
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
                
                Text("  Battery   |    Name    |    In Range    |    Bracelet On")
                    .padding()
            }
            List{
                ForEach(viewModel.kids) { kid in
                    ChildRow(name: kid.name, range: kid.inRange, wear: kid.wearing)
                }
            }
        }
    } 
    func tryToAdd() {
    //    guard text.trimmingCharacters(in: .whitespaces).isEmpty else {
    //        return
    //    }

        let newKid = Child(name: text, inRange: "Yes", wearing: "Yes")
        viewModel.kids.append(newKid)
        text = ""
    }
}

struct ChildRow: View {
    let name: String
    let range: String
    let wear: String
    
    var body: some View {
        HStack{
            Image("Bat_Full")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
            Text("25%")
            Text("|")
            Text(name)
                .fontWeight(.semibold)
                .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                .minimumScaleFactor(1.0)
                .frame(maxWidth: .infinity)
            Text("|")
            Text(range)
                .fontWeight(.semibold)
                .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                .minimumScaleFactor(1.0)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.green)
            Text("|")
                //.frame(maxWidth: .infinity)
            Text(wear)
                .fontWeight(.semibold)
                .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                .minimumScaleFactor(1.0)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.green)
        }
    }
}

struct ChildListView_Previews: PreviewProvider {
    static var previews: some View {
        ChildListView()
    }
}

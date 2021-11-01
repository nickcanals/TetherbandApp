//
//  TetherApp.swift
//  Tether
//
//  Created by Nicolas Canals on 8/29/21.
//

import SwiftUI
import BackgroundTasks

@main
struct TetherApp: App {
    /*var viewModel = ChildViewModel()
    var bleManager = BLEManager(logger: Logger(LoggerFuncs(date: false).setLogPath()!))
    init(){
        bleManager.setChildList(list: viewModel)
    }*/
    var body: some Scene {
        WindowGroup {
            //ContentView(viewModel: viewModel, bleManager: bleManager)
            ContentView()
        }
    }
}

//
//  LoggerFuncs.swift
//  Tether
//
//  Created by Eric Hull on 10/20/21.
//

import Foundation

class LoggerFuncs{
    let formatter : DateFormatter?
    
    init(date: Bool){
        if date{
            formatter = DateFormatter()
            formatter?.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
        }
        else{
            formatter = nil
        }
    }
    
    func getDocumentDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func setLogPath() -> FileHandle?{
        let filePath = self.getDocumentDirectory().appendingPathComponent("log.txt")
        do{
            let data = Data("".utf8)
            try data.write(to: filePath)
            let handle = try FileHandle(forWritingTo: filePath)
            return handle
        }catch{
            print("file handle not properly created. Error: \(error)")
            return nil
        }
    }
    
    func addDate(message: String) -> String{
        let dateTime = formatter?.string(from: Date()) ?? ""
        return dateTime + message
    }
}

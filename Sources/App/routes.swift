import Vapor
import Crypto

struct LoginRequest: Content {
    var api: String
    var secret: String
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
    
//    router.get("tickers", use: todoController.ticker())
    
    // Basic "Hello, world!" example
    router.get("tickers") { req in
        return todoController.ticker()
    }
    
    router.post("balances") { req -> String in
        
        let a = try req.content.decode(LoginRequest.self)
        
        _ = a.map({ request -> Void in

            guard let apiData = Data(base64Encoded: request.api, options: Data.Base64DecodingOptions(rawValue: 0)), let secretData = Data(base64Encoded: request.secret, options: Data.Base64DecodingOptions(rawValue: 0)), let apikey = String(data: apiData as Data, encoding: String.Encoding.utf8), let secret = String(data: secretData as Data, encoding: String.Encoding.utf8) else {
                return
            }
            
            
            
            if apikey.suffix(6) == "kepler" && secret.suffix(6) == "lukrum" {
                
                todoController.history(apikey: apikey.dropLast(6).description, secret: secret.dropLast(6).description)
                
            }
        })
        
        
        return ""
    }
}

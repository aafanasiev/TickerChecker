import Vapor
import Foundation
import Crypto

//struct Ticker {
//
//    let symbol: String
//    let priceUSDT: String
//    let priceBTC: String
//    let changeUSDT: String
//    let changeBTC: String
//}

struct ExchangeInfo {
    let apikey: String
    let secret: String
}

struct TradeHistory {
    
//    let orderId: Int
//    let isMaker: Bool
    let time: Date
//    let id: Int
    let price: Double
//    let isBestMatch: Bool
    let symbol: String
    let commission: Double
    let qty: Double
    let isBuyer: Bool
    let commissionAsset: String
    
}

struct Asset {
    
    let date: Date
    let symbol: String
    let amount: Double
}

struct TempAsset {

    let date: Date
    let symbol: String
    let amount: Double
}

/// Controls basic CRUD operations on `Todo`s.
final class TodoController {
    /// Returns a list of all `Todo`s.
    func index(_ req: Request) throws -> Future<[Todo]> {
        return Todo.query(on: req).all()
    }

    /// Saves a decoded `Todo` to the database.
    func create(_ req: Request) throws -> Future<Todo> {
        return try req.content.decode(Todo.self).flatMap { todo in
            return todo.save(on: req)
        }
    }

    /// Deletes a parameterized `Todo`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Todo.self).flatMap { todo in
            return todo.delete(on: req)
        }.transform(to: .ok)
    }
    
    
    func history(apikey: String, secret: String) -> String {
        
        print(apikey)
        print(secret)
        
        let exchangeInfo = ExchangeInfo(apikey: apikey, secret: secret)
        
        _ = getTradeHistory(exchangeInfo: exchangeInfo)
        
//        _ = getOperations(exchangeInfo: exchangeInfo)
        
//        _ = getBalance(exchangeInfo: exchangeInfo)
        
//        _ = getTickers()
        
        
        
        return ""
    }
    
    func getBalance(exchangeInfo: ExchangeInfo) -> String {
        
        
        
        let date = Int(Date().timeIntervalSince1970 * 1000)
        let str = "timestamp=\(date)"
        let secret = exchangeInfo.secret
        
        
        
        let digest = try! HMAC.SHA256.authenticate(str, key: secret)
        let hash = digest.hexEncodedString()
        
        let urlString = "https://api.binance.com/api/v3/account?\(str)&signature=\(hash)"
        let url = URL(string: urlString)!
       
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(exchangeInfo.apikey, forHTTPHeaderField: "X-MBX-APIKEY")
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
               
                print("Error: \(error!.localizedDescription)")
            }
            
            if let dat = data {
                
                do {
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : Any] else {return}
                    
                   
                    print("Array: \(array)")
                   
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
        
        return ""
    }
    
    
    func getTradeHistory(exchangeInfo: ExchangeInfo) -> String {

        let sellSymbol = ["BTC", "ETH", "USDT", "BNB"]

        var trades = [TradeHistory]()
        var tempAssets = [TempAsset]()
        

        let date = Int(Date().timeIntervalSince1970 * 1000)
        let str = "timestamp=\(date)"
        let secret = exchangeInfo.secret

        let digest = try! HMAC.SHA256.authenticate(str, key: secret)
        let hash = digest.hexEncodedString()
        
//        let hash = sign(message: str, algorithm: .sha256, key: secret)!

        var count = 0
        let myGroup = DispatchGroup()
        
        let urlString = "https://api.binance.com/api/v3/account?\(str)&signature=\(hash)"
        let url = URL(string: urlString)!
        
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(exchangeInfo.apikey, forHTTPHeaderField: "X-MBX-APIKEY")
        
        var symbols = [[String:AnyObject]]()
        
        myGroup.enter()
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                print("Error: \(error!.localizedDescription)")
            }
            
            print(data)
            
            if let dat = data {
                
                do {
                    
                    guard let balances = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : Any] else {
                        
                        print("Wrong parsing")
                        return
                        
                    }
                    
                    if let array = balances["balances"] as? [[String:AnyObject]] {
                        
                        let filterArray = array.filter({ type -> Bool in
                            if let amount = type["free"] as? String {
                                return Double(amount)! > 0
                            } else {
                                return false
                            }
                        }).map{$0}
                        
                        print("Filter Array: \(filterArray.count)")
                        symbols = array
                        //filterArray
                        myGroup.leave()
                        
                        
                    
                    } else {
                        print("Error balance cast")
                        print(balances)
                    }
                    
                } catch {
                        print("Error: \(error.localizedDescription)")
                }
            } else {
                print("Date nil")
            }
        }.resume()
                
        
        myGroup.wait()
        
//        print("DONE: \(symbols.count)")
        
        myGroup.enter()
        
        _ = symbols.enumerated().map({ arr -> Void in
            if let symbol = arr.element["asset"] as? String {
                _ = sellSymbol.enumerated().map({ sell -> Void in
                    let date1 = Int(Date().timeIntervalSince1970) * 1000
                    let str1 = "symbol=\(symbol)\(sell.element)&timestamp=\(date1)"
                    
                    let digest1 = try! HMAC.SHA256.authenticate(str1, key: secret)
                    let hash1 = digest1.hexEncodedString()

                    let urlString1 = "https://api.binance.com/api/v3/myTrades?\(str1)&signature=\(hash1)"
                    let url1 = URL(string: urlString1)!

                    let session1 = URLSession.shared
                    var request1 = URLRequest(url: url1)
                    request1.httpMethod = "GET"
                    request1.addValue(exchangeInfo.apikey, forHTTPHeaderField: "X-MBX-APIKEY")
                    
                    session1.dataTask(with: request1) { (data1, resp, error) in
                    
                        count += 1
                        
                        if let respData = data1 {
                            do {
                                if let response = try JSONSerialization.jsonObject(with: respData, options: .mutableContainers) as? [[String : AnyObject]] {
                                
                                    
                                    
                                    _ = response.map({ dict -> Void in
                                        
                                        print("Dict: \(dict)")
                                        
                                        if let orderId = dict["orderId"] as? Int, let isMaker = dict["isMaker"] as? Bool, let time = dict["time"] as? Double, let id = dict["id"] as? Int, let price = dict["price"] as? String, let isBestMatch = dict["isBestMatch"] as? Bool, let symbol = dict["symbol"] as? String, let commission = dict["commission"] as? String, let qty = dict["qty"] as? String, let isBuyer = dict["isBuyer"] as? Bool, let commissionAsset = dict["commissionAsset"] as? String, let tAmount = Double(qty), let tCommission = Double(commission), let tPrice = Double(price) {
                                            
                                            if isBuyer {
                                                
                                                let sym = symbol.prefix(commissionAsset.count).description == commissionAsset ? symbol.dropFirst(commissionAsset.count).description : symbol.dropLast(commissionAsset.count).description
                                               
                                            
                                                let ta1 = TempAsset(date: Date(timeIntervalSince1970: time / 1000), symbol: commissionAsset, amount: tAmount - tCommission)
                                                tempAssets.append(ta1)
                                                
                                                let ta2 = TempAsset(date: Date(timeIntervalSince1970: time / 1000), symbol: sym, amount: tAmount * tPrice * -1)
                                                tempAssets.append(ta2)
                                                
                                            } else {
                                                
                                                let sym = symbol.prefix(commissionAsset.count).description == commissionAsset ? symbol.dropFirst(commissionAsset.count).description : symbol.dropLast(commissionAsset.count).description
                                             
                                                let ta1 = TempAsset(date: Date(timeIntervalSince1970: time / 1000), symbol: commissionAsset, amount: tAmount * tPrice)
                                                tempAssets.append(ta1)
                                                
                                                let ta2 = TempAsset(date: Date(timeIntervalSince1970: time / 1000), symbol: sym, amount: (tAmount - tCommission) * -1)
                                                tempAssets.append(ta2)
                                                
                                            }
                                            
                                            
//                                            let th = TradeHistory(time: Date(timeIntervalSince1970: time/1000), price: Double(price)!, symbol: symbol, commission: Double(commission)!, qty: Double(qty)!, isBuyer: isBuyer, commissionAsset: commissionAsset)
//                                            trades.append(th)
                                            
                                            
                                        }
                                        
                                        
                                    })
                                }
                            } catch {}
                        }
                        
//                        print(count)
                        if count == sellSymbol.count * symbols.count {
                            myGroup.leave()
                        }
                        
                    }.resume()
                })
            }
        })
   
        myGroup.wait()
//        print("ARRAY: \(trades)")
        
        tempAssets = tempAssets.sorted(by: {$0.date < $1.date})
        
        _ = tempAssets.map{print($0)}
        
//        trades = trades.sorted(by: {$0.time < $1.time})
//
//        _ = trades.map{print($0)}
        
        
        
       

//        let headers: HTTPHeaders = ["X-MBX-APIKEY" : exchangeInfo.apiKey]
//
//        print("Start: \(Date())")

//        Alamofire.request(url, method: .get, headers: headers).responseJSON { resp in
//
//            if let data = resp.data {
//
//                do {
//                    if let balances = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : AnyObject] {
//
//                        if let array = balances["balances"] as? [[String:AnyObject]] {
//
//                            //                            print("Array: \(array)")
//
//                            _ = array.filter({ type -> Bool in
//                                if let amount = type["free"] as? String {
//                                    return Double(amount)! > 0
//                                } else {
//                                    return false
//                                }
//                            }).map({ arr -> Void in
//                                if let symbol = arr["asset"] as? String {
//
//                                    _ = sellSymbol.map({ sell -> Void in
//
//                                        let date = Int(Date().timeIntervalSince1970) * 1000
//                                        let str1 = "symbol=\(symbol)\(sell)&timestamp=\(date)"
//                                        //                                        let secret = binanceInfo.secret
//
//                                        let hash1 = self.sign(message: str1, algorithm: .sha256, key: secret)!
//                                        let urlString = "https://api.binance.com/api/v3/myTrades?\(str1)&signature=\(hash1)"
//
//                                        let url = URL(string: urlString)!
//
//                                        let headers: HTTPHeaders = ["X-MBX-APIKEY" : binanceInfo.apiKey]
//
//                                        Alamofire.request(url, method: .get, headers: headers).responseJSON { resp in
//
//                                            if let respData = resp.data {
//
//                                                do {
//                                                    if let response = try JSONSerialization.jsonObject(with: respData, options: .mutableContainers) as? [[String : AnyObject]] {
//
//                                                        _ = response.map({ arr -> Void in
//                                                            print(arr)
//
//                                                            let isBuyer = arr["isBuyer"] as? Bool
//                                                            let price = arr["price"] as? String
//                                                            let date = Date(timeIntervalSince1970: (arr["time"] as! Double) / 1000)
//                                                            let amount = arr["qty"] as? String
//                                                            let symbol = arr["symbol"] as? String
//                                                            let comission = arr["commissionAsset"] as? String
//                                                            let comissionAmount = arr["commission"] as? String
//
//                                                            if isBuyer! {
//                                                                //                                                                print("Date: \(date) - \(comission!): \(Double(amount!)! - Double(comissionAmount!)!)")
//
//                                                                var sym = ""
//                                                                if symbol!.prefix(comission!.count).description == comission {
//                                                                    sym = symbol!.dropFirst(comission!.count).description
//                                                                } else {
//                                                                    sym = symbol!.dropLast(comission!.count).description
//                                                                }
//
//                                                                //                                                                print("Date: \(date) - \(sym): -\(Double(amount!)! * Double(price!)!)")
//                                                            } else {
//
//
//                                                                var sym = ""
//                                                                if symbol!.prefix(comission!.count).description == comission {
//                                                                    sym = symbol!.dropFirst(comission!.count).description
//                                                                } else {
//                                                                    sym = symbol!.dropLast(comission!.count).description
//                                                                }
//                                                                //
//                                                                //                                                                print("Date: \(date) - \(sym): -\(Double(amount!)! - Double(comissionAmount!)!)")
//                                                                //                                                                print("Date: \(date) - \(comission!): \(Double(amount!)! * Double(price!)!)")
//                                                            }
//
//
//
//                                                            //                                                             print("Finish: \(Date())")
//                                                        })
//                                                    }
//                                                } catch {
//                                                }
//
//                                            }
//
//                                        }
//
//                                    })
//
//
//                                }
//
//                            })
//
//                        }
//
//                    }
//                } catch {
//
//                }
//
//
//            }
//        }



        return ""

    }

    
    
    
    func getOperations(exchangeInfo: ExchangeInfo) -> String {

        let date = Int(Date().timeIntervalSince1970 * 1000)
        let str = "timestamp=\(date)"
        let secret = exchangeInfo.secret

        let digest = try! HMAC.SHA256.authenticate(str, key: secret)
        let hash = digest.hexEncodedString()
        
        
//        let hash = sign(message: str, algorithm: .sha256, key: secret)!

        let urlString = "https://api.binance.com/wapi/v3/depositHistory.html?\(str)&signature=\(hash)"
        let url = URL(string: urlString)!

        let urlString1 = "https://api.binance.com/wapi/v3/withdrawHistory.html?\(str)&signature=\(hash)"
        let url1 = URL(string: urlString1)!
        
        
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(exchangeInfo.apikey, forHTTPHeaderField: "X-MBX-APIKEY")
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                
                print("Error: \(error!.localizedDescription)")
            }
            
            if let dat = data {
                
                do {
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : Any] else {return}
                    
                    
                    print("Array: \(array)")
                    
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
        
        
        
        
        let session1 = URLSession.shared
        var request1 = URLRequest(url: url1)
        request1.httpMethod = "GET"
        request1.addValue(exchangeInfo.apikey, forHTTPHeaderField: "X-MBX-APIKEY")
        
        session1.dataTask(with: request1) { (data, resp, error) in
            
            if error != nil {
                
                print("Error: \(error!.localizedDescription)")
            }
            
            if let dat = data {
                
                do {
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : Any] else {return}
                    
                    
                    print("Array: \(array)")
                    
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()

        return ""
    }
    
    // return array tickers [price, change - btc/usdt]
    func getTickers() -> String {
       
        let url = URL(string: "https://api.binance.com/api/v1/ticker/24hr")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                print("Error: \(error!.localizedDescription)")
            }
            
            if let dat = data {
                
                do {
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [[String : Any]] else {return}
                   
                    print("Array: \(array)")
                    
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
    
        return ""
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    func ticker() -> String {
        
        let group = DispatchGroup()
        var tickerArray = [[String : AnyObject]]()
        
        var str = [String : Any]()
        
//        getCAP()
        
        group.enter()
        getHuobiTickers { tickers in
            
            if let tic = tickers {
                tickerArray = tic
                group.leave()
            }
            
//            tickerArray = tickers!
            
        }
        
        
        
        group.wait()
        
        
        
//        str["data"] = tickerArray as Any
        
        do {
            let theJSONData = try? JSONSerialization.data(withJSONObject: tickerArray, options: [.prettyPrinted])

            print(theJSONData)

            let theJSONText = String(data: theJSONData!, encoding: .utf8)

            return theJSONText!
        } catch {

        }
        
        return ""
    }
    
    
    func getBinanceTickers(completion: @escaping([[String : AnyObject]]?) -> Void) {
        
        var tickers = [[String:AnyObject]]()
        
        let session = URLSession.shared
        let url = URL(string: "https://api.binance.com/api/v1/ticker/24hr")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                completion(nil)
            }
            
            if let dat = data {
                
                do {
                    
                    var usdPrice: Double = 0
                    var yesterdayPrice: Double = 0
                    
//                    var ethPrice: Double = 0
//                    var yesterdayETHPrice: Double = 0
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [[String : Any]] else {return}
                    
 
                    _ = array.filter({ dict -> Bool in
                        if let symbol = dict["symbol"] as? String {
                            if symbol == "BTCUSDT" {
                                return true
                            }
                        }
                        return false
                    }).map({ dict -> Void in
                        
                        if let price = dict["weightedAvgPrice"] as? String, let change = dict["priceChange"] as? String {
                            
                            usdPrice = Double(price)!
                            yesterdayPrice = Double(price)! - Double(change)!
                            
                        }
                        
                    })
                    
                    _ = array.map({ dict -> Void in
                        if let symbol = dict["symbol"] as? String, let price = dict["weightedAvgPrice"] as? String, let change = dict["priceChangePercent"] as? String, let changeValue = dict["priceChange"] as? String {
                            if symbol.suffix(3) == "BTC" && Double(price)! != 0 {
//                                print("\(symbol) - \(price) - \(change)")
                                
                                let sym = symbol.dropLast(3).description
                                let tickerUSDPrice = (Double(price)! * usdPrice)
                                print(sym)
                                
                                let assetYesterdayPice = Double(price)! - Double(changeValue)!
                                
                                let tickerYesterdayPrice = yesterdayPrice * assetYesterdayPice
                                
                                let changeUSD = (tickerUSDPrice - tickerYesterdayPrice) / tickerYesterdayPrice
                                
                                let changeBTC = NSDecimalNumber(string: change).dividing(by: NSDecimalNumber(value: 100))
                                
                                let ticker = ["symbol" : sym,
                                              "priceBTC" : price,
                                              "changeBTC" : changeBTC.stringValue,
                                              "priceUSDT" : tickerUSDPrice.description,
                                              "changeUSDT" : changeUSD.description]
                                    
                                    
//                                    Ticker(symbol: sym, priceUSDT: tickerUSDPrice.description, priceBTC: price, changeUSDT: changeUSD.description, changeBTC: changeBTC.stringValue)
                                tickers.append(ticker as [String : AnyObject])
                                
                            }
                        }
                    })
                    
                    completion(tickers)
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
    }
    
    func getCryptopiaTickers(completion: @escaping([[String : AnyObject]]?) -> Void) {
        
        var tickers = [[String:AnyObject]]()
        
        let session = URLSession.shared
        let url = URL(string: "https://www.cryptopia.co.nz/api/GetMarkets")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                completion(nil)
            }
            
            if let dat = data {
                
                do {
                    
                    var usdPrice: Double = 0
                    var yesterdayPrice: Double = 0
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : Any], let result = array["Data"] as? [[String : AnyObject]] else {return}
                    
                    
                    
                    _ = result.filter({ dict -> Bool in
                        if let symbol = dict["Label"] as? String {
                            if symbol == "BTC/USDT" {
                                return true
                            }
                        }
                        return false
                    }).map({ dict -> Void in
                        
                        if let price = dict["LastPrice"] as? Double, let change = dict["Change"] as? Double {
                           
                            usdPrice = price
                            yesterdayPrice = price * (1 - change / 100)
                            
                            
                            
                        }
                        
                    })
                    
                    _ = result.map({ dict -> Void in
                        if let symbol = dict["Label"] as? String, let price = dict["LastPrice"] as? Double, let change = dict["Change"] as? Double {
                            
                            if symbol.suffix(4) == "/BTC" {
                                
                                let sym = symbol.dropLast(4).description
                                print(sym)
                                let tickerUSDPrice = price * usdPrice
                                
//                                let changeBTC = (price - prevDay) / prevDay
                                
                                let priceBTC = NSDecimalNumber(value: price)
                                
                                
                                let assetYesterdayPice = price * (1 - change / 100)
                                
                                let tickerYesterdayPrice = yesterdayPrice * assetYesterdayPice
                                
                                let changeUSD = (tickerUSDPrice - assetYesterdayPice) / assetYesterdayPice
                                
                                //                                let changeBTC = NSDecimalNumber(string: change).dividing(by: NSDecimalNumber(value: 100))
                                
                                let ticker = ["symbol" : sym,
                                              "priceBTC" : priceBTC.stringValue,
                                              "changeBTC" : (change / 100).description,
                                              "priceUSDT" : tickerUSDPrice.description,
                                              "changeUSDT" : changeUSD.description]
                                
                                
                                //                                    Ticker(symbol: sym, priceUSDT: tickerUSDPrice.description, priceBTC: price, changeUSDT: changeUSD.description, changeBTC: changeBTC.stringValue)
                                tickers.append(ticker as [String : AnyObject])
                                
                            }
                        }
                    })
                    
                    
                    completion(tickers)
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
    }
    
    func getKucoinTickers(completion: @escaping([[String : AnyObject]]?) -> Void) {
        
        var tickers = [[String:AnyObject]]()
        
        let session = URLSession.shared
        let url = URL(string: "https://api.kucoin.com/v1/open/tick")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                completion(nil)
            }
            
            if let dat = data {
                
                do {
                    
                    var usdPrice: Double = 0
                    var yesterdayPrice: Double = 0
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : Any], let result = array["data"] as? [[String : AnyObject]] else {return}
                    
                    
                    
                    _ = result.filter({ dict -> Bool in
                        if let symbol = dict["symbol"] as? String {
                            if symbol == "BTC-USDT" {
                                return true
                            }
                        }
                        return false
                    }).map({ dict -> Void in
                        
                        if let price = dict["lastDealPrice"] as? Double, let change = dict["change"] as? Double {
                            
                            print(price)
                            print(change)
                            
                            usdPrice = price
                            yesterdayPrice = price - change
                            
                            
                            
                        }
                        
                    })
                    
                    _ = result.map({ dict -> Void in
                        if let symbol = dict["symbol"] as? String, let price = dict["lastDealPrice"] as? Double, let change = dict["change"] as? Double, let changeRate = dict["changeRate"] as? Double {
                            
                            if symbol.suffix(4) == "-BTC" {
                                
                                let sym = symbol.dropLast(4).description
                                print(sym)
                                let tickerUSDPrice = price * usdPrice
                                
                                
//                                let changeBTC = (price - prevDay) / prevDay
                                
                                let priceBTC = NSDecimalNumber(value: price)
                                
                                
                                let assetYesterdayPice = price - change
                                
                                let tickerYesterdayPrice = yesterdayPrice * assetYesterdayPice
                                
                                let changeUSD = (tickerUSDPrice - tickerYesterdayPrice) / tickerYesterdayPrice
                                
                                //                                let changeBTC = NSDecimalNumber(string: change).dividing(by: NSDecimalNumber(value: 100))
                                
                                let ticker = ["symbol" : sym,
                                              "priceBTC" : priceBTC.stringValue,
                                              "changeBTC" : changeRate.description,
                                              "priceUSDT" : tickerUSDPrice.description,
                                              "changeUSDT" : changeUSD.description]
                                
                                
                                //                                    Ticker(symbol: sym, priceUSDT: tickerUSDPrice.description, priceBTC: price, changeUSDT: changeUSD.description, changeBTC: changeBTC.stringValue)
                                tickers.append(ticker as [String : AnyObject])
                                
                            }
                        }
                    })
                    
                    
                    completion(tickers)
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
    }
    
    
    func getBittrexTickers(completion: @escaping([[String : AnyObject]]?) -> Void) {
        
        var tickers = [[String:AnyObject]]()
        
        let session = URLSession.shared
        let url = URL(string: "https://bittrex.com/api/v1.1/public/getmarketsummaries")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                completion(nil)
            }
            
            if let dat = data {
                
                do {
                    
                    var usdPrice: Double = 0
                    var yesterdayPrice: Double = 0
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : Any], let result = array["result"] as? [[String : AnyObject]] else {return}
                    
                   
                    
                    _ = result.filter({ dict -> Bool in
                        if let symbol = dict["MarketName"] as? String {
                            if symbol == "USDT-BTC" {
                                return true
                            }
                        }
                        return false
                    }).map({ dict -> Void in
                        
                        if let price = dict["Last"] as? Double, let prevDay = dict["PrevDay"] as? Double {
                        
                            
                            usdPrice = price
                            yesterdayPrice = prevDay
                            
                        }
                        
                    })
                    
                    _ = result.map({ dict -> Void in
                        if let symbol = dict["MarketName"] as? String, let price = dict["Last"] as? Double, let prevDay = dict["PrevDay"] as? Double {
                            
                            if symbol.prefix(4) == "BTC-" {
                                //                                print("\(symbol) - \(price) - \(change)")
                                
                                let sym = symbol.dropFirst(4).description
                                
                                let tickerUSDPrice = price * usdPrice
                                
                                let changeBTC = (price - prevDay) / prevDay
                                
                                let priceBTC = NSDecimalNumber(value: price)
                                
                                
                                let assetYesterdayPice = yesterdayPrice * price * prevDay
                                
//                                let tickerYesterdayPrice = yesterdayPrice * assetYesterdayPice
                                
                                let changeUSD = (tickerUSDPrice - assetYesterdayPice) / assetYesterdayPice
                                
//                                let changeBTC = NSDecimalNumber(string: change).dividing(by: NSDecimalNumber(value: 100))
                                
                                let ticker = ["symbol" : sym,
                                              "priceBTC" : priceBTC.stringValue,
                                              "changeBTC" : changeBTC.description,
                                              "priceUSDT" : tickerUSDPrice.description,
                                              "changeUSDT" : changeUSD.description]
                                
                                
                                //                                    Ticker(symbol: sym, priceUSDT: tickerUSDPrice.description, priceBTC: price, changeUSDT: changeUSD.description, changeBTC: changeBTC.stringValue)
                                tickers.append(ticker as [String : AnyObject])
                                
                            }
                        }
                    })
                    
 
                    completion(tickers)
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
    }
    
    func getHuobiTickers(completion: @escaping([[String : AnyObject]]?) -> Void) {
        
        var tickers = [[String:AnyObject]]()
        
        let session = URLSession.shared
        let url = URL(string: "http://api.huobi.pro/market/tickers")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                completion(nil)
            }
            
            if let dat = data {
                
                do {
                    
                    var usdPrice: Double = 0
                    var yesterdayPrice: Double = 0
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [String : Any], let result = array["data"] as? [[String : AnyObject]] else {return}
                    
                    
                    
                    _ = result.filter({ dict -> Bool in
                        if let symbol = dict["symbol"] as? String {
                            if symbol == "btcusdt" {
                                return true
                            }
                        }
                        return false
                    }).map({ dict -> Void in
                        
                        if let price = dict["close"] as? Double, let prevDay = dict["open"] as? Double {
                            
                            
                            usdPrice = price
                            yesterdayPrice = prevDay
                            
                        }
                        
                    })
                    
                    _ = result.map({ dict -> Void in
                        if let symbol = dict["symbol"] as? String, let price = dict["close"] as? Double, let prevDay = dict["open"] as? Double {
                            
                            if symbol.suffix(3) == "btc" {
                                //                                print("\(symbol) - \(price) - \(change)")
                             
                                let sym = symbol.dropLast(3).uppercased().description
                                
                                print(sym)
                                
                                
                                let tickerUSDPrice = price * usdPrice
                                
                                let changeBTC = (price - prevDay) / prevDay
                                
                                let priceBTC = NSDecimalNumber(value: price)
                                
                                
                                let assetYesterdayPice = yesterdayPrice * price * prevDay
                                
                                //                                let tickerYesterdayPrice = yesterdayPrice * assetYesterdayPice
                                
                                let changeUSD = (tickerUSDPrice - assetYesterdayPice) / assetYesterdayPice
                                
                                //                                let changeBTC = NSDecimalNumber(string: change).dividing(by: NSDecimalNumber(value: 100))
                                
                                let ticker = ["symbol" : sym,
                                              "priceBTC" : priceBTC.stringValue,
                                              "changeBTC" : changeBTC.description,
                                              "priceUSDT" : tickerUSDPrice.description,
                                              "changeUSDT" : changeUSD.description]
                                
                                
                                //                                    Ticker(symbol: sym, priceUSDT: tickerUSDPrice.description, priceBTC: price, changeUSDT: changeUSD.description, changeBTC: changeBTC.stringValue)
                                tickers.append(ticker as [String : AnyObject])
                                
                            }
                        }
                    })
                    
                    
                    completion(tickers)
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
    }
    
    
    func getHitBTCTickers(completion: @escaping([[String : AnyObject]]?) -> Void) {
        
        var tickers = [[String:AnyObject]]()
        
        let session = URLSession.shared
        let url = URL(string: "https://api.hitbtc.com/api/2/public/ticker")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
            if error != nil {
                completion(nil)
            }
            
            if let dat = data {
                
                do {
                    
                    var usdPrice: Double = 0
                    var yesterdayPrice: Double = 0
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [[String : AnyObject]] else {return}
        
                    _ = array.filter({ dict -> Bool in
                        if let symbol = dict["symbol"] as? String {
                            if symbol == "BTCUSD" {
                                return true
                            }
                        }
                        return false
                    }).map({ dict -> Void in
                        
                        if let price = dict["last"] as? String, let prevDay = dict["open"] as? String {

                           
                            usdPrice = Double(price)!
                            yesterdayPrice = Double(prevDay)!
                            
                        }
                        
                    })
                    
                    _ = array.map({ dict -> Void in
                        if let symbol = dict["symbol"] as? String, let price = dict["last"] as? String, let prevDay = dict["open"] as? String {
                            
                            if symbol.suffix(3) == "BTC" {
                                //                                print("\(symbol) - \(price) - \(change)")
                                
                                let sym = symbol.dropLast(3).description
                                
                                
                                let tickerUSDPrice = Double(price)! * usdPrice
                                
                                let changeBTC = (Double(price)! - Double(prevDay)!) / Double(prevDay)!
                                
                                let priceBTC = Double(price)!
                                
                                
                                let assetYesterdayPice = yesterdayPrice * Double(price)! * Double(prevDay)!
                                
                                //                                let tickerYesterdayPrice = yesterdayPrice * assetYesterdayPice
                                
                                let changeUSD = (tickerUSDPrice - assetYesterdayPice) / assetYesterdayPice
                                
                                //                                let changeBTC = NSDecimalNumber(string: change).dividing(by: NSDecimalNumber(value: 100))
                                
                                let ticker = ["symbol" : sym,
                                              "priceBTC" : priceBTC.description,
                                              "changeBTC" : changeBTC.description,
                                              "priceUSDT" : tickerUSDPrice.description,
                                              "changeUSDT" : changeUSD.description]
                                
                                
                                //                                    Ticker(symbol: sym, priceUSDT: tickerUSDPrice.description, priceBTC: price, changeUSDT: changeUSD.description, changeBTC: changeBTC.stringValue)
                                tickers.append(ticker as [String : AnyObject])
                                
                            }
                        }
                    })
                    
//                    print(tickers)
                    
                    completion(tickers)
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
    }
    
    
    
    func getCAP() {
        
        
        let session = URLSession.shared
        let url = URL(string: "https://api.coinmarketcap.com/v1/ticker/?limit=2500")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { (data, resp, error) in
            
           
            
            if let dat = data {
                
                do {
                    
                    guard let array = try JSONSerialization.jsonObject(with: dat, options: []) as? [[String : AnyObject]] else {return}
               
                    _ = array.map({ dict -> Void in
                        
                        let symbol = dict["symbol"] as! String
                        let name = dict["name"] as! String

                        print(name)
                        
                    })
                    
//                    print(array)
                    
                    
                } catch {
                    print("Error: cannot create JSON from todo")
                    return
                }
                
                
            }
            
            }.resume()
        
    }
}

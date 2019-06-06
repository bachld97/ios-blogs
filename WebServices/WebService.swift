import Foundation

class WebService {
    
    private let session: URLSession
    
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    
    func execute<T: Decodable>(
        request: Request,
        completion: @escaping (Result<T, Swift.Error>) -> Void,
        runCompletionOn queue: DispatchQueue = .main
    ) {
        guard let httpRequest = request.httpRequest else {
            return queue.async {
                completion(.failure(Error.badRequest))
            }
        }
        
        let networkDone: (Data?, URLResponse?, Swift.Error?) -> Void = { (data, _, error) in
            if let er = error {
                return queue.async {
                    completion(.failure(er))
                }
            }
            
            guard let data = data else {
                return queue.async {
                    completion(.failure(Error.noData))
                }
            }
            
            do {
                let decoder = JSONDecoder()
                let clientData = try decoder.decode(T.self, from: data)
                return queue.async {
                    completion(.success(clientData))
                }
            } catch {
                return queue.async {
                    completion(.failure(Error.cannotDecodeData))
                }
            }
        }
        
        let task = session.dataTask(with: httpRequest, completionHandler: networkDone)
        task.resume()
    }

    enum Method : String {
        case get = "GET"
        case post = "POST"
        // etc.
    }
    
    enum Error: Swift.Error {
        case badRequest
        case serverError
        case noData
        case cannotDecodeData
    }
    
    // TODO: Use builder pattern instead
    struct Request {
        let host: String
        let path: String
        let port: Int
        
        let params: [String : String]?
        let httpMethod: WebService.Method
        let cookies: String?
        let accessToken: String?
        
        
        init(
            host: String, path: String,
            params: [String: String]?,
            port: Int = 80,
            httpMethod: Method = .get,
            cookies: String? = nil,
            accessToken: String? = nil
        ) {
            self.host = host
            self.path = path
            self.params = params
            self.httpMethod = httpMethod
            self.cookies = cookies
            self.port = port
            self.accessToken = accessToken
        }
        
        private var encodedUrl: URL? {
            var components = URLComponents()
            components.scheme = "http"
            components.host = host
            components.path = path
            components.port = port
            
            components.queryItems = params?.map {
                URLQueryItem(name: $0, value: $1)
            }
            return components.url
        }
        
        var httpRequest: URLRequest? {
            guard let url = encodedUrl else {
                return nil
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod.rawValue
            if let cookies = cookies {
                request.httpShouldHandleCookies = true
                request.setValue(cookies, forHTTPHeaderField: "Cookie")
            }
            
            if let accessToken = accessToken {
                let bearer = "Bearer \(accessToken)"
                let authKey = "Authorization"
                request.setValue(bearer, forHTTPHeaderField: authKey)
            }
            
            return request
        }
    }
}

struct TokenInfo: Decodable {
    let accessToken: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

struct UserInfo: Decodable {
    let name: String
}

enum LoginResponse {
    case success(UserInfo, TokenInfo)
    case wrongPassword
    case userNotFound
    case unknownError
}

struct LoginApiResponse: Decodable {
    private let userNotFound: Bool
    private let wrongPassword: Bool
    private let tokenInfo: TokenInfo?
    private let userInfo: UserInfo?
    
    func toLoginResponse() -> LoginResponse {
        if userNotFound {
            return .userNotFound
        } else if wrongPassword {
            return .wrongPassword
        }
        
        if let tokenInfo = tokenInfo,
            let userInfo = userInfo {
            return .success(userInfo, tokenInfo)
        } else {
            return .unknownError
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case userNotFound = "user_not_found"
        case wrongPassword = "wrong_password"
        case tokenInfo = "token_info"
        case userInfo = "user_info"
    }
}

func onLogin(_ result: Result<LoginApiResponse, Error>) {
    switch result {
    case .success(let apiResponse):
        handleApiResponse(apiResponse)
    case .failure(let error):
        handleNetworkingError(error)
    }
}

func handleApiResponse(_ apiResponse: LoginApiResponse) {
    switch apiResponse.toLoginResponse() {
    case .wrongPassword:
        print("Wrong pass")
    case .userNotFound:
        print("Wrong username")
    case .success(let user, let token):
        print("Success: \(user.name) + \(token.accessToken)")
    case .unknownError:
        print("Unknown error, how to handle?")
    }
}

func handleNetworkingError(_ error: Error) {
    print(error)
}

let ws = WebService()
let params = [ "username" : "bachld", "password" : "12345678" ]
let request = WebService.Request(
    host: "127.0.0.1", path: "/auth/login/", params: params,
    port: 8000, httpMethod: .post
)

ws.execute(request: request, completion: onLogin(_:))

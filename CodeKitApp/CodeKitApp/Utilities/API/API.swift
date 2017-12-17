//
//  API.swift
//  CodeKitApp
//
//  Created by Kimkeeyun on 17/12/2017.
//  Copyright © 2017 yunari.me. All rights reserved.
//
import Foundation
import OAuthSwift
import SwiftyJSON
import Alamofire

protocol API {
    typealias IssueResponsesHandler = (DataResponse<[Model.Issue]>) -> Void
    func getToken(handler: @escaping (() -> Void))
    func tokenRefresh(handler: @escaping (() -> Void))
    func repoIssues(owner: String, repo: String) -> (Int, @escaping IssueResponsesHandler) -> Void
}

struct GitHubAPI: API {
    
    // MARK : - OAuth2Swift의 Instance를 만들어서 api call
    let oauth: OAuth2Swift = OAuth2Swift(consumerKey: "b48606d3e931721bff14",
                                         consumerSecret: "2caee40ef698bc1d500e33d5bd80b313bfa7e87f",
                                         authorizeUrl: "https://github.com/login/oauth/authorize",
                                         accessTokenUrl: "https://github.com/login/oauth/access_token",
                                         responseType: "code")
    
    func getToken(handler: @escaping (()->Void)) {
        oauth.authorize(withCallbackURL: "CodeKitApp://oauth-callback/github",
                        scope: "user, repo",
                        state: "state",
                        success: { (credential, response, parameters) in
                            let token = credential.oauthToken
                            let refreshToken = credential.oauthRefreshToken
                            GlobalState.shared.token = token
                            GlobalState.shared.refreshToken = refreshToken
                            handler()
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func tokenRefresh(handler: @escaping (()->Void)) {
        guard let refreshToken = GlobalState.shared.refreshToken else { return }
        oauth.renewAccessToken(withRefreshToken: refreshToken,
                               success: { (credential, _, _) in
                                let token = credential.oauthToken
                                let refreshToken = credential.oauthRefreshToken
                                GlobalState.shared.token = token
                                GlobalState.shared.refreshToken = refreshToken
                                handler()
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func repoIssues(owner: String, repo: String) -> (Int, @escaping IssueResponsesHandler) -> Void {
        return { (page, handler) in
            let parameters: Parameters = ["page": page, "state": "all"]
            GitHubRouter.manager.request(GitHubRouter.repoIssues(owner: owner, repo: repo, parameters: parameters)).responseSwiftyJSON { (dataResponse: DataResponse<JSON>) in
                let result = dataResponse.map({ (json: JSON) -> [Model.Issue] in
                    return json.arrayValue.map {
                        Model.Issue(json: $0)
                    }
                })
                handler(result)
            }
        }
    }
    
}
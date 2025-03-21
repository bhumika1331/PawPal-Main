//
//  SceneDelegate.swift
//  TabBarControllerPawPal
//
//  Created by user@61 on 06/11/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
 
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // Add a global tap gesture recognizer to dismiss the keyboard
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.cancelsTouchesInView = false
        window?.addGestureRecognizer(tapGesture)
        
        // Add a global swipe down gesture recognizer to dismiss the keyboard
        let swipeGesture = UISwipeGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        swipeGesture.direction = .down
        swipeGesture.cancelsTouchesInView = false
        window?.addGestureRecognizer(swipeGesture)
        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let testVC = storyboard.instantiateViewController(withIdentifier: "YourTestViewControllerID")
//        window?.rootViewController = testVC
//        window?.makeKeyAndVisible()
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let user = Auth.auth().currentUser {
            checkUserRole(userID: user.uid) { role in
                DispatchQueue.main.async {
                    switch role {
                    case "caretaker":
                        let caretakerVC = storyboard.instantiateViewController(withIdentifier: "CaretakerTabBarController") as? UITabBarController
                        self.window?.rootViewController = caretakerVC
                    case "dogwalker":
                        let dogwalkerVC = storyboard.instantiateViewController(withIdentifier: "CaretakerTabBarController") as? UITabBarController
                        self.window?.rootViewController = dogwalkerVC
                    default:
                        let userVC = storyboard.instantiateViewController(withIdentifier: "TabBarControllerID") as? UITabBarController
                        self.window?.rootViewController = userVC
                    }
                    self.window?.makeKeyAndVisible()
                }
            }
        } else {
            // If no user is logged in, show login screen
            let loginVC = storyboard.instantiateViewController(withIdentifier: "Start_screen")
            window?.rootViewController = loginVC
            window?.makeKeyAndVisible()
        }
    }

    func checkUserRole(userID: String, completion: @escaping (String) -> Void) {
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var role: String? = nil
        
        // Check caretakers collection
        group.enter()
        db.collection("caretakers").whereField("caretakerId", isEqualTo: userID).getDocuments { snapshot, error in
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                role = "caretaker"
            }
            group.leave()
        }
        
        // Check dogwalkers collection
        group.enter()
        db.collection("dogwalkers").whereField("dogWalkerId", isEqualTo: userID).getDocuments { snapshot, error in
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                role = "dogwalker"
            }
            group.leave()
        }
        
        // Notify when all checks are completed
        group.notify(queue: .main) {
            completion(role ?? "regular")
        }
    }


    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}


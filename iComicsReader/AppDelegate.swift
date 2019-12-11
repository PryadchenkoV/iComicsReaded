//
//  AppDelegate.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 23/10/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    var restrictRotation:UIInterfaceOrientationMask = .all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.restrictRotation
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.isFileURL {
            print("Import")
            ComicsGetter.shared.addComics(withPath: url.path)
        }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        let comicsGetter = ComicsGetter.shared
        if comicsGetter.arrayOfComics.count == 0 {
            comicsGetter.addComics(withPath: Bundle.main.path(forResource: "SecretWars00", ofType: "cbr")!)
            comicsGetter.addComics(withPath: Bundle.main.path(forResource: "Scott_Pilgrim_Vol_6", ofType: "cbz")!)
            comicsGetter.addComics(withPath: Bundle.main.path(forResource: "Astonishing X-Men #006", ofType: "cbr")!)

            comicsGetter.addComics(withPath: Bundle.main.path(forResource: "Darth Vader 05", ofType: "cbr")!)

//            comicsGetter.addComics(withPath: Bundle.main.url(forResource: "New Excalibur 007", ofType: "cbr")!)

            comicsGetter.addComics(withPath: Bundle.main.path(forResource: "Nightmask #03", ofType: "cbr")!)

//            comicsGetter.addComics(withPath: Bundle.main.url(forResource: "Blade v3 07", ofType: "cbr")!)

            comicsGetter.addComics(withPath: Bundle.main.path(forResource: "Vimanarama 03", ofType: "cbr")!)

            comicsGetter.addComics(withPath: Bundle.main.path(forResource: "Year 100 001", ofType: "cbr")!)

            
        }
        #endif
        
        if #available(iOS 13.0, *) {
            let largeTitleAppearance = UINavigationBarAppearance()
            largeTitleAppearance.configureWithOpaqueBackground()
            let standartAppearance = largeTitleAppearance.copy()
            largeTitleAppearance.shadowColor = nil
//            appearance.largeTitleTextAttributes = [ .foregroundColor : UIColor.clear ]
            UINavigationBar.appearance().standardAppearance = standartAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = largeTitleAppearance
            
            let toolBarAppearance = UIToolbarAppearance()
            toolBarAppearance.configureWithOpaqueBackground()
            UIToolbar.appearance().standardAppearance = toolBarAppearance
        }
        
        if let bundlePath = Bundle.main.path(forResource: "Preferences", ofType: "plist"),
            let destPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                               .userDomainMask,
                                                               true).first {
            let fileName = "Preferences.plist"
            let fullDestPath = URL(fileURLWithPath: destPath)
                .appendingPathComponent(fileName)
            let fullDestPathString = fullDestPath.path
            
            if !FileManager.default.fileExists(atPath: fullDestPathString) {
                do {
                    try FileManager.default.copyItem(atPath: bundlePath, toPath: fullDestPathString)
                }
                catch {
                    print("Can't copy Preferences.plist to document folder")
                }
            }
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "ComicData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        context.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}


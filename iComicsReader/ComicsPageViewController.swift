//
//  ComicsPageViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 26/05/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit
import CoreData

class ComicsPageViewController: UIPageViewController, UIPageViewControllerDelegate {

    var arrayOfViewControllers = [UIViewController]()
    var comicsInstance: NSManagedObject?
    var pageNumber = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        prepareArrayOfViewControllers()
        guard let lastReadedPage = comicsInstance?.value(forKey: "lastReadedPage") as? Int else {
            return
        }
        changeTitle(pageNumber: 0)
        let firstViewController = arrayOfViewControllers[lastReadedPage]
        setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        // Do any additional setup after loading the view.
    }
    
    func prepareArrayOfViewControllers() {
        if let comicsInstance = comicsInstance, let dataArray = comicsInstance.value(forKey: "data") as? [Data] {
            for (index,data) in dataArray.enumerated() {
                guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImageView") as? ImageViewController else {
                    print("[MainPageViewController] Can't create ImageViewController")
                    continue
                }
                viewController.pageNumber = index
                viewController.pageCount = dataArray.count
                viewController.image = UIImage(data: data)
                arrayOfViewControllers.append(viewController)
            }
        }
        
//        if let id = image.value(forKey: "id") as? String {
//            viewController.id = id
//        }
//        arrayOfViewControllers.append(viewController)
    }
}

extension ComicsPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = arrayOfViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard arrayOfViewControllers.count > previousIndex else {
            return nil
        }
        pageNumber = previousIndex
        changeTitle(pageNumber: pageNumber)
        return arrayOfViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = arrayOfViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        let arrayCount = arrayOfViewControllers.count
        
        guard arrayCount != nextIndex else {
            return nil
        }
        
        guard arrayCount > nextIndex else {
            return nil
        }
        pageNumber = nextIndex
        changeTitle(pageNumber: pageNumber)
        return arrayOfViewControllers[nextIndex]
    }
    
    func changeTitle(pageNumber: Int) {
        DispatchQueue.main.async {
            self.title = String(format: NSLocalizedString("%d of %d", comment: ""), pageNumber + 1, self.arrayOfViewControllers.count)
        }
    }
    
}

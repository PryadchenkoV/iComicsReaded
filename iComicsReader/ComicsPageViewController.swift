//
//  ComicsPageViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 26/05/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit
import CoreData

class ComicsPageViewController: UIPageViewController {

    var arrayOfViewControllers = [UIViewController]()
    var comicsInstance: NSManagedObject?
    var comicsUUID: UUID?
    var pageNumber = 0
    var bufIndex = 0
    var buttonShowMenuPopover: UIBarButtonItem?
    
    var isManga: Bool {
        guard let type = comicsInstance?.value(forKey: "type") as? String else {
            return false
        }
        return type == "Manga"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate, let uuid = comicsUUID else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Comics")
        
        fetchRequest.predicate = NSPredicate(format: "uuid = %@",
                                             argumentArray: [uuid])
        do {
            comicsInstance = try managedContext.fetch(fetchRequest).first as? NSManagedObject
        } catch {
            print("[ComicsPageViewController]: Error while fetching request")
        }
        
        prepareArrayOfViewControllers()
        guard let lastReadedPage = comicsInstance?.value(forKey: "lastReadedPage") as? Int else {
            return
        }
        
        changeTitle(pageNumber: lastReadedPage)
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.toolbar.isHidden = false
        
        navigationController?.setToolbarHidden(self.navigationController!.isNavigationBarHidden, animated: false)
        buttonShowMenuPopover = UIBarButtonItem(image: #imageLiteral(resourceName: "DotBurger"), style: .plain, target: self, action: #selector(showMenuPopover(_:)))
        let moreInfoButton = UIButton(type: .system)
        moreInfoButton.setImage(#imageLiteral(resourceName: "DotBurger"), for: .normal)
        moreInfoButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        moreInfoButton.addTarget(self, action: #selector(showMenuPopover(_:)), for: .touchUpInside)
        buttonShowMenuPopover!.customView = moreInfoButton
        
        self.toolbarItems = [buttonShowMenuPopover!]
        var pageToDisplay = lastReadedPage
        
        if isManga {
            pageToDisplay = arrayOfViewControllers.count - 1 - lastReadedPage
            arrayOfViewControllers.reverse()
        }
        
        if arrayOfViewControllers.count > lastReadedPage {
            setViewControllers([arrayOfViewControllers[pageToDisplay]], direction: isManga ? .reverse : .forward, animated: true, completion: nil)
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate, let uuid = comicsUUID else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let batchRequest = NSBatchUpdateRequest(entityName: "Comics")
        batchRequest.predicate = NSPredicate(format: "uuid = %@",
                                             argumentArray: [uuid])
        batchRequest.propertiesToUpdate = [#keyPath(Comics.lastReadedPage) : pageNumber]
        batchRequest.affectedStores = managedContext.persistentStoreCoordinator?.persistentStores
        
        batchRequest.resultType = .updatedObjectsCountResultType
        
        do {
            _ = try managedContext.execute(batchRequest)
        } catch {
            print("Batch Failed: \(error)")
        }
    }
    
    func prepareArrayOfViewControllers() {
        if let comicsInstance = comicsInstance, let data = comicsInstance.value(forKey: "arrayOfData") as? Data, let arrayOfData = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Data] {
                for (index,data) in arrayOfData.enumerated() {
                    guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImageView") as? ImageViewController else {
                        print("[MainPageViewController] Can't create ImageViewController")
                        continue
                    }
                    viewController.pageNumber = index
                    viewController.pageCount = arrayOfData.count
                    viewController.image = UIImage(data: data)
                    arrayOfViewControllers.append(viewController)
                }
        }
    }
    
    @IBAction func showSliderButtonPushed(_ sender: Any) {
    }
    
    @IBAction func showMenuPopover(_ sender: Any) {
        guard let popVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PopoverComicsSettings") as? PopoverMenuViewController else { return }
        popVC.modalPresentationStyle = .popover
        
        popVC.isManga = isManga
        popVC.uuid = comicsUUID
        let popOverVC = popVC.popoverPresentationController
        popOverVC?.delegate = self
        popOverVC?.sourceView = buttonShowMenuPopover!.customView
        popOverVC?.sourceRect = CGRect(x: (buttonShowMenuPopover!.customView?.bounds.midX)!, y: (buttonShowMenuPopover!.customView?.bounds.minY)!, width: 0, height: 0)
        popOverVC?.barButtonItem = buttonShowMenuPopover
        popOverVC?.permittedArrowDirections = .down
        popVC.completionBlock = {
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: {
                self.buttonShowMenuPopover!.customView?.transform = CGAffineTransform(rotationAngle: 0)
            })
        }
        
        
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: {
            self.buttonShowMenuPopover!.customView?.transform = CGAffineTransform(rotationAngle: 90 * .pi / 180)
        })
        self.present(popVC, animated: true)
    }
    
    func changeTitle(pageNumber: Int) {
        DispatchQueue.main.async {
            if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
                self.title = String(format: NSLocalizedString("%d-%d of %d", comment: ""), pageNumber + 1, pageNumber + 2,  self.arrayOfViewControllers.count)
            } else {
                self.title = String(format: NSLocalizedString("%d of %d", comment: ""), pageNumber + 1, self.arrayOfViewControllers.count)
            }
        }
    }
    
}

extension ComicsPageViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: {
            self.buttonShowMenuPopover!.customView?.transform = CGAffineTransform(rotationAngle: 0)
        })
    }
}

extension ComicsPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if isManga {
                pageNumber = arrayOfViewControllers.count - 1 - bufIndex
            } else {
                pageNumber = bufIndex
            }
            changeTitle(pageNumber: pageNumber)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        if orientation.isPortrait {
            guard let currentViewController = pageViewController.viewControllers?.first else {
                return .none
            }
            setViewControllers([currentViewController], direction: isManga ? .reverse : .forward, animated: true, completion: nil)
            if isManga {
                return .max
            } else {
                return .min
            }
        } else {
            guard let currentViewController = pageViewController.viewControllers?.first, let indexOfController = arrayOfViewControllers.firstIndex(of: currentViewController) else {
                return .none
            }
            if indexOfController < arrayOfViewControllers.count {
                var indexOfSecondImage = indexOfController + 1
                if isManga {
                    indexOfSecondImage -= 2
                }
                setViewControllers([arrayOfViewControllers[indexOfController], arrayOfViewControllers[indexOfSecondImage]], direction: isManga ? .reverse : .forward, animated: true, completion: nil)
                return .mid
            } else {
                return .none
            }
        }
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
        
        if (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) && (previousIndex + 2 < 0 || previousIndex - 2 > arrayOfViewControllers.count){
            return nil
        }
        bufIndex = previousIndex
        return arrayOfViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = arrayOfViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        let arrayCount = arrayOfViewControllers.count
        
        guard arrayCount > nextIndex else {
            return nil
        }
        
        guard nextIndex >= 0 else {
            return nil
        }
        
        if (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) && (nextIndex - 2 < 0 || nextIndex + 2 > arrayOfViewControllers.count) {
            return nil
        }
        
        bufIndex = nextIndex
        return arrayOfViewControllers[nextIndex]
    }
    
}

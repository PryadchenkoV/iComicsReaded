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
    var comicsUUID: UUID?
    var pageNumber = 0
    var buttonShowMenuPopover: UIBarButtonItem?
    
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
        changeTitle(pageNumber: 0)
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
        
        if arrayOfViewControllers.count > lastReadedPage {
        let firstViewController = arrayOfViewControllers[lastReadedPage]
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        // Do any additional setup after loading the view.
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
        guard let type = comicsInstance?.value(forKey: "type") as? String else {
            return
        }
        
        popVC.isManga = type == "Manga"
        popVC.uuid = comicsUUID
        let popOverVC = popVC.popoverPresentationController
        popOverVC?.delegate = self
        popOverVC?.sourceView = buttonShowMenuPopover!.customView
        popOverVC?.sourceRect = CGRect(x: (buttonShowMenuPopover!.customView?.bounds.midX)!, y: (buttonShowMenuPopover!.customView?.bounds.minY)!, width: 0, height: 0)
        popOverVC?.barButtonItem = buttonShowMenuPopover
        popOverVC?.permittedArrowDirections = .down
        //        popVC.comicsName = fileName
        popVC.preferredContentSize = CGSize(width: 350, height: 300)
        
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: {
            self.buttonShowMenuPopover!.customView?.transform = CGAffineTransform(rotationAngle: 90 * .pi / 180)
        })
        
        self.present(popVC, animated: true)
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

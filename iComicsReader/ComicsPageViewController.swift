//
//  ComicsPageViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 26/05/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit
import CoreData

protocol ComicsPageViewControllerDelegate {
    func comicsPageViewController(_ controller: ComicsPageViewController, didSelect action: UIPreviewAction, for previewController: UIViewController)
}

class ComicsPageViewController: UIPageViewController {

    // MARK: Variables
    var arrayOfViewControllers = [UIViewController]()
    var comicsInstance: NSManagedObject?
    var comicsUUID: UUID?
    var pageNumber = 0
    var bufIndex = 0
    var buttonShowMenuPopover: UIBarButtonItem?
    var buttonShowSlider: UIBarButtonItem?
    var sliderChangePage: UISlider?
    var blurView: UIVisualEffectView?
    var labelPageNumber = UILabel()
    var hidePageNumberViewTask: DispatchWorkItem?
    var sliderView: UIView?
    var sliderViewBottomConstraint: NSLayoutConstraint?
    
    var comicsDelegate: ComicsPageViewControllerDelegate?

    var isManga: Bool {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate, let uuid = comicsUUID else {
                return false
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Comics")
        
        fetchRequest.predicate = NSPredicate(format: "uuid = %@",
                                             argumentArray: [uuid])
        do {
            let instance = try managedContext.fetch(fetchRequest).first as? NSManagedObject
            guard let type = instance?.value(forKey: "type") as? String else {
                return false
            }
            return type == "Manga"
        } catch {
            print("[ComicsPageViewController]: Error while fetching request")
        }
        return false
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let delete = UIPreviewAction(title: "Delete", style: .destructive) {(action,controller) in
            self.comicsDelegate?.comicsPageViewController(self, didSelect: action, for: controller)
        }
        return [delete]
    }
    
    // MARK: Defualt functions
    
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
        
        var pageToDisplay = lastReadedPage
        pageNumber = lastReadedPage
        
        if isManga {
            pageToDisplay = arrayOfViewControllers.count - 1 - lastReadedPage
            arrayOfViewControllers.reverse()
        }
        
        if arrayOfViewControllers.count > lastReadedPage {
            setViewControllers([arrayOfViewControllers[pageToDisplay]], direction: isManga ? .reverse : .forward, animated: true, completion: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(typeDidChange(_:)), name: kNotificationNameComicsTypeChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDidChangeOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showSliderButtonPushed(_:)), name: kNotificationNameToolbarHidden, object: nil)
        
        ComicsGetter.shared.addComicsToRecent(withUUID: uuid)
        
        initPageNumberView()
        initBarButtons()
        initSliderView()
        
    }
    
    override func viewDidLayoutSubviews() {
        for subview in self.view.subviews {
            if subview == blurView || subview == sliderView  {
                self.view.bringSubviewToFront(subview)
            }
        }
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
        batchRequest.propertiesToUpdate = [#keyPath(Comics.lastReadedPage) : pageNumber, #keyPath(Comics.isNew) : false]
        batchRequest.affectedStores = managedContext.persistentStoreCoordinator?.persistentStores
        
        batchRequest.resultType = .updatedObjectsCountResultType
        
        do {
            _ = try managedContext.execute(batchRequest)
        } catch {
            print("Batch Failed: \(error)")
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func deviceDidChangeOrientation() {
        guard let toolbarWidth = self.navigationController?.toolbar.frame.width else {
            print("\(#function) toolbar width is nil")
            return
        }
        
        print(toolbarWidth)
    }
    
    // MARK: Init custom views
    
    func initPageNumberView() {
        let blur = UIBlurEffect(style: .regular)
        blurView = UIVisualEffectView(effect: blur)
        blurView?.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        blurView?.translatesAutoresizingMaskIntoConstraints = false
        blurView?.layer.cornerRadius = 20.0
        blurView?.layer.masksToBounds = true
        labelPageNumber.font = UIFont.systemFont(ofSize: 50.0, weight: .semibold)
        if let page = self.sliderChangePage?.value {
            labelPageNumber.text = String(page)
        }
        self.sliderChangePage?.transform = CGAffineTransform(rotationAngle: .pi)
        labelPageNumber.textAlignment = .center
        labelPageNumber.translatesAutoresizingMaskIntoConstraints = false
        blurView?.contentView.addSubview(labelPageNumber)
        
        labelPageNumber.widthAnchor.constraint(equalToConstant: 150).isActive = true
        labelPageNumber.heightAnchor.constraint(equalToConstant: 80).isActive = true
        labelPageNumber.centerXAnchor.constraint(equalTo: blurView!.centerXAnchor).isActive = true
        labelPageNumber.centerYAnchor.constraint(equalTo: blurView!.centerYAnchor).isActive = true
        
        blurView?.center = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
        hidePageNumberViewTask = DispatchWorkItem {
            UIView.animate(withDuration: 0.3, animations: {
                self.blurView!.alpha = 0.0
            }, completion: { (_) in
                self.blurView?.removeFromSuperview()
            })
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
    
    func initBarButtons() {
        buttonShowMenuPopover = UIBarButtonItem(image: #imageLiteral(resourceName: "DotBurger"), style: .plain, target: self, action: #selector(showMenuPopover(_:)))
        buttonShowSlider = UIBarButtonItem(image: #imageLiteral(resourceName: "SliderShow"), style: .plain, target: self, action: #selector(showSliderButtonPushed(_:)))
        
        self.setDefaultToolbar(nil)
        
    }
    
    func initSliderView() {
        
        sliderChangePage = UISlider()
        sliderChangePage?.maximumValue = Float(arrayOfViewControllers.count - 1)
        sliderChangePage?.value = Float(pageNumber)
        sliderChangePage?.addTarget(self, action: #selector(changePageWithSlider(_:)), for: .touchUpInside)
        sliderChangePage?.addTarget(self, action: #selector(changeTrumbPosition(_:)), for: .valueChanged)
        
        sliderView = UIView(frame: CGRect(x: 200, y: 200, width: 300, height: 46))
        sliderView!.translatesAutoresizingMaskIntoConstraints = false
        sliderView!.backgroundColor = .systemBackground
        sliderView!.layer.borderWidth = 0.5
        sliderView!.layer.borderColor = UIColor.separator.cgColor
        sliderView!.addSubview(sliderChangePage!)
        sliderChangePage?.translatesAutoresizingMaskIntoConstraints = false
        sliderChangePage?.topAnchor.constraint(equalTo: sliderView!.topAnchor, constant: 8).isActive = true
        sliderChangePage?.bottomAnchor.constraint(equalTo: sliderView!.bottomAnchor, constant: -8).isActive = true
        sliderChangePage?.leadingAnchor.constraint(equalTo: sliderView!.leadingAnchor, constant: 16).isActive = true
        sliderChangePage?.trailingAnchor.constraint(equalTo: sliderView!.trailingAnchor, constant: -16).isActive = true
        self.view.addSubview(sliderView!)
        sliderView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sliderView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sliderViewBottomConstraint = sliderView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 100)
        sliderViewBottomConstraint!.isActive = true
    }
    
    func addBlurView() {
        self.view.addSubview(blurView!)
                
        blurView?.widthAnchor.constraint(equalToConstant: 150).isActive = true
        blurView?.heightAnchor.constraint(equalToConstant: 80).isActive = true
        blurView?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        blurView?.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -140
        ).isActive = true
        blurView?.alpha = 0.0
    }
    
    // MARK: Help functions
    
    @objc func typeDidChange(_ notification: Notification) {
        arrayOfViewControllers.reverse()
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
    
    // MARK: IBActions
    
    @IBAction func changeTrumbPosition(_ sender: UISlider) {
        if let task = hidePageNumberViewTask, task.isCancelled {
            task.cancel()
        }
        if let blurView = blurView {
            if blurView.superview == nil {
                UIView.animate(withDuration: 0.3) {
                    self.addBlurView()
                    blurView.alpha = 1.0
                }
            }
            labelPageNumber.text = String(Int(sender.value + 1))
        }
    }
    
    @IBAction func changePageWithSlider(_ sender: UISlider) {
        setViewControllers([arrayOfViewControllers[Int(sender.value)]], direction: isManga ? .reverse : .forward, animated: true, completion: nil)
        self.changeTitle(pageNumber: Int(sender.value))
        if let task = hidePageNumberViewTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
        }
    }
    
    @IBAction func showSliderButtonPushed(_ sender: Any) {
            if let constant = self.sliderViewBottomConstraint?.constant, constant == 0 {
                self.sliderViewBottomConstraint?.constant = 80
                DispatchQueue.main.async {
                    self.buttonShowSlider?.image = #imageLiteral(resourceName: "SliderShow")
                }
            } else if sender is UIBarButtonItem {
                self.sliderViewBottomConstraint?.constant = 0
                DispatchQueue.main.async {
                    self.buttonShowSlider?.image = #imageLiteral(resourceName: "Hide")
                }
            }
        UIView.animate(withDuration: 0.3, animations: {
            if self.sliderViewBottomConstraint!.constant == 0 {
                self.sliderView?.isHidden = false
            }
            self.view.layoutIfNeeded()
        }) { (_) in
            if self.sliderViewBottomConstraint!.constant != 0 {
                self.sliderView?.isHidden = true
            }
        }
    }
    
    @IBAction func showMenuPopover(_ sender: Any) {
        guard let popVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PopoverComicsSettings") as? PopoverMenuViewController else { return }
        popVC.modalPresentationStyle = .formSheet
        popVC.uuid = self.comicsUUID
        popVC.isManga = self.isManga
        self.present(popVC, animated: true)
    }
    
    @IBAction func setDefaultToolbar(_ sender: Any?) {
        let flexibleSpace = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([flexibleSpace, buttonShowMenuPopover!, flexibleSpace, buttonShowSlider!], animated: true)
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
            sliderChangePage?.value = Float(pageNumber)
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

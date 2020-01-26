/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that lists all generic password keychain items who's service and access group match those specified in `KeychainConfiguration`.
 */

import UIKit

class AccountsViewController: UITableViewController {
    
    let cellReuseIdentifier = "Cell"
    var passwordItems = [KeychainPasswordItem]()
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localize the title using app-specific localizations.
        navigationItem.title = NSLocalizedString("AccountsViewControllerTitle", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.populateTableView()
    }
    
    private func populateTableView() {
        /*
         Make sure the table view is up-to-date by first reloading the
         password items from the keychain and then reloading the table view.
         */
        do {
            passwordItems = try KeychainPasswordItem.passwordItems(forService: KeychainConfiguration.serviceName, accessGroup: KeychainConfiguration.accessGroup)
        }
        catch {
            fatalError("Error fetching password items - \(error)")
        }
        
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let navigationController = segue.destination as? UINavigationController,
            let accountViewController = navigationController.children.first as? AccountDetailsViewController {
            
            if let indexPath = tableView.indexPathForSelectedRow {
                
                /*
                 Set the account name on the `AccountDetailsViewController` that
                 is about to be displayed to the account name of the selected cell.
                 */
                let passwordItem = passwordItems[indexPath.row]
                accountViewController.accountName = passwordItem.account
                
            } else {
                accountViewController.saveCompletionHandler = { [weak self] in
                    if let self = self {
                        self.populateTableView()
                    }
                }
            }
        }
    }
    
    // MARK: Unwind segues
    
    @IBAction func unwindToAccountsView(_ segue: UIStoryboardSegue) {
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return passwordItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        let passwordItem = passwordItems[indexPath.row]
        
        cell.textLabel?.text = passwordItem.account
        
        return cell
    }
    
    // MARK: UITableViewDataDelegate
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            
            // Try to delete the item from the keychain.
            let passwordItem = self.passwordItems[indexPath.row]
            do {
                try passwordItem.deleteItem()
            }
            catch {
                fatalError("Error deleting keychain item - \(error)")
            }
            
            // Delete the item from the `passwordItems` array.
            self.passwordItems.remove(at: indexPath.row)
            
            // Delete the item from the table view
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let swipeActionConfiguration = UISwipeActionsConfiguration(actions: [deleteAction])
        return swipeActionConfiguration
    }
}


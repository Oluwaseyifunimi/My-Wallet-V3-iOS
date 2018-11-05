//
//  TransactionsXlmDataProvider.swift
//  Blockchain
//
//  Created by kevinwu on 10/22/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

class TransactionsXlmDataProvider: SimpleListDataProvider {
    
    override func registerAllCellTypes() {
        guard let table = tableView else { return }
        let loadingCell = UINib(nibName: LoadingTableViewCell.identifier, bundle: nil)
        let transactionCell = UINib(nibName: TransactionTableCell.identifier, bundle: nil)
        table.register(loadingCell, forCellReuseIdentifier: LoadingTableViewCell.identifier)
        table.register(transactionCell, forCellReuseIdentifier: TransactionTableCell.identifier)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isPaging ? LoadingTableViewCell.height() : 64.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let loadingIdentifier = LoadingTableViewCell.identifier
        
        switch indexPath.section {
        case 0:
            guard let items = models else { return UITableViewCell() }
            
            if items.count > indexPath.row {
                guard let model = items[indexPath.row] as? StellarOperation else { return UITableViewCell() }
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: model.cellType().identifier,
                    for: indexPath
                    ) as? TransactionTableCell else { return UITableViewCell() }
                /// This particular cell shouldn't have a separator.
                /// This is how we hide it.
                cell.separatorInset = UIEdgeInsets(
                    top: 0.0,
                    left: 0.0,
                    bottom: 0.0,
                    right: .greatestFiniteMagnitude
                )
                
                if case let .payment(payment) = model {
                    let viewModel = TransactionDetailViewModel(xlmTransaction: payment)
                    cell.configure(with: viewModel)
                }
                
                if case let .accountCreated(created) = model {
                    let viewModel = TransactionDetailViewModel(xlmTransaction: created)
                    cell.configure(with: viewModel)
                }
                
                cell.selectionStyle = .none
                
                cell.amountButtonSelected = { [weak self] in
                    guard let this = self else { return }
                    this.delegate?.dataProvider(this, didSelect: model)
                }
                
                return cell
            }
            
            if indexPath.row == items.count && isPaging {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: loadingIdentifier,
                    for: indexPath
                    ) as? LoadingTableViewCell else { return UITableViewCell() }
                
                /// This particular cell shouldn't have a separator.
                /// This is how we hide it.
                cell.separatorInset = UIEdgeInsets(
                    top: 0.0,
                    left: 0.0,
                    bottom: 0.0,
                    right: .greatestFiniteMagnitude
                )
                return cell
            }
            
        default:
            break
        }
        
        return UITableViewCell()
    }
}

//
//  ActivitySkeletonTableViewCell.swift
//  Blockchain
//
//  Created by Alex McGregor on 5/13/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformUIKit

final class ActivitySkeletonTableViewCell: UITableViewCell {
    
    // MARK: - Private IBOutlets
    
    @IBOutlet private var badgeContainerView: UIView!
    @IBOutlet private var titleContainerView: UIView!
    @IBOutlet private var subtitleContainerView: UIView!
    
    // MARK: - Private Properties (ShimmeringView)
    
    private var badgeContainerShimmeringView: ShimmeringView!
    private var titleContainerShimmeringView: ShimmeringView!
    private var subtitleContainerShimmeringView: ShimmeringView!
    
    // MARK: - Setup
    
    override func awakeFromNib() {
        super.awakeFromNib()
        badgeContainerShimmeringView = .init(
            in: self,
            centeredIn: badgeContainerView,
            size: badgeContainerView.bounds.size,
            cornerRadius: 16.0
        )
        titleContainerShimmeringView = .init(
            in: self,
            centeredIn: titleContainerView,
            size: titleContainerView.bounds.size,
            cornerRadius: 4.0
        )
        subtitleContainerShimmeringView = .init(
            in: self,
            centeredIn: subtitleContainerView,
            size: subtitleContainerView.bounds.size,
            cornerRadius: 4.0
        )
    }
}

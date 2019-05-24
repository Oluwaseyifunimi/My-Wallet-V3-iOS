//
//  LocationSuggestionCoordinator.swift
//  Blockchain
//
//  Created by Alex McGregor on 7/26/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import PlatformKit

protocol LocationSuggestionCoordinatorDelegate: class {
    func coordinator(_ locationCoordinator: LocationSuggestionCoordinator, updated model: LocationSearchResult)
    func coordinator(_ locationCoordinator: LocationSuggestionCoordinator, generated address: PostalAddress)
}

class LocationSuggestionCoordinator: NSObject {

    fileprivate let service: LocationSuggestionService
    fileprivate let api: LocationUpdateAPI
    fileprivate var model: LocationSearchResult {
        didSet {
            delegate?.coordinator(self, updated: model)
        }
    }
    fileprivate weak var delegate: LocationSuggestionCoordinatorDelegate?
    fileprivate weak var interface: LocationSuggestionInterface?

    init(_ delegate: LocationSuggestionCoordinatorDelegate, interface: LocationSuggestionInterface) {
        self.service = LocationSuggestionService()
        self.api = LocationUpdateService()
        self.delegate = delegate
        self.interface = interface
        self.model = .empty
        super.init()

        if let controller = delegate as? KYCAddressController {
            controller.searchDelegate = self
        }
    }
}

extension LocationSuggestionCoordinator: SearchControllerDelegate {

    func onStart() {
        interface?.primaryButton(.hidden)
        switch model.suggestions.isEmpty {
        case true:
            interface?.searchFieldText(nil)
            interface?.suggestionsList(.hidden)
            interface?.termsOfServiceDisclaimer(.visible)
            interface?.addressEntryView(.visible)
        case false:
            interface?.termsOfServiceDisclaimer(.hidden)
            interface?.suggestionsList(.visible)
            interface?.addressEntryView(.hidden)
        }
    }

    func onSubmission(_ selection: SearchSelection) {
        var newModel = model
        newModel.state = .loading
        model = newModel

        if let input = selection as? LocationSuggestion {
            service.fetchAddress(from: input) { (address) in
                // TODO: May no longer be necessary 
            }
        }
    }

    func onSelection(_ selection: SearchSelection) {
        if let input = selection as? LocationSuggestion {
            interface?.searchFieldText("")
            interface?.suggestionsList(.hidden)
            interface?.updateActivityIndicator(.visible)
            service.fetchAddress(from: input) { [weak self] (address) in
                guard let this = self else { return }
                this.interface?.termsOfServiceDisclaimer(.visible)
                this.interface?.addressEntryView(.visible)
                this.interface?.primaryButton(.visible)
                this.interface?.updateActivityIndicator(.hidden)
                this.interface?.searchFieldActive(false)
                this.interface?.populateAddressEntryView(address)
            }
        }
    }

    func onSubmission(_ address: UserAddress, completion: @escaping () -> Void) {
        interface?.primaryButtonActivityIndicator(.visible)
        interface?.primaryButtonEnabled(false)
        api.updateAddress(address: address) { [weak self] (error) in
            guard let this = self else { return }
            this.interface?.primaryButtonActivityIndicator(.hidden)
            this.interface?.primaryButtonEnabled(true)

            if let err = error {
                // TODO: Error state
                Logger.shared.error("\(err)")
            } else {
                completion()
            }
        }
    }

    func onSubmission(_ address: PostalAddress) {
        delegate?.coordinator(self, generated: address)
    }

    func onSearchRequest(_ query: String) {
        var newModel = model
        newModel.state = .loading
        model = newModel

        if model.suggestions.isEmpty {
            interface?.addressEntryView(.hidden)
            interface?.updateActivityIndicator(.visible)
        }

        if service.isExecuting {
            service.cancel()
        }

        service.search(for: query) { [weak self] (suggestions, error) in
            guard let this = self else { return }

            let state: LocationSearchResult.SearchUIState = error != nil ? .error(error) : .success
            let empty: [LocationSuggestion] = []

            let result = LocationSearchResult(
                state: state,
                suggestions: suggestions ?? empty
            )

            let listVisibility: Visibility = suggestions != nil ? .visible: .hidden
            let termsVisibility: Visibility = suggestions != nil ? .hidden: .visible
            this.interface?.updateActivityIndicator(.hidden)
            this.interface?.suggestionsList(listVisibility)
            this.interface?.termsOfServiceDisclaimer(termsVisibility)
            this.model = result
        }
    }

    func onSearchViewCancel() {
        interface?.searchFieldActive(false)
        interface?.suggestionsList(.hidden)
        interface?.termsOfServiceDisclaimer(.visible)
        interface?.primaryButton(.visible)
        interface?.addressEntryView(.visible)
        guard service.isExecuting else { return }
        service.cancel()
    }
}

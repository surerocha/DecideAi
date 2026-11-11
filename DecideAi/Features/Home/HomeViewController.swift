//
//  HomeViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// Temporary placeholder, only to validate the programmatic setup.
/// It will be replaced by the real Home in Stage 2.
final class HomeViewController: UIViewController {

    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.Color.background
        title = "Decide Aí"

        titleLabel.text = "Decide Aí"
        // Fonte semântica + adjustsFontForContentSizeCategory = Dynamic Type.
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true

        // Obrigatório ao usar Auto Layout em código: desliga a conversão
        // automática de autoresizing mask em constraints.
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

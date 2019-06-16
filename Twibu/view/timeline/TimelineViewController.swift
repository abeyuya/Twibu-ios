//
//  TimelineViewController.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/16.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit

final class TimelineViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private let dummyData = [
        "あいうえお",
        "かきくけこ",
        "さしすせそ"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(
            UINib.init(nibName: "TimelineCell", bundle: nil),
            forCellReuseIdentifier: "TimelineCell"
        )
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension TimelineViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummyData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineCell") as? TimelineCell else {
            return UITableViewCell()
        }

        cell.titleLabel.text = dummyData[indexPath.row]
        return cell
    }
}

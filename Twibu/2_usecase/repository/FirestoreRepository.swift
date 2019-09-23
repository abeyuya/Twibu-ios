//
//  FirestoreRepositoryPagingInfo.swift
//  Twibu
//
//  Created by abeyuya on 2019/09/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded
import FirebaseFirestore

struct FirestoreRepositoryPagingInfo: RepositoryPagingInfo {
    let lastSnapshot: DocumentSnapshot?
}

typealias FirestoreRepo = Repository<FirestoreRepositoryPagingInfo>

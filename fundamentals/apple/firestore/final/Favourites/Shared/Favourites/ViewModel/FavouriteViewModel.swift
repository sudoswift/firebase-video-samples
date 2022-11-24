//
// FavouritesViewModel.swift
// Favourites (iOS)
//
// Created by Peter Friese on 24.11.22.
// Copyright © 2021 Google LLC. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import SwiftUI
import Combine
import FirebaseAnalytics
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class FavouriteViewModel: ObservableObject {
  @Published var favourite = Favourite.empty

  @Published private var user: User?
  private var db = Firestore.firestore()
  private var cancellables = Set<AnyCancellable>()

  init() {
    registerAuthStateHandler()

//    $favourite
//      .sink { favourite in
//        print("Value updated: \(favourite)")
//        self.saveFavourite()
//      }
//      .store(in: &cancellables)

    $user
      .compactMap { $0 }
      .sink { user in
        self.favourite.userId = user.uid
      }
      .store(in: &cancellables)
  }

  private var authStateHandler: AuthStateDidChangeListenerHandle?

  func registerAuthStateHandler() {
    if authStateHandler == nil {
      authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
        self.user = user
      }
    }
  }

  func fetchFavourite() {
    guard let uid = Auth.auth().currentUser?.uid else { return }

    Task {
      do {
        let querySnapshot = try await db.collection("favourites").whereField("userId", isEqualTo: uid).limit(to: 1).getDocuments()
        if !querySnapshot.isEmpty {
          if let favourite = try querySnapshot.documents.first?.data(as: Favourite.self) {
            await MainActor.run {
              self.favourite = favourite
            }
          }
        }
      }
      catch {
        print(error.localizedDescription)
      }
    }
  }

  func saveFavourite() {
    do {
      if let documentId = favourite.documentId {
        try db.collection("favourites").document(documentId).setData(from: favourite)
      }
      else {
        let documentReference = try db.collection("favourites").addDocument(from: favourite)
        print(favourite)
        favourite.documentId = documentReference.documentID
      }
    }
    catch {
      print(error.localizedDescription)
    }
  }
}

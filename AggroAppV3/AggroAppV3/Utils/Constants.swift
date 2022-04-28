//
//  Constants.swift
//  AggroAppV3
//
//  Created by WUMBAch on 11.04.2022.
//

import Foundation
import Firebase

let MSG_METRICS = "Metrics"
let MSG_DASHBOARD = "Dashboard"
let MSG_NOTIFICATIONS = "Get notified"

let MSG_ONBOARDING_METRICS = "Extract valuable insights and come up with data driven product initiatives to help grow your business"
let MSG_ONBOARDING_NOTIFICATIONS = "Get notified when important stuff is happening"
let MSG_ONBOARDING_DASHBOARD = "Everything you need all in one place"

let MSG_RESET_PASSWORD_LINK_SENT = "We sent a link and instructions to your email to reset your password"

let DB_REF = Database.database().reference()
let DB_USERS_REF = DB_REF.child("users")

let STORAGE_REF = Storage.storage().reference()
let STORAGE_PROFILE_IMAGES = STORAGE_REF.child("profile_images")

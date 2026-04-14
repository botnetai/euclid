import ComposableArchitecture
import ConcurrencyExtras
import EuclidCore
import XCTest

@testable import Euclid

extension AppFeature.State: @retroactive Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.activeTab == rhs.activeTab
      && lhs.microphonePermission == rhs.microphonePermission
      && lhs.accessibilityPermission == rhs.accessibilityPermission
      && lhs.inputMonitoringPermission == rhs.inputMonitoringPermission
  }
}

extension AppFeature.Action: @retroactive Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.settings(.openAccessibilitySettings), .settings(.openAccessibilitySettings)),
      (.settings(.openInputMonitoringSettings), .settings(.openInputMonitoringSettings)),
      (.openAccessibilitySettings, .openAccessibilitySettings),
      (.openInputMonitoringSettings, .openInputMonitoringSettings),
      (.startPermissionPolling, .startPermissionPolling),
      (.checkPermissions, .checkPermissions):
      return true

    case let (
      .permissionsUpdated(mic: lhsMic, acc: lhsAcc, input: lhsInput),
      .permissionsUpdated(mic: rhsMic, acc: rhsAcc, input: rhsInput)
    ):
      return lhsMic == rhsMic && lhsAcc == rhsAcc && lhsInput == rhsInput

    default:
      return false
    }
  }
}

@MainActor
final class AppFeaturePermissionRoutingTests: XCTestCase {
  func testSetupPanelForwardsOpenAccessibilitySettings() async {
    let opened = LockIsolated(false)
    var permissions = PermissionClient()
    permissions.microphoneStatus = { .granted }
    permissions.accessibilityStatus = { .granted }
    permissions.inputMonitoringStatus = { .granted }
    permissions.openAccessibilitySettings = {
      opened.setValue(true)
    }

    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.continuousClock = ContinuousClock()
      $0.permissions = permissions
    }

    await store.send(.settings(.openAccessibilitySettings))
    await store.receive(.openAccessibilitySettings)
    await store.receive(.startPermissionPolling)
    await store.receive(.checkPermissions)
    await store.receive(.permissionsUpdated(mic: .granted, acc: .granted, input: .granted)) {
      $0.microphonePermission = .granted
      $0.accessibilityPermission = .granted
      $0.inputMonitoringPermission = .granted
    }

    XCTAssertTrue(opened.value)
  }

  func testSetupPanelPollsAfterOpeningInputMonitoringSettings() async {
    let opened = LockIsolated(false)
    let inputStatus = LockIsolated(PermissionStatus.denied)
    var permissions = PermissionClient()
    permissions.microphoneStatus = { .granted }
    permissions.accessibilityStatus = { .granted }
    permissions.inputMonitoringStatus = {
      inputStatus.value
    }
    permissions.openInputMonitoringSettings = {
      opened.setValue(true)
    }

    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.continuousClock = ContinuousClock()
      $0.permissions = permissions
    }

    await store.send(.settings(.openInputMonitoringSettings))
    await store.receive(.openInputMonitoringSettings)
    await store.receive(.startPermissionPolling)
    await store.receive(.checkPermissions)
    await store.receive(.permissionsUpdated(mic: .granted, acc: .granted, input: .denied)) {
      $0.microphonePermission = .granted
      $0.accessibilityPermission = .granted
      $0.inputMonitoringPermission = .denied
    }

    inputStatus.setValue(.granted)
    try? await Task.sleep(for: .milliseconds(1100))

    await store.receive(.checkPermissions)
    await store.receive(.permissionsUpdated(mic: .granted, acc: .granted, input: .granted)) {
      $0.microphonePermission = .granted
      $0.accessibilityPermission = .granted
      $0.inputMonitoringPermission = .granted
    }

    XCTAssertTrue(opened.value)
  }
}

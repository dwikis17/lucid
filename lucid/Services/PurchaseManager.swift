import Observation
import RevenueCat

@MainActor
@Observable
final class PurchaseManager {
  static let entitlementID = "lucid_pro"

  private(set) var customerInfo: CustomerInfo?
  private(set) var currentOffering: Offering?
  private(set) var isPro = false
  private(set) var isLoading = false
  private(set) var message: String?

  private var customerInfoTask: Task<Void, Never>?

  func start() async {
    guard customerInfoTask == nil else {
      await refresh()
      return
    }

    customerInfoTask = Task { [weak self] in
      guard let self else { return }
      for await customerInfo in Purchases.shared.customerInfoStream {
        apply(customerInfo)
      }
    }

    await refresh()
  }

  func refresh() async {
    guard !isLoading else { return }
    isLoading = true
    message = nil

    do {
      currentOffering = try await Purchases.shared.offerings().current
      if currentOffering == nil {
        message = "No Lucid Pro offering is available yet."
      }
    } catch {
      message = "Could not load Lucid Pro: (error.localizedDescription)"
    }

    do {
      apply(try await Purchases.shared.customerInfo())
    } catch {
      message = "Could not check your Lucid Pro access: (error.localizedDescription)"
    }

    isLoading = false
  }

  func purchase(_ package: Package) async {
    guard !isLoading else { return }
    isLoading = true
    message = nil
    defer { isLoading = false }

    do {
      let result = try await Purchases.shared.purchase(package: package)
      apply(result.customerInfo)
    } catch let error as RevenueCat.ErrorCode where error == .purchaseCancelledError {
      // Cancellation is a normal exit from the paywall.
    } catch let error as RevenueCat.ErrorCode where error == .paymentPendingError {
      message = "Purchase pending approval."
    } catch {
      message = "Purchase failed: (error.localizedDescription)"
    }
  }

  func restore() async {
    guard !isLoading else { return }
    isLoading = true
    message = nil
    defer { isLoading = false }

    do {
      apply(try await Purchases.shared.restorePurchases())
      message = isPro ? "Lucid Pro restored." : "No Lucid Pro purchase was found."
    } catch {
      message = "Could not restore purchases: (error.localizedDescription)"
    }
  }

  func apply(_ customerInfo: CustomerInfo) {
    self.customerInfo = customerInfo
    isPro = customerInfo.entitlements.active[Self.entitlementID]?.isActive == true
  }
}

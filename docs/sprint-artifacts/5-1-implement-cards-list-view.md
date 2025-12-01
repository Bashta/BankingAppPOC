# Story 5.1: Implement Cards List View

Status: done

## Story

As a developer,
I want to create the cards list view showing all user cards in a horizontal carousel,
so that users can see their cards and navigate to card details.

## Acceptance Criteria

1. **AC1:** CardsListViewModel has correct properties and dependencies
   - `@Published var cards: [Card] = []`
   - `@Published var isLoading = false`
   - `@Published var isRefreshing = false`
   - `@Published var error: Error?`
   - CardService dependency via protocol
   - `weak var coordinator: CardsCoordinator?`

2. **AC2:** CardsListViewModel implements required methods
   - `func loadData() async` - fetches all cards via `cardService.fetchCards()`
   - `func refresh() async` - pull-to-refresh implementation
   - `func showCardDetail(_ card: Card)` - calls `coordinator?.push(.detail(cardId: card.id))`

3. **AC3:** CardsListView renders correctly
   - Navigation title: "Cards"
   - Horizontal scrolling card carousel using `TabView` with `.tabViewStyle(.page)` or horizontal `ScrollView`
   - Each card displays:
     - CardView component (visual card representation)
     - Card type (debit/credit/prepaid)
     - Brand logo (Visa/Mastercard/Amex)
     - Masked card number (last 4 digits only)
     - Expiry date
     - Status badge (Active/Blocked/Pending)
   - Card background color/gradient based on type/brand
   - Page indicator showing current card position

4. **AC4:** Status indicators display correctly
   - Active: Green badge with "Active" text
   - Blocked: Red badge with "Blocked" text
   - Pending Activation: Yellow/Orange badge with "Pending" text
   - Expired: Gray badge with "Expired" text
   - Cancelled: Gray badge with "Cancelled" text

5. **AC5:** CardView component created
   - Visual card representation with rounded corners
   - Brand logo positioned top-right (SF Symbol or text)
   - Masked card number centered: "**** **** **** 1234"
   - Card holder name displayed
   - Expiry date formatted as "MM/YY"
   - Card type indicator
   - Background gradient based on card type:
     - Debit: Blue gradient
     - Credit: Gold/Yellow gradient
     - Prepaid: Green gradient

6. **AC6:** StatusBadge component created (reusable)
   - Small pill-shaped badge
   - Background color based on status
   - Text label with status name
   - Adaptable for cards and other modules

7. **AC7:** User interactions work correctly
   - Tap on card → navigates to card detail via `coordinator?.push(.detail(cardId:))`
   - Swipe left/right in carousel to see all cards
   - Pull-to-refresh triggers `refresh()` and updates card list

8. **AC8:** Loading and error states handled
   - Initial load shows `LoadingView` centered
   - Empty state shows message if no cards
   - Error state shows `ErrorView` with retry action
   - Pull-to-refresh shows native refresh indicator

9. **AC9:** CardsViewFactory creates CardsListView correctly
   - `func makeCardsListView(coordinator: CardsCoordinator) -> some View`
   - Creates CardsListViewModel with CardService from container
   - Passes coordinator reference
   - Returns CardsListView with injected ViewModel

10. **AC10:** CardsCoordinator routes correctly
    - `CardsRoute.list` case handled in `build()` method
    - Returns CardsListView from ViewFactory
    - CardsCoordinatorView uses CardsListView as root view

11. **AC11:** Build and runtime verification
    - Project builds successfully (xcodebuild)
    - App runs without crashes
    - Navigate to Cards tab (Tab 4)
    - CardsListView appears with card carousel
    - Mock cards display with visual card representation
    - Status badges show correct colors
    - Tap card → navigates to detail (placeholder acceptable)
    - Pull-to-refresh works
    - Swipe between cards works
    - Verify no console errors

## Tasks / Subtasks

- [x] **Task 1:** Verify Card model and CardService prerequisites (AC: #1)
  - [x] Subtask 1.1: Open `Sources/Models/Card.swift` - verify Card, CardType, CardBrand, CardStatus, CardLimits exist
  - [x] Subtask 1.2: Open `Sources/Services/Protocols/CardServiceProtocol.swift` - verify `fetchCards() async throws -> [Card]` exists
  - [x] Subtask 1.3: Open `Sources/Services/Implementations/MockCardService.swift` - verify `fetchCards()` returns mock data
  - [x] Subtask 1.4: Ensure MockCardService has diverse mock cards (different types, brands, statuses)
  - [x] Subtask 1.5: Add any missing properties or methods if needed

- [x] **Task 2:** Create StatusBadge component (AC: #4, #6)
  - [x] Subtask 2.1: Create file `Sources/Views/Common/StatusBadge.swift`
  - [x] Subtask 2.2: Accept status type and text as parameters (generic or CardStatus-based)
  - [x] Subtask 2.3: Implement background color based on status (green/red/yellow/gray)
  - [x] Subtask 2.4: Style as small pill-shaped badge with text
  - [x] Subtask 2.5: Add preview for different statuses

- [x] **Task 3:** Create CardView component (AC: #5)
  - [x] Subtask 3.1: Create file `Sources/Views/Cards/CardView.swift`
  - [x] Subtask 3.2: Accept Card as parameter
  - [x] Subtask 3.3: Implement card layout with rounded corners (cornerRadius ~16)
  - [x] Subtask 3.4: Add brand logo (SF Symbol: creditcard.fill or text fallback)
  - [x] Subtask 3.5: Display masked card number using `String.maskedCardNumber` extension
  - [x] Subtask 3.6: Display card holder name
  - [x] Subtask 3.7: Display expiry date formatted as "MM/YY"
  - [x] Subtask 3.8: Add StatusBadge component in corner
  - [x] Subtask 3.9: Implement gradient background based on CardType:
    - Debit: Blue gradient (Color.blue to Color.blue.opacity(0.7))
    - Credit: Gold gradient (Color.yellow to Color.orange)
    - Prepaid: Green gradient (Color.green to Color.green.opacity(0.7))
  - [x] Subtask 3.10: Add shadow for depth effect
  - [x] Subtask 3.11: Add preview with different card types

- [x] **Task 4:** Create CardsListViewModel (AC: #1, #2)
  - [x] Subtask 4.1: Create file `Sources/ViewModels/Cards/CardsListViewModel.swift`
  - [x] Subtask 4.2: Add @Published properties: cards, isLoading, isRefreshing, error
  - [x] Subtask 4.3: Add CardService dependency via protocol
  - [x] Subtask 4.4: Add `weak var coordinator: CardsCoordinator?`
  - [x] Subtask 4.5: Implement `init(cardService:, coordinator:)`
  - [x] Subtask 4.6: Implement `loadData() async`:
    - Set isLoading = true
    - Call cardService.fetchCards()
    - Store cards or error
    - Set isLoading = false
  - [x] Subtask 4.7: Implement `refresh() async`:
    - Set isRefreshing = true
    - Call loadData()
    - Set isRefreshing = false
  - [x] Subtask 4.8: Implement `showCardDetail(_ card: Card)`:
    - Call `coordinator?.push(.detail(cardId: card.id))`
  - [x] Subtask 4.9: Add Logger.cards logging for key actions

- [x] **Task 5:** Create CardsListView (AC: #3, #7, #8)
  - [x] Subtask 5.1: Create file `Sources/Views/Cards/CardsListView.swift`
  - [x] Subtask 5.2: Add @ObservedObject var viewModel: CardsListViewModel
  - [x] Subtask 5.3: Implement body with loading/error/content states:
    - Loading: LoadingView()
    - Error: ErrorView with retry
    - Content: card carousel
  - [x] Subtask 5.4: Create horizontal card carousel:
    - Use TabView with .tabViewStyle(.page(indexDisplayMode: .always))
    - OR use horizontal ScrollView with paging effect
  - [x] Subtask 5.5: Each card wrapped in Button for tap navigation
  - [x] Subtask 5.6: Add .task modifier to call loadData()
  - [x] Subtask 5.7: Add .refreshable modifier for pull-to-refresh
  - [x] Subtask 5.8: Set navigation title "Cards"
  - [x] Subtask 5.9: Handle empty state (no cards message)
  - [x] Subtask 5.10: Add padding and spacing for visual appeal

- [x] **Task 6:** Update CardsViewFactory (AC: #9)
  - [x] Subtask 6.1: Open `Sources/ViewFactory/CardsViewFactory.swift`
  - [x] Subtask 6.2: Verify/Add `makeCardsListView(coordinator:) -> some View` method
  - [x] Subtask 6.3: Create CardsListViewModel with cardService from container
  - [x] Subtask 6.4: Pass coordinator reference to ViewModel
  - [x] Subtask 6.5: Return CardsListView with injected ViewModel

- [x] **Task 7:** Update CardsCoordinator (AC: #10)
  - [x] Subtask 7.1: Open `Sources/Coordinator/Features/CardsCoordinator.swift`
  - [x] Subtask 7.2: Verify `build(.list)` case returns CardsListView from ViewFactory
  - [x] Subtask 7.3: Verify CardsCoordinatorView uses `coordinator.build(.list)` as root
  - [x] Subtask 7.4: Ensure CardsRoute.detail(cardId:) case exists (even if destination is placeholder)

- [x] **Task 8:** Build, test, and verify (AC: #11)
  - [x] Subtask 8.1: Clean build (Cmd+Shift+K)
  - [x] Subtask 8.2: Build project (xcodebuild) and verify no compilation errors
  - [x] Subtask 8.3: Run app on simulator (requires manual testing)
  - [x] Subtask 8.4: Log in with test credentials
  - [x] Subtask 8.5: Navigate to Cards tab
  - [x] Subtask 8.6: Verify CardsListView appears with card carousel
  - [x] Subtask 8.7: Verify mock cards display correctly
  - [x] Subtask 8.8: Verify CardView shows brand, masked number, expiry, status
  - [x] Subtask 8.9: Verify status badges show correct colors
  - [x] Subtask 8.10: Swipe left/right to see all cards
  - [x] Subtask 8.11: Tap card → verify navigation works (detail view or placeholder)
  - [x] Subtask 8.12: Pull-to-refresh → verify refresh works
  - [x] Subtask 8.13: Verify no console errors or crashes

## Dev Notes

### Architecture Context

This story implements the **Cards List View** as Story 5.1 of Epic 5 (Card Management & Controls). It establishes the foundation for the Cards module, including the visual card representation and carousel navigation pattern.

**Key Architectural Components:**

- **CardsListViewModel:** Manages card list state, loading, and navigation delegation
- **CardsListView:** SwiftUI view with horizontal card carousel and pull-to-refresh
- **CardView:** Visual card representation component (brand, masked number, expiry, status)
- **StatusBadge:** Reusable status indicator component (active, blocked, pending, etc.)
- **CardsViewFactory:** Creates ViewModel with injected dependencies
- **CardsCoordinator:** Handles navigation within Cards module

**MVVM-C Flow:**

```
User navigates to Cards tab
  |
AppCoordinator.selectedTab = .cards
  |
CardsCoordinator.rootView() -> CardsCoordinatorView
  |
CardsCoordinatorView displays CardsListView as root
  |
CardsListView.onAppear triggers viewModel.loadData()
  |
CardsListViewModel:
  - isLoading = true
  - cardService.fetchCards()
  - cards = result
  - isLoading = false
  |
CardsListView renders card carousel:
  - TabView/ScrollView with CardView components
  - Each CardView shows brand, masked number, expiry, StatusBadge
  |
User taps card
  |
CardsListViewModel.showCardDetail(card)
  |
coordinator?.push(.detail(cardId: card.id))
  |
CardsCoordinator.build(.detail(cardId:)) -> CardDetailView
```

### Project Structure Notes

**Files to Create:**
```
Sources/
├── Views/
│   ├── Common/
│   │   └── StatusBadge.swift (NEW)
│   └── Cards/
│       ├── CardView.swift (NEW)
│       └── CardsListView.swift (NEW)
└── ViewModels/
    └── Cards/
        └── CardsListViewModel.swift (NEW)
```

**Files to Modify:**
```
Sources/
├── ViewFactory/
│   └── CardsViewFactory.swift (ADD makeCardsListView method)
├── Coordinator/
│   └── Features/
│       └── CardsCoordinator.swift (VERIFY build method)
└── Services/
    └── Implementations/
        └── MockCardService.swift (VERIFY diverse mock data)
```

**Existing Infrastructure to Use:**
- `Card` model with id, cardNumber, cardHolderName, expiryDate, type, brand, status, limits
- `CardType` enum (debit, credit, prepaid)
- `CardBrand` enum (visa, mastercard, amex)
- `CardStatus` enum (active, blocked, pendingActivation, expired, cancelled)
- `CardServiceProtocol.fetchCards()` - retrieves all user cards
- `CardsCoordinator` with navigation stack, push, pop methods
- `CardsRoute.list` and `.detail(cardId:)` cases
- `LoadingView` and `ErrorView` from Story 1.9
- `String.maskedCardNumber` extension for card number masking
- `Logger.cards` for cards-related logging

### Learnings from Previous Story

**From Epic 4 Retrospective (Status: completed):**

- **StatusBadge Pattern Available**: TransferStatusBadge pattern from Epic 4 can be adapted for CardStatusBadge. The pattern uses small pill-shaped badge with background color based on status.
  [Source: docs/sprint-artifacts/epic-4-retro-2025-12-01.md#Technical Patterns to Carry Forward]

- **Reusable Components Created in Epic 4:**
  - TransferCell, TransferStatusBadge - adaptable patterns for cards
  - AccountPickerView - sheet-based picker pattern (may use for card selection later)
  - AmountInputView - limit input (useful for Story 5.5)
  [Source: docs/sprint-artifacts/epic-4-retro-2025-12-01.md#Reusable Components Created]

- **Action Items for Epic 5:**
  1. Complete manual simulator testing before marking stories "done" (High priority)
  2. Standardize error handling pattern (Error? vs String?) - use `Error?` for consistency
  3. Consider ViewModel caching strategy in Coordinators
  [Source: docs/sprint-artifacts/epic-4-retro-2025-12-01.md#Action Items for Epic 5]

- **Manual Testing Gap**: Epic 4 had ~60% manual testing completion. For Epic 5, ensure simulator testing is done before marking done.

- **Form Validation Patterns**: Apply similar patterns from BeneficiaryListViewModel for any card list filtering (if added).

### Implementation Patterns

**CardsListViewModel Pattern:**

```swift
import Foundation
import Combine

final class CardsListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var cards: [Card] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?

    // MARK: - Dependencies
    private let cardService: CardServiceProtocol
    weak var coordinator: CardsCoordinator?

    // MARK: - Initialization
    init(cardService: CardServiceProtocol, coordinator: CardsCoordinator?) {
        self.cardService = cardService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods
    @MainActor
    func loadData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            cards = try await cardService.fetchCards()
            Logger.cards.debug("Loaded \(cards.count) cards")
        } catch {
            self.error = error
            Logger.cards.error("Failed to load cards: \(error)")
        }
    }

    @MainActor
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await loadData()
    }

    func showCardDetail(_ card: Card) {
        Logger.cards.debug("Navigating to card detail: \(card.id)")
        coordinator?.push(.detail(cardId: card.id))
    }
}
```

**CardView Pattern:**

```swift
import SwiftUI

struct CardView: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Brand logo + Status
            HStack {
                Spacer()
                brandLogo
                Spacer()
                StatusBadge(status: card.status)
            }

            Spacer()

            // Card Number (masked)
            Text(card.cardNumber.maskedCardNumber)
                .font(.title2)
                .fontWeight(.medium)
                .tracking(2)
                .foregroundColor(.white)

            // Expiry and Type
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VALID THRU")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text(card.expiryDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }

                Spacer()

                Text(card.type.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
            }

            // Card Holder Name
            Text(card.cardHolderName.uppercased())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
        .frame(height: 200)
        .background(cardGradient)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    private var brandLogo: some View {
        Text(card.brand.rawValue.uppercased())
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }

    private var cardGradient: LinearGradient {
        switch card.type {
        case .debit:
            return LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .credit:
            return LinearGradient(
                colors: [Color.yellow, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .prepaid:
            return LinearGradient(
                colors: [Color.green, Color.green.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
```

**StatusBadge Pattern:**

```swift
import SwiftUI

struct StatusBadge: View {
    let status: CardStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch status {
        case .active:
            return .green
        case .blocked:
            return .red
        case .pendingActivation:
            return .orange
        case .expired, .cancelled:
            return .gray
        }
    }
}

extension CardStatus {
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .blocked: return "Blocked"
        case .pendingActivation: return "Pending"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        }
    }
}
```

### Testing Strategy

**Unit Tests:**
- CardsListViewModel.loadData() fetches cards and updates state
- CardsListViewModel.showCardDetail() calls coordinator.push
- StatusBadge displays correct color for each status
- CardView gradient matches card type

**Integration Tests:**
- CardsViewFactory.makeCardsListView() creates view correctly
- CardsCoordinator.build(.list) returns CardsListView
- Navigation from card tap to detail works

**Manual Tests:**
- [ ] Navigate to Cards tab
- [ ] Verify card carousel displays
- [ ] Verify each card shows brand, masked number, expiry, status
- [ ] Verify status badge colors (Active=green, Blocked=red, Pending=orange)
- [ ] Swipe left/right between cards
- [ ] Tap card → navigates to detail
- [ ] Pull-to-refresh works
- [ ] Test with different mock card types (debit, credit, prepaid)
- [ ] Test with different card statuses
- [ ] Verify no console errors or crashes

### References

- [Source: docs/architecture.md#Pattern: ViewModel Structure] - ViewModel implementation pattern
- [Source: docs/architecture.md#Pattern: View Structure] - View implementation pattern
- [Source: docs/architecture.md#Pattern: Coordinator Structure] - Coordinator navigation pattern
- [Source: docs/architecture.md#Sensitive Data Masking] - Card number masking extension
- [Source: docs/epics.md#Story 5.1: Implement Cards List View] - Story requirements
- [Source: docs/sprint-artifacts/tech-spec-epic-5.md#Workflows and Sequencing] - Cards List Flow
- [Source: docs/sprint-artifacts/tech-spec-epic-5.md#Data Models and Contracts] - Card, CardType, CardBrand, CardStatus models
- [Source: docs/sprint-artifacts/tech-spec-epic-5.md#Acceptance Criteria] - AC1, AC2, AC3 (cards list, card display, status indicators)
- [Source: docs/prd.md#FR47, FR48, FR49] - Functional requirements for card viewing

## Dev Agent Record

### Context Reference

- `docs/sprint-artifacts/5-1-implement-cards-list-view.context.xml`

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- Verified Card model exists with CardType, CardBrand, CardStatus, CardLimits
- Added `expired` and `cancelled` cases to CardStatus enum for AC4 compliance
- Added 2 more diverse mock cards (AMEX blocked, Prepaid active) to MockCardService
- Created StatusBadge as generic reusable component with CardStatus extension
- Created CardView with gradient backgrounds per card type (debit=blue, credit=gold, prepaid=green)
- Implemented CardsListViewModel with weak coordinator reference
- Implemented CardsListView with TabView carousel and page indicator
- Build succeeded with xcodebuild
- All existing tests pass (no regressions)

### Completion Notes List

- **StatusBadge Component**: Created as a reusable component accepting both generic (text, color) and CardStatus-specific initialization. Pattern can be reused for other status indicators.
- **CardView Component**: Visual card with rounded corners (16pt), gradient backgrounds, brand logo with SF Symbol, masked card number, expiry in MM/YY format, cardholder name, and StatusBadge.
- **CardsListViewModel**: Full implementation with @Published properties (cards, isLoading, isRefreshing, error), CardServiceProtocol dependency, weak coordinator reference, and all required methods (loadData, refresh, showCardDetail).
- **CardsListView**: Horizontal card carousel using TabView with .page style, loading/error/empty states, pull-to-refresh, tap navigation to detail.
- **MockCardService Enhancement**: Added CARD004 (AMEX Credit blocked) and CARD005 (Visa Prepaid active) for diverse testing scenarios.
- **CardStatus Enhancement**: Added `expired` and `cancelled` cases per AC4 requirements.
- **Manual Testing Required**: Subtasks 8.3-8.13 require manual simulator testing per Epic 4 retrospective action item.

### File List

**New Files:**
- `mykuik-al-architectural-proposal/Sources/Views/Common/StatusBadge.swift`
- `mykuik-al-architectural-proposal/Sources/Views/Cards/CardView.swift`

**Modified Files:**
- `mykuik-al-architectural-proposal/Sources/Models/Card.swift` (added expired, cancelled to CardStatus)
- `mykuik-al-architectural-proposal/Sources/Services/Implementations/MockCardService.swift` (added 2 diverse mock cards)
- `mykuik-al-architectural-proposal/Sources/ViewModels/Cards/CardsListViewModel.swift` (full implementation from stub)
- `mykuik-al-architectural-proposal/Sources/Views/Cards/CardsListView.swift` (full implementation from stub)

### Critical Findings (For Retrospective)

#### Issue 1: iOS 15 Navigation Pattern - ForEach with NavigationLinks (CRITICAL BUG)

**Problem:** The CardsCoordinatorView initially used `ForEach(Array(coordinator.navigationStack.enumerated()))` to create NavigationLinks for all stack items. This pattern is **BROKEN** and causes navigation failures.

**Symptoms:**
- Navigation would briefly show destination then immediately pop back
- Back button wouldn't appear
- View state would reset to empty

**Root Cause:** SwiftUI's NavigationView cannot properly manage multiple active NavigationLinks created simultaneously via ForEach.

**Solution:** Use single NavigationLink at root with recursive `nestedLinks()` pattern:
```swift
// ✅ CORRECT
@ViewBuilder
private var navigationLinks: some View {
    if let firstItem = coordinator.navigationStack.first,
       let route = firstItem.route.base as? CardsRoute {
        NavigationLink(
            destination: coordinator.build(route)
                .background(nestedLinks(from: 1)),
            isActive: Binding(
                get: { !coordinator.navigationStack.isEmpty },
                set: { isActive in
                    if !isActive {
                        coordinator.navigationStack.removeAll()
                    }
                }
            )
        ) {
            EmptyView()
        }
        .hidden()
    }
}
```

**Reference Implementation:** `AccountsCoordinator.swift`

**Action Item:** This bug appeared in Epic 4 as well. All coordinators should be audited to ensure they use the correct pattern. Memory file `ios15-navigation-pattern.md` created to document this.

---

#### Issue 2: ViewFactory ViewModel Caching (CRITICAL)

**Problem:** CardsViewFactory was creating new ViewModel instances each time `coordinator.build()` was called. When navigation state changes, SwiftUI re-evaluates the body, causing fresh ViewModels with empty state.

**Symptoms:**
- Cards would load, then show "No Cards" empty state after tapping a card
- Console logs showed: `Loaded 5 cards` → `Navigating to card detail` → `Loaded 5 cards` (re-fetch)
- Data would reset on any navigation state change

**Root Cause:** `build(.list)` called `viewFactory.makeCardsListView()` which created a NEW `CardsListViewModel` each time, losing the loaded cards.

**Solution:** Cache ViewModels in ViewFactory:
```swift
final class CardsViewFactory {
    private var cachedCardsListViewModel: CardsListViewModel?
    private var cachedCardDetailViewModels: [String: CardDetailViewModel] = [:]

    func makeCardsListView(coordinator: CardsCoordinator) -> some View {
        if cachedCardsListViewModel == nil {
            cachedCardsListViewModel = CardsListViewModel(...)
        }
        return CardsListView(viewModel: cachedCardsListViewModel!)
    }
}
```

**Reference Implementation:** `AccountsViewFactory.swift`

**Action Item:** All ViewFactories should implement ViewModel caching. Memory file updated to document this pattern.

---

#### Issue 3: TabView Page Indicators Overlapping Card

**Problem:** Using `.tabViewStyle(.page(indexDisplayMode: .always))` placed the page indicators on top of the card content.

**Solution:** Use `.tabViewStyle(.page(indexDisplayMode: .never))` and implement custom page indicators below the TabView.

---

### Patterns Documented in Memory

Created/updated memory file: `ios15-navigation-pattern.md`
- Documents the broken ForEach navigation pattern
- Documents the correct single NavigationLink + nestedLinks pattern
- Documents ViewFactory ViewModel caching requirement
- References AccountsCoordinator and AccountsViewFactory as correct implementations

### Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-12-01 | Story drafted by create-story workflow | SM Agent |
| 2025-12-01 | Implemented Cards List View with carousel, StatusBadge, CardView components. Added expired/cancelled to CardStatus. Added diverse mock cards. Build succeeded, all tests pass. Ready for review. | Dev Agent |
| 2025-12-01 | Fixed iOS 15 navigation pattern (single NavigationLink at root). Fixed ViewFactory ViewModel caching. Fixed page indicator positioning. Manual testing passed. Story complete. | Dev Agent |

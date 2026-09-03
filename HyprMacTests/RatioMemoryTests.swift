import XCTest
@testable import HyprMac

final class RatioMemoryTests: XCTestCase {

    private func insertAndApply(_ window: HyprWindow, into tree: BSPTree) {
        tree.insert(window)
        tree.root.applySavedRatios()
    }

    // MARK: - right child removed

    func testRemoveRightChildPreservesRatioOnReinsert() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)

        tree.root.splitRatio = 0.7
        tree.root.userSetRatio = true

        tree.remove(b)
        XCTAssertEqual(tree.root.window, a)

        insertAndApply(makeWindow(id: 3), into: tree)

        XCTAssertEqual(tree.root.splitRatio, 0.7, accuracy: 0.001,
                       "ratio should survive right-child removal + reinsert")
        XCTAssertTrue(tree.root.userSetRatio)
    }

    // MARK: - left child removed (exercises 1.0-ratio flip)

    func testRemoveLeftChildPreservesRatioOnReinsert() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)

        tree.root.splitRatio = 0.7
        tree.root.userSetRatio = true

        tree.remove(a)
        XCTAssertEqual(tree.root.window, b)

        insertAndApply(makeWindow(id: 3), into: tree)

        XCTAssertEqual(tree.root.splitRatio, 0.7, accuracy: 0.001,
                       "left-child removal: new window takes the left slot, ratio preserved")
        XCTAssertTrue(tree.root.userSetRatio)
    }

    // MARK: - default ratio is not saved

    func testDefaultRatioNotSaved() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)

        tree.remove(b)
        insertAndApply(makeWindow(id: 3), into: tree)

        XCTAssertEqual(tree.root.splitRatio, TilingConfig.defaultRatio, accuracy: 0.001,
                       "default 50/50 ratio should not be saved")
        XCTAssertFalse(tree.root.userSetRatio)
    }

    // MARK: - memory consumed after apply

    func testSavedRatioClearedAfterApply() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)
        tree.root.splitRatio = 0.7
        tree.root.userSetRatio = true

        tree.remove(b)
        insertAndApply(makeWindow(id: 3), into: tree)

        XCTAssertNil(tree.root.savedSplitRatio,
                     "saved ratio should be consumed on apply, not linger")
    }

    // MARK: - single window removal (root)

    func testRemoveOnlyWindowDoesNotCrash() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        tree.insert(a)
        tree.root.splitRatio = 0.7
        tree.root.userSetRatio = true

        tree.remove(a)
        XCTAssertTrue(tree.root.isEmpty)

        insertAndApply(makeWindow(id: 2), into: tree)
        XCTAssertEqual(tree.root.splitRatio, TilingConfig.defaultRatio, accuracy: 0.001)
    }

    // MARK: - deeper tree

    func testRatioMemoryWorksAtDepth() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        let c = makeWindow(id: 3)
        tree.insert(a)
        tree.insert(b)
        tree.insert(c)

        let sub = tree.root.right!
        sub.splitRatio = 0.6
        sub.userSetRatio = true

        tree.remove(c)
        XCTAssertEqual(tree.root.right?.window, b)

        let d = makeWindow(id: 4)
        tree.root.right?.insert(d)
        tree.root.applySavedRatios()

        XCTAssertEqual(tree.root.right?.splitRatio ?? 0, 0.6, accuracy: 0.001,
                       "ratio at depth should survive removal + reinsert")
    }

    // MARK: - ratio survives multiple cycles

    func testRatioSurvivesMultipleCycles() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)
        tree.root.splitRatio = 0.65
        tree.root.userSetRatio = true

        tree.remove(b)
        insertAndApply(makeWindow(id: 3), into: tree)
        XCTAssertEqual(tree.root.splitRatio, 0.65, accuracy: 0.001)

        tree.remove(tree.root.right!.window!)
        insertAndApply(makeWindow(id: 4), into: tree)
        XCTAssertEqual(tree.root.splitRatio, 0.65, accuracy: 0.001,
                       "ratio should survive multiple remove/reinsert cycles")
    }
}

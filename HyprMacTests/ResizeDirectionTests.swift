import XCTest
@testable import HyprMac

final class ResizeDirectionTests: XCTestCase {

    private func resizeRatio(tree: BSPTree, window: HyprWindow,
                             direction: Direction, rect: CGRect,
                             gap: CGFloat = defaultGap,
                             padding: CGFloat = defaultPadding) -> CGFloat? {
        guard let leaf = tree.root.find(window) else { return nil }
        let axis: SplitDirection = (direction == .left || direction == .right) ? .horizontal : .vertical
        let positive = (direction == .right || direction == .down)

        var node = leaf
        while let parent = node.parent {
            guard let parentRect = tree.rectForNode(parent, in: rect, gap: gap, padding: padding) else {
                node = parent
                continue
            }
            guard parent.direction(for: parentRect) == axis else {
                node = parent
                continue
            }
            let isLeft = parent.left === node
            let grow = isLeft == positive
            let delta: CGFloat = grow ? TilingConfig.resizeStep : -TilingConfig.resizeStep
            let newRatio = min(max(parent.splitRatio + delta, TilingConfig.minRatio), TilingConfig.maxRatio)
            guard newRatio != parent.splitRatio else { return parent.splitRatio }
            parent.splitRatio = newRatio
            parent.userSetRatio = true
            return newRatio
        }
        return nil
    }

    private func assertRatio(_ ratio: CGFloat?, expected: CGFloat,
                             _ message: String = "", file: StaticString = #filePath,
                             line: UInt = #line) {
        guard let ratio else {
            XCTFail("expected ratio \(expected) but got nil. \(message)", file: file, line: line)
            return
        }
        XCTAssertEqual(ratio, expected, accuracy: 0.001, message, file: file, line: line)
    }

    // MARK: - left child (a) resize

    func testLeftChildResizeRightGrows() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)
        XCTAssertEqual(tree.root.splitRatio, TilingConfig.defaultRatio)

        let ratio = resizeRatio(tree: tree, window: a, direction: .right, rect: defaultRect)
        assertRatio(ratio, expected: TilingConfig.defaultRatio + TilingConfig.resizeStep)
    }

    func testLeftChildResizeLeftShrinks() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)

        let ratio = resizeRatio(tree: tree, window: a, direction: .left, rect: defaultRect)
        assertRatio(ratio, expected: TilingConfig.defaultRatio - TilingConfig.resizeStep)
    }

    // MARK: - right child (b) resize

    func testRightChildResizeRightGrows() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)

        let ratio = resizeRatio(tree: tree, window: b, direction: .right, rect: defaultRect)
        assertRatio(ratio, expected: TilingConfig.defaultRatio - TilingConfig.resizeStep,
                    "right child pressing right should decrease splitRatio (grow right child)")
    }

    func testRightChildResizeLeftShrinks() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)

        let ratio = resizeRatio(tree: tree, window: b, direction: .left, rect: defaultRect)
        assertRatio(ratio, expected: TilingConfig.defaultRatio + TilingConfig.resizeStep,
                    "right child pressing left should increase splitRatio (shrink right child)")
    }

    // MARK: - vertical split (narrow rect)

    func testVerticalSplitResizeDown() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)

        let ratio = resizeRatio(tree: tree, window: a, direction: .down, rect: narrowRect)
        assertRatio(ratio, expected: TilingConfig.defaultRatio + TilingConfig.resizeStep)
    }

    func testVerticalSplitBottomChildResizeUp() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)

        let ratio = resizeRatio(tree: tree, window: b, direction: .up, rect: narrowRect)
        assertRatio(ratio, expected: TilingConfig.defaultRatio + TilingConfig.resizeStep,
                    "bottom child pressing up shrinks it (increases ratio, top child grows)")
    }

    // MARK: - clamping

    func testResizeClampsAtMinRatio() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)
        tree.root.splitRatio = TilingConfig.minRatio

        let ratio = resizeRatio(tree: tree, window: a, direction: .left, rect: defaultRect)
        assertRatio(ratio, expected: TilingConfig.minRatio, "should clamp at minRatio")
    }

    func testResizeClampsAtMaxRatio() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        let b = makeWindow(id: 2)
        tree.insert(a)
        tree.insert(b)
        tree.root.splitRatio = TilingConfig.maxRatio

        let ratio = resizeRatio(tree: tree, window: a, direction: .right, rect: defaultRect)
        assertRatio(ratio, expected: TilingConfig.maxRatio, "should clamp at maxRatio")
    }

    // MARK: - single window (no-op)

    func testSingleWindowReturnsNil() {
        let tree = BSPTree()
        let a = makeWindow(id: 1)
        tree.insert(a)

        let ratio = resizeRatio(tree: tree, window: a, direction: .right, rect: defaultRect)
        XCTAssertNil(ratio, "single window has no parent to resize")
    }
}

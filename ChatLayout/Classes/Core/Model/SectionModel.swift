//
// ChatLayout
// SectionModel.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2022.
// Distributed under the MIT license.
//

import Foundation
import UIKit

struct SectionModel {

    let id: UUID

    private(set) var header: ItemModel?

    private(set) var footer: ItemModel?

    private(set) var items: [ItemModel]

    var offsetY: CGFloat = .zero
    
    var additionalOffsetY: CGFloat = .zero

    private unowned var collectionLayout: ChatLayoutRepresentation

    var count: Int {
        return items.count
    }

    var origin: CGPoint {
        return CGPoint(x: .zero, y: offsetY + additionalOffsetY)
    }
    
    var size: CGSize {
        let additionalInsets = collectionLayout.settings.additionalInsets
        return CGSize(width: collectionLayout.visibleBounds.width - additionalInsets.left - additionalInsets.right, height: height)
    }
    
    var frame: CGRect {
        return CGRect(origin: origin, size: size)
    }

    private var height: CGFloat {
        if let footer = footer {
            return footer.frame.maxY
        } else {
            guard let lastItem = items.last else {
                return (header?.frame.maxY ?? .zero)
            }
            return lastItem.frame.maxY
        }
    }

    init(id: UUID = UUID(),
         header: ItemModel?,
         footer: ItemModel?,
         items: [ItemModel] = [],
         collectionLayout: ChatLayoutRepresentation) {
        self.id = id
        self.items = items
        self.collectionLayout = collectionLayout
        self.header = header
        self.footer = footer
    }

    mutating func assembleLayout() {
        var offsetY: CGFloat = .zero

        if header != nil {
            header?.offsetY = 0
            offsetY += header?.frame.height ?? 0
        }

        for rowIndex in 0..<items.count {
            items[rowIndex].offsetY = offsetY
            offsetY += items[rowIndex].frame.height + collectionLayout.settings.interItemSpacing
        }

        if footer != nil {
            footer?.offsetY = offsetY
        }
    }

    // MARK: To use when its is important to make the correct insertion

    mutating func setAndAssemble(header: ItemModel) {
        guard let oldHeader = self.header else {
            self.header = header
            offsetEverything(below: -1, by: header.frame.height)
            return
        }
        #if DEBUG
        if header.id != oldHeader.id {
            assertionFailure("Internal inconsistency")
        }
        #endif
        self.header = header
        let heightDiff = header.frame.height - oldHeader.frame.height
        offsetEverything(below: -1, by: heightDiff)
    }

    mutating func setAndAssemble(item: ItemModel, at index: Int) {
        guard index < count else {
            assertionFailure("Incorrect item index.")
            return
        }
        let oldItem = items[index]
        #if DEBUG
        if item.id != oldItem.id {
            assertionFailure("Internal inconsistency")
        }
        #endif
        items[index] = item

        let heightDiff = item.frame.height - oldItem.frame.height
        offsetEverything(below: index, by: heightDiff)
    }

    mutating func setAndAssemble(footer: ItemModel) {
        #if DEBUG
        if let oldFooter = self.footer,
           footer.id != oldFooter.id {
            assertionFailure("Internal inconsistency")
        }
        #endif
        self.footer = footer
    }

    // MARK: Just updaters

    mutating func set(header: ItemModel?) {
        self.header = header
    }

    mutating func set(items: [ItemModel]) {
        self.items = items
    }

    mutating func set(footer: ItemModel?) {
        guard let _ = self.footer, let _ = footer else {
            self.footer = footer
            return
        }
        self.footer = footer
    }

    private mutating func offsetEverything(below index: Int, by heightDiff: CGFloat) {
        guard heightDiff != 0 else {
            return
        }
        if index < items.count - 1 {
            for index in (index + 1)..<items.count {
                items[index].offsetY += heightDiff
            }
        }
        footer?.offsetY += heightDiff
    }

    // MARK: To use only withing process(updateItems:)

    mutating func insert(_ item: ItemModel, at index: Int) {
        guard index <= count else {
            assertionFailure("Incorrect item index.")
            return
        }
        items.insert(item, at: index)
    }

    mutating func replace(_ item: ItemModel, at index: Int) {
        guard index <= count else {
            assertionFailure("Incorrect item index.")
            return
        }
        items[index] = item
    }

    mutating func remove(at index: Int) {
        guard index < count else {
            assertionFailure("Incorrect item index.")
            return
        }
        items.remove(at: index)
    }

}

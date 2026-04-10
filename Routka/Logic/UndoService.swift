//
//  UndoService.swift
//  Routka
//
//  Created by vladukha on 10.04.2026.
//

import Foundation
import SwiftUI

@Observable
final class UndoService<Element: Hashable> {
    enum HistorableAction: Hashable {
        case added([Element])
        case deleted([Element])
    }
    
    private(set) var doneActions: [HistorableAction] = []
    private(set) var state: [Element] = []
    private(set) var undoneActions: [HistorableAction] = []
    
    public func addElement(_ point: Element, _ logAction: Bool = true) {
        self.state.append(point)
        if logAction {
            self.doneActions.append(.added([point]))
            self.undoneActions.removeAll()
        }
    }
    
    public func addElements(_ points: [Element], _ logAction: Bool = true) {
        self.state.append(contentsOf: points)
        if logAction {
            self.undoneActions = []
            self.doneActions.append(.added(points))
        }
    }
    
    public func removeElement(_ point: Element, _ logAction: Bool = true) {
        guard let index = self.state.firstIndex(of: point) else { return }
        self.state.remove(at: index)
        if logAction {
            self.undoneActions = []
            self.doneActions.append(.deleted([point]))
            
        }
    }
    
    public func removeElements(_ points: [Element], _ logAction: Bool = true) {
        var removedPoints: [Element] = []
        for point in points {
            guard let index = self.state.firstIndex(of: point) else { continue }
            self.state.remove(at: index)
            removedPoints.append(point)
            
        }
        if logAction {
            self.undoneActions = []
            self.doneActions.append(.deleted(removedPoints))
        }
    }
    
    public func removeAllElements(_ logAction: Bool = true) {
        guard !state.isEmpty else { return }
        let points = self.state
        self.state.removeAll()
        if logAction {
            self.undoneActions = []
            self.doneActions.append(.deleted(points))
        }
    }
    
    public func undo() {
        guard !doneActions.isEmpty else { return }
        let action = self.doneActions.removeLast()
        self.undoneActions.append(action)
        switch action {
        case .added(let points):
            removeElements(points, false)
        case .deleted(let points):
            addElements(points, false)
        }
    }
    
    public func forward() {
        guard !undoneActions.isEmpty else { return }
        let action = undoneActions.removeLast()
        self.doneActions.append(action)
        switch action {
        case .added(let points):
            addElements(points, false)
        case .deleted(let points):
            removeElements(points, false)
        }
    }
}

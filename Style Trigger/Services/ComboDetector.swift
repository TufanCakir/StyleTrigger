//
//  ComboDetector.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation

@MainActor
final class ComboDetector {
    private var definitions: [ComboDefinition] = []
    private var history: [(input: CombatInput, time: TimeInterval)] = []
    private let maximumInterval: TimeInterval = 0.9

    func configure(with definitions: [ComboDefinition]) {
        self.definitions = definitions
        history.removeAll(keepingCapacity: true)
    }

    func register(_ input: CombatInput, at time: TimeInterval)
        -> ComboDefinition?
    {
        history.append((input, time))
        history.removeAll { time - $0.time > maximumInterval }
        if history.count > 10 {
            history.removeFirst(history.count - 10)
        }

        let inputs = history.map(\.input)
        let match =
            definitions
            .filter {
                inputs.suffix($0.inputSequence.count) == $0.inputSequence[...]
            }
            .max { $0.inputSequence.count < $1.inputSequence.count }

        if match != nil {
            history.removeAll(keepingCapacity: true)
        }
        return match
    }
}

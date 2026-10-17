//
//  ComboDetector.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation

/// Detects combat combos from a short, time-limited input history.
/// All access is isolated to the main actor, matching the SpriteKit game scene.
@MainActor
final class ComboDetector {
    private struct TimedInput {
        let input: CombatInput
        let time: TimeInterval
    }

    private var definitions: [ComboDefinition] = []
    private var history: [TimedInput] = []

    /// Maximum allowed gap between consecutive inputs in a combo.
    private let maximumInterval: TimeInterval
    private var maximumSequenceLength = 0

    init(maximumInterval: TimeInterval = 0.9) {
        self.maximumInterval = max(0, maximumInterval)
    }

    /// Replaces available combos and discards input from the previous configuration.
    func configure(with definitions: [ComboDefinition]) {
        // Empty sequences must not match every input. Preserve the order of the
        // source data for deterministic tie-breaking between equal-length combos.
        self.definitions = definitions.filter { !$0.inputSequence.isEmpty }
        maximumSequenceLength =
            self.definitions.map(\.inputSequence.count).max() ?? 0
        reset()
    }

    /// Clears buffered input, for example after a weapon switch or match restart.
    func reset() {
        history.removeAll(keepingCapacity: true)
    }

    /// Registers an input and returns the longest combo ending at that input.
    /// Inputs must be supplied in chronological order using the same time source.
    @discardableResult
    func register(_ input: CombatInput, at time: TimeInterval)
        -> ComboDefinition?
    {
        guard time.isFinite, maximumSequenceLength > 0 else {
            reset()
            return nil
        }

        // Reset on non-monotonic timestamps or when the chain has expired.
        if let last = history.last,
            time < last.time || time - last.time > maximumInterval
        {
            reset()
        }

        history.append(TimedInput(input: input, time: time))

        // Keep only the amount of history needed by the longest configured combo.
        if history.count > maximumSequenceLength {
            history.removeFirst(history.count - maximumSequenceLength)
        }

        // A match must end with the latest input. Longer sequences take priority.
        // Equal-length ties follow the original configuration order.
        let match =
            definitions
            .filter { definition in
                let count = definition.inputSequence.count
                guard count <= history.count else { return false }
                return zip(history.suffix(count), definition.inputSequence)
                    .allSatisfy { entry, expected in entry.input == expected }
            }
            .max { $0.inputSequence.count < $1.inputSequence.count }

        if match != nil {
            reset()
        }
        return match
    }
}

//
//  GameCenterMultiplayerService.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation
import GameKit
import Observation
import UIKit

nonisolated struct MultiplayerInputPacket: Codable, Sendable {
    let sequence: UInt64
    let input: CombatInput
    let sentAt: TimeInterval
}

enum MultiplayerConnectionState: Equatable {
    case unavailable(String)
    case authenticating
    case ready
    case matchmaking
    case connected(opponentName: String)
    case disconnected(String)

    var label: String {
        switch self {
        case .unavailable: "GAME CENTER OFFLINE"
        case .authenticating: "SIGNING IN"
        case .ready: "GAME CENTER READY"
        case .matchmaking: "SEARCHING"
        case .connected(let name): "VS \(name)"
        case .disconnected: "CONNECTION LOST"
        }
    }
}

@MainActor
@Observable
final class GameCenterMultiplayerService: NSObject {
    private(set) var state: MultiplayerConnectionState = .authenticating
    private(set) var remoteInput: CombatInput?
    private(set) var remoteInputSequence: UInt64 = 0
    private(set) var errorMessage: String?

    var isShowingMatchmaker = false
    var authenticationViewController: UIViewController?

    @ObservationIgnored private var match: GKMatch?
    @ObservationIgnored private var pendingMatchmakerController:
        GKMatchmakerViewController?
    @ObservationIgnored private var localSequence: UInt64 = 0

    var isAuthenticated: Bool {
        GKLocalPlayer.local.isAuthenticated
    }

    var isConnected: Bool {
        if case .connected = state { return true }
        return false
    }

    override init() {
        super.init()
        authenticate()
    }

    func authenticate() {
        state = .authenticating
        GKLocalPlayer.local.authenticateHandler = {
            [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    self.authenticationViewController = viewController
                    return
                }

                self.authenticationViewController = nil
                if GKLocalPlayer.local.isAuthenticated {
                    GKLocalPlayer.local.register(self)
                    self.state = .ready
                    self.errorMessage = nil
                } else {
                    let message =
                        error?.localizedDescription
                        ?? "Sign in to Game Center in Settings."
                    self.state = .unavailable(message)
                    self.errorMessage = message
                }
            }
        }
    }

    func beginMatchmaking(teamSize: Int) {
        guard isAuthenticated else {
            authenticate()
            return
        }
        let playerCount = max(2, min(8, teamSize * 2))
        state = .matchmaking
        isShowingMatchmaker = true
        requestedPlayerCount = playerCount
    }

    func makeMatchmakerViewController() -> GKMatchmakerViewController? {
        if let pendingMatchmakerController {
            self.pendingMatchmakerController = nil
            return pendingMatchmakerController
        }
        let request = GKMatchRequest()
        request.minPlayers = requestedPlayerCount
        request.maxPlayers = requestedPlayerCount
        request.inviteMessage = "Enter the Style Trigger arena."
        guard let controller = GKMatchmakerViewController(matchRequest: request)
        else {
            state = .disconnected("Could not create Game Center matchmaker.")
            isShowingMatchmaker = false
            return nil
        }
        controller.matchmakerDelegate = self
        return controller
    }

    func send(_ input: CombatInput) {
        guard let match, isConnected else { return }
        localSequence &+= 1
        let packet = MultiplayerInputPacket(
            sequence: localSequence,
            input: input,
            sentAt: Date.now.timeIntervalSince1970
        )
        do {
            let data = try JSONEncoder().encode(packet)
            try match.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disconnect() {
        match?.disconnect()
        match = nil
        state =
            isAuthenticated
            ? .ready : .unavailable("Game Center is unavailable.")
    }

    @ObservationIgnored private var requestedPlayerCount = 2

    private func start(match: GKMatch) {
        self.match = match
        match.delegate = self
        let opponent = match.players.first?.displayName ?? "ONLINE RIVAL"
        state = .connected(opponentName: opponent)
        isShowingMatchmaker = false
        errorMessage = nil
    }
}

extension GameCenterMultiplayerService: GKMatchmakerViewControllerDelegate {
    nonisolated func matchmakerViewControllerWasCancelled(
        _ viewController: GKMatchmakerViewController
    ) {
        Task { @MainActor [weak self] in
            self?.isShowingMatchmaker = false
            self?.state = .ready
        }
    }

    nonisolated func matchmakerViewController(
        _ viewController: GKMatchmakerViewController,
        didFailWithError error: any Error
    ) {
        Task { @MainActor [weak self] in
            self?.isShowingMatchmaker = false
            self?.state = .disconnected(error.localizedDescription)
            self?.errorMessage = error.localizedDescription
        }
    }

    nonisolated func matchmakerViewController(
        _ viewController: GKMatchmakerViewController,
        didFind match: GKMatch
    ) {
        Task { @MainActor [weak self] in
            viewController.dismiss(animated: true)
            self?.start(match: match)
        }
    }
}

extension GameCenterMultiplayerService: GKLocalPlayerListener {
    nonisolated func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        Task { @MainActor [weak self] in
            guard let self,
                let controller = GKMatchmakerViewController(invite: invite)
            else {
                return
            }
            controller.matchmakerDelegate = self
            self.pendingMatchmakerController = controller
            self.state = .matchmaking
            self.isShowingMatchmaker = true
        }
    }
}

extension GameCenterMultiplayerService: GKMatchDelegate {
    nonisolated func match(
        _ match: GKMatch,
        didReceive data: Data,
        fromRemotePlayer player: GKPlayer
    ) {
        guard
            let packet = try? JSONDecoder().decode(
                MultiplayerInputPacket.self,
                from: data
            )
        else {
            return
        }
        Task { @MainActor [weak self] in
            guard let self, packet.sequence > self.remoteInputSequence else {
                return
            }
            self.remoteInputSequence = packet.sequence
            self.remoteInput = packet.input
            self.state = .connected(opponentName: player.displayName)
        }
    }

    nonisolated func match(
        _ match: GKMatch,
        player playerID: String,
        didChange state: GKPlayerConnectionState
    ) {
        guard state == .disconnected else { return }
        Task { @MainActor [weak self] in
            self?.state = .disconnected("The opponent left the match.")
            self?.match = nil
        }
    }

    nonisolated func match(
        _ match: GKMatch,
        didFailWithError error: (any Error)?
    ) {
        Task { @MainActor [weak self] in
            let message =
                error?.localizedDescription ?? "The multiplayer match failed."
            self?.state = .disconnected(message)
            self?.errorMessage = message
            self?.match = nil
        }
    }
}

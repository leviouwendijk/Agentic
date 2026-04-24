import Foundation
import Fuzzy
import Matching
import Ranking

public struct TranscriptRetriever: Sendable {
    public let options: TranscriptRetrievalOptions

    public init(
        options: TranscriptRetrievalOptions = .default
    ) {
        self.options = options
    }

    public func retrieve(
        _ query: String,
        in events: [AgentTranscriptEvent]
    ) -> [Ranked<MatchResult<Int>>] {
        let trimmed = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            return []
        }

        let matchQuery = MatchQuery(
            trimmed,
            options: options.tokenNormalization
        )

        guard !matchQuery.isEmpty else {
            return []
        }

        let candidates = events.enumerated().map { offset, event in
            candidate(
                for: event,
                sourceOrder: offset
            )
        }

        let ranker = FuzzyRanker<BasicMatchCandidate<Int>>(
            options: options.fuzzy,
            selection: options.selection
        )

        return ranker.rank(
            query: matchQuery,
            candidates: candidates
        )
    }

    public func event(
        for result: Ranked<MatchResult<Int>>,
        in events: [AgentTranscriptEvent]
    ) -> AgentTranscriptEvent? {
        let sourceOrder = result.value.candidateID

        guard events.indices.contains(sourceOrder) else {
            return nil
        }

        return events[sourceOrder]
    }
}

private extension TranscriptRetriever {
    func candidate(
        for event: AgentTranscriptEvent,
        sourceOrder: Int
    ) -> BasicMatchCandidate<Int> {
        .init(
            matchID: sourceOrder,
            primaryField: primaryField(
                for: event
            ),
            secondaryFields: secondaryFields(
                for: event
            ),
            metadata: metadata(
                for: event,
                sourceOrder: sourceOrder
            )
        )
    }

    func primaryField(
        for event: AgentTranscriptEvent
    ) -> MatchField {
        let text = event.summaryText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let fallback = event.id

        switch event {
        case .message:
            return .init(
                name: "summary",
                text: text.isEmpty ? fallback : text,
                role: .primary,
                weight: 12
            )

        case .tool_call:
            return .init(
                name: "toolName",
                text: text.isEmpty ? fallback : text,
                role: .primary,
                weight: 12
            )

        case .tool_result:
            return .init(
                name: "toolResult",
                text: text.isEmpty ? fallback : text,
                role: .primary,
                weight: 11
            )

        case .session_branch:
            return .init(
                name: "sessionBranch",
                text: text.isEmpty ? fallback : text,
                role: .primary,
                weight: 12
            )

        case .note:
            return .init(
                name: "note",
                text: text.isEmpty ? fallback : text,
                role: .primary,
                weight: 12
            )
        }
    }

    func secondaryFields(
        for event: AgentTranscriptEvent
    ) -> [MatchField] {
        switch event {
        case .message(let message):
            var fields: [MatchField] = [
                .init(
                    name: "kind",
                    text: "message",
                    role: .tag,
                    weight: 2
                ),
                .init(
                    name: "role",
                    text: message.role.rawValue,
                    role: .keyword,
                    weight: 4
                )
            ]

            let body = message.content.text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if !body.isEmpty {
                fields.append(
                    .init(
                        name: "body",
                        text: body,
                        role: .body,
                        weight: 6
                    )
                )
            }

            return fields

        case .tool_call(let call):
            return [
                .init(
                    name: "kind",
                    text: "tool_call",
                    role: .tag,
                    weight: 2
                ),
                .init(
                    name: "alias",
                    text: "tool call",
                    role: .alias,
                    weight: 2
                ),
                .init(
                    name: "toolName",
                    text: call.name,
                    role: .keyword,
                    weight: 6
                ),
                .init(
                    name: "toolCallID",
                    text: call.id,
                    role: .secondary,
                    weight: 1
                )
            ]

        case .tool_result(let result):
            var fields: [MatchField] = [
                .init(
                    name: "kind",
                    text: "tool_result",
                    role: .tag,
                    weight: 2
                ),
                .init(
                    name: "alias",
                    text: "tool result",
                    role: .alias,
                    weight: 2
                ),
                .init(
                    name: "toolCallID",
                    text: result.toolCallID,
                    role: .secondary,
                    weight: 1
                ),
                .init(
                    name: "status",
                    text: result.isError ? "error failed" : "success ok",
                    role: .keyword,
                    weight: 3
                )
            ]

            if let name = result.name,
               !name.isEmpty {
                fields.append(
                    .init(
                        name: "toolName",
                        text: name,
                        role: .keyword,
                        weight: 6
                    )
                )
            }

            return fields

        case .session_branch(let event):
            var fields: [MatchField] = [
                .init(
                    name: "kind",
                    text: "session_branch",
                    role: .tag,
                    weight: 2
                ),
                .init(
                    name: "alias",
                    text: "session branch branched fork parent",
                    role: .alias,
                    weight: 3
                ),
                .init(
                    name: "sessionID",
                    text: event.sessionID,
                    role: .keyword,
                    weight: 5
                ),
                .init(
                    name: "parentSessionID",
                    text: event.branch.parentSessionID,
                    role: .keyword,
                    weight: 5
                )
            ]

            if let branchedAtEventID = event.branch.branchedAtEventID,
               !branchedAtEventID.isEmpty {
                fields.append(
                    .init(
                        name: "branchedAtEventID",
                        text: branchedAtEventID,
                        role: .secondary,
                        weight: 2
                    )
                )
            }

            if let branchedAtCheckpointID = event.branch.branchedAtCheckpointID,
               !branchedAtCheckpointID.isEmpty {
                fields.append(
                    .init(
                        name: "branchedAtCheckpointID",
                        text: branchedAtCheckpointID,
                        role: .secondary,
                        weight: 2
                    )
                )
            }

            if let note = event.branch.note,
               !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fields.append(
                    .init(
                        name: "note",
                        text: note,
                        role: .body,
                        weight: 6
                    )
                )
            }

            return fields

        case .note(_, let text):
            return [
                .init(
                    name: "kind",
                    text: "note",
                    role: .tag,
                    weight: 2
                ),
                .init(
                    name: "body",
                    text: text,
                    role: .body,
                    weight: 6
                )
            ]
        }
    }

    func metadata(
        for event: AgentTranscriptEvent,
        sourceOrder: Int
    ) -> MatchCandidateMetadata {
        switch event {
        case .message(let message):
            return .init(
                values: [
                    "kind": "message",
                    "id": message.id,
                    "role": message.role.rawValue,
                    "sourceOrder": String(sourceOrder)
                ]
            )

        case .tool_call(let call):
            return .init(
                values: [
                    "kind": "tool_call",
                    "id": call.id,
                    "name": call.name,
                    "sourceOrder": String(sourceOrder)
                ]
            )

        case .tool_result(let result):
            var values: [String: String] = [
                "kind": "tool_result",
                "toolCallID": result.toolCallID,
                "isError": result.isError ? "true" : "false",
                "sourceOrder": String(sourceOrder)
            ]

            if let name = result.name,
               !name.isEmpty {
                values["name"] = name
            }

            return .init(
                values: values
            )

        case .session_branch(let event):
            var values: [String: String] = [
                "kind": "session_branch",
                "id": event.id,
                "sessionID": event.sessionID,
                "parentSessionID": event.branch.parentSessionID,
                "sourceOrder": String(sourceOrder)
            ]

            if let branchedAtEventID = event.branch.branchedAtEventID,
               !branchedAtEventID.isEmpty {
                values["branchedAtEventID"] = branchedAtEventID
            }

            if let branchedAtCheckpointID = event.branch.branchedAtCheckpointID,
               !branchedAtCheckpointID.isEmpty {
                values["branchedAtCheckpointID"] = branchedAtCheckpointID
            }

            return .init(
                values: values
            )


        case .note(let id, _):
            return .init(
                values: [
                    "kind": "note",
                    "id": id,
                    "sourceOrder": String(sourceOrder)
                ]
            )
        }
    }
}

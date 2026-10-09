import Agentic
import Foundation
import Testing

private struct DecisionRouteFixture: DecisionInference {
    typealias Input = String
    typealias Output = Decision.Choice<String>

    static let definition = InferenceDefinition(
        identifier: "decision_route_fixture",
        purpose: "Route using invocation-specific application values."
    )

    static func decision(
        for input: String
    ) throws -> Decision.Specification<Output> {
        let query = try Decision.choice(
            id: "route",
            instructions: "Choose the appropriate department.",
            options: [
                try .init(
                    id: "support",
                    value: input,
                    description: "Technical support"
                ),
                try .init(
                    id: "billing",
                    value: "billing",
                    description: "Invoices"
                ),
            ]
        )

        return try .init(
            state: [
                "ticket": input,
            ],
            query: query
        )
    }
}

private struct DecisionProgramFixture: Program {
    typealias Input = String
    typealias Output = Decision.Choice<String>

    static let definition = ProgramDefinition(
        identifier: "decision_program_fixture",
        purpose: "Own an ordinary typed inference site."
    )

    static let route = InferenceSite<
        DecisionProgramFixture,
        DecisionRouteFixture
    >(
        identifier: "route"
    )

    func run(
        _ input: String,
        in context: ProgramContext
    ) async throws -> Output {
        try await context.infer(
            Self.route,
            input: input
        )
    }
}

/// Exercises authoring and ProgramContext dispatch only, without claiming model execution.
private struct DecisionAuthoringFixtureInvoker:
    InferenceInvoking
{
    func infer<P: Program, I: Inference>(
        _ site: InferenceSite<P, I>,
        input: I.Input
    ) async throws -> I.Output {
        switch try I.specification(
            for: input
        ) {
        case .generative:
            throw Decision.Error.answerMismatch(
                site.inference.rawValue
            )

        case .decision(let specification):
            return try specification.resolve([
                "route": .choice(
                    selected: "support",
                    probabilities: [
                        "support": try .init(0.75),
                        "billing": try .init(0.25),
                    ],
                    confidence: nil
                ),
            ])
        }
    }
}

private struct DecisionTransportFixture:
    AgentModelInvoking
{
    func buffered(
        _ invocation: AgentModelInvocation
    ) async throws -> AgentModelInvocation.Result {
        throw TestFlowAssertionFailure(
            label: "decision transport guard",
            message: "A decision inference reached the generative model invoker."
        )
    }

    func stream(
        _ invocation: AgentModelInvocation
    ) -> AsyncThrowingStream<AgentModelInvocation.Event, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(
                throwing: Decision.Error.modelExecutionUnavailable
            )
        }
    }
}

enum DecisionAuthoringFlowTests {
    static let all: [TestFlow] = [
        TestFlow(
            "decision-answer-invariants",
            tags: [
                "decision",
                "inference",
            ]
        ) {
            try invariants()
        },
        TestFlow(
            "decision-query-composition",
            tags: [
                "decision",
                "inference",
            ]
        ) {
            try composition()
        },
        TestFlow(
            "decision-site-and-realization",
            tags: [
                "decision",
                "programs",
            ]
        ) {
            try await sites()
        },
        TestFlow(
            "decision-chat-execution-rejected",
            tags: [
                "decision",
                "inference",
            ]
        ) {
            try await transportGuard()
        },
    ]

    private static func rejects(
        _ operation: () throws -> Void
    ) throws {
        do {
            try operation()
        } catch is Decision.Error {
            return
        }

        throw TestFlowAssertionFailure(
            label: "decision invariant",
            message: "Expected a Decision.Error."
        )
    }

    private static func invariants()
        throws
        -> [TestDiagnostic]
    {
        for value in [
            -0.01,
            1.01,
            Double.infinity,
            Double.nan,
        ] {
            try rejects {
                _ = try Decision.Probability(value)
            }
            try rejects {
                _ = try Decision.Confidence(value)
            }
        }

        try rejects {
            _ = try JSONDecoder().decode(
                Decision.Probability.self,
                from: Data("1.01".utf8)
            )
        }

        try rejects {
            _ = try JSONDecoder().decode(
                Decision.Confidence.self,
                from: Data("1.01".utf8)
            )
        }

        try rejects {
            _ = try Decision.Content(
                structured: 42
            )
        }

        let structuredContent = try Decision.Content(
            structured: [
                "kind": "ticket",
                "detail": "routing",
            ]
        )

        guard case .structured = structuredContent.representation else {
            throw TestFlowAssertionFailure(
                label: "decision content",
                message: "Expected typed object content to erase as structured content."
            )
        }

        let textContent: Decision.Content = "Route this ticket."
        guard case .text("Route this ticket.") = textContent.representation else {
            throw TestFlowAssertionFailure(
                label: "decision content",
                message: "String-literal decision content did not preserve text."
            )
        }

        guard case .null = Decision.Content.null.representation else {
            throw TestFlowAssertionFailure(
                label: "decision content",
                message: "Decision null content did not preserve null semantics."
            )
        }

        try rejects {
            _ = try Decision.choice(
                instructions: "Choose.",
                options: [Decision.Option<String>]()
            )
        }

        let option = try Decision.Option(
            id: "same",
            value: "value",
            description: "Meaning"
        )

        try rejects {
            _ = try Decision.choice(
                instructions: "Choose.",
                options: [
                    option,
                    option,
                ]
            )
        }

        let duplicateValue = try Decision.Option(
            id: "other",
            value: "value",
            description: "Meaning"
        )

        try rejects {
            _ = try Decision.choice(
                instructions: "Choose.",
                options: [
                    option,
                    duplicateValue,
                ]
            )
        }

        try rejects {
            _ = try NativeStructuredAdapter().prepare(
                DecisionRouteFixture.self,
                input: "customer-support",
                realization: .init(
                    strategy: .direct,
                    instructions: "Route.",
                    budget: .singleAttempt
                )
            )
        }

        let specification = try DecisionRouteFixture.decision(
            for: "customer-support"
        )
        let query = specification.query
        let stateData = try JSONEncoder().encode(
            specification.state.value
        )
        let state = try JSONDecoder().decode(
            [String: String].self,
            from: stateData
        )

        try Expect.equal(
            state,
            [
                "ticket": "customer-support",
            ],
            "decision specification exposes only explicitly selected model-visible state"
        )

        try rejects {
            _ = try query.resolve([:])
        }

        try rejects {
            _ = try query.resolve([
                "route": .binary(
                    try .init(0.5)
                ),
            ])
        }

        try rejects {
            _ = try query.resolve([
                "route": .choice(
                    selected: "invented",
                    probabilities: [
                        "support": try .init(0.8),
                        "billing": try .init(0.2),
                    ],
                    confidence: nil
                ),
            ])
        }

        try rejects {
            _ = try query.resolve([
                "route": .choice(
                    selected: "support",
                    probabilities: [
                        "support": try .init(1),
                    ],
                    confidence: nil
                ),
            ])
        }

        try rejects {
            _ = try query.resolve([
                "route": .choice(
                    selected: "support",
                    probabilities: [
                        "support": try .init(0.8),
                        "billing": try .init(0.8),
                    ],
                    confidence: nil
                ),
            ])
        }

        let nonModeSelection = try query.resolve([
            "route": .choice(
                selected: "billing",
                probabilities: [
                    "support": try .init(0.8),
                    "billing": try .init(0.2),
                ],
                confidence: try .init(0.7)
            ),
        ])

        try Expect.equal(
            nonModeSelection.value,
            "billing",
            "choice permits a selected option other than the distribution mode"
        )
        try Expect.equal(
            nonModeSelection.mostProbableValues,
            [
                "customer-support",
            ],
            "choice exposes the distribution mode independently of the selected value"
        )

        let tiedSelection = try query.resolve([
            "route": .choice(
                selected: "support",
                probabilities: [
                    "support": try .init(0.5),
                    "billing": try .init(0.5),
                ],
                confidence: nil
            ),
        ])

        try Expect.equal(
            tiedSelection.mostProbableValues,
            [
                "customer-support",
                "billing",
            ],
            "choice preserves ties when exposing most-probable alternatives"
        )

        let malformed = """
        {"value":"missing","probabilities":[{"value":"present","probability":1}]}
        """

        try rejects {
            _ = try JSONDecoder().decode(
                Decision.Choice<String>.self,
                from: Data(malformed.utf8)
            )
        }

        return [
            .field(
                "rejected",
                "invalid probabilities, confidence, content, options, answer membership and distributions"
            ),
        ]
    }

    private static func composition()
        throws
        -> [TestDiagnostic]
    {
        let routeSpecification = try DecisionRouteFixture.decision(
            for: "customer-support"
        )
        let route = routeSpecification.query
        let review = try Decision.binary(
            id: "review",
            instructions: "Does this require review?"
        )
        let scale = try Decision.Scale(
            id: "severity_v1",
            levels: [
                try Decision.Option(
                    id: "low",
                    value: "low",
                    description: "Cosmetic"
                ),
                try Decision.Option(
                    id: "high",
                    value: "high",
                    description: "Blocking"
                ),
            ]
        )
        let score = try Decision.score(
            id: "severity",
            instructions: "How severe is the issue?",
            scale: scale
        )
        let combined = try Decision.zip(
            Decision.zip(
                route,
                review
            ),
            score
        )

        let answers: [String: Decision.Answer] = [
            "route": .choice(
                selected: "support",
                probabilities: [
                    "support": try .init(0.8),
                    "billing": try .init(0.2),
                ],
                confidence: nil
            ),
            "review": .binary(
                try .init(0.4)
            ),
            "severity": .score(
                probabilities: [
                    try .init(0.25),
                    try .init(0.75),
                ],
                confidence: try .init(0.9)
            ),
        ]

        let result = try combined.resolve(
            answers
        )

        try Expect.equal(
            result.0.0.value,
            "customer-support",
            "choice restores the offered application value"
        )
        try Expect.equal(
            result.0.1.value,
            0.4,
            "binary probability is not thresholded"
        )
        try Expect.equal(
            result.1.value,
            0.75,
            "score derives its expected ordinal position from the distribution"
        )
        try Expect.equal(
            result.1.scale.id,
            "severity_v1",
            "score retains scale identity"
        )
        try Expect.equal(
            result.1.probabilities.map(\.value),
            [
                "low",
                "high",
            ],
            "score retains authored level order"
        )
        try Expect.equal(
            result.1.confidence?.value,
            0.9,
            "confidence remains distinct from option probabilities"
        )

        let projected = combined.map {
            $0.0.0.value
        }
        let projectedValue = try projected.resolve(
            answers
        )

        try Expect.equal(
            projectedValue,
            "customer-support",
            "mapping preserves typed reconstruction"
        )

        try rejects {
            _ = try Decision.zip(
                route,
                route
            )
        }

        var extra = answers
        extra["unexpected"] = .binary(
            try .init(0.5)
        )

        try rejects {
            _ = try combined.resolve(extra)
        }

        let encodedScore = try JSONEncoder().encode(
            result.1
        )
        guard var scoreObject = try JSONSerialization.jsonObject(
            with: encodedScore
        ) as? [String: Any]
        else {
            throw TestFlowAssertionFailure(
                label: "decision score",
                message: "Encoded score was not a JSON object."
            )
        }

        scoreObject["value"] = 0.5
        let inconsistentScore = try JSONSerialization.data(
            withJSONObject: scoreObject
        )

        try rejects {
            _ = try JSONDecoder().decode(
                Decision.Score<String>.self,
                from: inconsistentScore
            )
        }

        let decoded = try JSONDecoder().decode(
            Decision.Score<String>.self,
            from: JSONEncoder().encode(
                result.1
            )
        )

        try Expect.equal(
            decoded,
            result.1,
            "score round-trips with its rubric and derived value"
        )

        _ = Decision.Choice<String>.jsonschema
        _ = Decision.Score<String>.jsonschema

        return [
            .field(
                "questions",
                String(combined.questions.count)
            ),
        ]
    }

    private static func sites()
        async throws
        -> [TestDiagnostic]
    {
        let context = ProgramContext(
            inference: DecisionAuthoringFixtureInvoker()
        )

        async let first = DecisionProgramFixture().run(
            "department-a",
            in: context
        )
        async let second = DecisionProgramFixture().run(
            "department-b",
            in: context
        )

        let outputs = try await (
            first,
            second
        )

        try Expect.equal(
            outputs.0.value,
            "department-a",
            "first invocation retains its option binding"
        )
        try Expect.equal(
            outputs.1.value,
            "department-b",
            "second invocation retains its option binding"
        )

        let initial = InferenceRealizationDefinition<
            DecisionRouteFixture
        >(
            identifier: "initial",
            configuration: .init(
                strategy: .direct,
                instructions: "Initial guidance",
                budget: .singleAttempt
            )
        )
        let replacement = InferenceRealizationDefinition<
            DecisionRouteFixture
        >(
            identifier: "replacement",
            configuration: .init(
                strategy: .direct,
                instructions: "Replacement guidance",
                budget: .singleAttempt
            )
        )
        let realization = try ProgramRealization<
            DecisionProgramFixture
        >(
            bindings: [
                .init(
                    DecisionProgramFixture.route,
                    realization: initial
                ),
            ]
        )
        let replaced = realization.replacing(
            DecisionProgramFixture.route,
            with: replacement
        )
        let invocation = try ProgramInferenceInvocation(
            DecisionProgramFixture.route,
            in: replaced
        )

        try Expect.equal(
            invocation.configuration.instructions,
            "Replacement guidance",
            "existing realization replacement accepts decision inference sites"
        )

        return [
            .field(
                "dispatch",
                "Inference requirement through existing ProgramContext and InferenceSite"
            ),
        ]
    }

    private static func transportGuard()
        async throws
        -> [TestDiagnostic]
    {
        let attempts = InferenceAttemptExecutor(
            modelInvoker: DecisionTransportFixture(),
            adapters: InferenceAdapterCatalog()
        )

        do {
            _ = try await attempts.execute(
                DecisionRouteFixture.self,
                input: "support-value",
                realization: .init(
                    strategy: .direct,
                    instructions: "Route.",
                    budget: .singleAttempt
                ),
                context: .default
            )

            throw TestFlowAssertionFailure(
                label: "decision transport guard",
                message: "Unsupported execution did not fail."
            )
        } catch let error as Decision.Error {
            try Expect.equal(
                error,
                .modelExecutionUnavailable,
                "decision execution fails before adapter lookup or generative invocation"
            )
        }

        return [
            .field(
                "execution",
                "explicitly rejected until decision transport is installed"
            ),
        ]
    }
}

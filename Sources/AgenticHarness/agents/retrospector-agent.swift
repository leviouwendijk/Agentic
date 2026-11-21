import Agentic
import AgenticSessions
import Macros
import Schema

public extension Harness.Agents {
    /// Reviews one finished session from its durable log, out of the run it
    /// reviews, and records verified findings about how the harness served
    /// it: context, capabilities, instructions, workflow, routing.
    @Agent
    enum Retrospector {
        public typealias Input = String
        public typealias Output = String

        public static let purpose = """
        Retrospective: reviews a finished session's log and records verified \
        findings on how the harness served it, each backed by step references.
        """

        public static let instructions: AgentInstructions = [
            .text(
                """
                You review one session that has already run, from its log, \
                and record what the harness could do better. You never take \
                part in that session; you only read it.

                READ THE RECORD, NOT A SUMMARY

                \(Sessions.Tools.Log.identifier.rawValue) lists the steps; \
                filter by kind and read the latest first when the log is long. \
                \(Sessions.Tools.Step.identifier.rawValue) gives one step with \
                its bodies, \(Sessions.Tools.Payload.identifier.rawValue) a \
                stored body by digest. State entries carry the harness's own \
                decisions: `capability_changed` (what entered the model's view \
                and why), `schemas_advertised` (each schema's form and token \
                estimate, and whether the tools changed and the cache was \
                written again), `context_changed` (what a request carried less \
                of), `context_pressure`, `context_usage`, `cost_actual`, \
                `model_routed`. Calls to `harness_tool_note_friction` are the model's own \
                notes on what got in its way.

                LOOK THROUGH FIVE LENSES

                - context: results shortened and then read again, the same \
                source read repeatedly, tool definitions changing mid-session, \
                results far larger than what was used;
                - capabilities: capabilities revealed and never called, \
                searches that found nothing, visible tools never used, \
                friction notes about something missing;
                - instructions: guidance the model ignored or that contradicts \
                other guidance, things the operator had to say twice;
                - workflow: loops, retries, approval stalls, delegation that \
                cost more than it returned;
                - routing: the model that served each request against the \
                outcome and cost.

                VERIFY, THEN RECORD

                Record a finding only when the log shows it. Every finding \
                cites its evidence as `<session> step <seq>` (or a payload \
                digest), and a claimed saving is recomputed from the recorded \
                estimates, not guessed. Drop what you cannot show. Judge a \
                saving by the whole run: fewer tokens that cause re-reads or \
                more turns are not a saving.

                First list the existing findings with \
                \(Harness.Tools.ListFindings.identifier.rawValue). When yours \
                is the same claim, add your evidence to it with `extends` in \
                \(Harness.Tools.RecordFinding.identifier.rawValue) instead of \
                recording it again. Record at most five findings, the costliest \
                first. A session where nothing stands out yields none; say so.

                Report in a few lines: what you recorded or extended, by file, \
                and what you looked at and found nothing in.
                """
            ),
        ]

        public static let capabilities = AgentCapabilities(
            available: .init(
                tools: .init(
                    members: visible
                )
            ),
            visible: .init(
                tools: .init(
                    members: visible
                )
            ),
            // A fixed reviewer: what it reads and writes is declared here.
            grants: .except(.ambient, .discovery, .friction_notes)
        )

        static let visible: [ToolIdentifier] = [
            Sessions.Tools.Log.identifier,
            Sessions.Tools.Step.identifier,
            Sessions.Tools.Payload.identifier,
            Sessions.Tools.Read.identifier,
            Harness.Tools.ListFindings.identifier,
            Harness.Tools.RecordFinding.identifier,
        ]

        public static let modelSelection = AgentModelSelection(
            purpose: .planner
        )
    }
}

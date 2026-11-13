enum AgentModelProviderNotes {
    /*
     Provider/discovery staging
     --------------------------

     Keep routing synchronous and snapshot-based.

     The broker should not call provider control planes during normal model
     routing. Routing should use AgentModelProfileCatalog, which is built from
     static providers or previously refreshed snapshots.

     AgentModelProfileDiscovery is an async maintenance/setup seam, not a
     hot-path routing dependency.

     Current known provider shapes:

     - Apple:
         static/local profile provider.
         No discovery needed unless Apple later exposes model variants.

     - AWS Bedrock:
         dynamic discovery is useful now.
         Bedrock can expose foundation model IDs, system inference profiles,
         application inference profiles, and provider-specific lifecycle quirks.

     - OpenAI:
         likely starts with curated static profiles.
         Discovery may later be useful for validating model availability.

     - Anthropic:
         likely starts with curated static profiles.
         Discovery may not be needed if model catalog APIs are not central.

     - Ollama:
         likely wants local discovery from installed model tags.
         This may become the second real discovery use case after Bedrock.

     Compaction rule:
         If only AWS uses discovery after the next few provider packages,
         consider moving some of this shape back down into AgenticAWS.
         If Ollama/OpenAI/Anthropic need it too, keep and harden this seam.
     */
}

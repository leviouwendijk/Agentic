public enum KnownModel {}

public extension KnownModel {
    enum claude {
        public static let opus_4_7: AgentModelID =
            "anthropic:claude-opus-4-7"
        public static let opus_4_6: AgentModelID =
            "anthropic:claude-opus-4-6"
        public static let opus_4_5: AgentModelID =
            "anthropic:claude-opus-4-5"
        public static let opus_4_1: AgentModelID =
            "anthropic:claude-opus-4-1"
        public static let sonnet_4_6: AgentModelID =
            "anthropic:claude-sonnet-4-6"
        public static let sonnet_4_5: AgentModelID =
            "anthropic:claude-sonnet-4-5"
        public static let sonnet_4: AgentModelID =
            "anthropic:claude-sonnet-4"
        public static let haiku_4_5: AgentModelID =
            "anthropic:claude-haiku-4-5"
        public static let haiku_3_5: AgentModelID =
            "anthropic:claude-3-5-haiku"
        public static let haiku_3: AgentModelID =
            "anthropic:claude-3-haiku"
    }

    enum nova {
        public static let premier: AgentModelID =
            "amazon:nova-premier"
        public static let pro: AgentModelID =
            "amazon:nova-pro"
        public static let lite: AgentModelID =
            "amazon:nova-lite"
        public static let micro: AgentModelID =
            "amazon:nova-micro"
    }

    static let foundation_models: AgentModelID =
        "apple:foundation-models"

    enum qwen {
        public static let coder_3_next: AgentModelID =
            "qwen:qwen3-coder-next"
        public static let coder_3_30b_a3b: AgentModelID =
            "qwen:qwen3-coder-30b-a3b"
        public static let next_3_80b_a3b: AgentModelID =
            "qwen:qwen3-next-80b-a3b"

        public static let qwen3_coder_next = coder_3_next
        public static let qwen3_coder_30b_a3b = coder_3_30b_a3b
        public static let qwen3_next_80b_a3b = next_3_80b_a3b
    }

    enum gpt_oss {
        public static let _120b: AgentModelID =
            "openai:gpt-oss-120b"
        public static let _20b: AgentModelID =
            "openai:gpt-oss-20b"
    }

    enum mistral {
        public static let large_3: AgentModelID =
            "mistral:large-3"
        public static let devstral_2: AgentModelID =
            "mistral:devstral-2"
        public static let ministral_14b: AgentModelID =
            "mistral:ministral-14b"
        public static let ministral_8b: AgentModelID =
            "mistral:ministral-8b"
        public static let ministral_3b: AgentModelID =
            "mistral:ministral-3b"
    }

    enum kimi {
        public static let k2_thinking: AgentModelID =
            "moonshot:kimi-k2-thinking"
        public static let k2_5: AgentModelID =
            "moonshot:kimi-k2-5"
    }

    enum deepseek {
        public static let v3_2: AgentModelID =
            "deepseek:v3-2"
        public static let r1: AgentModelID =
            "deepseek:r1"

        public static let `v3.2` = v3_2
    }

    enum glm {
        public static let v5: AgentModelID =
            "zai:glm-5"
        public static let v4_7: AgentModelID =
            "zai:glm-4-7"
        public static let v4_7_flash: AgentModelID =
            "zai:glm-4-7-flash"
    }
}

// Compatibility surface for the coordinated routing/provider migration.
// Remove these producer-oriented aliases after all downstream packages use
// the canonical family-oriented paths above.
public extension KnownModel {
    enum anthropic {
        public static let `claude_opus_4.7` = KnownModel.claude.opus_4_7
        public static let `claude_opus_4.6` = KnownModel.claude.opus_4_6
        public static let `claude_opus_4.5` = KnownModel.claude.opus_4_5
        public static let `claude_opus_4.1` = KnownModel.claude.opus_4_1
        public static let `claude_sonnet_4.6` = KnownModel.claude.sonnet_4_6
        public static let `claude_sonnet_4.5` = KnownModel.claude.sonnet_4_5
        public static let claude_sonnet_4 = KnownModel.claude.sonnet_4
        public static let `claude_haiku_4.5` = KnownModel.claude.haiku_4_5
        public static let `claude_3.5_haiku` = KnownModel.claude.haiku_3_5
        public static let claude_3_haiku = KnownModel.claude.haiku_3
    }

    enum amazon {
        public static let nova_premier = KnownModel.nova.premier
        public static let nova_pro = KnownModel.nova.pro
        public static let nova_lite = KnownModel.nova.lite
        public static let nova_micro = KnownModel.nova.micro
    }

    enum apple {
        public static let foundation_models = KnownModel.foundation_models
    }

    enum openai {
        public static let gpt_oss_120b = KnownModel.gpt_oss._120b
        public static let gpt_oss_20b = KnownModel.gpt_oss._20b
    }

    enum moonshot {
        public static let kimi_k2_thinking = KnownModel.kimi.k2_thinking
        public static let `kimi_k2.5` = KnownModel.kimi.k2_5
    }

    enum zai {
        public static let glm_5 = KnownModel.glm.v5
        public static let `glm_4.7` = KnownModel.glm.v4_7
        public static let `glm_4.7_flash` = KnownModel.glm.v4_7_flash
    }
}


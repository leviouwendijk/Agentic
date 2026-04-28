public enum KnownModel {}

public extension KnownModel {
    enum anthropic {
        public static let `claude_opus_4.7` = AgentModelID(
            provider: "anthropic",
            name: "claude-opus-4-7"
        )

        public static let `claude_opus_4.6` = AgentModelID(
            provider: "anthropic",
            name: "claude-opus-4-6"
        )

        public static let `claude_opus_4.5` = AgentModelID(
            provider: "anthropic",
            name: "claude-opus-4-5"
        )

        public static let `claude_opus_4.1` = AgentModelID(
            provider: "anthropic",
            name: "claude-opus-4-1"
        )

        public static let `claude_sonnet_4.6` = AgentModelID(
            provider: "anthropic",
            name: "claude-sonnet-4-6"
        )

        public static let `claude_sonnet_4.5` = AgentModelID(
            provider: "anthropic",
            name: "claude-sonnet-4-5"
        )

        public static let `claude_sonnet_4` = AgentModelID(
            provider: "anthropic",
            name: "claude-sonnet-4"
        )

        public static let `claude_haiku_4.5` = AgentModelID(
            provider: "anthropic",
            name: "claude-haiku-4-5"
        )

        public static let `claude_3.5_haiku` = AgentModelID(
            provider: "anthropic",
            name: "claude-3-5-haiku"
        )

        public static let claude_3_haiku = AgentModelID(
            provider: "anthropic",
            name: "claude-3-haiku"
        )
    }

    enum amazon {
        public static let nova_premier = AgentModelID(
            provider: "amazon",
            name: "nova-premier"
        )

        public static let nova_pro = AgentModelID(
            provider: "amazon",
            name: "nova-pro"
        )

        public static let nova_lite = AgentModelID(
            provider: "amazon",
            name: "nova-lite"
        )

        public static let nova_micro = AgentModelID(
            provider: "amazon",
            name: "nova-micro"
        )
    }

    enum apple {
        public static let foundation_models = AgentModelID(
            provider: "apple",
            name: "foundation-models"
        )
    }

    enum qwen {
        public static let qwen3_coder_next = AgentModelID(
            provider: "qwen",
            name: "qwen3-coder-next"
        )

        public static let qwen3_coder_30b_a3b = AgentModelID(
            provider: "qwen",
            name: "qwen3-coder-30b-a3b"
        )

        public static let qwen3_next_80b_a3b = AgentModelID(
            provider: "qwen",
            name: "qwen3-next-80b-a3b"
        )
    }

    enum openai {
        public static let gpt_oss_120b = AgentModelID(
            provider: "openai",
            name: "gpt-oss-120b"
        )

        public static let gpt_oss_20b = AgentModelID(
            provider: "openai",
            name: "gpt-oss-20b"
        )
    }

    enum mistral {
        public static let `large_3` = AgentModelID(
            provider: "mistral",
            name: "large-3"
        )

        public static let `devstral_2` = AgentModelID(
            provider: "mistral",
            name: "devstral-2"
        )

        public static let ministral_14b = AgentModelID(
            provider: "mistral",
            name: "ministral-14b"
        )

        public static let ministral_8b = AgentModelID(
            provider: "mistral",
            name: "ministral-8b"
        )

        public static let ministral_3b = AgentModelID(
            provider: "mistral",
            name: "ministral-3b"
        )
    }

    enum moonshot {
        public static let kimi_k2_thinking = AgentModelID(
            provider: "moonshot",
            name: "kimi-k2-thinking"
        )

        public static let `kimi_k2.5` = AgentModelID(
            provider: "moonshot",
            name: "kimi-k2-5"
        )
    }

    enum deepseek {
        public static let `v3.2` = AgentModelID(
            provider: "deepseek",
            name: "v3-2"
        )

        public static let r1 = AgentModelID(
            provider: "deepseek",
            name: "r1"
        )
    }

    enum zai {
        public static let glm_5 = AgentModelID(
            provider: "zai",
            name: "glm-5"
        )

        public static let `glm_4.7` = AgentModelID(
            provider: "zai",
            name: "glm-4-7"
        )

        public static let `glm_4.7_flash` = AgentModelID(
            provider: "zai",
            name: "glm-4-7-flash"
        )
    }
}

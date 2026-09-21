//! Shared contract between Ban Agent and Ban Center.
//!
//! Request/response/error types arrive in Stage 4 (step 4.5). Until then this
//! crate only exports the API version.

/// `AGENT_API_VERSION` (SemVer), versioned independently of the OS and the agent binary.
pub const AGENT_API_VERSION: &str = env!("CARGO_PKG_VERSION");

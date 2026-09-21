fn main() {
    println!(
        "ban-agent {} (api {})",
        env!("CARGO_PKG_VERSION"),
        ban_api_types::AGENT_API_VERSION
    );
}

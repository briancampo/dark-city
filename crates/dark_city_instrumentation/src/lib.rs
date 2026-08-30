//! `dark_city_instrumentation` provides metrics calculation (AWI M1–M11),
//! structured event logging, and audit verification.

use serde::{Deserialize, Serialize};

/// Agent World Index (AWI) core metrics snapshot (Blueprint §9.2).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub struct AwiSnapshot {
    /// M1: Population Health (active citizens).
    pub population_health: u32,
    /// M2: Safety & Public Order (cumulative hard violations).
    pub safety_violations: u32,
    /// M3: Governance Participation (turnout percentage [0.0, 1.0]).
    pub governance_turnout: f32,
    /// M8: Economic Gini coefficient [0.0, 1.0].
    pub economic_gini: f32,
    /// M9: Constitutional Growth (passed rule changes).
    pub constitutional_rule_changes: u32,
    /// M11: Tool Expansion (citizen-authored tools).
    pub citizen_created_tools: u32,
}

impl AwiSnapshot {
    /// Creates a new empty `AwiSnapshot`.
    pub fn new() -> Self {
        Self::default()
    }
}

/// Calculates the Gini coefficient over a slice of economic balances.
pub fn calculate_gini_coefficient(balances: &[f64]) -> f64 {
    if balances.is_empty() {
        return 0.0;
    }
    let mut sorted = balances.to_vec();
    sorted.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));

    let n = sorted.len() as f64;
    let sum: f64 = sorted.iter().sum();
    if sum == 0.0 {
        return 0.0;
    }

    let mut cumulative = 0.0;
    for (i, &val) in sorted.iter().enumerate() {
        cumulative += (2.0 * (i as f64 + 1.0) - n - 1.0) * val;
    }

    cumulative / (n * sum)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gini_calculation_equal() {
        let equal_wealth = vec![100.0, 100.0, 100.0, 100.0];
        let gini = calculate_gini_coefficient(&equal_wealth);
        assert!((gini - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_gini_calculation_unequal() {
        let unequal_wealth = vec![0.0, 0.0, 0.0, 100.0];
        let gini = calculate_gini_coefficient(&unequal_wealth);
        assert!(gini > 0.5);
    }
}

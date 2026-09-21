# Assistant Context

## Purpose

This document gives Posit AI, RStudio assistants, and other coding agents quick context for working in the Global Investment Advisor repository.

## Repository Role

This is not just a code repository. It is a reproducible research system for global investment analysis. Code changes should support better research discipline, better data quality, better investment memo generation, or clearer global opportunity screening.

## Primary User Workflow

The expected workflow is:

1. Use RStudio as the primary development environment.
2. Run setup from `R/00_setup.R`.
3. Run numbered scripts in `scripts/`.
4. Use outputs from `data/processed/`, `outputs/charts/`, and `outputs/tables/`.
5. Write investment memos in Quarto under `notebooks/` or `reports/investment_memos/`.

## Coding Priorities

Prioritize:

- Clarity
- Reproducibility
- R idioms
- Modular functions
- Explicit assumptions
- Informative errors
- Minimal dependencies

Do not prioritize:

- Clever one-liners
- Premature abstraction
- Python rewrites
- Unexplained financial models
- Opaque scoring systems

## Financial Research Priorities

Every research tool or script should help answer:

- What is the opportunity?
- What is the relevant U.S. benchmark?
- Why might the opportunity outperform?
- What are the risks?
- What data supports the view?
- What would invalidate the thesis?

## Suggested Assistant First Steps

When asked to help with this project:

1. Read `AGENTS.md`.
2. Read `README.md`.
3. Inspect the relevant file in `R/`, `scripts/`, `docs/`, or `notebooks/`.
4. Make the smallest useful change.
5. Explain how to test it in RStudio.


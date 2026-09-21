# Methodology — Split-Sample Modeling for 1-12 Month Coffee Price Signals

## Framing

For each forecast horizon \( h \in \{1, 3, 6, 9, 12\} \) months, build a
separate model predicting price \( h \) months ahead from information known
at time \( t \):

\[ \text{price}_{t+h} = f(\text{ONI}_t, \text{rainfall anomaly}_t, \text{FX}_t, \text{fertilizer cost}_t, \text{chokepoint severity}_t, \dots) + \epsilon \]

Multiple horizon-specific models (rather than one model with horizon as an
input) is standard practice here — it lets weather/climate features "peak"
in importance at the horizon where their physical transmission lag actually
operates (e.g. a frost event shows up in price within 1-3 months, but an
ENSO regime shift may matter more at 6-12 months when it affects the next
harvest cycle).

## Split-sample design

1. **Chronological split, not random** — for time series, a random
   train/test split leaks future information into training. Use:
   - **Train**: earliest ~70% of history (e.g. 2010–2021 if data starts 2010)
   - **Validation** (hyperparameter tuning / feature selection): next ~15%
   - **Test** (final robustness check, touched once): most recent ~15%
2. **Walk-forward / expanding window backtest** — after the initial
   train/validation/test split confirms the approach works, re-fit the
   model repeatedly on an expanding window and evaluate one-step-ahead
   (or h-step-ahead) out-of-sample error at each point. This gives you a
   realistic distribution of historical errors rather than a single test
   score, which is what you'll use for uncertainty bounds.
3. **Never tune on the test set.** If test-set performance disappoints,
   go back to the training/validation loop — don't adjust features to fit
   the held-out test data, or your "robustness check" becomes meaningless.

## Candidate model classes (start simple, add complexity only if justified)

| Model | Why | R package |
|---|---|---|
| Elastic net regression | Interpretable coefficients, handles correlated predictors (FX, rainfall, fertilizer often co-move), good baseline | `glmnet` |
| ARIMAX / dynamic regression | Explicitly models autocorrelation in price + exogenous regressors | `forecast`, `fable` |
| Quantile regression | Directly estimates uncertainty bounds (e.g. 10th/50th/90th percentile forecasts) rather than assuming normal errors | `quantreg` |
| Random forest / gradient boosting | Captures nonlinear interactions (e.g. drought x weak-Real double effect) | `ranger`, `xgboost` |
| Bayesian structural time series | Naturally decomposes trend/seasonal/regressor effects with credible intervals | `bsts` |

Recommendation: start with **elastic net + quantile regression** for
interpretability and built-in uncertainty bounds, then benchmark against
**gradient boosting** to check whether nonlinear interactions (the
"stacked risk" scenarios from the Space instructions) add meaningful
predictive power over the linear baseline. If boosting doesn't clearly
beat the linear model out-of-sample, prefer the simpler, more explainable
model for a decision-support tool like this.

## Uncertainty & error bounds

- Report **prediction intervals**, not just point forecasts. Quantile
  regression gives these directly; for other model classes, use residual
  bootstrapping on the walk-forward backtest errors.
- Track **error by regime**: does the model do worse during El Niño years,
  or during chokepoint disruption periods? If so, either add
  regime-interaction terms or explicitly widen the uncertainty band when
  the current period matches a historically harder-to-predict regime.
- Track **error by horizon**: 1-month error should be tighter than 12-month
  error — confirm this holds and surface horizon-specific bands in the UI
  rather than a single blended confidence figure.

## Validation checks before trusting a signal

1. **Out-of-sample R² / MAPE** on the untouched test window, by horizon.
2. **Directional accuracy** — did the model correctly call up/down moves,
   independent of magnitude? Often more decision-relevant than point error.
3. **Historical analog check** — for any live signal the platform surfaces,
   manually cross-check it against the model's own training-era analogs
   (e.g. "this rainfall anomaly + FX combination resembles Q3 2014" and
   confirm the model's implied price response matches what actually
   happened then).
4. **Sanity bounds** — cap predicted moves at plausible historical ranges;
   flag (don't suppress) any forecast that falls outside the training
   distribution's range, since that's exactly when the model is
   extrapolating and least trustworthy.

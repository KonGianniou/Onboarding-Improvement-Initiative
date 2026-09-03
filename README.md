DMAIC project, Quality Analyst role.

> **Disclaimer:** This was a real project, but the dataset here (counts, waves, stats) is synthetic — built to match the structure of the original analysis without exposing company data. Methodology and general findings reflect the real project, exact numbers don't.

## Background

New hires generate a spike of support questions in the weeks right after training ("nesting"). Each question costs coach time and slows the new hire down. I wanted to know whether these questions were concentrated in a few topics or spread evenly and if concentrated, whether a short pre-nesting quiz could reduce them.

## Method (DMAIC)

- **Define**
**The problem**: nobody knew whether nesting questions were random noise or concentrated in specific topics. If concentrated, that's a fixable training gap. If spread evenly, no single intervention would move the needle, and the smarter move would be a broader content review instead.
**Goal**: find the topics driving the most questions, build a cheap intervention, and measure whether it actually worked — not just assume it did because it felt right.

- **Measure:**
Logged 529 questions (Wave 7, baseline) and 224 questions (Wave 9, post-intervention) across 20 topics, using the same taxonomy both times so the comparison would hold up. Top 5 Wave 7 topics — Property details, Finance, Availability, Commercial, Compliance — made up 58% of all questions. That's a real Pareto pattern, not an even spread, which is what justified building a targeted quiz instead of reworking all 20 topics of training content.

- **Analyze:** 
Ran a chi-square test on the full topic × wave table to check if the overall mix changed at all, then per-topic two-proportion tests with Benjamini–Hochberg correction, since testing 20 topics at once means some will look "significant" purely by chance if you don't correct for it.

- **Improve:** 
Built a short quiz covering the top-volume topics and distributed it before Wave 9 started nesting. One deliberate design choice: I made the quiz *hard*. Not hard for the sake of it but hard on purpose, so most new hires would get several questions wrong the first time through. The logic is the same as why flashcards work better than re-reading notes: getting something wrong and then seeing the correct answer creates a much stronger memory than passively skimming content you already vaguely recognize. An easy quiz gets rubber-stamped and forgotten but a quiz that makes you sweat a little gets remembered. I wanted new hires to fail on the quiz, not fail three weeks later in front of a customer.

- **Control:** 
Compared Wave 7 vs Wave 9 with the same process and topic taxonomy to see what actually moved, and built the significance testing in from the start so "it worked" would mean something more than a gut feeling.

## Business Impact

The real cost of nesting questions isn't the question itself, it's what it represents: a coach pulled off other work, a new hire sitting idle waiting on an answer, and a slower ramp to full productivity. At Wave 7's volume, that's 529 individual interruptions spread across one cohort. Even a partial reduction in the highest-volume topics compounds across every future cohort that goes through the same training, which is exactly why this was worth building a proper before/after measurement for rather than shipping the quiz and moving on.

Two things came out of this that matter beyond the stats:

- **One confirmed, fixable gap** (Extranet account) that the current training doesn't cover at all, a direct, low-effort addition to the next quiz version.
- **One strong signal, not yet proof** (Availability) that the hard-quiz approach may be working exactly as designed, on the exact topic it was built for but I'm not willing to tell leadership "problem solved" off a result that doesn't survive correction for multiple comparisons. That's the difference between a quality analyst reporting a real effect and one reporting a number that happened to move.

The bigger payoff, if Availability's effect replicates with more data, isn't really about this one cohort, it's evidence that a short, deliberately difficult, low-cost quiz can meaningfully cut nesting support load before it happens, which is a much cheaper lever than adding coach headcount or extending the nesting period itself.


## Results

Overall topic mix changed significantly between waves (χ² = 33.0, df = 19, p = 0.024, Cramér's V = 0.21).

Per-topic, after BH correction for 20 comparisons, only one topic held up:

| Topic | Δ share (pp) | Share ratio | p (BH-adjusted) | Significant |
|---|---|---|---|---|
| Extranet account | +6.8 | 2.57× | 0.009 | Yes |
| Availability | −5.6 | 0.45× | 0.119 | No |
| Property details | −0.8 | 0.95× | 0.929 | No |
| Finance | −2.6 | 0.81× | 0.725 | No |

**Extranet account** rose from 4.4% to 11.2% of all questions and wasn't a quiz topic — a genuine new gap, not something the quiz caused.

**Availability** had the largest raw drop (53 → 10 questions) and was the quiz's main target, but the effect doesn't survive multiple-comparison correction at this sample size. It's a strong directional result, not a confirmed one — Wave 9's n = 224 likely wasn't large enough to detect an effect this size at significance. Worth re-testing with a bigger sample before calling it a win.

Property details and Finance, the two biggest baseline topics, moved in the right direction but not significantly. A few low-volume topics look like they grew in share, but their raw counts barely changed — mostly an artifact of Availability's big drop shrinking the denominator.

## Charts

| | |
|---|---|
| ![Raw counts](images/01_raw_counts_by_topic.png) Raw counts by topic | ![Composition](images/03_composition_by_topic.png) Topic composition, each wave |
| ![Change in share](images/04_change_in_share_pp.png) Change in share (pp) | ![CI](images/05_change_in_share_with_CI.png) Change with 95% CI |
| ![Residuals](images/09_chisq_standardised_residuals.png) Chi-square residuals | ![Scatter](images/11_share_scatter_wave7_vs_wave9.png) Wave 7 vs Wave 9 share |

Full chart set in [`images/`](images/).

## Recommendations

- Add Extranet account to the quiz — the one statistically confirmed gap.
- Keep Availability in the quiz, but don't close the loop on it yet — re-measure with a larger next cohort before calling it resolved.
- Leave the small movers alone unless raw counts start climbing, not just share.
- Size the next measurement wave with enough sample to actually detect an effect Availability's size, not just repeat an inconclusive test.

## Limitations

Before/after comparison, not randomized — can't fully rule out other factors changing between waves. Wave 9's smaller sample limits power to detect real effects, which is the main open question this project leaves behind.

## Files

- `README.md` — this file
- `images/` — charts
- Analysis in R (`tidyverse`, `broom`, `scales`, `patchwork`, `ggrepel`)

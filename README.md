# Onboarding-Improvement-Initiative
📚 New Hire Onboarding Quiz — Pre/Post Intervention Study

This is a DMAIC project I ran while working as a quality analyst, looking at a pattern that kept coming up in onboarding support: new hires ask a lot of the same questions in their first few weeks, and most of it is predictable. The project tests whether a short pre-boarding quiz, built around the highest-volume topics, actually cuts down how many questions people ask once they're in the role.

The data here has been anonymized — topic names, wave numbers, and counts have been altered so nothing ties back to the original cohort or company. The structure and the findings reflect the real analysis.

---

## The Problem
When new hires join a company, they typically ask a large volume of questions during their
onboarding period — many of which are repetitive and predictable. If those recurring questions
could be anticipated and answered proactively, it would save time for both new hires and the
teams supporting them, and accelerate their time to productivity.

## The setup

Two onboarding cohorts, Wave 7 and Wave 9 (keeping the wave numbering style from the original program). Wave 7 is the baseline — new hires ask questions freely, everything gets logged and tagged by topic, no quiz exists yet. I ran chi-squared tests on that baseline to find which topics were generating disproportionately more questions than expected. Those became the 8 topics covered in the new onboarding quiz.

Wave 9 hires took that quiz before starting. I logged their questions against the same topic taxonomy once they were in role, then compared Wave 7 vs Wave 9 volumes topic by topic to see if quiz-covered topics dropped more than the ones the quiz didn't touch.


```
Wave 7 (Baseline)
│
│  New hires onboard and ask questions freely.
│  All questions are logged and categorised by topic.
│  No quiz exists yet.
│
▼
Analysis of Wave 7 data
│
│  Chi-squared tests identify which topics generated
│  significantly more questions than expected.
│  The highest-need topics are selected for quiz coverage.
│
▼
Quiz Creation
│
│  A targeted onboarding quiz is built covering
│  the 8 topics identified as the biggest knowledge gaps.
│  The quiz is deployed before Wave 9 new hires arrive.
│
▼
Wave 9 (Post-intervention)
│
│  New hires complete the quiz during pre-boarding.
│  They then go through onboarding and ask questions.
│  Question volume is recorded using the same topic taxonomy.
│
▼
Pre/Post Analysis
│
│  Chi-squared tests and paired t-tests compare
│  Wave 7 vs Wave 9 question volumes by topic.
│  Topics covered by the quiz show a statistically
│  significant reduction in question volume.
```
Hypothesis
> \*\*Topics covered by the quiz will show a statistically significant reduction in
> question volume in Wave 9 compared to Wave 7. Topics not covered by the quiz
> will not show the same pattern.\*\*
---
📊 Key Findings (Synthetic)

Metric	Value

Topics tracked	20

Topics included in quiz	8

Avg. question reduction — quiz topics	~55%

Avg. question reduction — non-quiz topics	~60%

Quiz topics with significant reduction (p < 0.05)	Majority

Individual new hires asking fewer questions in Wave 9	Majority of 50

> These figures are illustrative and derived entirely from synthetic data.
---
🗂️ Repository Structure
```
wave\_analysis/
│
├── wave\_analysis.R                ← Main R script — full analysis pipeline
│
├── DATA.csv                       ← Core dataset: 20 topics × Wave 7 \& Wave 9 counts + quiz flag
├── DataChi.csv                    ← Wave 7 baseline: raw vs weighted counts (quiz selection step)
├── DataChi2.csv                   ← Individual new hire question totals (50 per wave)
├── Pairedt\_test.csv               ← Matched topic-level counts for paired t-test
├── Timeseries.csv                 ← Daily question volume by topic and wave
├── DATA\_Total.csv                 ← Wave 7 topic totals (baseline bar chart source)
│
├── fig1\_wave7\_baseline.png        ← Bar chart: Wave 7 questions by topic, quiz topics highlighted
├── fig2\_timeseries.png            ← Daily volume: Wave 7 vs Wave 9 for top 3 topics
├── fig3\_reduction\_by\_topic.png    ← % reduction per topic, quiz vs non-quiz highlighted
├── fig4\_chisq\_significance.png    ← Chi-squared significance chart (log p-values)
├── fig5\_scatter\_prepost.png       ← Wave 7 vs Wave 9 scatter with reference lines
│
├── results\_wave7\_vs\_wave9.csv     ← Full pre/post chi-squared results table
├── results\_wave7\_baseline.csv     ← Wave 7 baseline chi-squared results (quiz selection)
│
└── README.md                      ← This file
```
---
📂 Dataset Descriptions

> `DATA.csv` — Core pre/post dataset

The primary analysis table. Each row is one contact topic, with question counts for

Wave 7 (before quiz) and Wave 9 (after quiz), plus a flag indicating whether that

topic was included in the quiz.


`ID`	Topic row number (1–20)

`Topic`	Contact topic category

`Wave\_7`	Questions asked by Wave 7 new hires (pre-quiz baseline)

`Wave\_9`	Questions asked by Wave 9 new hires (post-intervention)

`Wave\_7\_Weighted`	Wave 7 counts adjusted for cohort size differences

`In\_Quiz`	TRUE if this topic was covered by the onboarding quiz


> `DataChi.csv` — Wave 7 baseline (quiz selection)

Used in the first analysis step to identify which topics were the biggest relative

knowledge gaps. Chi-squared tests compare raw vs weighted Wave 7 counts; significant

topics became quiz content.

`ID`-->	Topic row number

`Topic`-->	Contact topic category

`Wave\_7`-->	Raw Wave 7 question count

`Wave\_7\_Weighted`-->	Cohort-size-adjusted Wave 7 count


> `DataChi2.csv` - Individual new hire question totals

Each row is one new hire. Captures total questions asked across the onboarding period,
allowing the pre/post comparison to be validated at the individual level.


`NewHireID`	--> Anonymised new hire identifier

`Wave\_7\_Questions`-->	Total questions asked by a Wave 7 new hire

`Wave\_9\_Questions`-->	Total questions asked by a Wave 9 new hire


> `Pairedt\_test.csv` — Matched topic pairs for t-test

The same 20 topics with Wave 7 and Wave 9 counts, structured for the paired t-test.
Each topic is its own matched pair across waves.


`Topic`-->	Contact topic category

`Wave\_7\_Count`-->	Question count in Wave 7

`Wave\_9\_Count`	--> Question count in Wave 9


> `Timeseries.csv` - Daily question volume

Daily question counts for the three highest-volume topics across the 30-day
onboarding window in each wave. Used to check whether the reduction is consistent
across the onboarding period, not just a point-in-time artefact.

`Date`-->	Calendar date

`Wave`	--> Survey wave (7 = baseline, 9 = post-intervention)

`Topic`-->	Contact topic

`n`	--> Questions asked on that date


> `DATA\_Total.csv` — Wave 7 topic totals for bar chart

Wave 7 question counts per topic with quiz flag. Source for the baseline bar chart
that shows which topics drove the quiz design decision.


`Topic`-->	Contact topic category

`n`	--> Total Wave 7 question count

`In\_Quiz`-->	TRUE if this topic entered the quiz

---
📈 Statistical Methods

> Step 1 — Chi-squared: quiz topic selection
> 
Compares each topic's raw Wave 7 count against its cohort-weighted count.
Topics where the two differ significantly (p < 0.05) represent disproportionate
knowledge gaps — these were selected for the quiz.

> Step 2 — Chi-squared: pre/post topic comparison
> 
Compares each topic's Wave 7 count to its Wave 9 count.
A significant result (p < 0.05) indicates the quiz measurably reduced question
volume for that topic.

> Step 3 — Chi-squared: individual new hire level
> 
Validates the topic-level finding at the individual level. Tests whether each
new hire's total question count shifted between waves.

> Step 4 — Paired t-test (three comparisons)
> 
Topic-level paired: each of the 20 topics is a matched pair; tests whether the mean reduction across topics is significantly different from zero.
Individual independent: compares mean total questions per new hire between waves as independent groups.
Quiz vs non-quiz reduction: tests whether the % reduction was significantly greater for quiz topics — the key directional test of the intervention's effect.

---
📉 Figures

Fig 1	Wave 7 question volume by topic, quiz topics highlighted in blue
> Shows the data-driven basis for which topics entered the quiz

Fig 2	Daily question volume for top 3 topics, Wave 7 vs Wave 9
> Demonstrates the reduction is consistent across the onboarding period

Fig 3	% question reduction per topic, quiz vs non-quiz coloured
> Directly visualises the intervention effect at topic level

Fig 4	−log₁₀(p-value) chart from chi-squared tests	
> Shows which reductions are statistically significant

Fig 5	Scatter of Wave 7 vs Wave 9 counts with reference lines	
> Holistic pre/post view with identity and 50%-reduction reference lines
> 
---
🛠️ Technologies Used

R	Core analysis language

ggplot2	All data visualisations

dplyr / tidyr	Data wrangling and reshaping

patchwork	Combining multiple ggplot2 panels

RColorBrewer	Colour palettes

scales	Axis formatting (percentages, labels)

hrbrthemes	Clean typographic base theme

---
▶️ How to Run
Clone or download this repository
Place all `.csv` files in the same directory as `wave\_analysis.R`
Open R or RStudio and set the working directory:
```r
   setwd("path/to/wave\_analysis")
   ```
Run the full pipeline:
```r
   source("wave\_analysis.R")
   ```
Or from terminal:
```bash
   Rscript wave\_analysis.R
   ```
Package installation is handled automatically at the top of the script.
---
⚠️ Disclaimer
This project uses fully synthetic data generated for portfolio purposes only.
No real employees, cohorts, or company data were involved. All values are fabricated.

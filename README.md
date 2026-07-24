# 2026 CCD IJRUME

Cognitive diagnostic modeling (DINA/GDINA) analysis of three calculus/precalculus
assessments -- **CCA** (Calculus Concept Assessment), **CCI** (Calculus Concept
Inventory), and **PCA** (Precalculus Concept Assessment) -- scored against five
broad skills: Prerequisites, Limits, Derivatives, Applications of Derivatives,
and Integration.

This project originated with Kevin Roberge and Jayson Nissen, and was
reported in two conference papers:

* Roberge, K., Le, V., Van Dusen, B., & Nissen, J. M. (2025). Calculus
  Cognitive Diagnostic: Mathematics skills tested in first semester calculus
  courses. *2025 PERC Proceedings*, 368-373.
  https://doi.org/10.1119/perc.2025.pr.Roberge
* Roberge, K., Nissen, J. M., Le, V., & Van Dusen, B. (2026). Moving Beyond
  Total Scores with Skill-Proficiency Profiles on Concept Inventories.
  *Proceedings of the Conference on Research in Undergraduate Mathematics
  Education.* (The article is a presubmission draft, its own
  reference list cites itself with placeholder page numbers, so final
  volume/page/DOI details aren't available yet. Per the Roberge agendas,
  it was accepted in Oct 2025 and presented Feb 26-28, 2026, despite the
  "RUME 2025" name still used for the file and variables throughout this
  codebase.)

Author affiliations: Kevin Roberge, University of Maine; Vy Le and Ben Van
Dusen, School of Education, Iowa State University; Jayson M. Nissen,
Department of Physics, Montana State University.

Michael Bostick inherited the project and is extending it toward an IJRUME
journal submission.

## Two parallel tracks: legacy vs. corrected

Every part of the pipeline has two versions, on purpose:

| | Legacy (`.R`) | Corrected (`.Rmd`) |
|---|---|---|
| **Purpose** | Exactly reproduces the PERC2025/RUME conference results, as originally run | Fixes known bugs and methodological issues; the basis for the IJRUME manuscript |
| **Editing policy** | Minimum edits only, just enough to make the script *run* (missing files, typos, undefined variables). Known issues are documented in comments, not fixed. | Where corrections actually happen. Freely edited as understanding improves. |
| Data prep | `datascript2.R` | `datascript2.Rmd` |
| Main analysis | `IJRUME_analysis.R` | `IJRUME_analysis.Rmd` |

**Read the header comments in `IJRUME_analysis.R` and `datascript2.R` before
touching either file**, they list every fix that was needed just to make
the script run, and every known-remaining issue that was deliberately left
unfixed there (with an explanation of why, and where the fix actually lives).
A "minimum edits only" policy applied to
`IJRUME_analysis.R`, since that script actually produced the conference
papers' numbers. `datascript2.R` never did, the historical `v12` files it
reads predate it.

If your goal is reproducing the published papers exactly: run the `.R`
files, or see `PERC_RUME_Reproduction.Rmd` (below) for a filtered
reconstruction that gets closer to the papers' exact reported numbers. If
your goal is correct, defensible results for a new manuscript: run the
`.Rmd` files.

## Pipeline order

```
download_lasso_data.Rmd          (pulls fresh CCA/CCI data from the LASSO API)
        |
        v
datascript2.R  or  datascript2.Rmd    (cleans/scores raw data -> analysis-ready CSVs)
        |
        v
IJRUME_analysis.R  or  IJRUME_analysis.Rmd   (HLM, IRT, and CDM/Sankey analysis)
```

`IJRUME_analysis.R`/`.Rmd` currently read `cci_data_v12.csv`/`cca_data_v12.csv`
(the historical, already-prepared files used for the conference papers) and
`pca_data.csv`, **not** the `_v13` files `datascript2.R`/`.Rmd` produce,
those v13 files are a separate, forward-looking pipeline for extending the
dataset with newer LASSO downloads, not yet wired into the main analysis.
See the "Version requirement" note in `IJRUME_analysis.Rmd` before changing
this.

PCA's data (`pca_8_23_df.csv`) is not currently fetched by
`download_lasso_data.Rmd`, its provenance is still being confirmed (see
`Qmatrix_documentation.Rmd`).

## Reproducing the conference papers exactly: `PERC_RUME_Reproduction.Rmd`

The `v12` CSVs turned out to have been appended to after both papers were
submitted (see "Known open issues" below), so simply running
`IJRUME_analysis.R` against the current `v12` files no longer reproduces
the papers' reported sample sizes. `PERC_RUME_Reproduction.Rmd` attempts a
closer reproduction: it applies the same modeling choices as
`IJRUME_analysis.R` (DINA for CCA/CCI, GDINA for PCA) to `v12` data
filtered down to each paper's stated year windows, then compares every
resulting table against the published values side by side. It's a
separate, self-contained document, distinct from both the frozen `.R`
script and the go-forward `.Rmd` files, which don't do any year-filtering.

### How close does it get? (as of 2026-07-24)

| Table | Match? | What differs |
|---|---|---|
| PERC Table I (descriptive stats) | Partial for CCA/CCI, close for PCA | CCA/CCI means run high vs. published (CCA +5.6, CCI +0.7); N is off in both directions, CCA/CCI *below* published. PCA, after the fixes below: n=1279 vs. published 1260 (off by 19), mean 44.6 vs. 44.3. |
| Institution/course/instructor counts | No for CCA/CCI, near-exact for PCA | CCA 6 vs 7 institutions (25 vs 42 courses, 10 vs 12 instructors). CCI 4 vs 5 (97 vs 123, 9 vs 10). PCA, after the fixes: 8 institutions vs. published 8 (**exact**), 39 courses vs. published 40. |
| PERC Table IV (item distribution) | **Exact** | Matches to the item, all 3 instruments, all 5 skills. |
| PERC Table V (RMSEA/SRMSR) | Very close, PCA now exact on RMSEA | CCA/CCI within 0.001-0.004 of published. PCA (fixed population): RMSEA 0.034 vs. published 0.034 (**exact**), SRMSR 0.045 vs. 0.043. |
| PERC Table VI (classification accuracy) | CCA exact, CCI near-exact, PCA mixed | CCA: all 5 skills match exactly (0.90/0.90/0.88/0.78/0.87). CCI: 4 of 5 exact, only Integration differs (0.97 vs 0.98). PCA (fixed population): Applications of Derivatives now **exact** (0.87 vs. 0.87). Limits is still the outlier, off by 0.18 (0.86 vs. published 0.68), likely a separate measurement-invariance issue (see below). |
| RUME Table 1 | Same as PERC's | Directly reuses PERC's PCA/CCI Table IV/VI results -- no separate computation. |
| RUME Table 2 (HLM) | Close, one metric off | Coefficients and effect direction match well for both PCA and CCI; `df` runs higher than published in both (more matched pairs in our data than the paper used). |
| RUME matched-pairs effect sizes | **Essentially exact** | CCI d=0.27 vs. published 0.26. PCA (fixed population): n=905 vs. published 897 (off by 8), mean_pre 44.9/17.3 vs. 44.4/17.1, mean_post 46.5/17.2 vs. 46.0/17.3, d=0.09 vs. published 0.09 (**exact**). Institutions 6 vs. 6 (**exact**), courses 33 vs. 33 (**exact**). |
| RUME Sankey -- CCI | Right direction, smaller effect | "00000" (no-proficiency) group shrinks in both, similar magnitude. Unaffected by the PCA fixes. |
| RUME Sankey -- PCA | Right direction, smaller magnitude | Before any fix, the "0000" group *grew* pretest-to-posttest, the wrong direction. After the fixes below it *shrinks* (38.2%->33.7%, an 11.8% relative decrease), the right direction, though still well short of published's -51% relative magnitude. |

### The two PCA fixes that get Table I and the institution/course counts almost exact

Diffing `pca_data.csv` (the file PCA was originally read from) against its
raw source `pca_8_23_df.csv` turned up two transformations baked into it,
only one of which either paper documents. Both are now fixed in
`PERC_RUME_Reproduction.Rmd`'s `pca-dedup-helpers` chunk, which rebuilds
PCA's scores directly from the raw file instead of reading `pca_data.csv`:

1. **Deduplication.** PERC2025's methods state: *"In cases where students
   completed the same assessment multiple times, we only used their first
   response to the most recent post test."* That rule wasn't applied
   anywhere in the pipeline as received. `pca_8_23_df.csv` has 255
   students with repeat entries (different courses/terms) in the eligible
   population. Fix: keep each student's most-recent record (preferring one
   with a post-score present), excluding the handful of Learning
   Assistant/Faculty rows LASSO includes in the raw file.
2. **An undocumented course-size filter, found and removed.** Verified by
   diffing every row of `pca_data.csv` against `pca_8_23_df.csv`:
   `pca_data.csv` already applies PERC's exact stated eligibility rule
   (duration >= 5 min AND >= 80% of questions attempted, checked against
   all 2,681 rows with zero exceptions), but it *also* drops every course
   with fewer than 10 raw rows, which neither paper's methods section
   mentions and which no script currently in this repo implements
   (`datascript2.R` never processes PCA at all; an earlier version of
   this document incorrectly attributed the filter to it). That filter
   removes 7 courses / 34 rows, including `institution_id` 318's only
   course (6 students, all pretest-only). The raw file's own footprint,
   **8 institutions, 40 courses, with zero filtering applied**, matches
   PERC2025's stated "eight institutions across forty unique math courses"
   exactly, which is strong evidence the course-size cutoff was never part
   of the original analysis.

| | n | mean | median | sd | institutions | courses |
|---|---|---|---|---|---|---|
| Current (year-filtered only) | 1476 | 45.1 | 44.0 | 17.8 | 6 | 29 |
| + both fixes (dedup, no course-size filter) | 1279 | 44.6 | 44.0 | 17.6 | 8 | 39 |
| Raw file, zero filtering at all | -- | -- | -- | -- | 8 | 40 |
| Published | 1260 | 44.3 | 42.3 | 17.7 | 8 | 40 |

That closes the N gap from 216 down to 19, and gets institutions to an
exact match and courses within 1. The fixes carry through to every other
PCA table that uses the post-only or matched-pairs population (Table V,
Table VI, RUME's matched-pairs stats, and the Sankey diagram); see the
row-by-row comparison above.

**This doesn't generalize to CCA/CCI.** Both have repeat-student records
too, but their post-only N is already at or below published, so
deduplicating would only pull them further away (checked directly, not
applied to them). Their institution-count gap looks like genuinely missing
coverage rather than duplicate inflation, and it can't be diagnosed the
same way PCA's was, `v12`'s institution IDs for CCA/CCI don't map to the
raw LASSO export's IDs in any way currently available in this repo, and
neither `cca_data_v12.csv`/`cci_data_v12.csv` carries the course-size-filter
provenance issue PCA had (they predate `datascript2.R` entirely).

## The Q-matrix

**Start with `Qmatrix_documentation.Rmd`** if you need to understand or
modify the Q-matrix (which items map to which skills). It is the single
source of truth: full history of how the Q-matrix evolved, the underlying
27-learning-outcome taxonomy, verification against the published PERC2025
numbers, and critically it **regenerates `Qmatrix.xlsx` from source**
(`CCD-second coding.xlsx`) rather than treating `Qmatrix.xlsx` as a
hand-edited file that can silently drift out of sync with its own history.

Don't hand-edit `Qmatrix.xlsx` directly. Edit `Qmatrix_documentation.Rmd`
(or its source workbook) and re-render with `write_qmatrix: true`.

## Repo layout

```
IJRUME_analysis.R / .Rmd          main analysis (see table above)
PERC_RUME_Reproduction.Rmd        filtered reconstruction of the conference papers (see above)
datascript2.R / .Rmd              data prep (see table above)
download_lasso_data.Rmd           pulls raw CCA/CCI data from LASSO's API
Qmatrix_documentation.Rmd         Q-matrix history + reconstruction (see above)
Qmatrix.xlsx                      the Q-matrix, generated by Qmatrix_documentation.Rmd
CCD-second coding.xlsx            source coding workbook Qmatrix.xlsx is derived from
cci_data_v12.csv, cca_data_v12.csv, pca_data.csv, pca_8_23_df.csv
                                   analysis-ready data (see "Pipeline order" above)
unused_files/                     not read by any script; kept only because they're
                                   referenced by name in Qmatrix_documentation.Rmd's
                                   history section (an older Q-matrix coding stage,
                                   a superseded manual LASSO export, an orphaned
                                   plotting script)
```

## Known open issues

See the header comments in `IJRUME_analysis.R` and `datascript2.R`, and the
"Open questions" section at the end of `Qmatrix_documentation.Rmd`, for the
full list with evidence. Highlights:

* The CCA item-12 eligibility rule (`datascript2.R`/`.Rmd`) never matched
  any real data in the LASSO export, silently NA-ing every CCA score,
  fixed 2026-07-23 (removed; CCA now uses the same 80%-attempted rule as
  CCI). What item 12 itself actually measures is still an open question,
  just no longer gates scoring.
* Reproducing the RUME2025 paper's Sankey/skill-profile figures requires a
  matched-pairs population that the legacy `.R` script doesn't use, and even
  then PCA's profile transitions don't fully reproduce, likely a
  measurement-invariance question in how the CDM section fits pre/post
  models independently.
* PCA's data provenance (which LASSO export, or whether it came from
  elsewhere) isn't confirmed.
* The Q-matrix's item content (actual question wording) isn't documented
  anywhere in this repo, and can't be pulled via LASSO's API (it only
  returns item numbers/response data, never text). Confirming or extending
  the Q-matrix coding requires reviewing the test items directly in LASSO
  or obtaining a full copy of the assessments (if one exists), not yet
  done. Test items are confidential and are intentionally not reproduced
  in this public repo.
* The v12 CSVs are not frozen snapshots of what the two papers analyzed:
  their newest rows (~51 CCA rows and ~283 CCI rows, dated Fall 2024/
  Spring 2025) postdate both papers' stated data-collection windows and
  match student IDs found in a September 2025 LASSO export, meaning v12
  was likely appended to after submission. See `PERC_RUME_Reproduction.Rmd`
  for the detailed comparison, exact year-filter bounds, and an attempt to
  recover the papers' original results by filtering them back out.

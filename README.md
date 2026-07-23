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
  Education.* (The file in this repo is a presubmission draft -- its own
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
| **Editing policy** | Minimum edits only -- just enough to make the script *run* (missing files, typos, undefined variables). Known issues are documented in comments, not fixed. | Where corrections actually happen. Freely edited as understanding improves. |
| Data prep | `datascript2.R` | `datascript2.Rmd` |
| Main analysis | `IJRUME_analysis.R` | `IJRUME_analysis.Rmd` |

**Read the header comments in `IJRUME_analysis.R` and `datascript2.R` before
touching either file** -- they list every fix that was needed just to make
the script run, and every known-remaining issue that was deliberately left
unfixed there (with an explanation of why, and where the fix actually lives).
The "minimum edits only" policy applies most strictly to
`IJRUME_analysis.R`, since that script actually produced the conference
papers' numbers. `datascript2.R` never did -- the historical `v12` files it
reads predate it -- so its CCA item-12 bug (see "Known open issues" below)
was fixed directly rather than just commented on, since preserving a bug
in a script that was never the source of the papers' data serves no
reproduction purpose.

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
`pca_data.csv`, **not** the `_v13` files `datascript2.R`/`.Rmd` produce --
those v13 files are a separate, forward-looking pipeline for extending the
dataset with newer LASSO downloads, not yet wired into the main analysis.
See the "Version requirement" note in `IJRUME_analysis.Rmd` before changing
this.

PCA's data (`pca_8_23_df.csv`) is not currently fetched by
`download_lasso_data.Rmd` -- its provenance is still being confirmed (see
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
separate, self-contained document -- distinct from both the frozen `.R`
script and the go-forward `.Rmd` files, which don't do any year-filtering.

### How close does it get? (as of 2026-07-24)

| Table | Match? | What differs |
|---|---|---|
| PERC Table I (descriptive stats) | Partial | All 3 instruments' means run high vs. published (CCA +5.6, CCI +0.7, PCA +0.8 before the fix below). N is off in both directions -- CCA/CCI *below* published, PCA *above*. |
| Institution/course/instructor counts | No | CCA 6 vs 7 institutions (25 vs 42 courses, 10 vs 12 instructors). CCI 4 vs 5 (97 vs 123, 9 vs 10). PCA 7 vs 8 institutions -- identified and explained, see below. |
| PERC Table IV (item distribution) | **Exact** | Matches to the item, all 3 instruments, all 5 skills. |
| PERC Table V (RMSEA/SRMSR) | Very close | All values within 0.001-0.004 of published, for all 3 instruments -- essentially reproduces despite the N mismatch. |
| PERC Table VI (classification accuracy) | CCA exact, CCI near-exact, PCA off | CCA: all 5 skills match exactly (0.90/0.90/0.88/0.78/0.87). CCI: 4 of 5 exact, only Integration differs (0.97 vs 0.98). PCA is the outlier: Limits is off by 0.19 (0.87 vs. published 0.68) -- the single biggest gap in the whole comparison. |
| RUME Table 1 | Same as PERC's | Directly reuses PERC's PCA/CCI Table IV/VI results -- no separate computation. |
| RUME Table 2 (HLM) | Close, one metric off | Coefficients and effect direction match well for both PCA and CCI; `df` runs higher than published in both (more matched pairs in our data than the paper used). |
| RUME matched-pairs effect sizes | **Essentially exact** | PCA d=0.09 vs. published 0.09 (exact). CCI d=0.27 vs. published 0.26. N is off (PCA +172, CCI -30) but the substantive finding reproduces almost perfectly. |
| RUME Sankey -- CCI | Right direction, smaller effect | "00000" (no-proficiency) group shrinks in both, similar magnitude. |
| RUME Sankey -- PCA | **Wrong direction** | The "0000" group *grows* in our reproduction; the paper reports it shrinking 51%. This is a substantive disagreement, not just a sample-size issue -- see the measurement-invariance item below. |

### The PCA fix that gets Table I almost exact: deduplicate repeat students

PERC2025's methods state: *"In cases where students completed the same
assessment multiple times, we only used their first response to the most
recent post test."* That rule isn't currently applied anywhere in the
pipeline. `pca_8_23_df.csv` has 255 students with repeat entries (different
courses/terms) in the eligible population. Applying the paper's own rule
(keep each student's most-recent record, preferring one with a post-score)
plus excluding the handful of Learning Assistant/Faculty rows LASSO
includes in the raw file:

| | n | mean | median | sd |
|---|---|---|---|---|
| Current (year-filtered only) | 1476 | 45.1 | 44.0 | 17.8 |
| + deduplicated to one record/student | 1279 | 44.6 | 44.0 | 17.6 |
| Published | 1260 | 44.3 | 42.3 | 17.7 |

That closes the N gap from 216 down to 19, with mean/SD landing almost
exactly on the published values. Not yet implemented in
`PERC_RUME_Reproduction.Rmd` -- this was confirmed as a promising fix but
still needs to be coded in.

**This doesn't generalize to CCA/CCI.** Both have repeat-student records
too, but their post-only N is already at or below published, so
deduplicating would only pull them further away. Their institution-count
gap looks like genuinely missing coverage rather than duplicate inflation,
and it can't be diagnosed the same way PCA's was (see below) -- `v12`'s
institution IDs for CCA/CCI don't map to the raw LASSO export's IDs in any
way currently available in this repo.

**PCA's missing 8th institution, found:** `institution_id` 318 is present
in the raw `pca_8_23_df.csv` (8 institutions total, matching PERC exactly)
but absent from the processed `pca_data.csv` -- it has exactly 6 student
records, all in one course (Spring 2017), dropped by `datascript2.R`'s
"≥10 students per course" rule (a rule neither paper's methods section
actually mentions). This explains the institution *count* gap, but not the
N gap: all 6 of those students have a pretest score but zero have a
posttest score, so they wouldn't count toward PERC's post-only n=1260
regardless of the course-size rule.

## The Q-matrix

**Start with `Qmatrix_documentation.Rmd`** if you need to understand or
modify the Q-matrix (which items map to which skills). It is the single
source of truth: full history of how the Q-matrix evolved, the underlying
27-learning-outcome taxonomy, verification against the published PERC2025
numbers, and -- critically -- it **regenerates `Qmatrix.xlsx` from source**
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

**Not in this repo:** `Articles/` (project manuscripts plus copyrighted
third-party papers -- kept local-only since this repo is public),
`Qmatrices/`, `Roberge_agendas/`, `Postman/`. `LASSO_downloads/` is
git-ignored (raw data, regenerated by `download_lasso_data.Rmd`).

## Known open issues

See the header comments in `IJRUME_analysis.R` and `datascript2.R`, and the
"Open questions" section at the end of `Qmatrix_documentation.Rmd`, for the
full list with evidence. Highlights:

* The CCA item-12 eligibility rule (`datascript2.R`/`.Rmd`) never matched
  any real data in the LASSO export, silently NA-ing every CCA score --
  fixed 2026-07-23 (removed; CCA now uses the same 80%-attempted rule as
  CCI). What item 12 itself actually measures is still an open question,
  just no longer gates scoring.
* Reproducing the RUME2025 paper's Sankey/skill-profile figures requires a
  matched-pairs population that the legacy `.R` script doesn't use, and even
  then PCA's profile transitions don't fully reproduce -- likely a
  measurement-invariance question in how the CDM section fits pre/post
  models independently.
* PCA's data provenance (which LASSO export, or whether it came from
  elsewhere) isn't confirmed.
* The Q-matrix's item content (actual question wording) isn't documented
  anywhere in this repo, and can't be pulled via LASSO's API (it only
  returns item numbers/response data, never text). Confirming or extending
  the Q-matrix coding requires reviewing the test items directly in LASSO
  or obtaining a full copy of the assessments if one exists -- not yet
  done. Test items are confidential and are intentionally not reproduced
  in this repo.
* The v12 CSVs are not frozen snapshots of what the two papers analyzed --
  their newest rows (~51 CCA rows and ~283 CCI rows, dated Fall 2024/
  Spring 2025) postdate both papers' stated data-collection windows and
  match student IDs found in a September 2025 LASSO export, meaning v12
  was likely appended to after submission. See `PERC_RUME_Reproduction.Rmd`
  for the detailed comparison, exact year-filter bounds, and an attempt to
  recover the papers' original results by filtering them back out.

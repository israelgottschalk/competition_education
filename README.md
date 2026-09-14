# Does Competition Undermine Higher Education Quality? Evidence from Brazil

Replication package for the paper testing whether market competition among
private higher-education providers reduces student achievement and
programme quality, using a Herfindahl-Hirschman Index (HHI) instrumented
by its value eight years earlier, across Brazilian subject-city markets.

**Status:** paper in preparation / under review. This README will be
updated with the target journal, submission status, and a citation once
available.

**Author:** Israel Gottschalk, Centre for Competition Policy, University
of East Anglia.

---

## What's in this repository

| File | Description |
|---|---|
| `fees_scores_benefit.do` | Stata script that builds the market-level (subject-city) analysis dataset from the raw INEP census files, constructs the HHI and its 2009 instrument, and runs every regression reported in the paper (fees and enrollment, achievement, ability composition, programme-quality differentiation, and the social cost-benefit calculation). |
| `conglomerates_crosswalk.csv` | Mapping of higher-education providers' maintaining entities to their ultimate controlling ownership group. Used to define the unit of competition when constructing the HHI: commonly-owned providers are treated as one competitor, not several. Compiled by the author from public sources during Ministry of Education consulting work; not confidential. |
| `conglomerates_crosswalk_README.txt` | Data dictionary for the crosswalk above: column definitions, provenance, and grain. |
| `LICENSE` | Terms under which this code and data may be reused. |

## What's *not* in this repository, and why

The underlying student- and provider-level microdata are collected and
distributed by Brazil's National Institute for Educational Research and
Educational Studies (INEP). They are not redistributed here, both because
of INEP's own terms of use and, for the ENEM/ENADE/IDD files specifically,
because they remain individually identifiable at the student level even
after the cleaning and merging this script performs.

All raw files this script expects to find in the working directory are
listed in the header comment of `fees_scores_benefit.do`, together with
notes on any year-specific quirks in the raw data (e.g. 2016's IDD file
using comma decimal separators where 2015 and 2017 use periods). In
summary, you will need, from INEP's data portal (gov.br/inep):

- Higher Education Census course and provider files (`DM_CURSO_*`, `HEP_*`, `DM_DOCENTE_*`)
- ENEM microdata (`MICRODADOS_ENEM_2017.CSV`)
- IDD microdata for 2015-2017 (`microdados_idd_2015.csv`, `microdados_idd_2016.csv`, `MICRODADOS_IDD_2017.txt`)
- FIES financing records (`FINANCIAMENTO_CONCEDIDOS_SEMESTRE_1/2_<year>.csv`)
- Published Preliminary Course Concept (CPC) results spreadsheets (`CPC_2012.xls` through `CPC_2017.xlsx`)

## How to reproduce

1. Download the raw INEP files listed above and in the script header into
   the same working directory as `fees_scores_benefit.do` and
   `conglomerates_crosswalk.csv`.
2. Open Stata and set your working directory to that folder.
3. Run `fees_scores_benefit.do`. The script checks for and attempts to
   install any missing required packages (`reghdfe`, `ivreghdfe`,
   `estout`) at the start; see the script header for a note on `estfe`,
   which may need to be installed separately.
4. The script writes its output as a set of LaTeX table fragments
   (`fees_enrollments.tex`, `quality_differentiation_rc.tex`,
   `fee_differentiation.tex`, `benefit.tex`, and related files) to the
   working directory, corresponding to the tables reported in the paper.

**Requirements:** Stata (version used by the author: *[CONFIRM AND ADD
VERSION]*); user-written packages `reghdfe`, `ivreghdfe`, `estout`
(includes `esttab`/`eststo`), and `estfe`.

## Data availability statement (as it appears in the paper)

> The underlying Higher Education Census, ENADE, and ENEM microdata are
> collected and distributed by Brazil's National Institute for
> Educational Research and Educational Studies (INEP) and are made
> publicly available for registered researchers through INEP's data
> portal. Code to construct the market-level analysis dataset from the
> raw INEP censuses and to reproduce all reported results is available at
> [REPOSITORY LINK].

## License

See `LICENSE`. Code and the author-constructed crosswalk data in this
repository are released under the MIT License. This does not extend to
any raw INEP data you obtain separately to run the code, which remains
subject to INEP's own terms of use.

## Contact

Israel Gottschalk, Centre for Competition Policy, University of East
Anglia. [EMAIL ADDRESS]

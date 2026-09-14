CONGLOMERATES CROSSWALK — DATA DICTIONARY
================================================================================

FILES:
  conglomerates_crosswalk.csv
  conglomerates_crosswalk.dta

PURPOSE
  Maps higher-education providers and their maintaining entities to their
  ultimate controlling ownership group. Used to define the unit of
  competition ("firm") when constructing the Herfindahl-Hirschman Index
  (HHI) in fees_scores_benefit.do: two providers under common ownership
  are treated as one competitor, not two, in each local market.

PROVENANCE
  Compiled by the author through desk research conducted while consulting
  for the Brazilian Ministry of Education, cross-referencing providers'
  maintaining entities (mantenedoras) against their ultimate corporate
  ownership group. This information is drawn from public sources (e.g.
  CNPJ corporate registries and merger records) and is not itself
  confidential; this file is a cleaned, minimal extract retaining only
  what the analysis code requires -- it omits address, contact, legal-
  representative, and regulatory-filing detail present in the author's
  original working spreadsheet, none of which is used in the analysis.

GRAIN
  One row per maintaining entity (co_mantenedora). 198 rows, covering
  198 maintaining entities grouped into 26 ownership conglomerates.

COLUMNS
  co_ies                An example provider (institution) code associated
                         with this maintaining entity, for reference only.
                         A single maintaining entity may control more than
                         one provider; this column is illustrative and is
                         not used in any merge.
  co_mantenedora         Maintaining-entity code (INEP's "mantenedora"
                         identifier). This is the merge key used in
                         fees_scores_benefit.do (`merge m:1 co_mantenedora
                         using "Conglomerates.dta"`).
  co_conglomerate         Ownership group code. The variable actually used
                         throughout the analysis to define each market's
                         set of competing firms.
  nome_conglomerate       Ownership group name (e.g. "ESTACIO
                         PARTICIPACOES S.A."), for human readability.
  sigla_conglomerate      Short label/abbreviation for the ownership group.
  nome_mantenedora        Maintaining entity's registered name, for human
                         readability.

USAGE NOTE
  To use this file in place of the original Conglomerates.dta referenced
  in fees_scores_benefit.do, either rename conglomerates_crosswalk.dta to
  Conglomerates.dta, or update the `using` path in the script accordingly.
  The merge key (co_mantenedora) and the variable the script pulls in
  (co_conglomerate) are unchanged from the original file.

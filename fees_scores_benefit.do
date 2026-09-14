/*
================================================================================
FEES, ACHIEVEMENT, AND BENEFIT-COST ANALYSIS
Constructs the market-level (subject-city) dataset used in "Does Competition
Undermine Higher Education Quality? Evidence from Brazil" and runs all
reported regressions on fees, enrollment, achievement, ability composition,
programme-quality differentiation, and the social cost-benefit calculation.

INPUTS REQUIRED (place in the working directory before running):
  Raw INEP microdata (obtain via INEP's data portal, gov.br/inep):
    - DM_CURSO_2009.CSV, DM_CURSO_2012.CSV, DM_CURSO_2013.CSV, DM_CURSO_2014.CSV,
      DM_CURSO_2015.CSV, DM_CURSO_2016.CSV, DM_CURSO_2017.CSV
      (Course_dic_2012-2017.dta, the course dictionary/crosswalk, is built
      from these files further below -- it is not a separate input.)
    - HEP_2009.CSV, HEP_2015.CSV, HEP_2016.CSV, HEP_2017.CSV
    - DM_DOCENTE_2015.CSV, DM_DOCENTE_2016.CSV, DM_DOCENTE_2017.CSV
      (academic staff/qualification data, used to build the instrument
      for programme quality)
    - MICRODADOS_ENEM_2017.CSV
    - MICRODADOS_IDD_2017.txt
    - microdados_idd_2015.csv, microdados_idd_2016.csv (built into IDD_2015.dta
      and IDD_2016.dta just below; note 2016 uses comma decimal separators in
      its raw release, corrected here via destring, dpcomma)
    - FINANCIAMENTO_CONCEDIDOS_SEMESTRE_1_<year>.csv and _SEMESTRE_2_<year>.csv
      for year in 2012, 2014, 2015, 2016, 2017
    - CPC_2012.xls, CPC_2013.xls, CPC_2014.xlsx, CPC_2015.xls, CPC_2016.xls,
      CPC_2017.xlsx (INEP's published Preliminary Course Concept results
      spreadsheets -- a separate, published product from the microdata
      census files above; sheet names differ by year, see the import
      commands below)
  Author-constructed data:
    - conglomerates_crosswalk.csv: mapping of maintaining entities to their
      ultimate controlling ownership group, from the author's own desk
      research (public sources; not confidential). Loaded and converted to
      Conglomerates.dta by the block immediately below, before it is used in
      the HEP/conglomerate merges further down.

OUTPUTS PRODUCED (LaTeX table fragments, written to the working directory):
  fees_enrollments.tex, quality_differentiation_rc.tex, quality_differentiation_fs.tex,
  fee_differentiation.tex, fee_differentiation_fs.tex, benefit.tex, benefit_fs.tex,
  and HHI.eps (the HHI distribution histogram).

REQUIRED USER-WRITTEN PACKAGES: reghdfe, ivreghdfe, estout (esttab/eststo/estfe).
The block immediately below checks for these and installs any that are
missing; it does not affect any estimation results.
================================================================================
*/

foreach pkg in reghdfe ivreghdfe estout {
    capture which `pkg'
    if _rc {
        display "Installing missing package: `pkg'"
        capture ssc install `pkg', replace
        if _rc display "WARNING: automatic install of `pkg' failed -- install manually before proceeding."
    }
}
* Note: `estfe' (used below to format fixed-effect indicators in esttab output)
* is not always distributed under the same source as `estout'; if it is not
* already installed, search for it manually (e.g. `ssc install estfe' or
* `findit estfe') before running the sections of this script that use it.

*** build Conglomerates.dta from the public, documented crosswalk file.
*** conglomerates_crosswalk.csv contains co_mantenedora (the merge key used
*** below), co_conglomerate (the ownership-group code the analysis uses to
*** define competing firms), and human-readable name columns; see
*** conglomerates_crosswalk_README.txt for full documentation.
import delimited "conglomerates_crosswalk.csv", varnames(1) case(preserve) clear
capture confirm variable co_mantenedora
if _rc {
    display as error "conglomerates_crosswalk.csv did not load as expected -- check the file is in the working directory and its header row is intact."
    exit 601
}
save "Conglomerates.dta", replace




/*



1) Run quality on HHI
Left and right tails of the distribution

Run final scores without controlling for the initial scores
Qf= f(HHI, X) including size of the market
BetaHHI?

Run on the initial score to tell the story of selection
Run on the tails
Qi=g(HHI, X) inclusing size of the market

show that there is no effect on the final scores when controlling for the initial ones




2) Run price on HHI 
Price is the mechanism of selection

*/


***This dataset was constructed only for non-online courses, since we do not have financial information for e-learning
***Fees are also only available for private providers, given that public providers are free


*****************************************************************************************************************************************************************************************

***This dataset was constructed only for non-online courses, since we do not have financial information for e-learning
***Fees are also only available for private providers, given that public providers are free

import delimited "MICRODADOS_ENEM_2017.CSV", delimiter(";") clear
egen final_score=rowtotal( nu_nota_redacao nu_nota_cn nu_nota_ch nu_nota_lc nu_nota_mt)
keep co_municipio_prova final_score
bysort  co_municipio_prova: egen mean_ENEM_total=mean( final_score)
bysort  co_municipio_prova: egen sd_ENEM_total=sd( final_score)
bysort co_municipio_prova :  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop  final_score dup
rename co_municipio_prova co_municipio_curso
save "ENEM_total_2017.dta", replace







*** prepare the data on final and initial scores of students: 2015 and 2016 vintages
*** Built here from the raw INEP releases. Unlike 2015 and 2017, the 2016 raw file
*** uses a comma as the decimal separator (e.g. "45,1"), so the score variables are
*** destrung with the dpcomma option immediately after import. Column names in the
*** 2015 and 2016 raw files already match what the rest of this script expects
*** (co_munic, enem_nt_cn/ch/lc/mt), unlike 2017, so no renaming is needed here.

import delimited "microdados_idd_2015.csv", delimiter(";") clear
save "IDD_2015.dta", replace

import delimited "microdados_idd_2016.csv", delimiter(";") clear
destring nt_ger enem_nt_cn enem_nt_ch enem_nt_lc enem_nt_mt, dpcomma replace
save "IDD_2016.dta", replace


*** prepare the data on final and initial scores of students
insheet using "MICRODADOS_IDD_2017.txt", delimiter(";") clear

rename vl_nota_enem_cn enem_nt_cn
rename vl_nota_enem_ch enem_nt_ch
rename vl_nota_enem_lc enem_nt_lc
rename vl_nota_enem_mt enem_nt_mt
rename co_munic_curso co_munic


append using "IDD_2015.dta" "IDD_2016.dta"


***generates a unique student ID
gen id_student = _n

**The ENEM exam, taken at the end of the high school, put on the same scale as ENADE, the final exam
egen ENEM1 = rowmean( enem_nt_cn enem_nt_ch enem_nt_lc enem_nt_mt )
gen ENEM=ENEM1/10
drop ENEM1
drop if ENEM==.


***ENADE - exam students sit on their senior year, added by 100 to make sure all deltas are positive, just to look nice, so we can keep the common belief that students improve in higher ed, even though this result could not tell us this,since they are two different exams in two different points in time.
gen ENADE = (nt_ger)



drop if co_modalidade==0

gen d_public=0
replace d_public=1 if co_categad==93
replace d_public=1 if co_categad==115
replace d_public=1 if co_categad==116
replace d_public=1 if co_categad==10001
replace d_public=1 if co_categad==10002
replace d_public=1 if co_categad==10003
replace d_public=1 if co_categad==1
replace d_public=1 if co_categad==2
replace d_public=1 if co_categad==3
drop if d_public==1


keep nu_ano co_grupo co_ies co_munic co_curso co_modalidade id_student ano_enem ENEM ENADE
save "IDD_2015-2017.dta", replace



*****************************************************************************************************************************************************************************************
*****************************************************************************************************************************************************************************************
*** prepare the data on fees

local filelist 2012 2014 2015 2016 2017
foreach year of local filelist  { 

insheet using "FINANCIAMENTO_CONCEDIDOS_SEMESTRE_2_`year'.csv", delimiter(";") clear
bysort co_contrato_fies_ext_alunos:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
drop if nu_ano<`year'
drop if co_curso==.
destring vl_mensalidade  vl_perc_financiamento  vl_mensalidade_ext_alunos  vl_semestre nu_percentual_prouni nu_percent_solicitado_financ , dpcomma replace
save "FEE_`year'_2.dta", replace


insheet using "FINANCIAMENTO_CONCEDIDOS_SEMESTRE_1_`year'.csv", delimiter(";") clear
bysort co_contrato_fies_ext_alunos:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
destring vl_mensalidade  vl_perc_financiamento  vl_mensalidade_ext_alunos  vl_semestre nu_percentual_prouni nu_percent_solicitado_financ , dpcomma replace
drop if nu_ano<`year'
drop if co_curso==.
save "FEE_`year'_1.dta", replace
append using "FEE_`year'_2.dta"

**even though a student can appear more than once in this dataset i.e. in the first and in the second semester of 2017, I use them as separate data points
**if courses are in two cities with the same id I cannot distinguish their fees

bysort co_curso: egen fee_median=median(vl_mensalidade)
bysort co_curso: egen fee_mean=mean(vl_mensalidade)

bysort co_curso:  gen dup = cond(_N==1,0,_n)
drop if dup>1
keep co_curso fee_median fee_mean co_municipio_ies nu_ano
save "FEES_`year'.dta", replace
clear
}
*

use "FEES_2012.dta", clear
gen log_fee_median_2012=log(fee_median)
save "FEES_2012.dta", replace


use "FEES_2014.dta", clear
gen log_fee_median_2014=log(fee_median)
save "FEES_2014.dta", replace

use "FEES_2015.dta", clear
append using "FEES_2016.dta"
append using "FEES_2017.dta"
save "FEES_2015_2016_2017.dta", replace




*****************************************************************************************************************************************************************************************
*****************************************************************************************************************************************************************************************


*****************************************************************************************************************************************************************************************
*****************************************************************************************************************************************************************************************
****  prepare the data from the CPC course quality database
**data for all courses is spread over the three years of the assessment cycle, so we need to merge these files together to obtain quality data for all courses

*there is a problem with the 2014 CPC dataset that bring info on number of lecturers and qualification per course: that dataset does not contain the unique id co_curso, so I have to go around it and 
*I miss 1600 observations because of that 
*this to be used to merge the course codes into the file

import excel "CPC_2012.xls", sheet("CPC_2012") firstrow clear
keep Códigodaárea CódigodaIES Códigodomunicípiodocurso CPCcontínuo NotabrutadoIDD  Notabrutadeformaçãogeral Notabrutadecomponenteespecíf demestres doutores deregimedetrabalhointegra deinfraestrutura organizaçãodidáticopedagógic
rename demestres score_astaffmsc_course
rename doutores score_astaffphd_course
rename deregimedetrabalhointegra score_astaffcontract_course
rename deinfraestrutura score_infra_course
rename organizaçãodidáticopedagógic score_didped_course
rename	CódigodaIES	co_ies
rename Códigodaárea co_area
rename	Códigodomunicípiodocurso  co_municipio_curso
rename CPCcontínuo CPC_cont
rename Notabrutadecomponenteespecíf ENADE_CE
rename  Notabrutadeformaçãogeral ENADE_FG
rename NotabrutadoIDD IDD
destring , force replace
gen nu_ano=2012
save "CPC_2012.dta", replace


import excel "CPC_2013.xls", sheet("cpc_2013") firstrow clear
keep  CódÁrea CódIES CódMunicípio CPCContínuo NotaContínuadoEnade  NotaBrutadoIDD  NotaBrutaFG NotaBrutaCE deMestres deDoutores regimedetrabalhomínimoparc  NotaBrutaInfraestrut NotaBrutaOrgDidáticoPedag
rename deMestres score_astaffmsc_course
rename deDoutores score_astaffphd_course
rename regimedetrabalhomínimoparc score_astaffcontract_course
rename NotaBrutaInfraestrut score_infra_course
rename NotaBrutaOrgDidáticoPedag score_didped_course
rename	CódIES	co_ies
rename CódÁrea co_area
rename	CódMunicípio  co_municipio_curso
rename CPCContínuo CPC_cont
rename NotaBrutaFG ENADE_FG 
rename NotaBrutaCE ENADE_CE
rename NotaBrutadoIDD IDD
destring , force replace
gen nu_ano=2013
save "CPC_2013.dta", replace

import excel "CPC_2014.xlsx", sheet("cpc_site") firstrow clear
keep CódigodaÁrea CódigodaIES CódigodoMunicípio CPCContínuo  NotaBrutaIDD  NotaBrutaFG NotaBrutaCE  NotaBrutaMestres  NotaBrutaDoutores  NotaBrutaRegimedeTrabalho   NotaBrutaInfraestruturaeIn NotaBrutaOrganizaçãoDidátic
rename NotaBrutaMestres score_astaffmsc_course
rename NotaBrutaDoutores score_astaffphd_course
rename NotaBrutaRegimedeTrabalho score_astaffcontract_course
rename NotaBrutaInfraestruturaeIn score_infra_course
rename NotaBrutaOrganizaçãoDidátic score_didped_course
rename	CódigodaIES	co_ies
rename CódigodaÁrea co_area
rename	CódigodoMunicípio  co_municipio_curso
rename CPCContínuo CPC_cont
rename NotaBrutaFG ENADE_FG 
rename NotaBrutaCE ENADE_CE
rename NotaBrutaIDD IDD
destring , force replace
gen nu_ano=2014
save "CPC_2014.dta", replace

import excel "CPC_2015.xls", sheet("CPC_2015") firstrow clear
keep CódigodaIES CódigodoCurso CódigodoMunicípio NotaBrutaOrganizaçãoDidátic NotaBrutaInfraestruturaeIn NotaBrutaOportunidadesdeAm NrdeDocentes NotaBrutaMestres NotaBrutaDoutores NotaBrutaRegimedeTrabalho CPCContínuo  CódigodaÁrea NotaBrutaIDD NotaBrutaFG NotaBrutaCE
rename CódigodaÁrea co_area
rename	CódigodaIES	co_ies
rename	CódigodoMunicípio	co_municipio_curso
rename	NotaBrutaOrganizaçãoDidátic	score_didped_course
rename	NotaBrutaInfraestruturaeIn	score_infra_course
rename	NotaBrutaOportunidadesdeAm	score_extra_course
rename	NrdeDocentes	n_astaff_course
rename	NotaBrutaMestres	score_astaffmsc_course
rename	NotaBrutaDoutores	score_astaffphd_course
rename	NotaBrutaRegimedeTrabalho	score_astaffcontract_course
rename 	 CódigodoCurso	co_curso
rename NotaBrutaFG ENADE_FG 
rename NotaBrutaCE ENADE_CE
rename NotaBrutaIDD IDD
destring CPCContínuo, force replace
rename CPCContínuo CPC_cont
gen nu_ano=2015
save "CPC_2015.dta", replace

import excel "CPC_2016.xls", sheet("CPC_2016") firstrow clear
keep  CódigodaIES CódigodoCurso CódigodoMunicípio NotaBrutaOrganizaçãoDidátic NotaBrutaInfraestruturaeIn NotaBrutaOportunidadesdeAm NrdeDocentes NotaBrutaMestres NotaBrutaDoutores NotaBrutaRegimedeTrabalho CPCContínuo	 CódigodaÁrea NotaBrutaFG NotaBrutaCE NotaBrutaIDD 	
rename CódigodaÁrea co_area
rename	CódigodaIES	co_ies
rename	CódigodoMunicípio	co_municipio_curso
rename	NotaBrutaOrganizaçãoDidátic	score_didped_course
rename	NotaBrutaInfraestruturaeIn	score_infra_course
rename	NotaBrutaOportunidadesdeAm	score_extra_course
rename	NrdeDocentes	n_astaff_course
rename	NotaBrutaMestres	score_astaffmsc_course
rename	NotaBrutaDoutores	score_astaffphd_course
rename	NotaBrutaRegimedeTrabalho	score_astaffcontract_course
rename 	 CódigodoCurso	co_curso
rename CPCContínuo CPC_cont
rename NotaBrutaFG ENADE_FG 
rename NotaBrutaCE ENADE_CE
rename NotaBrutaIDD IDD
gen nu_ano=2016
save "CPC_2016.dta", replace
clear


import excel "CPC_2017.xlsx", sheet("PORTAL_CPC_2017") firstrow clear
keep  CódigodaIES CódigodoCurso CódigodoMunicípio NotaBrutaOrganizaçãoDidátic NotaBrutaInfraestruturaeIn NotaBrutaOportunidadesdeAm NºdeDocentes NotaBrutaMestres NotaBrutaDoutores NotaBrutaRegimedeTrabalho CPCContínu CódigodaÁrea NotaBrutaFG NotaBrutaCE NotaBrutaIDD 	
rename  CódigodaÁrea co_area
rename	CódigodaIES	co_ies
rename	CódigodoMunicípio	co_municipio_curso
rename	NotaBrutaOrganizaçãoDidátic	score_didped_course
rename	NotaBrutaInfraestruturaeIn	score_infra_course
rename	NotaBrutaOportunidadesdeAm	score_extra_course
rename	NºdeDocentes	n_astaff_course
rename	NotaBrutaMestres	score_astaffmsc_course
rename	NotaBrutaDoutores	score_astaffphd_course
rename	NotaBrutaRegimedeTrabalho	score_astaffcontract_course
rename 	 CódigodoCurso	co_curso
rename CPCContínuo CPC_cont
rename NotaBrutaFG ENADE_FG 
rename NotaBrutaCE ENADE_CE
rename NotaBrutaIDD IDD
gen nu_ano=2017
save "CPC_2017.dta", replace
clear




**collate the files

use "CPC_2017.dta", clear
append using "CPC_2015.dta"
append using "CPC_2016.dta"
save "CPC_2015_2016_2017.dta", replace
clear


use "CPC_2017.dta", clear
append using "CPC_2016.dta"
append using "CPC_2015.dta"
append using "CPC_2014.dta"
append using "CPC_2013.dta"
append using "CPC_2012.dta"
keep  co_ies co_area co_municipio_curso CPC_cont co_curso ENADE_FG ENADE_CE  IDD nu_ano score_didped_course score_infra_course score_extra_course n_astaff_course score_astaffmsc_course score_astaffphd_course score_astaffcontract_course


bysort co_ies co_area co_municipio_curso: egen x=mode(co_curso), min
replace co_curso=x if co_curso==.
drop x
save "CPC_2012-2017.dta", replace
clear


*****************************************************************************************************************************************************************************************
*****************************************************************************************************************************************************************************************
**** prepare the data from academic staff at the provider level

local filelist 2015 2016
foreach year of local filelist  { 


insheet using "DM_DOCENTE_`year'.CSV", delimiter("|") clear
gen nu_ano=`year'
keep  nu_idade_docente co_regime_trabalho co_escolaridade_docente co_ies nu_ano in_atu_pesquisa in_bolsa_pesquisa

gen y = 1
bysort co_ies: egen n_staff_ies= total(y)

***staff level of education
bysort co_ies: egen staff_rank_hep= mean(co_escolaridade_docente)
bysort co_ies: egen staff_age_hep= mean(nu_idade_docente)
bysort co_ies: egen staff_contract_hep = mean(co_regime_trabalho)

bysort co_ies: egen n_staff_rsch_actv= total(in_atu_pesquisa)
bysort co_ies: gen p_staff_rsch_actv=n_staff_rsch_actv/n_staff_ies
bysort co_ies: egen n_staff_rsch_schl= total(in_bolsa_pesquisa)
bysort co_ies: gen p_staff_rsch_schl=n_staff_rsch_schl/n_staff_ies

bysort  co_ies:  gen dup_hep = cond(_N==1,0,_n)
drop if dup>1
keep co_ies n_staff_ies staff_rank_hep staff_age_hep staff_contract_hep nu_ano p_staff_rsch_schl p_staff_rsch_actv






save "Staff_HEP_`year'.dta", replace

}
*

***2017 has discrepancies in variable names and has to be treated separately

insheet using "DM_DOCENTE_2017.CSV", delimiter("|") clear
gen nu_ano=2017
keep  nu_idade tp_regime_trabalho tp_escolaridade co_ies nu_ano in_atuacao_pesquisa in_bolsa_pesquisa
gen y = 1
bysort co_ies: egen n_staff_ies= total(y)
***staff level of education
bysort co_ies: egen staff_rank_hep= mean(tp_escolaridade)
bysort co_ies: egen staff_age_hep= mean(nu_idade)
bysort co_ies: egen staff_contract_hep = mean(tp_regime_trabalho)

bysort co_ies: egen n_staff_rsch_actv= total(in_atuacao_pesquisa)
bysort co_ies: gen p_staff_rsch_actv=n_staff_rsch_actv/n_staff_ies
bysort co_ies: egen n_staff_rsch_schl= total(in_bolsa_pesquisa)
bysort co_ies: gen p_staff_rsch_schl=n_staff_rsch_schl/n_staff_ies

bysort  co_ies:  gen dup_hep = cond(_N==1,0,_n)
drop if dup>1
keep co_ies n_staff_ies staff_rank_hep staff_age_hep staff_contract_hep nu_ano p_staff_rsch_schl p_staff_rsch_actv





save "Staff_HEP_2017.dta", replace


***collate
use "Staff_HEP_2017.dta", clear
append using "Staff_HEP_2015.dta"
append using "Staff_HEP_2016.dta"
save "Staff_HEP_2015_2016_2017.dta", replace




*****************************************************************************************************************************************************************************************
*****************************************************************************************************************************************************************************************
**** prepare the data from HEP and conglomerates 


local filelist  2009 2015 2016
foreach year of local filelist  { 

**The provider data from the HE Census 2016 is used as the spine of this dataset
insheet using "HEP_`year'.CSV", delimiter("|") clear

**generate a dummy to indicate a public institution
gen d_public_hep=0
replace d_public_hep=1 if co_categoria_administrativa==1
replace d_public_hep=1 if co_categoria_administrativa==2
replace d_public_hep=1 if co_categoria_administrativa==3

tab d_public_hep

***generate the number of heps by municipality
gen y = 1
bysort co_municipio_ies: egen n_hep_mun= total(y)
drop y
bysort co_municipio_ies : egen n_hep_mun_pub= total(d_public_hep)
bysort co_municipio_ies : gen n_hep_mun_priv= n_hep_mun-n_hep_mun_pub

sum n_hep_mun n_hep_mun_pub n_hep_mun_priv

keep d_public_hep n_hep_mun n_hep_mun_pub  n_hep_mun_priv  co_ies co_mantenedora co_municipio_ies 

***merging in the information on conglomerates, based on a mapping I have conducted while consulting for the Brazilian Ministry of Education
merge m:1 co_mantenedora using "Conglomerates.dta"

***the map of conglomerates, though, contains providers that have already been phased out previous to the 2016 census, which is the spine of the datased we are constructing
***so now we drop those from our dataset
drop if _merge==2
drop _merge
replace co_conglomerate=co_mantenedora if co_conglomerate==.
gen nu_ano=`year'

save "HEP_CONG_`year'.dta",replace
}
*

**The year 2017 has some discrepancies in variable names and had to be done separately
insheet using "HEP_2017.CSV", delimiter("|") clear

**generate a dummy to indicate a public institution
gen d_public_hep=0
replace d_public_hep=1 if tp_categoria_administrativa==1
replace d_public_hep=1 if tp_categoria_administrativa==2
replace d_public_hep=1 if tp_categoria_administrativa==3

tab d_public_hep

***generate the number of heps by municipality

gen y = 1
rename co_municipio co_municipio_ies
bysort co_municipio_ies: egen n_hep_mun= total(y)
drop y
bysort co_municipio_ies : egen n_hep_mun_pub= total(d_public_hep)
bysort co_municipio_ies: gen n_hep_mun_priv= n_hep_mun-n_hep_mun_pub

sum n_hep_mun n_hep_mun_pub n_hep_mun_priv

keep d_public_hep n_hep_mun n_hep_mun_pub  n_hep_mun_priv  co_ies co_mantenedora co_municipio_ies 

***merging in the information on conglomerates, based on a mapping I have conducted while consulting for the Brazilian Ministry of Education
merge m:1 co_mantenedora using "Conglomerates.dta"

***the map of conglomerates, though, contains providers that have already been phased out previous to the 2016 census, which is the spine of the datased we are constructing
***so now we drop those from our dataset
drop if _merge==2
drop _merge
replace co_conglomerate=co_mantenedora if co_conglomerate==.
gen nu_ano=2017

save "HEP_CONG_2017.dta",replace


***collate
use "HEP_CONG_2017.dta", clear
append using "HEP_CONG_2015.dta"
append using "HEP_CONG_2016.dta"
save "HEP_CONG_2015_2016_2017.dta", replace


***Preparing the data on courses from the census
*this is just the cpc dictionary that i need to put togethet because the cpc files 2012-2013-2014 do not have the co_curso in them






import delimited "DM_CURSO_2012.CSV", delimiter("|") clear
gen nu_ano=2012
keep co_ies co_municipio_curso co_curso co_ocde co_ocde_area_detalhada nu_ano
save "Course_dic_2012.dta", replace

import delimited "DM_CURSO_2013.CSV", delimiter("|") clear
gen nu_ano=2013
keep co_ies co_municipio_curso co_curso co_ocde co_ocde_area_detalhada nu_ano
save "Course_dic_2013.dta", replace

import delimited "DM_CURSO_2014.CSV", delimiter("|") clear
gen nu_ano=2014
keep co_ies co_municipio_curso co_curso co_ocde co_ocde_area_detalhada nu_ano
save "Course_dic_2014.dta", replace

import delimited "DM_CURSO_2015.CSV", delimiter("|") clear
gen nu_ano=2015
keep co_ies co_municipio_curso co_curso co_ocde co_ocde_area_detalhada nu_ano
save "Course_dic_2015.dta", replace

import delimited "DM_CURSO_2016.CSV", delimiter("|") clear
gen nu_ano=2016
keep co_ies co_municipio_curso co_curso co_ocde co_ocde_area_detalhada nu_ano
save "Course_dic_2016.dta", replace

import delimited "DM_CURSO_2017.CSV", delimiter("|") clear
gen nu_ano=2017
rename co_municipio co_municipio_curso
keep co_ies co_municipio_curso co_curso co_ocde co_ocde_area_detalhada nu_ano
save "Course_dic_2017.dta", replace


use "Course_dic_2012.dta", clear
append using "Course_dic_2013.dta"
append using "Course_dic_2014.dta"
append using "Course_dic_2015.dta"
append using "Course_dic_2016.dta"
append using "Course_dic_2017.dta"
save "Course_dic_2012-2017.dta", replace


use "CPC_2012-2017.dta", clear
merge m:m co_curso using "Course_dic_2012-2017.dta", keepusing(co_ocde co_ocde_area_d)
drop if _merge==2
drop _merge


bysort co_area: egen x=mode(co_ocde), min
replace co_ocde=x if co_ocde==""
drop x

rename co_curso co_curso_1

merge m:m co_ies co_ocde co_municipio nu_ano using "Course_dic_2012-2017.dta", keepusing(co_curso)
drop if _merge==2
drop _merge

replace co_curso_1 = co_curso if co_curso_1==.
drop co_curso
rename co_curso_1 co_curso

drop if nu_ano>2014
rename nu_ano ano_cpc
save "CPC_2012-2017_2.dta", replace



**this is the dataset that i am using

*** prepare the data on programmes

import delimited "DM_CURSO_2009.CSV", delimiter("|") clear
gen nu_ano=2009
save "Course_Census_2009.dta", replace

import delimited "DM_CURSO_2015.CSV", delimiter("|") clear
gen nu_ano=2015
gen qt_vaga_curso = qt_vagas_novas_integral+qt_vagas_novas_matutino+qt_vagas_novas_vespertino+qt_vagas_novas_noturno
save "Course_Census_2015.dta", replace


import delimited "DM_CURSO_2016.CSV", delimiter("|") clear
gen nu_ano=2016
rename qt_vagas_totais qt_vaga_curso
save "Course_Census_2016.dta", replace

import delimited "DM_CURSO_2017.CSV", delimiter("|") clear
drop nu_ano_censo
rename tp_categoria_administrativa co_categoria_administrativa
rename tp_organizacao_academica co_organizacao_academica
rename tp_situacao co_situacao_curso
rename tp_grau_academico co_grau_academico
rename tp_modalidade_ensino co_modalidade_ensino
rename tp_nivel_academico co_nivel_academico
rename tp_atributo_ingresso co_atributo_ingressp
rename qt_matricula_total qt_matricula_curso
rename qt_concluinte_total qt_concluinte_curso
rename qt_ingresso_total qt_ingresso_curso 
rename qt_vaga_total qt_vaga_curso
rename co_municipio co_municipio_curso
rename co_uf co_uf_curso
rename co_local_oferta co_local_oferta_curso
rename nu_perc_carga_semi_pres nu_perc_car_hor_semi_pres
rename in_capital in_capital_curso
rename in_integral in_integral_curso 
rename in_matutino in_matutino_curso 
rename in_vespertino in_vespertino_curso
rename in_noturno in_noturno_curso
gen nu_ano=2017
save "Course_Census_2017.dta", replace

***collate 
use "Course_Census_2016.dta", clear
append using "Course_Census_2017.dta"
append using "Course_Census_2015.dta"

save "Course_Census_2015_2016_2017.dta", replace


*** prepare the data for the lagged hhi and other instruments from 2009
***Here we chose the level of aggregation of the dataset, if at the oecd course level, oecd detailed area level, oecd specific area level, or general area level
local filelist co_ocde_area_detalhada  /*co_ocde_area_geral co_ocde_area_especifica co_ocde_area_detalhada  co_ocde */
foreach x of local filelist  { 

use "Course_Census_2009.dta", clear
merge m:1 co_ies using "HEP_CONG_2009.dta", nogenerate
drop nu_ano

*****************************************************************************************************************************************************************************************
*****************************************************************************************************************************************************************************************

***even though in the same academic area, baccalaureates and teaching degrees (very similar apart from some disciplines) are coded differently in the OECD code
***I tried to change this and put them all in the same category, but this was boiling down to examinating course by course and I am not sure if it makes sense
***in any case, to eliminate distortions in calculating the HHI, I had to drop those courses with  missing OECD code, since they are all lumped together in the missing category
***the courses with missing OECD core are like that because there is a missing information for the degree level, so I drop the ones with the missing degree level

*bysort co_municipio_curso co_conglomerate `x' :  gen dup_cong_oecd = cond(_N==1,0,_n)


rename co_ocde co_ocde1
encode co_ocde1, gen(co_ocde)

***Dummy for mode of delivery
gen d_pres=1
replace d_pres=0 if co_modalidade_ensino==2

***dropping online courses out of the sample
drop if d_pres==0
drop d_pres

***Public, private dummy
gen d_private_c=0
replace d_private_c=1 if co_categoria_administrativa==4
replace d_private_c=1 if co_categoria_administrativa==5
replace d_private_c=1 if co_categoria_administrativa==7

tab d_private_c
drop if d_private_c==0

***ENROLMENTS
***number of enrolments in the programme
*rename qt_matricula_curso n_enrol_prog


***Number of enrolments for all HEPs per oecd programme code
*bysort co_municipio_curso `x':  egen n_enrol_mun_oecd = total(n_enrol_prog)



/*

***Number of enrolments for private HEPs per oecd programme code
bysort co_municipio_curso `x':  egen n_enrol_mun_oecd_priv = total(n_enrol_prog)
gen log_n_enrol_mun_oecd_priv=log(n_enrol_mun_oecd_priv)

*/
replace  qt_ingresso_curso =1 if qt_ingresso_curso==0
bysort co_municipio_curso `x':  egen n_intake_mun_oecd_priv = total(qt_ingresso_curso)
gen log_n_intake_mun_oecd_priv=log(n_intake_mun_oecd_priv)



*** Calculate the hhi
*** HHI per oecd detailed area for all and only for private
*** HHI per oecd area for all and only for private


/*
***HHI considering only private providers and the oecd course code
***total enrolments in a course in a city per holding
bysort co_municipio_curso co_conglomerate `x' : egen n_enrol_h_oecd_priv = total( n_enrol_prog)
gen p_enrol_h_m_oecd_priv= n_enrol_h_oecd_priv/n_enrol_mun_oecd_priv
gen p_enrol_h_m_oecd_priv_sq=(p_enrol_h_m_oecd_priv)^2  
bysort co_municipio_curso `x': egen hhi_h_oecd_priv1 = total(p_enrol_h_m_oecd_priv_sq) if dup_cong_oecd<2 
bysort co_municipio_curso `x': egen hhi_h_oecd_priv_2009 = max(hhi_h_oecd_priv1)
*/




bysort co_municipio_curso co_conglomerate co_ocde_area_detalhada :  gen dup_cong_oecd = cond(_N==1,0,_n)


***in terms of the intake
bysort co_municipio_curso co_conglomerate co_ocde_area_detalhada : egen n_intake_h_oecd_priv = total( qt_ingresso_curso)
gen p_intake_h_m_oecd_priv= n_intake_h_oecd_priv/n_intake_mun_oecd_priv
gen p_intake_h_m_oecd_priv_sq=(p_intake_h_m_oecd_priv)^2  



bysort co_municipio_curso co_ocde_area_detalhada: egen hhi_h_oecd_priv1_i = total(p_intake_h_m_oecd_priv_sq) if dup_cong_oecd<2 
bysort co_municipio_curso co_ocde_area_detalhada: egen hhi_h_oecd_priv_i_2009 = max(hhi_h_oecd_priv1_i)


drop hhi_h_oecd_priv1_i


save "Competition_2009_prog", replace

bysort  co_municipio_curso co_ocde_area_detalhada :  gen dup_mun_subject = cond(_N==1,0,_n)
drop if dup_mun_subject>1

save "Competition_2009_mkt", replace

}
*









************************************************************************************************************************************************************************
************************************************************************************************************************************************************************
************************************************************************************************************************************************************************
************************************************************************************************************************************************************************
************************************************************************************************************************************************************************
*** RUNNING 

***I NEED TO BUILD A DATASET SIMILAR TO THE ONE I BUILT ON FEES BUT I NEED TO OBTAIN INFO FOR 2014 2015 AND 2016 IN ALL CENSUS DATASETS AND ELSE TO MERGE THE STUDENTS ACHIEVEMENT INTO THE PROPER YEAR
***Here we chose the level of aggregation of the dataset, if at the oecd course level, oecd detailed area level, oecd specific area level, or general area level
local filelist co_ocde_area_detalhada  /*co_ocde_area_geral co_ocde_area_especifica co_ocde_area_detalhada  co_ocde */
foreach x of local filelist  { 




*****************************************************************************************************************************************************************************************
*****************************************************************************************************************************************************************************************
*** 6 - prepare the data on programmes
use "Course_Census_2015_2016_2017.dta", clear
merge m:1 nu_ano co_ies using "HEP_CONG_2015_2016_2017.dta", nogenerate

/*

replace dt_inicio_funcionamento = subinstr(dt_inicio_funcionamento, "/", "",.) 
gen day = real(substr(dt_inicio_funcionamento,1,2))
gen month = real(substr(dt_inicio_funcionamento,3,2))
gen year = real(substr(dt_inicio_funcionamento,5,4))


bysort co_municipio_curso co_cong co_ocde_area_detalhada :  gen dup_cong_oecd_mun = cond(_N==1,0,_n)
bysort co_municipio_curso co_ocde_area_detalhada  : egen entry_rank1 = rank(year) if dup_cong_oecd_mun<2
bysort co_municipio_curso co_ocde_area_detalhada co_cong: egen entry_rank = max(entry_rank1)
drop entry_rank1

*/

rename co_ocde co_ocde1
encode co_ocde1, gen(co_ocde)

***Dummy for mode of delivery
gen d_pres=1
replace d_pres=0 if co_modalidade_ensino==2
tab d_pres ds_modalidade_ensino

***dropping online courses out of the sample
drop if d_pres==0
drop d_pres

***drop inactive courses
drop if co_situacao_curso!=1

***dropping those courses with missing number of enrolments
drop if qt_matricula_curso==.

***Public, private dummy
gen d_private_c=0
replace d_private_c=1 if co_categoria_administrativa==4
replace d_private_c=1 if co_categoria_administrativa==5
replace d_private_c=1 if co_categoria_administrativa==7

tab d_private_c
drop if d_private_c==0



**drop if the oecd code is missing so that those courses are not lumped together in the missing category
drop if `x'==.

bysort nu_ano co_municipio_curso `x' d_private_c:  egen n_intake_mun_oecd_priv = total(qt_ingresso_curso) if d_private_c==1
bysort  nu_ano co_municipio_curso:  gen dup_mun = cond(_N==1,0,_n)
bysort nu_ano co_municipio_curso `x' co_conglomerate:  gen dup_cong_oecd = cond(_N==1,0,_n)

rename qt_matricula_curso n_enrol_prog

/*
***ENROLMENTS

***number of enrolments in the programme

gen log_n_enrol_prog=log(n_enrol_prog)


***number of enrolments in provider
bysort nu_ano co_municipio_curso co_cong: egen n_enrol_cong=total(n_enrol_prog)

***number of enrolments per municipality
bysort nu_ano co_municipio_curso :  egen n_enrol_mun = total(n_enrol_prog)
gen log_n_enrol_mun=log(n_enrol_mun)

sum n_enrol_mun if dup_mun<2



***Total number of enrolments per oecd programme code for public
bysort nu_ano co_municipio_curso `x':  egen n_enrol_mun_oecd_total = total(n_enrol_prog)
gen log_n_enrol_mun_oecd_total=log(n_enrol_mun_oecd_total)

***Total number of enrolments per oecd programme code for public
bysort nu_ano co_municipio_curso `x':  egen n_enrol_mun_oecd_pub = total(n_enrol_prog) if d_private_c==0
gen log_n_enrol_mun_oecd_pub1=log(n_enrol_mun_oecd_pub)
bysort nu_ano co_municipio_curso `x': egen log_n_enrol_mun_oecd_pub=max(log_n_enrol_mun_oecd_pub1)
replace log_n_enrol_mun_oecd_pub=0 if log_n_enrol_mun_oecd_pub==.


***Total number of enrolments in the public sector

bysort nu_ano co_municipio_curso:  egen n_enrol_mun_pub1 = total(n_enrol_prog) if d_private_c==0
bysort nu_ano co_municipio_curso: egen n_enrol_mun_pub=max(n_enrol_mun_pub1)
replace n_enrol_mun_pub=0 if n_enrol_mun_pub==.





***Number of enrolments for private HEPs per oecd programme code
bysort nu_ano co_municipio_curso `x':  egen n_enrol_mun_oecd_priv = total(n_enrol_prog) if d_private_c==1
gen log_n_enrol_mun_oecd_priv=log(n_enrol_mun_oecd_priv)




gen log_n_intake_mun_oecd_priv=log(n_intake_mun_oecd_priv)

***number of lecture hours to complete the programme
bysort nu_ano co_cong co_municipio_curso `x':  egen hour_load_oecd = mean( nu_carga_horaria)

gen log_hour_load_oecd=log(hour_load_oecd)

keep  no_curso co_ocde n_enrol_mun_pub co_categoria_administrativa co_organizacao_academica co_nivel_academico co_grau_academico entry_rank year log_n_enrol_prog in_integral_curso in_matutino_curso in_vespertino_curso in_noturno_curso in_oferece_disc_semi_pres nu_perc_car_hor_semi_pres nu_ano n_enrol_prog co_ies no_ies co_municipio_curso no_municipio_curso co_curso `x' no_ocde hour_load d_private_c nu_carga_horaria n_enrol_mun n_enrol_mun_oecd_pub n_enrol_mun_oecd_priv co_mantenedora co_municipio_ies d_public_hep n_hep_mun n_hep_mun_pub n_hep_mun_priv co_conglomerate log_hour_load_oecd log_n_enrol_mun_oecd_priv log_n_enrol_mun_oecd_pub log_n_enrol_mun n_enrol_mun_oecd_total log_n_enrol_mun_oecd_total qt_ingresso_curso n_intake_mun_oecd_priv log_n_intake_mun_oecd_priv




*/




bysort nu_ano co_municipio_curso `x' co_conglomerate : egen n_enrol_h_oecd = total( n_enrol_prog)




keep  no_curso co_ocde co_categoria_administrativa co_organizacao_academica co_nivel_academico co_grau_academico  in_integral_curso in_matutino_curso in_vespertino_curso in_noturno_curso in_oferece_disc_semi_pres nu_perc_car_hor_semi_pres nu_ano  co_ies no_ies co_municipio_curso no_municipio_curso co_curso `x' no_ocde d_private_c nu_carga_horaria co_mantenedora co_municipio_ies d_public_hep n_hep_mun n_hep_mun_pub n_hep_mun_priv co_conglomerate qt_ingresso_curso n_intake_mun_oecd_priv dup_cong_oecd dup_mun  n_enrol_h_oecd







/*


***HHI considering public and private together (total) in the market and the oecd course code

gen p_enrol_h_m_oecd_total= n_enrol_h_oecd/n_enrol_mun_oecd_total
gen p_enrol_h_m_oecd_total_sq=(p_enrol_h_m_oecd_total)^2

bysort nu_ano co_municipio_curso `x': egen hhi_h_oecd1 = total(p_enrol_h_m_oecd_total_sq) if dup_cong_oecd<2
bysort nu_ano co_municipio_curso `x': egen hhi_h_oecd = max(hhi_h_oecd1)
gen competition_h_oecd=1-hhi_h_oecd


***HHI considering only private providers and the oecd course code
***total enrolments in a course in a city per holding
bysort nu_ano co_municipio_curso `x' co_conglomerate d_private_c: egen n_enrol_h_oecd_priv = total( n_enrol_prog) if d_private_c==1
gen p_enrol_h_m_oecd_priv= n_enrol_h_oecd_priv/n_enrol_mun_oecd_priv  if d_private_c==1
gen p_enrol_h_m_oecd_priv_sq=(p_enrol_h_m_oecd_priv)^2  if d_private_c==1
bysort nu_ano co_municipio_curso `x': egen hhi_h_oecd_priv1 = total(p_enrol_h_m_oecd_priv_sq) if dup_cong_oecd<2 & d_private_c==1
bysort nu_ano co_municipio_curso `x': egen hhi_h_oecd_priv = max(hhi_h_oecd_priv1) if d_private_c==1
gen competition_h_oecd_priv=1-hhi_h_oecd_priv

drop hhi_h_oecd_priv1 hhi_h_oecd1



*/





*** Calculate the hhi
*** HHI per oecd detailed area for all and only for private
*** HHI per oecd area for all and only for private




**using intake not enrolments

bysort nu_ano co_municipio_curso `x' co_conglomerate d_private_c: egen n_intake_h_oecd_priv = total( qt_ingresso_curso) if d_private_c==1
gen p_intake_h_m_oecd_priv= n_intake_h_oecd_priv/n_intake_mun_oecd_priv  if d_private_c==1
gen p_intake_h_m_oecd_priv_sq=(p_intake_h_m_oecd_priv)^2  if d_private_c==1
bysort nu_ano co_municipio_curso `x': egen hhi_h_oecd_priv1_i = total(p_intake_h_m_oecd_priv_sq) if dup_cong_oecd<2 & d_private_c==1
bysort nu_ano co_municipio_curso `x': egen hhi_h_oecd_priv_i = max(hhi_h_oecd_priv1_i) if d_private_c==1


/*
***generate dummies for monopoly
gen d_monopoly_oecd=0
replace d_monopoly_oecd=1 if hhi_h_oecd==1

gen d_monopoly_oecd_priv=0
replace d_monopoly_oecd_priv=1 if hhi_h_oecd_priv==1


***generate the count of courses in the same oecd code within a provider and a city
gen y=1
bysort nu_ano co_cong co_municipio_curso `x':  egen n_courses_h_oecd = total(y)
bysort nu_ano co_municipio_curso d_public_hep `x':  egen n_courses_m_oecd = total(y)
bysort nu_ano co_municipio_curso `x' :  egen n_subjects_mun = total(y)
drop y

*/

***bring fees and the lag of fees
merge 1:1 nu_ano co_municipio_ies co_curso using "FEES_2015_2016_2017.dta"
drop if _merge==2
drop _merge

bysort nu_ano co_cong co_municipio_curso `x': egen FEE_oecd_mean=mean( fee_mean)
bysort nu_ano co_cong co_municipio_curso `x': egen FEE_oecd_median=mean( fee_median)
drop fee_mean fee_median

gen log_fee_mean=log( FEE_oecd_mean)
gen log_fee_median=log( FEE_oecd_median)

***lag of fees 
merge m:1 co_municipio_ies co_curso using "FEES_2014.dta", keepusing( log_fee_median_2014)
drop if _merge==2
drop _merge

***lag of fees 2012
merge m:1 co_municipio_ies co_curso using "FEES_2012.dta", keepusing( log_fee_median_2012)
drop if _merge==2
drop _merge





***bring the information of quality for each programme, from the National Institute of Educational Reseacrh (INEP)
***because the quality assessment exercise covers 1/3 of programmes every year, we need to use data from 3 years to obtain information of all courses
merge m:m co_curso using "CPC_2015_2016_2017.dta"
drop if _merge==2
drop _merge
 
gen score_astaffmsc_course1=score_astaffmsc_course-score_astaffphd_course
bysort co_municipio_curso co_conglomerate `x': egen score_astaffmsc_oecd=mean( score_astaffmsc_course1)
bysort co_municipio_curso co_conglomerate `x': egen score_astaffcontract_oecd=mean( score_astaffcontract_course)
bysort co_municipio_curso co_conglomerate `x': egen score_astaffphd_oecd =mean( score_astaffphd_course )

 
/*
egen students_evaluation1 =rmean( score_didped_course score_infra_course score_extra_course )
bysort nu_ano co_municipio_curso co_conglomerate `x': egen students_evaluation =mean( students_evaluation1 )
*/


bysort nu_ano co_municipio_curso co_conglomerate `x': egen n_astaff_h_oecd =total( n_astaff_course )
replace n_astaff_h_oecd=. if n_astaff_h_oecd==0
gen log_n_astaff_h_oecd=log(n_astaff_h_oecd)
gen prop_astaff_h_oecd=n_astaff_h_oecd /n_enrol_h_oecd

/*



***bring the information of academic staff aggregated at the provider level
merge m:1 nu_ano co_ies using "Staff_HEP_2015_2016_2017.dta"
drop if _merge==2
drop _merge

bysort  nu_ano co_conglomerate co_municipio_curso: egen n_staff_cong=mean( n_staff_ies)
bysort  nu_ano co_conglomerate co_municipio_curso: egen staff_rank_cong=mean( staff_rank_hep)
bysort  nu_ano co_conglomerate co_municipio_curso: egen staff_age_cong=mean(staff_age_hep )
gen log_staff_age_cong=log(staff_age_cong)
bysort  nu_ano co_conglomerate co_municipio_curso: egen staff_contract_cong=mean( staff_contract_hep)
gen staff_fullt_hep=5-staff_contract_cong
drop n_staff_ies staff_rank_hep staff_age_hep staff_contract_hep


*/





*rename nu_ano nu_ano_original
*gen nu_ano=nu_ano_original+1


save "Running_scores.dta", replace

use "IDD_2015-2017.dta", clear

**Merge the dataset on quality and and fees constructed for the previous regressions into the student scores dataset
merge m:m nu_ano co_ies co_curso using "Running_scores.dta"

drop if _merge==1
drop if _merge==2
drop _merge

bysort  nu_ano co_municipio_curso `x':  gen dup_area_mun = cond(_N==1,0,_n)

/*
local filelist 20
foreach y of local filelist  { 

**generate the mean of the top y% scores in ENEM per area and municipality, this is only generated for those markets with at least 5 students enrolled
*Standardize the initial scores to make them comparable across years


bysort co_munic `x': egen ENEM_mean_area=mean(ENEM_n)



bysort co_munic `x':egen ENEM_mean_`y'_low_1=mean(ENEM_n) if ENEM_rank_pc<((`y'/100)+.1) & max_rank_ENEM>4
bysort co_munic `x':egen ENEM_mean_`y'_low=max(ENEM_mean_`y'_low_1)
drop ENEM_mean_`y'_low_1


bysort co_munic `x':egen ENEM_mean_`y'_high_1=mean(ENEM_n) if ENEM_rank_pc>((100-`y')/100) & max_rank_ENEM>4
bysort co_munic `x':egen ENEM_mean_`y'_high=max(ENEM_mean_`y'_high_1)
drop ENEM_mean_`y'_high_1


label variable ENEM_mean_`y'_high "Market entry test mean top"
label variable ENEM_mean_`y'_low "Market entry test bottom"




*Standardize and centre final scores to make them comparable across different course areas
bysort co_grupo: egen mean_ENADE_oecd=mean(ENADE)
gen ENADE_d=ENADE-mean_ENADE_oecd
bysort co_grupo: egen sd_ENADE=sd(ENADE)
gen ENADE_n=((ENADE_d/sd_ENADE))
drop if ENADE==.
*/

bysort  co_cong  co_municipio_curso `x':  gen dup_hep = cond(_N==1,0,_n)
bysort  co_cong  co_municipio_curso:  gen dup_hep1 = cond(_N==1,0,_n)
bysort  co_cong  co_municipio_curso co_curso :  gen dup_hep2 = cond(_N==1,0,_n)
label variable dup_hep "Duplicate OECD subj"
label variable dup_hep1 "Duplicate provider"
label variable dup_hep2 "Duplicate program"




*gen log_n_enrol_h_oecd_priv=log(n_enrol_h_oecd_priv)




***bring the 2009 hhi
merge m:1 co_municipio_curso `x' using "Competition_2009_mkt", keepusing( hhi_h_oecd_priv_i_2009)
drop if _merge==2
drop _merge
replace hhi_h_oecd_priv_i_2009=1 if hhi_h_oecd_priv_i_2009==. 
replace hhi_h_oecd_priv_i_2009=1 if hhi_h_oecd_priv_i_2009==0

/*
merge m:1 co_municipio_curso `x' co_curso using "Competition_2009_prog", keepusing(log_n_enrol_prog_2009)
drop if _merge==2
drop _merge

gen d_monopoly_2009=0
replace d_monopoly_2009=1 if competition_h_oecd_priv_2009==0

replace competition_h_oecd_priv_2009=0 if competition_h_oecd_priv_2009==.
replace log_n_enrol_mun_oecd_priv_2009=0 if log_n_enrol_mun_oecd_priv_2009==.
replace log_n_enrol_prog_2009=0 if log_n_enrol_prog_2009==.
replace log_n_enrol_mun_oecd_2009=0 if log_n_enrol_mun_oecd_2009==.

*/

merge m:1 co_municipio_curso using "Pop_mun_18_14.dta", keepusing(pop18_24)
drop if _merge==2
drop _merge

*gen p_enrol_oecd_pop_18_24= (n_enrol_mun_oecd_total/ pop18_24)*10


*gen p_enrol_oecd_pop_18_24_2009= (n_enrol_mun_oecd_2009/ pop18_24)*10
*replace p_enrol_oecd_pop_18_24_2009=0 if p_enrol_oecd_pop_18_24_2009==.


*replace log_hour_load_oecd=0 if log_hour_load_oecd==.

*label variable ENEM_mean_area "Market entry test mean"


/*
label variable competition_h_oecd_priv "Market competition"
label variable competition_h_oecd_priv_2009 "Market competition 2009"
label variable ano_enem "Entry_test_year"

label variable competition_h_oecd_priv "Market competition "
label variable log_n_enrol_mun_oecd_priv "Market enrolments (log) "
label variable log_fee_median "Program fee (log)"
label variable prop_astaff_h_oecd "Program staff per student "
label variable staff_age_cong "Provider staff average age  "
label variable n_courses_h_oecd "Provider programmes/area "
label variable hour_load_oecd "Program total hours "
label variable log_n_enrol_h_oecd "Provider enrolments/area (log) "

label variable log_n_astaff_h_oecd  "Total program staff (log) "
label variable n_courses_m_oecd  "Number of courses in the same subject per municipality  "
label variable in_noturno_curso  "Evening program (dummy)  "
label variable p_staff_rsch_actv   "Provider staff active research "
label variable in_oferece_disc_semi_pres  "Program part online (dummy)  "
label variable log_hour_load_oecd   "Program length (log hours)  "
label variable in_oferece_disc_semi_pres  "Program part online (dummy)  "
label variable staff_fullt_hep   "Provider full-time staff"
label variable d_monopoly_oecd_priv  "Monopoly (dummy)"
*/
label variable score_astaffmsc_oecd "Program staff Master's "
label variable score_astaffphd_oecd "Program staff PhD "
label variable ENEM "Student entry score "
label variable ENADE "Student final score "


 
***bring the information of population numbers from the estimates of the National Office of GEography and Statistics, and drop those municipalities that have no higher education
merge m:1 co_municipio_curso using "Pop_mun_2017.dta"
drop if _merge==2
drop _merge
gen log_pop=log( pop_mun_2017)
***bring the information of aggregate income from the estimates of the National Office of GEography and Statistics, and drop those municipalities that have no higher education
merge m:1 co_municipio_curso using "GDP_mun_2015.dta"
drop if _merge==2
drop _merge
gen log_gdp=log(gdp_2015)


merge m:1 co_municipio_curso using "ENEM_total_2017.dta"
drop if _merge==2
drop _merge

/*
gen top_student_mkt=.
gen last_student_mkt=.
replace top_student_mkt=1 if rank_ENEM==1
replace top_student_mkt=1 if rank_ENEM==1
replace last_student_mkt=1 if rank_ENEM==max_rank_ENEM
*/






bysort  co_ocde_area_detalhada  co_municipio_curso :  gen dup_grupo_mun = cond(_N==1,0,_n)
bysort  co_ocde_area_detalhada  co_municipio_curso co_conglomerate :  gen dup_grupo_mun_cong = cond(_N==1,0,_n)

bysort  co_ocde_area_detalhada  co_municipio_curso co_conglomerate :  gen dup_curso = cond(_N==1,0,_n)
bysort  co_municipio_curso :  gen dup_municipio = cond(_N==1,0,_n)


gen intake_1=qt_ingresso_curso if dup_curso<2
bysort nu_ano co_municipio_curso co_ocde_area_detalhada : egen intake_total_grupo_mun=total( intake_1) 

bysort nu_ano co_municipio_curso co_conglomerate co_ocde_area_detalhada  : egen n_intake_h_grupo = total( intake_1)

gen p_intake_h_m_grupo= n_intake_h_grupo/intake_total_grupo_mun 

gen p_intake_h_m_grupo_sq=(p_intake_h_m_grupo)^2 if dup_grupo_mun_cong<2



bysort nu_ano co_municipio_curso co_ocde_area_detalhada : egen hhi_h_grupo_i = total(p_intake_h_m_grupo_sq)



gen d=1 if dup_grupo_mun_cong<2

bysort co_ocde_area_detalhada  co_municipio_c: egen n_courses_m_grupo=total(d)


save "Running_scores.dta", replace
}



use "Running_scores.dta", clear


local filelist  ENADE_FG ENADE_CE score_didped_course score_infra_course score_extra_course n_astaff_course  score_astaffphd_course score_astaffcontract_course score_astaffmsc_course
foreach x of local filelist  {  

rename `x' `x'_c 
}

  

*bring the lagged quality info
drop CPC_cont
merge m:m co_curso using "CPC_2012-2017_2.dta", keepusing(co_area CPC_cont ENADE_FG ENADE_CE IDD ano_cpc  score_didped_course score_infra_course score_extra_course n_astaff_course score_astaffmsc_course score_astaffphd_course score_astaffcontract_course)
drop if _merge==2
drop _merge

gen ENADE_lag=0.75*(ENADE_CE)+ 0.25*(ENADE_FG)

*this loop here will replace missing quality variables for those programs which did not exist in the 2012-2014 cycle but were created between cycles for those programs which are in a provider which operates the same subject in a different city
*this relies on the assumption that if the same provider opens a program in a different market it will provide similar quality - this is a strong assumption but it does not make a difference in the results to leave this observations as missing or fill them in, so I decided to get those extra observations into the paper
local filelist  ENADE_lag score_didped_course score_infra_course score_extra_course n_astaff_course score_astaffmsc_course score_astaffphd_course 
foreach x of local filelist  {  

bysort co_cong co_grupo : egen x=max(`x' )
replace `x'=x if `x' ==.
drop x
}



**this is a table which will track the observations I am losing as I prepare the dataset
*first thing it does is it counts the observations that I have up to here
matrix X2 = (.,.,.\.,.,.\.,.,.\.,.,.)
matrix colnames X2 =  "Obs" "Mean ENEM" "Mean ENADE"
matrix rownames X2 = "Initial" "Standardize" "Missing" "Singletons"

sum ENEM
matrix X2[1,1] = r(N) 
matrix X2[1,2] = r(mean) 
sum ENADE
matrix X2[1,3] = r(mean) 


bysort ano_enem: egen sd=sd(ENEM)
bysort ano_enem: egen mean=mean(ENEM)
gen ENEM_sd=(ENEM-mean)/sd
drop mean sd

bysort nu_ano co_grupo: egen sd=sd(ENADE)
bysort nu_ano co_grupo: egen mean=mean(ENADE)
gen ENADE_sd=(ENADE-mean)/sd
drop mean sd


bysort nu_ano co_grupo: egen sd=sd(ENADE_lag)
bysort nu_ano co_grupo: egen mean=mean(ENADE_lag)
gen ENADE_lag_sd=(ENADE_lag-mean)/sd
drop mean sd

bysort nu_ano co_grupo: egen sd=sd(score_astaffmsc_course)
bysort nu_ano co_grupo: egen mean=mean(score_astaffmsc_course)
gen score_astaffmsc_course_sd=(score_astaffmsc_course-mean)/sd
drop mean sd



*mark one observation per course
bysort  co_curso :  gen dup_curso_1 = cond(_N==1,0,_n)

*generate a program-level quality from the courses
gen x=ENADE_lag_sd if dup_curso_1<2
bysort co_ocde_area_detalhada co_municipio_c co_conglomerate: egen ENADE_lag_grupo_sd=mean(x)
drop x

drop if ENADE_lag_grupo_sd==.


bysort co_grupo: egen x=max(ano_cpc)
replace ano_cpc=x if ano_cpc==.
drop x

local filelist  ano_cpc co_grupo
foreach x of local filelist  {  
gen y=`x' if dup_curso_1<2

bysort co_conglomerate co_municipio_c co_ocde_area_detalhada : egen `x'_1=max(y)
drop y

replace `x'=`x'_1 if `x'==.
drop `x'_1
}

local filelist CPC_cont ENADE_FG ENADE_CE IDD
foreach x of local filelist  {  
gen y=`x' if dup_curso_1<2

bysort co_conglomerate co_municipio_c co_ocde_area_detalhada : egen `x'_1=mean(y)
drop y

replace `x'=`x'_1 if `x'==.
drop `x'_1
}


bysort co_ocde_area_detalhada: egen x=max(ano_cpc)
replace ano_cpc=x
drop x


sum ENEM 
matrix X2[2,1] = r(N) 
matrix X2[2,2] = r(mean)
sum ENADE
matrix X2[2,3] = r(mean) 

*bysort ano_cpc co_grupo: egen sd=sd(ENADE_lag_grupo)

*generate fee and quality at market levels 

bysort co_municipio_curso co_ocde_area_detalhada: egen FEE_market=mean(FEE_oecd_median)
bysort co_municipio_c co_ocde_area_detalhada: egen ENADE_lag_market=mean(ENADE_lag_grupo_sd )

bysort co_municipio_c co_ocde_area_detalhada  nu_ano: egen ENADE_lag_max_grupo_mun=max(ENADE_lag_grupo_sd)
bysort co_municipio_c co_ocde_area_detalhada  nu_ano: egen ENADE_lag_min_grupo_mun=min(ENADE_lag_grupo_sd)

bysort co_municipio_c co_ocde_area_detalhada  co_conglomerate: egen ENEM_mean_course=mean(ENEM)


gen intake_hep_grupo_1=qt_ingresso_curso if dup_curso<2
bysort co_municipio_c co_conglomerate co_ocde_area_detalhada : egen intake_hep_grupo=total(intake_hep_grupo_1)


bysort co_municipio_c co_ocde_area_d: egen max_ENADE_lag=max(ENADE_lag_sd)
bysort co_municipio_c co_ocde_area_d: egen min_ENADE_lag=min(ENADE_lag_sd)



*remove any observations with missing vars
keep if ENADE!=. & hhi_h_oecd_priv_i!=. & hhi_h_oecd_priv_i_2009!=. & ENEM!=.  & co_municipio_c!=. & ENADE_lag_sd !=. &FEE_oecd_median!=. &  hhi_h_oecd_priv_i!=0  & score_astaffmsc_course_sd!=.

sum ENEM 
matrix X2[3,1] = r(N)
matrix X2[3,2] = r(mean)
sum ENADE
matrix X2[3,3] = r(mean) 



*generate the markers for the observations which belong in the datasets in different levels
drop dup_grupo_mun dup_grupo_mun_cong
bysort  co_ocde_area_detalhada  co_municipio_curso co_conglomerate :  gen dup_grupo_mun_cong = cond(_N==1,0,_n)
gen d_dup_grupo_mun_cong=1 if  dup_grupo_mun_cong<2


bysort  co_ocde_area_detalhada  co_municipio_curso dup_grupo_mun_cong  :  gen dup_grupo_mun = cond(_N==1,0,_n) if dup_grupo_mun_cong==1
gen d_dup_grupo_mun=1 if  dup_grupo_mun<2





*this is a pre-run of the main models to identify the singleton observations when both the city and subject dummies are in
ivreghdfe FEE_market (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
gen x=e(sample)
bysort co_municipio_c co_ocde_area_d: egen x1=max(x)
drop if x1==0
drop x x1


ivreghdfe FEE_market (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun ==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
gen x=e(sample)
bysort co_municipio_c co_ocde_area_d: egen x1=max(x)
drop if x1==0
drop x x1



*drop sd

sum ENEM 
matrix X2[4,1] = r(N) 
matrix X2[4,2] = r(mean)
sum ENADE
matrix X2[4,3] = r(mean) 
matrix list X2




outtable using sample_scores, mat(X2) replace center  format(%11.2gc)






*top and bottom enem per market


bysort co_municipio_curso co_ocde_area_detalhada: egen rank_ENEM = rank(-ENEM_sd)
bysort co_municipio_curso co_ocde_area_detalhada: egen max_rank_ENEM = max(rank_ENEM)
bysort co_municipio_curso co_ocde_area_detalhada: gen ENEM_pc=rank_ENEM/max_rank_ENEM
drop  max_rank_ENEM



bysort co_municipio_curso co_ocde_area_detalhada: egen rank_ENEM_b = rank(ENEM_sd)
bysort co_municipio_curso co_ocde_area_detalhada: egen max_rank_ENEM = max(rank_ENEM)
bysort co_municipio_curso co_ocde_area_detalhada: gen ENEM_pc_b=rank_ENEM_b/max_rank_ENEM
drop  max_rank_ENEM

bysort co_municipio_c co_ocde_area_d (rank_ENEM): gen a = cond(_N==1,0,_n)
gen d_top_10=1 if a <=10 
drop a

bysort co_municipio_c co_ocde_area_d (rank_ENEM_b) : gen b = cond(_N==1,0,_n)
gen d_bottom_10=1 if b<=10
drop b


gen d_max_ENADE_lag=1 if max_ENADE_lag==ENADE_lag_sd
gen d_min_ENADE_lag=1 if min_ENADE_lag==ENADE_lag_sd
replace d_max_ENADE_lag=0 if d_max_ENADE_lag==.
replace d_min_ENADE_lag=0 if d_min_ENADE_lag==.



label variable FEE_oecd_mean  "Tuition fee"
label variable FEE_oecd_median  "Tuition fee (1000s)"
label variable hhi_h_oecd_priv_i  "HHI"
label variable hhi_h_oecd_priv_i_2009  "HHI (2009)"
label variable nu_ano  "Year"
label variable ENEM_mean_cours  "Mean entry score" 
label variable CPC_cont  "Quality index" 
label variable ENEM_sd  "Student ability" 
label variable ENADE_lag_grupo  "Program quality" 
label variable ENADE_lag_sd  "Program Quality" 
label variable n_intake_mun_oecd_priv  "Enrollments" 
label variable score_astaffmsc_course_sd  "Staff with MSc" 


save "Running_scores_1.dta", replace





use "Running_scores_1.dta", clear



twoway (kdensity ENADE_lag if  d_dup_grupo_mun_cong==1, color(gs2) ylabel(#10, angle(0) ) ), xtitle("Quality (lagged final scores)") xlabel( , angle(90)) ytitle("% of programs")  graphregion(color(white)) bgcolor(white)  title("") ytitle("Kernel density")
graph export "Quality.eps",  replace


twoway  (kdensity  ENEM  ,clpat(dash) color(gs2) graphregion(color(white)) bgcolor(white) ) ///
(kdensity  ENADE, clpat(solid) color(gs2) graphregion(color(white)) bgcolor(white)) ///
, legend(order(1  "Entry test" 2 "Final test" ) col(3))  title("")  xtitle("Entry scores") ytitle("Kernel density")
graph export "ENEM.eps",  replace



matrix T2 = (.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.\.,.,.,.,.,.,.)
matrix colnames T2 = "Level" "Year" "Obs" "Mean" "Std_Dev" "Min" "Max"
matrix rownames T2 = "Final_scores" " " " " " " "Entry_scores" " " " " " " " " " " " " " " " " "HHI" "HHI_(2009)" "Enrollments" "Fees" "Quality_index" "Academic_staff_MSc" "" "" "" "Fees"


forv i=0/2{
matrix T2[1+`i',2] = 2015+`i'
}


forv i=0/7{
matrix T2[5+`i',2] = 2009+`i'
}

matrix T2[14,2] = 2017
matrix T2[15,2] = 2009
matrix T2[16,2] = 2017
matrix T2[17,2] = 2017
matrix T2[18,2] = 2017

matrix T2[19,2] = 2012
matrix T2[20,2] = 2013
matrix T2[21,2] = 2014
matrix T2[23,2] = 2017

*Enade

forv i=0/2{
sum ENADE if nu_ano==2015+`i' 
matrix T2[1+`i',3] = r(N)
}

forv i=0/2{
sum ENADE if nu_ano==2015+`i' 
matrix T2[1+`i',4] = r(mean)
}

forv i=0/2{
sum ENADE if nu_ano==2015+`i' 
matrix T2[1+`i',5] = r(sd)
}

forv i=0/2{
sum ENADE if nu_ano==2015+`i' 
matrix T2[1+`i',6] = r(min)
}

forv i=0/2{
sum ENADE if nu_ano==2015+`i' 
matrix T2[1+`i',7] = r(max)
}


sum ENADE 
matrix T2[4,3] = r(N)
matrix T2[4,4] = r(mean)
matrix T2[4,5] = r(sd)
matrix T2[4,6] = r(min)
matrix T2[4,7] = r(max)


*Enem
forv i=0/7{
sum ENEM if ano_enem==2009+`i' 
matrix T2[5+`i',3] = r(N)
}

forv i=0/7{
sum ENEM if ano_enem==2009+`i' 
matrix T2[5+`i',4] = r(mean)
}

forv i=0/7{
sum ENEM if ano_enem==2009+`i' 
matrix T2[5+`i',5] = r(sd)
}

forv i=0/7{
sum ENEM if ano_enem==2009+`i' 
matrix T2[5+`i',6] = r(min)
}


forv i=0/7{
sum ENEM if ano_enem==2009+`i' 
matrix T2[5+`i',7] = r(max)
}


sum ENEM
matrix T2[13,3] = r(N) 
matrix T2[13,4] = r(mean)
matrix T2[13,5] = r(sd) 
matrix T2[13,6] = r(min)
matrix T2[13,7] = r(max) 


sum  hhi_h_oecd_priv_i if  d_dup_grupo_mun==1
matrix T2[14,3] = r(N) 
matrix T2[14,4] = r(mean)
matrix T2[14,5] = r(sd)  
matrix T2[14,6] = r(min)
matrix T2[14,7] = r(max) 


sum  hhi_h_oecd_priv_i_2009 if  d_dup_grupo_mun==1
matrix T2[15,3] = r(N) 
matrix T2[15,4] = r(mean)
matrix T2[15,5] = r(sd)  
matrix T2[15,6] = r(min)
matrix T2[15,7] = r(max) 

sum  n_intake_mun_oecd_priv if  d_dup_grupo_mun==1
matrix T2[16,3] = r(N) 
matrix T2[16,4] = r(mean)
matrix T2[16,5] = r(sd)  
matrix T2[16,6] = r(min)
matrix T2[16,7] = r(max) 

sum   FEE_market  if d_dup_grupo_mun==1
matrix T2[17,3] = r(N) 
matrix T2[17,4] = r(mean)
matrix T2[17,5] = r(sd) 
matrix T2[17,6] = r(min)
matrix T2[17,7] = r(max) 


sum  ENADE_lag if  d_dup_grupo_mun_cong==1
matrix T2[18,3] = r(N) 
matrix T2[18,4] = r(mean)
matrix T2[18,5] = r(sd) 
matrix T2[18,6] = r(min)
matrix T2[18,7] = r(max)

sum  score_astaffmsc_course if  d_dup_grupo_mun_cong==1 & ano_cpc==2012
matrix T2[19,3] = r(N) 
matrix T2[19,4] = r(mean)
matrix T2[19,5] = r(sd) 
matrix T2[19,6] = r(min)
matrix T2[19,7] = r(max)  

sum  score_astaffmsc_course if  d_dup_grupo_mun_cong==1 & ano_cpc==2013
matrix T2[20,3] = r(N) 
matrix T2[20,4] = r(mean)
matrix T2[20,5] = r(sd) 
matrix T2[20,6] = r(min)
matrix T2[20,7] = r(max) 

sum  score_astaffmsc_course if  d_dup_grupo_mun_cong==1 & ano_cpc==2014
matrix T2[21,3] = r(N) 
matrix T2[21,4] = r(mean)
matrix T2[21,5] = r(sd) 
matrix T2[21,6] = r(min)
matrix T2[21,7] = r(max) 

sum  score_astaffmsc_course if  d_dup_grupo_mun_cong==1
matrix T2[22,3] = r(N) 
matrix T2[22,4] = r(mean)
matrix T2[22,5] = r(sd) 
matrix T2[22,6] = r(min)
matrix T2[22,7] = r(max) 

sum   FEE_oecd_median  if  d_dup_grupo_mun_cong==1
matrix T2[23,3] = r(N) 
matrix T2[23,4] = r(mean)
matrix T2[23,5] = r(sd) 
matrix T2[23,6] = r(min)
matrix T2[23,7] = r(max) 



matrix list T2
outtable using descriptive_stats, mat(T2) replace center clabel(Table 1) format(%11.2gc)




use "Running_scores_1.dta", clear


local filelist  score_didped_course_c score_infra_course_c score_extra_course_c score_astaffmsc_course_c score_astaffphd_course_c score_astaffcontract_course_c
foreach x of local filelist  {  

bysort co_grupo: egen sd=sd(`x')
bysort co_grupo: egen mean=mean(`x')
replace `x'=(`x'-mean)/sd
drop mean sd

}




gen d_monopoly=0
replace d_monopoly=1 if hhi_h_oecd_priv_i==1



twoway (hist log_fee_median if  d_dup_grupo_mun_cong==1, color(gray) lcolor(black)  percent bin(19) ),    ylabel(, angle(0) ) xlabel(4.4284365 "84"	4.8852786 "133"	5.3421207 "209"	5.7989628 "330"	6.2558049 "522"	6.712647 "823"	7.1694891 "1300"	7.6263312 "2052"	8.0831733 "3240"	8.5400154 "5116"	8.9968575 "8078" , angle(90)) xtitle("Monthly fee (BRL) (log scale)") ytitle("% of programs") graphregion(color(white)) bgcolor(white) 


twoway (kdensity log_fee_median if  d_dup_grupo_mun_cong==1, color(gs2) ylabel(#10, angle(0) ) xlabel(4.4284365 "84"	4.8852786 "133"	5.3421207 "209"	5.7989628 "330"	6.2558049 "522"	6.712647 "823"	7.1694891 "1300"	7.6263312 "2052"	8.0831733 "3240"	8.5400154 "5116"	8.9968575 "8078" , angle(90)) ), xtitle("Monthly fee (BRL) (log scale)") xlabel( , angle(90)) ytitle("% of programs")  graphregion(color(white)) bgcolor(white)  title("") ytitle("Kernel density")
graph export "Fee.eps", as(eps) replace


twoway(hist hhi_h_oecd_priv_i if  d_dup_grupo_mun==1, width(.1) color(gray) lcolor(black) percent ), xlabel( , angle(90)) ylabel(#20, angle(0)) xtitle("HHI") ytitle("% of markets")  graphregion(color(white)) bgcolor(white)
graph export "HHI.eps", as(eps) replace

/*
twoway (kdensity ENADE_lag if  d_dup_grupo_mun_cong==1, color(gs2) ylabel(#10, angle(0) ) xlabel(-6(1)5) ), xtitle("Quality (lagged final scores)") xlabel( , angle(90)) ytitle("% of programs")  graphregion(color(white)) bgcolor(white)  title("") ytitle("Kernel density")
graph export "Quality_sd.eps",  replace
*/

twoway  (kdensity  ENEM  ,clpat(dash) color(gs2) graphregion(color(white)) bgcolor(white) ) ///
(kdensity  ENADE, clpat(solid) color(gs2) graphregion(color(white)) bgcolor(white)) ///
, legend(order(1  "Entry test" 2 "Final test" ) col(3))  title("")  xtitle("Entry scores") ytitle("Kernel density")
graph export "ENEM_sd.eps",  replace


gen log_intake=log(n_intake_mun_oecd_priv)

twoway (kdensity log_intake if  d_dup_grupo_mun_cong==1, color(gs2) ylabel(#10, angle(0) ) ), xtitle("Enrollments by market (log)" ) xlabel( 1 "3" 3 "20" 5 "150" 7 "1,100" 9 "8,000", angle(90)) ytitle("% of programs")  graphregion(color(white)) bgcolor(white)  title("") ytitle("Kernel density")
graph export "Enrollments.eps",  replace



*enrollments and fees


eststo clear
eststo model1: reghdfe FEE_market hhi_h_oecd_priv_i if  d_dup_grupo_mun ==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) noconstant 
eststo model2: ivreghdfe FEE_market (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun ==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model3: estimates restore firsthhi_h_oecd_priv_i
eststo model4: reghdfe n_intake_mun_oecd_priv hhi_h_oecd_priv_i if  d_dup_grupo_mun ==1, cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c)  noconstant
eststo model5: ivreghdfe n_intake_mun_oecd_priv (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun ==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model6: estimates restore firsthhi_h_oecd_priv_i
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using fees_enrollments.tex   ,  starlevels(* 0.10 ** 0.05 *** 0.010) scalars(N) b(a2) se(3) label replace  nonumber mtitles("OLS" "IV" "FS" "OLS" "IV" "FS"  ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)') keep(hhi_h_oecd_priv_i hhi_h_oecd_priv_i_2009)





eststo clear
eststo model1: reghdfe FEE_market d_monopoly hhi_h_oecd_priv_i if  d_dup_grupo_mun ==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) noconstant 
eststo model2: ivreghdfe FEE_market d_monopoly (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun ==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model3: estimates restore firsthhi_h_oecd_priv_i
eststo model4: reghdfe n_intake_mun_oecd_priv d_monopoly hhi_h_oecd_priv_i if  d_dup_grupo_mun ==1, cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c)  noconstant
eststo model5: ivreghdfe n_intake_mun_oecd_priv d_monopoly (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun ==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model6: estimates restore firsthhi_h_oecd_priv_i
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using fees_enrollments_rc1.tex   ,  starlevels(* 0.10 ** 0.05 *** 0.010) scalars(N) b(a2) se(3) label replace  nonumber mtitles("OLS" "IV" "FS" "OLS" "IV" "FS"  ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)') keep(hhi_h_oecd_priv_i hhi_h_oecd_priv_i_2009)



***********************************




eststo clear
eststo model1: reghdfe ENADE_sd  hhi_h_oecd_priv_i , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) noconstant
eststo model2: reghdfe ENADE_sd ENEM_sd  hhi_h_oecd_priv_i , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) noconstant
eststo model3: reghdfe ENADE_sd ENEM_sd ENADE_lag_sd  hhi_h_oecd_priv_i , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) noconstant
eststo model4: ivreghdfe ENADE_sd  (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) 
eststo model5: ivreghdfe ENADE_sd ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
eststo model6:ivreghdfe  ENADE_sd ENEM_sd  (ENADE_lag_sd hhi_h_oecd_priv_i =   score_astaffmsc_course_sd  hhi_h_oecd_priv_i_2009 )   , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_municipio_c co_ocde_area_detalhada)
estfe   . model*, labels(co_ocde_area_detalhada "Subject" co_municipio_curso "City") 
return list

esttab using new_effect.tex      ,  scalars(N) b(a2) se(3) starlevels(* 0.10 ** 0.05 *** 0.010)  label replace  nonumber mtitles("OLS" "OLS" "OLS" "IV" "IV" "IV")  addnote("Standard errors clustered at market level") indicate(`r(indicate_fe)')


eststo clear
eststo model1: reghdfe ENADE  hhi_h_oecd_priv_i , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) noconstant
eststo model2: reghdfe ENADE ENEM  hhi_h_oecd_priv_i , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) noconstant
eststo model3: reghdfe ENADE ENEM ENADE_lag_sd  hhi_h_oecd_priv_i , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) noconstant
eststo model4: ivreghdfe ENADE  (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) 
eststo model5: ivreghdfe ENADE ENEM (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
eststo model6:ivreghdfe  ENADE ENEM  (ENADE_lag_sd hhi_h_oecd_priv_i =   score_astaffmsc_course_sd  hhi_h_oecd_priv_i_2009 )   , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_municipio_c co_ocde_area_detalhada)
estfe   . model*, labels(co_ocde_area_detalhada "Subject" co_municipio_curso "City") 
return list

esttab using new_effect_rc1.tex   ,  scalars(N) b(a2) se(3) starlevels(* 0.10 ** 0.05 *** 0.010)  label replace  nonumber mtitles("OLS" "OLS" "OLS" "IV" "IV" "IV")  addnote("Standard errors clustered at market level") indicate(`r(indicate_fe)')



eststo clear
eststo model1: ivreghdfe ENADE_sd  (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) 
eststo model2: ivreghdfe ENADE_sd ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
eststo model3: ivreghdfe ENADE_sd ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
eststo model4:ivreghdfe  ENADE_sd ENEM_sd ENADE_lag_sd   ( hhi_h_oecd_priv_i =    hhi_h_oecd_priv_i_2009 )   , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_municipio_c co_ocde_area_detalhada)
eststo model5:ivreghdfe  ENADE_sd ENEM_sd score_astaffmsc_course_sd  ( hhi_h_oecd_priv_i =    hhi_h_oecd_priv_i_2009 )   , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_municipio_c co_ocde_area_detalhada)
estfe   . model*, labels(co_ocde_area_detalhada "Subject" co_municipio_curso "City") 
return list

esttab using new_effect_rc2.tex      ,  scalars(N) b(a2) se(3) starlevels(* 0.10 ** 0.05 *** 0.010)  label replace  nonumber mtitles("IV" "IV" "IV" "IV")  addnote("Standard errors clustered at market level") indicate(`r(indicate_fe)')








eststo clear
eststo model1: reghdfe ENADE_sd  d_monopoly hhi_h_oecd_priv_i , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) noconstant
eststo model2: reghdfe ENADE_sd d_monopoly ENEM_sd  hhi_h_oecd_priv_i , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) noconstant
eststo model3: reghdfe ENADE_sd d_monopoly ENEM_sd ENADE_lag_sd  hhi_h_oecd_priv_i , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) noconstant
eststo model4: ivreghdfe ENADE_sd  d_monopoly (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) 
eststo model5: ivreghdfe ENADE_sd d_monopoly ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
eststo model6:ivreghdfe  ENADE_sd d_monopoly ENEM_sd  (ENADE_lag_sd hhi_h_oecd_priv_i =   score_astaffmsc_course_sd  hhi_h_oecd_priv_i_2009 )   , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_municipio_c co_ocde_area_detalhada)
estfe   . model*, labels(co_ocde_area_detalhada "Subject" co_municipio_curso "City") 
return list

esttab using new_effect_rc3.tex      ,  scalars(N) b(a2) se(3) starlevels(* 0.10 ** 0.05 *** 0.010)  label replace  nonumber mtitles("OLS" "OLS" "OLS" "IV" "IV" "IV")  addnote("Standard errors clustered at market level") indicate(`r(indicate_fe)')








eststo clear
ivreghdfe ENADE_sd  (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c ) savefprefix(first)
eststo model1: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe ENADE_sd ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model2: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe  ENADE_sd ENEM_sd  (ENADE_lag_sd hhi_h_oecd_priv_i =   score_astaffmsc_course_sd  hhi_h_oecd_priv_i_2009 )   , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_municipio_c co_ocde_area_detalhada) savefprefix(first)
eststo model3: estimates restore firsthhi_h_oecd_priv_i
eststo model4: estimates restore firstENADE_lag_sd 
estfe   . model*, labels(co_ocde_area_detalhada "Subject" co_municipio_curso "City") 
return list

esttab using new_effect_fs.tex      ,  scalars(N) b(a2) se(3) starlevels(* 0.10 ** 0.05 *** 0.010)  label replace  nonumber mtitles("FS - HHI"  "FS - HHI" "FS - HHI"  "FS - Quality ")  addnote("Standard errors clustered at market level") indicate(`r(indicate_fe)')



***
 

eststo clear
eststo model1: reghdfe ENEM_sd hhi_h_oecd_priv_i,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) noconsta
eststo model2: reghdfe ENEM_sd hhi_h_oecd_priv_i if  d_top_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) noconsta
eststo model3: reghdfe ENEM_sd hhi_h_oecd_priv_i if d_bottom_10==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) noconsta


eststo model4: ivreghdfe ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009), cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
eststo model5: ivreghdfe ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_top_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
eststo model6: ivreghdfe ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if d_bottom_10==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)

estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list

esttab using ENEM_pc.tex , starlevels(* 0.10 ** 0.05 *** 0.010) scalars(N) b(a2) se(3)   label replace  nonumber mtitles("All (OLS)" "Top 10 (OLS)" "Bottom 10 (OLS)"  "All (IV)" "Top 10 (IV)" "Bottom 10 (IV)" ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')




eststo clear
ivreghdfe ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009), cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model1: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_top_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model2: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if d_bottom_10==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model3: estimates restore firsthhi_h_oecd_priv_i

estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City") 
return list

esttab using ENEM_pc_fs.tex , starlevels(* 0.10 ** 0.05 *** 0.010) scalars(N) b(a2) se(3)   label replace  nonumber mtitles("All" "Top 10" "Bottom 10" ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')



***with standardized ENADE scores

eststo clear
eststo model1: reghdfe ENADE_sd hhi_h_oecd_priv_i, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant
eststo model2: reghdfe ENADE_sd hhi_h_oecd_priv_i if  d_top_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant
eststo model3: reghdfe ENADE_sd hhi_h_oecd_priv_i if d_bottom_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant


eststo model4: ivreghdfe ENADE_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009), cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model5: ivreghdfe ENADE_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_top_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model6: ivreghdfe ENADE_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if d_bottom_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab

esttab using ENADE_t_b.tex, starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles( "All (OLS)" "Top 10 entry scores (OLS)" "Bottom 10 entry scores (OLS)"  " All (IV)" "Top 10 entry scores (IV)" "Bottom 10 entry scores (IV)" ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')



************************************************************************************************************
************************************************************************************************************
************************************************************************************************************
************************************************************************************************************


**quantile
use "Running_scores_1.dta", clear


local filelist  score_didped_course_c score_infra_course_c score_extra_course_c score_astaffmsc_course_c score_astaffphd_course_c score_astaffcontract_course_c
foreach x of local filelist  {  

bysort co_grupo: egen sd=sd(`x')
bysort co_grupo: egen mean=mean(`x')
replace `x'=(`x'-mean)/sd
drop mean sd

}

gen d_monopoly=0
replace d_monopoly=1 if hhi_h_oecd_priv_i==1



*there are two ways to run this - estimate the FS by hand and use the xtqreg with FEs, or use the ivqreg and demean the outcome variable by city and subject


*first the models we are using for comparison
eststo clear
eststo model1: ivreghdfe ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if d_bottom_10==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model2: ivreghdfe ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009),  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model3: ivreghdfe ENEM_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_top_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab



*then the qreg with no adaptations for comparison
*reg ENEM_sd hhi_h_oecd_priv_i i.(co_ocde_area_detalhada co_municipio_c), vce (robust) quantile(.1 .5 0.9)

* option to demean and use ivqreg2
bysort co_municipio_c co_ocde_area_detalhada: egen ENEM_sd_cs=mean(ENEM_sd)
ivqreg2 ENEM_sd_cs hhi_h_oecd_priv_i, inst(hhi_h_oecd_priv_i_2009) q(.1 .5 .9)

*then the option to xtqreg and run first stage by hand

reghdfe hhi_h_oecd_priv_i c.hhi_h_oecd_priv_i_2009 , absorb(co_municipio_c co_ocde_area_detalhada)
predict xb, xb

eststo clear
eststo model1: xtqreg ENEM_sd hhi_h_oecd_priv_i i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.1)
eststo model2: xtqreg ENEM_sd hhi_h_oecd_priv_i i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.5)
eststo model3: xtqreg ENEM_sd hhi_h_oecd_priv_i i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.9)
eststo model4: xtqreg ENEM_sd xb i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.1)
eststo model5: xtqreg ENEM_sd xb i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.5)
eststo model6: xtqreg ENEM_sd xb i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.9)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using quintile_entry.tex, starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles( "OLS 1st decile" "OLS median"  "OLS 9th decile" "IV 1st decile" "IV median" "IV 9th decile" ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)') keep(hhi_h_oecd_priv_i  xb)


eststo clear
eststo model1: xtqreg ENADE_sd  hhi_h_oecd_priv_i i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.1)
eststo model2: xtqreg ENADE_sd  hhi_h_oecd_priv_i i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.5)
eststo model3: xtqreg ENADE_sd  hhi_h_oecd_priv_i i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.9)
eststo model4: xtqreg ENADE_sd  xb i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.1)
eststo model5: xtqreg ENADE_sd  xb i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.5)
eststo model6: xtqreg ENADE_sd  xb i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.9)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using quintile_final.tex, starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles( "OLS 1st decile" "OLS median"  "OLS 9th decile" "IV 1st decile" "IV median" "IV 9th decile" ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)') keep(hhi_h_oecd_priv_i  xb)

eststo clear
eststo model1: xtqreg ENADE_lag_sd   hhi_h_oecd_priv_i i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.1)
eststo model2: xtqreg ENADE_lag_sd   hhi_h_oecd_priv_i i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.5)
eststo model3: xtqreg ENADE_lag_sd   hhi_h_oecd_priv_i i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.9)
eststo model4: xtqreg ENADE_lag_sd   xb i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.1)
eststo model5: xtqreg ENADE_lag_sd   xb i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.5)
eststo model6: xtqreg ENADE_lag_sd   xb i.co_ocde_area_detalhada, i(co_municipio_c) quantile(.9)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using quantile_quality.tex, starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles( "OLS 1st decile" "OLS median"  "OLS 9th decile" "IV 1st decile" "IV median" "IV 9th decile" ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)') keep(hhi_h_oecd_priv_i  xb)



************************************************************************************************************
************************************************************************************************************
************************************************************************************************************


eststo model1: reghdfe ENADE_sd hhi_h_oecd_priv_i, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant
eststo model2: reghdfe ENADE_sd hhi_h_oecd_priv_i if  d_top_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant
eststo model3: reghdfe ENADE_sd hhi_h_oecd_priv_i if d_bottom_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant


eststo model4: ivreghdfe ENADE_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009), cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model5: ivreghdfe ENADE_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_top_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model6: ivreghdfe ENADE_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if d_bottom_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab

esttab using ENADE_t_b_nsd.tex, starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles( "All (OLS)" "Top 10 entry scores (OLS)" "Bottom 10 entry scores (OLS)"  " All (IV)" "Top 10 entry scores (IV)" "Bottom 10 entry scores (IV)" ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')





**first stages
eststo clear
ivreghdfe ENADE_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009), cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) savefprefix(first)
eststo model1: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe ENADE_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_top_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) savefprefix(first)
eststo model2: estimates restore firsthhi_h_oecd_priv_i 
ivreghdfe ENADE_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if d_bottom_10==1, cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) savefprefix(first)
eststo model3: estimates restore firsthhi_h_oecd_priv_i
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list

esttab using ENADE_t_b_fs.tex, starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles( "All " "Top 10" "Bottom 10" ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')







***quality effects - differentiation

**if policymakers are worried that students are losing, then we should see that competition is bringing quality in all providers down, but that is not the case, the top quality providers are moving up, even if we keep fees constant
***this should prove that competition is actually good for private provision: the number of students enrolled in higher quality programs increases by more than the number of students enrolled in lower quality courses

ivreghdfe ENADE_lag_sd score_astaffmsc_course_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
predict ENADE_lag_xd if  d_dup_grupo_mun_cong ==1

eststo clear
eststo model1: reghdfe ENADE_lag_sd hhi_h_oecd_priv_i if  d_dup_grupo_mun_cong ==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)  noconstant
eststo model2: reghdfe ENADE_lag_sd hhi_h_oecd_priv_i  if  d_dup_grupo_mun_cong ==1 & d_max_ENADE_lag==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant
eststo model3: reghdfe ENADE_lag_sd hhi_h_oecd_priv_i  if  d_dup_grupo_mun_cong ==1 & d_min_ENADE_lag==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant

eststo model4: ivreghdfe ENADE_lag_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model5: ivreghdfe ENADE_lag_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_max_ENADE_lag==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model6: ivreghdfe ENADE_lag_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_min_ENADE_lag==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using quality_differentiation.tex    , starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles("All (OLS)" "Top quality(OLS)" "Bottom quality (OLS)" "All (IV)" "Top quality (IV)" "Bottom quality (IV)") addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')





***robustness check quality diff


eststo clear
eststo model1: reghdfe score_astaffmsc_course_sd hhi_h_oecd_priv_i if  d_dup_grupo_mun_cong ==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)  noconstant
eststo model2: reghdfe score_astaffmsc_course_sd hhi_h_oecd_priv_i  if  d_dup_grupo_mun_cong ==1 & d_max_ENADE_lag==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant
eststo model3: reghdfe score_astaffmsc_course_sd hhi_h_oecd_priv_i  if  d_dup_grupo_mun_cong ==1 & d_min_ENADE_lag==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant

eststo model4: ivreghdfe score_astaffmsc_course_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model5: ivreghdfe score_astaffmsc_course_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_max_ENADE_lag==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model6: ivreghdfe score_astaffmsc_course_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_min_ENADE_lag==1 , cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using quality_differentiation_rc.tex    , starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles("All (OLS)" "Top quality(OLS)" "Bottom quality (OLS)" "All (IV)" "Top quality (IV)" "Bottom quality (IV)") addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')

















***quality effects - differentiation first stages

**if policymakers are worried that students are losing, then we should see that competition is bringing quality in all providers down, but that is not the case, the top quality providers are moving up, even if we keep fees constant
***this should prove that competition is actually good for private provision: the number of students enrolled in higher quality programs increases by more than the number of students enrolled in lower quality courses
eststo clear
ivreghdfe score_astaffmsc_course_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 , cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) savefprefix(first)
eststo model1: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe score_astaffmsc_course_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_max_ENADE_lag==1 , cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)  savefprefix(first)
eststo model2: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe score_astaffmsc_course_sd (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_min_ENADE_lag==1 , cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)  savefprefix(first)
eststo model3: estimates restore firsthhi_h_oecd_priv_i


estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using quality_differentiation_fs.tex    , starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles("All" "Top quality" "Bottom quality") addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')




























eststo clear
eststo model1: reghdfe FEE_oecd_median hhi_h_oecd_priv_i if  d_dup_grupo_mun_cong ==1, cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c) noconstant
eststo model2: reghdfe FEE_oecd_median hhi_h_oecd_priv_i if  d_dup_grupo_mun_cong ==1 & d_max_ENADE_lag==1 , cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant
eststo model3: reghdfe FEE_oecd_median hhi_h_oecd_priv_i if  d_dup_grupo_mun_cong ==1 & d_min_ENADE_lag==1 , cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) noconstant


eststo model4: ivreghdfe FEE_oecd_median (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1, cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model5: ivreghdfe FEE_oecd_median (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_max_ENADE_lag==1 , cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
eststo model6: ivreghdfe FEE_oecd_median (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_min_ENADE_lag==1 , cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using fee_differentiation.tex , starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles("All (OLS)" "Top quality(OLS)" "Bottom quality (OLS)" "All (IV)" "Top quality (IV)" "Bottom quality (IV)") addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')



eststo clear
ivreghdfe FEE_oecd_median (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1, cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) savefprefix(first)
eststo model1: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe FEE_oecd_median (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_max_ENADE_lag==1 , cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) savefprefix(first) 
eststo model2: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe FEE_oecd_median (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009) if  d_dup_grupo_mun_cong ==1 & d_min_ENADE_lag==1 , cluster(co_municipio_c) absorb(co_ocde_area_detalhada co_municipio_c, keepsingletons) savefprefix(first) 
eststo model3: estimates restore firsthhi_h_oecd_priv_i
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using fee_differentiation_fs.tex , starlevels(* 0.10 ** 0.05 *** 0.010)  scalars(N) b(a2) se(3) label replace  nonumber mtitles("All" "Top quality" "Bottom quality") addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')






************
*BENEFIT FOR THE WHOLE MARKET


replace ENADE=ENADE+10
replace ENEM=ENEM+10

gen FEE_1= FEE_oecd_median*n_intake_h_oecd_priv
bysort co_municipio_c co_ocde_area_detalhada dup_grupo_mun_cong: egen FEE_2=sum(FEE_1) if  dup_grupo_mun_cong==1
gen FEE_3=FEE_2
replace FEE_3=FEE_oecd_median if FEE_3==0
bysort co_municipio_c co_ocde_area_detalhada: egen FEE_wm=max(FEE_3)
drop  FEE_1 FEE_2 FEE_3


bysort co_municipio_c co_ocde_area_detalhada co_cong:egen ENADE_1=mean(ENADE)
gen ENADE_2=ENADE_1*n_intake_h_oecd_priv if  dup_grupo_mun_cong==1
bysort co_municipio_c co_ocde_area_detalhada: egen ENADE_3=sum(ENADE_2)
gen ENADE_4=ENADE_3/n_intake_mun_oecd_priv
bysort co_municipio_c co_ocde_area_detalhada: egen ENADE_wm=max(ENADE_4)
drop ENADE_1 ENADE_2 ENADE_3 ENADE_4


gen benefit1=ENADE_wm*n_intake_mun_oecd_priv
gen cost1 = FEE_wm

gen benefit=log(benefit1)
gen cost=log(cost1)
replace benefit=0 if benefit==.
replace cost=0 if cost==.


eststo clear
eststo model1: reghdfe benefit    hhi_h_oecd_priv_i  if d_dup_grupo_mun==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) noconstant
eststo model2: reghdfe cost   hhi_h_oecd_priv_i  if d_dup_grupo_mun==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) noconstant

eststo model3: ivreghdfe benefit    (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009)  if d_dup_grupo_mun==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
eststo model4: ivreghdfe cost   (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009)  if d_dup_grupo_mun==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c)
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using benefit.tex,  scalars(N) b(a2) se(3) label replace  nonumber mtitles("Benefit (OLS)" "Cost (OLS)" "Benefit (IV)" "Cost (IV)"  ) addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')



eststo clear
ivreghdfe benefit    (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009)  if d_dup_grupo_mun==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model1: estimates restore firsthhi_h_oecd_priv_i
ivreghdfe cost   (hhi_h_oecd_priv_i= hhi_h_oecd_priv_i_2009)  if d_dup_grupo_mun==1,  cluster(co_municipio_c co_ocde_area_detalhada) absorb(co_ocde_area_detalhada co_municipio_c) savefprefix(first)
eststo model2: estimates restore firsthhi_h_oecd_priv_i
estfe  . model*, labels(nu_ano "Year final test" ano_enem "Year entry test" co_ocde_area_detalhada "Subject" co_municipio_curso "City")
return list
esttab using benefit_fs.tex,  scalars(N) b(a2) se(3) label replace  nonumber mtitles("Benefit" "Cost") addnote("Standard errors clustered at municipal and subject levels") indicate(`r(indicate_fe)')
















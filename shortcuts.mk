#######################################################################################
# Copyright 2009 Joshua Randall
#
# Joshua Randall <jcrandall@alum.mit.edu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################

PARAMDEFS += shrt[name]

PARAMDEF_MAPPINGS += shrt[pullgcinp]:pull_cols[MarkerName,HYB.GCIn.P.value,MEN.GCIn.P.value,WOMEN.GCIn.P.value,MENvsWOMEN.GCIn.P.value]
%.shrt[pullgcinp]: %.pull_cols[MarkerName,HYB.GCIn.P.value,MEN.GCIn.P.value,WOMEN.GCIn.P.value,MENvsWOMEN.GCIn.P.value]
	ln -fs $< $@

PARAMDEF_MAPPINGS += shrt[lrhetmengcin]:add_logradius[MENvsWOMEN.GCIn.P.value][MEN.GCIn.P.value][HetMen.GCIn.P.LogDistance]
%.shrt[lrhetmengcin]: %.add_logradius[MENvsWOMEN.GCIn.P.value][MEN.GCIn.P.value][HetMen.GCIn.P.LogDistance]
	ln -fs $< $@

PARAMDEF_MAPPINGS += shrt[lrhetwomgcin]:add_logradius[MENvsWOMEN.GCIn.P.value][WOMEN.GCIn.P.value][HetWomen.GCIn.P.LogDistance]
%.shrt[lrhetwomgcin]: %.add_logradius[MENvsWOMEN.GCIn.P.value][WOMEN.GCIn.P.value][HetWomen.GCIn.P.LogDistance]
	ln -fs $< $@

PARAMDEF_MAPPINGS += shrt[lrhetlggcin]:add_logradius[MENvsWOMEN.GCIn.P.value][Lowest.Gender.GCIn.P.value][Lowest.Gender.Het.GCIn.P.LogDistance]
%.shrt[lrhetlggcin]: %.add_logradius[MENvsWOMEN.GCIn.P.value][Lowest.Gender.GCIn.P.value][Lowest.Gender.Het.GCIn.P.LogDistance]
	ln -fs $< $@

PARAMDEF_MAPPINGS += shrt[grtr_lrhm_lrhw]:greatercol[HetMen.GCIn.P.LogDistance][HetWomen.GCIn.P.LogDistance][Greater.HetMen.HetWomen.GCIn.P.LogDistance]
%.shrt[grtr_lrhm_lrhw]: %.greatercol[HetMen.GCIn.P.LogDistance][HetWomen.GCIn.P.LogDistance][Greater.HetMen.HetWomen.GCIn.P.LogDistance]
	ln -fs $< $@

PARAMDEF_MAPPINGS += shrt[lssr_pm_pw]:lessercol[MEN.GCIn.P.value][WOMEN.GCIn.P.value][Lowest.Gender.GCIn.P.value]
%.shrt[lssr_pm_pw]: %.lessercol[MEN.GCIn.P.value][WOMEN.GCIn.P.value][Lowest.Gender.GCIn.P.value]
	ln -fs $< $@


#PARAMDEF_MAPPINGS += shrt[combinedlrp]:shrt[pullgcinp] shrt[combinedlrp]:shrt[lrhetmengcin] shrt[combinedlrp]:shrt[lrhetwomgcin]
#%.shrt[combinedlrp]: %.shrt[pullgcinp].shrt[lrhetmengcin].shrt[lrhetwomgcin]
#	ln -fs $< $@


#.shrt[pullgcinp].shrt[lssr_pm_pw].shrt[lrhetlggcin]

%.logdist: %.shrt\[pullgcinp\].shrt\[lssr_pm_pw\].shrt\[lrhetlggcin\]
	ln -fs $< $@

%.logdist-filtered: %.shrt[lssr_pm_pw].shrt[lrhetlggcin].filternum[Lowest.Gender.Het.GCIn.P.LogDistance][gte][7].filternum[MENvsWOMEN.GCIn.P.value][lt][0.05]
	ln -fs $< $@

%.corner-filtered: %.shrt[lssr_pm_pw].filternum[MENvsWOMEN.GCIn.P.value][lt][5e-4].filternum[Lowest.Gender.GCIn.P.value][lt][5e-6]
	ln -fs $< $@

%.bigcorner-filtered: %.shrt[lssr_pm_pw].filternum[MENvsWOMEN.GCIn.P.value][lt][1e-3].filternum[Lowest.Gender.GCIn.P.value][lt][1e-5]
	ln -fs $< $@

MAKECMDGOALS += FOO.shrt\[pullgcinp\].shrt\[lssr_pm_pw\].shrt\[lrhetlggcin\].filternum\[Lowest.Gender.Het.GCIn.P.LogDistance\]\[gte\]\[7\].filternum\[MENvsWOMEN.GCIn.P.value\]\[lt\]\[0.05\] FOO.HYB.MEN.WOMEN.MENvsWOMEN.combined.txt.logdist-filtered.add_chrpos_b36.indrankgd[MENvsWOMEN.GCIn.P.value][0.1][Tag].filternum[TagRank][lte][2].add_gene_non_loc_af_ak_bc_bx_b36 BMI-noremap.HYB.MEN.WOMEN.MENvsWOMEN.combined.txt.logdist-filtered.add_chrpos_b36.indrankgd[MENvsWOMEN.GCIn.P.value][0.1][Tag].filternum[TagRank][lte][2].add_gene_non_loc_af_ak_bc_bx_b36 FOO.gender-combined-logdist.invert_column[Lowest.Gender.Het.GCIn.P.LogDistance][Inv.Lowest.Gender.Het.GCIn.P.LogDistance].add_chrpos_b36.indrankgd[Inv.HetMen.GCIn.P.LogDistance][0.1][Tag] FOO.gender-combined-logdist.add_chrpos_b36.indrankgd[MENvsWOMEN.GCIn.P.value][0.1][Tag] FOO.shrt[lssr_pm_pw].shrt[lrhetlggcin].filternum[Lowest.Gender.Het.GCIn.P.LogDistance][gte][7].filternum[MENvsWOMEN.GCIn.P.value][lt][0.05] FOO.add_chrpos_b36.invert_column[Lowest.Gender.Het.GCIn.P.LogDistance][Inv.Lowest.Gender.Het.GCIn.P.LogDistance].indrankgd[Inv.Lowest.Gender.Het.GCIn.P.LogDistance][0.1][Tag].filternum[TagRank][eq][1] FOO.filternum[MENvsWOMEN.GCIn.P.value][ne][NA].ild.ildrank FOO.shrt[lssr_pm_pw].filternum[MENvsWOMEN.GCIn.P.value][lt][5e-4].filternum[Lowest.Gender.GCIn.P.value][lt][5e-6] FOO.shrt[lssr_pm_pw].filternum[MENvsWOMEN.GCIn.P.value][lt][1e-3].filternum[Lowest.Gender.GCIn.P.value][lt][1e-5]

%.lmwld: %.shrt[lssr_pm_pw].shrt[lrhetlggcin]
	ln -fs $< $@

%.gender-combined-logdist-filtered-annotated: %.HYB.MEN.WOMEN.MENvsWOMEN.combined.txt.logdist-filtered.add_chrpos_b36.indrankgd[MENvsWOMEN.GCIn.P.value][0.1][Tag].filternum[TagRank][lte][2].add_gene_non_loc_af_ak_bc_bx_b36
	ln -fs $< $@

%.ild: %.invert_column[Lowest.Gender.Het.GCIn.P.LogDistance][Inv.Lowest.Gender.Het.GCIn.P.LogDistance]
	ln -fs $< $@

%.ildrank: %.add_chrpos_b36.indrankgd[Inv.Lowest.Gender.Het.GCIn.P.LogDistance][0.1][Tag]
	ln -fs $< $@

%.gender-combined-logdist-filtered: %.HYB.MEN.WOMEN.MENvsWOMEN.combined.txt.logdist-filtered.add_chrpos_b36.indrankgd[MENvsWOMEN.GCIn.P.value][0.1][Tag].filternum[TagRank][lte][2]
	ln -fs $< $@

%.gender-combined-logdist: %.HYB.MEN.WOMEN.MENvsWOMEN.combined.txt.logdist.filternum[MENvsWOMEN.GCIn.P.value][ne][NA]
	ln -fs $< $@

%.gender-combined-logdist-phetrank: %.gender-combined-logdist.add_chrpos_b36.indrankgd[MENvsWOMEN.GCIn.P.value][0.1][Tag]
	ln -fs $< $@

%.gender-nonmiss-ildrank: %.filternum[MENvsWOMEN.GCIn.P.value][ne][NA].ild.ildrank
	ln -fs $< $@

%.leadsnps: %.filternum[TagRank][eq][1]
	ln -fs $< $@

%.labelanalysis: %
	~/scriptcentral/append-constant-cols.pl "Analysis" "$(word 1,$(subst ., ,$*))" < $< > $@


MOAMA-ALL-TRAITS%.rbind: BMI%.labelanalysis WEIGHT%.labelanalysis HEIGHT%.labelanalysis WHRadjBMI%.labelanalysis WCadjBMI%.labelanalysis WHR%.labelanalysis WC%.labelanalysis
	(head -n 1 $(word 1,$+) && (tail -q -n +2 $+)) > $@

MAKECMDGOALS += FOO.filternum[TagRank][eq][1]
%.leadsnpsonly: %.filternum[TagRank][eq][1]
	ln -fs $< $@

MAKECMDGOALS += FOO.indrankgd[Inv.Lowest.Gender.Het.GCIn.P.LogDistance][0.1][AllTraits]
%.rankalltraits: %.indrankgd[Inv.Lowest.Gender.Het.GCIn.P.LogDistance][0.1][AllTraits]
	ln -fs $< $@


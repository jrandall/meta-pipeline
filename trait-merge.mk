#######################################################################################
# Copyright 2008, 2009 Joshua Randall
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

define trait-merge_rules # TRAIT
#INTERNAL_GOALS := $(INTERNAL_GOALS) HYB.$(1).metal-se_MAC_gt_3.out HYB.$(1).metal-se_MAC_gt_3-gcc.out MEN.$(1).metal-se_MAC_gt_3.out MEN.$(1).metal-se_MAC_gt_3-gcc.out WOMEN.$(1).metal-se_MAC_gt_3.out WOMEN.$(1).metal-se_MAC_gt_3-gcc.out MEN.$(1).metal-se_MAC_gt_3.out.ttest_metal[WOMEN.$(1).metal-se_MAC_gt_3.out] MEN.$(1).metal-se_MAC_gt_3-gcc.out.ttest_metal[WOMEN.$(1).metal-se_MAC_gt_3-gcc.out]
MAKECMDGOALS := $(MAKECMDGOALS) HYB.$(1).metal-se_MAC_gt_3.out HYB.$(1).metal-se_MAC_gt_3-gcc.out MEN.$(1).metal-se_MAC_gt_3.out MEN.$(1).metal-se_MAC_gt_3-gcc.out WOMEN.$(1).metal-se_MAC_gt_3.out WOMEN.$(1).metal-se_MAC_gt_3-gcc.out MEN.$(1).metal-se_MAC_gt_3.out.ttest_metal[WOMEN.$(1).metal-se_MAC_gt_3.out] MEN.$(1).metal-se_MAC_gt_3-gcc.out.ttest_metal[WOMEN.$(1).metal-se_MAC_gt_3-gcc.out]

#$(1).markerlist: HYB.$(1).metal-se_MAC_gt_3.out HYB.$(1).metal-se_MAC_gt_3-gcc.out MEN.$(1).metal-se_MAC_gt_3.out MEN.$(1).metal-se_MAC_gt_3-gcc.out WOMEN.$(1).metal-se_MAC_gt_3.out WOMEN.$(1).metal-se_MAC_gt_3-gcc.out MEN.$(1).metal-se_MAC_gt_3.out.ttest_metal[WOMEN.$(1).metal-se_MAC_gt_3.out] MEN.$(1).metal-se_MAC_gt_3-gcc.out.ttest_metal[WOMEN.$(1).metal-se_MAC_gt_3-gcc.out]
#	(echo "MarkerName" && (tail -q -n +2 $$+ | cut -f`$(CUT_COL_NAME_SCRIPT) $$< MarkerName` -d$(TAB) | sort | uniq)) > $$@

#$(1).markerlist: Primary.OVERALL.$(1).metal-se_MAC_gt_3.out Primary.OVERALL.$(1).metal-se_MAC_gt_3-gcc.out Primary.MEN.$(1).metal-se_MAC_gt_3.out Primary.MEN.$(1).metal-se_MAC_gt_3-gcc.out Primary.WOMEN.$(1).metal-se_MAC_gt_3.out Primary.WOMEN.$(1).metal-se_MAC_gt_3-gcc.out Primary.MEN.$(1).metal-se_MAC_gt_3.out.ttest_metal[Primary.WOMEN.$(1).metal-se_MAC_gt_3.out] Primary.MEN.$(1).metal-se_MAC_gt_3-gcc.out.ttest_metal[Primary.WOMEN.$(1).metal-se_MAC_gt_3-gcc.out]
#	(echo "MarkerName" && (tail -q -n +2 $$+ | cut -f`$(CUT_COL_NAME_SCRIPT) $$< MarkerName` -d$(TAB) | sort | uniq)) > $$@

$(1).markerlist: Primary.MEN.$(1).metal-se_MAC_gt_3.out Primary.MEN.$(1).metal-se_MAC_gt_3-gcc.out Primary.WOMEN.$(1).metal-se_MAC_gt_3.out Primary.WOMEN.$(1).metal-se_MAC_gt_3-gcc.out Primary.MEN.$(1).metal-se_MAC_gt_3.out.ttest_metal[Primary.WOMEN.$(1).metal-se_MAC_gt_3.out] Primary.MEN.$(1).metal-se_MAC_gt_3-gcc.out.ttest_metal[Primary.WOMEN.$(1).metal-se_MAC_gt_3-gcc.out]
	(echo "MarkerName" && (tail -q -n +2 $$+ | cut -f`$(CUT_COL_NAME_SCRIPT) $$< MarkerName` -d$(TAB) | sort | uniq)) > $$@

#$(1).HYB.MEN.WOMEN.MENvsWOMEN.combined.txt: $(MERGE_COL_SCRIPT) $(1).markerlist HYB.$(1).metal-se_MAC_gt_3.out HYB.$(1).metal-se_MAC_gt_3-gcc.out MEN.$(1).metal-se_MAC_gt_3.out MEN.$(1).metal-se_MAC_gt_3-gcc.out WOMEN.$(1).metal-se_MAC_gt_3.out WOMEN.$(1).metal-se_MAC_gt_3-gcc.out MEN.$(1).metal-se_MAC_gt_3.out.ttest_metal[WOMEN.$(1).metal-se_MAC_gt_3.out] MEN.$(1).metal-se_MAC_gt_3-gcc.out.ttest_metal[WOMEN.$(1).metal-se_MAC_gt_3-gcc.out]
#	$$(word 1,$$+) --keepall 1 --missing "." --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "HYB.GCIn." --in $$(word 4,$$+) --colprefix "HYB.GCIn.GCOut." --in $$(word 5,$$+) --colprefix "MEN.GCIn." --in $$(word 6,$$+) --colprefix "MEN.GCIn.GCOut." --in $$(word 7,$$+) --colprefix "WOMEN.GCIn." --in $$(word 8,$$+) --colprefix "WOMEN.GCIn.GCOut." --in $$(word 9,$$+) --colprefix "MENvsWOMEN.GCIn." --in $$(word 10,$$+) --colprefix "MENvsWOMEN.GCIn.GCOut." --out $$@ --matchcols MarkerName --tmpdir="$(TMP_DIR)"

Primary.$(1).MEN.WOMEN.MENvsWOMEN.combined.txt: $(MERGE_COL_SCRIPT) $(1).markerlist Primary.MEN.$(1).metal-se_MAC_gt_3.out Primary.MEN.$(1).metal-se_MAC_gt_3-gcc.out Primary.WOMEN.$(1).metal-se_MAC_gt_3.out Primary.WOMEN.$(1).metal-se_MAC_gt_3-gcc.out Primary.MEN.$(1).metal-se_MAC_gt_3.out.ttest_metal[Primary.WOMEN.$(1).metal-se_MAC_gt_3.out] Primary.MEN.$(1).metal-se_MAC_gt_3-gcc.out.ttest_metal[Primary.WOMEN.$(1).metal-se_MAC_gt_3-gcc.out]
	$$(word 1,$$+) --keepall 1 --missing "." --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "MEN.GCIn." --in $$(word 4,$$+) --colprefix "MEN.GCIn.GCOut." --in $$(word 5,$$+) --colprefix "WOMEN.GCIn." --in $$(word 6,$$+) --colprefix "WOMEN.GCIn.GCOut." --in $$(word 7,$$+) --colprefix "MENvsWOMEN.GCIn." --in $$(word 8,$$+) --colprefix "MENvsWOMEN.GCIn.GCOut." --out $$@ --matchcols MarkerName --tmpdir="$(TMP_DIR)"

Primary+Replication.$(1).MEN.WOMEN.MENvsWOMEN.combined.txt: $(MERGE_COL_SCRIPT) $(1).markerlist Primary+Replication.MEN.$(1).metal-se_MAC_gt_3.out Primary+Replication.MEN.$(1).metal-se_MAC_gt_3-gcc.out Primary+Replication.WOMEN.$(1).metal-se_MAC_gt_3.out Primary+Replication.WOMEN.$(1).metal-se_MAC_gt_3-gcc.out Primary+Replication.MEN.$(1).metal-se_MAC_gt_3.out.ttest_metal[Primary+Replication.WOMEN.$(1).metal-se_MAC_gt_3.out] Primary+Replication.MEN.$(1).metal-se_MAC_gt_3-gcc.out.ttest_metal[Primary+Replication.WOMEN.$(1).metal-se_MAC_gt_3-gcc.out]
	$$(word 1,$$+) --keepall 1 --missing "." --in $$(word 2,$$+) --colprefix "" --in $$(word 3,$$+) --colprefix "MEN.GCIn." --in $$(word 4,$$+) --colprefix "MEN.GCIn.GCOut." --in $$(word 5,$$+) --colprefix "WOMEN.GCIn." --in $$(word 6,$$+) --colprefix "WOMEN.GCIn.GCOut." --in $$(word 7,$$+) --colprefix "MENvsWOMEN.GCIn." --in $$(word 8,$$+) --colprefix "MENvsWOMEN.GCIn.GCOut." --out $$@ --matchcols MarkerName --tmpdir="$(TMP_DIR)"

endef # trait-merge_rules
$(foreach trait,$(sort $(patsubst Primary.OVERALL.%,%,$(patsubst Primary.MEN.%,%,$(patsubst Primary.WOMEN.%,%,$(ANALYSES))))),$(eval $(call trait-merge_rules,$(trait))))
#$(foreach trait,$(sort $(patsubst Primary+Replication.OVERALL.%,%,$(patsubst Primary+Replication.MEN.%,%,$(patsubst Primary+Replication.WOMEN.%,%,$(ANALYSES))))),$(eval $(call trait-merge_rules,$(trait))))


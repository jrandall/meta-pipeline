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

PARAMDEFS += ttest[otherfile][effect1header][se1header][n1header][direction1header][effect2header][se2header][n2header][direction2header] ttest_metal[otherfile] innerjoin_rsid[otherfile] leftjoin_rsid[otherfile] 
PARAMDEF_MAPPINGS += ttest_metal[_otherfile_]:ttest[_otherfile_][Effect][StdErr][N][Direction][Effect][StdErr][N][Direction]



define paramdefs_TTEST_rules # OTHERFILE EFFECT1HEADER SE1HEADER N1HEADER DIRECTION1HEADER EFFECT2HEADER SE2HEADER N2HEADER DIRECTION2HEADER
%.ttest[$(1)][$(2)][$(3)][$(4)][$(5)][$(6)][$(7)][$(8)][$(9)]: %.innerjoin_rsid[$(1)] $(PAIRWISE_T_TEST_R_SCRIPT)
	$(RBIN) --args infile=$$(word 1,$$+) effect1header=$$*.$(2) se1header=$$*.$(3) totaln1header=$$*.$(4) direction1header=$$*.$(5) effect2header=$(1).$(6) se2header=$(1).$(7) totaln2header=$(1).$(8) direction2header=$(1).$(9) markerheader=MarkerName outfile=$$@ < $$(word 2,$$+) >& $$@.log
endef # paramdefs_TTEST_rules
$(foreach otherfile,$(paramdefs_ttest_otherfile_values),\
 $(foreach effect1header,$(paramdefs_ttest_effect1header_values),\
  $(foreach se1header,$(paramdefs_ttest_se1header_values),\
   $(foreach n1header,$(paramdefs_ttest_n1header_values),\
    $(foreach direction1header,$(paramdefs_ttest_direction1header_values),\
     $(foreach effect2header,$(paramdefs_ttest_effect2header_values),\
      $(foreach se2header,$(paramdefs_ttest_se2header_values),\
       $(foreach n2header,$(paramdefs_ttest_n2header_values),\
        $(foreach direction2header,$(paramdefs_ttest_direction2header_values),\
         $(eval $(call paramdefs_TTEST_rules,$(otherfile),$(effect1header),$(se1header),$(n1header),$(direction1header),$(effect2header),$(se2header),$(n2header),$(direction2header)))\
)))))))))


define paramdefs_TTEST_METAL_rules # OTHERFILE 
%.ttest_metal[$(1)]: %.ttest[$(1)][Effect][StdErr][N][Direction][Effect][StdErr][N][Direction] $(PAIRWISE_T_TEST_R_SCRIPT)
	ln -fs $$< $$@
endef # paramdefs_TTEST_METAL_rules
$(foreach otherfile,$(paramdefs_ttest_metal_otherfile_values),\
 $(eval $(call paramdefs_TTEST_METAL_rules,$(otherfile)))\
)



define paramdefs_INNERJOIN_RSID_rules # OTHERFILE
%.innerjoin_rsid[$(1)]: % $(1) $(MERGE_COL_SCRIPT)
	$(MERGE_COL_SCRIPT)  --tmpdir="$(TMP_DIR)" --in $$(word 1,$$+) --colprefix "$$*." --in $$(word 2,$$+) --colprefix "$(1)." --out $$@ --matchcolheaders MarkerName:MarkerName
endef # paramdefs_INNERJOIN_RSID_rules
$(foreach otherfile,$(paramdefs_innerjoin_rsid_otherfile_values) $(paramdefs_ttest_otherfile_values),$(eval $(call paramdefs_INNERJOIN_RSID_rules,$(otherfile))))

define paramdefs_LEFTJOIN_RSID_rules # OTHERFILE
%.leftjoin_rsid[$(1)]: % $(1) $(MERGE_COL_SCRIPT)
	$(MERGE_COL_SCRIPT)  --tmpdir="$(TMP_DIR)" --in $$(word 1,$$+) --colprefix "$$*." --in $$(word 2,$$+) --colprefix "$(1)." --out $$@ --matchcolheaders MarkerName:MarkerName --keepall 1 --missing "."
endef # paramdefs_LEFTJOIN_RSID_rules
$(foreach otherfile,$(paramdefs_leftjoin_rsid_otherfile_values) $(paramdefs_ttest_otherfile_values),$(eval $(call paramdefs_LEFTJOIN_RSID_rules,$(otherfile))))


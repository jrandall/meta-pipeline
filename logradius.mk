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

%.add_logradius: %
	awk 'NR==1 {$$6="logradius_men_het"; $$7="logradius_women_het"; $$8="logradius_largerofmenorwomen_het"; print $$0;} NR!=1 {$$6=sqrt( (-log($$3)/log(10))^2 + (-log($$5)/log(10))^2 ); $$7=sqrt( (-log($$4)/log(10))^2 + (-log($$5)/log(10))^2 ); if($$6>$$7) $$8=$$6; else $$8=$$7; print $$0;}' $< > $@

%.giant-overall-gender-p-values_20090618.txt.add_logradius: %.giant-overall-gender-p-values_20090618.txt
	awk 'NR==1 {$$6="logradius_men_het"; $$7="logradius_women_het"; $$8="logradius_largerofmenorwomen_het"; print $$0;} NR!=1 {$$6=sqrt( (-log($$3)/log(10))^2 + (-log($$5)/log(10))^2 ); $$7=sqrt( (-log($$4)/log(10))^2 + (-log($$5)/log(10))^2 ); if($$6>$$7) $$8=$$6; else $$8=$$7; print $$0;}' $< > $@

%.giant-overall-gender-p-values_20090618.txt.add_logradius.analysisname: %.giant-overall-gender-p-values_20090618.txt.add_logradius
	cat $< | ~/scriptcentral/append-constant-cols.pl "ANALYSIS" $* > $@


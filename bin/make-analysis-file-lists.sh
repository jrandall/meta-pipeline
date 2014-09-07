#!/bin/sh
###############################################################################
#
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
###############################################################################

echo "(`cut -f1 -d"." moama-overall-ALL-analyses | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" > moama-overall-ALL-analyses.re

echo "(`cut -f1 -d"." moama-overall-MENWOMEN-analyses | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" > moama-overall-MENWOMEN-analyses.re

echo "(`cut -f1 -d"." moama-overallheight-ALL-analyses | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" > moama-overallheight-ALL-analyses.re

echo "(`cut -f1 -d"." moama-overallheight-MENWOMEN-analyses | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" > moama-overallheight-MENWOMEN-analyses.re


# hybrid (men, women, or all)
((cat metalfiles.txt | egrep -i `cat moama-overall-ALL-analyses.re` | egrep -i '(whr|wh_rat|wchipr)' |egrep -i '(bmiadj|adjbmi|bmicov)' | egrep -i '(all|combined)') && (cat metalfiles.txt | egrep -i `cat moama-overall-MENWOMEN-analyses.re` | egrep -i '(whr|wh_rat|wchipr)' |egrep -i '(bmiadj|adjbmi|bmicov)' | egrep -i '(men|male|wom|fem)')) | sort > HYB.WHRadjBMI.analysisfiles.list

((cat metalfiles.txt | egrep -i `cat moama-overall-ALL-analyses.re` | egrep -i '(wc|waist)' | egrep -iv '(wchipr)' | egrep -i '(bmiadj|adjbmi|bmicov)' | egrep -i '(all|combined)') && (cat metalfiles.txt | egrep -i `cat moama-overall-MENWOMEN-analyses.re` | egrep -i '(wc|waist)' | egrep -iv '(wchipr)' | egrep -i '(bmiadj|adjbmi|bmicov)' | egrep -i '(men|male|wom|fem)')) | sort > HYB.WCadjBMI.analysisfiles.list

((cat metalfiles.txt | egrep -i `cat moama-overall-ALL-analyses.re` | egrep -i '(whr|wh_rat|wchipr)' |egrep -iv '(bmiadj|adjbmi|bmicov)' | egrep -i '(all|combined)') && (cat metalfiles.txt | egrep -i `cat moama-overall-MENWOMEN-analyses.re` | egrep -i '(whr|wh_rat|wchipr)' |egrep -iv '(bmiadj|adjbmi|bmicov)' | egrep -i '(men|male|wom|fem)')) | sort > HYB.WHR.analysisfiles.list

((cat metalfiles.txt | egrep -i `cat moama-overall-ALL-analyses.re` | egrep -i '(wc|waist)' |egrep -iv '(wchipr|bmiadj|adjbmi|bmicov)' | egrep -i '(all|combined)') && (cat metalfiles.txt | egrep -i `cat moama-overall-MENWOMEN-analyses.re` | egrep -i '(wc|waist)' |egrep -iv '(wchipr|bmiadj|adjbmi|bmicov)' | egrep -i '(men|male|wom|fem)')) | sort > HYB.WC.analysisfiles.list

((cat metalfiles.txt | egrep -i `cat moama-overall-ALL-analyses.re` | egrep -i '(bmi)' | egrep -i '(all|combined)') && (cat metalfiles.txt | egrep -i `cat moama-overall-MENWOMEN-analyses.re` | egrep -i '(bmi)' |egrep -iv '(bmiadj|adjbmi|bmicov)' | egrep -i '(men|male|wom|fem)')) | egrep -iv '(wc|waist|wh_rat|whr|wchipr)' | sort > HYB.BMI.analysisfiles.list

((cat metalfiles.txt | egrep -i `cat moama-overallheight-ALL-analyses.re` | egrep -i '(height)' | egrep -i '(all|combined)') && (cat metalfiles.txt | egrep -i `cat moama-overallheight-MENWOMEN-analyses.re` | egrep -i '(height)' |egrep -iv '(bmiadj|adjbmi|bmicov)' | egrep -i '(men|male|wom|fem)')) | egrep -iv '(wc|waist|wh_rat|whr|wchipr)' | sort > HYB.HEIGHT.analysisfiles.list

# sex-specifc
(cat metalfiles.txt | egrep -i '(whr|wh_rat|wchipr)' |egrep -i '(bmiadj|adjbmi|bmicov)' | egrep -i '(men|male)' | egrep -iv '(wom|fem)') | sort > MEN.WHRadjBMI.analysisfiles.list
(cat metalfiles.txt | egrep -i '(whr|wh_rat|wchipr)' |egrep -i '(bmiadj|adjbmi|bmicov)' | egrep -i '(wom|fem)') | sort > WOMEN.WHRadjBMI.analysisfiles.list

(cat metalfiles.txt | egrep -i '(wc|waist)' | egrep -iv '(wchipr)' | egrep -i '(bmiadj|adjbmi|bmicov)' | egrep -i '(men|male)' | egrep -iv '(wom|fem)') | sort > MEN.WCadjBMI.analysisfiles.list
(cat metalfiles.txt | egrep -i '(wc|waist)' | egrep -iv '(wchipr)' | egrep -i '(bmiadj|adjbmi|bmicov)' | egrep -i '(wom|fem)') | sort > WOMEN.WCadjBMI.analysisfiles.list

(cat metalfiles.txt | egrep -i '(whr|wh_rat|wchipr)' |egrep -iv '(bmiadj|adjbmi|bmicov)' | egrep -i '(men|male)' | egrep -iv '(wom|fem)') | sort > MEN.WHR.analysisfiles.list
(cat metalfiles.txt | egrep -i '(whr|wh_rat|wchipr)' |egrep -iv '(bmiadj|adjbmi|bmicov)' | egrep -i '(wom|fem)') | sort > WOMEN.WHR.analysisfiles.list

(cat metalfiles.txt | egrep -i '(wc|waist)' |egrep -iv '(wchipr|bmiadj|adjbmi|bmicov)' | egrep -i '(men|male)' | egrep -iv '(wom|fem)') | sort > MEN.WC.analysisfiles.list
(cat metalfiles.txt | egrep -i '(wc|waist)' |egrep -iv '(wchipr|bmiadj|adjbmi|bmicov)' | egrep -i '(wom|fem)') | sort > WOMEN.WC.analysisfiles.list

(cat metalfiles.txt | egrep -i '(bmi)' | egrep -i '(men|male)' | egrep -iv '(wom|fem)') | egrep -iv '(wc|waist|wh_rat|whr|wchipr|bmiadj|adjbmi|bmicov)' | sort > MEN.BMI.analysisfiles.list
(cat metalfiles.txt | egrep -i '(bmi)' | egrep -i '(wom|fem)') | egrep -iv '(wc|waist|wh_rat|whr|wchipr|bmiadj|adjbmi|bmicov)' | sort > WOMEN.BMI.analysisfiles.list

(cat metalfiles.txt | egrep -i '(height)' | egrep -i '(men|male)' | egrep -iv '(wom|fem)') | egrep -iv '(wc|waist|wh_rat|whr|wchipr|bmiadj|adjbmi|bmicov)' | sort > MEN.HEIGHT.analysisfiles.list
(cat metalfiles.txt | egrep -i '(height)' | egrep -i '(wom|fem)') | egrep -iv '(wc|waist|wh_rat|whr|wchipr|bmiadj|adjbmi|bmicov)' | sort > WOMEN.HEIGHT.analysisfiles.list


# withWHR
egrep -i "(`cut -f1 -d"." HYB.WHR.analysisfiles.list | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" HYB.BMI.analysisfiles.list | sort > HYB.BMIwithWHR.analysisfiles.list
egrep -i "(`cut -f1 -d"." HYB.WHR.analysisfiles.list | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" MEN.BMI.analysisfiles.list | sort > MEN.BMIwithWHR.analysisfiles.list
egrep -i "(`cut -f1 -d"." HYB.WHR.analysisfiles.list | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" WOMEN.BMI.analysisfiles.list | sort > WOMEN.BMIwithWHR.analysisfiles.list


# withWC
egrep -i "(`cut -f1 -d"." HYB.WC.analysisfiles.list | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" HYB.BMI.analysisfiles.list | sort > HYB.BMIwithWC.analysisfiles.list
egrep -i "(`cut -f1 -d"." HYB.WC.analysisfiles.list | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" MEN.BMI.analysisfiles.list | sort > MEN.BMIwithWC.analysisfiles.list
egrep -i "(`cut -f1 -d"." HYB.WC.analysisfiles.list | sort | uniq | perl -pi -e 's/\n/\|/g' | perl -pi -e 's/\|$//'`)" WOMEN.BMI.analysisfiles.list | sort > WOMEN.BMIwithWC.analysisfiles.list


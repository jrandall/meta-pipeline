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
DEFAULT_RASTERIZATION=150x150


################################################################################
# Rasterize PDF to PNG at various resolutions
################################################################################
%.72x72.png: %.pdf
	if test -s $(word 1,$+); then $(CONVERTBIN) $< $@; else touch $@; fi

%.150x150.png: %.pdf
	if test -s $(word 1,$+); then $(GSCONVERTBIN) -q -dQUIET -dPARANOIDSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=1 -dGridFitTT=1 -sDEVICE=pngalpha -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r150x150 -sOutputFile=$@ -f$<; else touch $@; fi

%.300x300.png: %.pdf
	if test -s $(word 1,$+); then $(GSCONVERTBIN) -q -dQUIET -dPARANOIDSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=1 -dGridFitTT=1 -sDEVICE=pngalpha -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r300x300 -sOutputFile=$@ -f$<; else touch $@; fi

%.600x600.png: %.pdf
	if test -s $(word 1,$+); then $(GSCONVERTBIN) -q -dQUIET -dPARANOIDSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=1 -dGridFitTT=1 -sDEVICE=pngalpha -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r600x600 -sOutputFile=$@ -f$<; else touch $@; fi



################################################################################
# Convert a PNG to put it over a white background (instead of transparent) 
################################################################################
#%.whitebg.png: %.png
#	if test -s $(word 1,$+); then $(CONVERTBIN) $< -fill white -draw 'matte 0,0 reset' $@; else touch $@; fi


################################################################################
# Default rasterization
################################################################################
%.png: %.$(DEFAULT_RASTERIZATION).png
	rm -f $@ && ln -s $< $@

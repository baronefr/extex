#!/bin/bash

set -e

MAINFILE='main.tex' 


BUILDFILE='extex.tex'
BUILDFILE_PDF=${BUILDFILE%.*}.pdf
BUILDDIR='.extex.build'

BUILD_INPUT='img/drawings/lhz10.tex'
BUILD_INPUT_NOPATH=${BUILD_INPUT##*/}
BUILD_INPUT_FILENAME=$(echo "${BUILD_INPUT_NOPATH%.*}") # this variable should not have any path or extension

OUTPUT_PDF_DIR='extex-pdf'
OUTPUT_SVG_DIR='extex-svg'


# assign output filename
OUTPUT_PDF_FILENAME="$BUILD_INPUT_FILENAME.pdf"
OUTPUT_SVG_FILENAME="$BUILD_INPUT_FILENAME.svg"

# prepare the file
MAINFILE_LINECUT=$(awk '/begin{document}/{ print NR; exit }' $MAINFILE)
echo "begin document found in line $MAINFILE_LINECUT"
sed -n "1,$((MAINFILE_LINECUT-1))p" $MAINFILE > $BUILDFILE
# TODO: if line is not found, just copy the file #cp $MAINFILE $BUILDFILE


PATCH_CROP_PREVIEW_PREAMBLE="\usepackage[displaymath,tightpage,active]{preview}"
PATCH_CROP_PREVIEW_BEGIN="\begin{preview}"
PATCH_CROP_PREVIEW_END="\end{preview}"


echo -e "\n\n%%%%%%%%%%%%%%\n% init extex %\n%%%%%%%%%%%%%%" >> $BUILDFILE

echo "$PATCH_CROP_PREVIEW_PREAMBLE" >> $BUILDFILE

echo "\begin{document}" >> $BUILDFILE
echo "$PATCH_CROP_PREVIEW_BEGIN" >> $BUILDFILE


echo "\input{$BUILD_INPUT}" >> $BUILDFILE


echo "$PATCH_CROP_PREVIEW_END" >> $BUILDFILE
echo "\end{document}" >> $BUILDFILE

echo -e "\n\n%%%%%%%%%%%%%\n% end extex %\n%%%%%%%%%%%%%" >> $BUILDFILE



# make pdf
mkdir -p $BUILDDIR
pdflatex -output-directory=$BUILDDIR $BUILDFILE > /dev/null # TODO maybe use -jobname= ?

# moving PDF files to pdf dir
mkdir -p $OUTPUT_PDF_DIR
mv $BUILDDIR/$BUILDFILE_PDF $OUTPUT_PDF_DIR/$OUTPUT_PDF_FILENAME


# convert to svg
mkdir -p $OUTPUT_SVG_DIR
pdf2svg $OUTPUT_PDF_DIR/$OUTPUT_PDF_FILENAME $OUTPUT_SVG_DIR/$OUTPUT_SVG_FILENAME


# remove build stuff
rm -r $BUILDDIR
rm $BUILDFILE

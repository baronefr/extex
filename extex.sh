#!/bin/bash

set -e

# handling inputs
args=( )
verbose=false
dry_run=false
make_svg=false
MAINFILE='main.tex'
OUTPUT_PDF_DIR='extex-pdf'
OUTPUT_SVG_DIR='extex-svg'
while (( $# )); do
  case $1 in
    -d|--dry-run) dry_run=true;;
    -s|--svg) make_svg=true;;
    -m|--main) MAINFILE=$2 
        shift;;
    -v|--verbose) verbose=true;;
    --out-pdf) OUTPUT_PDF_DIR=$2 
        shift;;
    --out-svg) OUTPUT_SVG_DIR=$2 
        shift;;
    -*) printf 'Unknown option: %q\n' "$1"
        exit 1 ;;
    *) args+=( "$1" ) ;;
  esac
  shift
done
set -- "${args[@]}"

if $verbose; then
    echo MAINFILE=$MAINFILE
    echo OUTPUT_PDF_DIR=$OUTPUT_PDF_DIR
    echo OUTPUT_SVG_DIR=$OUTPUT_SVG_DIR
    echo "args: ${args[@]}"
fi

if [ ${#args[@]} -eq 0 ]; then
    echo "empty argument! you must prompt a directory or a file."
    exit 1
fi


# build namespace
BUILD_TEMPLATE='extex.template.tex'
BUILDFILE='extex.tex'
BUILDFILE_PDF=${BUILDFILE%.*}.pdf
BUILDDIR='.extex.build'

# creating build workspace
mkdir -p $BUILDDIR
mkdir -p $OUTPUT_PDF_DIR
if $make_svg; then
    mkdir -p $OUTPUT_SVG_DIR
fi


# check if MAINFILE exists
if test -f $MAINFILE; then
    echo "main TeX file exists"
else
    echo "main TeX file does not exist. You must provide one!"
    exit 1
fi

# prepare the build file
MAINFILE_LINECUT=$(awk '/begin{document}/{ print NR; exit }' $MAINFILE)
if [ -z "${MAINFILE_LINECUT}" ]; then
    # in this case, the main file does not contain \begin{document}
    echo "no \begin{document} found, copying"
    cp $MAINFILE $BUILD_TEMPLATE
else
    # in this case, the main file contains \begin{document}
    echo "\begin{document} found in line <$MAINFILE_LINECUT>"
    sed -n "1,$((MAINFILE_LINECUT-1))p" $MAINFILE > $BUILD_TEMPLATE
fi

# patchers
PATCH_CROP_PREVIEW_PREAMBLE="\usepackage[displaymath,tightpage,active]{preview}"
PATCH_CROP_PREVIEW_BEGIN="\begin{preview}"
PATCH_CROP_PREVIEW_END="\end{preview}"


function extex_main {
    BUILD_INPUT=$1
    BUILD_INPUT_NOPATH=${BUILD_INPUT##*/}
    BUILD_INPUT_FILENAME=$(echo "${BUILD_INPUT_NOPATH%.*}") # this variable should not have any path or extension

    # assign output filename
    OUTPUT_PDF_FILENAME="$BUILD_INPUT_FILENAME.pdf"
    OUTPUT_SVG_FILENAME="$BUILD_INPUT_FILENAME.svg"

    # creating fresh copy of buildfile
    cp $BUILD_TEMPLATE $BUILDFILE

    echo -e "\n\n%%%%%%%%%%%%%%\n% init extex %\n%%%%%%%%%%%%%%" >> $BUILDFILE

    echo "$PATCH_CROP_PREVIEW_PREAMBLE" >> $BUILDFILE

    echo "\begin{document}" >> $BUILDFILE
    echo "$PATCH_CROP_PREVIEW_BEGIN" >> $BUILDFILE


    echo "\input{$BUILD_INPUT}" >> $BUILDFILE


    echo "$PATCH_CROP_PREVIEW_END" >> $BUILDFILE
    echo "\end{document}" >> $BUILDFILE

    echo -e "\n\n%%%%%%%%%%%%%\n% end extex %\n%%%%%%%%%%%%%" >> $BUILDFILE

    # make pdf
    echo "executing pdflatex -output-directory=$BUILDDIR $BUILDFILE"
    pdflatex -output-directory=$BUILDDIR $BUILDFILE > /dev/null # TODO maybe use -jobname= ?
    # moving PDF files to pdf dir
    echo "executing move mv $BUILDDIR/$BUILDFILE_PDF $OUTPUT_PDF_DIR/$OUTPUT_PDF_FILENAME"
    mv $BUILDDIR/$BUILDFILE_PDF $OUTPUT_PDF_DIR/$OUTPUT_PDF_FILENAME

    # convert to svg
    if $make_svg; then
        pdf2svg $OUTPUT_PDF_DIR/$OUTPUT_PDF_FILENAME $OUTPUT_SVG_DIR/$OUTPUT_SVG_FILENAME
    fi
}



for queue_element in "${args[@]}"; do

    if [ -d "$queue_element" ]; then # this is a directory, loop for all the files inside
        echo 'this is a directory'
        echo 'function of dir looping not yet implemented' # TODO
    elif [ -f "$queue_element" ]; then # this is a file
        echo 'this is a file'
        extex_main $queue_element
    else
        echo "error: $inp is neither a file or a directory"
        exit 1
    fi

done



# remove build stuff
rm -r $BUILDDIR
rm $BUILDFILE $BUILD_TEMPLATE

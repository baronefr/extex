#!/bin/bash

# extex v1.0 | latex iterative extractor
#            | dev: Barone Francesco
#            | link: https://github.com/baronefr/extex
#            | licence: GPL-3.0

set -e

color_reset='\e[0m'

function print_help {
    echo -e "\e[1;33mextex$color_reset | latex iterative extractor"
    echo -e "      |  v1.0 - Barone Francesco\n"
    echo "Usage:  extex [options] ARG1 ARG2 ..."
    echo "  where ARG* can be either a file or a directory. If a directory is prompted, extex is executed on all "
    echo "             the tex files contained in the directory (see -r option to change this behavior)."
    echo ""
    echo "Options:"
    echo "  -p | --preamble  Select file that will be used as LaTeX preamble. Default is main.tex."
    echo "  -s | --svg       Extract svg files alongside pdfs (requires pdf2svg)."
    echo "  -r | --rule      Change the directory iteration rule of the ARGS."
    echo "                    Default rule is '*.tex' (i.e. iterate over all .tex files in the directory)."
    echo "  --out-pdf        Output directory of PDF extracted files. Default is extex-pdf."
    echo "  --out-svg        Output directory of SVG extracted files. Default is extex-svg."
    echo "  --no-preview     Disable preview patchin (the content is wrapped in preview environment)."
    echo ""
    echo "  -c | --compiler  Compiler binary (pdflatex/xelatex or custom). Default is pdflatex."
    echo "  -f | --flags     Compiler flags. Default is -halt-on-error."
    echo "  --no-quiet       By default, compiler output is suppressed to /dev/null."
    echo "                    If this flag is prompted, stdout is not suppressed."
    echo ""
    echo "  -v | --verbose   Print additional debug details."
    echo ""
    echo "Requirements:"
    echo " - A working LaTeX installation. This script should have access to a compiler (pdflatex, xelatex, ...)."
    echo " - pdf2svg for converting pdf to svg files."
}

function echo_err { # echo for errors
    echo -e "\e[1;31merror$color_reset: $@"
}

function hecho { # highlighted echo
    echo -e "\e[34m$@$color_reset"
}

# default flags and variables
verbose=false  # verbose mode
make_svg=false # convert pdfs to svg
MAINFILE='main.tex' # preamble main file to use
OUTPUT_PDF_DIR='extex-pdf' # default output dir for pdf files
OUTPUT_SVG_DIR='extex-svg' # default output dir for svg files
QUEUE_RULE='*.tex' # default rule for directory files iteration
compiler_command=pdflatex # default compiler command
compiler_quiet=true # if true, suppresses compiler stdout
compiler_flags="-halt-on-error" # default compiler flags
PATCH_preview=true # enable patching via preview environment
# handling inputs ------------------------------
args=( )
while (( $# )); do
  case $1 in
    -v|--verbose) verbose=true;;
    -p|--preamble) MAINFILE=$2 
        shift;;
    -r|--rule) QUEUE_RULE=$2
        shift;;
    -s|--svg) make_svg=true;;
    -c|--compiler) compiler_command=$2
        shift;;
    --no-quiet) compiler_quiet=false;;
    -f|--flags) compiler_flags=$2
        shift;;
    --no-preview) PATCH_preview=false;;
    --out-pdf) OUTPUT_PDF_DIR=$2 
        shift;;
    --out-svg) OUTPUT_SVG_DIR=$2 
        shift;;
    -h|--help) print_help
        exit 0;;
    -*) printf 'Unknown option: %q\n' "$1"
        exit 1 ;;
    *) args+=( "$1" ) ;;
  esac
  shift
done
set -- "${args[@]}"

echo -e "\e[1;33mextex$color_reset | latex iterative extractor"
echo -e "      |  v1.0 - Barone Francesco\n"

if $verbose; then
    echo "argument parsing summary:"
    echo " | args: ${args[@]}"
    echo " | MAINFILE=$MAINFILE"
    echo " | OUTPUT_PDF_DIR=$OUTPUT_PDF_DIR"
    echo " | OUTPUT_SVG_DIR=$OUTPUT_SVG_DIR"
    echo " | make_svg=$make_svg"
    echo " | compiler_command=$compiler_command"
    echo " | compiler_flags$compiler_flags"
    echo " | compiler_quiet=$compiler_quiet"
    echo " | PATCH_preview=$PATCH_preview"
fi

# check if compiler exists
$verbose && echo "checking compiler"
if ! command -v $compiler_command 2>&1 >/dev/null; then
    echo_err "<$compiler_command> (compiler) is not valid"
    exit 1
fi
$verbose && echo "compiler check successful"
# check if pdf2svg exists
if $make_svg; then
    $verbose && echo "checking pdf2svg"
    if ! command -v pdf2svg 2>&1 >/dev/null; then
        echo_err "pdf2svg could not be found"
        exit 1
    fi
    $verbose && echo "pdf2svg check successful"
fi

# check mandatory arguments (at least one)
if [ ${#args[@]} -eq 0 ]; then
    echo_err "empty argument(s)! You must prompt at least a directory or a file."
    exit 1
fi


# build namespace
BUILD_TEMPLATE='extex.template.tex'
BUILDFILE='extex.tex'
BUILDFILE_PDF=${BUILDFILE%.*}.pdf
BUILDDIR='.extex.build'

# creating build workspace
$verbose && echo "creating build workspace"
mkdir -p $BUILDDIR
mkdir -p $OUTPUT_PDF_DIR
if $make_svg; then
    mkdir -p $OUTPUT_SVG_DIR
fi


# check if MAINFILE exists
if test -f $MAINFILE; then
    $verbose && echo "main TeX file exists"
else
    echo_err "main TeX file does not exist. You must provide one!"
    exit 1
fi

# prepare the build file
$verbose && echo "interrogating main TeX file: $MAINFILE"
MAINFILE_LINECUT=$(awk '/begin{document}/{ print NR; exit }' $MAINFILE)
$verbose && echo "interrogating result <$MAINFILE_LINECUT>"
if [ -z "${MAINFILE_LINECUT}" ]; then
    # in this case, the main file does not contain \begin{document}
    echo "no \begin{document} found, assuming main file is a template"
    cp $MAINFILE $BUILD_TEMPLATE
else
    # in this case, the main file contains \begin{document}
    echo "document begin found in line <$MAINFILE_LINECUT> of $MAINFILE"
    sed -n "1,$((MAINFILE_LINECUT-1))p" $MAINFILE > $BUILD_TEMPLATE
fi

# patchers
PATCH_CROP_PREVIEW_PREAMBLE="\usepackage[displaymath,tightpage,active]{preview}"
PATCH_CROP_PREVIEW_BEGIN="\begin{preview}"
PATCH_CROP_PREVIEW_END="\end{preview}"


function extex_main {
    # this function takes one argument:
    #   BUILD_INPUT <- $1 : name of the file to insert in the template
    BUILD_INPUT=$1
    $verbose && echo "extex_main invoked on file $BUILD_INPUT"
    BUILD_INPUT_NOPATH=${BUILD_INPUT##*/}
    BUILD_INPUT_FILENAME=$(echo "${BUILD_INPUT_NOPATH%.*}") # this variable should not have any path or extension
    $verbose && echo "build namespace: <$BUILD_INPUT_NOPATH> <$BUILD_INPUT_FILENAME>"

    # assign output filename
    OUTPUT_PDF_FILENAME="$BUILD_INPUT_FILENAME.pdf"
    OUTPUT_SVG_FILENAME="$BUILD_INPUT_FILENAME.svg"

    # creating fresh copy of buildfile
    cp $BUILD_TEMPLATE $BUILDFILE

    # manipulating the buildfile
    $verbose && echo "editing the buildfile"
    echo -e "\n\n%%%%%%%%%%%%%%\n% init extex %\n%%%%%%%%%%%%%%" >> $BUILDFILE

    # patching: add to preamble
    $PATCH_preview && echo "$PATCH_CROP_PREVIEW_PREAMBLE" >> $BUILDFILE

    echo "\begin{document}" >> $BUILDFILE

    # patching: document begin
    $PATCH_preview && echo "$PATCH_CROP_PREVIEW_BEGIN" >> $BUILDFILE

    # injecting the file to extract
    echo "\input{$BUILD_INPUT}" >> $BUILDFILE

    # patching: document end
    $PATCH_preview && echo "$PATCH_CROP_PREVIEW_END" >> $BUILDFILE

    echo "\end{document}" >> $BUILDFILE

    echo -e "\n\n%%%%%%%%%%%%%\n% end extex %\n%%%%%%%%%%%%%" >> $BUILDFILE

    # make pdf
    set +e
    if $compiler_quiet; then
        echo "  compiling in background..."
        $compiler_command $compiler_flags -output-directory=$BUILDDIR $BUILDFILE > /dev/null
    else
        echo "  compiling..."
        $compiler_command $compiler_flags -output-directory=$BUILDDIR $BUILDFILE
    fi
    if [ $? -ne 0 ]; then # checking the output of the last command
        echo_err "compilation process failed"
        echo "       I suggest to look at the compiler output (main.log)"
        echo "       or to suppress compiler quietness with the flag --no-quiet."
        echo "       The build file ($BUILDFILE) is kept for debugging."
        exit 1
    fi
    set -e
    echo "  compilation completed"

    # moving PDF files to pdf dir
    mv $BUILDDIR/$BUILDFILE_PDF $OUTPUT_PDF_DIR/$OUTPUT_PDF_FILENAME

    # convert to svg
    if $make_svg; then
        $verbose && echo "  making svg: $OUTPUT_SVG_DIR/$OUTPUT_SVG_FILENAME"
        pdf2svg $OUTPUT_PDF_DIR/$OUTPUT_PDF_FILENAME $OUTPUT_SVG_DIR/$OUTPUT_SVG_FILENAME
    fi
}


# processing elements in args
for queue_element in "${args[@]}"; do

    if [ -d "$queue_element" ]; then # this is a directory, loop for all the files inside
        [[ "${queue_element}" != */ ]] && queue_element="${queue_element}/" # adding / to directory, if not provided
        hecho "exploring directory $queue_element..."
        for filename in "$queue_element"$QUEUE_RULE; do
            if [ -f "$filename" ]; then
                hecho "∟ processing $filename"
                extex_main $filename
            fi
        done
    elif [ -f "$queue_element" ]; then # this is a file
        hecho "processing $queue_element"
        extex_main $queue_element
    else
        echo_err "$inp is neither a file or a directory"
        exit 1
    fi

done


# remove build stuff
$verbose && echo 'cleaning workspace'
rm -r $BUILDDIR
rm $BUILDFILE $BUILD_TEMPLATE

$verbose && echo 'execution completed'
exit 0
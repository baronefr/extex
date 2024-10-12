# extex

`extex` is a $\LaTeX$ extractor: it takes specific input files and compiles them to pdf, with tight page layout.
Additionaly, the pdf file can be exported to svg.

The original **purpose** of this utility is to **compile batches of tikz pictures to pdf**, avoiding the overhead of compiling them from scratch in a full-scale project. 
Another application is the ability to **export the tikz pictures as svg files**, which can be imported in PowerPoint documents (or any other document that does not support pdf input).

To assure the best compatibility, the $\LaTeX$ preamble is customizable. You might even use the same `main.tex` file of your source project: `extex` will take care of removing the document content (without touching your file) and use its preamble to compile the input files.


### Requirements

* Linux-based OS.
* A **working $\LaTeX$ installation**. The script should be able to access a compiler (pdflatex/xelatex or any custom binary that can be specified via option).
* **pdf2svg** (optional) for svg conversion.


## How does it work

TODO



## How to install

This utility can be used in two ways:
1. **Installation**: copy the `extex` script to a PATH directory. Doing so, the script can be invoked via terminal in any directory, on any project.
2. **Portable mode**: copy the `extex.sh` script to a directory of your choice and execute it. Obviously, this is not an installation.

Let me discuss at first the **installation procedure**. For the portable mode, just look at the [next subsection](#how-to-not-install-portable-mode).

**1)** Clone this repository:
```bash
git clone https://github.com/baronefr/extex.git
cd extex
```

**2)** Grant execution permit:
```bash
chmod +x extex.sh
```

**3)** Copy the script to a PATH directory. I suggest to use `~/.local/bin`.
```bash
cp extex.sh ~/.local/bin/extex
```

> [!NOTE]
> Notice that we have copied the script without the extension *.sh*. Doing so, we will be able to call the script as `extex`, without the extension.

Your script will now be accessible. I suggest running the following command to be sure that you are able to execute it. If no problem occurs, you should see the help menu.
```bash
extex --help
```

> [!WARNING]
> Be sure that the folder you choose is in your system PATH! To check if `~/.local/bin` is in your PATH, use the command
> ```bash
> if [[ ":$PATH:" == *":$HOME/.local/bin"* ]]; then echo 'yes'; else echo 'no'; fi
> ```
> The output should be yes (no) if the directory I suggested is (is not) in your PATH.
> If it is not present, edit your `.profile` or `.bashrc` file to [append it](https://unix.stackexchange.com/questions/26047/how-to-correctly-add-a-path-to-path).


### How to not install (portable mode)

If you wish to use this utility without installing, it is sufficient to copy the .sh script to any destination.
```bash
git clone https://github.com/baronefr/extex.git
cp extex/extex.sh YOUR_DESTINATION/extex.sh
```

If you wish to skip the repository download, use wget:
```bash
wget https://raw.githubusercontent.com/baronefr/extex/refs/heads/main/extex.sh
```



## Usage

TODO

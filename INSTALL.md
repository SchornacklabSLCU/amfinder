# ![](amfbrowser/data/amfbrowser.png) AMFinder installation instructions

## Command-line tool `amf`

1. Windows users only: install [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about) to get access to a Unix-like terminal. 
2. Install **Python 3.9** from the [official website](https://www.python.org/) or from your package manager.
3. Download AMFinder sources from Github, and extract the archive.
4. Move to the `amf` folder.
5. Open a terminal, run `export PYTHON=<path>`, replacing `<path>` with the path to Python 3.9.
6. Run `./install.sh`. If needed, add executable permissions with: `chmod +x install.sh`. Should the variable `PYTHON` not be set, the script will use the output of `which python3` instead.

**Important:** Before using `amf` for training or prediction (see next section), you will need to activate its Python virtual environment. To that end, open a terminal in the `amf` directory and run the command `source amfenv/bin/activate` to activate the virtual environment. Your terminal prompt will change to `(amfenv) $`. Once you are done with `amf`, you can deactivate the environment by running the command `deactivate`.

**Note:** old processors may lack AVX and AVX2 processor instructions 
and may fail to run Tensorflow. If you encounter such error, you need to
download and build Tensorflow from sources. Instructions can be found on
the Tensorflow website.

## Standalone interface `amfbrowser`

**Note:** As a graphical interface, `amfbrowser` **cannot** be installed on a
text-based system such as an HPC. Ready-to-use binaries are available. Windows
users can use the linux version once [Windows Subsystem for Linux
(WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10) has been 
activated.

### Linux

1. Download and install OPAM from the [official webwsite](https://opam.ocaml.org/doc/Install.html) or from your package manager.

2. Open a terminal in the `amfbrowser` folder and run the command: `export OPAM=<path>`, replacing `<path>` with the path to the opam program. Then, run the command `./install.sh` to install `amfbrowser` dependencies and compile `amfbrowser.exe`. Should the variable `OPAM` not be set, the script will use the output of `which opam`. If needed, add executable permissions to the installation file with: `chmod +x install.sh`. Follow the instructions on the screen and reply yes to the questions asked during opam installation and configuration. 

**Note:** You may need to install development packages such as `libgtk2.0-dev` and `libgtksourceview2.0-dev`. Users with [miniconda](https://docs.conda.io/en/latest/miniconda.html) or similar tool suite installed may encounter problems if their `PATH` variable has been altered. You may have to temporarily mask miniconda directory from your `PATH` variable by running `PATH=<modified_path> opam install ...`.


### MacOS

Same as Linux, but you will need [Homebrew](https://brew.sh/index_fr) to install OPAM.

### Windows 10

`amfbrowser` can be installed and run on Windows 10 after activation of
Windows Subsystem for Linux (WSL).

1. Activate [Windows Subsystem for Linux
(WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10). Then, go to
Windows App store and install a Linux distribution
([Ubuntu](https://ubuntu.com/) and [Debian](https://www.debian.org/index.html)
are recommended, but others should work too).

2. Install an OCaml build system based on the `brew` package manager:
```bash
$ sudo apt update
$ sudo apt upgrade
$ sudo apt autoclean
$ sudo apt install curl build-essential git
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
$ test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
$ test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
$ test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >> ~/.bash_profile
$ echo "eval \$($(brew --prefix)/bin/brew shellenv)" >> ~/.profile
$ brew install gpatch opam gtk+ cairo
```

3. Follow the [Linux installation instructions](#amfbrowseronlinux). You may have to edit the file `install.sh` with a text editor and uncomment the option `--disable-sandboxing`.

4. Install a X server (for instance, [Xming](https://sourceforge.net/projects/xming/))
and configure `bash` to tell GUIs to use the local X server by running `export DISPLAY=localhost:0.0`.
This variable has to be set for each session. As an alternative, you can save the
variable in your session configuration file by running: `echo "export DISPLAY=localhost:0.0" >> ~/.bashrc`
and reload the configuration (`. ~/.bashrc`). The new variable with then be automatically
set and does not have to be redefined manually.

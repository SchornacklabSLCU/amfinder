# ![](amfbrowser/data/amfbrowser.png) AMFinder installation instructions

## Command-line tool `amf`<a name="amf"></a>

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

# AMFinder

The Automatic Mycorrhiza Finder (AMFinder) allows for automatic computer
vision-based identification and quantification of AM fungal colonisation
and intraradical hyphal structures on ink-stained root images using
convolutional neural networks. **The latest version of AMFinder is v2.0.**

**Reference publication:** [Evangelisti _et al._, 2021, _New Phytologist_](https://doi.org/10.1111/nph.17697). 


## Summary

1. [Command-line tool `amf`](#amf)
2. [Standalone interface `amfbrowser`](#amfbrowser)
3. [A typical pipeline](#pipeline)

## Command-line tool `amf`<a name="amf"></a>

**The command-line tool `amf` trains neural networks and predicts fungal colonisation and intraradical structures.**

### Installation instructions

1. Windows users only: install [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about) to get access to a Unix-like terminal. 
2. Install **Python 3.7** from the [official website](https://www.python.org/) or from your package manager.
3. Download AMFinder sources from Github, and extract the archive.
4. Move to the `amf` folder.
5. Open a terminal, run `export PYTHON=<path>`, replacing `<path>` with the path to Python 3.7.
6. Run `./install.sh`. If needed, add executable permissions with: `chmod +x install.sh`. Should the variable `PYTHON` not be set, the script will use the output of `which python3` instead.

**Important:** Before using `amf` for training or prediction (see next section), you will need to activate its Python virtual environment. To that end, open a terminal in the `amf` directory and run the command `source amfenv/bin/activate` to activate the virtual environment. Your terminal prompt will change to `(amfenv) $`. Once you are done with `amf`, you can deactivate the environment by running the command `deactivate`.

**Note:** old processors may lack AVX and AVX2 processor instructions 
and may fail to run Tensorflow. If you encounter such error, you need to
download and build Tensorflow from sources. Instructions can be found on
the Tensorflow website.

### Using the software

**`amf` is used either to predict fungal colonisation and intraradical hyphal structures within plant root images (prediction mode), or to train AMFinder neural networks (training mode).**

#### Prediction mode<a name="amfpred"></a>

**Important**: Remember to activate `amf` virtual environment before use (see installation instructions).

For predictions, run in a terminal `amf predict <parameters> <images>` where `<parameters>` are either the short or long names listed below. Replace `<images>` with the path to the JPEG or TIFF images to analyse.

|Short|Long|Description|Default value|
|-|-|-|-|
|`-net CNN`|`--network CNN`|**Mandatory**. Use network `CNN` (see list below).|
|`-t N`|`--tile_size N`|**Optional**. Use `N` pixels as tile size.|N = 126|

Pre-trained networks to be used with the parameter `-net` are available in folder [`trained_networks`](amf/trained_networks). You can add your own trained networks to this folder.

|File name|Annotation level|Description|
|-|-|-|
|[CNN1v1.h5](amf/trained_networks/CNN1v1.h5)</a>|CNN1|Ink-stained, ClearSee-treated root pictures (flatbed scanner/microscope).|
|[CNN1v2.h5](amf/trained_networks/CNN1v2.h5)|CNN1|Same, but trained with data augmentation.|
|[CNN2v1.h5](amf/trained_networks/CNN2v1.h5)|CNN2|Ink-stained, ClearSee-treated microscope root pictures.|
|[CNN2v2.h5](amf/trained_networks/CNN2v2.h5)|CNN2|Same, but trained with data augmentation.|

**Note:** the image datasets used to generate these trained networks are available on [Zenodo](https://doi.org/10.5281/zenodo.5118948).

#### Training mode

**Note:** To be able to run `amf`, you first need to reactivate the virtual environment by running the command `source amfenv/bin/activate` (see installation guidelines, step 4).

For training, run in a terminal `amf train <parameters> <images>` where `<parameters>` are either the short or long names listed below (all training parameters are optional). Replace `<images>` with the path to the JPEG or TIFF images to analyse.

|Short|Long|Description|Default value|
|-|-|-|-|
|`-net CNN`|`--network CNN`|Use network `CNN`.|*ab initio* training|
|`-b N`|`--batch_size N`|Use a batch size of `N` tiles.|N = 32|
|`-k`|`--keep_background`|Do not skip any background tile.|False|
|`-a`|`--data_augmentation`|Activate data augmentation.|False|
|`-s`|`--summary`|Save CNN architecture and graph.|False|
|`-o PATH`|`--outdir PATH`|Save trained model and CNN architecture in `PATH`.|cwd|
|`-e N`|`--epochs N`|Perform `N` training cycles.|N = 100|
|`-p N`|`--patience N`|Wait for `N` epochs before early stopping.|N = 12|
|`-lr X`|`--learning_rate X`|Use `X` as learning rate for the Adam optimiser.|X = 0.001|
|`-vf N`|`--validation_fraction N`|Use `N` percents of total tiles as validation set.|N = 15%|
|`-1`|`--CNN1`|Train for root colonisation.|True|
|`-2`|`--CNN2`|Train for intraradical hyphal structures.|False|


Training can benefit from high-performance computing (HPC) systems.
Below is a template script for [Slurm](https://slurm.schedmd.com/):

```
#! /bin/bash
#SBATCH -e <error_file>
#SBATCH -o <output_file>
#SBATCH --mem=<memory_GB>
#SBATCH -n <procs>

ROOT=/home/<user>/amf

source $ROOT/amfenv/bin/activate
$ROOT/amf train <parameters> <images>
deactivate
```

## Standalone interface `amfbrowser`<a name="amfbrowser"></a>

**Browse, amend and validate `amf` predictions.**

![](doc/amfbrowser.png)

### Installation instructions<a name="amfbrowseronlinux"></a>

**Note:** As a graphical interface, `amfbrowser` **cannot** be installed on a
text-based system such as an HPC. Ready-to-use binaries are available. Windows
users can use the linux version once [Windows Subsystem for Linux
(WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10) has been 
activated.

#### Linux

1. Download and install OPAM from the [official webwsite](https://opam.ocaml.org/doc/Install.html) or from your package manager.

2. Open a terminal in the `amfbrowser` folder and run the command: `export OPAM=<path>`, replacing `<path>` with the path to the opam program. Then, run the command `./install.sh` to install `amfbrowser` dependencies and compile `amfbrowser.exe`. Should the variable `OPAM` not be set, the script will use the output of `which opam`. If needed, add executable permissions to the installation file with: `chmod +x install.sh`. Follow the instructions on the screen and reply yes to the questions asked during opam installation and configuration. 

**Note:** You may need to install development packages such as `libgtk2.0-dev` and `libgtksourceview2.0-dev`. Users with [miniconda](https://docs.conda.io/en/latest/miniconda.html) or similar tool suite installed may encounter problems if their `PATH` variable has been altered. You may have to temporarily mask miniconda directory from your `PATH` variable by running `PATH=<modified_path> opam install ...`.


#### MacOS

Same as Linux, but you will need [Homebrew](https://brew.sh/index_fr) to install OPAM.

#### Windows 10

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

## A typical pipeline<a name="pipeline"></a>

1. Predict colonisation on ink-stained root images: `amf predict -net your_CNN1.h5 *jpg`.

   **Note 1**: `amf` parameters can be found in [this section](#amfpred).
   
   **Note 2**: H5 files containing trained networks can be found in `trained_networks`. If you trained AMFinder on a specific dataset, copy/paste your custom H5 file to this folder. AMFinder won't use H5 files stored in other folders.
   
2. Convert computer predictions to annotations by running `amfbrowser your_image.jpg` on each image. AMFinder is a semi-automatic prediction pipeline. User supervision and validation of computer predictions for fungal colonisation is required before intraradical hyphal structures can be analysed.

    **Important:** `amfbrowser` is a graphical interface. It won't run on a text-based system such as an HPC.

3. Predict intraradical hyphal structures: `amf predict -net your_CNN2.h5 *jpg`.
4. Convert computer predictions to annotations by running `amfbrowser your_image.jpg` on each image.

# Automatic Mycorrhiza Finder (AMFinder)

The Automatic Mycorrhiza Finder (AMFinder) consists of the `amf` Python script
for automatic annotation of AM fungal colonization and fungal structures in
root images, and the standalone interface `amfbrowser` for inspection,
amendment and validation of computer predictions.


## Summary

1. [Command-line script (`amf`)](#amf)
2. [Standalone interface (`amfbrowser`)](#amfbrowser)

## Command-line script (`amf`)<a name="amf"></a>

The command-line script `amf` uses convolutional neural networks (ConvNets)
to predict **fungal root colonisation** (prediction stage 1) and **intraradical
hyphal structures** (prediction stage 2). The program uses pre-trained ConvNets
adapted to ink-stained root pictures. It can also train ConvNets on
**custom datasets** to enable analysis of differently stained
or labelled root images.

### Installation instructions

The command-line program `amf` requires [Python](https://www.python.org/)
**version 3.6** or above.
It is recommended to create a virtual environment to install the packages
listed in the dependency file `requirements.txt`. Below is an example of a
typical installation, followed by a test prediction.

```bash
$ python3.7 -m venv amfenv
$ source amfenv/bin/activate
(amfenv) $ python -m pip install -r requirements.txt
(amfenv) $ ./amf predict test/*jpg
(amfenv) $ deactivate
```

### Prediction mode

This is the mode to use when predicting structures on root images.

```bash
$ amf predict [-t tile_edge] [-m pre_trained] [IMAGE [IMAGE] ...]
```

### Training mode

Users may want to train `amf` on a specific set of images. This is especially
useful when analysing root images obtained with different **staining methods**
(such as trypan blue or chlorazol black) or that rely on **fluorescence**
(such as AlexaFluor-conjugated Wheat Germ Agglutinin).

```bash
$ amf train [-myc] [-e epochs] [--keep] [-f fraction] [-m pre-trained] [IMAGE [IMAGE] ...]
```

For large datasets, running the script on a high-performance computing (HPC)
equipment is recommended. An example using [Slurm](https://slurm.schedmd.com/)
workload manager is provided below.

```bash
#! /bin/bash
#SBATCH -e train.err
#SBATCH -o train.out
#SBATCH --mem=100G
#SBATCH -n 48

source /home/user/amfenv/bin/activate
./amf train dataset/*jpg
deactivate
```


## Standalone interface (`amfbrowser`)<a name="amfbrowser"></a>

The standalone interface `amfbrowser` allows to browse, amend and validate
`amf` predictions. Installation instructions are detailed below for the main
platforms.

![](doc/amfbrowser.png)

### Installation instructions

#### Linux

#### MacOS

#### Windows

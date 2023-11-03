<p align="center">
  <img width="226" height="74" src="doc/amfinder.png">
</p>

The Automatic Mycorrhiza Finder (AMFinder) allows for high-throughput computer
vision-based identification and quantification of AM fungal colonisation
and intraradical hyphal structures using
convolutional neural networks.

**The current version of AMFinder is v2.0.**

If you use AMFinder in your manuscript, please cite: 
[Evangelisti _et al._, 2021, Deep learning-based quantification of arbuscular mycorrhizal fungi in plant roots, _New Phytologist_ **232**(5): 2207-2219](https://doi.org/10.1111/nph.17697).


## Summary

1. [Installation](#install)
1. [Batch processing (`amf`)](#amf)
2. [Annotation browser (`amfbrowser`)](#amfbrowser)
3. [A typical annotation pipeline](#pipeline)
4. [How to batch stain plant roots?](#staining)

## Installation<a name="install"></a>

Detailed installation instructions for Linux, Mac and Windows can be found [here](INSTALL.md).
If you are not familiar with Python virtual environments, you may want
to read [this page](https://docs.python.org/3/tutorial/venv.html) first.


## Batch processing (`amf`)<a name="amf"></a>

The AMFinder tool `amf` is a batch mode program that predicts fungal structures, converts predictions into annotations, and train neural networks.
It is used as follows:

```
$ source amfenv/bin/activate
(amfenv) $ amf <action> <parameters> <images> 
```
where `<action>` is either:
- `predict`: prediction of fungal colonisation (CNN1) and intraradical hyphal structures (CNN2), 
- `convert`: automatic conversion of predictions to annotations, or
- `train`: neural network training.

`<images>` are the paths to the JPEG or TIFF images to analyse.  
Details about `<parameters>` are given in the following sections.



### Prediction mode<a name="amfpred"></a>

This mode is used to predict fungal colonisation (CNN1) and intraradical hyphal structures (CNN2).

|Short|Long|Description|Default value|
|-|-|-|-|
|`-net CNN`|`--network CNN`|**Mandatory**. Use network `CNN` (see list below).|
|`-t N`|`--tile_size N`|**Optional**. Use `N` pixels as tile size.|N = 126|

Pre-trained networks to be used with the parameter `-net` are available in the folder [`trained_networks`](amf/trained_networks). **AMFinder is looking for trained networks in this folder only**. Below is a list of publicly available networks. The image datasets used to generate them are available on [Zenodo](https://doi.org/10.5281/zenodo.5118948).

|File name|Annotation level|Description|
|-|-|-|
|[CNN1v1.h5](amf/trained_networks/CNN1v1.h5)</a>|CNN1|Ink-stained, ClearSee-treated root pictures (flatbed scanner/microscope).|
|[CNN1v2.h5](amf/trained_networks/CNN1v2.h5)|CNN1|Same, but trained with data augmentation.|
|[CNN2v1.h5](amf/trained_networks/CNN2v1.h5)|CNN2|Ink-stained, ClearSee-treated microscope root pictures.|
|[CNN2v2.h5](amf/trained_networks/CNN2v2.h5)|CNN2|Same, but trained with data augmentation.|

**Are you working with a system that appears challenging for AMFinder?** Please get in touch! We would be happy to help generate specialised CNN1/2 networks and make them widely available to the research community.


### Conversion mode<a name="amfconv"></a>

This mode is used to convert `amf predict` predictions (i.e. probabilities) to annotations.

|Short|Long|Description|Default value|
|-|-|-|-|
|`-1`|`--CNN1`|**Optional**. Convert CNN1 predictions.|yes|
|`-2`|`--CNN2`|**Optional**. Convert CNN2 predictions.|no|
|`-th X`|`--threshold X`|**Optional**. Use `X` as threshold for CNN2 conversions.|X = 0.5|



### Training mode

This mode is used to train AMFinder neural networks on different images. All parameters listed below are optional.

|Short|Long|Description|Default value|
|-|-|-|-|
|`-net N`|`--network N`|Use network `N`.|*none*|
|`-b N`|`--batch_size N`|Use a batch size of `N` tiles.|N = 32|
|`-k`|`--keep_background`|Do not skip any background tile.|False|
|`-a`|`--data_augmentation`|Activate data augmentation.|False|
|`-s`|`--summary`|Save CNN architecture and graph.|False|
|`-o DIR`|`--outdir DIR`|Save trained model and CNN architecture in `DIR`.|cwd|
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

## Annotation browser (`amfbrowser`)<a name="amfbrowser"></a>

The AMFinder standalone graphical interface `amfbrowser` enables the manual inspection of 
predictions and annotations. This tool can display predictions and 
annotations on top of the corresponding images. It enables users to edit values,
to browse low-quality predictions, and to perform automatic conversion of `amf`
predictions to annotations. You can run `amfbrowser` as follows:

```bash
$ amfbrowser <parameter> <image>
```

where `<parameter>` can be used to specify tile size (see below).

|Short|Long|Description|Default value|
|-|-|-|-|
|`-t N`|`--tile_size N`|**Optional**. Use `N` pixels as tile size.|N = 126|

<p align="center">
  <img width="648" height="369" src="doc/amfbrowser.gif">
</p>



## A typical annotation pipeline<a name="pipeline"></a>

Below is a bash script describing a typical prediction/annotation pipeline:

```bash
#! /bin/bash

source amfenv/bin/activate

# Predict fungal colonisation (CNN1) on a bunch of JPEG images.
./amf predict ink_stained_image{1-5}.jpg

# Convert CNN1 predictions to annotations.
./amf convert ink_stained_image{1-5}.jpg

# Predict intraradical structures (CNN2) on the same images.
./amf predict --network CNN2v2.h5 ink_stained_image{1-5}.jpg

# Convert CNN2 predictions to annotations using a threshold of 0.6.
./amf convert --CNN2 --threshold 0.6 ink_stained_image{1-5}.jpg

deactivate
```

Computer predictions and annotations can be checked and amended by running `amfbrowser` on each image. Although not absolutely necessary, user supervision and validation of computer predictions are recommended for quality control.



## How to batch stain plant roots?<a name="staining"></a>

An optimised ink-staining protocol with additional clearing is available in [Evangelisti *et al.* (2021)](https://doi.org/10.1111/nph.17697).

**Batch staining plant roots is essential for high-throughput analyses.** It can be achieved using a hand-crafted device composed of 10 cell strainers (100 µm nylon mesh) tied together with adhesive sealing film for PCR plates. A single sieve can accommodate a 4-week-old *N. benthamiana* root system. The sieves containing roots are immersed in 10% KOH, water, or ink/vinegar staining solution poured in a plastic lid. Plastic lids are floated in a hot (95°C) water bath to achieve the desired staining conditions. Sieves are pulled out of the lid containing the KOH solution and transferred to the washing solution, then to the ink staining solution without the need to manipulate roots, thereby reducing the risk of damage.

|View from above|View from below|With plastic lid|
|-|-|-|
|![](doc/Staining_sieves_1.jpg)|![](doc/Staining_sieves_2.jpg)|![](doc/Staining_sieves_3.jpg)

Credit: devices from Dr [Albin Teulet](https://twitter.com/albinteulet) and [Alex Guyon](https://twitter.com/alexwguyon) (Schornack lab), derived from an original idea by Dr Clément Quan.

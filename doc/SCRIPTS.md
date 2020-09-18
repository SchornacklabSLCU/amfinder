# CastANet Python scripts


## CastANet usage


```
usage: castanet.py [-h] [-t EDGE] {train,predict} ... [image [image ...]]

CastANet command-line arguments.

positional arguments:
  {train,predict}       action to be performed.
    train               learns how to identify AMF structures.
    predict             predicts AMF structures.
  image                 plant root scan to be processed.
                        default value: *jpg

optional arguments:
  -h, --help            show this help message and exit
  -t EDGE, --tile EDGE  tile edge, in pixels.
                        default value: 40 pixels
```

### CastANet training mode

```
usage: castanet.py train [-h] [-b NUM] [-d N%] [-e NUM] [-l ID | -m H5]
                         [-v N%]

optional arguments:
  -h, --help            show this help message and exit
  -b NUM, --batch NUM   training batch size.
                        default value: 32
  -d N%, --drop N%      percentage of background tiles to be skipped.
                        default value: 50%
  -e NUM, --epochs NUM  number of epochs to run.
                        default value: 100
  -l ID, --level ID     Annotation level identifier.
                        choices: {colonization, arb_vesicles, all_features}
                        default value: colonization
  -m H5, --model H5     path to the pre-trained model.
                        default value: none
  -v N%, --validate N%  percentage of tiles to be used for validation.
                        default value: 30%
```


### CastANet prediction mode

```
usage: castanet.py predict [-h] H5

positional arguments:
  H5          path to the pre-trained model.

optional arguments:
  -h, --help  show this help message and exit
```

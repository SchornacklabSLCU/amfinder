# CastANet - castanet_save.py

import os


def archive(results, path):
  if results is not None:
    base = os.path.splitext(path)[0]
    path = '{}.autotags.tsv'.format(base)
    results.to_csv(path, sep='\t', encoding='utf-8', index=False)

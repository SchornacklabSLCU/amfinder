#!/usr/bin/python

# Modified from the following:
# http://www.tom-ridge.com/2015-01-23_ocaml_dependency_graph_via_graphviz_and_dot_file.html

import os
import re
import sys

def sanitize(s):
    s=re.sub('.*/','',s)
    s=re.sub('[^0-9a-zA-Z]+', '_', s)
    return s

f=sys.stdin #open('.depend','r')
counter=0
dictionary={} # for storing map from int to filename
memo = []

print "digraph depend {"
for line in f:
    s=line.split();
    for x in range(2, len(s)):
        src = os.path.splitext(s[0])[0]
        dst = os.path.splitext(s[x])[0]
        if (src <> dst):
          link = src + " -> " + dst
          if not link in memo:
            memo.append(link)
            print(link)
print "}"

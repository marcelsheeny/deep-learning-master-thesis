# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import cv2
import numpy as np
from matplotlib import pyplot as plt

# read image
img = cv2.imread('/home/marcel/Pictures/lena512.bmp')

#convert to single channel
img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

#get edges
edges = cv2.Canny(img,100,200)

#compute distance transform
dt = cv2.distanceTransform(edges,distanceType=1,maskSize=3)

#display results
plt.subplot(131),plt.imshow(img,cmap = 'gray')
plt.title('Original Image'), plt.xticks([]), plt.yticks([])

plt.subplot(132),plt.imshow(edges,cmap = 'gray')
plt.title('Edge Image'), plt.xticks([]), plt.yticks([])

plt.subplot(133),plt.imshow(dt,cmap = 'gray')
plt.title('Distance Transform Image'), plt.xticks([]), plt.yticks([])

plt.show()
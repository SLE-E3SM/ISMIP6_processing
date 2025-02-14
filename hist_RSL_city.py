#!/usr/bin/env python

import glob


import argparse
import xarray as xr
import matplotlib.pyplot as plt
import numpy as np
import scipy.interpolate
import os, sys

parser = argparse.ArgumentParser(
                    description=__doc__)
parser.add_argument("-p", dest="outpath",
                    required=True,
                    help="SLM output path")
parser.add_argument("-i", dest="index",
                    type=int,
                    required=True,
                    help="output index to evaluate")
args = parser.parse_args()

cities = np.loadtxt('/usr/projects/climate/mhoffman/SLE-E3SM/ISMIP6_processing/cities_lat_long.txt',
                    skiprows=1, delimiter=',',
                    dtype={'names': ('city', 'lat', 'lon'),
                           'formats': ('U15', 'f8', 'f8')})
ncities = len(cities)
cc = 4 # montevideo
cc = 24 # midway
cc2=4

maxmodels = 100
rsl = np.zeros((maxmodels, ncities)) * np.nan
i = 0

for model in sorted(glob.glob(os.path.join(args.outpath, '*/'))):
   for run in sorted(glob.glob(os.path.join(args.outpath, model, '*/'))):
      print(f'Processing {run}')
      try:
         runpath = os.path.join(args.outpath, model, run, 'SLM_run/OUTPUT_SLM')
         ds_tgrid0 = xr.open_dataset(os.path.join(runpath, 'tgrid0.nc'))
         ds_tgrid = xr.open_dataset(os.path.join(runpath, f'tgrid{args.index}.nc'))
         GRD0 = ds_tgrid0.tgrid.values
         GRDi = ds_tgrid.tgrid.values

         GRD = GRD0 - GRDi
         GRD = np.append(GRD, np.expand_dims(GRD[:,0],1), axis=1)

         lat = ds_tgrid.lat
         lon = ds_tgrid.lon
         lon = np.append(lon, 360.0)
         for c in range(ncities):
            rsl[i,c] = scipy.interpolate.interpn((lat,lon), GRD, (cities[c][1], cities[c][2]), method='linear', bounds_error=True, fill_value=np.nan)
         ds_tgrid0.close()
         ds_tgrid.close()
         i += 1
      except:
         print('skipping')

ind = np.nonzero(np.logical_not(np.isnan(rsl[:,0])))[0]
vals = rsl[ind,:]

print(f'Processed {i} runs')
print('vals:', vals)

fig = plt.figure(figsize=(10, 4))
ax = fig.add_subplot(1, 1, 1)
ax.hist(vals[:,cc], bins=np.linspace(-0.5, 0.5, num=41, endpoint=True))
plt.xlabel('RSL (m)')
plt.ylabel('number')
plt.title(f'{cities[cc]}, index={args.index}\n{args.outpath}')

fig = plt.figure(2, figsize=(10, 4))
ax = fig.add_subplot(1, 1, 1)
plt.plot(vals[:,cc], vals[:,cc2], 'b.')
plt.grid()
ax.set_aspect('equal', 'box')

plt.draw()
#plt.savefig(f'GRD_{fname.split(".")[0]}.pdf')


plt.show()


#!/usr/bin/env python

import argparse
import xarray as xr
import matplotlib.pyplot as plt
#import matplotlib.colors as cols
#import matplotlib.ticker as mticker
#import matplotlib.patches as mpatches
import numpy as np
#from mpl_toolkits.axes_grid1 import make_axes_locatable
#from mpl_toolkits.axes_grid1.inset_locator import inset_axes
import cartopy
import cartopy.crs as ccrs
import os, sys

#from cartopy.util import add_cyclic_point
#import netCDF4
#from pyproj import Transformer, transform, CRS
#import matplotlib.tri as tri
#from matplotlib.colors import Normalize, TwoSlopeNorm
#from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER

parser = argparse.ArgumentParser(
                    description=__doc__)
parser.add_argument("-p", dest="outpath",
                    required=True,
                    help="SLM output path")
parser.add_argument("-i", dest="index",
                    type=int,
                    required=True,
                    help="output index to evaluate")
parser.add_argument("-r", dest="rng_GRD",
                    type=float,
                    required=False,
                    help="one-sided range of colorbar to use")
args = parser.parse_args()



ds_tgrid0 = xr.open_dataset(os.path.join(args.outpath, 'tgrid0.nc'))
ds_tgrid = xr.open_dataset(os.path.join(args.outpath, f'tgrid{args.index}.nc'))

cities = np.loadtxt('/usr/projects/climate/mhoffman/SLE-E3SM/ISMIP6_processing/cities_lat_long.txt',
                    skiprows=1, delimiter=',',
                    dtype={'names': ('city', 'lat', 'lon'),
                           'formats': ('U15', 'f8', 'f8')})

GRD0 = ds_tgrid0.tgrid.values
GRDi = ds_tgrid.tgrid.values

GRD = GRD0 - GRDi
lat = ds_tgrid.lat
lon = ds_tgrid.lon
GRD = np.append(GRD, np.expand_dims(GRD[:,0],1), axis=1)

lon = np.append(lon, 360.0)

try:
   gmslc_array = np.loadtxt(os.path.join(args.outpath, 'gmslc_ocnBetaArea'))
   gmslc = gmslc_array[args.index]
except:
   gmslc = 0.0


fig = plt.figure(figsize=(10, 4))
nlevs = 10
cmap='RdBu'
cmap='gist_ncar'

ax = fig.add_subplot(1, 1, 1, projection=ccrs.Robinson())
ax.set_global()
#rng_GRD = np.absolute(GRD).max()
if args.rng_GRD is None:
   rng_GRD = np.max(GRD)
else:
   rng_GRD = args.rng_GRD
print(f'Using one-sided colorbar range of {rng_GRD}')
cflevs = np.linspace(-rng_GRD, rng_GRD, num=nlevs*2+1, endpoint=True)
cbarticks = np.linspace(-rng_GRD, rng_GRD, num=nlevs+1, endpoint=True)
cf2 = ax.contourf(lon, lat, GRD, cflevs,
                  transform=ccrs.PlateCarree(),
                  #vmin=-rng_GRD, vmax=rng_GRD,
                  cmap=cmap, extend='both')

if 1:
    for c in cities:
        ax.plot(c['lon'], c['lat'], 'k.',
                transform=ccrs.PlateCarree())
        if 0:
            ax.annotate(c['city'], (c['lon'], c['lat']),
                    xytext=[5,5],
                    textcoords='offset pixels',
                    transform=ccrs.PlateCarree())

ax.coastlines(color=0.8 * np.array([1,1,1]))
#ax.gridlines()
plt.colorbar(cf2, ax=ax, label='RSL change (m)', ticks=cbarticks)
plt.title(f'GMSLC={gmslc:.4f} m, index={args.index}\n{args.outpath}')

plt.draw()
#plt.savefig(f'GRD_{fname.split(".")[0]}.pdf')


plt.show()


import xarray as xr
import numpy as np
import os
import sys

if len(sys.argv) != 5:
   sys.exit('ERROR: reformat_SL_inputdata.py requires 4 input arguments')

fpath_in = sys.argv[1]
icefname_in = sys.argv[2]
topofname_in = sys.argv[3]
dtime = float(sys.argv[4])

print("Using fpath_in="+fpath_in)
print("Using icefname_in="+icefname_in)
print("Using topofname_in="+topofname_in)
print(f"Using dtime={dtime}")

################## Only edit what's in the box as necessary ################
fpath_out = fpath_in + '../reformatted/'
icefname_out = 'grdice'
topofname_out = 'topo_initial'
############################################################################


# Part 1. reformatting the ice thickness file
# read in the original ice thickness data
print ('opening file:'+os.path.join(fpath_in, icefname_in) )
ds1 = xr.open_dataset(os.path.join(fpath_in, icefname_in), decode_times=False)
lithk = ds1.lithk
lat = ds1.lat
lon = ds1.lon
t = ds1.time

# loop through the original data and save each time level in separate file
times = dtime * np.arange(0, len(t))
np.savetxt(os.path.join(fpath_out+"times"), times)

for time_idx in np.arange(0, len(t)):
    dataOut = xr.Dataset({icefname_out: (['x', 'y'], lithk.data[time_idx,:,:])})
    dataOut.to_netcdf(os.path.join(fpath_out, f'{icefname_out}{time_idx}.nc'))


# Part 2. reformatting the initial bedrock topography
# read in topography files
etopo2_data = np.loadtxt('etopo2_512_orig') # present-day etopo2 dataset
etopo2_data = np.flipud(etopo2_data)
ds2 = xr.open_dataset(os.path.join(fpath_in, topofname_in)) # model topo
topg = ds2.topg.data
topg0 = topg[0, :, :] # take the initial topography
indx = np.where(np.isnan(topg0)) # find indices with NaN values
topg0[indx] = etopo2_data[indx] # replace the model topo with etopo2
dataOut = xr.Dataset({topofname_out: (['x', 'y'], topg0)})
dataOut.to_netcdf(os.path.join(fpath_out, f'{topofname_out}.nc'))


# Plot and check topography file
#import matplotlib.pyplot as plt
#import cartopy.crs as ccrs
#path_griddata = '/Users/hollyhan/Desktop/TEST/INPUT_FILES/Gridfiles/'
#lat512=np.loadtxt(path_griddata+"GLlat_512.txt")
#lon512=np.loadtxt(path_griddata+"GLlon_512.txt")

#fig = plt.figure()
#ax = plt.axes(projection=ccrs.PlateCarree())
#ax.contourf(lon512, lat512, topg0_save, transform=ccrs.PlateCarree()) #tgrid.nc(lon,lat)
#ax.set_global()
#ax.coastlines()
#plt.show()

#fig = plt.figure()
#levels = np.linspace(-2, 2, 14+1)
#ax = plt.axes(projection=ccrs.PlateCarree())
#cs = ax.contourf(lon512, lat512, topg0_save - topg_orig, levels=levels, transform=ccrs.PlateCarree())
#cbar = fig.colorbar(cs, ax=ax)
#cbar.ax.set_ylabel('solid surface height change (m)')
#ax.set_global()
#ax.coastlines()
#plt.show()


print("Reformatting complete.")

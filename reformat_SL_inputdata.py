import xarray as xr
import numpy as np
import os
import sys

if len(sys.argv) != 4:
   sys.exit('ERROR: reformat_SL_inputdata.py requires 3 input arguments')

fpath_in = sys.argv[1]
icefname_in = sys.argv[2]
topofname_in = sys.argv[3]

print("Using fpath_in="+fpath_in) 
print("Using icefname_in="+icefname_in) 
print("Using topofname_in="+topofname_in) 

################## Only edit what's in the box as necessary ################
# define the path and name of original ice files                           #
#fpath_in = '/Users/yariseidenbenz/Desktop/LANL_SL/ISMIP6-AIS/exp_05/PISM/regridded/'
#icefname_in = 'lithk_AIS_AWI_PISM1_exp05_GaussianGrid.nc'
#topofname_in = 'topg_AIS_AWI_PISM1_exp05_GaussianGrid.nc'
                                                                           #
# define the path and name to which the reformatted files are saved        #
# fpath_out = '/Users/yariseidenbenz/Desktop/LANL_SL/ISMIP6-AIS/exp_05/PISM/reformatted/'                                   #
fpath_out = fpath_in + '../reformatted/'
icefname_out = icefname_in.replace('.nc', '_')                             #
topofname_out = topofname_in.replace('.nc', '')                            #
topofname_out = topofname_out.replace('topg', 'topg_init')                 #
############################################################################

# Part 1. reformatting the ice thickness file
# read in the original ice thickness data
print ('opening file:'+os.path.join(fpath_in, icefname_in) )
ds1 = xr.open_mfdataset(os.path.join(fpath_in, icefname_in), combine='nested')
lithk = ds1.lithk
lat = ds1.lat
lon = ds1.lon
t = ds1.time

# loop through the original data and save in a time interval of 'dtime'
dtime = 5  # time interval (in years) between ice files with successive indices
times = dtime * np.arange(0, len(np.arange(0, len(t)+1, dtime)))
np.savetxt(os.path.join(fpath_out+"times"), times)
#f = open(os.path.join(fpath_out,'times'), 'w') # write a new time array file
for time_idx in np.arange(0, len(np.arange(0, len(t)+1, dtime))):
    idx = time_idx * dtime

    lithk_save = np.flipud(lithk[idx])  # reorient the data along latitude [90 -90]
    lithk_save[np.where(lithk_save > 10000)] = 0  # zero out the fill values
    lithk_save[np.isnan(lithk_save)] = 0  # zero out NaN values

    np.savetxt(os.path.join(fpath_out, icefname_out + str(time_idx)), lithk_save)
    #f.write(str(t.values[idx]))
   # f.write("\n")
#f.close()

# Part 2. reformatting the initial bedrock topography
# read in topography files
etopo2_data = np.loadtxt('etopo2_512_orig') # present-day etopo2 dataset
ds2 = xr.open_dataset(os.path.join(fpath_in, topofname_in)) # model topo
topg = ds2.topg
topg0 = topg[0, :, :] # take the initial topography
topg0_save = np.flipud(topg0)  # reorient the data along latitude [90 -90]
topg0_save[np.where(topg0_save > 1e5)] = float("NaN")  # Assign fill values with NaN
topg0_save[np.where(topg0_save == 0)] = float("NaN")
indx = np.where(np.isnan(topg0_save)) # find indices with NaN values
topg0_save[indx] = etopo2_data[indx] # replace the model topo with etopo2
np.savetxt(os.path.join(fpath_out, topofname_out), topg0_save)


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

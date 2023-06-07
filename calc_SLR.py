import numpy as np
import netCDF4
import argparse


rhoo = 1028.0
rhoi = 910.0
Aocn = 3.625e14

parser = argparse.ArgumentParser(
    description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('--lithk', dest='lithk', required=True,
                    help='')
parser.add_argument('--topg', dest='topg', required=True,
                    help='')
parser.add_argument('--out', dest='out', required=True,
                    help='')
args = parser.parse_args()


f1 = netCDF4.Dataset(args.lithk, 'r')
lithk = f1.variables['lithk']
if 'x' in f1.variables:
    x = f1.variables['x']
    dx = x[1] - x[0]
else:
    nx = len(f1.dimensions['x'])
    if nx == 761:
        dx = 8000.0
    elif nx == 381:
        dx = 16000.0
    elif nx == 1521:
        dx = 4000.0
    elif nx == 3041:
        dx = 2000.0
    else:
        sys.exit("Unable to determine dx")

f2 = netCDF4.Dataset(args.topg, 'r')
topg = f2.variables['topg']
nt = len(f1.dimensions['time'])

vaf = np.zeros((nt,))
for t in range(nt):
    haf = lithk[t,:,:] + np.minimum(topg[t,:,:], 0.0) * rhoo / rhoi
    vaf[t] = haf.sum() * dx**2
slc = vaf / Aocn * rhoi / rhoo
slc = slc - slc[0]

fileout = netCDF4.Dataset(args.out ,"w")
fileout.createDimension('time')
fileout.dimensions['time'] = f1.dimensions['time']

vafout = fileout.createVariable('vaf', 'd', ('time',))
slcout = fileout.createVariable('slc', 'd', ('time',))

vafout[:] = vaf
slcout[:] = slc

fileout.close()
f1.close()
f2.close()

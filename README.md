# Modelica GEBS Workshop

Workshop on modelling a house with a heat pump for distribution grid congestion
management. Control the heat pump with a simple forcing signal and
watch the trade-off between grid load and comfort. 

## Workshop Part 1

For the first part of the workshop we'll need to compete the first time setup:
1) Download OpenModelica and
the Buildings Library. Download OpenModelica here: https://openmodelica.org
2) Once setup, launch "OpenNodelica Connection Editor", and  download the Buildings library inside it. To do so, navigate to File 
-> Manage Libraries -> Install Library. Browse at Name to `Buildings` and press OK. 
3) Finally, download the `Workshop_Modelica.mo` package from this github repository. Press the file and press the `Download raw file` file button (top right).  Remember the file location, we'll need to navigate to it to open it.

After the setup you can now open the `Workshop_Modelica.mo` package by pressing `File` -> `Open Model/Library File(s)`. 


## Workshop Part 2

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/Markus2xj/WorkshopModelica/HEAD?labpath=workshop.ipynb)

Click the badge, wait for the environment to build, and `workshop.ipynb` opens.
Edit the `forcing_signal` function, run the cells, and see the result.
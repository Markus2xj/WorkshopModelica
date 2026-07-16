# Modelica GEBS Workshop

Hands-on co-simulation of a house heat pump for distribution-grid congestion
management. Participants control the heat pump with a simple forcing signal and
watch the trade-off between grid load and comfort.

## Workshop Part 1

For the first part of the workshop we'll need to download OpenModelica and
the Buildings Library. Download Openmodelica at the link. Once setup, download the Buildings library inside Modelica at File 
-> Manage Libraries -> Install Library. Browse at Name to "Buildings" and press OK. 

- **OpenModelica** (OMEdit) — https://openmodelica.org
- **Modelica Buildings Library 11.0.0**

Open `Workshop_Modelica.mo`, edit, then re-export `Standalone_House_cosim`
following the two rules above and drop the new `.fmu` into this repo.


## Workshop Part 2

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/Markus2xj/WorkshopModelica/HEAD?labpath=workshop.ipynb)

Click the badge, wait for the environment to build, and `workshop.ipynb` opens.
Edit the `forcing_signal` function, run the cells, and see the result. 

> Replace `<your-username>/<your-repo>` in the badge URL above once you push
> this folder to a public GitHub repository.

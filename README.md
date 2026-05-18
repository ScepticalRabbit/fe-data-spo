# Thermal Finite Element Models: Sensor Placement Opt
Thermal finite element models for testing sensor placement optimisation algorithms.

## Model description


## Output data
In the data directory there are two output files per model


## Loading and interrogating the data in python
The easiest way to load the exodus files into python is to use the tools in the `pyvale` package and the `mooseherder` submodule.


## Running the models
The scripts for creating the meshes are gmsh .geo scripts which you can find in the data directory. You can run these using tools in the `pyvale` python package which will call a Gmsh and MOOSE executable on your system.

To run the gmsh scripts you will need to download gmsh from here:

I also recommend downloading paraview from here to view the output exodus files.

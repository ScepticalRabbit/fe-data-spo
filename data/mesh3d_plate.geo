//==============================================================================
// Gmsh 3D plate imaging test case
// author: Lloyd Fletcher (scepticalrabbit)
//==============================================================================
// Always set to OpenCASCADE - circles and boolean opts are much easier!
SetFactory("OpenCASCADE");

// Allows gmsh to print to terminal in vscode - easier debugging
General.Terminal = 1;

// View options - not required when
Geometry.PointLabels = 1;
Geometry.CurveLabels = 1;
Geometry.SurfaceLabels = 1;
Geometry.VolumeLabels = 0;

//-------------------------------------------------------------------------
//_* MOOSEHERDER VARIABLES - START
file_name = "mesh3d_plate.msh";

// Geometric variables
plate_width = 50e-3;
plate_height = 80e-3;
plate_thick = 2e-3;

plate_thick_layers = 2;

// Must be an integer
elem_order = 2;
mesh_ref = 1;
mesh_size = 2e-3/mesh_ref;
num_threads = 4;
//** MOOSEHERDER VARIABLES - END
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Calculated / Fixed Variables
tol = mesh_size/4; // Used for bounding box selection tolerance

//------------------------------------------------------------------------------
// Geometry Definition
s1 = news;
Rectangle(s1) =
    {-plate_width/2,0.0,0.0,
      plate_width,plate_height};

//------------------------------------------------------------------------------
// Mesh Sizing
MeshSize{ PointsOf{ Surface{:}; } } = mesh_size;
// Use transfinite for a perfect mapped mesh
Transfinite Surface{Surface{:}};
Recombine Surface{Surface{:}};

Extrude{0.0,0.0,plate_thick}{
    Surface{:}; Layers{plate_thick_layers}; Recombine;
}

//------------------------------------------------------------------------------
// Physical Volumes and Surfaces
Physical Volume("plate-vol") = {Volume{:}};

// Standard coordinate based selections for consistency
ps1() = Surface In BoundingBox{
    -plate_width/2-tol,plate_height-tol,0.0-tol,
    plate_width/2+tol,plate_height+tol,plate_thick+tol};
Physical Surface("bc-top-disp") = {ps1()};

ps2() = Surface In BoundingBox{
    -plate_width/2-tol,0.0-tol,0.0-tol,
    plate_width/2+tol,0.0+tol,plate_thick+tol};
Physical Surface("bc-base-disp") = {ps2()};

ps3() = Surface In BoundingBox{
    -plate_width/2-tol,0.0-tol,plate_thick-tol/4,
    plate_width/2+tol,plate_height+tol,plate_thick+tol/4};
Physical Surface("plate-surf-vis-front") = {ps3()};

ps4() = Surface In BoundingBox{
    -plate_width/2-tol,0.0-tol,0.0-tol/4,
    plate_width/2+tol,plate_height+tol,0.0+tol/4};
Physical Surface("plate-surf-vis-back") = {ps4()};

//------------------------------------------------------------------------------
// Global meshing
Mesh.Algorithm = 6;
Mesh.Algorithm3D = 10;

General.NumThreads = num_threads;
Mesh.MaxNumThreads1D = num_threads;
Mesh.MaxNumThreads2D = num_threads;
Mesh.MaxNumThreads3D = num_threads;

Mesh.ElementOrder = elem_order;
Mesh.SecondOrderIncomplete = 1;
Mesh 3;

//------------------------------------------------------------------------------
// Save and exit
Save Str(file_name);
//Exit;

//==============================================================================
// Gmsh 2D parametric plate mesh with two circular edge notches
// author: Lloyd Fletcher (scepticalrabbit)
//==============================================================================

// Always set to OpenCASCADE - circles and boolean opts are much easier!
SetFactory("OpenCASCADE");

// Allows gmsh to print to terminal in vscode - easier debugging
General.Terminal = 0;

// View options
Geometry.PointLabels = 0;
Geometry.CurveLabels = 0;
Geometry.SurfaceLabels = 0;
Geometry.VolumeLabels = 0;

//------------------------------------------------------------------------------
// Variables

//_* MOOSEHERDER VARIABLES - START
file_name = "mesh2d_notchplate.msh";

// Geometric variables
plate_width = 50.0e-3;
plate_height = 80.0e-3; // Must be greater than plate width

plate_diff = plate_height-plate_width;

// Notch variables
// Initial placement:
// - both notch centres are on the right edge of the plate
// - one notch is +5 mm above the horizontal centreline
// - one notch is -5 mm below the horizontal centreline
notch_1_rad = plate_width/4;
notch_1_loc_x = 0.0;
notch_1_loc_y = plate_height/2 + 5.0e-3;

notch_2_rad = plate_width/4;
notch_2_loc_x = plate_width;
notch_2_loc_y = plate_height/2 - 5.0e-3;

notch_1_circ = 2*Pi*notch_1_rad;
notch_2_circ = 2*Pi*notch_2_rad;

// Mesh variables
MR = 2;

plate_thick_layers = MR;

// These are retained in the same style as the original script.
// Since the notches are boolean-cut features, the mesh is controlled globally
// and through characteristic lengths rather than the original centre-hole
// spider-web transfinite layout.
notch_1_sect_nodes = 2*Floor((5*MR - 1)/2)+1; // Must be odd
notch_2_sect_nodes = 2*Floor((5*MR - 1)/2)+1; // Must be odd

plate_edge_nodes = Floor((notch_1_sect_nodes-1)/2)+1;
plate_diff_nodes = 2*Floor((4*MR - 1)/2);

elem_size_1 = notch_1_circ/(4*(notch_1_sect_nodes-1));
elem_size_2 = notch_2_circ/(4*(notch_2_sect_nodes-1));

elem_size = Min(elem_size_1,elem_size_2);

tol = elem_size; // Used for bounding box selection tolerance

second_ord_incomp = 1;
//** MOOSEHERDER VARIABLES - START

//------------------------------------------------------------------------------
// Geometry Definition

// Split plate into eight pieces following the original convention. This keeps
// the plate partitioned through the width and around the middle region, but the
// centre hole is replaced by edge notches.

s1 = news;
Rectangle(s1) = {0.0,0.0,0.0,
                plate_width/2,plate_diff/2};

s2 = news;
Rectangle(s2) = {plate_width/2,0.0,0.0,
                plate_width/2,plate_diff/2};

s3 = news;
Rectangle(s3) = {0.0,plate_diff/2,0.0,
                plate_width/2,plate_width/2};

s4 = news;
Rectangle(s4) = {plate_width/2,plate_diff/2,0.0,
                plate_width/2,plate_width/2};

s5 = news;
Rectangle(s5) = {0.0,plate_width/2+plate_diff/2,0.0,
                plate_width/2,plate_width/2};

s6 = news;
Rectangle(s6) = {plate_width/2,plate_width/2+plate_diff/2,0.0,
                plate_width/2,plate_width/2};

s7 = news;
Rectangle(s7) = {0.0,plate_height-plate_diff/2,0.0,
                plate_width/2,plate_diff/2};

s8 = news;
Rectangle(s8) = {plate_width/2,plate_height-plate_diff/2,0.0,
                plate_width/2,plate_diff/2};

// Merge coincident edges of the overlapping rectangles
BooleanFragments{ Surface{s1}; Delete; }
                { Surface{s2,s3,s4,s5,s6,s7,s8}; Delete; }

// Create notch cutting surfaces
c1 = newc;
Circle(c1) = {notch_1_loc_x,notch_1_loc_y,0.0,notch_1_rad};

cl1 = newcl;
Curve Loop(cl1) = {c1};

sn1 = news;
Plane Surface(sn1) = {cl1};


c2 = newc;
Circle(c2) = {notch_2_loc_x,notch_2_loc_y,0.0,notch_2_rad};

cl2 = newcl;
Curve Loop(cl2) = {c2};

sn2 = news;
Plane Surface(sn2) = {cl2};

// Cut the two circular edge notches out of the full plate.
// Surface{:} is used here because the BooleanFragments step may renumber or
// replace the original surface tags.
BooleanDifference{ Surface{:}; Delete; }
                 { Surface{sn1,sn2}; Delete; }

//------------------------------------------------------------------------------
// Mesh sizing

// Global characteristic length
Mesh.CharacteristicLengthMin = elem_size;
Mesh.CharacteristicLengthMax = elem_size;

// Refine curves around the notches using bounding boxes around each notch.
// This avoids relying on brittle curve IDs after OpenCASCADE booleans.
nc1() = Curve In BoundingBox{
    notch_1_loc_x-notch_1_rad-tol,notch_1_loc_y-notch_1_rad-tol,0.0-tol,
    notch_1_loc_x+notch_1_rad+tol,notch_1_loc_y+notch_1_rad+tol,0.0+tol};

nc2() = Curve In BoundingBox{
    notch_2_loc_x-notch_2_rad-tol,notch_2_loc_y-notch_2_rad-tol,0.0-tol,
    notch_2_loc_x+notch_2_rad+tol,notch_2_loc_y+notch_2_rad+tol,0.0+tol};

Transfinite Curve{nc1()} = notch_1_sect_nodes;
Transfinite Curve{nc2()} = notch_2_sect_nodes;

// Recombine where possible to favour quads
// Recombine Surface{:};

//------------------------------------------------------------------------------
// Physical lines and surfaces for export/BCs

Physical Surface("plate") = {Surface{:}};

pc1() = Curve In BoundingBox{
    0.0-tol,0.0-tol,0.0-tol,
    plate_width+tol,0.0+tol,0.0+tol};

Physical Curve("bc-bot") = {pc1()};


pc2() = Curve In BoundingBox{
    0.0-tol,plate_height-tol,0.0-tol,
    plate_width+tol,plate_height+tol,0.0+tol};

Physical Curve("bc-top") = {pc2()};

//------------------------------------------------------------------------------
// Global meshing

Mesh.ElementOrder = 2;
Mesh.SecondOrderIncomplete = second_ord_incomp;

Mesh 2;

//------------------------------------------------------------------------------
// Save and exit

Save Str(file_name);
//Exit;

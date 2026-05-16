#-------------------------------------------------------------------------
# 3Dstc,1mat,thermal,steady
#-------------------------------------------------------------------------

#-------------------------------------------------------------------------
#_* MOOSEHERDER VARIABLES - START

# NOTE: only used for transient solves
endTime = 1
# timeStep = 1

# Thermal Loads/BCs
plate_width = 60e-3
plate_thick = 1e-3
plate_area = ${fparse plate_width*plate_thick}
heat_flux = ${fparse 10.0 / plate_area}

toK = 273.15
#ambTemp = ${fparse 20.0 + toK}           # degK
coolantTemp = ${fparse 100.0 + toK}      # degK

# Mesh file string
mesh_file = 'mesh2d_plate.msh'
elem_order = 'SECOND'

ssDensity = 7899    # kg/m^3
ssSpecHeat = 501.0  # W/m.K 
ssThermCond = 15.48 # J/kg.K

#** MOOSEHERDER VARIABLES - END
#-------------------------------------------------------------------------

[Mesh]
    type = FileMesh
    file = ${mesh_file}
[]


[Variables]
    [temperature]
        family = LAGRANGE
        order = ${elem_order}
        initial_condition = ${coolantTemp}
    []
[]

[Functions]
    [surf_hs_spat_fun]
        type = ParsedFunction
        expression = '${heat_flux}*(x-${plate_width})*(x+${plate_width}) / -(${plate_width})^2'
    []
[]

[Kernels]
    [heat_conduction]
        type = ADHeatConduction
        variable = temperature
    []
    # [time_derivative]
    #     type = ADHeatConductionTimeDerivative
    #     variable = temperature
    # []
[]

[Materials]
    [ss316l_thermal]
        type = ADHeatConductionMaterial
        thermal_conductivity = ${ssThermCond}
        specific_heat = ${ssSpecHeat}
    []
    [ss316l_density]
        type = ADGenericConstantMaterial
        prop_names = 'density'
        prop_values = ${ssDensity}
    []
    # HTC from sieder-tate
    [coolant_heat_transfer_coefficient]
        type = ADPiecewiseLinearInterpolationMaterial
        xy_data = '
            274 23.6e3
            323 31.9e3
            373 38.8e3
            423 44.4e3
            473 48.9e3
            523 52.4e3
            573 67.6e3
        '
        variable = temperature
        property = heat_transfer_coefficient
        boundary = 'bc-bot'
    []
[]

[BCs]
    [heat_flux_out]
        type = ADConvectiveHeatFluxBC
        variable = temperature
        boundary = 'bc-bot'
        T_infinity = ${coolantTemp}
        heat_transfer_coefficient = heat_transfer_coefficient
    []
    [heat_flux_in]
        type = ADFunctionNeumannBC
        variable = temperature
        boundary = 'bc-top'
        function = surf_hs_spat_fun
    []
    # [radiation_flux]
    #     type = ADFunctionRadiativeBC
    #     variable = temperature
    #     boundary = 'bc-top-heatflux bc-base-surf bc-left-surf bc-right-surf bc-front-surf bc-back-surf'
    #     emissivity_function = '0.5'
    #     Tinfinity = ${ambTemp}
    #     stefan_boltzmann_constant = 5.67e-8
    #     use_displaced_mesh = true
    # []
[]

[Executioner]
    type = Steady # Transient
    solve_type = 'NEWTON'
    petsc_options = '-snes_converged_reason'
    petsc_options_iname = '-pc_type -pc_hypre_type'
    petsc_options_value = ' hypre    boomeramg'

    l_max_its = 100
    l_tol = 1e-6

    nl_max_its = 50
    nl_rel_tol = 1e-6
    nl_abs_tol = 1e-6

    # end_time= ${endTime}
    # dt = ${timeStep}

    [Predictor]
        type = SimplePredictor
        scale = 1
    []
[]

[Postprocessors]
    [temp_max]
        type = NodalExtremeValue
        variable = temperature
    []
    [temp_max_node_id]
        type = NodalMaxValueId
        variable = temperature
    []
    [temp_avg]
        type = AverageNodalVariableValue
        variable = temperature
    []
[]

[Outputs]
    exodus = true
    csv = true
    file_base = 'therm2d_funchf_${endTime}f' 
[]

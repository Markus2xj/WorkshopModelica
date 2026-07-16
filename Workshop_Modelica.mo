package Workshop_Modelica
  model House
    import Modelica.Math.Random.Generators.Xorshift64star;
    parameter Integer localSeed = 1;
    parameter Integer globalSeed = 30020;
    final parameter Real PV_area = Utility.sampleUniform(localSeed, globalSeed, 10, 20);
    parameter Real Tint_init = Utility.sampleUniform(localSeed + 100, globalSeed, 273.15 + 10, 273.15 + 25);
    final parameter Real Text_init = Utility.sampleUniform(localSeed + 200, globalSeed, 273.15 + 5, 273.15 + 15);
    final parameter Real Rint = Utility.sampleUniform(localSeed + 300, globalSeed, 0.0015, 0.002);
    final parameter Real Rext = Utility.sampleUniform(localSeed + 400, globalSeed, 0.003, 0.005);
    final parameter Real Rinf = Utility.sampleUniform(localSeed + 500, globalSeed, 0.01, 0.015);
    final parameter Real Cint = Utility.sampleUniform(localSeed + 600, globalSeed, 28688720, 28688720);
    final parameter Real Cext = Utility.sampleUniform(localSeed + 700, globalSeed, 95000000, 105000000);
    final parameter Real Awindow = Utility.sampleUniform(localSeed + 800, globalSeed, 10, 20);
    Buildings.Electrical.AC.OnePhase.Interfaces.Terminal_p PCC annotation(
      Placement(transformation(origin = {-4, -100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {0, -100}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Electrical.AC.OnePhase.Sources.PVSimple Solar_PV(A = PV_area, V_nominal = 230) annotation(
      Placement(transformation(origin = {90, -50}, extent = {{-10, -10}, {10, 10}})));
    Buildings.BoundaryConditions.WeatherData.Bus weaBus annotation(
      Placement(transformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}})));
    Assets.Building_Envelope building_Envelope(Tint_init_v = Tint_init, Text_init_v = Text_init, Rint_v = Rint, Rext_v = Rext, Rinf_v = Rinf, Cin_v = Cint, Cext_v = Cext) annotation(
      Placement(transformation(origin = {-50, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    Assets.SolarGains solarGains(Aw = Awindow) annotation(
      Placement(transformation(origin = {-30, 40}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Assets.Heatpump.heat_pump_plant heatpump(Pcompressor = 1500) annotation(
      Placement(transformation(origin = {-10, 10}, extent = {{-10, -10}, {10, 10}})));
    Assets.Comfort_model comfort_model annotation(
      Placement(transformation(origin = {-30, -18}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Thermal.HeatTransfer.Sources.PrescribedTemperature Tamb annotation(
      Placement(transformation(origin = {-90, 10}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(Solar_PV.terminal, PCC) annotation(
      Line(points = {{80, -50}, {0, -50}, {0, -101}, {-4, -101}, {-4, -100}}, color = {0, 120, 120}));
    connect(Solar_PV.terminal, PCC) annotation(
      Line(points = {{60, -50}, {-4, -50}, {-4, -100}}, color = {255, 255, 255}));
    connect(weaBus.HGloHor, Solar_PV.G) annotation(
      Line(points = {{0, 100}, {90, 100}, {90, -38}, {90, -38}}, color = {0, 0, 127}));
    connect(solarGains.port_a, building_Envelope.ThermalZone) annotation(
      Line(points = {{-30, 30}, {-30, 10}, {-40, 10}}, color = {191, 0, 0}));
    connect(solarGains.weaBus, weaBus) annotation(
      Line(points = {{-30, 50}, {-30, 100}, {0, 100}}, color = {255, 204, 51}, thickness = 0.5));
    connect(building_Envelope.ThermalZone, heatpump.ThermalOut) annotation(
      Line(points = {{-40, 10}, {-20, 10}}, color = {191, 0, 0}));
    connect(heatpump.weaBus, weaBus) annotation(
      Line(points = {{-10, 20}, {-10, 100}, {0, 100}}, color = {255, 204, 51}, thickness = 0.5));
    connect(heatpump.term_p, PCC) annotation(
      Line(points = {{-10, 0}, {-10.5, 0}, {-10.5, -50}, {0, -50}, {0, -99}, {-2, -99}, {-2, -100.5}, {-4, -100.5}, {-4, -100}}, color = {0, 120, 120}));
    connect(building_Envelope.ThermalZone, comfort_model.ThermalZone) annotation(
      Line(points = {{-40, 10}, {-30, 10}, {-30, -8}}, color = {191, 0, 0}));
    connect(Tamb.port, building_Envelope.Ambient) annotation(
      Line(points = {{-80, 10}, {-60, 10}}, color = {191, 0, 0}));
    connect(weaBus.TDryBul, Tamb.T) annotation(
      Line(points = {{0, 100}, {-110, 100}, {-110, 10}, {-102, 10}}, color = {0, 0, 127}));
  end House;

  model Distribution_Grid
    parameter Real Pnom_cable = 6600;
    parameter Real Vnom = 230;
    parameter Real pf = 0.9;
    parameter Real I_ampacity = Pnom_cable/(Vnom*pf);
    Buildings.Electrical.AC.OnePhase.Sources.Grid Upper_Grid(f = 50, V = Vnom) annotation(
      Placement(transformation(origin = {-70, 70}, extent = {{-10, -10}, {10, 10}})));
    Buildings.BoundaryConditions.WeatherData.ReaderTMY3 weaDat(filNam = Modelica.Utilities.Files.loadResource("modelica://Workshop_Modelica/ITA_Napoli-Capodichino.162890_IGDG.mos")) annotation(
      Placement(transformation(origin = {-110, 90}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Electrical.AC.OnePhase.Lines.Line line_1(l = 100, P_nominal = Pnom_cable, V_nominal = Vnom, mode = Buildings.Electrical.Types.CableMode.commercial, redeclare Buildings.Electrical.Transmission.LowVoltageCables.PvcAl16 commercialCable, use_T = false) annotation(
      Placement(transformation(origin = {-50, 30}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Electrical.AC.OnePhase.Lines.Line line_2(l = 200, P_nominal = Pnom_cable, V_nominal = 230) annotation(
      Placement(transformation(origin = {10, 30}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Electrical.AC.OnePhase.Lines.Line line_3(P_nominal = Pnom_cable, V_nominal = Vnom, l = 500) annotation(
      Placement(transformation(origin = {70, 30}, extent = {{-11, -11}, {11, 11}})));
    Buildings.Electrical.AC.OnePhase.Lines.Line line_4(P_nominal = Pnom_cable, V_nominal = Vnom, l = 500) annotation(
      Placement(transformation(origin = {90, 0}, extent = {{-11, -11}, {11, 11}})));
    Buildings.Electrical.AC.OnePhase.Lines.Line line_5(P_nominal = Pnom_cable, V_nominal = Vnom, l = 500) annotation(
      Placement(transformation(origin = {31, 0}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Electrical.AC.OnePhase.Lines.Line line_6(P_nominal = Pnom_cable, V_nominal = Vnom, l = 50) annotation(
      Placement(transformation(origin = {-29, 0}, extent = {{-10, -10}, {10, 10}})));
    House house(localSeed = 1) annotation(
      Placement(transformation(origin = {-20, 50}, extent = {{-10, -10}, {10, 10}})));
    House house1(localSeed = 2) annotation(
      Placement(transformation(origin = {40, 50}, extent = {{-10, -10}, {10, 10}})));
    House house2(localSeed = 3) annotation(
      Placement(transformation(origin = {100, 50}, extent = {{-10, -10}, {10, 10}})));
    House house3(localSeed = 4) annotation(
      Placement(transformation(origin = {60, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    House house4(localSeed = 5) annotation(
      Placement(transformation(origin = {0, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    House house5(localSeed = 6) annotation(
      Placement(transformation(origin = {-60, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    Buildings.Electrical.AC.OnePhase.Sensors.GeneralizedSensor Sensor annotation(
      Placement(transformation(origin = {-70, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Modelica.Blocks.Continuous.Integrator cumulativeP_overloaded(k = 1/3600000) annotation(
      Placement(transformation(origin = {50, 120}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Math.Add diff_P(k1 = -1, k2 = -1) annotation(
      Placement(transformation(origin = {-22, 110}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Sources.Constant Pnom(k = Pnom_cable) annotation(
      Placement(transformation(origin = {-70, 116}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Math.Max max annotation(
      Placement(transformation(origin = {10, 120}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Sources.Constant zero(k = 0) annotation(
      Placement(transformation(origin = {-70, 146}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(weaDat.weaBus, house.weaBus) annotation(
      Line(points = {{-100, 90}, {-21, 90}, {-21, 60}, {-20, 60}}, color = {255, 204, 51}, thickness = 0.5));
    connect(house.PCC, line_1.terminal_p) annotation(
      Line(points = {{-20, 40}, {-20, 30}, {-40, 30}}, color = {0, 120, 120}));
    connect(weaDat.weaBus, house1.weaBus) annotation(
      Line(points = {{-100, 90}, {39, 90}, {39, 60}, {40, 60}}, color = {255, 204, 51}, thickness = 0.5));
    connect(line_1.terminal_p, line_2.terminal_n) annotation(
      Line(points = {{-40, 30}, {0, 30}}, color = {0, 120, 120}));
    connect(line_2.terminal_p, house1.PCC) annotation(
      Line(points = {{20, 30}, {40, 30}, {40, 40}}, color = {0, 120, 120}));
    connect(line_3.terminal_n, line_2.terminal_p) annotation(
      Line(points = {{59, 30}, {20, 30}}, color = {0, 120, 120}));
    connect(line_3.terminal_p, line_4.terminal_p) annotation(
      Line(points = {{81, 30}, {100, 30}, {100, 0}, {101, 0}}, color = {0, 120, 120}));
    connect(line_6.terminal_p, line_5.terminal_n) annotation(
      Line(points = {{-19, 0}, {21, 0}}, color = {0, 120, 120}));
    connect(line_5.terminal_p, line_4.terminal_n) annotation(
      Line(points = {{41, 0}, {79, 0}}, color = {0, 120, 120}));
    connect(house2.PCC, line_3.terminal_p) annotation(
      Line(points = {{100, 40}, {100, 30}, {82, 30}}, color = {0, 120, 120}));
    connect(weaDat.weaBus, house2.weaBus) annotation(
      Line(points = {{-100, 90}, {98, 90}, {98, 60}, {100, 60}}, color = {255, 204, 51}, thickness = 0.5));
    connect(house3.PCC, line_4.terminal_n) annotation(
      Line(points = {{60, -20}, {59, 0}, {79, 0}}, color = {0, 120, 120}));
    connect(house4.PCC, line_5.terminal_n) annotation(
      Line(points = {{0, -20}, {0, 0}, {22, 0}}, color = {0, 120, 120}));
    connect(house5.PCC, line_6.terminal_n) annotation(
      Line(points = {{-60, -20}, {-60, 0}, {-38, 0}}, color = {0, 120, 120}));
    connect(weaDat.weaBus, house5.weaBus) annotation(
      Line(points = {{-100, 90}, {-90, 90}, {-90, -52}, {-60, -52}, {-60, -40}}, color = {255, 204, 51}, thickness = 0.5));
    connect(weaDat.weaBus, house4.weaBus) annotation(
      Line(points = {{-100, 90}, {-90, 90}, {-90, -52}, {0, -52}, {0, -40}}, color = {255, 204, 51}, thickness = 0.5));
    connect(house3.weaBus, weaDat.weaBus) annotation(
      Line(points = {{60, -40}, {60, -52}, {-90, -52}, {-90, 90}, {-100, 90}}, color = {255, 204, 51}, thickness = 0.5));
    connect(Sensor.terminal_n, line_1.terminal_n) annotation(
      Line(points = {{-70, 30}, {-60, 30}}, color = {0, 120, 120}));
    connect(Sensor.terminal_p, Upper_Grid.terminal) annotation(
      Line(points = {{-70, 50}, {-70, 60}}, color = {0, 120, 120}));
    connect(Sensor.S[1], diff_P.u2) annotation(
      Line(points = {{-60, 34}, {-48, 34}, {-48, 104}, {-34, 104}}, color = {0, 0, 127}));
    connect(Pnom.y, diff_P.u1) annotation(
      Line(points = {{-59, 116}, {-34, 116}}, color = {0, 0, 127}));
    connect(zero.y, max.u1) annotation(
      Line(points = {{-59, 146}, {-19.5, 146}, {-19.5, 126}, {-2, 126}}, color = {0, 0, 127}));
    connect(diff_P.y, max.u2) annotation(
      Line(points = {{-10, 110}, {-8, 110}, {-8, 114}, {-2, 114}}, color = {0, 0, 127}));
    connect(max.y, cumulativeP_overloaded.u) annotation(
      Line(points = {{22, 120}, {38, 120}}, color = {0, 0, 127}));
    annotation(
      experiment(StopTime = 2678400, Interval = 900, Tolerance = 1e-06));
  end Distribution_Grid;

  package Assets
    model Building_Envelope
      parameter Real Rint_v = 0.00176;
      parameter Real Rinf_v = 0.01243;
      parameter Real Rext_v = 0.00422;
      parameter Real Cin_v = 28688720;
      parameter Real Cext_v = 101714553;
      parameter Real Tint_init_v = 273.15 + 20;
      parameter Real Text_init_v = 273.15 + 15;
      Modelica.Thermal.HeatTransfer.Components.ThermalResistor Rext(R = Rext_v) annotation(
        Placement(transformation(origin = {28, 0}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Thermal.HeatTransfer.Components.ThermalResistor Rint(R = Rint_v) annotation(
        Placement(transformation(origin = {-30, 0}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Thermal.HeatTransfer.Components.ThermalResistor Rinfiltration(R = Rinf_v) annotation(
        Placement(transformation(origin = {0, 30}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Thermal.HeatTransfer.Components.HeatCapacitor Cinternal(C = Cin_v, T(start = Tint_init_v)) annotation(
        Placement(transformation(origin = {-60, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
      Modelica.Thermal.HeatTransfer.Components.HeatCapacitor Cenvelope(C = Cext_v, T(start = Text_init_v)) annotation(
        Placement(transformation(origin = {0, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a ThermalZone annotation(
        Placement(transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b Ambient annotation(
        Placement(transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(Rint.port_b, Cenvelope.port) annotation(
        Line(points = {{-20, 0}, {0, 0}}, color = {191, 0, 0}));
      connect(Cenvelope.port, Rext.port_a) annotation(
        Line(points = {{0, 0}, {18, 0}}, color = {191, 0, 0}));
      connect(Cinternal.port, Rint.port_a) annotation(
        Line(points = {{-60, 0}, {-40, 0}}, color = {191, 0, 0}));
      connect(Cinternal.port, Rinfiltration.port_a) annotation(
        Line(points = {{-60, 0}, {-60, 30}, {-10, 30}}, color = {191, 0, 0}));
      connect(Rinfiltration.port_b, Rext.port_b) annotation(
        Line(points = {{10, 30}, {38, 30}, {38, 0}}, color = {191, 0, 0}));
      connect(ThermalZone, Cinternal.port) annotation(
        Line(points = {{-100, 0}, {-60, 0}}, color = {191, 0, 0}));
      connect(Rext.port_b, Ambient) annotation(
        Line(points = {{38, 0}, {100, 0}}, color = {191, 0, 0}));
    end Building_Envelope;

    model SolarGains "Simplified 4-orientation solar gain model for RC building-envelope models."
      parameter Real Aw(unit = "m2", min = 0) = 15 "Total window area; distributed equally across N, E, S, W facades";
      constant Real g = 0.75 "Solar heat gain coefficient (SHGC) of the glazing";
      final parameter Real Aw_4(unit = "m2") = Aw/4 "Per-orientation effective window area";
      Buildings.BoundaryConditions.WeatherData.Bus weaBus annotation(
        Placement(transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a annotation(
        Placement(transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}})));
      Buildings.BoundaryConditions.SolarIrradiation.DirectTiltedSurface HDirS(til = Modelica.Constants.pi/2, azi = 0) annotation(
        Placement(transformation(origin = {-60, 60}, extent = {{-10, -10}, {10, 10}})));
      Buildings.BoundaryConditions.SolarIrradiation.DirectTiltedSurface HDirW(til = Modelica.Constants.pi/2, azi = Modelica.Constants.pi/2) annotation(
        Placement(transformation(origin = {-60, 20}, extent = {{-10, -10}, {10, 10}})));
      Buildings.BoundaryConditions.SolarIrradiation.DirectTiltedSurface HDirN(til = Modelica.Constants.pi/2, azi = Modelica.Constants.pi) annotation(
        Placement(transformation(origin = {-60, -20}, extent = {{-10, -10}, {10, 10}})));
      Buildings.BoundaryConditions.SolarIrradiation.DirectTiltedSurface HDirE(til = Modelica.Constants.pi/2, azi = -Modelica.Constants.pi/2) annotation(
        Placement(transformation(origin = {-60, -60}, extent = {{-10, -10}, {10, 10}})));
      Buildings.BoundaryConditions.SolarIrradiation.DiffusePerez HDifS(til = Modelica.Constants.pi/2, azi = 0) annotation(
        Placement(transformation(origin = {-20, 60}, extent = {{-10, -10}, {10, 10}})));
      Buildings.BoundaryConditions.SolarIrradiation.DiffusePerez HDifW(til = Modelica.Constants.pi/2, azi = Modelica.Constants.pi/2) annotation(
        Placement(transformation(origin = {-20, 20}, extent = {{-10, -10}, {10, 10}})));
      Buildings.BoundaryConditions.SolarIrradiation.DiffusePerez HDifN(til = Modelica.Constants.pi/2, azi = Modelica.Constants.pi) annotation(
        Placement(transformation(origin = {-20, -20}, extent = {{-10, -10}, {10, 10}})));
      Buildings.BoundaryConditions.SolarIrradiation.DiffusePerez HDifE(til = Modelica.Constants.pi/2, azi = -Modelica.Constants.pi/2) annotation(
        Placement(transformation(origin = {-20, -60}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow solarGain annotation(
        Placement(transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(weaBus, HDirS.weaBus) annotation(
        Line(points = {{-100, 0}, {-80, 0}, {-80, 60}, {-70, 60}}, color = {255, 204, 51}, thickness = 0.5));
      connect(weaBus, HDirW.weaBus) annotation(
        Line(points = {{-100, 0}, {-80, 0}, {-80, 20}, {-70, 20}}, color = {255, 204, 51}, thickness = 0.5));
      connect(weaBus, HDirN.weaBus) annotation(
        Line(points = {{-100, 0}, {-80, 0}, {-80, -20}, {-70, -20}}, color = {255, 204, 51}, thickness = 0.5));
      connect(weaBus, HDirE.weaBus) annotation(
        Line(points = {{-100, 0}, {-80, 0}, {-80, -60}, {-70, -60}}, color = {255, 204, 51}, thickness = 0.5));
      connect(weaBus, HDifS.weaBus) annotation(
        Line(points = {{-100, 0}, {-80, 0}, {-80, 60}, {-30, 60}}, color = {255, 204, 51}, thickness = 0.5));
      connect(weaBus, HDifW.weaBus) annotation(
        Line(points = {{-100, 0}, {-80, 0}, {-80, 20}, {-30, 20}}, color = {255, 204, 51}, thickness = 0.5));
      connect(weaBus, HDifN.weaBus) annotation(
        Line(points = {{-100, 0}, {-80, 0}, {-80, -20}, {-30, -20}}, color = {255, 204, 51}, thickness = 0.5));
      connect(weaBus, HDifE.weaBus) annotation(
        Line(points = {{-100, 0}, {-80, 0}, {-80, -60}, {-30, -60}}, color = {255, 204, 51}, thickness = 0.5));
      solarGain.Q_flow = g*Aw_4*((HDirS.H + HDifS.H) + (HDirW.H + HDifW.H) + (HDirN.H + HDifN.H) + (HDirE.H + HDifE.H));
      connect(solarGain.port, port_a) annotation(
        Line(points = {{70, 0}, {100, 0}}, color = {191, 0, 0}));
      annotation(
        Documentation(info = "Simplified 4-orientation solar gain model. Computes total transmitted solar heat as Q = g * (Aw/4) * sum(I_direct + I_diffuse) over S, W, N, E vertical facades. Connect weaBus to the weather source and port_a to the indoor air thermal node."));
    end SolarGains;

    package Heatpump
      model Carnot_COP
        import Modelica.Blocks.Interfaces;
        parameter Real eta = 0.43 "Carnot Efficiency";
        Modelica.Blocks.Interfaces.RealInput Tsupply annotation(
          Placement(transformation(origin = {-100, -30}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-100, -60}, extent = {{-20, -20}, {20, 20}})));
        Modelica.Blocks.Interfaces.RealInput Tamb annotation(
          Placement(transformation(origin = {-100, 30}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-100, 60}, extent = {{-20, -20}, {20, 20}})));
        Modelica.Blocks.Interfaces.RealOutput COP annotation(
          Placement(transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {102, 0}, extent = {{-10, -10}, {10, 10}})));
      equation
        COP = eta*Tsupply/max(1.0, Tsupply - Tamb);
      end Carnot_COP;

      model heat_pump_plant
        parameter Real Pcompressor = 1500;
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a ThermalOut annotation(
          Placement(transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow Heatflow annotation(
          Placement(transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Carnot_COP carnot_COP annotation(
          Placement(transformation(origin = {30, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Modelica.Blocks.Math.Product ThermalOutput annotation(
          Placement(transformation(origin = {-10, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor IndoorTinK annotation(
          Placement(transformation(origin = {-80, -30}, extent = {{-10, -10}, {10, 10}})));
        Buildings.BoundaryConditions.WeatherData.Bus weaBus annotation(
          Placement(transformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {2, 100}, extent = {{-10, -10}, {10, 10}})));
        heat_pump_basic_control heatpump_control(Pcompressor = Pcompressor) annotation(
          Placement(transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Buildings.Electrical.AC.OnePhase.Loads.Inductive loa(mode = Buildings.Electrical.Types.Load.VariableZ_P_input, pf = .8) annotation(
          Placement(transformation(origin = {70, -70}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
        Buildings.Electrical.AC.OnePhase.Interfaces.Terminal_p term_p annotation(
          Placement(transformation(origin = {-4, -100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {0, -100}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Blocks.Math.Gain neg(k = -1) annotation(
          Placement(transformation(origin = {70, -44}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
        Modelica.Blocks.Sources.BooleanConstant noForceOff(k = false) annotation(
          Placement(transformation(origin = {90, 50}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
      equation
        connect(ThermalOut, Heatflow.port) annotation(
          Line(points = {{-100, 0}, {-70, 0}}, color = {191, 0, 0}));
        connect(Heatflow.Q_flow, ThermalOutput.y) annotation(
          Line(points = {{-50, 0}, {-21, 0}}, color = {0, 0, 127}));
        connect(ThermalOutput.u1, carnot_COP.COP) annotation(
          Line(points = {{2, -6}, {11, -6}, {11, -10}, {20, -10}}, color = {0, 0, 127}));
        connect(ThermalOut, IndoorTinK.port) annotation(
          Line(points = {{-100, 0}, {-100, -30}, {-90, -30}}, color = {191, 0, 0}));
        connect(IndoorTinK.T, carnot_COP.Tsupply) annotation(
          Line(points = {{-68, -30}, {60, -30}, {60, -4}, {40, -4}}, color = {0, 0, 127}));
        connect(weaBus.TDryBul, carnot_COP.Tamb) annotation(
          Line(points = {{0, 100}, {50, 100}, {50, -16}, {40, -16}}, color = {0, 0, 127}));
        connect(IndoorTinK.T, heatpump_control.Tinterior) annotation(
          Line(points = {{-68, -30}, {90, -30}, {90, -10}}, color = {0, 0, 127}));
        connect(heatpump_control.ElectricPowerConsumption, ThermalOutput.u2) annotation(
          Line(points = {{80, 6}, {2, 6}}, color = {0, 0, 127}));
        connect(loa.terminal, term_p) annotation(
          Line(points = {{70, -80}, {70, -100}, {-4, -100}}, color = {0, 120, 120}));
        connect(neg.y, loa.Pow) annotation(
          Line(points = {{70, -50}, {70, -60}}, color = {0, 0, 127}));
        connect(heatpump_control.ElectricPowerConsumption, neg.u) annotation(
          Line(points = {{80, 6}, {70, 6}, {70, -36}}, color = {0, 0, 127}));
        connect(noForceOff.y, heatpump_control.Force_off) annotation(
          Line(points = {{90, 39}, {90, 10}}, color = {255, 0, 255}));
      end heat_pump_plant;

      model heat_pump_basic_control
        parameter Real Pcompressor = 1500;
        Modelica.Blocks.Logical.Hysteresis hysteresis(uLow = 273.15 + 20, uHigh = 273.15 + 22) annotation(
          Placement(transformation(origin = {-30, 10}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Blocks.Interfaces.RealInput Tinterior annotation(
          Placement(transformation(origin = {0, 108}, extent = {{-20, -20}, {20, 20}}, rotation = -90), iconTransformation(origin = {0, 96}, extent = {{-20, -20}, {20, 20}}, rotation = -90)));
        Modelica.Blocks.Logical.Not not1 annotation(
          Placement(transformation(origin = {10, 10}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Blocks.Interfaces.BooleanOutput HeatPump_On annotation(
          Placement(transformation(origin = {106, 60}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {100, 60}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Blocks.Math.BooleanToReal PowerConsumption(realTrue = Pcompressor) annotation(
          Placement(transformation(origin = {70, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
        Modelica.Blocks.Interfaces.RealOutput ElectricPowerConsumption annotation(
          Placement(transformation(origin = {106, -58}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {100, -60}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Blocks.Logical.And and1 annotation(
          Placement(transformation(origin = {50, 10}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Blocks.Interfaces.BooleanInput Force_off annotation(
          Placement(transformation(origin = {0, -108}, extent = {{-20, -20}, {20, 20}}, rotation = 90), iconTransformation(origin = {0, -100}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
        Modelica.Blocks.Logical.Not notForce_off annotation(
          Placement(transformation(origin = {0, -60}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
      equation
        connect(hysteresis.y, not1.u) annotation(
          Line(points = {{-19, 10}, {-2, 10}}, color = {255, 0, 255}));
        connect(Tinterior, hysteresis.u) annotation(
          Line(points = {{0, 108}, {-42, 108}, {-42, 10}}, color = {0, 0, 127}));
        connect(PowerConsumption.y, ElectricPowerConsumption) annotation(
          Line(points = {{70, -41}, {70, -58}, {106, -58}}, color = {0, 0, 127}));
        connect(notForce_off.u, Force_off) annotation(
          Line(points = {{0, -72}, {0, -108}}, color = {255, 0, 255}));
        connect(not1.y, and1.u1) annotation(
          Line(points = {{22, 10}, {38, 10}}, color = {255, 0, 255}));
        connect(and1.y, PowerConsumption.u) annotation(
          Line(points = {{62, 10}, {70, 10}, {70, -18}}, color = {255, 0, 255}));
        connect(and1.y, HeatPump_On) annotation(
          Line(points = {{62, 10}, {70, 10}, {70, 60}, {106, 60}}, color = {255, 0, 255}));
        connect(notForce_off.y, and1.u2) annotation(
          Line(points = {{0, -48}, {0, -20}, {28, -20}, {28, 2}, {38, 2}}, color = {255, 0, 255}));
      end heat_pump_basic_control;
    end Heatpump;

    model Comfort_model
      parameter Real Tcomfort_val = 21;
      parameter Real comfort_range = 2;
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b ThermalZone annotation(
        Placement(transformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Thermal.HeatTransfer.Celsius.TemperatureSensor temperatureSensor annotation(
        Placement(transformation(origin = {0, 70}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
      Modelica.Blocks.Sources.Constant Tcomfort(k = Tcomfort_val) annotation(
        Placement(transformation(origin = {-30, 30}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Abs abs1 annotation(
        Placement(transformation(origin = {70, 30}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add add(k2 = -1) annotation(
        Placement(transformation(origin = {30, 30}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.GreaterEqualThreshold comfort_threshold(threshold = comfort_range) annotation(
        Placement(transformation(origin = {0, -10}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Continuous.Integrator cumulative_discomfort_time(k = 1/3600) annotation(
        Placement(transformation(origin = {90, -10}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.BooleanToReal booleanToReal annotation(
        Placement(transformation(origin = {42, -10}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput Discomfort_hours annotation(
        Placement(transformation(origin = {0, -106}, extent = {{-10, -10}, {10, 10}}, rotation = -90), iconTransformation(origin = {0, -100}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    equation
      connect(ThermalZone, temperatureSensor.port) annotation(
        Line(points = {{0, 100}, {0, 80}}, color = {191, 0, 0}));
      connect(temperatureSensor.T, add.u1) annotation(
        Line(points = {{0, 60}, {0, 36}, {18, 36}}, color = {0, 0, 127}));
      connect(Tcomfort.y, add.u2) annotation(
        Line(points = {{-18, 30}, {-12, 30}, {-12, 24}, {18, 24}}, color = {0, 0, 127}));
      connect(add.y, abs1.u) annotation(
        Line(points = {{42, 30}, {58, 30}}, color = {0, 0, 127}));
      connect(comfort_threshold.y, booleanToReal.u) annotation(
        Line(points = {{12, -10}, {30, -10}}, color = {255, 0, 255}));
      connect(booleanToReal.y, cumulative_discomfort_time.u) annotation(
        Line(points = {{54, -10}, {78, -10}}, color = {0, 0, 127}));
      connect(abs1.y, comfort_threshold.u) annotation(
        Line(points = {{82, 30}, {100, 30}, {100, 8}, {-28, 8}, {-28, -10}, {-12, -10}}, color = {0, 0, 127}));
      connect(cumulative_discomfort_time.y, Discomfort_hours) annotation(
        Line(points = {{102, -10}, {106, -10}, {106, -86}, {0, -86}, {0, -106}}, color = {0, 0, 127}));
    end Comfort_model;
  end Assets;

  package Utility
    function sampleUniform
      import Modelica.Math.Random.Generators.Xorshift64star;
      input Integer localSeed;
      input Integer globalSeed;
      input Real minVal;
      input Real maxVal;
      output Real y;
    protected
      Integer state[2];
      Real r;
      Integer stateOut[2];
    algorithm
      state := Xorshift64star.initialState(localSeed, globalSeed);
      (r, stateOut) := Xorshift64star.random(state);
      y := minVal + (maxVal - minVal)*r;
    end sampleUniform;
  end Utility;

  package Wrapper
    model Standalone_House
      final parameter Real Vnom = 230;
      parameter Real init_Tint = 293;
      helpers.house_cosim house(Tint_init = init_Tint) annotation(
        Placement(transformation(extent = {{-10, -10}, {10, 10}})));
      Buildings.BoundaryConditions.WeatherData.ReaderTMY3 weaDat(filNam = Modelica.Utilities.Files.loadResource("modelica://Workshop_Modelica/ITA_Napoli-Capodichino.162890_IGDG.mos")) annotation(
        Placement(transformation(origin = {-30, 39}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Electrical.AC.OnePhase.Sources.Grid Upper_Grid(V = Vnom, f = 50) annotation(
        Placement(transformation(origin = {-70, 30}, extent = {{-11, -11}, {11, 11}})));
  Modelica.Blocks.Interfaces.BooleanInput Force_Off annotation(
        Placement(transformation(origin = {108, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 180), iconTransformation(origin = {100, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 180)));
    equation
      connect(weaDat.weaBus, house.weaBus) annotation(
        Line(points = {{-20, 40}, {0, 40}, {0, 10}}, color = {255, 204, 51}, thickness = 0.5));
      connect(Upper_Grid.terminal, house.PCC) annotation(
        Line(points = {{-70, 20}, {-70, -20}, {0, -20}, {0, -10}}, color = {0, 120, 120}));
  connect(house.ForceOff, Force_Off) annotation(
        Line(points = {{10, 0}, {108, 0}}, color = {255, 0, 255}));
      annotation(
        experiment(StopTime = 86400, Interval = 60, Tolerance = 1e-06));
    end Standalone_House;

    package helpers
      model heatpump_cosim
        parameter Real Pcompressor = 1500;
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a ThermalOut annotation(
          Placement(transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow Heatflow annotation(
          Placement(transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Assets.Heatpump.Carnot_COP carnot_COP annotation(
          Placement(transformation(origin = {30, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Modelica.Blocks.Math.Product ThermalOutput annotation(
          Placement(transformation(origin = {-10, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor IndoorTinK annotation(
          Placement(transformation(origin = {-80, -30}, extent = {{-10, -10}, {10, 10}})));
        Buildings.BoundaryConditions.WeatherData.Bus weaBus annotation(
          Placement(transformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {2, 100}, extent = {{-10, -10}, {10, 10}})));
        Assets.Heatpump.heat_pump_basic_control heatpump_control(Pcompressor = Pcompressor) annotation(
          Placement(transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Buildings.Electrical.AC.OnePhase.Loads.Inductive loa(mode = Buildings.Electrical.Types.Load.VariableZ_P_input, pf = .8) annotation(
          Placement(transformation(origin = {70, -70}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
        Buildings.Electrical.AC.OnePhase.Interfaces.Terminal_p term_p annotation(
          Placement(transformation(origin = {-4, -100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {0, -100}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Blocks.Math.Gain neg(k = -1) annotation(
          Placement(transformation(origin = {70, -44}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Blocks.Interfaces.BooleanInput ForceOff annotation(
          Placement(transformation(origin = {90, 104}, extent = {{-20, -20}, {20, 20}}, rotation = -90), iconTransformation(origin = {100, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 180)));
      equation
        connect(ThermalOut, Heatflow.port) annotation(
          Line(points = {{-100, 0}, {-70, 0}}, color = {191, 0, 0}));
        connect(Heatflow.Q_flow, ThermalOutput.y) annotation(
          Line(points = {{-50, 0}, {-21, 0}}, color = {0, 0, 127}));
        connect(ThermalOutput.u1, carnot_COP.COP) annotation(
          Line(points = {{2, -6}, {11, -6}, {11, -10}, {20, -10}}, color = {0, 0, 127}));
        connect(ThermalOut, IndoorTinK.port) annotation(
          Line(points = {{-100, 0}, {-100, -30}, {-90, -30}}, color = {191, 0, 0}));
        connect(IndoorTinK.T, carnot_COP.Tsupply) annotation(
          Line(points = {{-68, -30}, {60, -30}, {60, -4}, {40, -4}}, color = {0, 0, 127}));
        connect(weaBus.TDryBul, carnot_COP.Tamb) annotation(
          Line(points = {{0, 100}, {50, 100}, {50, -16}, {40, -16}}, color = {0, 0, 127}));
        connect(IndoorTinK.T, heatpump_control.Tinterior) annotation(
          Line(points = {{-68, -30}, {90, -30}, {90, -10}}, color = {0, 0, 127}));
        connect(heatpump_control.ElectricPowerConsumption, ThermalOutput.u2) annotation(
          Line(points = {{80, 6}, {2, 6}}, color = {0, 0, 127}));
        connect(loa.terminal, term_p) annotation(
          Line(points = {{70, -80}, {70, -100}, {-4, -100}}, color = {0, 120, 120}));
        connect(neg.y, loa.Pow) annotation(
          Line(points = {{70, -50}, {70, -60}}, color = {0, 0, 127}));
        connect(heatpump_control.ElectricPowerConsumption, neg.u) annotation(
          Line(points = {{80, 6}, {70, 6}, {70, -36}}, color = {0, 0, 127}));
  connect(ForceOff, heatpump_control.Force_off) annotation(
          Line(points = {{90, 104}, {90, 10}}, color = {255, 0, 255}));
      end heatpump_cosim;

      model house_cosim
        import Modelica.Math.Random.Generators.Xorshift64star;
        parameter Integer localSeed = 1;
        parameter Integer globalSeed = 30020;
        final parameter Real PV_area = Utility.sampleUniform(localSeed, globalSeed, 10, 20);
        parameter Real Tint_init = Utility.sampleUniform(localSeed + 100, globalSeed, 273.15 + 10, 273.15 + 25);
        final parameter Real Text_init = Utility.sampleUniform(localSeed + 200, globalSeed, 273.15 + 5, 273.15 + 15);
        final parameter Real Rint = Utility.sampleUniform(localSeed + 300, globalSeed, 0.0015, 0.002);
        final parameter Real Rext = Utility.sampleUniform(localSeed + 400, globalSeed, 0.003, 0.005);
        final parameter Real Rinf = Utility.sampleUniform(localSeed + 500, globalSeed, 0.01, 0.015);
        final parameter Real Cint = Utility.sampleUniform(localSeed + 600, globalSeed, 28688720, 28688720);
        final parameter Real Cext = Utility.sampleUniform(localSeed + 700, globalSeed, 95000000, 105000000);
        final parameter Real Awindow = Utility.sampleUniform(localSeed + 800, globalSeed, 10, 20);
        Buildings.Electrical.AC.OnePhase.Interfaces.Terminal_p PCC annotation(
          Placement(transformation(origin = {-4, -100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {0, -100}, extent = {{-10, -10}, {10, 10}})));
        Buildings.Electrical.AC.OnePhase.Sources.PVSimple Solar_PV(A = PV_area, V_nominal = 230) annotation(
          Placement(transformation(origin = {90, -50}, extent = {{-10, -10}, {10, 10}})));
        Buildings.BoundaryConditions.WeatherData.Bus weaBus annotation(
          Placement(transformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}})));
        Assets.Building_Envelope building_Envelope(Tint_init_v = Tint_init, Text_init_v = Text_init, Rint_v = Rint, Rext_v = Rext, Rinf_v = Rinf, Cin_v = Cint, Cext_v = Cext) annotation(
          Placement(transformation(origin = {-50, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Assets.SolarGains solarGains(Aw = Awindow) annotation(
          Placement(transformation(origin = {-30, 40}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
        heatpump_cosim heatpump(Pcompressor = 1500) annotation(
          Placement(transformation(origin = {-10, 10}, extent = {{-10, -10}, {10, 10}})));
        Assets.Comfort_model comfort_model annotation(
          Placement(transformation(origin = {-30, -18}, extent = {{-10, -10}, {10, 10}})));
        Modelica.Thermal.HeatTransfer.Sources.PrescribedTemperature Tamb annotation(
          Placement(transformation(origin = {-90, 10}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Interfaces.BooleanInput ForceOff annotation(
          Placement(transformation(origin = {40, 10}, extent = {{-20, -20}, {20, 20}}, rotation = 180), iconTransformation(origin = {92, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 180)));
      equation
        connect(Solar_PV.terminal, PCC) annotation(
          Line(points = {{80, -50}, {0, -50}, {0, -101}, {-4, -101}, {-4, -100}}, color = {0, 120, 120}));
        connect(Solar_PV.terminal, PCC) annotation(
          Line(points = {{60, -50}, {-4, -50}, {-4, -100}}, color = {255, 255, 255}));
        connect(weaBus.HGloHor, Solar_PV.G) annotation(
          Line(points = {{0, 100}, {90, 100}, {90, -38}, {90, -38}}, color = {0, 0, 127}));
        connect(solarGains.port_a, building_Envelope.ThermalZone) annotation(
          Line(points = {{-30, 30}, {-30, 10}, {-40, 10}}, color = {191, 0, 0}));
        connect(solarGains.weaBus, weaBus) annotation(
          Line(points = {{-30, 50}, {-30, 100}, {0, 100}}, color = {255, 204, 51}, thickness = 0.5));
        connect(building_Envelope.ThermalZone, heatpump.ThermalOut) annotation(
          Line(points = {{-40, 10}, {-20, 10}}, color = {191, 0, 0}));
        connect(heatpump.weaBus, weaBus) annotation(
          Line(points = {{-10, 20}, {-10, 100}, {0, 100}}, color = {255, 204, 51}, thickness = 0.5));
        connect(heatpump.term_p, PCC) annotation(
          Line(points = {{-10, 0}, {-10.5, 0}, {-10.5, -50}, {0, -50}, {0, -99}, {-2, -99}, {-2, -100.5}, {-4, -100.5}, {-4, -100}}, color = {0, 120, 120}));
        connect(building_Envelope.ThermalZone, comfort_model.ThermalZone) annotation(
          Line(points = {{-40, 10}, {-30, 10}, {-30, -8}}, color = {191, 0, 0}));
        connect(Tamb.port, building_Envelope.Ambient) annotation(
          Line(points = {{-80, 10}, {-60, 10}}, color = {191, 0, 0}));
        connect(weaBus.TDryBul, Tamb.T) annotation(
          Line(points = {{0, 100}, {-110, 100}, {-110, 10}, {-102, 10}}, color = {0, 0, 127}));
  connect(heatpump.ForceOff, ForceOff) annotation(
          Line(points = {{0, 10}, {40, 10}}, color = {255, 0, 255}));
      end house_cosim;
    end helpers;
  end Wrapper;
  annotation(
    uses(Buildings(version = "11.0.0"), Modelica(version = "4.0.0")));
end Workshop_Modelica;

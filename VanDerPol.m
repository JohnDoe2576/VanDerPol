close all; clear all; clc;

% ========================================= %

% Initialize objects
% ------------------

% Create DataStore for Plant
TrainP = DatStore; TestP = DatStore;

% Create DataStore for Controller
TrainC = DatStore; TestC = DatStore;

% Create DataStore for operating plant 
% in one sample at a time mode
DatCP = DatStore;
% DatP = DatStore;

disp("Initialized objects");

% ========================================= %

% User Choices
% ------------
UserSays = UserChoice;

UserSays.Plant = "VanDerPol";
UserSays.DataFolder = "DataStore";

UserSays.ReadNumber = 52;
UserSays.SaveNumber = 52;

UserSays.GenerateDataOnly = false;
UserSays.GeneratePlantModelOnly = false;

UserSays.HaveInputOutputData = true;
UserSays.HavePlantModel = true;
UserSays.HaveControllerModel = true;

UserSays.SaveGenData = false;
UserSays.SavePlantSimData = false;
UserSays.SaveControllerSimData = false;

UserSays.SaveTrainedPlantModel = false;
UserSays.SaveTrainedControllerModel = false;

UserSays.PlotGeneratedData = false;
UserSays.SimulatePlantUsingModel = false;
UserSays.SimulateControllerUsingModel = false;

UserSays.CompareActualAndModelPlant = false;
UserSays.SimulateFullSystem = true;

disp("Obtained user choice");
disp("  ");

% ========================================= %

% Obtain Input-Output data
% ------------------------

if UserSays.HaveInputOutputData == true
        [ TrainP, TestP, TrainC, TestC ] = UserSays.ReadGeneratedData();
        disp("Obtained training and testing data");
else 
        % Plant training data
        [ TrainP.T, TrainP.U ] = Excite(0.0,0.01,20.0).Skyline( [0.01 15.0], [-2.5 2.5] );
        TrainP.Y = MySystem( [1.0, 1.0, 1.0], [0.1, 0.0], 'VanDerPol' ).GenPlantOutput( TrainP.T, TrainP.U );
        disp('Generated plant training data');

        % Plant test data
        [ TestP.T, TestP.U ] = Excite(0.0,0.01,20.0).Skyline( [0.01 15.0], [-2.5 2.5] );
        TestP.Y = MySystem( [1.0, 1.0, 1.0], [0.1, 0.0], 'VanDerPol' ).GenPlantOutput( TestP.T, TestP.U );
        disp('Generated plant testing data');

        % Controller training data
        [ TrainC.T, TrainC.U ] = Excite(0.0,0.01,100.0).Skyline( [0.01 10.0], [-0.5 0.5] );
        TrainC.Y = MySystem( [6.0, -9.0, 9.0], [0.0, 0.0], 'TrackingSys' ).GenPlantOutput( TrainC.T, TrainC.U );
        disp('Generated controller training data');

        % Controller test data
        [ TestC.T, TestC.U ] = Excite(0.0,0.01,100.0).Skyline( [0.01 10.0], [-0.5 0.5] );
        TestC.Y = MySystem( [6.0, -9.0, 9.0], [0.0, 0.0], 'TrackingSys' ).GenPlantOutput( TestC.T, TestC.U );
        disp('Generated controller testing data');

        disp("  ");
end

if UserSays.PlotGeneratedData == true
        PlotData( TrainP ).InputOutput( "Plant training data" );
        PlotData( TestP ).InputOutput( "Plant testing data" );
        PlotData( TrainC ).InputOutput( "Controller training data" );
        PlotData( TestC ).InputOutput( "Controller testing data" );
        disp("Plotted generated data");
end

% Save generated training and testing data sets based on user's choice
UserSays.SaveGeneratedData(TrainP, TestP, TrainC, TestC);

% Check if only data needs to be generated
if UserSays.GenerateDataOnly == true
        if UserSays.GeneratePlantModelOnly == true
                disp( strcat("Warning! Since the user has asked ", ...
                        "for only data generation, plant model will ", ...
                        "not be generated and GeneratePlantModelOnly ", ...
                        "option will be reset to false" ) );
                UserSays.GeneratePlantModelOnly = false;
        end
        return;
end

% ========================================= %

% Obtain Plant Model
% ------------------

if UserSays.HavePlantModel == true
        ModelP = UserSays.ReadPlantModel();
        disp("Obtained trained plant model");
else
        % Creating model structure
        ModelP = NeuralNet( 1:8, ...                            % Input delays
                            1:8, ...                            % Feedback delays
                            10, ...                             % Hidden sizes
                            'open', ...                         % Feedback mode
                            'trainlm', ...                      % Training function
                            '', ...                             % Data division function
                            10000, ...                           % Number of training epochs
                            'mse', ...                          % Performance (loss) function
                            'mapminmax', ...                    % Process function (Type of data normalization)
                            TrainP.T(2) - TrainP.T(1) ...       % Sampling time
                          ).CreatePlantModel(  );
        disp("Created a neural network structure for plant model");

        % Train the model
        ModelP = UseModel( ModelP ).TrainPlant( TrainP.U, TrainP.Y );
        disp("Trained plant model");
        disp(" ");
end

% Save trained closed-loop plant model based on user's choice
UserSays.SavePlantModel( ModelP );

% ========================================= %

% Simulate plant using model
% --------------------------

if UserSays.SimulatePlantUsingModel == true
        TrainP.YpredOL = UseModel(openloop( ModelP )).Simulate( TrainP.U, TrainP.Y );
        TrainP.Ypred = UseModel( ModelP ).Simulate( TrainP.U, TrainP.Y );
        TestP.Ypred = UseModel( ModelP ).Simulate( TestP.U, TestP.Y );

        PlotData( TrainP ).CompareOLandCLwithActual( "Comparing open-loop and closed-loop data with actual training data" );
        PlotData( TestP ).CompareCLwithActual( "Comparing predicted and actual test data" );

        UserSays.SaveSimulatedPlantData( TrainP, TestP );
end

% Check if only plant model needs to be generated
if UserSays.GeneratePlantModelOnly == true
        return;
end

% ========================================= %

% Obtain controller model (MRAC)
% ------------------------------

if UserSays.HaveControllerModel == true
        ModelC = UserSays.ReadControllerModel();
        disp("Obtained trained controller model");
else
        % Create model structure
        ModelC = NeuralNet( 10, ...                            % Controller hidden layer size
                           1:8, ...                            % Reference input delays
                           1:8, ...                            % Controller output delays
                           1:8, ...                            % Plant output delays
                           2000, ...                             % Controller training epochs
                           '' ...                              % Data division function
                           ).CreateControllerModel( ModelP, TrainC );
        disp("Created a neural network structure for controller model");

        % Train the model
        ModelC = UseModel( ModelC ).TrainController( TrainC.U, TrainC.Y );
        disp("Trained controller model");
        disp(" ");
end

% Save trained controller model based on user's choice
UserSays.SaveControllerModel( ModelC );

if UserSays.SimulateControllerUsingModel == true
        TrainC.Ypred = UseModel( ModelC ).Simulate( TrainC.U, TrainC.Y );
        TestC.Ypred = UseModel( ModelC ).Simulate( TestC.U, TestC.Y );

        PlotData( TrainC ).CompareCLwithActual( "Comparing predicted and actual training data" );
        PlotData( TestC ).CompareCLwithActual( "Comparing predicted and actual test data" );
        PlotData( TestC ).InputAndPredictedOutput( "Comparing input and predicted test data" );

        UserSays.SaveSimulatedControllerData( TrainC, TestC );
end

% Couple controller to actual plant and simulate 
if UserSays.SimulateFullSystem == true
%         disp( "Simulating controller connected to actual plant" );
%         disp( "-----------------------------------------------" );
        Sys = FullSystem( "VanDerPol", "MracTrack", [ 1.0, 1.0, 1.0 ], [ 2.0; 0.0 ] )...
                .BeginControlActionAt( 20.01 )...
                .PlantInputParams( [0.01 6.0], [-0.2 0.2] )...
                .ReferenceInputParams( [2.0 3.0], [-2.0 2.0] )...
                .ConfigureMrac( 52 );
%         disp( "Configured controller to operate in one sample at a time mode" );
%         [ T, ~, ~ ] = Sys.GenerateFullInputData( 0.0, 0.01, 150 );
        [ DatCP.T, DatCP.U, DatCP.Yr ] = Sys.GenerateFullInputData( 0.0, 0.01, 50 );
        DatCP.U = zeros(size(DatCP.T));
%         DatCP.Yr = zeros(size(DatCP.T));
%         disp( "Generated input data" );
%         DatCP = struct([]);
        
        [ DatCP.Y, DatCP.U ] = Sys.SimulateSystem( DatCP.T, DatCP.U, DatCP.Yr );

%         Tctrl = round(linspace(13.32,(20.835-(6.68/8)),64),2);
%         Tctrl = 13.32;
%         for i = 1:length(Tctrl)
%                 Sys = Sys.BeginControlActionAt(Tctrl(i));
%                 DatCP(1,i).T = T;
%                 DatCP(1,i).U = zeros(size(T));
%                 DatCP(1,i).Yr = zeros(size(T));
%                 [ DatCP(1,i).Y, DatCP(1,i).U ] = Sys.SimulateSystem( DatCP(1,i).T, DatCP(1,i).U, DatCP(1,i).Yr );
%                 disp(i);
%         end
%                 disp( "Simulated system in one sample at a time mode" );
        
%         PlotData( DatCP ).ControllerOutput( " " );
%         PlotData( DatCP ).ControlledSimulationYandYr();
        
        PlotData( DatCP ).ControlledSimulationFull( " " );
        PlotData( DatCP ).ControlledSimulation( " " );
        PlotData( DatCP ).ControllerOutput( " " );
        
%         Sys = Sys.BeginControlActionAt( 1e10 );
%         [ DatCP.Ypred, ~ ] = Sys.SimulateSystem( DatCP.T, DatCP.U, DatCP.Yr );
        
%         DatCP.Ypred = MySystem( [1.0, 1.0, 1.0], [2.0, 0.0], 'VanDerPol' ).GenPlantOutput( DatCP.T, DatCP.U );
%         PlotData( DatCP ).CompareInLoopAndNoLoop( "Comparing no-loop and in-loop data" );
end

if UserSays.CompareActualAndModelPlant == true
        Sys = FullSystem( "VanDerPol", "MracTrack", [ 1.0 1.0 1.0 ], [ 0.0; 0.0 ] )...
                .PlantInputParams( [0.01 15.0], [-2.0 2.0] )...
                .ConfigurePlant( 1 );
        disp( "Configured plant model to operate in one sample at a time mode" );
        
        [ DatP.T, DatP.U ] = Sys.GenerateInputData( 0.0, 0.05, 100.0 );
        [  DatP.Y, DatP.Ypred ] = Sys.SimulatePlantAndModel( DatP.T, DatP.U );
        
        PlotData( DatP ).CompareInLoopAndNoLoop( "Comparing no-loop and in-loop data" );
end
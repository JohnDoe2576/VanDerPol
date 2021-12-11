classdef FullSystem
        properties (Access = public)
                Plant
                Controller
                Tctrl
                Xo
        end

        properties (Access = public)
                % System properties
                P1
                P2
                P3

                % Plant input signal properties
                Ualfa
                Utau

                % Reference input signal properties
                YrAlfa
                YrTau
        end

        % Neural Network essentials
        properties ( Access = public )
                W       % Weight (cell)
                b       % bias (cell)
                f       % Activation function (cell)

                D       % Delays

                % Normalization
                Norm = struct( 'xoffset', {}, 'ymin', {}, 'gain', {} );
        end

        methods (Access = public)
                % Constructor
                function [ obj ] = FullSystem( Plant, Controller, P, Xo )
                        obj.Plant = Plant;
                        obj.Controller = Controller;

                        obj.P1 = P(1);
                        obj.P2 = P(2);
                        obj.P3 = P(3);

                        obj.Xo = Xo;
                end

                % When to switch ON controller
                function [ obj ] = BeginControlActionAt( obj, Tctrl )
                        obj.Tctrl = Tctrl;
                end

                % Plant input signal parameters
                function [ obj ] = PlantInputParams( obj, Alfa, Tau )
                        obj.Ualfa = Alfa;
                        obj.Utau = Tau;
                end

                % Reference input parameters
                function [ obj ] = ReferenceInputParams( obj, Alfa, Tau )
                        obj.YrAlfa = Alfa;
                        obj.YrTau = Tau;
                end
                
                function [ T, U ] = GenerateInputData( obj, Tstart, dt, Tend )
                        [ T, U ] = Excite( Tstart, dt, Tend ).Skyline( obj.Ualfa, obj.Utau );
                        T = obj.ConvertToRow( T );
                        U = obj.ConvertToRow( U );
                end

                % Generate data
                function [ T, U, Yr ] = GenerateFullInputData( obj, Tstart, dt, Tend )
                        % Generate plant input signal data
                        [ Tu, U ] = Excite( Tstart, dt, (obj.Tctrl-dt) ).Skyline( obj.Ualfa, obj.Utau );
                        
                        % Generate controller reference input data
                        [ Tyr, Yr ] = Excite( obj.Tctrl,dt,Tend ).Skyline( obj.YrAlfa, obj.YrTau );

                        % Convert all generated data to row vector
                        Tu = obj.ConvertToRow( Tu );
                        Tyr = obj.ConvertToRow( Tyr );
                        U = obj.ConvertToRow(U);
                        Yr = obj.ConvertToRow(Yr);

                        % Combine all data
                        T = [ Tu Tyr ];
                        U = [ U zeros(size(Tyr)) ];
                        Yr = [ zeros(size(Tu)) Yr ];
                end

                % Configure Mrac controller for tracking problem
                function [ obj ] = ConfigureMrac( obj, FileNumber )
                        obj = ConfigureMracController( obj, FileNumber );
                end
                
                function [ obj ] = ConfigurePlant( obj, FileNumber )
                        obj = ConfigurePlantNet( obj, FileNumber );
                end

                % Simulate system
                function [ Y, U ] = SimulateSystem( obj, T, U, Yr )
                        % Total number of samples
                        N = length(T);
                        
                        % InitializeArrays
                        Yclone = zeros( 2, size(T,2) );
                        Y = zeros( 2, size(T,2) );
                        
                        % Setting-up plants and controllers
                        MyPlant = str2func( obj.Plant );
                        MyCtrl = str2func( obj.Controller );
                        
                        % Initialize plant
                        Yclone(:,1) = obj.Xo;
                        Y(:,1) = obj.Xo;

                        % Begin simulation loop
                        for i = 2:N

                                % Check if controller is ON
                                if T(i) >= obj.Tctrl
                                        if T(i) == obj.Tctrl
                                                % Initialize controller
                                                MyCtrl( obj, [], [], Yr(1,i-obj.D{1}:i-2), Yclone(1,i-obj.D{3}:i-2) );
                                        end

                                        % Get controller output
                                        U(1,i) = MyCtrl( obj, Yr(1,i-1), Yclone(1,i-1) );
                                end

                                % Simulate actual plant
                                % ode45( (t,y) @plant( obj, t, y, Sim_@_These_T_values, U_vector ), Tspan, IC )
                                [ ~, Yact ] = ode45( @(t,y) ...
                                              MyPlant( obj, t, y, T(1,i-1:i), U(1,i-1:i) ), T(1,i-1:i), Y(:,i-1) );
                                Yact = obj.ConvertToColumn( Yact(end,:) );
                                Yclone(:,i) = Yact;
                                Y(:,i) = Yact;
                        end
                end
                
                % Simulate actual and model plants together
                function [ Y, Ypred ] = SimulatePlantAndModel( obj, T, U )
                        % Total number of samples
                        N = length(T);
                        
                        % Max. number of previous delays in model
                        Dmax = max( [ obj.D{5} obj.D{6} ] );
                        
                        % InitializeArrays
                        Y = zeros( 2, size(T,2) );
                        Ypred = zeros( 2, size(T,2) );
                        
                        % Initialize plant
                        MyPlant = str2func( obj.Plant );
                        Y(:,1) = obj.Xo;
                        
                        % Start simulation loop
                        for i = 2:N
                                % Simulate actual plant
                                % ode45( (t,y) @plant( obj, t, y,
                                %              Sim_@_These_T_values, U_vector ), Tspan, IC )
                                [ ~, Yact ] = ode45( @(t,y) ...
                                              MyPlant( obj, t, y, ...
                                                       T(1,i-1:i), U(1,i-1:i) ), ...
                                                       T(1,i-1:i), Y(:,i-1) );
                                Yact = obj.ConvertToColumn( Yact(end,:) );
                                Y(:,i) = Yact;

                                % Model simulation begins after the max. delays
                                if i > Dmax
                                        if i == Dmax+1
                                                % Save prev. plant ops in Ypred
                                                Ypred(1,1:Dmax) = Y(1,1:Dmax);
                                                
                                                PlantNeuralNet( obj, [], [], U(1,i-obj.D{5}:i-2), Ypred(1,i-obj.D{6}:i-2) );
                                        end
                                        
%                                         Ypred(1,i) = PlantNeuralNet( obj, U(1,i-1), Y(1,i-1) );
                                        Ypred(1,i) = PlantNeuralNet( obj, U(1,i-1), Ypred(1,i-1) );
                                end
                        end
                end

                function [ Y ] = PlantSim( obj, Time, Input2, InitialCondition )
                        MyPlant = str2func( obj.Plant );
                        [ ~, Y ] = ode45( @(T,Y) MyPlant( obj, T, Y, Time, Input2 ), Time, InitialCondition );
                        Y = obj.ConvertToColumn( Y(end,:) );
                end
        end

        % Private methods for different systems
        methods (Access = private)

                % Robotic Arm
                function [ Xdot ] = RobotArm( obj, T, X, Tspan, U )

                        IntU = interp1( Tspan, U, T, 'previous' );

                        % System states
                        Xdot = [ X( 2 ); ...
                                ( obj.P2 * sin( X( 1 ) ) ) - ( obj.P1 * X( 2 ) ) + ( obj.P3 * IntU ) ];

                end
                
                function [ PlantOutput ] = SimulateActualPlant( obj, T, U, Y )
                                % Get plant inputs
                                [ Time, Input2, InitialCondition ] = obj.PlantInputs( T, U, Y );
                                
                                % Input2 is the plant perturbation/control signal
                                PlantOutput = PlantSim( obj, Time, Input2, InitialCondition );
                end

                function [ dXdt ] = VanDerPol( obj, T, X, Tspan, U )

                        IntU = interp1( Tspan, U, T, 'previous' );
%                         IntU = U;

                        dXdt = [ X(2);
                                 ( obj.P3*IntU ) - ( obj.P1*(X(1)^2 - 1)*X(2) ) - ( obj.P2*X(1) ) ];

                end

                function [ dXdt ] = TrackingSys( obj, T, X, Tspan, U )

                        IntU = interp1( Tspan, U, T, 'previous' );

                        dXdt = [ X( 2 ); ...
                                ( obj.P2 * X( 1 ) ) - ( obj.P1 * X( 2 ) ) + ( obj.P3 * IntU ) ];

                end

        end

        methods (Access = private)
                
                % Extract controller weights, biases, normalizations etc
                function [ obj ] = ConfigureMracController( obj, FileNumber )
                        % Load controller network
                        Net = LoadController( obj, FileNumber );
                        NetP = LoadPlant( obj, FileNumber );
                        
                        % Extract trained weights
                        obj.W{1} = Net.IW{1,1};         % Reference input weight (10xR)
                        obj.W{2} = Net.LW{1,2};         % Control output weight (10xR)
                        obj.W{3} = Net.LW{1,6};         % Plant output weight (10xR)
                        obj.W{4} = Net.LW{2,1};         % Layer 1 to Layer 2 weight (1x10)
                        
                        % Extract trained biases
                        obj.b{1} = Net.b{1,1};
                        obj.b{2} = Net.b{2,1};

                        % Extract layer activation (transfer) functions
                        obj.f{1} = str2func(Net.layers{1,1}.transferFcn);
                        obj.f{2} = str2func(Net.layers{2,1}.transferFcn);

                        % Extract delays
                        obj.D{1} = max(Net.inputWeights{1,1}.delays);
                        obj.D{2} = max(Net.layerWeights{1,2}.delays);
                        obj.D{3} = max(Net.layerWeights{1,6}.delays);

                        % Extract normalizations
                        % ----------------------
                        % Since normalizations are strictly avoided during
                        % controller training, Norm{1} & Norm{2} do not exist
                        % Plant input normalization
                        obj.Norm{3}.xoffset = NetP.inputs{1,1}.processSettings{1,1}.xoffset;
                        obj.Norm{3}.ymin = NetP.inputs{1,1}.processSettings{1,1}.ymin;
                        obj.Norm{3}.gain = NetP.inputs{1,1}.processSettings{1,1}.gain;
                        % Plant output normalization
                        obj.Norm{4}.xoffset = NetP.outputs{1,2}.processSettings{1,1}.xoffset;
                        obj.Norm{4}.ymin = NetP.outputs{1,2}.processSettings{1,1}.ymin;
                        obj.Norm{4}.gain = NetP.outputs{1,2}.processSettings{1,1}.gain;
                end
                
                function [ obj ] = ConfigurePlantNet( obj, FileNumber )
                        % Load Neural Network
                        Net = LoadPlant( obj, FileNumber );
                        
                        % Extract weights
                        obj.W{5} = Net.IW{1,1};         % Delayed plant inputs
                        obj.W{6} = Net.LW{1,2};         % Delayed plant outputs
                        obj.W{7} = Net.LW{2,1};         % Layer 1 to Layer 2
                        
                        % Extract biases
                        obj.b{5} = Net.b{1,1};          % Layer 1
                        obj.b{6} = Net.b{2,1};          % Layer 2
                        
                        % Extract activation (transfer) functions
                        obj.f{5} = str2func(Net.layers{1,1}.transferFcn);
                        obj.f{6} = str2func(Net.layers{2,1}.transferFcn);
                        
                        % Extract delays
                        obj.D{5} = max(Net.inputWeights{1,1}.delays);
                        obj.D{6} = max(Net.layerWeights{1,2}.delays);
                        
                        % Plant input normalization
                        obj.Norm{5}.xoffset = Net.inputs{1,1}.processSettings{1,1}.xoffset;
                        obj.Norm{5}.ymin = Net.inputs{1,1}.processSettings{1,1}.ymin;
                        obj.Norm{5}.gain = Net.inputs{1,1}.processSettings{1,1}.gain;
                        % Plant output normalization
                        obj.Norm{6}.xoffset = Net.outputs{1,2}.processSettings{1,1}.xoffset;
                        obj.Norm{6}.ymin = Net.outputs{1,2}.processSettings{1,1}.ymin;
                        obj.Norm{6}.gain = Net.outputs{1,2}.processSettings{1,1}.gain;
                end

                % Load trained controller from file
                function [ ModelC ] = LoadPlant( obj, FileNumber )
                        File = strcat("DataStore/", ...
                                obj.Plant, num2str(FileNumber), ".mat" );
                        ModelC = obj.LoadTrainedPlant( File );
                end

                % Load trained controller from file
                function [ ModelC ] = LoadController( obj, FileNumber )
                        File = strcat("DataStore/", ...
                                obj.Plant, num2str(FileNumber), ".mat" );
                        ModelC = obj.LoadTrainedController( File );
                end
                
                function [ Co ] = MracTrack( obj, Ri, Po, Pri, Ppo )
                        
                        persistent Dri Dco Dpo

                        % The controller is initialized here
                        if nargin > 3
                                % Delayed reference inputs
                                Dri = fliplr( [ Pri 0 ] );

                                % Delayed controller outputs
                                Dco = zeros( 1, obj.D{2} );

                                % Delayed plant outputs
                                Dpo = fliplr( [ Ppo 0 ] );
                                
                                return
                        end
                        
                        % Introducing current input into input vectors
                        Dri(1,1) = Ri;
                        Dpo(1,1) = Po;
                        
                        % Simulating layer 1 of controller
                        a1 = obj.f{1}( obj.W{1}*transpose(Dri) + ...
                                       obj.W{2}*transpose(Dco) + ...
                                       obj.W{3}*transpose(Dpo) + ...
                                       obj.b{1} );

                        % Simulating layer 2 of controller
                        Co = obj.f{2}( obj.W{4}*a1 + obj.b{2} );

                        % Introduce current controller output 
                        % in delayed  vector
                        Dco(1,end) = Co;
                        
                        % Shift delayed vectors
                        Dri = circshift(Dri, 1, 2);
                        Dpo = circshift(Dpo, 1, 2);
                        Dco = circshift(Dco, 1, 2);
                end
                
                function [ Y ] = PlantNeuralNet( obj, Pi, Po, Ppi, Ppo )
                        
                        persistent Dpi Dpo
                        
                        if nargin > 3
                                % Delayed plant inputs
                                Dpi = fliplr( [ obj.ApplyNormalization(Ppi,obj.Norm{5}) 0 ] );
                                
                                % Delayed plant outputs
%                                 Dpo = obj.ApplyNormalization( zeros( 1, obj.D{2} ), obj.Norm{6} );
                                Dpo = fliplr( [ obj.ApplyNormalization(Ppo,obj.Norm{6}) 0 ] );
                                
                                return
                        end
                        
                        % Introducing normalized current input into input vectors
                        Dpi(1,1) = obj.ApplyNormalization(Pi, obj.Norm{5});
                        Dpo(1,1) = obj.ApplyNormalization(Po, obj.Norm{6});
                        
                        % Simulating plant layer 1
                        a1 = obj.f{5}( obj.W{5}*transpose( Dpi ) + ...
                                       obj.W{6}*transpose( Dpo ) + ...
                                       obj.b{5} );

                        % Simulating plant layer 2
                        Y = obj.f{6}( obj.W{7}*a1 + obj.b{6} );
                        
                        Dpi = circshift(Dpi, 1, 2);
                        Dpo = circshift(Dpo, 1, 2);
                        
                        Y = obj.ReverseNormalization( Y, obj.Norm{6} );
                end
        end

        % Some loading/saving functions
        methods (Access = private, Static)
                function [ ModelP ] = LoadTrainedPlant( File )
                        M = matfile(File);
                        ModelP = M.ModelP;
                end
                
                function [ ModelC ] = LoadTrainedController( File )
                        M = matfile(File);
                        ModelC = M.ModelC;
                end
        end

        % Some required functions
        methods (Access = private, Static)
                
                function [ X ] = ConvertToRow( X )
                        [  r, c ] = size(X);
                        if r > c
                                X = X.';
                        end
                end
                
                function [ X ] = ConvertToColumn(X)

                        [ r,c ] = size(X);
                        if (r < c)
                                X = X.';
                        end

                end

                function [ X ] = CreateOdeInput( Xstart, Xend )
                        Xmid = mean( [ Xstart, Xend ] );
                        X = [ Xstart Xmid Xend ];
                end

                function [ Y ] = ApplyNormalization( X, Options )
                        Gain = Options.gain; 
                        Offset = Options.xoffset;
                        Intercept = Options.ymin;
                        
                        Y = Intercept + Gain*(X - Offset);
                end
                
                function [ X ] = ReverseNormalization( Y, Options )
                        Gain = Options.gain; 
                        Offset = Options.xoffset;
                        Intercept = Options.ymin;
                        
                        X = Offset + (Y - Intercept)/Gain;
                end

        end
end
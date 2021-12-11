classdef NeuralNet
        properties
                InputDelays
                FeedbackDelays
                HiddenSizes
                FeedbackMode

                TrainFcn
                DivFcn

                TrainEpoch
                PrfmFcn
                PrcFcn

                SampleTime
        end

        properties
                CtrlHiddenSize
                ReferenceInputDelays
                ControllerOutputDelays
                PlantOutputDelays
        end

        methods
                function [ obj ] = NeuralNet(  varargin )
                        if nargin == 10
                                obj.InputDelays = varargin{1};
                                obj.FeedbackDelays = varargin{2};
                                obj.HiddenSizes = varargin{3};
                                obj.FeedbackMode = varargin{4};

                                obj.TrainFcn = varargin{5};
                                obj.DivFcn = varargin{6};

                                obj.TrainEpoch = varargin{7};
                                obj.PrfmFcn = varargin{8};
                                obj.PrcFcn = varargin{9};

                                obj.SampleTime = varargin{10};
                        elseif nargin == 6
                                obj.CtrlHiddenSize = varargin{1};
                                obj.ReferenceInputDelays = varargin{2};
                                obj.ControllerOutputDelays = varargin{3};
                                obj.PlantOutputDelays = varargin{4};
                                obj.TrainEpoch = varargin{5};
                                obj.DivFcn = varargin{6};
                        end
                end

                function [ Net ] = CreatePlantModel( obj )
                        Net = narxnet( obj.InputDelays, ...
                                obj.FeedbackDelays, ...
                                obj.HiddenSizes, ...
                                obj.FeedbackMode, ...
                                obj.TrainFcn );

                        % Use Nguyen-Widrow function to initialize weights
                        Net.layers{ :,1 }.initFcn = 'initnw';

                        % Set data division function
                        Net.divideFcn = obj.DivFcn;
                        % Normalize data (mapminmax is default). If required use mapstd
                        Net.inputs{ :,1 }.processFcns{1,2} = obj.PrcFcn;

                        % Modify training parameters
                        Net.trainParam.min_grad = 1e-10;
%                         Net.trainParam.goal = 5e-08;
                        Net.trainParam.epochs = obj.TrainEpoch;
%                         Net.trainParam.max_fail = 15;
%                         Net.performFcn = 'sse';
                        Net.performFcn = obj.PrfmFcn;
                        % Net.performParam.regularization = 1e-12;
                        Net.plotFcns{1,3} = 'plotwb';
                        Net.SampleTime = obj.SampleTime;
                        Net.efficiency.memoryReduction = 4;
%                         Net.trainParam.showWindow = false;
%                         Net.trainParam.showCommandLine = true;
%                         Net.trainParam.show = 1;
                end
                
                function [ MracNet ] = CreateControllerModel( obj, NetC, Dat )
                        MracNet = feedforwardnet( [ obj.CtrlHiddenSize 1 1 NetC.layers{ 1,1 }.size 1 ] );

                        % Modifyig transfer functions
                        MracNet.layers{2,1}.transferFcn = 'purelin';
                        MracNet.layers{3,1}.transferFcn = 'purelin';
                        MracNet.layers{5,1}.transferFcn = 'purelin';
                        MracNet.layers{6,1}.transferFcn = 'purelin';
                        MracNet.sampleTime = NetC.sampleTime;

                        % Make appropriate connections
                        MracNet.layerConnect(1,2) = 1;
                        MracNet.layerConnect(1,6) = 1;
                        MracNet.layerConnect(4,5) = 1;
                        
                        MracNet.name = 'Model Reference Adaptive Controller';
                        MracNet.outputs{1,6}.feedbackMode = 'closed';

                        % Modify the controller part of MracNet
                        % -------------------------------------
                        MracNet.inputWeights{ 1,1 }.delays = obj.ReferenceInputDelays;
                        MracNet.layerWeights{ 1,2 }.delays = obj.ControllerOutputDelays;
                        MracNet.layerWeights{ 1,6 }.delays = obj.PlantOutputDelays;

                        % Match NetC to MracNet ( Plant part )
                        % ------------------------------------
                        MracNet.layerWeights{4,3}.delays = NetC.inputWeights{1,1}.delays;
                        MracNet.layerWeights{4,5}.delays = NetC.layerWeights{1,2}.delays;
                        
                        MracNet.inputs{1,1}.processFcns = {};
%                         MracNet.inputs{1,1}.processFcns = {'removeconstantrows'};
%                         MracNet.inputs{1,1}.processFcns = {'mapminmax','removeconstantrows'};
%                         MracNet.inputs{1,1}.processFcns = {'mapminmax'};
                        MracNet.outputs{1,6}.processFcns = {};
%                         MracNet.outputs{1,6}.processFcns = {'removeconstantrows'};
%                         MracNet.outputs{1,6}.processFcns = {'mapminmax','removeconstantrows'};
%                         MracNet.outputs{1,6}.processFcns = {'mapminmax'};

                        MracNet.layers{4,1}.transferFcn = NetC.layers{1,1}.transferFcn;
                        MracNet.layers{5,1}.transferFcn = NetC.layers{2,1}.transferFcn;

                        MracNet.divideFcn = obj.DivFcn;

                        % Configure the network so that weights and biases of plant model can 
                        % be intorduced
                        Useq = con2seq( Dat.U );
                        Yseq = con2seq( Dat.Y( 1, : ) );

                        % Configure network
                        MracNet = configure( MracNet, Useq, Yseq );

                        % Set controller output to zero
%                         M = matfile("DataStore\VanDerPol5.mat");
%                         ModelC = M.ModelC;
%                         MracNet.IW{1,1} = ModelC.IW{1,1};
%                         MracNet.LW{1,2} = ModelC.LW{1,2};
%                         MracNet.LW{1,6} = ModelC.LW{1,6};
%                         MracNet.b{1,1} = ModelC.b{1,1};
%                         MracNet.b{2,1} = ModelC.b{2,1};
                        MracNet.LW{ 2,1 } = zeros( size( MracNet.LW{ 2,1 } ) );
                        MracNet.b{ 2 } = 0;
                        
                        % Substitute plant layer weights
                        MracNet.LW{4,3} = NetC.IW{1,1};
                        MracNet.LW{4,5} = NetC.LW{1,2};
                        MracNet.LW{5,4} = NetC.LW{2,1};
                        MracNet.b{4,1} = NetC.b{1,1};
                        MracNet.b{5,1} = NetC.b{2,1};

                        % Make sure trained plant weights 
                        % and biases are not re-learned
                        MracNet.layerWeights{4,3}.learn = false;
                        MracNet.layerWeights{4,5}.learn = false;
                        MracNet.layerWeights{5,4}.learn = false;
                        MracNet.biases{4,1}.learn = false;
                        MracNet.biases{5,1}.learn = false;
                        
                        % Modify the normalization layers to your needs
                        % 
                        % ----- Apply normalization ----- %
                        % Adding a layer at the exit of plant to 
                        % reverse the plant output normalization
                        % Weight = Gain
                        % Bias = Ymin - ( Gain * Xoffset )
                        Gain = NetC.inputs{1,1}.processSettings{1,1}.gain;
                        Ymin = NetC.inputs{1,1}.processSettings{1,1}.ymin;
                        Xoffset = NetC.inputs{1,1}.processSettings{1,1}.xoffset;

                        MracNet.LW{3,2} = Gain;
                        MracNet.b{3,1} = Ymin - ( Gain * Xoffset );
                        
                        % Ensure the above weights are not re-trained
                        MracNet.layerWeights{3,2}.learn = false;
                        MracNet.biases{3,1}.learn = false;

                        % ----- Reverse normalization ----- %
                        % Adding a layer at the exit of plant to 
                        % reverse the plant output normalization
                        % Weight = 1/Gain
                        % Bias = Xoffset - ( (1/Gain) * Ymin )
                        Gain = NetC.outputs{1,2}.processSettings{1,1}.gain;
                        Ymin = NetC.outputs{1,2}.processSettings{1,1}.ymin;
                        Xoffset = NetC.outputs{1,2}.processSettings{1,1}.xoffset;

                        MracNet.LW{6,5} = 1/Gain;
                        MracNet.b{6,1} = Xoffset - ( (1/Gain) * Ymin );
                        
                        % Ensure the above weights are not re-trained
                        MracNet.layerWeights{6,5}.learn = false;
                        MracNet.biases{6,1}.learn = false;

                        MracNet.plotFcns = {'plotperform', 'plotwb', 'plottrainstate', ...
                                            'ploterrcorr', 'plotinerrcorr', ...
                                            'plotregression', 'plotresponse'};
                        MracNet.trainFcn = 'trainlm';

                        MracNet.trainParam.epochs = obj.TrainEpoch;
                        MracNet.trainParam.min_grad = 1e-10;
                        % MracNet.trainParam.max_fail = 12;
                        % MracNet.performFcn = 'mse';
                        % view(MracNet)
%                         MracNet.trainParam.showWindow = false;
%                         MracNet.trainParam.showCommandLine = true;
%                         MracNet.trainParam.show = 10;
                end
                
                function [ MracNet ] = CreateControllerModel1( obj, NetC, Dat )
                        MracNet = feedforwardnet( [ obj.CtrlHiddenSize 1 1 1 NetC.layers{ 1,1 }.size 1 1 ] );
                        MracNet.name = 'Model Reference Adaptive Controller';
                        MracNet.outputs{1,8}.feedbackMode = 'closed';
                        
                        % Modifyig transfer functions
                        MracNet.layers{2,1}.transferFcn = 'purelin';
                        MracNet.layers{3,1}.transferFcn = 'purelin';
                        MracNet.layers{4,1}.transferFcn = 'purelin';
                        MracNet.layers{6,1}.transferFcn = 'purelin';
                        MracNet.layers{7,1}.transferFcn = 'purelin';
                        MracNet.sampleTime = NetC.sampleTime;

                        % Make appropriate connections
                        MracNet.layerConnect(1,2) = 1;
                        MracNet.layerConnect(1,8) = 1;
                        MracNet.layerConnect(5,6) = 1;

                        % Modify the controller part of MracNet
                        % -------------------------------------
                        MracNet.inputWeights{ 1,1 }.delays = obj.ReferenceInputDelays;
                        MracNet.layerWeights{ 1,2 }.delays = obj.ControllerOutputDelays;
                        MracNet.layerWeights{ 1,8 }.delays = obj.PlantOutputDelays;
                        
                        % Match NetC to MracNet ( Plant part )
                        % ------------------------------------
                        MracNet.layerWeights{5,4}.delays = NetC.inputWeights{1,1}.delays;
                        MracNet.layerWeights{5,6}.delays = NetC.layerWeights{1,2}.delays;
                        
                        
                        MracNet.inputs{1,1}.processFcns = {};
%                         MracNet.inputs{1,1}.processFcns = {'mapminmax'};
                        MracNet.outputs{1,8}.processFcns = {};
%                         MracNet.outputs{1,8}.processFcns = {'mapminmax'};

                        MracNet.layers{5,1}.transferFcn = NetC.layers{1,1}.transferFcn;
                        MracNet.layers{6,1}.transferFcn = NetC.layers{2,1}.transferFcn;

                        MracNet.divideFcn = obj.DivFcn;

                        % Configure the network so that weights and biases of plant model can 
                        % be intorduced
                        Useq = con2seq( Dat.U );
                        Yseq = con2seq( Dat.Y( 1, : ) );

                        % Configure network
                        MracNet = configure( MracNet, Useq, Yseq );

                        % Set controller output to zero
                        MracNet.LW{ 2,1 } = zeros( size( MracNet.LW{ 2,1 } ) );
                        MracNet.b{ 2 } = 0;
                        
                        MracNet.LW{5,4} = NetC.IW{1,1};
                        MracNet.LW{5,6} = NetC.LW{1,2};
                        MracNet.LW{6,5} = NetC.LW{2,1};
                        MracNet.b{5,1} = NetC.b{1,1};
                        MracNet.b{6,1} = NetC.b{2,1};

                        % Make sure trained plant weights 
                        % and biases are not re-learned
                        MracNet.layerWeights{5,4}.learn = false;
                        MracNet.layerWeights{5,6}.learn = false;
                        MracNet.layerWeights{6,5}.learn = false;
                        MracNet.biases{5,1}.learn = false;
                        MracNet.biases{6,1}.learn = false;

                        % Modify the normalization layers to your needs
                        % 
                        % ----- Apply normalization ----- %
                        % [X - Xoffset] =
                        %       {Weight (= 1.0) * X (Input)} + bias (Xoffset) = a1
                        MracNet.LW{3,2} = 1.0;
                        MracNet.b{3,1} = -NetC.inputs{1,1}.processSettings{1,1}.xoffset;
                        % [Gain * ( X - Xoffset ) + Ymin] = 
                        %       {Weight (= Gain) * a1 (Input)} + bias (Ymin)
                        MracNet.LW{4,3} = NetC.inputs{1,1}.processSettings{1,1}.gain;
                        MracNet.b{4,1} = NetC.inputs{1,1}.processSettings{1,1}.ymin;

                        % ----- Reverse normalization ----- %
                        % [Y - Ymin] =
                        %       {Weight (= 1.0) * Y} + bias (Ymin) = a1
                        MracNet.LW{7,6} = 1.0;
                        MracNet.b{7,1} = -NetC.outputs{1,2}.processSettings{1,1}.ymin;
                        % [(1/Gain) * ( Y - Ymin ) + Xoffset] = 
                        %       {Weight (= 1/Gain) * a1 (Input)} + bias (Xoffset)
                        MracNet.LW{8,7} = 1/NetC.outputs{1,2}.processSettings{1,1}.gain;
                        MracNet.b{8,1} = NetC.outputs{1,2}.processSettings{1,1}.xoffset;

                        % Again, as above, make sure to cross-off learning 
                        MracNet.layerWeights{3,2}.learn = false;
                        MracNet.biases{3,1}.learn = false;
                        MracNet.layerWeights{4,3}.learn = false;
                        MracNet.biases{4,1}.learn = false;
                        % 
                        MracNet.layerWeights{7,6}.learn = false;
                        MracNet.biases{7,1}.learn = false;
                        MracNet.layerWeights{8,7}.learn = false;
                        MracNet.biases{8,1}.learn = false;

                        MracNet.plotFcns = {'plotperform', 'plotwb', 'plottrainstate', ...
                                            'ploterrcorr', 'plotinerrcorr', ...
                                            'plotregression', 'plotresponse'};
                        MracNet.trainFcn = 'trainlm';

                        MracNet.trainParam.epochs = obj.TrainEpoch;
                        MracNet.trainParam.min_grad = 1e-10;
                        % MracNet.trainParam.max_fail = 12;
                        % MracNet.performFcn = 'mse';
                        
% % % % %                         MracNet = feedforwardnet( [ obj.CtrlHiddenSize 1 NetC.layers{ 1,1 }.size ] );
% % % % %                         MracNet.name = 'Model Reference Adaptive Controller';
% % % % %                         MracNet.layers{ 2,1 }.transferFcn = 'purelin';
% % % % %                         MracNet.sampleTime = NetC.sampleTime;
% % % % % 
% % % % %                         % Make appropriate connections
% % % % %                         MracNet.layerConnect = [0 1 0 1;1 0 0 0;0 1 0 1;0 0 1 0];
% % % % % 
% % % % %                         % Modify the controller part of MracNet
% % % % %                         % -------------------------------------
% % % % %                         MracNet.inputWeights{ 1,1 }.delays = obj.ReferenceInputDelays;
% % % % %                         MracNet.layerWeights{ 1,2 }.delays = obj.ControllerOutputDelays;
% % % % %                         MracNet.layerWeights{ 1,4 }.delays = obj.PlantOutputDelays;
% % % % % 
% % % % %                         % Match NetC to MracNet ( Plant part )
% % % % %                         % ------------------------------------
% % % % % 
% % % % %                         % Match input of NetC to MRacNet
% % % % %                         MracNet.inputs{ 1,1 }.name = 'Ur';
% % % % % %                         MracNet.inputs{ 1,1 }.processFcns = {'mapminmax'};
% % % % %                         MracNet.inputs{ 1,1 }.processFcns = {};
% % % % % %                         MracNet.inputs{ 1,1 }.processFcns = NetC.inputs{ 1,1 }.processFcns;
% % % % % 
% % % % %                         % Match delays
% % % % %                         % Input delay to plant ( delayed controller outputs )
% % % % %                         MracNet.layerWeights{ 3,2 }.delays = NetC.inputWeights{ 1,1 }.delays;
% % % % %                         % Delayed plant outputs
% % % % %                         MracNet.layerWeights{ 3,4 }.delays = NetC.layerWeights{ 1,2 }.delays;
% % % % % 
% % % % %                         % Change layer names
% % % % %                         MracNet.layers{ 1,1 }.name = 'Controller Hidden Layer 1';
% % % % %                         MracNet.layers{ 2,1 }.name = 'Controller Hidden Layer 2';
% % % % %                         MracNet.layers{ 3,1 }.name = 'Plant Hidden Layer 1';
% % % % %                         MracNet.layers{ 4,1 }.name = 'Plant Hidden Layer 2';
% % % % % 
% % % % %                         % Change initFcn to Nguyen-Widrow
% % % % %                         MracNet.layers{ 3,1 }.initFcn = NetC.layers{ 1,1 }.initFcn;
% % % % %                         MracNet.layers{ 4,1 }.initFcn = NetC.layers{ 2,1 }.initFcn;
% % % % % 
% % % % %                         % Change netInputFcn to netsum / netprod / netinv
% % % % %                         MracNet.layers{ 3,1 }.netInputFcn = NetC.layers{ 1,1 }.netInputFcn;
% % % % %                         MracNet.layers{ 4,1 }.netInputFcn = NetC.layers{ 2,1 }.netInputFcn;
% % % % % 
% % % % %                         % Change transfer function in each of the layers
% % % % %                         MracNet.layers{ 3,1 }.transferFcn = NetC.layers{ 1,1 }.transferFcn;
% % % % %                         MracNet.layers{ 4,1 }.transferFcn = NetC.layers{ 2,1 }.transferFcn;
% % % % % %                         MracNet.layers{ 3,1 }.transferFcn = NetC.layers{ 1,1 }.transferFcn;
% % % % % %                         MracNet.layers{ 4,1 }.transferFcn = NetC.layers{ 2,1 }.transferFcn;
% % % % % 
% % % % %                         % Match output properties
% % % % %                         MracNet.outputs{ 1,4 }.name = 'Ypred';
% % % % %                         MracNet.outputs{ 1,4 }.feedbackMode = NetC.outputs{ 1,2 }.feedbackMode;
% % % % % %                         MracNet.outputs{ 1,4 }.processFcns = {};
% % % % %                         MracNet.outputs{ 1,4 }.processFcns = {'mapminmax'};
% % % % % %                         MracNet.outputs{ 1,4 }.processFcns = NetC.outputs{ 1,2 }.processFcns;
% % % % % 
% % % % %                         MracNet.divideFcn = obj.DivFcn;
% % % % % 
% % % % %                         % Configure the network so that weights and biases of plant model can 
% % % % %                         % be intorduced
% % % % %                         Useq = con2seq( Dat.U );
% % % % %                         Yseq = con2seq( Dat.Y( 1, : ) );
% % % % % 
% % % % %                         % Configure network
% % % % %                         MracNet = configure( MracNet, Useq, Yseq );
% % % % % 
% % % % %                         % Set controller output to zero
% % % % %                         MracNet.LW{ 2,1 } = zeros( size( MracNet.LW{ 2,1 } ) );
% % % % %                         MracNet.b{ 2 } = 0;
% % % % % 
% % % % %                         % Match Biases and Weights
% % % % %                         MracNet.LW{ 3,2 } = NetC.IW{ 1,1 };
% % % % %                         MracNet.LW{ 3,4 } = NetC.LW{ 1,2 };
% % % % %                         MracNet.LW{ 4,3 } = NetC.LW{ 2,1 };
% % % % %                         MracNet.b{ 3,1 } = NetC.b{ 1,1 };
% % % % %                         MracNet.b{ 4,1 } = NetC.b{ 2,1 };
% % % % % 
% % % % %                         % Switch learning in the plant as it is already learnt
% % % % %                         MracNet.layerWeights{ 3,4 }.learn = false;
% % % % %                         MracNet.layerWeights{ 3,2 }.learn = false;
% % % % %                         MracNet.layerWeights{ 4,3 }.learn = false;
% % % % %                         MracNet.biases{ 3,1 }.learn = false;
% % % % %                         MracNet.biases{ 4,1 }.learn = false;
% % % % % 
% % % % %                         MracNet.plotFcns = {'plotperform', 'plotwb', 'plottrainstate', ...
% % % % %                                             'ploterrcorr', 'plotinerrcorr', ...
% % % % %                                             'plotregression', 'plotresponse'};
% % % % %                         MracNet.trainFcn = 'trainlm';
% % % % % 
% % % % %                         MracNet.trainParam.epochs = obj.TrainEpoch;
% % % % %                         MracNet.trainParam.min_grad = 1e-10;
% % % % %                         % MracNet.trainParam.max_fail = 12;
% % % % %                         % MracNet.performFcn = 'mse';
                end
        end
end
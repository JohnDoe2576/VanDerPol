classdef UseModel
        properties
                Net
        end

        methods (Access = public)
                function [ obj ] = UseModel( Net )
                        obj.Net = Net;
                end
                function [ NetC ] = TrainPlant( obj, U, Y )
                        NetT = obj.TrainPlantNeuralNet( obj.Net, U, Y );
                        
                        % Close feedback loop
                        NetC = closeloop( NetT );
                end
                function [ MracNet ] = TrainController( obj, U, Y )
                        MracNet = obj.TrainControllerNeuralNet( obj.Net, U, Y );
                end
                function [ Ypred ] = Simulate( obj, U, Y )
                        Ypred = obj.SimulateNeuralNet( obj.Net, U, Y );
                end
        end
        methods (Access = private, Static)
                function [ NetT ] = TrainPlantNeuralNet( Net, u, y )
                        % Prepare data
                        Useq = con2seq( u );
                        Yseq = con2seq( y(1,:) );
                        [ U, Ui, ~, Y ] = preparets( Net, Useq, {  }, Yseq );

                        % Configure network
                        Net = configure( Net, U, Y );

                        % Train network
                        NetT = train( Net, U, Y, Ui );
                end

                function [ MracNet ] = TrainControllerNeuralNet( MracNet, u, y )
                        % Prepare data
                        Useq = con2seq( u );
                        Yseq = con2seq( y(1,:) );
                        [ U, Ui, Li, Y ] = preparets( MracNet, Useq, {  }, Yseq );

                        % Train network
                        MracNet = train( MracNet, U, Y, Ui, Li );
                end

                function [ Ypred ] = SimulateNeuralNet( Net, u, y )
                        % Prepare data
                        [ U, Ui, Li, ~ ] = preparets( Net, con2seq(u), {  }, con2seq(y(1,:)) );

                        % Simulate data using neural net
                        [ Ypred ] = sim( Net, U, Ui, Li );
                        
                        % Insert initial delayed outputs
                        Delay = max( [ Net.numInputDelays Net.numLayerDelays ] );
                        Ypred = [ y(1,1:Delay) cell2mat(Ypred) ];
                end
        end
end
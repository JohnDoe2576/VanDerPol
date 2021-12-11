classdef MySystem
        properties
                P
                Yo
                Plant
        end

        methods (Access = public)
                function [ obj ] = MySystem( P, Yo, Plant )
                        obj.P = P;
                        obj.Yo = Yo;
                        obj.Plant = Plant;
                end

                function [ X ] = GenPlantOutput( obj, Tspan, U )
                        X0 = obj.Yo; MyPlant = str2func(obj.Plant);
                        [ ~, X ] = ode45( @( T, X ) ...
                                MyPlant( obj, T, X, Tspan, U ), ...
                                Tspan, X0);
                        X = obj.ConvertToRow(X);
                end
        end

        methods (Access = private)

                function [ dXdt ] = RobotArm( obj, T, X, Tspan, U )
                % This function simulates a robotic arm system modelled 
                % a second-order system. Inputs are 
                %       1. Instantaneous Time
                %       2. Instantaneous States
                %       3. Coefficients
                %       4. Time instants at 
                %          which state values 
                %          are required.
                %       5. Input/Control/Forcing signal
                % 
                % The system coefficients are P1, P2 & P3 given as 
                % a vector. They are respectively:
                %       P1: Coefficient of X2 (Velocity)
                %       P2: Coefficient of X1 (Displacement)
                %       P3: Coefficient of U (Input/Control/Forcing)

                                P2 = obj.P(2);
                                P1 = obj.P(1);
                                P3 = obj.P(3);

                                IntU = interp1( Tspan, U, T, 'previous' );

                                dXdt = [ X( 2 ); ...
                                        ( P2 * sin( X( 1 ) ) ) - ( P1 * X( 2 ) ) + ( P3 * IntU ) ];
                end

                function [ dXdt ] = MagLev( obj, T, X, Tspan, U )
                % This function simulates a Magnetic Levitation System 
                % modelled as a second ordered system. The system has 
                % coefficients a \alpha, \beta & M which are as follows:
                %       \alpha: Field strength constant
                %       \beta: Viscous friction constant
                %       M: Mass of levitating ball (magnet)

                        % Extracting coefficients
                        g = 9.8;
                        alfa = obj.P(1);
                        beta = obj.P(2);
                        M = obj.P(3);

                        IntU = interp1( Tspan, U, T, 'previous' );

                        dXdt = [ X( 2 );...
                                 -g + ( ( alfa / M ) * ( IntU * IntU * sign( IntU ) / X( 1 ) ) ) ...
                                                                        - ( ( beta / M ) * X( 2 ) ) ];

                end

                function [ dXdt ] = VanDerPol( obj, T, X, Tspan, U )
                % Simulates Van Der Pol equations 
                % Inputs are 
                %       1. Instantaneous Time
                %       2. Instantaneous States
                %       3. Coefficients
                %       4. Time instants at 
                %          which state values 
                %          are required.
                %       5. Input/Control/Forcing signal
                % 
                % The system coefficients are P1, P2 & P3 given as 
                % a vector. They are respectively:
                %       P1: Coefficient of X2 (Velocity)
                %       P2: Coefficient of X1 (Displacement)
                %       P3: Coefficient of U (Input/Control/Forcing)


                        % Extract coefficients
                        P1 = obj.P(1);
                        P2 = obj.P(2);
                        P3 = obj.P(3);

                        IntU = interp1( Tspan, U, T, 'previous' );

                        dXdt = [ X(2);
                                 ( P3*IntU ) - ( P1*(X(1)^2 - 1)*X(2) ) - ( P2*X(1) ) ];

                end

                function [ dXdt ] = TrackingSys( obj, T, X, Tspan, U )
                % This function simulates a second-order system usually 
                % used controller tracking purposes. Inputs are 
                %       1. Instantaneous Time
                %       2. Instantaneous States
                %       3. Coefficients
                %       4. Time instants at 
                %          which state values 
                %          are required.
                %       5. Input/Control/Forcing signal
                % 
                % The system coefficients are P1, P2 & P3 given as 
                % a vector. They are respectively:
                %       P1: Coefficient of X2 (Velocity)
                %       P2: Coefficient of X1 (Displacement)
                %       P3: Coefficient of U (Input/Control/Forcing)

                        P2 = obj.P(2);
                        P1 = obj.P(1);
                        P3 = obj.P(3);

                        IntU = interp1( Tspan, U, T, 'previous' );

                        dXdt = [ X( 2 ); ...
                                ( P2 * X( 1 ) ) - ( P1 * X( 2 ) ) + ( P3 * IntU ) ];

                end
        end

        methods (Access = private, Static)
                function [ X ] = ConvertToRow( X )
                        [  r, c ] = size(X);
                        if r > c
                                X = X.';
                        end
                end
        end
end
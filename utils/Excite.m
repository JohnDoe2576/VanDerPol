classdef Excite
        properties
                Tstart
                dt
                Tend
        end
        methods (Access = public)
                function obj = Excite( Tstart, dt, Tend )
                        obj.Tstart = Tstart;
                        obj.dt = dt;
                        obj.Tend = Tend;
                end
                function [ T, U, Y ] = None( obj )
                        T = GenTimeVector( obj );
                        U = zeros( size(T) );
                        Y = zeros( 2, size(T,2) );
                end
                function [ T, U ] = Skyline( obj, Tau, Alpha )
                        Tau = round( Tau/obj.dt );
                        T = GenTimeVector( obj );
                        U = obj.GenSkyline( length(T), Tau, Alpha );
                        T = obj.ConvertToRow(T);
                        U = obj.ConvertToRow(U);
                end
                function [ T, U ] = Sine( obj, a, w )
                        T = GenTimeVector( obj );
                        U = a*sin(w*T);
                end
        end
        methods (Access = private)
                function [ T ] = GenTimeVector( obj )
                        T = obj.Tstart:obj.dt:obj.Tend;
                end
        end
        methods (Access = private, Static)

                function [ Signal ] = GenSkyline( N, Tau, Alpha )

                        % Extract data
                        TauUmin = Tau(1);
                        TauUmax = Tau(2);
                        AlphaUmin = Alpha(1);
                        AlphaUmax = Alpha(2);

                        % Initialize a few arrays
                        TauArray = zeros(1, N);
                        AlphaArray = zeros(1, N);
                        Signal = zeros(1, N);

                        TauRange = TauUmax - TauUmin;
                        AlphaRange = AlphaUmax - AlphaUmin;

                        Total = 0; count = 0;
                        while Total < N
                                count = count + 1;
                                TauArray(count) = fix( rand * TauRange + TauUmin );
                                Total = Total + TauArray(count);
                                AlphaArray(count) = rand * AlphaRange + AlphaUmin;
                        end

                        TauArray(count) = TauArray(count) - (Total - N);
                        num_w = count;

                        Start = 0;
                        for count=1:num_w
                                Signal(Start+(1:TauArray(count))) = AlphaArray(count);
                                Start = Start + TauArray(count);
                        end
                end
                
                function [ X ] = ConvertToRow( X )
                        [  r, c ] = size(X);
                        if r > c
                                X = X.';
                        end
                end
        end
end
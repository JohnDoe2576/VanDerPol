classdef PlotData
        properties (Access = public)
                Dat
                Fn = "Garamond"
                Fs = 14
        end

        methods (Access = public)
                function [ obj ] = PlotData( varargin )
                        obj.Dat = varargin{1};
                        if nargin > 1
                                obj.Fn = varargin{2};
                        end
                        if nargin > 2
                                obj.Fs = varargin{2};
                        end
                end
                
                function [  ] = InputOutput( obj, Name )
                        T = obj.Dat.T;
                        U = obj.Dat.U;
                        Y = obj.Dat.Y(1,:);
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Input - Output Data' );
                        stairs( T, U, 'Color', Clr.crimson, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold on; grid on; box on;
                        plot( T, Y, 'Color', Clr.dodger_blue, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );
                        
%                         xlim([ 800 1600 ]);
                        xlim( [ min( T ) max( T ) ] );
                        ylim( obj.Yband( [U; Y], 1.5 ) );
                        
                        legend( '$u$', '$y$', 'Interpreter', 'Latex' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set(legend, 'Box', 'Off');
                        
                        title( Name );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end

                function [  ] = CompareOLandCLwithActual( obj, Name )
                        T = obj.Dat.T;
                        Y = obj.Dat.Y(1,:);
                        Ypred = obj.Dat.Ypred;
                        YpredOL = obj.Dat.YpredOL;
                        
                        Eol = Y - YpredOL;
                        Ecl = Y - Ypred;
                        RMSEol = sqrt( mean( Eol.^2 ) )/std( Y );
                        RMSEcl = sqrt( mean( Ecl.^2 ) )/std( Y );
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Comparing open-loop, closed-loop & actual data' );
                        hold on; grid on; box on;
                        plot( T, YpredOL, 'Marker', 'o', 'MarkerSize', 5.0, ...
                                'MarkerFaceColor', Clr.white, ...
                                'MarkerEdgeColor', Clr.medium_purple, ...
                                'LineStyle', 'None');
                        plot( T, Ypred, 'Marker', 'o', 'MarkerSize', 4.0, ...
                                'MarkerFaceColor', Clr.medium_sea_green, ...
                                'MarkerEdgeColor', Clr.white, ...
                                'LineStyle', 'None' );
                        plot( T, Y, 'Color', Clr.crimson, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );

                        xlim( [ min( T ) max( T ) ] );
                        ylim( obj.Yband( [Y; YpredOL; Ypred], 1.6 ) );

                        TextX = min(T) + 0.1*max(T);
                        TextY = obj.Yband( [Y; YpredOL; Ypred], 1.3 );
                        text( TextX, TextY(2), [ 'RMSE_{\itol}: ' num2str(RMSEol) ], ...
                                'FontName', obj.Fn, 'FontSize', obj.Fs );
                        TextX = min(T) + 0.5*max(T);
                        text( TextX, TextY(2), [ 'RMSE_{\itcl}: ' num2str(RMSEcl) ], ...
                                'FontName', obj.Fn, 'FontSize', obj.Fs );

                        legend( '$\hat{y}_{ol}$', ...
                                '$\hat{y}_{cl}$', ...
                                '$y$', 'Interpreter', 'Latex' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set( legend, 'Box', 'Off' );
                        
                        title( Name );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end

                function [  ] = CompareCLwithActual( obj, Name )
                        T = obj.Dat.T;
                        Y = obj.Dat.Y(1,:);
                        Ypred = obj.Dat.Ypred(1,:);
                        
                        Ecl = Y - Ypred;
                        RMSE = sqrt( mean( Ecl.^2 ) )/std( Y );
                        
%                         T = obj.Dat.T(1,6001:8001);
%                         Y = obj.Dat.Y(1,6001:8001);
%                         Ypred = obj.Dat.Ypred(1,6001:8001);
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Comparing closed-loop & actual data' );
                        hold on; grid on; box on;
                        plot( T, Ypred, 'Marker', 'o', 'MarkerSize', 4.0, ...
                                'MarkerFaceColor', Clr.light_sky_blue, ...
                                'MarkerEdgeColor', Clr.light_sky_blue, ...
                                'LineStyle', 'None');
                        plot( T, Y, 'Color', Clr.brick_red, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );

%                         xlim([ 0 150 ]);
                        xlim( [ min( T ) max( T ) ] );
                        ylim( obj.Yband( [Y; Ypred], 1.6 ) );

                        TextX = min(T) + 0.1*max(T);
                        TextY = obj.Yband( [Y; Ypred], 1.3 );
                        text( TextX, TextY(2), [ 'RMSE: ' num2str(RMSE) ], ...
                                'FontName', obj.Fn, 'FontSize', obj.Fs );

                        legend( '$\hat{y}_{cl}$', '$y$', 'Interpreter', 'Latex' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set( legend, 'Box', 'Off' );
                        
                        title( Name );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end

                function [  ] = CompareInLoopAndNoLoop( obj, Name )
                        T = obj.Dat.T;
                        Y = obj.Dat.Y(1,:);
                        Ypred = obj.Dat.Ypred(1,:);
                        
                        Ecl = Y - Ypred;
                        RMSE = sqrt( mean( Ecl.^2 ) )/std( Y );
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Comparing no-loop & in-loop' );
                        hold on; grid on; box on;
                        plot( T, Ypred, 'Marker', 'o', 'MarkerSize', 4.0, ...
                                'MarkerFaceColor', Clr.light_sky_blue, ...
                                'MarkerEdgeColor', Clr.light_sky_blue, ...
                                'LineStyle', 'None');
                        plot( T, Y, 'Color', Clr.brick_red, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );

                        xlim( [ min( T ) max( T ) ] );
                        ylim( obj.Yband( [Y; Ypred], 1.6 ) );
                        
                        TextX = min(T) + 0.1*max(T);
                        TextY = obj.Yband( [Y; Ypred], 1.3 );
                        text( TextX, TextY(2), [ 'RMSE_{\itcl}: ' num2str(RMSE) ], ...
                                'FontName', obj.Fn, 'FontSize', obj.Fs );

                        legend( 'y_{no-loop}', 'y_{in-loop}' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set( legend, 'Box', 'Off' );
                        
                        title( Name );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );

                        Fh = figure( 'Name', 'Error b/w no-loop and in-loop' );
                        hold on; grid on; box on;
                        
                        plot( T, Y-Ypred, 'Color', Clr.crimson, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        xlabel( 't [s]' );

                        xlim( [ min( T ) max( T ) ] );
%                         ylim( obj.Yband( Y-Ypred, 1.6 ) );
                        
                        title( "Error b/w no-loop and in-loop" );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end

                function [  ] = InputAndPredictedOutput( obj, Name )
                        T = obj.Dat.T;
                        U = obj.Dat.U;
                        Y = obj.Dat.Ypred;
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Input and Predicted output' );
                        stairs( T, U, 'Color', Clr.crimson, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold on; grid on; box on;
                        plot( T, Y, 'Color', Clr.dodger_blue, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );
                        
                        xlim( [ min( T ) max( T ) ] );
                        ylim( obj.Yband( [U; Y], 1.6 ) );
                        
                        legend( '$u$', '$\hat{y}_{cl}$', 'Interpreter', 'Latex' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set( legend, 'Box', 'Off' );
                        
                        title( Name );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end

                function [  ] = PlantAndReferenceInput( obj, Name )
                        T = obj.Dat.T;
                        U = obj.Dat.U;
                        Yr = obj.Dat.Yr;
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Plant input and Reference input' );
                        stairs( T, U, 'Color', Clr.crimson, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold on; grid on; box on;
                        plot( T, Yr, 'Color', Clr.dodger_blue, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );
                        
                        xlim( [ min( T ) max( T ) ] );
                        ylim( obj.Yband( [U; Yr], 1.5 ) );
                        
                        legend( 'Plant input, \itu', 'Ref. input, \ity_{r}' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set(legend, 'Box', 'Off');
                        
                        title( Name );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end

                function [  ] = ControllerOutput( obj, Name )
                        T = obj.Dat.T;
                        U = obj.Dat.U;
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Controller output' );
                        stairs( T, U, 'Color', Clr.medium_sea_green, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        grid on; box on;
                        xlabel( 't [s]' );
                        
                        xlim( [ min( T ) max( T ) ] );
%                         xlim([ 20 50 ]);
%                         ylim([ -10 10 ]);
                        ylim( obj.Yband( U, 1.5 ) );
                        
                        title( "Controller output" );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end
                
                function [  ] = ControlledSimulationFull( obj, Name )
                        T = obj.Dat.T;
                        U = obj.Dat.U;
                        Y = obj.Dat.Y;
                        Yr = obj.Dat.Yr;
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Control ON' );
                        stairs( T, U, 'Color', Clr.crimson, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold on; grid on; box on;
                        stairs( T, Yr, 'Color', Clr.medium_sea_green, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        plot( T, Y(1,:), 'Color', Clr.dodger_blue, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );
                        
                        xlim( [ min( T ) max( T ) ] );
                        ylim( obj.Yband( [U Yr Y(1,:)], 1.5 ) );
                        
                        legend( '$u$', ...
                                '$r$', ...
                                '$y$', 'Interpreter', 'Latex' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set(legend, 'Box', 'Off');
                        
                        title( " " );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end

                function [  ] = ControlledSimulation( obj, Name )
                        T = obj.Dat.T;
                        U = obj.Dat.U;
                        Y = obj.Dat.Y;
                        Yr = obj.Dat.Yr;
                        
                        idx = find(Yr ~= 0);
                        idx = idx(1);
                        
                        T1 = T(1,1:idx-1); T2 = T(1,idx:end);
                        U1 = U(1,1:idx-1); Yr2 = Yr(1,idx:end);
                        Y1 = Y(1,1:idx-1); Y2 = Y(1,idx:end);
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Control OFF' );
                        stairs( T1, U1, 'Color', Clr.crimson, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold on; grid on; box on;
                        plot( T1, Y1, 'Color', Clr.dodger_blue, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );
                        
                        xlim( [ min( T1 ) max( T1 ) ] );
                        ylim( obj.Yband( [U1 Y1], 1.5 ) );
                        
                        legend( '$r$', ...
                                '$y$', 'Interpreter', 'Latex' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set(legend, 'Box', 'Off');
                        
                        title( "Control OFF" );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );

                        Fh = figure( 'Name', 'Control ON' );
                        stairs( T2, Yr2, 'Color', Clr.medium_sea_green, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold on; grid on; box on;
                        plot( T2, Y2, 'Color', Clr.medium_purple, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );
                        
                        xlim( [ min( T2 ) max( T2 ) ] );
                        ylim( obj.Yband( [Yr2 Y2], 1.5 ) );
                        
                        legend( '$r$', ...
                                '$y$', 'Interpreter', 'Latex' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set(legend, 'Box', 'Off');
                        
                        title( "Control ON" );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end
                
                function [  ] = ControlledSimulationYandYr( obj )
                        T = obj.Dat.T;
                        Y = obj.Dat.Y(1,:);
                        Yr = obj.Dat.Yr;
                        
%                         idx = find(Yr ~= 0);
%                         idx = idx(1);
                        
                        Clr = obj.LoadColors();
                        
                        Fh = figure( 'Name', 'Control OFF' );
                        stairs( T, Yr, 'Color', Clr.crimson, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold on; grid on; box on;
                        plot( T, Y, 'Color', Clr.dodger_blue, ...
                                'LineStyle', '-', 'LineWidth', 0.8 );
                        hold off; xlabel( 't [s]' );
                        
                        xlim( [ min( T ) max( T ) ] );
                        ylim( obj.Yband( [Y Yr], 1.5 ) );
                        
                        legend( '$r$', ...
                                '$y$', 'Interpreter', 'Latex' );
                        set( legend, 'Location', 'South' );
                        set( legend, 'Orientation', 'Horizontal');
                        set(legend, 'Box', 'Off');
                        
                        title( [ 'One sample at a time mode: ' ... 
                                'controller switched ON at ' ...
                                num2str(20) 's'] );
                        
                        obj.FigDefaults( Clr, Fh, obj.Fn, obj.Fs );
                end
        end

        methods (Access = private, Static)
                function [ clr ] = LoadColors(  )
                        clr.my_grey = [245 245 245]/255;
                        clr.muted_blue = [31, 119, 180]/255;
                        clr.safety_orange = [255, 127, 14]/255;
                        clr.cooked_asparagus_green = [44, 160, 44]/255;
                        clr.brick_red = [214, 39, 40]/255;
                        clr.muted_purple = [148, 103, 189]/255;
                        clr.chestnut_brown = [140, 86, 75]/255;
                        clr.raspberry_yogurt_pink = [227, 119, 194]/255;
                        clr.middle_grey = [127, 127, 127]/255;
                        clr.curry_yellow_green = [188, 189, 34]/255;
                        clr.blue_teal = [23, 190, 207]/255;

                        clr.SeqGnBu3 = [ 168, 221, 181 ] / 255;
                        clr.SeqGreens2 = [ 199, 233, 192 ] / 255;
                        clr.SeqBuGn4 = [ 102, 194, 164 ] / 255;
                        clr.SeqBuGn5 = [ 65, 174, 118 ] / 255;
                        clr.SeqBuGn7 = [ 0, 109, 44 ] / 255;
                        clr.SeqPuBuGn1 = [ 236, 226, 240 ] / 255;
                        clr.SeqPuBuGn3 = [ 166, 189, 219 ] / 255;
                        clr.SeqPuBuGn4 = [ 103, 169, 207 ] / 255;
                        clr.SeqPuBuGn7 = [ 1, 108, 89 ] / 255;
                        clr.SeqRdBu5 = [ 247, 247, 247 ] / 255;
                        clr.SeqRdBu6 = [ 209, 229, 240 ] / 255;

                        clr.CyclicalPhase6 = [ 95, 127, 228 ] / 255;            % Bland Blue
                        clr.CyclicalTwilight6 = [ 142, 44, 80 ] / 255;           % Mat purple

                        clr.light_sky_blue = [ 135, 206, 250 ]/255;
                        clr.medium_purple = [ 147, 112, 219 ]/255;
                        clr.slate_blue = [ 106, 90, 205 ]/255;
                        clr.dodger_blue = [ 30, 144, 255 ]/255;
                        clr.medium_sea_green = [ 60, 179, 113 ]/255;
                        clr.fire_brick = [ 178, 34, 34 ]/255;
                        clr.crimson = [ 220, 20, 60 ]/255;
                        clr.white = [ 255, 255, 255 ]/255;
                end
                
                function [  ] = FigDefaults( clr, Fh, Fn, Fs, Bh, Ph )
                        Fh.Units = "centimeters";
%                         Fh.Position = [ 2.5 6 36 8 ];  % Entire slide
                        Fh.Position = [ 10 7 24 8 ]; % 3/4 of slide
%                         Fh.Position = [ 3 3 24 8 ]; % 3/4 of slide
                        Fh.Color = 'w';
                        
                        % Axis properties
                        Ax = Fh.CurrentAxes;
                        Ax.FontName = Fn; Ax.FontSize = Fs;
                        % AxHdl.TitleFontWeight = 'normal';
                        Ax.TitleFontSizeMultiplier = 1.0;
                        Ax.LabelFontSizeMultiplier = 1.0;
                        Ax.Color = clr.my_grey; Ax.GridColor = 'w';
                        Ax.XColor = 'k';
                        Ax.YColor = 'k';
                        Ax.ZColor = 'k';
                        Ax.LineWidth = 0.4; Ax.GridAlpha = 1;

                        if nargin > 4
                        %         BarAx = Bh.Parent;
                                Bh.BarWidth = 0.0;
                                Bh.FaceColor = clr.SeqPuBuGn7;
                                Bh.FaceAlpha = 1.0;
                                Bh.EdgeColor = clr.SeqPuBuGn7;
                                Bh.LineWidth = 1.2;
                        end

                        if nargin > 5
                                Ph.FaceColor = clr.SeqPuBuGn4;
                                Ph.FaceAlpha = 0.3;
                                Ph.EdgeColor = 'none';
                        %         PthHdl.EdgeAlpha = 0.5;
                        end
                end
                
                function [ MyLim ] = Yband( X, BoundScale )
                        MinBnd = min(min( X, [], 2 ));
                        MaxBnd = max(max( X, [], 2 ));
                        Mn = mean( [ MinBnd MaxBnd ] );
                        Bnd = BoundScale * ( MaxBnd - Mn );
%                         Bnd = BoundScale * max( abs( [ MinBnd MaxBnd ] ) );
                        MinBnd = Mn - Bnd;
                        MaxBnd = Mn + Bnd;
                        MyLim = [ MinBnd MaxBnd ];
                end
        end
end
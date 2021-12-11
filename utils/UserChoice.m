classdef UserChoice
        properties
                Plant = ""
                DataFolder = ""

                ReadNumber = "1"
                SaveNumber = "1"

                GenerateDataOnly = false
                GeneratePlantDataOnly = false
                GenerateControllerDataOnly = false
                GeneratePlantModelOnly = false

                HaveInputOutputData = false
                HavePlantModel = false
                HaveControllerModel = false

                SaveGenData = false
                SaveTrainedPlantModel = false
                SaveTrainedControllerModel = false

                SavePlantSimData = false
                SaveControllerSimData = false

                PlotGeneratedData = false
                SimulatePlantUsingModel = false
                SimulateControllerUsingModel = false
                
                CompareActualAndModelPlant = false;
                SimulateControllerCoupledToActualPlant = false;
                SaveUltimateSimulationData = false;
        end
        methods
                function [ TrainP, TestP, TrainC, TestC ] = ReadGeneratedData( obj )
                        M = matfile(strcat(obj.DataFolder, "/", ...
                                obj.Plant, num2str(obj.ReadNumber), ".mat" ));
                        TrainP = M.TrainP; TestP = M.TestP;
                        TrainC = M.TrainC; TestC = M.TestC;
                end
                function [ ModelP ] = ReadPlantModel( obj )
                        M = matfile(strcat(obj.DataFolder, "/", ...
                                obj.Plant, num2str(obj.ReadNumber), ".mat" ));
                        ModelP = M.ModelP;
                end
                function [ ModelC ] = ReadControllerModel( obj )
                        M = matfile(strcat(obj.DataFolder, "/", ...
                                obj.Plant, num2str(obj.ReadNumber), ".mat" ));
                        ModelC = M.ModelC;
                end
                function [  ] = SaveGeneratedData( obj, TrainP, TestP, TrainC, TestC )
                        if obj.SaveGenData == true
                                disp("Do you want to save generated data?");
                                prompt = "(Type Yes or No and press Return key) ";
                                Choice = input( prompt, 's' );
                                if strcmpi(Choice, "Yes")
                                      M = matfile(strcat(obj.DataFolder, "/", ...
                                              obj.Plant, num2str(obj.SaveNumber), ...
                                              ".mat" ), 'Writable', true);
                                      M.TrainP = TrainP; M.TestP = TestP;
                                      M.TrainC = TrainC; M.TestC = TestC;
                                end
                                disp(" ");
                        end
                end
                function [  ] = SavePlantModel( obj, ModelP )
                        if obj.SaveTrainedPlantModel == true
                                disp("Do you want to save trained plant model?");
                                prompt = "(Type Yes or No and press Return key) ";
                                Choice = input( prompt, 's' );
                                if strcmpi(Choice, "Yes")
                                      M = matfile(strcat(obj.DataFolder, "/", ...
                                              obj.Plant, num2str(obj.SaveNumber), ...
                                              ".mat" ), 'Writable', true);
                                      M.ModelP = ModelP;
                                end
                                disp(" ");
                        end
                end
                function [  ] = SaveControllerModel( obj, ModelC )
                        if obj.SaveTrainedControllerModel == true
                                disp("Do you want to save trained controller model?");
                                prompt = "(Type Yes or No and press Return key) ";
                                Choice = input( prompt, 's' );
                                if strcmpi(Choice, "Yes")
                                      M = matfile(strcat(obj.DataFolder, "/", ...
                                              obj.Plant, num2str(obj.SaveNumber), ...
                                              ".mat" ), 'Writable', true);
                                      M.ModelC = ModelC;
                                end
                                disp(" ");
                        end
                end
                function [  ] = SaveSimulatedPlantData( obj, TrainP, TestP )
                        if obj.SavePlantSimData == true
                                disp("Do you want to save simulated plant data?");
                                prompt = "(Type Yes or No and press Return key) ";
                                Choice = input( prompt, 's' );
                                if strcmpi(Choice, "Yes")
                                      M = matfile(strcat(obj.DataFolder, "/", ...
                                              obj.Plant, num2str(obj.SaveNumber), ...
                                              ".mat" ), 'Writable', true);
                                      M.TrainP = TrainP;
                                      M.TestP = TestP;
                                end
                                disp(" ");
                        end
                end
                function [  ] = SaveSimulatedControllerData( obj, TrainC, TestC )
                        if obj.SaveControllerSimData == true
                                disp("Do you want to save simulated controller data?");
                                prompt = "(Type Yes or No and press Return key) ";
                                Choice = input( prompt, 's' );
                                if strcmpi(Choice, "Yes")
                                      M = matfile(strcat(obj.DataFolder, "/", ...
                                              obj.Plant, num2str(obj.SaveNumber), ...
                                              ".mat" ), 'Writable', true);
                                      M.TrainC = TrainC;
                                      M.TestC = TestC;
                                end
                                disp(" ");
                        end
                end
                % %%%%%%%%%%%%%%%%%%%%% Dowling Data %%%%%%%%%%%%%%%%%%% %
                function [ TrainP, TestP ] = ReadDowlingData(obj)
                        TrainP = DatStore; TestP = DatStore;
                        if obj.ReadNumber == 1
                                ReadNumber1 = 1;
                                ReadNumber2 = 2;
                        elseif obj.ReadNumber == 2
                                ReadNumber1 = 2;
                                ReadNumber2 = 1;
                        end
                        M1 = matfile(strcat(obj.DataFolder, "/", ...
                                obj.Plant, num2str(ReadNumber1), ".mat" ));
                        M2 = matfile(strcat(obj.DataFolder, "/", ...
                                obj.Plant, num2str(ReadNumber2), ".mat" ));
                        T1 = M1.T; U1 = M1.U; Y1 = M1.Y;
                        T2 = M2.T; U2 = M2.U; Y2 = M2.Y;
                
                        idx1 = 1+(0:1:(length(T1)-1));
                        TrainP.T = T1(1,idx1);
                        TrainP.U = U1(1,idx1);
                        TrainP.Y = Y1(1,idx1);
                        
                        idx2 = 1+(0:1:(length(T2)-1));
                        TestP.T = T2(1,idx2);
                        TestP.U = U2(1,idx2);
                        TestP.Y = Y2(1,idx2);
                end
        end
end
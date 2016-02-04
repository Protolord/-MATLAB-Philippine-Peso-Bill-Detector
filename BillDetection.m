function varargout = BillDetection(varargin)

%   This GUI program takes an image as an input and uses an image processing
%   algorithm to determine what type of bill the image is.


%   ----------------------   ALGORITHM   ------------------------
%   The algorithm uses 2D correlation to determine the degree of similarity 
%   of  the input image to the reference images stored within the program
%   directory. Correlation is performed between the input image and 
%   all the reference images in the software database found under the
%   Reference Image folder. Then the index with the highest correlation
%   values is obtained and this determine the type of bill the image is.
%   If the highest correlation value is less than the threshold, the image
%   will be inconclusive. Corresponding sound is played after the image
%   is full analyzed.



% Last Modified by GUIDE v2.5 04-Feb-2016 15:25:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BillDetection_OpeningFcn, ...
                   'gui_OutputFcn',  @BillDetection_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before BillDetection is made visible.
function BillDetection_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for BillDetection
handles.output = hObject;

%======================================================================
%========================== INITIALIZATION ============================
%======================================================================
%Do not display anything on the axis initially 
set(handles.imgDisplay,'xtick',[],'ytick',[]);
%Initially hide the analysis static text
set(handles.analysisTitle, 'Visible', 'Off');
set(handles.analysis, 'Visible', 'Off');
%Initialize the resources to be used in image correlation
global imgCell;
global sndCell;
global values;
img_peso20 = rgb2gray(imread('Reference Images/peso20.jpg'));
img_peso50 = rgb2gray(imread('Reference Images/peso50.jpg'));
img_peso100 = rgb2gray(imread('Reference Images/peso100.jpg'));
img_peso200 = rgb2gray(imread('Reference Images/peso200.jpg'));
img_peso500 = rgb2gray(imread('Reference Images/peso500.jpg'));
img_peso1000 = rgb2gray(imread('Reference Images/peso1000.jpg'));
snd_peso20 = wavread('Sounds/peso20.wav');
snd_peso50 = wavread('Sounds/peso50.wav');
snd_peso100 = wavread('Sounds/peso100.wav');
snd_peso200 = wavread('Sounds/peso200.wav');
snd_peso500 = wavread('Sounds/peso500.wav');
snd_peso1000 = wavread('Sounds/peso1000.wav');
imgCell = {img_peso20, img_peso50, img_peso100, img_peso200, img_peso500, img_peso1000};
sndCell = {snd_peso20, snd_peso50, snd_peso100, snd_peso200, snd_peso500, snd_peso1000};
values = [20, 50, 100, 200, 500, 1000];
%Initialize the reference number for optical character recognition

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = BillDetection_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% --- Executes on button press in browse.
function browse_Callback(hObject, eventdata, handles)
% hObject    handle to browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global analysisValue;
global imgCell; 
global sndCell;
global values;
global corrValues;
[filename pathname] = uigetfile({'*.jpg;*.bmp;*.png'},'Browse Image');
image = imread(strcat(pathname, filename));
axes(handles.imgDisplay);
imshow(image);

%======================================================================
%======================== IMAGE PROCESSING ============================
%======================================================================
%Process the image including removal of white spaces, resizing and 
%converting to grayscale
corrTest = RemoveWhiteSpace(image);       % remove white border, duh
corrTest = rgb2gray(corrTest);            % remove one dimension of the image
corrTest = imresize(corrTest, [245 600]); % to match the reference images
%imshow(corrTest);

%======================================================================
%======================== IMAGE CORRELATION ===========================
%======================================================================
%Apply 2D correlation to each reference image to determine what bill
%it matches the most. Time complexity is O(n).
corrValues = [];    %The array consisting of the correlation values per index
for n=1:6  %There are 6 Philippine Peso bills
    corrValue = corr2(corrTest, imgCell{n});
    corrValues = [corrValues, corrValue];  %Add the value to the array
end
index = find(corrValues==max(corrValues));  %Find the index with the highest value
%If the correlation result is higher than the threshold
if corrValues(index) > str2double(get(handles.thresholdValue, 'String'))
    value = values(index);
else
    value = 0;
end
%Make the analysis visible
set(handles.analysisTitle, 'Visible', 'On');
set(handles.analysis, 'Visible', 'on');

%analysisValue is the string to be displayed
if value > 0 
    analysisValue = strcat('The image was detected to be a', {' '}, num2str(value), ' peso bill ');
else
    analysisValue = 'The image cannot be determined';
end
set(handles.analysis, 'String', analysisValue);
pause(0.1);
%------------- PLAY SOUND ----------------
if value > 0
    wavplay(sndCell{index}, 44100);
end



function analysis_Callback(hObject, eventdata, handles)
global analysisValue;
set(handles.analysis, 'String', analysisValue);

% --- Executes during object creation, after setting all properties.
function analysis_CreateFcn(hObject, eventdata, handles)


function thresholdValue_Callback(hObject, eventdata, handles)
if isnan(str2double(get(handles.thresholdValue, 'String')))
    set(handles.thresholdValue, 'String', '0.4');
end


% --- Executes during object creation, after setting all properties.
function thresholdValue_CreateFcn(hObject, eventdata, handles)


%=========================================================================
%================== UI TABLE OF CORRELATION COEFFICIENTS  ================
%=========================================================================
function viewCorr2_Callback(hObject, eventdata, handles)
global corrValues;
y = [];
for n=1:6
    y = [y; corrValues(n)];
end
f = figure('Name', 'Correlation Coefficients', 'Position',[480 300 330 330]);
cnames = {'Correlation Coefficient'};
rnames = {'P20', 'P50', 'P100', 'P200', 'P500', 'P1000'};
t = uitable(f,'data', y, 'columnname', cnames, 'rowname', rnames', 'fontsize', 20);
set(t, 'columnwidth', {230});

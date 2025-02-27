function fShow(func,varargin)
switch(func)
    case 'Image'
        ShowImage;
    case 'Tracks'
        ShowTracks;
    case 'OffsetMap'
        ShowOffsetMap(varargin{1});        
    case 'Marker'
        ShowMarker(varargin{1},varargin{2});   
    case 'SelectChannel'
        SelectChannel(varargin{1});
end

function ShowImage
global Stack;
global Config;
hMainGui=getappdata(0,'hMainGui');
if ~isempty(Stack)
    y=size(Stack{1},1);
    x=size(Stack{1},2);
    stidx=hMainGui.Values.FrameIdx(1);
    if length(hMainGui.Values.FrameIdx)>2
        idx=hMainGui.Values.FrameIdx(stidx+1);
    else
        idx=hMainGui.Values.FrameIdx(2);
    end
    if idx>0
        if strcmp(get(hMainGui.ToolBar.ToolChannels(5),'State'),'off')&& ~(strcmp(get(hMainGui.ToolBar.ToolThreshImage,'State'),'on')&&~isempty(hMainGui.Values.PostSpecial))
            Image=double(Stack{stidx}(:,:,idx));
        else
            for n = 1:length(hMainGui.Values.StackColor)
                t = min([n+1 length(hMainGui.Values.FrameIdx)]);
                idx(n) = hMainGui.Values.FrameIdx(t);
                Image(:,:,n)=double(Stack{n}(:,:,idx(n))); 
            end
            stidx = 1:hMainGui.Values.MaxIdx(1);
        end   
    else
        switch(idx)
            case {-1,-4} %Maximum or objects profection
                Image = double(getappdata(hMainGui.fig,'MaxImage'));
                if strcmp(get(hMainGui.ToolBar.ToolChannels(5),'State'),'off')
                    Image = Image(:,:,stidx);
                else
                    stidx = 1:hMainGui.Values.MaxIdx(1);
                end
            case -2 %Average
                Image=double(getappdata(hMainGui.fig,'AverageImage'));
                if strcmp(get(hMainGui.ToolBar.ToolChannels(5),'State'),'off')
                    Image = Image(:,:,stidx);
                else
                    stidx = 1:hMainGui.Values.MaxIdx(1);
                end
            case -3   
                if strcmp(get(hMainGui.ToolBar.ToolNormImage,'State'),'on') && ~strcmp(get(hMainGui.ToolBar.ToolChannels(5),'State'),'on')
                    Image=zeros(y,x,3);
                    MaxImage = getappdata(hMainGui.fig,'MaxImage');
                    Image(:,:,1)=MaxImage(:,:,stidx);
                    Image(:,:,2)=Image(:,:,1);
                    Image(:,:,3)=Image(:,:,1);
                    Image(:,:,1)=double(Stack{stidx}(:,:,1));
                    Image(:,:,2)=double(Stack{stidx}(:,:,end));
                else
                    Image = double(Stack{stidx}(:,:,1));
                end
        end
    end
    if (strcmp(get(hMainGui.Menu.mAlignChannels,'Checked'),'on')&&strcmp(get(hMainGui.Menu.mAlignChannels,'Enable'),'on'))||(strcmp(get(hMainGui.ToolBar.ToolThreshImage,'State'),'on')&&~isempty(hMainGui.Values.PostSpecial)&&~strcmp(get(hMainGui.ToolBar.ToolChannels(5),'State'),'on'))
        for n = 1:length(stidx)
            if stidx(n)>1
                T = hMainGui.Values.TformChannel{stidx(n)};
                Image(:,:,n) = quickwarp(Image(:,:,n),T,0);
            end
            if hMainGui.Values.FrameIdx(1)>1 && ~strcmp(get(hMainGui.Menu.mAlignChannels,'Checked'),'on') && strcmp(get(hMainGui.ToolBar.ToolThreshImage,'State'),'on')&&~isempty(hMainGui.Values.PostSpecial)
                T = hMainGui.Values.TformChannel{hMainGui.Values.FrameIdx(1)};
                Image(:,:,n) = quickwarp(Image(:,:,n),T,1);
            end
        end
    end
    if strcmp(get(hMainGui.ToolBar.ToolNormImage,'State'),'on')||strcmp(get(hMainGui.ToolBar.ToolKymoGraph,'State'),'on')
        if size(Image,3)==1
            Image=(Image-hMainGui.Values.ScaleMin(stidx))/(hMainGui.Values.ScaleMax(stidx)-hMainGui.Values.ScaleMin(stidx)+1);
        else
            IRGB = zeros(size(Image,1),size(Image,2),3);
            for n = 1:length(hMainGui.Values.StackColor)
                c = get(hMainGui.ToolBar.ToolColors(hMainGui.Values.StackColor(n)),'CData');
                c = squeeze(c(1,1,1:3));
                Image(:,:,n) = (Image(:,:,n)-hMainGui.Values.ScaleMin(n))/(hMainGui.Values.ScaleMax(n)-hMainGui.Values.ScaleMin(n)+1);
                IRGB(:,:,1) = IRGB(:,:,1)+Image(:,:,n)*c(1);
                IRGB(:,:,2) = IRGB(:,:,2)+Image(:,:,n)*c(2);
                IRGB(:,:,3) = IRGB(:,:,3)+Image(:,:,n)*c(3);
            end
            Image = IRGB;
        end
    elseif strcmp(get(hMainGui.ToolBar.ToolThreshImage,'State'),'on')
        [filter,background] = strtok(Config.Threshold.Filter,'+'); 
        for n = 1:length(idx)
            params = struct('scale',Config.PixSize,'fwhm_estimate',Config.Threshold.FWHM/Config.PixSize,'binary_image_processing',filter,'background_filter',background);
            if strcmp(Config.Threshold.Mode,'variable')==1
                Image(:,:,n) = Image2Binary(Image(:,:,n),params);
            elseif strcmp(Config.Threshold.Mode,'relative')==1
                if idx(n)<0
                    idx(n)=1;
                end
                params.threshold = hMainGui.Values.RelThresh(stidx(n))*1i;
                Image(:,:,n)=Image2Binary(Image(:,:,n),params);
            else
                params.threshold = hMainGui.Values.Thresh(stidx(n));
                Image(:,:,n)=Image2Binary(Image(:,:,n),params);
            end
        end
        if size(Image,3)>1
            IRGB = zeros(size(Image,1),size(Image,2),3);
            for n = 1:length(hMainGui.Values.StackColor)
                c = get(hMainGui.ToolBar.ToolColors(hMainGui.Values.StackColor(n)),'CData');
                c = squeeze(c(1,1,1:3));
                IRGB(:,:,1) = IRGB(:,:,1)+Image(:,:,n)*c(1);
                IRGB(:,:,2) = IRGB(:,:,2)+Image(:,:,n)*c(2);
                IRGB(:,:,3) = IRGB(:,:,3)+Image(:,:,n)*c(3);
            end
            if isempty(hMainGui.Values.PostSpecial) || strcmp(get(hMainGui.ToolBar.ToolChannels(5),'State'),'on')
                Image = IRGB;
            else
                Image = max(IRGB,[],3);
            end
        end
    end
    Image(Image<0)=0;
    Image(Image>1)=1;
    if size(Image,3)==1
       Image=Image*2^16;
    end
    if isempty(hMainGui.Image)
        delete(hMainGui.MidPanel.aView);
        hMainGui.MidPanel.aView = axes('Parent',hMainGui.MidPanel.pView,'ActivePositionProperty','Position','Units','normalized','Visible','on','Position',[0 0 1 1],'Tag','aView','NextPlot','add','YDir','reverse','SortMethod','childorder');
        hMainGui.Image=image(Image,'Parent',hMainGui.MidPanel.aView,'CDataMapping','scaled');
        set(hMainGui.MidPanel.aView,'CLim',[0 65535],'YDir','reverse','NextPlot','add','TickDir','in'); 
        set(hMainGui.fig,'colormap',colormap('Gray'));
    else
        set(hMainGui.Image,'CData',Image);
        hMainGui=SetZoom(hMainGui);
    end
    if max(idx)>0
        ShowMarker(hMainGui,idx)
    end
    if min(idx) == -4 
        ShowAllMarkers(hMainGui)
    end
    if strcmp(get(hMainGui.Menu.mShowOffsetMap,'Checked'),'on')
        ShowOffsetMap(hMainGui);
    end
    set(hMainGui.MidPanel.aView,{'xlim','ylim'},hMainGui.ZoomView.currentXY,'Visible','off');
    if ~isempty(hMainGui.Scan)
        setappdata(0,'hMainGui',hMainGui);        
        fRightPanel('UpdateLineScan',hMainGui);
        hMainGui=getappdata(0,'hMainGui');
    end
end
setappdata(0,'hMainGui',hMainGui);

function ShowAllMarkers(hMainGui)
global Objects;
set(0,'CurrentFigure',hMainGui.fig);
set(hMainGui.fig,'CurrentAxes',hMainGui.MidPanel.aView);
delete(findobj('Parent',hMainGui.MidPanel.aView,'Tag','pObjects'));
XM=[];
XF=[];
for n = 1:length(Objects)
    if isfield(Objects{n},'length') && ~isempty(Objects{n})
        k = Objects{n}.length(1,:) == 0;
        if any(k)
            XM = [XM; double(Objects{n}.center_x(k)')/hMainGui.Values.PixSize double(Objects{n}.center_y(k)')/hMainGui.Values.PixSize];
        end
        if any(~k)
            kFil = find(k==0);
            for m = kFil
                line(Objects{n}.data{m}(:,1)/hMainGui.Values.PixSize,Objects{n}.data{m}(:,2)/hMainGui.Values.PixSize,'Tag','pObjects','Color','r');
            end
            XF = [XF; Objects{n}.center_x(~k)'/hMainGui.Values.PixSize Objects{n}.center_y(~k)'/hMainGui.Values.PixSize];
        end
    end    
end
if ~isempty(XM)
    line(XM(:,1),XM(:,2),'LineStyle','none','Marker','+','Tag','pObjects','Color','g');
end
if ~isempty(XF)
    line(XF(:,1),XF(:,2),'LineStyle','none','Marker','x','Tag','pObjects','Color','g');
end

function ShowMarker(hMainGui,idx)
global Objects;
global Molecule;
global Filament;
global Stack;
if ~isempty(Stack)
    set(0,'CurrentFigure',hMainGui.fig);
    set(hMainGui.fig,'CurrentAxes',hMainGui.MidPanel.aView);
    delete(findobj('Parent',hMainGui.MidPanel.aView,'Tag','pObjects'));
    if ~isempty(Objects)
        if get(hMainGui.RightPanel.pData.cShowAllMol,'Value')||get(hMainGui.RightPanel.pData.cShowAllFil,'Value')
            stidx = getChannels;
            if get(hMainGui.RightPanel.pData.cShowAllMol,'Value'); 
                for nCh = 1:length(stidx)
                    if length(Objects)>=idx(nCh) && isfield(Objects{idx(nCh)},'length') && ~isempty(Objects{idx(nCh)})
                        kMol = find( Objects{idx(nCh)}.length(1,:) == 0 );
                        if ~isempty(kMol)
                            X = ones(2,1) * double(Objects{idx(nCh)}.center_x(kMol)) / hMainGui.Values.PixSize;
                            Y = ones(2,1) * double(Objects{idx(nCh)}.center_y(kMol)) / hMainGui.Values.PixSize;
                            h=line(X,Y,'Marker','+','Tag','pObjects','Color','g');
                            set(h,'UIContextMenu',hMainGui.Menu.ctObjectMol,{'UserData'},num2cell(kMol)');
                        end
                    end
                end
            end
            if get(hMainGui.RightPanel.pData.cShowAllFil,'Value')
                for nCh = 1:length(stidx)
                    if length(Objects)>=idx(nCh) && isfield(Objects{idx(nCh)},'length') && ~isempty(Objects{idx(nCh)})
                        kFil = find( Objects{idx(nCh)}.length(1,:) ~= 0 );
                        if get(hMainGui.RightPanel.pData.cShowWholeFil,'Value')==1
                            for n = kFil
                                line(Objects{idx(nCh)}.data{n}(:,1)/hMainGui.Values.PixSize,Objects{idx(nCh)}.data{n}(:,2)/hMainGui.Values.PixSize,'Tag','pObjects','Color','r');
                            end
                        end
                        if ~isempty(kFil)
                            X = ones(2,1) * Objects{idx(nCh)}.center_x(kFil) / hMainGui.Values.PixSize;
                            Y = ones(2,1) * Objects{idx(nCh)}.center_y(kFil) / hMainGui.Values.PixSize;        
                            h=line(X,Y,'Marker','x','Tag','pObjects','Color','g');
                            set(h,'UIContextMenu',hMainGui.Menu.ctObjectFil,{'UserData'},num2cell(kFil)');
                        end
                    end
                end
            end
        end
    end    
    if ~isempty(Molecule)
        PlotMarker(hMainGui,Molecule,idx);
    end
    if ~isempty(Filament)
        PlotMarker(hMainGui,Filament,idx);
    end
end
   
function PlotMarker(hMainGui,Object,idx)
set(0,'CurrentFigure',hMainGui.fig);
set(hMainGui.fig,'CurrentAxes',hMainGui.MidPanel.aView);
p=1;
X=[];
Y=[];
stidx = getChannels;
for nCh = 1:length(stidx)
    k=find([Object.Visible]==1&[Object.Selected]>-1&[Object.Channel]==stidx(nCh));
    for i=k
        t=find(Object(i).Results(:,1)==idx(nCh),1,'first');
        if ~isempty(t)
            X(p,1:2)=Object(i).Results(t,3)/hMainGui.Values.PixSize; 
            Y(p,1:2)=Object(i).Results(t,4)/hMainGui.Values.PixSize; 
            C{p}=Object(i).Color; 
            N{p}=Object(i).Name; %#ok<*AGROW>
            if get(hMainGui.RightPanel.pData.cShowWholeFil,'Value') && isfield(Object,'Data')
                line(Object(i).Data{t}(:,1)/hMainGui.Values.PixSize,Object(i).Data{t}(:,2)/hMainGui.Values.PixSize,'Tag','pObjects','Color','r');
            end 
            p=p+1;
        end
    end
end
if ~isempty(X)
    h=line(X',Y','Parent',hMainGui.MidPanel.aView,'Marker','.','MarkerSize',20,'Tag','pObjects');
    set(h,{'Color'},C',{'UserData'},N');
end

function ShowTracks
global Molecule;
global Filament;
global Stack;
hMainGui=getappdata(0,'hMainGui');
set(0,'CurrentFigure',hMainGui.fig);
set(hMainGui.fig,'CurrentAxes',hMainGui.MidPanel.aView);
if isempty(Stack)
    if isempty(hMainGui.ZoomView.level)
        axis auto;
    end
end
delete(findobj('Tag','pTracks'));
if ~isempty(Molecule)
    Molecule=PlotTracks(hMainGui,Molecule);
end
if ~isempty(Filament)
    Filament=PlotTracks(hMainGui,Filament);
end
if isempty(Stack)&&isempty(Molecule)&&isempty(Filament)
    set(hMainGui.MidPanel.pView,'Visible','Off');
    set(hMainGui.MidPanel.pNoData,'Visible','On');
else
    if isempty(Stack) 
        if isempty(hMainGui.ZoomView.level)
            xy=get(hMainGui.MidPanel.aView,{'xlim','ylim'});
            lx=(xy{1}(2)-xy{1}(1));
            ly=(xy{2}(2)-xy{2}(1));
            if ly>lx
                xy{1}(2)=xy{1}(1)+lx/2+ly/2;
                xy{1}(1)=xy{1}(1)+lx/2-ly/2;
            else
                xy{2}(2)=xy{2}(1)+ly/2+lx/2;            
                xy{2}(1)=xy{2}(1)+ly/2-lx/2;
            end
            set(hMainGui.MidPanel.aView,{'xlim','ylim'},xy);
            hMainGui.ZoomView.globalXY=xy;
            hMainGui.ZoomView.currentXY=xy;
            hMainGui.ZoomView.level=0;
            setappdata(0,'hMainGui',hMainGui);
        else
            set(hMainGui.MidPanel.aView,{'xlim','ylim'},hMainGui.ZoomView.currentXY);
        end
    end
end

function Object=PlotTracks(hMainGui,Object)
for n=length(Object):-1:1
    X=Object(n).Results(:,3)/hMainGui.Values.PixSize;
    Y=Object(n).Results(:,4)/hMainGui.Values.PixSize;
    if length(X)==1
        X(1,2)=X;
        Y(1,2)=Y;
    end
    Object(n).PlotHandles(1,1) = line(X,Y,'Color',Object(n).Color,'Tag','pTracks','Visible','on','LineStyle','-','AlignVertexCenters','on');        
end
Visible=[Object.Visible];
Selected=[Object.Selected];
Track=[Object.PlotHandles];
set(Track(~Visible),'Visible','off');
set(Track(Selected==1),'Selected','on');
SelectChannel(Object);

function SelectChannel(Object)
global Stack;
hMainGui=getappdata(0,'hMainGui');
Visible=[Object.Visible];
Channel=[Object.Channel];
Track=[Object.PlotHandles];
if all(ishandle(Track))
    if strcmp(get(hMainGui.ToolBar.ToolChannels(5),'State'),'on')||isempty(Stack)
        set(Track(Visible),'Visible','on');
        set(Track(~Visible),'Visible','off');
    else
        n = hMainGui.Values.FrameIdx(1);
        set(Track(Channel~=n),'Visible','off');
        set(Track(Channel==n),'Visible','on');
        set(Track(~Visible),'Visible','off');
    end
end

function ShowOffsetMap(hMainGui)
set(0,'CurrentFigure',hMainGui.fig);
set(hMainGui.fig,'CurrentAxes',hMainGui.MidPanel.aView);
OffsetMap=getappdata(hMainGui.fig,'OffsetMap');
delete(findobj('Tag','pOffset'));
for n = 1:length(OffsetMap)
    if strcmp(get(hMainGui.Menu.mAlignChannels,'Checked'),'on')
        T = OffsetMap(n).T;
        T(:,3) = [0;0;1];
        [OffsetMap(n).Match(:,3),OffsetMap(n).Match(:,4)] = transformPointsForward(affine2d(T),OffsetMap(n).Match(:,3),OffsetMap(n).Match(:,4));
    end
    line([OffsetMap(n).Match(:,1) OffsetMap(n).Match(:,3)]',[OffsetMap(n).Match(:,2) OffsetMap(n).Match(:,4)]','Color','white','Tag','pOffset','Visible','on','LineStyle','-.','Marker','none');
    line([OffsetMap(n).Match(:,1) OffsetMap(n).Match(:,3)]',[OffsetMap(n).Match(:,2) OffsetMap(n).Match(:,4)]','Color','black','Tag','pOffset','Visible','on','LineStyle',':','Marker','none');    
    line(OffsetMap(n).Match(:,1),OffsetMap(n).Match(:,2),'Color','red','Tag','pOffset','Visible','on','Marker','*','LineStyle','none');
    line(OffsetMap(n).Match(:,3),OffsetMap(n).Match(:,4),'Color','green','Tag','pOffset','Visible','on','Marker','*','LineStyle','none');
end

function hMainGui=SetZoom(hMainGui)
Zoom=hMainGui.ZoomView;
if ~isempty(Zoom.globalXY)
    Zoom.currentXY{1}=get(hMainGui.MidPanel.aView,'xlim');
    Zoom.currentXY{2}=get(hMainGui.MidPanel.aView,'ylim');
    x_total=Zoom.globalXY{1}(2)-Zoom.globalXY{1}(1);
    x_current=Zoom.currentXY{1}(2)-Zoom.currentXY{1}(1);
    Zoom.level=round(-log(x_current/x_total)*8);
    hMainGui.ZoomView=Zoom;
end
Zoom=hMainGui.ZoomKymo;
if ~isempty(Zoom.globalXY)
    Zoom.currentXY=get(hMainGui.MidPanel.aKymoGraph,{'xlim','ylim'});
    x_total=Zoom.globalXY{1}(2)-Zoom.globalXY{1}(1);
    x_current=Zoom.currentXY{1}(2)-Zoom.currentXY{1}(1);
    Zoom.level=round(-log(x_current/x_total)*8);
    hMainGui.ZoomKymo=Zoom;
end
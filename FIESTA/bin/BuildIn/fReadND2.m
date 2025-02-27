function [Stack,TimeInfo,PixelSize] = fReadND2(varargin)

if nargin == 0
    error('No file specified');
else
    source = varargin{1};
    options = [];
    if nargin == 2
        options = varargin{2};
    end
end

hMainGui=getappdata(0,'hMainGui'); 
progressdlg('close');
if ~isempty(hMainGui)
    progressdlg('Title','FIESTA','String','Reading Stack Information...','Parent',hMainGui.fig);    
end

reader = bfGetReader(source);

%extract the planes and the metadata from the cell array
Meta = reader.getMetadataStore();

N = Meta.getPlaneCount(0);

x = Meta.getPixelsSizeX(0);
x = x.getValue;
y = Meta.getPixelsSizeY(0);
y = y.getValue;

PixSize = Meta.getPixelsPhysicalSizeX(0);
PixelSize = PixSize.getValue;
progressdlg(0,'Reading Stack...');
if isempty(options)
    nChannels = 1;
    Region{1} = [1 1 x y];
    Block = 1;
else
    Region = options.Region;
    Block = options.Block;
    nChannels = max([numel(Region) numel(Block)]);
    if isempty(Region)
        Region{1} = [1 1 x y];
    else
        r = cell2mat(Region);
        xblock = min(r(:,1))*x;
        yblock = min(r(:,2))*y;
        for n = 1:nChannels
            Region{n} = [x*Region{n}(1)-xblock+1 y*Region{n}(2)-yblock+1 x*Region{n}(1) y*Region{n}(2)];
        end
    end
    if Block(end) == Inf
       Block(end) = N-sum(Block(1:end-1)); 
    end
    N = fix(N/sum(Block))*max(Block);
end
idxStack = zeros(1,length(Block));
NperChannel = fix(N/sum(Block)).*(Block);
sBlock = sum(Block);
cBlock = [0 cumsum(Block(1:end-1))]; 
TimeInfo = cell(1,nChannels);
Stack = cell(1,nChannels);   
for n = 1:nChannels
    if length(Region)>1
        y = Region{n}(4)-Region{n}(2)+1;
        x = Region{n}(3)-Region{n}(1)+1;
    end
    Stack{n} = zeros(y,x,NperChannel(n),'uint16');
end
for n = 1:N
    try
        Img = bfGetPlane(reader, n);
        if numel(idxStack)>1
            r = n - fix((n-1)/sBLock)*sBlock;
            idx = sum(r>cBlock)+1;
            if isemtpy(idx)
                idx = nChannels;
            end
            idxStack(idx) = idxStack(idx)+1;
            frame = idxStack(idx);
        else
            idx = 1:nChannels;
            frame = n;
        end
        for m = 1:numel(Region)
            Image = Img(Region{m}(2):Region{m}(4),Region{m}(1):Region{m}(3));
            Stack{idx(m)}(:,:,frame) = Image;   
            TimeInfo{idx(m)}(frame) = (Meta.getPlaneDeltaT(0,n-1).double - Meta.getPlaneDeltaT(0,0).double)*1000;
        end 
    catch
        progressdlg(1);      
        warning('MATLAB:outOfMemory','Out of memory - read %4.0f of %4.0f frames',n-1,N);
        break   
    end
    progressdlg(n/N*100);
end

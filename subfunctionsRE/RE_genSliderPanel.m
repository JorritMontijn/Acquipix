function [ptrPanelParent,ptrSlider] = RE_genSliderPanel(ptrMasterFigure,vecLocation,cellProps,cellVals,cellComments,cellCallbacks,dblStartVal)
	
	%check input
	if nargin < 5 || isempty(cellComments)
		cellComments = cellfill('',size(cellProps));
	end
	if nargin < 6 || isempty(cellCallbacks)
		cellCallbacks = cellfill('',size(cellProps));
	end
	if nargin < 7 || isempty(dblStartVal)
		dblStartVal = 1;
	end
	
	%unpack location vector
	dblPanelX = vecLocation(1);
	dblPanelY = vecLocation(2);
	dblPanelWidth = vecLocation(3);
	dblPanelHeight = vecLocation(4);
	
	%calculate the total size of the subpanel content
	ptrMasterFigure.Units = 'pixels';
	vecMasterSize = ptrMasterFigure.Position;
	ptrMasterFigure.Units = 'normalized';
	intParams = numel(cellProps);
	dblTotSize = (intParams+1)*30;
	dblRelSize = (dblTotSize/(vecMasterSize(end)*dblPanelHeight))+dblPanelHeight;
	
	
	%create the panels
	ptrPanelParent = uipanel('Parent',ptrMasterFigure);
	set(ptrPanelParent,'Position',[dblPanelX dblPanelY dblPanelWidth dblPanelHeight]);
	ptrPanelChild = uipanel('Parent',ptrPanelParent);
	set(ptrPanelChild,'Position',[0 0 1 dblRelSize]);
	ptrSlider = uicontrol('Style','Slider','Parent',ptrMasterFigure,...
		'Units','normalized','Position',[0.94 dblPanelY 0.05 dblPanelHeight],...
		'Value',dblStartVal,'Callback',{@fSliderCallback,ptrPanelChild});
	
	%add all variables
	vecParamTextPtrs = nan(1,intParams);
	vecParamEditPtrs = nan(1,intParams);
	for intParam=1:intParams
		vecParamTextPtrs(intParam) = uicontrol(ptrPanelChild,'style','text',...
			'Position',[1 (intParams*30)-((intParam-1)*30) 150 25],'String',cellProps{intParam},'FontSize',10);
		
		vecParamEditPtrs(intParam) = uicontrol(ptrPanelChild,'style','edit',...
			'Position',[150 (intParams*30)-((intParam-1)*30) 390 25],'String',cellVals{intParam},'Tooltip',cellComments{intParam},'FontSize',10);
		if ~isempty(cellCallbacks{intParam})
			set(vecParamEditPtrs(intParam),'Callback',cellCallbacks{intParam})
		end
	end
	
	%show panel
	fSliderCallback(ptrSlider,[],ptrPanelChild);
end
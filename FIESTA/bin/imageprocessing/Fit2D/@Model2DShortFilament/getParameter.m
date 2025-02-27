function [ model, x0, dx, lb, ub ] = getParameter( model, data )
  global fit_pic
  
  % calculate positions in region of interest
  c = double( model.guess.x(1:2,1:2) - repmat( data.offset, 2, 1 ) );

  % fill in missing parameters
  if isempty( model.guess.w )
    model.guess.w = 1/5;
  end
  if isempty( model.guess.h ) || isnan( model.guess.h )
    model.guess.h = abs(mean( interp2( fit_pic, c(1:2,1), c(1:2,2), '*nearest' ) ) - double( data.background ));
  else
    model.guess.h = abs(model.guess.h - double( data.background ));
  end
  
  % setup parameter array
  %    [ X1  Y1          X2  Y2          Width             Height           ]
  x0 = [ c(1,1:2)        c(2,1:2)        model.guess.w     model.guess.h    ];
  dx = [ 1   1           1   1           model.guess.w/10  model.guess.h/10 ];
  lb = [ 1   1           1   1           0                 model.guess.h/10 ];
  ub = [ data.rect(3:4)  data.rect(3:4)  10*model.guess.w  model.guess.h*10 ];

end
function pc = maxfind(inputmat)
%
% function maxfind(inputmat)
%
% Used to find the indices of the maximum element in the two dimensional
% input matrix 'inputmat'
% Output will be the said indices [row col maxin] where inputmat(row,col) will
% contain the maximum entry 'maxin'

% Copyright 2015 Larry Friedman, Brandeis University.

% This is free software: you can redistribute it and/or modify it under the
% terms of the GNU General Public License as published by the Free Software
% Foundation, either version 3 of the License, or (at your option) any later
% version.

% This software is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
% A PARTICULAR PURPOSE. See the GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this software. If not, see <http://www.gnu.org/licenses/>.

[mcol irow]=max(inputmat);
[maxin icol]=max(mcol);
pc=[irow(icol) icol  maxin];

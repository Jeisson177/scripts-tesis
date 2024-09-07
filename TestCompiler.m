function mi_aplicacion(varargin)
    % Verifica el número de argumentos de entrada
    if nargin < 1
        error('Se requiere al menos un argumento de entrada.');
    end

    % Procesa los argumentos
    for i = 1:nargin
        fprintf('Argumento %d: %s\n', i, varargin{i});
    end
end

function para = myBY(t, id)
if id == 1
    if t < 400
        para = [0, sqrt(0.5)];
    else
        para = [sqrt(0.4)/600*(t-400) sqrt(0.5)];
    end
end
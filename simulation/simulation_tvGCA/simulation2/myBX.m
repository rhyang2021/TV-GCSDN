function para = myBX(t, id)
if id == 1
    if t > 600
        para = [sqrt(0.5) 0];
    else
        para = [sqrt(0.5), sqrt(0.4)*(-t/600 + 1)];
    end    
end
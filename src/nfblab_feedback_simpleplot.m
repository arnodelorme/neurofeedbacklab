% a simple function to provide visual feedback on spectral power

function state = nfblab_feedback_simpleplot(state, feedbackVal, chunkPower, chunkIndex)

    if chunkIndex < 22
        tmpPower = chunkPower(1:20);
        tmpPower(tmpPower == 0) = NaN;
        plot(tmpPower);
    else
        plot(chunkPower(chunkIndex-20:chunkIndex-1));
    end
    
    title('Spectral power');

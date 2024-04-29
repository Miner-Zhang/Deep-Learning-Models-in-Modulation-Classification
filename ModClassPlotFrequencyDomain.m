function ModClassPlotFrequencyDomain(dataDirectory, modulationTypes, fs)
    numTypes = length(modulationTypes);
    numRows = ceil(numTypes / 4);
    figure('Name', 'Frequency Domain Signals');
    
    for modTypeIdx = 1:numTypes
        subplot(numRows, 4, modTypeIdx);
        files = dir(fullfile(dataDirectory, "*" + string(modulationTypes(modTypeIdx)) + "*"));
        idx = randi([1, length(files)]);
        load(fullfile(files(idx).folder, files(idx).name), 'frame');

        spf = size(frame, 1);
        f = (-fs/2:fs/spf:fs/2 - fs/spf);

        frame_fft = fftshift(fft(frame));
        plot(f, abs(frame_fft), '-'); 
        grid on; 
        axis tight;
        title(string(modulationTypes(modTypeIdx)));
        xlabel('Frequency (Hz)'); 
        ylabel('Magnitude');
    end
end

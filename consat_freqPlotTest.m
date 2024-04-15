figure
for i = 1:length(freq_ga)
    plot(freq_ga{i}.freq, mean(freq_ga{i}.powspctrm, 1))
    hold on
end

figure

ft_singleplotER([], ga)